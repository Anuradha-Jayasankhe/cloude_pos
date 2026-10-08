import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart' as db;
import '../models/models.dart' as models;
import 'api_client.dart';

class SyncService {
  static const int _maxRetryCount = 6;
  static const int _defaultPullLimit = 500;
  static const int _maxActivityLogItems = 300;
  static const Duration _autoSyncInterval = Duration(seconds: 15);
  static const String _lastSyncErrorKey = 'last_sync_error';

  final ApiClient _apiClient;
  final String tenantId;
  late final db.AppDatabase _database;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  Timer? _autoSyncTimer;
  Future<bool>? _inFlightSync;
  void Function()? _onRemoteDataApplied;
  String? _lastFailureReason;
  bool _isDisposed = false;
  int _autoSyncSuppressionDepth = 0;
  bool _syncRerunRequested = false;

  /// True when the last connectivity event was 'none'.
  /// Used to detect when the device comes back online so retry counts can be
  /// reset before the next sync attempt.
  bool _wasOffline = false;

  String? get lastFailureReason => _lastFailureReason;
  String get _workspaceStateKey => 'workspace_state_$tenantId';
  String get _activityLogKey => 'sync_activity_log_$tenantId';

  Future<T> runWithoutAutoSync<T>(Future<T> Function() action) async {
    _autoSyncSuppressionDepth++;
    try {
      return await action();
    } finally {
      _autoSyncSuppressionDepth--;
      if (_autoSyncSuppressionDepth == 0 && !_isDisposed) {
        unawaited(syncAllData());
      }
    }
  }

  bool get isAutoSyncSuppressed => _autoSyncSuppressionDepth > 0;

  SyncService(this._apiClient, this.tenantId) {
    _database = db.AppDatabase(tenantId);

    // Track whether the last known connectivity state was offline.
    // When the device comes BACK online after being offline, we must reset
    // all retry counters so items that exhausted their retry budget during
    // the offline period are eligible to be pushed again immediately.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        // Going offline — record the state so we know to reset retries later.
        _wasOffline = true;
        return;
      }

