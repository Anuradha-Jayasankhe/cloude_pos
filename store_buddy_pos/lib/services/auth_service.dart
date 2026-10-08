import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  static const String _platformTenantId = 'platform';
  static const String _deviceIdKey = 'device_id';
  static const String _cachedEmailKey = 'cached_login_email';
  static const String _cachedPasswordKey = 'cached_login_password';
  static const String _activationCodeKey = 'activation_code';
  static const String _activationTenantIdKey = 'activated_tenant_id';
  static const String _activationStoreNameKey = 'activated_store_name';
  final _random = Random();
  String? _lastActionError;

  AuthService(this._apiClient);

  String? get lastActionError => _lastActionError;

  void _setError(String? message) {
    _lastActionError = message;
  }

  Future<User> _storeOfflineTrialSession({
    required String tenantId,
    required String storeName,
    required String ownerEmail,
    required String ownerPassword,
    required String ownerName,
    required DateTime trialEndsAt,
    bool isOfflineMode = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User(
      id: 'trial-owner-$tenantId',
      tenantId: tenantId,
      name: ownerName.trim().isEmpty ? storeName : ownerName.trim(),
      email: ownerEmail,
      role: 'manager',
      isActive: true,
      locationIds: const ['main'],
      maxLocations: 100,
    );

    await _storeSessionUser(user, 'store-session-token-$tenantId');
    await prefs.setString(_cachedEmailKey, ownerEmail);
    await prefs.setString(_cachedPasswordKey, ownerPassword);
    await prefs.setString(_activationTenantIdKey, tenantId);
    await prefs.setString(_activationStoreNameKey, storeName);
    await prefs.setString('trial_ends_at', trialEndsAt.toIso8601String());
    await prefs.setBool('is_offline_mode', isOfflineMode);
    await prefs.setString(
      'subscription_info',
      jsonEncode({
        'plan_id': isOfflineMode ? 'offline' : 'trial',
        'plan_name': isOfflineMode ? 'Offline Standalone' : 'Trial',
        'status': isOfflineMode ? 'OFFLINE' : 'TRIAL',
        'sync_enabled': !isOfflineMode,
        'plan_expires_at': trialEndsAt.toIso8601String(),
        'is_offline_mode': isOfflineMode,
      }),
    );

    return user;
  }

  Future<void> _storeSessionUser(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('refresh_token', 'local-refresh-token');
    await prefs.setString('user_data', jsonEncode(user.toJson()));

    if (user.tenantId != _platformTenantId) {
      await prefs.setString('tenant_id', user.tenantId);
    } else {
      await prefs.remove('tenant_id');
    }
  }

  Future<void> _storeCachedCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedEmailKey, email);
    await prefs.setString(_cachedPasswordKey, password);
  }

  Future<({String email, String password})?> getCachedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_cachedEmailKey) ?? '';
    final password = prefs.getString(_cachedPasswordKey) ?? '';
    if (email.isEmpty || password.isEmpty) return null;
    return (email: email, password: password);
  }

  bool _isConnectivityFailure(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  Future<User?> _loginWithServer(
    String email,
    String password, {
    String? tenantId,
    String? displayNameHint,
  }) async {
    await _apiClient.autoDetectEnvironment();
    final deviceId = await _getOrCreateDeviceId();
    final prefs = await SharedPreferences.getInstance();
    final savedDeviceLabel = (prefs.getString('device_label') ?? '').trim();
    final deviceName = savedDeviceLabel.isEmpty
        ? 'Store Buddy POS'
        : savedDeviceLabel;
    final response = await _apiClient.post(
      '/auth/login',
      data: {
        'tenant_id': tenantId,
        'email': email,
        'password': password,
        'device_id': deviceId,
        'device_name': deviceName,
      },
    );

    if (response.statusCode != 200) return null;

    final data = Map<String, dynamic>.from(response.data as Map);
    final resolvedTenantId = (data['tenant_id'] ?? '').toString();
    final role = (data['role'] ?? 'manager').toString();
    final userId = (data['user_id'] ?? '').toString();
    final token = (data['access_token'] ?? '').toString();
    final locationIds =
        (data['location_ids'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item.toString())
            .toList();
    final maxLocations = (data['max_locations'] as num?)?.toInt() ?? 100;

    if (resolvedTenantId.isEmpty || token.isEmpty || userId.isEmpty) {
      return null;
    }

    final user = User(
      id: userId,
      tenantId: resolvedTenantId,
      name: (displayNameHint == null || displayNameHint.trim().isEmpty)
          ? email.split('@').first
          : displayNameHint,
      email: email,
      role: role,
      isActive: true,
      locationIds: locationIds,
      maxLocations: maxLocations,
    );
    await _storeSessionUser(user, token);

    // Persist subscription/plan info for display in Sync Manager
    try {
      final planId = (data['plan_id'] ?? 'trial').toString();
      final planName = (data['plan_name'] ?? 'Trial').toString();
      final planStatus = (data['status'] ?? 'TRIAL').toString().toUpperCase();
      final syncEnabled = data['sync_enabled'] as bool? ?? true;
      final planExpiresAt =
          (data['plan_expires_at'] ?? data['trial_ends_at'] ?? '').toString();
      final subscriptionInfo = jsonEncode({
        'plan_id': planId,
        'plan_name': planName,
        'status': planStatus,
        'sync_enabled': syncEnabled,
        'plan_expires_at': planExpiresAt.isEmpty ? null : planExpiresAt,
      });
      await prefs.setString('subscription_info', subscriptionInfo);
      if (planExpiresAt.isNotEmpty) {
        await prefs.setString('trial_ends_at', planExpiresAt);
      }
    } catch (_) {
      // Non-critical — subscription display can fall back to defaults
    }

    // Update activation tenant ID and store name to match the authenticated user's tenant
    if (resolvedTenantId != _platformTenantId) {
      await prefs.setString(_activationTenantIdKey, resolvedTenantId);
      final storeName = (data['store_name'] ?? '').toString().trim();
      if (storeName.isNotEmpty) {
        await prefs.setString(_activationStoreNameKey, storeName);
      } else {
        await prefs.setString(
          _activationStoreNameKey,
          resolvedTenantId.replaceAll('-', ' ').toUpperCase(),
        );
      }
    }

    return user;
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random();
    final newId =
        'dev-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1 << 20)}';
    await prefs.setString(_deviceIdKey, newId);
    return newId;
  }

  Future<({String tenantId, String storeName, DateTime? trialEndsAt})?>
  activateDeviceWithCode(
    String activationCode, {
    required String deviceLabel,
  }) async {
    _setError(null);
    final normalizedCode = activationCode.trim().toUpperCase();
    final normalizedLabel = deviceLabel.trim();

    if (normalizedCode.isEmpty || normalizedLabel.isEmpty) {
      _setError('Activation code and device label are required.');
      return null;
    }

    if (normalizedCode.startsWith('SBOFF-')) {
      final offlineRes = validateOfflineLicenseKey(normalizedCode);
      if (offlineRes['valid'] == true) {
        if (offlineRes['expired'] == true) {
          _setError('License key has expired.');
          return null;
        }
        final String tenantId = offlineRes['tenantId'];
        final String planId = offlineRes['planId'];
        final DateTime expiryDate = offlineRes['expiryDate'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_activationCodeKey, normalizedCode);
        await prefs.setString(_activationTenantIdKey, tenantId);
        await prefs.setString('tenant_id', tenantId);
        await prefs.setString(
          _activationStoreNameKey,
          'Store ${tenantId.toUpperCase()}',
        );
        await prefs.setString('device_label', normalizedLabel);

        final subscriptionInfo = jsonEncode({
          'plan_id': planId,
          'plan_name': planId.toUpperCase(),
          'status': 'OFFLINE',
          'sync_enabled': false,
          'plan_expires_at': expiryDate.toIso8601String(),
        });
        await prefs.setString('subscription_info', subscriptionInfo);
        await prefs.setString('trial_ends_at', expiryDate.toIso8601String());

        final defaultUser = User(
          id: 'offline-owner',
          tenantId: tenantId,
          name: 'Offline Owner',
          email: 'owner@storebuddy.local',
          role: 'owner',
          isActive: true,
          locationIds: ['main'],
          maxLocations: 100,
        );
        await prefs.setString('user_data', jsonEncode(defaultUser.toJson()));
        await prefs.setString('auth_token', 'store-session-token-$tenantId');
        await prefs.setString('refresh_token', 'local-refresh-token');

        await prefs.setString(_cachedEmailKey, 'owner@storebuddy.local');
        await prefs.setString(_cachedPasswordKey, 'offline');

        return (
          tenantId: tenantId,
          storeName: 'Store ${tenantId.toUpperCase()}',
          trialEndsAt: expiryDate,
        );
      } else {
        _setError(offlineRes['reason'] ?? 'Invalid license key.');
        return null;
      }
    }

    try {
      await _apiClient.autoDetectEnvironment();
      final deviceId = await _getOrCreateDeviceId();
      final response = await _apiClient.post(
        '/auth/activate-device',
        data: {
          'activation_code': normalizedCode,
          'device_id': deviceId,
          'device_name': normalizedLabel,
        },
      );

      if (response.statusCode != 200) {
        _setError('Activation failed. Please check your code.');
        return null;
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      final tenantId = (data['tenant_id'] ?? '').toString().trim();
      final storeName = (data['store_name'] ?? '').toString().trim();
      final trialEndsRaw = (data['trial_ends_at'] ?? '').toString().trim();
      final trialEndsAt = trialEndsRaw.isEmpty
          ? null
          : DateTime.tryParse(trialEndsRaw);

      if (tenantId.isEmpty) {
        _setError('Activation response is missing tenant id.');
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activationCodeKey, normalizedCode);
      await prefs.setString(_activationTenantIdKey, tenantId);
      await prefs.setString(_activationStoreNameKey, storeName);
      await prefs.setString('device_label', normalizedLabel);

      return (
        tenantId: tenantId,
        storeName: storeName,
        trialEndsAt: trialEndsAt,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (_isConnectivityFailure(e)) {
        _setError(
          'Cannot reach server. Check internet connection and API URL.',
        );
      } else if (status == 401) {
        _setError('Invalid activation code.');
      } else if (status == 403) {
        _setError('Trial expired. Contact platform admin to reactivate.');
      } else if (status == 404) {
        _setError('Activation code does not match an active store.');
      } else {
        _setError('Activation failed. Please try again.');
      }
      return null;
    } catch (_) {
      _setError('Activation failed. Please try again.');
      return null;
    }
  }

  Future<User?> login(
    String email,
    String password, {
    bool isPlatform = false,
  }) async {
    _setError(null);
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      _setError('Email and password are required.');
      return null;
    }

    if (isPlatform) {
      try {
        final platformUser = await _loginWithServer(
          normalizedEmail,
          normalizedPassword,
          tenantId: _platformTenantId,
          displayNameHint: 'Platform Admin',
        );
        if (platformUser == null ||
            platformUser.role.toLowerCase() != 'platform_admin') {
          _setError('Invalid platform admin credentials.');
          return null;
        }
        return platformUser;
      } on DioException catch (e) {
        if (_isConnectivityFailure(e)) {
          _setError(
            'Cannot reach server. Check internet connection and API URL.',
          );
        } else {
          _setError('Invalid platform admin credentials.');
        }
        return null;
      } catch (_) {
        _setError('Could not sign in right now.');
        return null;
      }
    }

    bool sawConnectivityFailure = false;
    String? serverErrorMsg;

    final prefs = await SharedPreferences.getInstance();
    final activatedTenantId = (prefs.getString(_activationTenantIdKey) ?? '')
        .trim()
        .toLowerCase();
    final subscriptionInfoRaw = prefs.getString('subscription_info') ?? '';
    String sessionStatus = '';
    if (subscriptionInfoRaw.isNotEmpty) {
      try {
        final subscriptionInfo = Map<String, dynamic>.from(
          jsonDecode(subscriptionInfoRaw) as Map,
        );
        sessionStatus = (subscriptionInfo['status'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
      } catch (_) {}
    }
    final authToken = (prefs.getString('auth_token') ?? '').trim();
    final cached = await getCachedCredentials();
    final userDataRaw = prefs.getString('user_data');

    if ((authToken.startsWith('store-session-token-') ||
            sessionStatus == 'TRIAL' ||
            sessionStatus == 'OFFLINE') &&
        userDataRaw != null) {
      try {
        final localUser = User.fromJson(jsonDecode(userDataRaw));
        final storedEmail = localUser.email.trim().toLowerCase();
        if (storedEmail == normalizedEmail ||
            (cached != null && cached.email == normalizedEmail)) {
          return localUser;
        }
      } catch (_) {}
    }

    if ((authToken.startsWith('store-session-token-') ||
            sessionStatus == 'TRIAL' ||
            sessionStatus == 'OFFLINE') &&
        cached != null &&
        cached.email == normalizedEmail &&
        cached.password == normalizedPassword) {
      if (userDataRaw != null) {
        return User.fromJson(jsonDecode(userDataRaw));
      }
    }

    // 1. Default offline owner fallback bypass
    if (normalizedEmail == 'owner@storebuddy.local' &&
        normalizedPassword == 'offline') {
      final defaultUser = User(
        id: 'offline-owner',
        tenantId: activatedTenantId.isNotEmpty ? activatedTenantId : 'offline',
        name: 'Offline Owner',
        email: 'owner@storebuddy.local',
        role: 'owner',
        isActive: true,
        locationIds: const ['main'],
        maxLocations: 100,
      );
      await _storeSessionUser(
        defaultUser,
        'store-session-token-${defaultUser.tenantId}',
      );
      await _storeCachedCredentials(normalizedEmail, normalizedPassword);
      return defaultUser;
    }

    // 2. Try online login first if we can
    // Check tenant specific login
    if (activatedTenantId.isNotEmpty) {
      try {
        final activatedUser = await _loginWithServer(
          normalizedEmail,
          normalizedPassword,
          tenantId: activatedTenantId,
          displayNameHint: null,
        );
        if (activatedUser != null) {
          await _storeCachedCredentials(normalizedEmail, normalizedPassword);
          return activatedUser;
        }
      } on DioException catch (e) {
        if (_isConnectivityFailure(e)) {
          sawConnectivityFailure = true;
        } else {
          serverErrorMsg = e.response?.data is Map
              ? (e.response?.data['detail'] ??
                        e.response?.data['message'] ??
                        'Invalid credentials')
                    .toString()
              : 'Invalid credentials';
          _setError(serverErrorMsg);
        }
      } catch (e) {
        // Other unexpected errors
      }
    }

    // Try general login if tenant not specific or didn't return user, or if tenant login failed with invalid credentials
    if (!sawConnectivityFailure &&
        (serverErrorMsg == null ||
            serverErrorMsg.toLowerCase().contains('invalid credential'))) {
      try {
        final user = await _loginWithServer(
          normalizedEmail,
          normalizedPassword,
          tenantId: null,
          displayNameHint: null,
        );
        if (user != null) {
          _setError(null);
          await _storeCachedCredentials(normalizedEmail, normalizedPassword);
          return user;
        }
      } on DioException catch (e) {
        if (_isConnectivityFailure(e)) {
          sawConnectivityFailure = true;
        } else {
          // If we got a real error (like 401/403) from general login, try platform login fallback before throwing.
          final statusCode = e.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            // Attempt platform admin login fallback
            try {
              final platformUser = await _loginWithServer(
                normalizedEmail,
                normalizedPassword,
                tenantId: _platformTenantId,
                displayNameHint: 'Platform Admin',
              );
              if (platformUser != null &&
                  platformUser.role.toLowerCase() == 'platform_admin') {
                await _storeCachedCredentials(
                  normalizedEmail,
                  normalizedPassword,
                );
                return platformUser;
              }
            } on DioException catch (pe) {
              if (_isConnectivityFailure(pe)) {
                sawConnectivityFailure = true;
              } else {
                serverErrorMsg = pe.response?.data is Map
                    ? (pe.response?.data['detail'] ??
                              pe.response?.data['message'] ??
                              'Invalid credentials')
                          .toString()
                    : 'Invalid credentials';
                _setError(serverErrorMsg);
              }
            } catch (_) {}
          } else {
            serverErrorMsg = e.response?.data is Map
                ? (e.response?.data['detail'] ??
                          e.response?.data['message'] ??
                          'Invalid credentials')
                      .toString()
                : 'Invalid credentials';
            _setError(serverErrorMsg);
          }
        }
      } catch (_) {}
    }

    // 3. Fallback to cached/offline credentials when they match the local session.
    if (cached != null &&
        cached.email == normalizedEmail &&
        cached.password == normalizedPassword) {
      final userData = prefs.getString('user_data');
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
    }

    if (sawConnectivityFailure) {
      _setError('Cannot reach server. Check internet connection and API URL.');
      return null;
    }

    if (serverErrorMsg != null) {
      _setError(serverErrorMsg);
    } else {
      _setError('Invalid credentials.');
    }
    return null;
  }

  Future<bool> createStoreLogin({
    required String storeName,
    required String tenantId,
    required String email,
    required String password,
    String role = 'manager',
    String? userName,
    DateTime? trialStartsAt,
    DateTime? trialEndsAt,
  }) async {
    _setError(null);
    await _apiClient.autoDetectEnvironment();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedTenantId = tenantId.trim().toLowerCase();

    if (storeName.trim().isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedTenantId.isEmpty ||
        password.trim().isEmpty) {
      _setError('Store name, owner email, and password are required.');
      return false;
    }

    var attemptTenantId = normalizedTenantId;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _apiClient.post(
          '/auth/register-store',
          data: {
            'store_name': storeName,
            'tenant_id': attemptTenantId,
            'owner_name': userName ?? storeName,
            'owner_email': normalizedEmail,
            'password': password,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          break;
        }

        if (response.statusCode != null) {
          _setError('Could not create trial account right now.');
          return false;
        }
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final detail = (e.response?.data is Map)
            ? (e.response?.data['detail'] ?? '').toString().toLowerCase()
            : '';

        if (statusCode == 409 && detail.contains('tenant id already exists')) {
          _setError(
            'Shop ID already exists. Choose a different shop ID and try again.',
          );
          return false;
        }

        if (statusCode == 409 && detail.contains('email already exists')) {
          _setError(
            'This email is already used by another account. Use another email or sign in.',
          );
          return false;
        }

        if (!_isConnectivityFailure(e) && statusCode != null) {
          final serverDetail = (e.response?.data is Map)
              ? (e.response?.data['detail'] ??
                      e.response?.data['message'] ??
                      e.response?.data['error'] ??
                      '')
                  .toString()
                  .trim()
              : '';
          if (serverDetail.isNotEmpty) {
            _setError(serverDetail);
          } else if (statusCode >= 500) {
            _setError('Server error ($statusCode). Please verify server is running.');
          } else {
            _setError('Could not create trial account. Please check your details.');
          }
          return false;
        }

        _setError(
          'Cannot reach server. Check internet connection and API URL.',
        );
        return false;
      } catch (_) {
        _setError('Could not create trial account right now.');
        return false;
      }

      if (attempt == 2) {
        _setError('Could not create unique shop ID. Please try again.');
        return false;
      }
    }
    return true;
  }

  Future<String?> createTenantUserLogin({
    required String tenantId,
    required String email,
    required String password,
    required String role,
    List<String> locationIds = const <String>[],
    bool active = true,
    String? userName,
  }) async {
    _setError(null);
    final normalizedTenantId = tenantId.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();
    final normalizedRole = role.trim().toLowerCase();
    final normalizedName = (userName ?? '').trim();

    if (normalizedTenantId.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPassword.isEmpty ||
        normalizedName.isEmpty) {
      _setError('Tenant, name, email and password are required.');
      return null;
    }

    try {
      final response = await _apiClient.post(
        '/auth/users',
        data: {
          'tenant_id': normalizedTenantId,
          'name': normalizedName,
          'email': normalizedEmail,
          'password': normalizedPassword,
          'role': normalizedRole,
          'location_ids': locationIds,
          'active': active,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : const <String, dynamic>{};
        final userId = (responseData['user_id'] ?? '').toString().trim();
        if (userId.isNotEmpty) {
          return userId;
        }

        _setError('User login was created but server did not return user id.');
        return null;
      }

      _setError('Could not create user login right now.');
      return null;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final rawDetail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ??
                  e.response?.data['message'] ??
                  e.response?.data['error'] ??
                  '')
              .toString()
          : '';
      final detail = rawDetail.toLowerCase();
      final rawBody = e.response?.data?.toString().toLowerCase() ?? '';

      if (statusCode == 404 &&
          (rawBody.contains('cannot post /api/v1/auth/users') ||
              detail.contains('cannot post /api/v1/auth/users'))) {
        _setError(
          'Server needs update. Deploy latest backend to enable user login creation.',
        );
        return null;
      }

      if (statusCode == 409 ||
          detail.contains('email already exists') ||
          detail.contains('already in use')) {
        _setError(
          'This email is already used by another account. Use another email.',
        );
        return null;
      }

      if (statusCode == 404 && detail.contains('tenant not found')) {
        _setError('Tenant not found. Please refresh and try again.');
        return null;
      }

      if (statusCode == 401 ||
          detail.contains('token') ||
          detail.contains('unauthorized')) {
        _setError(
          'Server session token is invalid or expired. Created user locally. Please sign in again to sync.',
        );
        return null;
      }

      if (statusCode == 403 || detail.contains('not allowed')) {
        _setError('You are not allowed to create user logins.');
        return null;
      }

      if (rawDetail.trim().isNotEmpty) {
        _setError(rawDetail.trim());
        return null;
      }

      if (!_isConnectivityFailure(e) && statusCode != null) {
        _setError('Could not create user login (Server code $statusCode). Check details.');
        return null;
      }

      _setError('Cannot reach server. Check internet connection and API URL.');
      return null;
    } catch (_) {
      _setError('Could not create user login right now.');
      return null;
    }
  }

  Future<bool> updateTenantUserPassword({
    required String tenantId,
    required String email,
    required String password,
  }) async {
    _setError(null);
    final normalizedTenantId = tenantId.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedTenantId.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPassword.isEmpty) {
      _setError('Tenant, email and password are required.');
      return false;
    }

    try {
      final response = await _apiClient.post(
        '/auth/users/password',
        data: {
          'tenant_id': normalizedTenantId,
          'email': normalizedEmail,
          'password': normalizedPassword,
        },
      );

      if (response.statusCode == 200) {
        return true;
      }

      _setError('Could not update user password right now.');
      return false;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString().toLowerCase()
          : '';

      final rawBody = e.response?.data?.toString().toLowerCase() ?? '';

      if (statusCode == 404 &&
          (rawBody.contains('cannot post /api/v1/auth/users/password') ||
              detail.contains('cannot post /api/v1/auth/users/password'))) {
        _setError(
          'Server needs update. Deploy latest backend to enable password updates.',
        );
        return false;
      }

      if (statusCode == 404 && detail.contains('user not found')) {
        _setError('User login not found on server.');
        return false;
      }

      if (statusCode == 403) {
        _setError('You are not allowed to update user credentials.');
        return false;
      }

      if (!_isConnectivityFailure(e) && statusCode != null) {
        _setError('Could not update user password. Please check details.');
        return false;
      }

      _setError('Cannot reach server. Check internet connection and API URL.');
      return false;
    } catch (_) {
      _setError('Could not update user password right now.');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getStoreLogins() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataRaw = prefs.getString('user_data') ?? '';
    if (userDataRaw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    Map<String, dynamic> userData;
    try {
      userData = Map<String, dynamic>.from(jsonDecode(userDataRaw) as Map);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }

    final tenantId =
        (userData['tenantId'] ?? prefs.getString('tenant_id') ?? '')
            .toString()
            .trim();
    if (tenantId.isEmpty) return <Map<String, dynamic>>[];

    final storeName =
        (prefs.getString(_activationStoreNameKey) ??
                prefs.getString('store_name') ??
                userData['name'] ??
                'Trial Store')
            .toString()
            .trim();
    final email = (userData['email'] ?? prefs.getString(_cachedEmailKey) ?? '')
        .toString()
        .trim();
    final role = (userData['role'] ?? 'manager').toString().trim();
    final trialEndsAt = prefs.getString('trial_ends_at') ?? '';
    final subscriptionInfoRaw = prefs.getString('subscription_info') ?? '';
    String status = 'TRIAL';
    if (subscriptionInfoRaw.isNotEmpty) {
      try {
        final subscriptionInfo = Map<String, dynamic>.from(
          jsonDecode(subscriptionInfoRaw) as Map,
        );
        status = (subscriptionInfo['status'] ?? status).toString().trim();
      } catch (_) {}
    }

    return <Map<String, dynamic>>[
      {
        'tenant_id': tenantId,
        'tenantId': tenantId,
        'store_name': storeName,
        'storeName': storeName,
        'owner_email': email,
        'email': email,
        'owner_name': userData['name'] ?? storeName,
        'name': userData['name'] ?? storeName,
        'role': role,
        'status': status.isEmpty ? 'TRIAL' : status,
        'trial_ends_at': trialEndsAt,
        'trialEndsAt': trialEndsAt,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getPlatformStores() async {
    final response = await _apiClient.get('/auth/platform/stores');
    if (response.statusCode != 200) return <Map<String, dynamic>>[];

    final rows = (response.data as List<dynamic>?) ?? const <dynamic>[];
    return rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<bool> reactivateStoreTrial({
    required String tenantId,
    int days = 7,
    DateTime? trialEndsAt,
  }) async {
    final normalizedTenantId = tenantId.trim().toLowerCase();
    if (normalizedTenantId.isEmpty) return false;

    final data = {
      'days': days,
      if (trialEndsAt != null) 'trialEndsAt': trialEndsAt.toIso8601String(),
    };
    final response = await _apiClient.post(
      '/auth/platform/stores/$normalizedTenantId/trial/reactivate',
      data: data,
    );
    return response.statusCode == 200;
  }

  Future<bool> deactivatePlatformStore({required String tenantId}) async {
    _setError(null);
    final normalizedTenantId = tenantId.trim().toLowerCase();
    if (normalizedTenantId.isEmpty) return false;

    try {
      final response = await _apiClient.post(
        '/auth/platform/stores/$normalizedTenantId/deactivate',
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        _setError('Store not found. Refresh and try again.');
        return false;
      }
      if (statusCode == 403) {
        _setError('You are not allowed to deactivate stores.');
        return false;
      }
      if (!_isConnectivityFailure(e) && statusCode != null) {
        _setError('Could not deactivate store right now.');
        return false;
      }
      _setError('Cannot reach server. Check internet connection and API URL.');
      return false;
    } catch (_) {
      _setError('Could not deactivate store right now.');
      return false;
    }
  }

  Future<bool> updatePlatformStore({
    required String tenantId,
    required String storeName,
    required String ownerEmail,
    String? ownerName,
    int? maxLocations,
    int? maxUsers,
    int? maxProducts,
  }) async {
    _setError(null);
    final normalizedTenantId = tenantId.trim().toLowerCase();
    final normalizedStoreName = storeName.trim();
    final normalizedOwnerEmail = ownerEmail.trim().toLowerCase();
    final normalizedOwnerName = (ownerName ?? '').trim();

    if (normalizedTenantId.isEmpty ||
        normalizedStoreName.isEmpty ||
        normalizedOwnerEmail.isEmpty) {
      _setError('Tenant id, store name and owner email are required.');
      return false;
    }

    try {
      final response = await _apiClient.patch(
        '/auth/platform/stores/$normalizedTenantId',
        data: {
          'store_name': normalizedStoreName,
          'owner_email': normalizedOwnerEmail,
          if (normalizedOwnerName.isNotEmpty) 'owner_name': normalizedOwnerName,
          if (maxLocations != null) 'max_locations': maxLocations,
          if (maxUsers != null) 'max_users': maxUsers,
          if (maxProducts != null) 'max_products': maxProducts,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString().toLowerCase()
          : '';

      if (statusCode == 404) {
        _setError('Store not found. Refresh and try again.');
        return false;
      }
      if (statusCode == 409 && detail.contains('email already exists')) {
        _setError('Email already exists. Use a different owner email.');
        return false;
      }
      if (statusCode == 403) {
        _setError('You are not allowed to update stores.');
        return false;
      }
      if (!_isConnectivityFailure(e) && statusCode != null) {
        _setError('Could not update store right now.');
        return false;
      }

      _setError('Cannot reach server. Check internet connection and API URL.');
      return false;
    } catch (_) {
      _setError('Could not update store right now.');
      return false;
    }
  }

  Future<bool> deletePlatformStore({required String tenantId}) async {
    _setError(null);
    final normalizedTenantId = tenantId.trim().toLowerCase();
    if (normalizedTenantId.isEmpty) {
      _setError('Tenant id is required.');
      return false;
    }

    try {
      final response = await _apiClient.delete(
        '/auth/platform/stores/$normalizedTenantId',
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        _setError('Store not found. Refresh and try again.');
        return false;
      }
      if (statusCode == 403) {
        _setError('You are not allowed to delete stores.');
        return false;
      }
      if (!_isConnectivityFailure(e) && statusCode != null) {
        _setError('Could not delete store right now.');
        return false;
      }

      _setError('Cannot reach server. Check internet connection and API URL.');
      return false;
    } catch (_) {
      _setError('Could not delete store right now.');
      return false;
    }
  }

  Future<bool> hasAnyStoreLogins() async {
    final logins = await getStoreLogins();
    return logins.isNotEmpty;
  }

  Future<bool> createTrialStoreOwner({
    required String storeName,
    required String ownerEmail,
    required String ownerPassword,
    String? ownerName,
    bool isOfflineOnly = false,
  }) async {
    _setError(null);
    await _apiClient.autoDetectEnvironment();
    final normalizedStore = storeName.trim();
    final normalizedEmail = ownerEmail.trim().toLowerCase();
    final normalizedPassword = ownerPassword.trim();

    if (normalizedStore.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPassword.isEmpty) {
      _setError('Store name, owner email, and password are required.');
      return false;
    }

    final tenantSlug = normalizedStore
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final prefix = isOfflineOnly ? 'off' : 'trial';
    final tenantId = tenantSlug.isEmpty
        ? '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(10000)}'
        : '$tenantSlug-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(10000)}';

    final trialStart = DateTime.now();
    final trialEnd = trialStart.add(const Duration(days: 7));

    // If Offline Standalone selected explicitly
    if (isOfflineOnly) {
      await _storeOfflineTrialSession(
        tenantId: tenantId,
        storeName: normalizedStore,
        ownerEmail: normalizedEmail,
        ownerPassword: normalizedPassword,
        ownerName: (ownerName ?? '').trim().isEmpty
            ? normalizedStore
            : ownerName!.trim(),
        trialEndsAt: trialEnd,
        isOfflineMode: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_offline_mode', true);
      return true;
    }

    // 1. Try to create the store on the server first
    final registeredOnServer = await createStoreLogin(
      storeName: normalizedStore,
      tenantId: tenantId,
      email: normalizedEmail,
      password: normalizedPassword,
      userName: (ownerName ?? '').trim().isEmpty
          ? normalizedStore
          : ownerName!.trim(),
      trialStartsAt: trialStart,
      trialEndsAt: trialEnd,
    );

    if (!registeredOnServer) {
      // If server registration failed:
      // If it was a connectivity failure, fallback to offline local trial
      if (_lastActionError != null &&
          _lastActionError!.contains('Cannot reach server')) {
        await _storeOfflineTrialSession(
          tenantId: tenantId,
          storeName: normalizedStore,
          ownerEmail: normalizedEmail,
          ownerPassword: normalizedPassword,
          ownerName: (ownerName ?? '').trim().isEmpty
              ? normalizedStore
              : ownerName!.trim(),
          trialEndsAt: trialEnd,
          isOfflineMode: true,
        );
        _setError(null); // Clear server error since we fell back to offline
        return true;
      }
      // Otherwise, it was a real server error (conflict, email already exists, etc.), so fail!
      return false;
    }

    // 2. If server registration succeeded, login with the server to get a real token and setup session!
    final loggedInUser = await login(normalizedEmail, normalizedPassword);
    if (loggedInUser != null) {
      return true;
    }

    // If login failed for some reason, fallback to local trial session
    await _storeOfflineTrialSession(
      tenantId: tenantId,
      storeName: normalizedStore,
      ownerEmail: normalizedEmail,
      ownerPassword: normalizedPassword,
      ownerName: (ownerName ?? '').trim().isEmpty
          ? normalizedStore
          : ownerName!.trim(),
      trialEndsAt: trialEnd,
    );
    return true;
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isOffline = prefs.getBool('is_offline_mode') ?? false;

    // If online token exists and not strictly offline, query server
    final token = (prefs.getString('auth_token') ?? '').trim();
    if (token.isNotEmpty &&
        !token.startsWith('store-session-token-') &&
        !isOffline) {
      try {
        final res = await _apiClient.get('/auth/subscription-status');
        if (res.statusCode == 200 && res.data is Map) {
          final data = Map<String, dynamic>.from(res.data as Map);
          await prefs.setString('subscription_info', jsonEncode(data));
          if (data['plan_expires_at'] != null) {
            await prefs.setString(
              'trial_ends_at',
              data['plan_expires_at'].toString(),
            );
          }
          return data;
        }
      } catch (_) {
        // Fall back to local info
      }
    }

    // Read local subscription info
    final raw = prefs.getString('subscription_info') ?? '';
    Map<String, dynamic> info = {};
    if (raw.isNotEmpty) {
      try {
        info = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }

    final trialEndsRaw =
        info['plan_expires_at'] ?? prefs.getString('trial_ends_at') ?? '';
    DateTime? expiresAt = trialEndsRaw.toString().isNotEmpty
        ? DateTime.tryParse(trialEndsRaw.toString())
        : null;
    final now = DateTime.now();
    final isExpired = expiresAt != null && now.isAfter(expiresAt);

    return {
      'tenant_id': prefs.getString('tenant_id') ?? '',
      'store_name': prefs.getString(_activationStoreNameKey) ?? 'My Store',
      'status': isExpired
          ? 'EXPIRED'
          : (info['status'] ?? (isOffline ? 'OFFLINE' : 'TRIAL')),
      'plan_id': info['plan_id'] ?? (isOffline ? 'offline' : 'trial'),
      'plan_name': info['plan_name'] ??
          (isOffline ? 'Offline Standalone' : 'Free Trial'),
      'sync_enabled': !isOffline && (info['sync_enabled'] ?? true),
      'plan_expires_at': expiresAt?.toIso8601String(),
      'is_expired': isExpired,
      'hotline': '+94 72 954 5538',
      'support_email': 'contact@bizparkstudio.lk',
    };
  }

  Future<bool> activateOfflineLicense(String key) async {
    _setError(null);
    final res = validateOfflineLicenseKey(key);
    if (res['valid'] != true) {
      _setError(res['reason']?.toString() ?? 'Invalid license key format.');
      return false;
    }
    if (res['expired'] == true) {
      _setError('This offline license key has expired.');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final expiryDate = res['expiryDate'] as DateTime;
    final planId = res['planId'].toString();
    final tenantId = res['tenantId'].toString();

    await prefs.setString(_activationCodeKey, key.trim().toUpperCase());
    await prefs.setString('tenant_id', tenantId);
    await prefs.setString(
      'subscription_info',
      jsonEncode({
        'plan_id': planId,
        'plan_name': 'Offline Lifetime License',
        'status': 'OFFLINE',
        'sync_enabled': false,
        'plan_expires_at': expiryDate.toIso8601String(),
        'is_offline_mode': true,
      }),
    );
    await prefs.setString('trial_ends_at', expiryDate.toIso8601String());
    await prefs.setBool('is_offline_mode', true);
    return true;
  }

  Future<User?> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if (response.statusCode == 201) {
        return User.fromJson(response.data['user']);
      }
    } catch (_) {}

    return null;
  }

  Future<User?> getProfile() async {
    try {
      final response = await _apiClient.get('/auth/profile');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } catch (_) {}

    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = (prefs.getString('auth_token') ?? '').trim();
    final isLocalTrialSession = authToken.startsWith('store-session-token-');
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');

    if (!isLocalTrialSession) {
      await prefs.remove('user_data');
      await prefs.remove('tenant_id');
      await prefs.remove(_cachedEmailKey);
      await prefs.remove(_cachedPasswordKey);
      await prefs.remove('subscription_info');
      await prefs.remove('trial_ends_at');
      await prefs.remove(_activationTenantIdKey);
      await prefs.remove(_activationStoreNameKey);
      await prefs.remove(_activationCodeKey);
    }
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }

    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && !isTokenExpired(token);
  }

  bool isTokenExpired(String token) {
    if (token.startsWith('platform-session-token') ||
        token.startsWith('store-session-token-')) {
      return false;
    }

    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  // ─── New Admin API Endpoints ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminQrPayments({String? status}) async {
    _setError(null);
    try {
      final response = await _apiClient.get(
        '/admin/qr-payments',
        queryParameters: {if (status != null) 'status': status},
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      _setError('Failed to fetch QR payments: $e');
    }
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getAdminDocs() async {
    _setError(null);
    try {
      final response = await _apiClient.get('/admin/docs');
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>? ?? const <dynamic>[]);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _setError('Failed to fetch documentation: $e');
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getAdminTutorials() async {
    _setError(null);
    try {
      final response = await _apiClient.get('/admin/tutorials');
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>? ?? const <dynamic>[]);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _setError('Failed to fetch tutorials: $e');
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> createAdminDoc(
    Map<String, dynamic> data,
  ) async {
    _setError(null);
    try {
      final response = await _apiClient.post('/admin/docs', data: data);
      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to create doc: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateAdminDoc(
    String id,
    Map<String, dynamic> data,
  ) async {
    _setError(null);
    try {
      final response = await _apiClient.patch('/admin/docs/$id', data: data);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to update doc: $e');
    }
    return null;
  }

  Future<bool> deleteAdminDoc(String id) async {
    _setError(null);
    try {
      final response = await _apiClient.delete('/admin/docs/$id');
      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to delete doc: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> createAdminTutorial(
    Map<String, dynamic> data,
  ) async {
    _setError(null);
    try {
      final response = await _apiClient.post('/admin/tutorials', data: data);
      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to create tutorial: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateAdminTutorial(
    String id,
    Map<String, dynamic> data,
  ) async {
    _setError(null);
    try {
      final response = await _apiClient.patch(
        '/admin/tutorials/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to update tutorial: $e');
    }
    return null;
  }

  Future<bool> deleteAdminTutorial(String id) async {
    _setError(null);
    try {
      final response = await _apiClient.delete('/admin/tutorials/$id');
      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to delete tutorial: $e');
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getAdminTenants({
    String? status,
    String? search,
  }) async {
    _setError(null);
    try {
      final response = await _apiClient.get(
        '/admin/tenants',
        queryParameters: {
          if (status != null) 'status': status,
          if (search != null) 'search': search,
        },
      );
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final list = (data['tenants'] as List<dynamic>? ?? const <dynamic>[]);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _setError('Failed to fetch admin tenants: $e');
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> createAdminTenant({
    required String tenantId,
    required String storeName,
    required String ownerEmail,
    required String ownerName,
    required String ownerPhone,
    required String address,
    required String password,
    required String planId,
    int days = 0,
  }) async {
    _setError(null);
    try {
      final response = await _apiClient.post(
        '/admin/tenants',
        data: {
          'tenant_id': tenantId,
          'store_name': storeName,
          'owner_email': ownerEmail,
          'owner_name': ownerName,
          'owner_phone': ownerPhone,
          'address': address,
          'password': password,
          'plan_id': planId,
          'days': days,
        },
      );
      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to create tenant: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateAdminTenant({
    required String tenantId,
    required String storeName,
    String? ownerPhone,
    String? address,
    int? maxLocations,
    int? maxUsers,
    int? maxProducts,
    bool? syncEnabled,
  }) async {
    _setError(null);
    try {
      final response = await _apiClient.patch(
        '/admin/tenants/$tenantId',
        data: {
          'store_name': storeName,
          if (ownerPhone != null) 'owner_phone': ownerPhone,
          if (address != null) 'address': address,
          if (maxLocations != null) 'max_locations': maxLocations,
          if (maxUsers != null) 'max_users': maxUsers,
          if (maxProducts != null) 'max_products': maxProducts,
          if (syncEnabled != null) 'sync_enabled': syncEnabled,
        },
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to update tenant: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> assignAdminPlan({
    required String tenantId,
    required String planId,
    int days = 0,
    String? expiresAt,
  }) async {
    _setError(null);
    try {
      final response = await _apiClient.post(
        '/admin/tenants/$tenantId/assign-plan',
        data: {
          'plan_id': planId,
          if (days > 0) 'days': days,
          if (expiresAt != null) 'expires_at': expiresAt,
        },
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to assign plan: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> suspendAdminTenant({
    required String tenantId,
  }) async {
    _setError(null);
    try {
      final response = await _apiClient.post(
        '/admin/tenants/$tenantId/suspend',
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to suspend tenant: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> activateAdminTenant({
    required String tenantId,
    int days = 30,
    String? planId,
  }) async {
    _setError(null);
    try {
      final response = await _apiClient.post(
        '/admin/tenants/$tenantId/activate',
        data: {'days': days, if (planId != null) 'plan_id': planId},
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to activate tenant: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> generateAdminOfflineKey({
    required String tenantId,
    required String planId,
    int days = 365,
  }) async {
    _setError(null);
    try {
      final response = await _apiClient.post(
        '/admin/tenants/$tenantId/generate-offline-key',
        data: {'plan_id': planId, 'days': days},
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to generate offline key: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAdminPlans() async {
    _setError(null);
    try {
      final response = await _apiClient.get('/admin/plans');
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>? ?? const <dynamic>[]);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _setError('Failed to fetch plans: $e');
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> createAdminPlan(
    Map<String, dynamic> data,
  ) async {
    _setError(null);
    try {
      final response = await _apiClient.post('/admin/plans', data: data);
      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to create plan: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateAdminPlan(
    String planId,
    Map<String, dynamic> data,
  ) async {
    _setError(null);
    try {
      final response = await _apiClient.patch(
        '/admin/plans/$planId',
        data: data,
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to update plan: $e');
    }
    return null;
  }

  Future<bool> deleteAdminPlan(String planId) async {
    _setError(null);
    try {
      final response = await _apiClient.delete('/admin/plans/$planId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to delete plan: $e');
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getAdminUsers({String? tenantId}) async {
    _setError(null);
    try {
      final response = await _apiClient.get(
        '/admin/users',
        queryParameters: {if (tenantId != null) 'tenant_id': tenantId},
      );
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final list = (data['users'] as List<dynamic>? ?? const <dynamic>[]);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _setError('Failed to fetch users: $e');
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getAdminActivity({
    String? tenantId,
    String? action,
    String? resource,
  }) async {
    _setError(null);
    try {
      final response = await _apiClient.get(
        '/admin/activity',
        queryParameters: {
          if (tenantId != null) 'tenant_id': tenantId,
          if (action != null) 'action': action,
          if (resource != null) 'resource': resource,
        },
      );
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final list = (data['logs'] as List<dynamic>? ?? const <dynamic>[]);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _setError('Failed to fetch activity: $e');
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getAdminReleases() async {
    _setError(null);
    try {
      final response = await _apiClient.get('/admin/releases');
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>? ?? const <dynamic>[]);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _setError('Failed to fetch releases: $e');
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>?> createAdminRelease(
    Map<String, dynamic> data,
  ) async {
    _setError(null);
    try {
      final response = await _apiClient.post('/admin/releases', data: data);
      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to create release: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateAdminRelease(
    String id,
    Map<String, dynamic> data,
  ) async {
    _setError(null);
    try {
      final response = await _apiClient.patch(
        '/admin/releases/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to update release: $e');
    }
    return null;
  }

  Future<bool> deleteAdminRelease(String id) async {
    _setError(null);
    try {
      final response = await _apiClient.delete('/admin/releases/$id');
      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException catch (e) {
      final detail = (e.response?.data is Map)
          ? (e.response?.data['detail'] ?? '').toString()
          : e.toString();
      _setError(detail);
    } catch (e) {
      _setError('Failed to delete release: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    _setError(null);
    try {
      final response = await _apiClient.get('/admin/stats');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      _setError('Failed to fetch admin stats: $e');
    }
    return <String, dynamic>{};
  }

  Future<String?> getTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tenant_id');
  }
}

String _offlineKeyChecksum(String data) {
  final secretData = 'SB_OFFLINE_SECRET_$data';
  final bytes = utf8.encode(secretData);
  final digest = sha256.convert(bytes);
  return digest.toString().substring(0, 8).toUpperCase();
}

Map<String, dynamic> validateOfflineLicenseKey(String key) {
  try {
    final normalized = key.trim().toUpperCase();
    final parts = normalized.split('-');
    if (parts.length < 5 || parts[0] != 'SBOFF') {
      return {'valid': false, 'reason': 'Invalid format'};
    }

    final checksum = parts[parts.length - 1];
    final expiry = parts[parts.length - 2];
    final planId = parts.sublist(2, parts.length - 2).join('-').toLowerCase();
    final tenantId = parts[1].toLowerCase();

    final data = '$tenantId|$planId|$expiry';
    final expectedChecksum = _offlineKeyChecksum(data);

    if (checksum != expectedChecksum) {
      return {'valid': false, 'reason': 'Invalid checksum'};
    }

    final year = int.parse(expiry.substring(0, 4));
    final month = int.parse(expiry.substring(4, 6));
    final day = int.parse(expiry.substring(6, 8));
    final expiryDate = DateTime(year, month, day, 23, 59, 59);

    final now = DateTime.now();
    if (now.isAfter(expiryDate)) {
      return {
        'valid': true,
        'tenantId': tenantId,
        'planId': planId,
        'expiryDate': expiryDate,
        'expired': true,
      };
    }

    return {
      'valid': true,
      'tenantId': tenantId,
      'planId': planId,
      'expiryDate': expiryDate,
      'expired': false,
    };
  } catch (e) {
    return {'valid': false, 'reason': 'Parse error'};
  }
}