      // Coming back online.
      if (_wasOffline) {
        _wasOffline = false;
        // Reset retry counts for ALL queued items before syncing so that items
        // which exhausted their retry budget during the offline period are not
        // silently abandoned. We fire-and-forget the reset then sync.
        unawaited(
          _database
              .resetAllRetryCounts()
              .then((_) async {
                await _appendActivityLog(
                  'connectivity_restored_retries_reset',
                  {},
                );
                unawaited(syncAllData());
              })
              .catchError((_) {
                // If the reset fails (e.g. DB closed), still attempt sync.
                unawaited(syncAllData());
              }),
        );
      } else {
        unawaited(syncAllData());
      }
    });

    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) {
      unawaited(syncAllData());
    });
    unawaited(syncAllData());
  }

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<bool> syncAllData() async {
    if (_isDisposed) return false;
    final pendingSync = _inFlightSync;
    if (pendingSync != null) {
      _syncRerunRequested = true;
      return pendingSync;
    }

    final syncFuture = () async {
      var lastResult = false;
      do {
        _syncRerunRequested = false;
        lastResult = await _runSync();
      } while (_syncRerunRequested && !_isDisposed);
      return lastResult;
    }();

    _inFlightSync = syncFuture;
    try {
      return await syncFuture;
    } finally {
      if (identical(_inFlightSync, syncFuture)) {
        _inFlightSync = null;
      }
    }
  }

  Future<bool> _runSync() async {
    await _appendActivityLog('sync_start', {'tenantId': tenantId});
    _lastFailureReason = null;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('subscription_info') ?? '';
    if (raw.isNotEmpty) {
      try {
        final info = jsonDecode(raw) as Map;
        final syncEnabled = info['sync_enabled'] as bool? ?? true;
        if (!syncEnabled) {
          _lastFailureReason = null;
          await _clearPersistedFailureReason();
          return true;
        }
      } catch (_) {}
    }

    if (!await isOnline()) {
      _lastFailureReason =
          'No internet connection detected. Keep working offline and retry sync when online.';
      await _appendActivityLog('sync_skipped_offline', {
        'reason': _lastFailureReason,
      });
      await _persistLastFailureReason();
      await _reportDeviceState(
        status: 'offline',
        error: _lastFailureReason ?? '',
      );
      return false;
    }

    final authCheckMessage = await _validateAuthSession();
    if (authCheckMessage != null) {
      _lastFailureReason = authCheckMessage;
      await _appendActivityLog('sync_skipped_auth', {
        'reason': _lastFailureReason,
      });
      await _persistLastFailureReason();
      await _reportDeviceState(
        status: 'auth_error',
        error: _lastFailureReason ?? '',
      );
      return false;
    }

    try {
      await _repairMissingQueueEntries();

      // Only consider items that are still eligible to be pushed (haven't
      // exhausted retries) when deciding whether a push is needed.
      final pendingItems = await _database.getPendingSyncItems(
        maxRetries: _maxRetryCount,
      );
      final hasPending = pendingItems.isNotEmpty;
      final serverAhead = hasPending ? true : await _isServerAhead();

      if (!hasPending && !serverAhead) {
        // Nothing to push and server has no new events — skip entire cycle.
        await _appendActivityLog('sync_skipped_uptodate', {
          'localSeq': await _getLastSeq(),
        });
        await _reportDeviceState(status: 'healthy');
        return true;
      }

      // Push local queue first, then pull merged stream for deterministic replay.
      if (hasPending) await _uploadPendingChanges();
      if (serverAhead || hasPending) await _pullChanges();
      if (_lastFailureReason == null) {
        await _clearPersistedFailureReason();
      } else {
        await _persistLastFailureReason();
      }
      await _reportDeviceState(
        status: _lastFailureReason == null ? 'healthy' : 'degraded',
        error: _lastFailureReason ?? '',
      );
      await _appendActivityLog(
        _lastFailureReason == null
            ? 'sync_success'
            : 'sync_success_with_warnings',
        _lastFailureReason == null
            ? const <String, dynamic>{}
            : <String, dynamic>{'reason': _lastFailureReason},
      );
      return true;
    } on DioException catch (e) {
      _lastFailureReason = _mapDioFailure(e);
      await _appendActivityLog('sync_failed_dio', {
        'reason': _lastFailureReason,
        'statusCode': e.response?.statusCode,
      });
      await _persistLastFailureReason();
      await _reportDeviceState(
        status: 'error',
        error: _lastFailureReason ?? '',
      );
      return false;
    } catch (e, st) {
      final detail = e.toString();
      _lastFailureReason = 'Sync failed unexpectedly: $detail';
      await _appendActivityLog('sync_failed_unexpected', {
        'reason': _lastFailureReason,
        'error': detail,
        'stack': st.toString(),
      });
      await _persistLastFailureReason();
      await _reportDeviceState(
        status: 'error',
        error: _lastFailureReason ?? '',
      );
      return false;
    }
  }

  /// Validates the stored auth session before attempting a sync.
  ///
  /// Returns a human-readable error string if the session is unusable, or
  /// `null` if the session looks valid and the sync should proceed.
  Future<String?> _validateAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      return 'You are not logged in to the sync server. Please sign in again.';
    }

    if (token.startsWith('store-session-token-') ||
        token.startsWith('platform-session-token')) {
      return 'This is an offline local session token. Sign in using server credentials to enable sync.';
    }

    // Check whether the JWT has expired. The AuthInterceptor silently skips the
    // Authorization header for expired tokens, which causes the server to return
    // 401 — which in turn clears the stored token, breaking all subsequent syncs.
    // Detect expiry here and attempt a silent re-login with cached credentials.
    try {
      if (JwtDecoder.isExpired(token)) {
        await _appendActivityLog('auth_token_expired', {});
        final reloginResult = await _attemptSilentRelogin(prefs);
        if (reloginResult != null) {
          return reloginResult; // Re-login failed → surface the error.
        }
        // Re-login succeeded; new token stored in prefs. Continue with sync.
        return null;
      }
    } catch (_) {
      // JwtDecoder can throw on malformed tokens; treat as expired.
      return 'Session token is invalid. Please sign in again.';
    }

    return null;
  }

  /// Tries to re-authenticate using credentials cached by the auth service.
  /// Returns an error string on failure, or `null` on success.
  Future<String?> _attemptSilentRelogin(SharedPreferences prefs) async {
    final email = (prefs.getString('cached_login_email') ?? '').trim();
    final password = (prefs.getString('cached_login_password') ?? '').trim();
    if (email.isEmpty || password.isEmpty) {
      return 'Session expired. Please sign in again to continue syncing.';
    }

    try {
      final tenantId = (prefs.getString('tenant_id') ?? '').trim();
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          if (tenantId.isNotEmpty) 'tenant_id': tenantId,
          'email': email,
          'password': password,
          'device_id': prefs.getString('device_id') ?? '',
          'device_name': prefs.getString('device_label') ?? 'Store Buddy POS',
        },
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final newToken = (data['access_token'] ?? '').toString();
        if (newToken.isNotEmpty) {
          await prefs.setString('auth_token', newToken);
          await _appendActivityLog('auth_silent_relogin_success', {
            'email': email,
          });
          return null; // Success.
        }
      }
    } on DioException catch (_) {
      // Network or auth error — fall through to failure message.
    } catch (_) {
      // Unexpected error — fall through.
    }

    return 'Session expired and automatic re-login failed. Please sign in again.';
  }

  String _mapDioFailure(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return 'Server rejected authentication. Sign out and sign in again to refresh your token.';
    }
    if (code == 404) {
      return 'Sync endpoint was not found. Verify API base URL and backend route prefix.';
    }
    if (code == 422) {
      return 'Server rejected one or more queued operations. Check payload mapping and server validation logs.';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Cannot reach sync server. Confirm backend is running and API URL is reachable.';
    }

    return 'Sync request failed (${code ?? 'no-status'}). Check backend logs for details.';
  }

  Future<void> _persistLastFailureReason() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncErrorKey, _lastFailureReason ?? '');
  }

  Future<void> _clearPersistedFailureReason() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncErrorKey);
  }

  Future<void> _reportDeviceState({
    required String status,
    String error = '',
    int? lastAppliedSeq,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceLabel = (prefs.getString('device_label') ?? '').trim();
      await _apiClient.post(
        '/sync/device-state',
        data: {
          'last_applied_seq': lastAppliedSeq ?? await _getLastSeq(),
          'last_sync_status': status,
          'last_sync_error': error,
          if (deviceLabel.isNotEmpty) 'device_name': deviceLabel,
        },
      );
    } catch (_) {
      // Device-state reporting is best-effort and must never block sync.
    }
  }

  Future<int> _getLastSeq() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_sync_seq_$tenantId') ?? 0;
  }

  Future<void> _setLastSeq(int seq) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_seq_$tenantId', seq);
  }

  /// Fetches the current latest_seq from the server without downloading any
  /// events. Used by the auto-sync timer to decide whether a full pull is
  /// actually needed before making a heavier network request.
  ///
  /// Returns null if the check fails (network error, 4xx, etc.).
  Future<int?> _fetchServerLatestSeq() async {
    try {
      final response = await _apiClient.get('/sync/status');
      if (response.statusCode == 200) {
        final data = _toMap(response.data);
        return (data['latest_seq'] as num?)?.toInt();
      }
    } catch (_) {
      // Status check failures are non-fatal; fall back to a full pull.
    }
    return null;
  }

  /// Returns true if the server has events newer than our local seq cursor.
  Future<bool> _isServerAhead() async {
    final localSeq = await _getLastSeq();
    final serverSeq = await _fetchServerLatestSeq();
    if (serverSeq == null) return true; // Unknown — assume pull needed.
    return serverSeq > localSeq;
  }

  /// Bootstraps a fresh device from the /sync/full-snapshot endpoint.
  ///
  /// A fresh device has lastSeq = 0, meaning it would have to replay the
  /// entire SyncEvent history to build its local state. Instead, we fetch a
  /// point-in-time snapshot of all current SyncRecord documents for this tenant
  /// and apply them directly, then set lastSeq to the returned latest_seq so
  /// future incremental pulls only fetch genuinely new events.
  Future<bool> _bootstrapFromSnapshot() async {
    try {
      await _appendActivityLog('bootstrap_snapshot_start', {});
      final response = await _apiClient.get('/sync/full-snapshot');
      if (response.statusCode != 200) return false;

      final data = _toMap(response.data);
      final snapshotSeq = (data['latest_seq'] as num?)?.toInt() ?? 0;
      final records = (data['records'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      var applied = 0;
      var failed = 0;
      for (final record in records) {
        final entity = (record['entity'] ?? '').toString();
        final entityId = (record['entity_id'] ?? '').toString();
        final payload = _toMap(record['payload']);

        if (entity.isEmpty || entityId.isEmpty) continue;
        payload.putIfAbsent('id', () => entityId);
        payload.putIfAbsent('_id', () => entityId);

        try {
          await _applyWorkspaceEvent(entity, 'INSERT', payload);
          if (entity == 'products' || entity == 'inventory') {
            await _applyProductEvent('INSERT', payload);
          } else if (entity == 'customers') {
            await _applyCustomerEvent('INSERT', payload);
          } else if (entity == 'employees') {
            await _applyEmployeeEvent('INSERT', payload);
          } else if (entity == 'sales') {
            await _applySaleEvent('INSERT', payload);
          } else if (entity == 'expenses') {
            await _applyExpenseEvent('INSERT', payload);
          }
          applied++;
        } catch (_) {
          failed++;
        }
      }

      await _setLastSeq(snapshotSeq);
      await _reportDeviceState(
        status: failed == 0 ? 'healthy' : 'degraded',
        error: failed == 0
            ? ''
            : 'Bootstrap snapshot skipped $failed record(s) due to invalid payload.',
        lastAppliedSeq: snapshotSeq,
      );
      await _appendActivityLog('bootstrap_snapshot_done', {
        'snapshotSeq': snapshotSeq,
        'recordCount': records.length,
        'applied': applied,
        'failed': failed,
      });
      return true;
    } catch (e) {
      await _appendActivityLog('bootstrap_snapshot_failed', {
        'error': e.toString(),
      });
      return false;
    }
  }

  Future<void> _pullChanges() async {
    final initialSeq = await _getLastSeq();

    // A fresh device with seq=0 uses the full snapshot endpoint to get all
    // current server state in one request rather than replaying every
    // historical SyncEvent. After bootstrapping, lastSeq is set to the
    // snapshot's seq and we drop out — no incremental pull needed.
    if (initialSeq == 0) {
      final snapshotOk = await _bootstrapFromSnapshot();
      if (snapshotOk) {
        _onRemoteDataApplied?.call();
        return;
      }
      // Snapshot failed — fall through to the normal incremental pull
      // starting from seq=0 (may be slow for stores with many events).
    }

    int sinceSeq = initialSeq;
    int latestSeq = sinceSeq;
    var appliedEvents = 0;
    var skippedLocalEvents = 0;
    var skippedOwnEvents = 0;
    var failedEvents = 0;

    // Read this device's ID once so we can skip re-applying our own pushed
    // events (they are already in the local DB; re-applying causes unnecessary
    // DB writes and spurious UI refresh callbacks).
    final prefs = await SharedPreferences.getInstance();
    final ownDeviceId = (prefs.getString('device_id') ?? '').trim();

    while (true) {
      final response = await _apiClient.get(
        '/sync/pull',
        queryParameters: {'since_seq': sinceSeq, 'limit': _defaultPullLimit},
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Unexpected status code during pull: ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }

      final data = _toMap(response.data);
      final eventsRaw = data['events'];
      final events = eventsRaw is List<dynamic> ? eventsRaw : const <dynamic>[];

      final serverLatestSeq = (data['latest_seq'] as num?)?.toInt() ?? sinceSeq;
      latestSeq = serverLatestSeq > latestSeq ? serverLatestSeq : latestSeq;

      var highestSeenSeq = sinceSeq;

      for (final event in events) {
        final eventMap = _toMap(event);
        final eventSeq = (eventMap['seq'] as num?)?.toInt();
        if (eventSeq != null && eventSeq > highestSeenSeq) {
          highestSeenSeq = eventSeq;
        }

        // Skip events that originated from this device — they are already
        // applied locally and re-applying them is unnecessary. We still advance
        // the seq cursor (above) so these events are not fetched again.
        final sourceDeviceId = (eventMap['source_device_id'] ?? '')
            .toString()
            .trim();
        if (ownDeviceId.isNotEmpty &&
            sourceDeviceId.isNotEmpty &&
            sourceDeviceId == ownDeviceId) {
          skippedOwnEvents += 1;
          continue;
        }

        try {
          final applied = await _applyEvent(eventMap);
          final journalEntity = (eventMap['entity'] ?? '').toString();
          final journalEntityId =
              (eventMap['entity_id'] ?? eventMap['entityId'] ?? '')
                  .toString()
                  .trim();
          if (eventSeq != null) {
            await _upsertInboundJournal(
              serverSeq: eventSeq,
              operation: (eventMap['action'] ?? '').toString().toUpperCase(),
              entityTable: journalEntity,
              recordId: journalEntityId,
              status: applied ? 'applied' : 'skipped',
              createdAt:
                  _parseDateTime(eventMap['server_ts']) ??
                  DateTime.now().toUtc(),
              payload: _encodeJournalPayload(eventMap['payload']),
              errorReason: applied
                  ? null
                  : 'Local state is newer than the incoming event.',
              sourceDeviceId: (eventMap['source_device_id'] ?? '')
                  .toString()
                  .trim(),
              sourceUserId: (eventMap['source_user_id'] ?? '')
                  .toString()
                  .trim(),
            );
          }

          if (applied) {
            appliedEvents += 1;
          } else {
            skippedLocalEvents += 1;
          }
        } catch (e) {
          failedEvents += 1;
          if (eventSeq != null) {
            await _upsertInboundJournal(
              serverSeq: eventSeq,
              operation: (eventMap['action'] ?? '').toString().toUpperCase(),
              entityTable: (eventMap['entity'] ?? '').toString(),
              recordId: (eventMap['entity_id'] ?? eventMap['entityId'] ?? '')
                  .toString()
                  .trim(),
              status: 'failed',
              createdAt:
                  _parseDateTime(eventMap['server_ts']) ??
                  DateTime.now().toUtc(),
              payload: _encodeJournalPayload(eventMap['payload']),
              errorReason: e.toString(),
              sourceDeviceId: (eventMap['source_device_id'] ?? '')
                  .toString()
                  .trim(),
              sourceUserId: (eventMap['source_user_id'] ?? '')
                  .toString()
                  .trim(),
            );
          }
          await _appendActivityLog('pull_event_apply_failed', {
            'seq': eventSeq,
            'entity': eventMap['entity'],
            'entityId': eventMap['entity_id'] ?? eventMap['entityId'],
            'action': eventMap['action'],
            'error': e.toString(),
          });
        }
      }

      // Guard: only update sinceSeq when highestSeenSeq actually advanced.
      // Without this guard, a full page where all events belong to this device
      // (and are skipped) would leave sinceSeq unchanged and loop forever.
      if (highestSeenSeq > sinceSeq) {
        sinceSeq = highestSeenSeq;
      }

      // Stop paging when the server returned fewer events than the page size,
      // or when no new seq was seen (the entire page was own-device events
      // and we've caught up to latestSeq already).
      if (events.isEmpty ||
          events.length < _defaultPullLimit ||
          sinceSeq >= latestSeq) {
        break;
      }
    }

    final newSeq = sinceSeq > latestSeq ? sinceSeq : latestSeq;
    await _setLastSeq(newSeq);

    if (appliedEvents > 0 || newSeq > initialSeq) {
      _onRemoteDataApplied?.call();
      await _appendActivityLog('pull_applied', {
        'fromSeq': initialSeq,
        'toSeq': newSeq,
        'eventCount': appliedEvents,
        'skippedLocalCount': skippedLocalEvents,
        'skippedOwnCount': skippedOwnEvents,
        'failedEventCount': failedEvents,
      });
    } else {
      await _appendActivityLog('pull_noop', {
        'fromSeq': initialSeq,
        'toSeq': newSeq,
        'skippedLocalCount': skippedLocalEvents,
        'skippedOwnCount': skippedOwnEvents,
      });
    }

    if (failedEvents > 0) {
      _lastFailureReason =
          'Sync completed with $failedEvents event(s) skipped due to invalid payload.';
      await _persistLastFailureReason();
    }
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  String? _encodeJournalPayload(dynamic value) {
    if (value == null) return null;
    try {
      return jsonEncode(value);
    } catch (_) {
      return null;
    }
  }

  String _generateClientOpId(
    String operation,
    String entityTable,
    String recordId,
  ) {
    final nonce = DateTime.now().microsecondsSinceEpoch;
    return 'op-$nonce-${operation.toLowerCase()}-${entityTable.toLowerCase()}-${recordId.hashCode.abs()}';
  }

  String _clientOpIdForQueueItem(db.SyncQueueData item) {
    final current = (item.clientOpId ?? '').trim();
    if (current.isNotEmpty) {
      return current;
    }
    return 'legacy-${item.id}';
  }

  String _journalRetryStatus(int retryCount) {
    return retryCount >= _maxRetryCount ? 'failed' : 'retrying';
  }

  String _repairOperationForRecord(DateTime? createdAt, DateTime? updatedAt) {
    if (createdAt == null || updatedAt == null) {
      return 'UPDATE';
    }
    final ageDelta = updatedAt.difference(createdAt).abs();
    return ageDelta <= const Duration(seconds: 1) ? 'INSERT' : 'UPDATE';
  }

  Future<void> _repairMissingQueueEntries() async {
    await _repairUnsyncedSales();
    await _repairUnsyncedProducts();
    await _repairUnsyncedCustomers();
    await _repairUnsyncedEmployees();
    await _repairUnsyncedExpenses();
    await _repairUnsyncedWorkspaceRecords();
  }

  Future<void> _repairUnsyncedSales() async {
    final unsyncedSales = await _database.getUnsyncedSales();
    for (final sale in unsyncedSales) {
      if (await _database.hasQueuedSyncItemForRecord('sales', sale.id)) {
        continue;
      }

      final items = await _database.getSaleItems(sale.id);
      await queueOperation(
        _repairOperationForRecord(sale.createdAt, sale.updatedAt),
        'sales',
        sale.id,
        {
          'id': sale.id,
          'tenantId': sale.tenantId,
          'customerId': sale.customerId,
          'employeeId': sale.employeeId,
          'total': sale.total,
          'tax': sale.tax,
          'discount': sale.discount,
          'paymentMethod': sale.paymentMethod,
          'status': sale.status,
          'locationId': sale.locationId,
          'createdAt': sale.createdAt?.toIso8601String(),
          'updatedAt': sale.updatedAt?.toIso8601String(),
          'shippingAddress': sale.shippingAddress,
          'items': items
              .map(
                (item) => <String, dynamic>{
                  'id': item.id,
                  'saleId': item.saleId,
                  'productId': item.productId,
                  'productName': item.productName,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                  'total': item.total,
                  'tenantId': item.tenantId,
                },
              )
              .toList(),
        },
        triggerSync: false,
      );
      await _appendActivityLog('queue_repaired_missing_sale', {
        'recordId': sale.id,
      });
    }
  }

  Future<void> _repairUnsyncedProducts() async {
    final unsyncedProducts = await _database.getUnsyncedProducts();
    for (final product in unsyncedProducts) {
      if (await _database.hasQueuedSyncItemForRecord('products', product.id)) {
        continue;
      }

      await queueOperation(
        _repairOperationForRecord(product.createdAt, product.updatedAt),
        'products',
        product.id,
        {
          'id': product.id,
          'tenantId': product.tenantId,
          'name': product.name,
          'description': product.description,
          'sku': product.sku,
          'barcode': product.barcode,
          'price': product.price,
          'costPrice': product.costPrice,
          'category': product.category,
          'type': product.type,
          'unitOfMeasure': product.unitOfMeasure,
          'stock': product.stock,
          'minStock': product.minStock,
          'minPrice': product.minPrice,
          'warrantyMonths': product.warrantyMonths,
          'locationId': product.locationId,
          'createdAt': product.createdAt?.toIso8601String(),
          'updatedAt': product.updatedAt?.toIso8601String(),
        },
        triggerSync: false,
      );
      await _appendActivityLog('queue_repaired_missing_product', {
        'recordId': product.id,
      });
    }
  }

  Future<void> _repairUnsyncedCustomers() async {
    final unsyncedCustomers = await _database.getUnsyncedCustomers();
    for (final customer in unsyncedCustomers) {
      if (await _database.hasQueuedSyncItemForRecord(
        'customers',
        customer.id,
      )) {
        continue;
      }

      await queueOperation(
        _repairOperationForRecord(customer.createdAt, customer.updatedAt),
        'customers',
        customer.id,
        {
          'id': customer.id,
          'tenantId': customer.tenantId,
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email,
          'address': customer.address,
          'creditLimit': customer.creditLimit,
          'currentBalance': customer.currentBalance,
          'createdAt': customer.createdAt?.toIso8601String(),
          'updatedAt': customer.updatedAt?.toIso8601String(),
          'shippingAddress': customer.shippingAddress,
        },
        triggerSync: false,
      );
      await _appendActivityLog('queue_repaired_missing_customer', {
        'recordId': customer.id,
      });
    }
  }

  Future<void> _repairUnsyncedEmployees() async {
    final unsyncedEmployees = await _database.getUnsyncedEmployees();
    for (final employee in unsyncedEmployees) {
      if (await _database.hasQueuedSyncItemForRecord(
        'employees',
        employee.id,
      )) {
        continue;
      }

      await queueOperation(
        _repairOperationForRecord(employee.createdAt, employee.updatedAt),
        'employees',
        employee.id,
        {
          'id': employee.id,
          'tenantId': employee.tenantId,
          'name': employee.name,
          'email': employee.email,
          'role': employee.role,
          'locationId': employee.locationId,
          'createdAt': employee.createdAt?.toIso8601String(),
          'updatedAt': employee.updatedAt?.toIso8601String(),
        },
        triggerSync: false,
      );
      await _appendActivityLog('queue_repaired_missing_employee', {
        'recordId': employee.id,
      });
    }
  }

  Future<void> _repairUnsyncedExpenses() async {
    final unsyncedExpenses = await _database.getUnsyncedExpenses();
    for (final exp in unsyncedExpenses) {
      if (await _database.hasQueuedSyncItemForRecord('expenses', exp.id)) {
        continue;
      }

      await queueOperation(
        _repairOperationForRecord(exp.createdAt, exp.updatedAt),
        'expenses',
        exp.id,
        {
          'id': exp.id,
          'tenantId': exp.tenantId.isNotEmpty ? exp.tenantId : tenantId,
          'category': exp.category,
          'description': exp.description,
          'amount': exp.amount,
          'locationId': exp.locationId,
          'employeeId': exp.employeeId,
          'notes': exp.notes,
          'expenseDate': exp.expenseDate.toIso8601String(),
          'createdAt': exp.createdAt?.toIso8601String() ?? exp.expenseDate.toIso8601String(),
          'updatedAt': (exp.updatedAt ?? exp.createdAt ?? exp.expenseDate).toIso8601String(),
        },
        triggerSync: false,
      );
      await _appendActivityLog('queue_repaired_missing_expense', {
        'recordId': exp.id,
      });
    }
  }

  Future<void> _repairUnsyncedWorkspaceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workspaceStateKey);
    if (raw == null || raw.isEmpty) return;
    final Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) return;
      decoded = Map<String, dynamic>.from(parsed);
    } catch (_) {
      return;
    }

    // 1. Bank Transactions
    final bankTxList = (decoded['bankTransactions'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    for (final tx in bankTxList) {
      final id = (tx['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      if (await _database.hasQueuedSyncItemForRecord('bank_transactions', id) ||
          await _database.hasJournalEntryForRecord('bank_transactions', id)) {
        continue;
      }
      await queueOperation(
        'INSERT',
        'bank_transactions',
        id,
        {
          ...tx,
          'tenantId': tenantId,
          'updatedAt': tx['createdAt'] ?? DateTime.now().toIso8601String(),
        },
        triggerSync: false,
      );
      await _appendActivityLog('queue_repaired_missing_bank_tx', {'recordId': id});
    }

    // 2. Cashier Sessions
    final sessList = (decoded['cashierSessions'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    for (final sess in sessList) {
      final id = (sess['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      if (await _database.hasQueuedSyncItemForRecord('cashier_sessions', id) ||
          await _database.hasJournalEntryForRecord('cashier_sessions', id)) {
        continue;
      }
      await queueOperation(
        'INSERT',
        'cashier_sessions',
        id,
        {
          ...sess,
          'tenantId': tenantId,
          'updatedAt': sess['closingTime'] ?? sess['openingTime'] ?? DateTime.now().toIso8601String(),
        },
        triggerSync: false,
      );
      await _appendActivityLog('queue_repaired_missing_cashier_session', {'recordId': id});
    }

    // 3. Mobile Reloads
    final reloadList = (decoded['mobileReloads'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    for (final rld in reloadList) {
      final id = (rld['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      if (await _database.hasQueuedSyncItemForRecord('mobile_reloads', id) ||
          await _database.hasJournalEntryForRecord('mobile_reloads', id)) {
        continue;
      }
      await queueOperation(
        'INSERT',
        'mobile_reloads',
        id,
        {
          ...rld,
          'tenantId': tenantId,
          'updatedAt': rld['createdAt'] ?? DateTime.now().toIso8601String(),
        },
        triggerSync: false,
      );
      await _appendActivityLog('queue_repaired_missing_mobile_reload', {'recordId': id});
    }
  }

  Future<void> _upsertOutboundJournal({
    required String clientOpId,
    required String operation,
    required String entityTable,
    required String recordId,
    required String status,
    required DateTime createdAt,
    String? payload,
    String? errorReason,
    int? serverSeq,
    int retryCount = 0,
  }) async {
    final now = DateTime.now().toUtc();
    await _database.upsertSyncJournalEntry(
      db.SyncJournalCompanion(
        clientOpId: Value(clientOpId),
        serverSeq: Value(serverSeq),
        direction: const Value('outbound'),
        status: Value(status),
        operation: Value(operation),
        entityTable: Value(entityTable),
        recordId: Value(recordId),
        payload: Value(payload),
        errorReason: Value(errorReason),
        sourceDeviceId: const Value(null),
        sourceUserId: const Value(null),
        retryCount: Value(retryCount),
        createdAt: Value(createdAt),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _upsertInboundJournal({
    required int serverSeq,
    required String operation,
    required String entityTable,
    required String recordId,
    required String status,
    required DateTime createdAt,
    String? payload,
    String? errorReason,
    String? sourceDeviceId,
    String? sourceUserId,
  }) async {
    final now = DateTime.now().toUtc();
    await _database.upsertSyncJournalEntry(
      db.SyncJournalCompanion(
        clientOpId: const Value(null),
        serverSeq: Value(serverSeq),
        direction: const Value('inbound'),
        status: Value(status),
        operation: Value(operation),
        entityTable: Value(entityTable),
        recordId: Value(recordId),
        payload: Value(payload),
        errorReason: Value(errorReason),
        sourceDeviceId: Value(sourceDeviceId),
        sourceUserId: Value(sourceUserId),
        retryCount: const Value(0),
        createdAt: Value(createdAt),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _appendActivityLog(
    String type,
    Map<String, dynamic> details,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_activityLogKey);
      final list = <Map<String, dynamic>>[];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List<dynamic>) {
          for (final item in decoded) {
            if (item is Map) {
              list.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }

      list.add({
        'at': DateTime.now().toUtc().toIso8601String(),
        'type': type,
        ...details,
      });

      if (list.length > _maxActivityLogItems) {
        list.removeRange(0, list.length - _maxActivityLogItems);
      }

      await prefs.setString(_activityLogKey, jsonEncode(list));
    } catch (_) {
      // Logging should never interrupt sync flow.
    }
  }

  Future<List<Map<String, dynamic>>> getRecentSyncActivity({
    int limit = 100,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activityLogKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return <Map<String, dynamic>>[];
    }

    final entries = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (entries.length <= limit) {
      return entries;
    }
    return entries.sublist(entries.length - limit);
  }

  Future<List<Map<String, dynamic>>> getSyncJournalEntries({
    String? direction,
    String? status,
    int limit = 120,
  }) async {
    final entries = await _database.getSyncJournalEntries(
      direction: direction,
      status: status,
      limit: limit,
    );

    return entries
        .map(
          (entry) => <String, dynamic>{
            'id': entry.id,
            'client_op_id': entry.clientOpId,
            'server_seq': entry.serverSeq,
            'direction': entry.direction,
            'status': entry.status,
            'operation': entry.operation,
            'entity': entry.entityTable,
            'record_id': entry.recordId,
            'payload': entry.payload,
            'error_reason': entry.errorReason,
            'source_device_id': entry.sourceDeviceId,
            'source_user_id': entry.sourceUserId,
            'retry_count': entry.retryCount,
            'created_at': entry.createdAt.toIso8601String(),
            'updated_at': entry.updatedAt.toIso8601String(),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchServerAuditEvents({
    int limit = 200,
  }) async {
    final response = await _apiClient.get(
      '/sync/audit',
      queryParameters: {'limit': limit},
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Unexpected status code during audit pull: ${response.statusCode}',
        type: DioExceptionType.badResponse,
      );
    }

    final data = _toMap(response.data);
    final events = (data['events'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return events;
  }

  Future<
    ({
      int latestSeq,
      List<Map<String, dynamic>> events,
      List<Map<String, dynamic>> devices,
    })
  >
  fetchServerJournal({
    int limit = 200,
    int sinceSeq = 0,
    bool unseenOnly = false,
  }) async {
    final response = await _apiClient.get(
      '/sync/journal',
      queryParameters: {
        'limit': limit,
        if (sinceSeq > 0) 'since_seq': sinceSeq,
        if (unseenOnly) 'unseen_only': true,
      },
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message:
            'Unexpected status code during sync journal pull: ${response.statusCode}',
        type: DioExceptionType.badResponse,
      );
    }

    final data = _toMap(response.data);
    final latestSeq = (data['latest_seq'] as num?)?.toInt() ?? 0;
    final events = (data['events'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final devices = (data['devices'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return (latestSeq: latestSeq, events: events, devices: devices);
  }

  Future<bool> _applyEvent(Map<String, dynamic> event) async {
    final entity = (event['entity'] ?? '').toString();
    final action = (event['action'] ?? '').toString().toUpperCase();
    final entityId = (event['entity_id'] ?? event['entityId'] ?? '')
        .toString()
        .trim();
    final payload = _toMap(event['payload']);

    if (entityId.isNotEmpty) {
      payload.putIfAbsent('id', () => entityId);
      payload.putIfAbsent('_id', () => entityId);
    }

    final applied = await _applyWorkspaceEvent(entity, action, payload);
    if (!applied) return false;

    if (entity == 'products' || entity == 'inventory') {
      await _applyProductEvent(action, payload);
      return true;
    }
    if (entity == 'customers') {
      await _applyCustomerEvent(action, payload);
      return true;
    }
    if (entity == 'employees') {
      await _applyEmployeeEvent(action, payload);
      return true;
    }
    if (entity == 'users') {
      return true;
    }
    if (entity == 'sales') {
      await _applySaleEvent(action, payload);
      return true;
    }
    if (entity == 'expenses') {
      await _applyExpenseEvent(action, payload);
      return true;
    }

    return true;
  }

  Future<bool> _applyWorkspaceEvent(
    String entity,
    String action,
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workspaceStateKey);
    final Map<String, dynamic> decoded;
    if (raw == null || raw.isEmpty) {
      decoded = <String, dynamic>{};
    } else {
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) return true;
      decoded = Map<String, dynamic>.from(parsed);
    }

    if (entity == 'settings') {
      final existing = Map<String, dynamic>.from(
        (decoded['settings'] as Map?) ?? const <String, dynamic>{},
      );
      existing.addAll(payload);
      decoded['settings'] = existing;
      await prefs.setString(_workspaceStateKey, jsonEncode(decoded));
      return true;
    }

    if (entity == 'credit_payments' || entity == 'credit_sales') {
      final customerId = (payload['customerId'] ?? '').toString().trim();
      if (customerId.isEmpty) return true;

      final mapKey = entity == 'credit_payments'
          ? 'customerCreditPayments'
          : 'customerCreditSales';

      final mapData = Map<String, dynamic>.from(
        decoded[mapKey] as Map? ?? const <String, dynamic>{},
      );
      final existingList =
          (mapData[customerId] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

      final itemId = _workspaceItemKey(entity, payload);
      if (itemId == null || itemId.isEmpty) return true;

      final index = existingList.indexWhere(
        (item) => _workspaceItemKey(entity, item) == itemId,
      );

      if (index >= 0) {
        final existingItem = existingList[index];
        final existingTsStr =
            existingItem['updatedAt'] ?? existingItem['updated_at'];
        final incomingTsStr = payload['updatedAt'] ?? payload['updated_at'];

        if (existingTsStr != null && incomingTsStr != null) {
          try {
            final existingDate = DateTime.parse(existingTsStr.toString());
            final incomingDate = DateTime.parse(incomingTsStr.toString());
            if (incomingDate.isBefore(existingDate) ||
                incomingDate.isAtSameMomentAs(existingDate)) {
              return false; // Local is newer or same, skip LWW
            }
          } catch (_) {}
        }
      }

      if (action == 'DELETE') {
        if (index >= 0) {
          existingList.removeAt(index);
        }
      } else {
        if (index >= 0) {
          existingList[index] = payload;
        } else {
          existingList.add(payload);
        }
      }

      mapData[customerId] = existingList;
      decoded[mapKey] = mapData;
      await prefs.setString(_workspaceStateKey, jsonEncode(decoded));
      return true;
    }

    if (entity == 'categories') {
      final category =
          (payload['category'] ?? payload['name'] ?? payload['id'] ?? '')
              .toString()
              .trim();
      if (category.isEmpty) return true;

      final categories = (decoded['productCategories'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final attributes = Map<String, dynamic>.from(
        decoded['categoryAttributes'] ?? {},
      );

      if (action == 'DELETE') {
        categories.removeWhere((item) => item == category);
        attributes.remove(category);
      } else {
        if (!categories.contains(category)) {
          categories.add(category);
        }
        attributes[category] =
            (payload['attributes'] as List<dynamic>? ?? const <dynamic>[])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
      }

      decoded['productCategories'] = categories;
      decoded['categoryAttributes'] = attributes;
      await prefs.setString(_workspaceStateKey, jsonEncode(decoded));
      return true;
    }

    final key = _workspaceCollectionKey(entity);
    if (key == null) return true;

    final list = (decoded[key] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final payloadKey = _workspaceItemKey(entity, payload);
    if (payloadKey == null || payloadKey.isEmpty) return true;

    final index = list.indexWhere((item) {
      final itemKey = _workspaceItemKey(entity, item);
      return itemKey == payloadKey;
    });

    if (index >= 0) {
      final existingItem = list[index];
      final existingTsStr =
          existingItem['updatedAt'] ??
          existingItem['updated_at'] ??
          existingItem['createdAt'];
      final incomingTsStr =
          payload['updatedAt'] ?? payload['updated_at'] ?? payload['createdAt'];

      if (existingTsStr != null && incomingTsStr != null) {
        try {
          final existingDate = DateTime.parse(existingTsStr.toString());
          final incomingDate = DateTime.parse(incomingTsStr.toString());
          if (incomingDate.isBefore(existingDate) ||
              incomingDate.isAtSameMomentAs(existingDate)) {
            return false; // Local is newer or same, skip LWW
          }
        } catch (_) {}
      }
    }

    if (action == 'DELETE') {
      if (index >= 0) {
        list.removeAt(index);
      }
    } else {
      if (index >= 0) {
        list[index] = payload;
      } else {
        list.add(payload);
      }
    }

    decoded[key] = list;
    await prefs.setString(_workspaceStateKey, jsonEncode(decoded));
    return true;
  }

  String? _workspaceCollectionKey(String entity) {
    switch (entity) {
      case 'products':
      case 'inventory':
        return 'products';
      case 'customers':
        return 'customers';
      case 'employees':
        return 'employees';
      case 'users':
        return 'users';
      case 'locations':
        return 'locations';
      case 'stock_transfers':
        return 'stockTransfers';
      case 'suppliers':
        return 'suppliers';
      case 'coupons':
        return 'coupons';
      case 'services':
      case 'job_cards':
        return 'serviceJobs';
      case 'returns':
        return 'returns';
      case 'sales':
        return 'sales';
      case 'installments':
        return 'installmentPlans';
      case 'purchase_orders':
        return 'purchaseOrders';
      case 'attendance':
        return 'attendanceRecords';
      case 'payroll':
        return 'payrollRecords';
      case 'stock_adjustments':
        return 'stockAdjustments';
      case 'expenses':
        return 'expenses';
      case 'bank_transactions':
        return 'bankTransactions';
      case 'cashier_sessions':
        return 'cashierSessions';
      case 'mobile_reloads':
        return 'mobileReloads';
      default:
        return null;
    }
  }

  String? _workspaceItemKey(String entity, Map<String, dynamic> item) {
    if (entity == 'coupons') {
      return (item['code'] ?? '').toString();
    }
    if (entity == 'categories') {
      return (item['category'] ?? item['name'] ?? '').toString();
    }
    if (entity == 'credit_payments' || entity == 'credit_sales') {
      return (item['id'] ?? '').toString();
    }
    return (item['id'] ?? item['_id'] ?? '').toString();
  }

  Future<void> _applyProductEvent(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final id = _idFromPayload(payload);
    if (id == null) return;

    if (action == 'DELETE') {
      await _database.deleteProduct(id);
      return;
    }

    final existing = await _database.getProduct(id);
    final normalized = <String, dynamic>{
      ...payload,
      'id': id,
      '_id': id,
      'tenantId': (payload['tenantId'] ?? existing?.tenantId ?? tenantId)
          .toString(),
      'name': (payload['name'] ?? existing?.name ?? 'Unknown Product')
          .toString(),
      'description': (payload['description'] ?? existing?.description ?? '')
          .toString(),
      'sku': (payload['sku'] ?? existing?.sku ?? id).toString(),
      'barcode': (payload['barcode'] ?? existing?.barcode ?? id).toString(),
      'price': (payload['price'] as num?)?.toDouble() ?? existing?.price ?? 0.0,
      'costPrice':
          (payload['costPrice'] as num?)?.toDouble() ?? existing?.costPrice,
      'category': (payload['category'] ?? existing?.category ?? 'General')
          .toString(),
      'type':
          (payload['type'] ??
                  payload['productType'] ??
                  existing?.type ??
                  'PRODUCT')
              .toString()
              .toUpperCase(),
      'unitOfMeasure':
          (payload['unitOfMeasure'] ??
                  payload['measureUnit'] ??
                  existing?.unitOfMeasure ??
                  'PIECE')
              .toString()
              .toUpperCase(),
      'stock': (payload['stock'] as num?)?.toDouble() ?? existing?.stock ?? 0.0,
      'minStock':
          (payload['minStock'] as num?)?.toDouble() ??
          existing?.minStock ??
          0.0,
      'minPrice':
          (payload['minPrice'] as num?)?.toDouble() ??
          existing?.minPrice ??
          0.0,
      'warrantyMonths':
          (payload['warrantyMonths'] as num?)?.toInt() ??
          existing?.warrantyMonths ??
          0,
      'locationId': (payload['locationId'] ?? existing?.locationId)?.toString(),
      'synced': payload['synced'] ?? true,
      'createdAt':
          payload['createdAt'] ?? existing?.createdAt?.toIso8601String(),
      'updatedAt':
          payload['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
    };
    normalized['synced'] = true;
    normalized['isSynced'] = true;

    final product = models.Product.fromJson(normalized);
    if (existing == null) {
      await _database.insertProduct(product.toCompanion());
    } else {
      await _database.updateProduct(product.toCompanion());
    }
  }

  Future<void> _applyCustomerEvent(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final id = _idFromPayload(payload);
    if (id == null) return;

    if (action == 'DELETE') {
      await (_database.delete(
        _database.customers,
      )..where((c) => c.id.equals(id))).go();
      return;
    }

    payload.putIfAbsent('id', () => id);
    payload.putIfAbsent('_id', () => id);
    payload.putIfAbsent('tenantId', () => tenantId);
    payload['synced'] = true;
    payload['isSynced'] = true;
    final customer = models.Customer.fromJson(payload);
    final existing = await _database.getCustomer(customer.id);
    if (existing == null) {
      await _database.insertCustomer(customer.toCompanion());
    } else {
      await _database.updateCustomer(customer.toCompanion());
    }
  }

  Future<void> _applyEmployeeEvent(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final id = _idFromPayload(payload);
    if (id == null) return;

    if (action == 'DELETE') {
      await (_database.delete(
        _database.employees,
      )..where((e) => e.id.equals(id))).go();
      return;
    }

    payload.putIfAbsent('id', () => id);
    payload.putIfAbsent('_id', () => id);
    payload.putIfAbsent('tenantId', () => tenantId);
    payload.putIfAbsent('name', () => 'Employee');
    payload.putIfAbsent('email', () => '');
    payload.putIfAbsent('role', () => 'STAFF');
    payload.putIfAbsent('locationId', () => 'Main Branch');
    payload['synced'] = true;
    payload['isSynced'] = true;
    payload['name'] = (payload['name'] ?? 'Employee').toString();
    payload['email'] = (payload['email'] ?? '').toString();
    payload['role'] = (payload['role'] ?? 'STAFF').toString().toUpperCase();
    payload['locationId'] = (payload['locationId'] ?? 'Main Branch').toString();
    final employee = models.Employee.fromJson(payload);
    final existing = await _database.getEmployee(employee.id);
    if (existing == null) {
      await _database.insertEmployee(employee.toCompanion());
    } else {
      await _database.updateEmployee(employee.toCompanion());
    }
  }

  Future<void> _applySaleEvent(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final id = _idFromPayload(payload);
    if (id == null) return;

    if (action == 'DELETE') {
      await (_database.delete(
        _database.saleItems,
      )..where((si) => si.saleId.equals(id))).go();
      await (_database.delete(
        _database.sales,
      )..where((s) => s.id.equals(id))).go();
      return;
    }

    // Ensure all required fields are present so Sale.fromJson never throws
    // on a payload from an older client that omits optional fields.
    payload.putIfAbsent('id', () => id);
    payload.putIfAbsent('_id', () => id);
    payload.putIfAbsent('tenantId', () => tenantId);
    payload.putIfAbsent('employeeId', () => '');
    payload.putIfAbsent('total', () => 0);
    payload.putIfAbsent('tax', () => 0);
    payload.putIfAbsent('discount', () => 0);
    payload.putIfAbsent('paymentMethod', () => 'CASH');
    payload.putIfAbsent('status', () => 'COMPLETED');
    payload.putIfAbsent('locationId', () => '');

    // Mark as synced=true — this record came from the authoritative server so
    // we don't need to push it again. Without this the record stays synced=false
    // on Device B and gets re-queued, causing an unnecessary round-trip.
    payload['synced'] = true;
    payload['isSynced'] = true;

    final sale = models.Sale.fromJson(payload);

    // Atomically replace the sale header + all its items in a single DB
    // transaction. The previous approach (delete items → update header → insert
    // items) left a window where the sale had 0 items, causing _fromDomainSale
    // to build a receipt with no line items on Device B.
    await _database.transaction(() async {
      // insertSale now uses insertOrReplace so this handles both INSERT and
      // UPDATE without needing a separate getSale() lookup first.
      await _database.insertSale(sale.toCompanion());

      // Delete existing items then re-insert (safe inside the transaction).
      await (_database.delete(
        _database.saleItems,
      )..where((si) => si.saleId.equals(sale.id))).go();

      for (final item in sale.items) {
        await _database.insertSaleItem(item.toCompanion());
      }
    });
  }

  Future<void> _applyExpenseEvent(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final id = _idFromPayload(payload);
    if (id == null) return;

    if (action == 'DELETE') {
      await _database.deleteExpense(id);
      return;
    }

    final amt = (payload['amount'] as num?)?.toDouble() ?? 0.0;
    final expDate = payload['expenseDate'] != null
        ? DateTime.tryParse(payload['expenseDate'].toString()) ?? DateTime.now()
        : DateTime.now();
    final createdAt = payload['createdAt'] != null
        ? DateTime.tryParse(payload['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();
    final updatedAt = payload['updatedAt'] != null
        ? DateTime.tryParse(payload['updatedAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    final companion = db.ExpensesCompanion(
      id: Value(id),
      tenantId: Value((payload['tenantId'] ?? tenantId).toString()),
      category: Value((payload['category'] ?? 'OTHER').toString()),
      description: Value((payload['description'] ?? 'Expense').toString()),
      amount: Value(amt),
      locationId: Value((payload['locationId'] ?? '').toString()),
      employeeId: Value(payload['employeeId']?.toString()),
      notes: Value(payload['notes']?.toString()),
      expenseDate: Value(expDate),
      synced: const Value(true),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );

    await _database.insertExpense(companion);
  }

  String? _idFromPayload(Map<String, dynamic> payload) {
    final raw = payload['id'] ?? payload['_id'];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _markLocalRecordSynced(String entity, String recordId) async {
    if (entity.isEmpty || recordId.isEmpty) return;

    try {
      switch (entity) {
        case 'products':
        case 'inventory':
          await _database.markProductSynced(recordId);
          break;
        case 'sales':
          await _database.markSaleSynced(recordId);
          break;
        case 'customers':
          await _database.markCustomerSynced(recordId);
          break;
        case 'employees':
          await _database.markEmployeeSynced(recordId);
          break;
        case 'expenses':
          await _database.markExpenseSynced(recordId);
          break;
        default:
          break;
      }
    } catch (e) {
      await _appendActivityLog('post_ack_sync_mark_failed', {
        'entity': entity,
        'entityId': recordId,
        'error': e.toString(),
      });
    }
  }

  Future<void> _uploadPendingChanges() async {
    // getPendingSyncItems already excludes items that exceeded _maxRetryCount.
    final pendingItems = await _database.getPendingSyncItems(
      maxRetries: _maxRetryCount,
    );

    if (pendingItems.isEmpty) return;

    await _appendActivityLog('push_start', {
      'pendingCount': pendingItems.length,
    });

    final ops = <Map<String, dynamic>>[];
    final queuedByClientOpId = <String, db.SyncQueueData>{};
    for (final item in pendingItems) {
      if (!_isRetryWindowOpen(item)) continue;

      Map<String, dynamic> payload;
      try {
        final rawData = jsonDecode(item.data);
        payload = _toMap(rawData);
      } catch (e) {
        await _database.updateSyncItemRetry(item.id);
        final nextRetryCount = item.retryCount + 1;
        await _upsertOutboundJournal(
          clientOpId: _clientOpIdForQueueItem(item),
          operation: item.operation,
          entityTable: item.entityTable,
          recordId: item.recordId,
          status: _journalRetryStatus(nextRetryCount),
          createdAt: item.createdAt,
          payload: item.data,
          errorReason: 'Failed to decode queued payload: ${e.toString()}',
          retryCount: nextRetryCount,
        );
        await _appendActivityLog('queue_payload_decode_failed', {
          'queueId': item.id,
          'entity': item.entityTable,
          'recordId': item.recordId,
          'error': e.toString(),
        });
        continue;
      }

      if (payload.isEmpty) {
        await _database.updateSyncItemRetry(item.id);
        final nextRetryCount = item.retryCount + 1;
        await _upsertOutboundJournal(
          clientOpId: _clientOpIdForQueueItem(item),
          operation: item.operation,
          entityTable: item.entityTable,
          recordId: item.recordId,
          status: _journalRetryStatus(nextRetryCount),
          createdAt: item.createdAt,
          payload: item.data,
          errorReason: 'Queued payload resolved to an empty map.',
          retryCount: nextRetryCount,
        );
        await _appendActivityLog('queue_payload_invalid', {
          'queueId': item.id,
          'entity': item.entityTable,
          'recordId': item.recordId,
        });
        continue;
      }

      payload.putIfAbsent('id', () => item.recordId);

      // Use the actual record's updatedAt (embedded in the payload) as the
      // LWW timestamp sent to the server. This ensures conflict resolution
      // compares real mutation times, not queue-insertion times.
        final recordUpdatedAt = (payload['updatedAt'] ?? payload['updated_at'])
          ?.toString()
          .trim();
        final payloadCreatedAt = (payload['createdAt'] ?? payload['created_at'])
          ?.toString()
          .trim();
        final shouldRepairLegacyUpdateTimestamp =
          item.operation != 'INSERT' &&
          recordUpdatedAt != null &&
          recordUpdatedAt.isNotEmpty &&
          payloadCreatedAt != null &&
          payloadCreatedAt.isNotEmpty &&
          recordUpdatedAt == payloadCreatedAt;
        final updatedAtToSend =
          shouldRepairLegacyUpdateTimestamp
          ? item.createdAt.toUtc().toIso8601String()
          : (recordUpdatedAt != null && recordUpdatedAt.isNotEmpty)
          ? recordUpdatedAt
          : item.createdAt.toUtc().toIso8601String();
        if (shouldRepairLegacyUpdateTimestamp) {
        payload['updatedAt'] = updatedAtToSend;
        }

      final action = item.operation == 'DELETE' ? 'DELETE' : 'UPSERT';
      final clientOpId = _clientOpIdForQueueItem(item);
      queuedByClientOpId[clientOpId] = item;
      ops.add({
        'client_op_id': clientOpId,
        'entity': item.entityTable,
        'entity_id': item.recordId,
        'action': action,
        'payload': payload,
        'updated_at': updatedAtToSend,
      });
    }

    if (ops.isEmpty) return;

    late final Response<dynamic> response;
    try {
      response = await _apiClient.post('/sync/push', data: {'operations': ops});
    } on DioException catch (e) {
      final failureReason = _mapDioFailure(e);
      for (final item in queuedByClientOpId.values) {
        await _database.updateSyncItemRetry(item.id);
        final nextRetryCount = item.retryCount + 1;
        await _upsertOutboundJournal(
          clientOpId: _clientOpIdForQueueItem(item),
          operation: item.operation,
          entityTable: item.entityTable,
          recordId: item.recordId,
          status: _journalRetryStatus(nextRetryCount),
          createdAt: item.createdAt,
          payload: item.data,
          errorReason: failureReason,
          retryCount: nextRetryCount,
        );
      }
      rethrow;
    }

    // The server returns 200 on full success and 500 (with a partial accepted
    // array) when a MongoDB error occurs mid-loop. In both cases we process
    // the accepted acks so already-committed ops are not retried. If the
    // status is not 200 we still throw after processing acks so the overall
    // sync run is marked as failed and the caller can surface the error.
    final isServerError =
        response.statusCode != null && response.statusCode! >= 500;
    final isClientError =
        response.statusCode != null &&
        response.statusCode! >= 400 &&
        response.statusCode! < 500;

    if (isClientError) {
      // 4xx means the whole request was rejected (e.g. 401, 422).
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Unexpected status code during push: ${response.statusCode}',
        type: DioExceptionType.badResponse,
      );
    }

    final data = _toMap(response.data);
    final accepted = (data['accepted'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final ackedClientOpIds = <String>{};

    for (final ack in accepted) {
      final clientOpId = (ack['client_op_id'] ?? '').toString();
      if (clientOpId.isEmpty) continue;
      ackedClientOpIds.add(clientOpId);

      final queueItem =
          queuedByClientOpId[clientOpId] ??
          await _database.getSyncItemByClientOpId(clientOpId);
      if (queueItem == null) continue;

      final action = (ack['action'] ?? '').toString().trim().toUpperCase();

      final isAccepted = ack['accepted'] == true;
      if (isAccepted) {
        await _database.deleteSyncItem(queueItem.id);
        final hasMorePendingForRecord = await _database
            .hasQueuedSyncItemForRecord(
              queueItem.entityTable,
              queueItem.recordId,
            );
        if (action != 'DELETE' && !hasMorePendingForRecord) {
          await _markLocalRecordSynced(
            queueItem.entityTable,
            queueItem.recordId,
          );
        }
        await _upsertOutboundJournal(
          clientOpId: clientOpId,
          operation: queueItem.operation,
          entityTable: queueItem.entityTable,
          recordId: queueItem.recordId,
          status: 'acknowledged',
          createdAt: queueItem.createdAt,
          payload: queueItem.data,
          serverSeq: (ack['seq'] as num?)?.toInt(),
          retryCount: queueItem.retryCount,
        );
        await _appendActivityLog('push_ack_accepted', {
          'queueId': queueItem.id,
          'clientOpId': clientOpId,
          'entity': ack['entity'],
          'entityId': ack['entity_id'],
          'action': ack['action'],
          'seq': ack['seq'],
        });
      } else {
        // Check whether the server rejected due to a conflict (another device
        // has a newer timestamp) or due to a transient/validation error.
        // For conflicts: delete the local pending item — _pullChanges() will
        // apply the server's authoritative state so retrying would never succeed.
        // For other errors: update retry count+timestamp so back-off is measured
        // from the actual send time, not the queue-insertion time.
        final reason = ack['reason']?.toString() ?? '';
        final isConflict = reason == 'conflict';
        if (isConflict) {
          await _database.deleteSyncItem(queueItem.id);
          await _upsertOutboundJournal(
            clientOpId: clientOpId,
            operation: queueItem.operation,
            entityTable: queueItem.entityTable,
            recordId: queueItem.recordId,
            status: 'conflict',
            createdAt: queueItem.createdAt,
            payload: queueItem.data,
            errorReason:
                'Server rejected this change because a newer version already exists.',
            retryCount: queueItem.retryCount,
          );
          await _appendActivityLog('push_ack_conflict', {
            'queueId': queueItem.id,
            'clientOpId': clientOpId,
            'entity': ack['entity'],
            'entityId': ack['entity_id'],
            'action': ack['action'],
          });
        } else {
          // Use updateSyncItemRetry (not incrementRetryCount) to stamp the
          // actual failure time for correct exponential back-off calculation.
          await _database.updateSyncItemRetry(queueItem.id);
          final nextRetryCount = queueItem.retryCount + 1;
          await _upsertOutboundJournal(
            clientOpId: clientOpId,
            operation: queueItem.operation,
            entityTable: queueItem.entityTable,
            recordId: queueItem.recordId,
            status: _journalRetryStatus(nextRetryCount),
            createdAt: queueItem.createdAt,
            payload: queueItem.data,
            errorReason: reason,
            retryCount: nextRetryCount,
          );
          await _appendActivityLog('push_ack_rejected', {
            'queueId': queueItem.id,
            'clientOpId': clientOpId,
            'entity': ack['entity'],
            'entityId': ack['entity_id'],
            'action': ack['action'],
            'reason': reason,
          });
        }
      }
    }

    if (isServerError) {
      for (final entry in queuedByClientOpId.entries) {
        if (ackedClientOpIds.contains(entry.key)) continue;
        final item = entry.value;
        await _database.updateSyncItemRetry(item.id);
        final nextRetryCount = item.retryCount + 1;
        await _upsertOutboundJournal(
          clientOpId: entry.key,
          operation: item.operation,
          entityTable: item.entityTable,
          recordId: item.recordId,
          status: _journalRetryStatus(nextRetryCount),
          createdAt: item.createdAt,
          payload: item.data,
          errorReason:
              'Server error during push. The operation will be retried.',
          retryCount: nextRetryCount,
        );
      }

      // Acks were processed above; now surface the error so the sync run is
      // marked failed and the remaining un-acked ops are retried next cycle.
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Server error during push: ${response.statusCode}',
        type: DioExceptionType.badResponse,
      );
    }

    // NOTE: Do NOT advance _lastSeq from the push response's latest_seq here.
    // The push response's latest_seq reflects the seq of THIS device's just-pushed
    // operations. If another device made changes while this device was offline,
    // those changes have lower seq numbers. Advancing seq here would cause
    // _pullChanges() to miss all those changes entirely.
    // _pullChanges() already correctly updates _lastSeq after pulling all events.
  }

  /// Returns whether the retry back-off window has elapsed for a queued item.
  ///
  /// Backoff is measured from [SyncQueueData.lastRetryAt] (the time of the
  /// most-recent send attempt). If no attempt has been made yet, the item is
  /// always eligible. The schedule is exponential, clamped to 5 s – 300 s.
  bool _isRetryWindowOpen(db.SyncQueueData item) {
    if (item.retryCount <= 0) return true;

    // Exponential back-off: 5 * 2^retryCount seconds, max 300 s.
    // Measured from lastRetryAt (actual send time) so an item that was first
    // queued long ago but only recently failed still gets the full window.
    final backoffSeconds = (5 * (1 << item.retryCount)).clamp(5, 300);
    final baseline = item.lastRetryAt ?? item.createdAt;
    final nextTryAt = baseline.add(Duration(seconds: backoffSeconds));
    return DateTime.now().isAfter(nextTryAt);
  }

  Future<void> queueOperation(
    String operation,
    String entityTable,
    String recordId,
    Map<String, dynamic> data, {
    bool triggerSync = true,
  }) async {
    if (_isDisposed) return;
    final queuedAt = DateTime.now().toUtc();
    final prefs = await SharedPreferences.getInstance();
    final deviceId = (prefs.getString('device_id') ?? '').trim();
    final normalizedPayload = Map<String, dynamic>.from(data);
    final createdAtValue = (normalizedPayload['createdAt'] ?? '')
      .toString()
      .trim();
    final updatedAtValue = (normalizedPayload['updatedAt'] ?? '')
      .toString()
      .trim();

    normalizedPayload['id'] = recordId;
    normalizedPayload['_id'] = recordId;
    normalizedPayload['createdAt'] = createdAtValue.isEmpty
      ? queuedAt.toIso8601String()
      : createdAtValue;
    normalizedPayload['updatedAt'] = updatedAtValue.isEmpty
      ? queuedAt.toIso8601String()
      : updatedAtValue;
    normalizedPayload['synced'] = false;
    normalizedPayload['isSynced'] = false;
    if (deviceId.isNotEmpty) {
      normalizedPayload['deviceId'] = deviceId;
    }
    final clientOpId = _generateClientOpId(operation, entityTable, recordId);

    final syncItem = db.SyncQueueCompanion(
      operation: Value(operation),
      entityTable: Value(entityTable),
      recordId: Value(recordId),
      clientOpId: Value(clientOpId),
      data: Value(jsonEncode(normalizedPayload)),
      createdAt: Value(queuedAt),
    );

    // Keep the queue append-only so the server journal can record every local
    // action in order, even when the same record is edited repeatedly offline.
    final queuedItem = await _database.enqueueSyncItem(syncItem);
    await _upsertOutboundJournal(
      clientOpId: _clientOpIdForQueueItem(queuedItem),
      operation: queuedItem.operation,
      entityTable: queuedItem.entityTable,
      recordId: queuedItem.recordId,
      status: 'queued',
      createdAt: queuedItem.createdAt,
      payload: queuedItem.data,
      retryCount: queuedItem.retryCount,
    );
    await _appendActivityLog('queue_operation', {
      'operation': operation,
      'entity': entityTable,
      'recordId': recordId,
      'clientOpId': _clientOpIdForQueueItem(queuedItem),
    });
    if (triggerSync && _autoSyncSuppressionDepth == 0) {
      unawaited(syncAllData());
    }
  }

  Future<List<db.SyncQueueData>> getPendingQueue() {
    if (_isDisposed) {
      return Future.value(<db.SyncQueueData>[]);
    }
    // Use the same maxRetries filter as _uploadPendingChanges so callers
    // (e.g. the sync-badge counter in the UI) only see actionable items,
    // not permanently-failed ones that will never be sent.
    return _database.getPendingSyncItems(maxRetries: _maxRetryCount);
  }

  /// Registers a callback that runs after HTTP sync polling applies remote
  /// changes to the local workspace state.
  Future<void> startChangeListener(void Function() onRemoteDataApplied) async {
    if (_isDisposed) return;
    _onRemoteDataApplied = onRemoteDataApplied;
    await syncAllData();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _connectivitySub?.cancel();
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }
}
