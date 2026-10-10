// =============================================================================
// sync_page.dart
// Part of: dashboard_screen.dart  (loaded via the `part` directive)
//
// PURPOSE:
//   This file is a `part` extension on _DashboardScreenState.  Every method
//   declared here has direct access to the parent state's fields
//   (_syncService, _syncQueue, _lastSyncAt, etc.) without prop-drilling.
//
//   It contains:
//     Ã¢â‚¬Â¢ The Sync Manager diagnostics tab (_buildSyncPage)
//     Ã¢â‚¬Â¢ Subscription info banner and activation dialog
//     Ã¢â‚¬Â¢ Shared dialog helpers used by all other dashboard sub-screens
//       (Product, Customer, Attendance, Payroll, Employee, User, Coupon,
//        Service Job, Job Card, Supplier, Purchase Order dialogs)
//     Ã¢â‚¬Â¢ Utility widgets reused across sub-screens (_moduleCard, _statBox, etc.)
//
// HOW TO NAVIGATE THIS FILE:
//   Search for the section header comments ("-- Section Name --") to jump
//   to a specific feature area.
// =============================================================================

part of '../dashboard_screen.dart';

extension _SyncPageExt on _DashboardScreenState {
  Future<
    ({
      List<Map<String, dynamic>> activity,
      List<Map<String, dynamic>> journal,
      List<Map<String, dynamic>> serverEvents,
      List<Map<String, dynamic>> devices,
      int latestSeq,
    })
  >
  _loadSyncDiagnostics() async {
    final self = this;
    if (_syncService == null) {
      return (
        activity: <Map<String, dynamic>>[],
        journal: <Map<String, dynamic>>[],
        serverEvents: <Map<String, dynamic>>[],
        devices: <Map<String, dynamic>>[],
        latestSeq: 0,
      );
    }

    final activity = await _syncService!.getRecentSyncActivity(limit: 120);
    final journal = await _syncService!.getSyncJournalEntries(limit: 150);
    List<Map<String, dynamic>> serverEvents = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> devices = <Map<String, dynamic>>[];
    var latestSeq = 0;
    try {
      final serverJournal = await _syncService!.fetchServerJournal(
        limit: 120,
        unseenOnly: true,
      );
      serverEvents = serverJournal.events;
      devices = serverJournal.devices;
      latestSeq = serverJournal.latestSeq;
    } catch (_) {
      serverEvents = <Map<String, dynamic>>[];
      devices = <Map<String, dynamic>>[];
    }

    return (
      activity: activity,
      journal: journal,
      serverEvents: serverEvents,
      devices: devices,
      latestSeq: latestSeq,
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Timestamp Formatter
  // WHAT  : Normalises a DateTime, ISO-8601 string, or null into a human-
  //         readable local-time string. Returns '-' for null input.
  // WHERE : Used in every diagnostic ListView (journal, devices, server
  //         timeline, client activity) to display timestamped rows.
  // TODO  : Replace with a relative-time formatter ('2 min ago', 'yesterday')
  //         for better readability in the diagnostics timelines.
  // ---------------------------------------------------------------------------
  String _formatTimestamp(dynamic value) {
    final self = this;
    if (value == null) return '-';
    if (value is DateTime) {
      return value.toLocal().toString();
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return parsed.toLocal().toString();
  }

  // ---------------------------------------------------------------------------
  // SECTION: Sync Status Colour Resolver
  // WHAT  : Maps a sync status string to a display colour:
  //           green  Ã¢â€ â€™ acknowledged | applied | healthy
  //           orange Ã¢â€ â€™ queued | retrying | degraded
  //           red    Ã¢â€ â€™ conflict | failed | error | auth_error
  //           grey   Ã¢â€ â€™ skipped | offline
  //           primary Ã¢â€ â€™ everything else
  // WHERE : Called by _buildSyncStatusChip to pick the pill badge colour.
  // TODO  : Replace magic strings with a typed enum (SyncStatus) to avoid
  //         silent mismatches when the server adds new status values.
  // ---------------------------------------------------------------------------
  Color _syncStatusColor(String status, ThemeData theme) {
    final self = this;
    switch (status.toLowerCase()) {
      case 'acknowledged':
      case 'applied':
      case 'healthy':
        return Colors.green;
      case 'queued':
      case 'retrying':
      case 'degraded':
        return Colors.orange;
      case 'conflict':
      case 'failed':
      case 'error':
      case 'auth_error':
        return theme.colorScheme.error;
      case 'skipped':
      case 'offline':
        return Colors.blueGrey;
      default:
        return theme.colorScheme.primary;
    }
  }

  // ---------------------------------------------------------------------------
  // SECTION: Sync Status Chip Widget
  // WHAT  : Renders a pill-shaped badge with a colour-tinted background and
  //         border derived from _syncStatusColor. Displays the status text
  //         in UPPERCASE with underscores replaced by spaces.
  // WHERE : Used in the Local Journal list tiles and Device Sync Status tiles
  //         inside _buildSyncPage.
  // TODO  : Add a Tooltip with a plain-language description of each status
  //         (e.g. 'queued Ã¢â‚¬â€œ waiting for network connection') on hover.
  // ---------------------------------------------------------------------------
  Widget _buildSyncStatusChip(String status) {
    final self = this;
    final theme = Theme.of(context);
    final color = _syncStatusColor(status, theme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Sync Manager Page  (primary UI entry point for this file)
  // WHAT  : Builds the full Sync Manager tab.  Layout (top Ã¢â€ â€™ bottom):
  //   1. _buildSubscriptionInfoBanner  Ã¢â‚¬â€œ plan/expiry/sync-mode banner
  //   2. Last sync timestamp + last error message
  //   3. Pending operations queue list  (fixed 220 px, shows _syncQueue)
  //   4. FutureBuilder Ã¢â€ â€™ _loadSyncDiagnostics:
  //        Ã¢â‚¬Â¢ Stat boxes: Pending Queue / Local Journal / Server Events /
  //                      Devices / Latest Seq
  //        Ã¢â‚¬Â¢ Local Sync Journal ListView    (260 px, 150 entries max)
  //        Ã¢â‚¬Â¢ Device Sync Status ListView    (220 px)
  //        Ã¢â‚¬Â¢ Server Sync Timeline ListView  (220 px, 120 entries max)
  //        Ã¢â‚¬Â¢ Client Activity Timeline       (180 px, newest-first)
  // WHERE : Returned by the dashboard when the 'Sync' tab is active.
  // TODO  : Add pull-to-refresh; replace fixed-height ListViews with
  //         Expandable sections; paginate journal/server event lists.
  // ---------------------------------------------------------------------------
  Widget _buildSyncPage() {
    final self = this;
    return _moduleCard(
      title: 'Sync Manager',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => self.setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Diagnostics'),
          ),
          ElevatedButton.icon(
            onPressed: _canRunSync && !_syncInProgress ? _runManualSync : null,
            icon: const Icon(Icons.sync),
            label: Text(_syncInProgress ? 'Syncing...' : 'Run Manual Sync'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubscriptionInfoBanner(),
          const SizedBox(height: 14),
          Text('Last sync: ${_lastSyncAt?.toLocal().toString() ?? 'Never'}'),
          if (_lastSyncError != null) ...[
            const SizedBox(height: 8),
            Text(
              _lastSyncError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text('Pending operations: ${_syncQueue.length}'),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: _syncQueue.isEmpty
                ? const Center(child: Text('No pending operations'))
                : ListView.builder(
                    itemCount: _syncQueue.length,
                    itemBuilder: (context, index) {
                      final s = _syncQueue[index];
                      return ListTile(
                        leading: const Icon(Icons.sync_problem),
                        title: Text('${s.action} ${s.module}'),
                        subtitle: Text(
                          '${s.reference}  -  ${s.timestamp.toLocal()}',
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<
            ({
              List<Map<String, dynamic>> activity,
              List<Map<String, dynamic>> journal,
              List<Map<String, dynamic>> serverEvents,
              List<Map<String, dynamic>> devices,
              int latestSeq,
            })
          >(
            future: _loadSyncDiagnostics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final activity =
                  snapshot.data?.activity ?? const <Map<String, dynamic>>[];
              final journal =
                  snapshot.data?.journal ?? const <Map<String, dynamic>>[];
              final serverEvents =
                  snapshot.data?.serverEvents ?? const <Map<String, dynamic>>[];
              final devices =
                  snapshot.data?.devices ?? const <Map<String, dynamic>>[];
              final latestSeq = snapshot.data?.latestSeq ?? 0;

              // Declared OUTSIDE the StatefulBuilder builder so it is NOT
              // reset to -1 on every rebuild triggered by setNavState().
              int activeSection = 0; // 0 = Local Sync Journal shown by default

              return StatefulBuilder(
                builder: (context, setNavState) {
                  // Navigation button data (no GlobalKeys needed)
                  final navItems = [
                    (
                      label: 'Local Sync Journal',
                      icon: Icons.book_outlined,
                      index: 0,
                    ),
                    (
                      label: 'Device Sync Status',
                      icon: Icons.devices_other_rounded,
                      index: 1,
                    ),
                    (
                      label: 'Server Sync Timeline',
                      icon: Icons.cloud_sync_outlined,
                      index: 2,
                    ),
                    (
                      label: 'Client Activity Timeline',
                      icon: Icons.history_rounded,
                      index: 3,
                    ),
                  ];

                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  final activeColor = theme.colorScheme.primary;
                  final activeBg = activeColor.withValues(alpha: 0.12);
                  final inactiveBg = isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04);

                  // Returns true when a section should be rendered
                  bool show(int idx) =>
                      activeSection == -1 || activeSection == idx;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _statBox('Pending Queue', '${_syncQueue.length}'),
                          _statBox('Local Journal', '${journal.length}'),
                          _statBox('Server Events', '${serverEvents.length}'),
                          _statBox('Devices', '${devices.length}'),
                          _statBox('Latest Seq', '$latestSeq'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // â”€â”€ Section filter buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: navItems.map((nav) {
                          final isActive = activeSection == nav.index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isActive ? activeBg : inactiveBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive
                                    ? activeColor.withValues(alpha: 0.6)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : Colors.black.withValues(
                                              alpha: 0.10,
                                            )),
                                width: 1.5,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              // Tap any button â†’ show only that section
                              onTap: () => setNavState(() {
                                activeSection = nav.index;
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      nav.icon,
                                      size: 16,
                                      color: isActive
                                          ? activeColor
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.65),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      nav.label,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: isActive
                                                ? activeColor
                                                : theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.75),
                                            fontWeight: isActive
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // â”€â”€ Local Sync Journal (section 0) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      if (show(0)) ...[
                        Text(
                          'Local Sync Journal',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: activeSection == 0 ? 440 : 260,
                          child: journal.isEmpty
                              ? const Center(
                                  child: Text('No journal entries yet'),
                                )
                              : ListView.builder(
                                  itemCount: journal.length,
                                  itemBuilder: (context, index) {
                                    final item = journal[index];
                                    final status = (item['status'] ?? 'unknown')
                                        .toString();
                                    final direction =
                                        (item['direction'] ?? 'unknown')
                                            .toString();
                                    final operation = (item['operation'] ?? '')
                                        .toString();
                                    final entity = (item['entity'] ?? '')
                                        .toString();
                                    final entityId = (item['record_id'] ?? '')
                                        .toString();
                                    final seq = (item['server_seq'] ?? '-')
                                        .toString();
                                    final error = (item['error_reason'] ?? '')
                                        .toString()
                                        .trim();
                                    final updatedAt = _formatTimestamp(
                                      item['updated_at'] ?? item['created_at'],
                                    );
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        direction == 'outbound'
                                            ? Icons.upload_rounded
                                            : Icons.download_rounded,
                                      ),
                                      title: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            '${operation.isEmpty ? 'EVENT' : operation} $entity',
                                          ),
                                          _buildSyncStatusChip(status),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '${direction.toUpperCase()}  -  $entityId  -  $updatedAt${seq == '-' ? '' : '  -  seq $seq'}${error.isEmpty ? '' : '\n$error'}',
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // â”€â”€ Device Sync Status (section 1) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      if (show(1)) ...[
                        Text(
                          'Device Sync Status',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: activeSection == 1 ? 440 : 220,
                          child: devices.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No synced device status available',
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: devices.length,
                                  itemBuilder: (context, index) {
                                    final device = devices[index];
                                    final name =
                                        (device['device_name'] ??
                                                'Unknown device')
                                            .toString();
                                    final status =
                                        (device['last_sync_status'] ??
                                                'unknown')
                                            .toString();
                                    final lag = (device['lag'] ?? 0).toString();
                                    final lastSeen = _formatTimestamp(
                                      device['last_seen_at'],
                                    );
                                    final lastSeq =
                                        (device['last_applied_seq'] ?? 0)
                                            .toString();
                                    final error =
                                        (device['last_sync_error'] ?? '')
                                            .toString()
                                            .trim();
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.devices_other_rounded,
                                      ),
                                      title: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Text(name),
                                          _buildSyncStatusChip(status),
                                        ],
                                      ),
                                      subtitle: Text(
                                        'Lag: $lag  -  last seq: $lastSeq  -  seen: $lastSeen${error.isEmpty ? '' : '\n$error'}',
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // â”€â”€ Server Sync Timeline (section 2) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      if (show(2)) ...[
                        Text(
                          'Server Sync Timeline',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: activeSection == 2 ? 440 : 220,
                          child: serverEvents.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No server audit events available',
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: serverEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = serverEvents[index];
                                    final seq = (event['seq'] ?? '-')
                                        .toString();
                                    final action = (event['action'] ?? '')
                                        .toString();
                                    final entity = (event['entity'] ?? '')
                                        .toString();
                                    final entityId = (event['entity_id'] ?? '')
                                        .toString();
                                    final sourceDevice =
                                        (event['source_device_id'] ?? 'unknown')
                                            .toString();
                                    final ts = _formatTimestamp(
                                      event['server_ts'],
                                    );
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.cloud_done_outlined,
                                      ),
                                      title: Text('#$seq $action $entity'),
                                      subtitle: Text(
                                        '$entityId  -  $ts  -  device: $sourceDevice',
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // â”€â”€ Client Activity Timeline (section 3) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      if (show(3)) ...[
                        Text(
                          'Client Activity Timeline',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: activeSection == 3 ? 440 : 180,
                          child: activity.isEmpty
                              ? const Center(
                                  child: Text('No client activity logs yet'),
                                )
                              : ListView.builder(
                                  itemCount: activity.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        activity[activity.length - 1 - index];
                                    final type = (item['type'] ?? 'unknown')
                                        .toString();
                                    final at = _formatTimestamp(item['at']);
                                    final entity = (item['entity'] ?? '')
                                        .toString();
                                    final entityId =
                                        (item['recordId'] ??
                                                item['entityId'] ??
                                                '')
                                            .toString();
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.history),
                                      title: Text(type),
                                      subtitle: Text(
                                        '$at  ${entity.isEmpty ? '' : '- $entity'} ${entityId.isEmpty ? '' : '($entityId)'}',
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Subscription Info Banner
  // WHAT  : FutureBuilder widget that reads SharedPreferences
  //         'subscription_info' and renders a coloured card showing:
  //           Ã¢â‚¬Â¢ Plan name (e.g. 'Pro', 'Trial')
  //           Ã¢â‚¬Â¢ Status badge: ACTIVE (green) / TRIAL (orange) /
  //                           SUSPENDED (red) / EXPIRED (red) / OFFLINE (grey)
  //           Ã¢â‚¬Â¢ Days-remaining label (red if expired, orange if Ã¢â€°Â¤7 days)
  //           Ã¢â‚¬Â¢ Cloud Sync ON / Offline Mode pill badge
  //           Ã¢â‚¬Â¢ 'Activate Sync' button when sync is disabled
  // WHERE : Embedded at the very top of _buildSyncPage.
  // TODO  : Auto-refresh when the app resumes from background (AppLifecycleState);
  //         add a 'Manage Plan' button that deep-links to the admin portal.
  // ---------------------------------------------------------------------------
  Widget _buildSubscriptionInfoBanner() {
    final self = this;
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadSubscriptionInfo(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        if (!snapshot.hasData) return const SizedBox.shrink();
        final info = snapshot.data!;
        final planName = (info['plan_name'] ?? 'Trial').toString();
        final status = (info['status'] ?? 'TRIAL').toString().toUpperCase();
        final syncEnabled = info['sync_enabled'] as bool? ?? true;
        final expiresAt = info['plan_expires_at'] != null
            ? DateTime.tryParse(info['plan_expires_at'].toString())
            : null;

        Color statusColor;
        String statusLabel;
        IconData statusIcon;
        switch (status) {
          case 'ACTIVE':
            statusColor = Colors.green;
            statusLabel = 'Active';
            statusIcon = Icons.check_circle_outline;
            break;
          case 'SUSPENDED':
            statusColor = Colors.red;
            statusLabel = 'Suspended';
            statusIcon = Icons.block_outlined;
            break;
          case 'OFFLINE':
            statusColor = Colors.blueGrey;
            statusLabel = 'Offline License';
            statusIcon = Icons.wifi_off_outlined;
            break;
          case 'EXPIRED':
            statusColor = Colors.red;
            statusLabel = 'Expired';
            statusIcon = Icons.error_outline;
            break;
          default: // TRIAL
            statusColor = Colors.orange;
            statusLabel = 'Trial';
            statusIcon = Icons.access_time_outlined;
        }

        // Calculate days remaining
        String expiryLabel = '';
        if (expiresAt != null) {
          final days = expiresAt.difference(DateTime.now()).inDays;
          if (days < 0) {
            expiryLabel = 'Expired ${(-days)} days ago';
            statusColor = Colors.red;
          } else if (days == 0) {
            expiryLabel = 'Expires today!';
            statusColor = Colors.red;
          } else if (days <= 7) {
            expiryLabel = 'Expires in $days days';
            statusColor = Colors.orange;
          } else {
            expiryLabel =
                'Valid until ${expiresAt.toLocal().toString().substring(0, 10)}';
          }
        }

        final cardColor = isDark
            ? statusColor.withValues(alpha: 0.12)
            : statusColor.withValues(alpha: 0.06);
        final borderColor = statusColor.withValues(alpha: 0.3);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          planName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: syncEnabled
                                ? Colors.blue.withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: syncEnabled
                                  ? Colors.blue.withValues(alpha: 0.35)
                                  : Colors.grey.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                syncEnabled
                                    ? Icons.cloud_done_outlined
                                    : Icons.cloud_off_outlined,
                                size: 12,
                                color: syncEnabled ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                syncEnabled ? 'Cloud Sync ON' : 'Offline Mode',
                                style: TextStyle(
                                  color: syncEnabled
                                      ? Colors.blue
                                      : Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (expiryLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        expiryLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!syncEnabled) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showUpgradeToOnlineDialog(context),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: const Text('Activate Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Upgrade to Online Sync Dialog
  // WHAT  : AlertDialog that accepts an Activation Code (format
  //         SB_STORENAME_XXXX), calls AuthService.activateDeviceWithCode,
  //         then on success:
  //           1. Clears cached 'subscription_info' in SharedPreferences.
  //           2. Shows a success SnackBar.
  //           3. Fires AuthLogoutRequested so the user re-authenticates
  //              and picks up new cloud credentials.
  //         On failure: shows an error SnackBar with authService.lastActionError.
  // WHERE : Triggered by the 'Activate Sync' button in _buildSubscriptionInfoBanner.
  // TODO  : Show a loading spinner overlay during activation;
  //         add a QR-code scanner as an alternative to manual code entry.
  // ---------------------------------------------------------------------------
  void _showUpgradeToOnlineDialog(BuildContext context) {
    final self = this;
    final codeController = TextEditingController();
    var isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Upgrade to Online Sync'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the Activation Code generated from your StoreBuddy Admin Panel to enable Cloud Sync.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Activation Code',
                      hintText: 'e.g. SB_STORENAME_XXXX',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isSubmitting,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.isEmpty) return;

                          setState(() => isSubmitting = true);
                          final authService = self.context.read<AuthService>();

                          final prefs = await SharedPreferences.getInstance();
                          final deviceLabel =
                              prefs.getString('device_label') ??
                              'Store Buddy POS';

                          final res = await authService.activateDeviceWithCode(
                            code,
                            deviceLabel: deviceLabel,
                          );

                          if (!context.mounted) return;
                          if (!self.mounted) return;
                          setState(() => isSubmitting = false);

                          if (res != null) {
                            await prefs.remove('subscription_info');

                            if (context.mounted) {
                              Navigator.pop(context);
                            }

                            if (self.mounted) {
                              ScaffoldMessenger.of(self.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Device activated online! Please sign in again to sync.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              self.context.read<AuthBloc>().add(
                                AuthLogoutRequested(),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    authService.lastActionError ??
                                        'Activation failed.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: Text(isSubmitting ? 'Activating...' : 'Activate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Subscription Info Loader
  // WHAT  : Reads 'subscription_info' JSON blob from SharedPreferences.
  //         Falls back to individual 'trial_ends_at' pref and constructs
  //         a minimal map when the full blob is absent or corrupted.
  //         Returns a Map with keys: plan_name, status, sync_enabled,
  //         plan_expires_at.
  // WHERE : Called by _buildSubscriptionInfoBanner's FutureBuilder.
  // TODO  : Add a server-side refresh path (call the licensing endpoint)
  //         when local cache is missing or older than N hours.
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> _loadSubscriptionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('subscription_info') ?? '';
      if (raw.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
      // Fall back to reading individual prefs
      final trialEndsAt = prefs.getString('trial_ends_at') ?? '';
      return {
        'plan_name': 'Trial',
        'status': 'TRIAL',
        'sync_enabled': _syncService != null,
        'plan_expires_at': trialEndsAt.isNotEmpty ? trialEndsAt : null,
      };
    } catch (_) {
      return {
        'plan_name': 'Trial',
        'status': 'TRIAL',
        'sync_enabled': _syncService != null,
        'plan_expires_at': null,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // SECTION: Module Card Shell (shared layout wrapper)
  // WHAT  : Responsive card wrapper used by all sub-screen builders.
  //         Ã¢â‚¬Â¢ Switches padding 12 px Ã¢â€ â€ 20 px at the 920 px width breakpoint.
  //         Ã¢â‚¬Â¢ Constrains content to UiSize.pageMaxContentWidth.
  //         Ã¢â‚¬Â¢ Renders a large title + optional action widget row in the header.
  // WHERE : Wraps the content returned by _buildSyncPage and every other
  //         dashboard sub-screen (Inventory, Customers, HR, etc.).
  // TODO  : Extract into a dedicated shared widget file (e.g.
  //         'widgets/module_card.dart') so sub-screens can import it directly
  //         without going through the extension.
  // ---------------------------------------------------------------------------
  Widget _moduleCard({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    final self = this;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 920;
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 12 : 20),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: UiSize.pageMaxContentWidth,
              ),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            self._t(title),
                            style: TextStyle(
                              fontSize: compact ? 24 : 40,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (action != null) action,
                        ],
                      ),
                      const SizedBox(height: 14),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Stat Box Tile
  // WHAT  : Fixed-width (220 px) metric card that renders a small label and
  //         a large (24 pt) numeric/text value inside a rounded bordered box.
  // WHERE : Used in the diagnostics Wrap row inside _buildSyncPage:
  //         Pending Queue, Local Journal, Server Events, Devices, Latest Seq.
  // TODO  : Add an optional subtitle or trend indicator (Ã¢â€ â€˜ Ã¢â€ â€œ) to show
  //         changes since the last refresh.
  // ---------------------------------------------------------------------------
  Widget _statBox(String label, String value) {
    final self = this;
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Add / Edit Product Dialog
  // WHAT  : Right-drawer slide-in dialog (600 px wide, full height) for
  //         creating or editing a product.  Fields:
  //           Ã¢â‚¬Â¢ Name *, Description, SKU *, Category (+ inline Add Category)
  //           Ã¢â‚¬Â¢ Product Type (Unit / Service)
  //           Ã¢â‚¬Â¢ Price *, Min Price, Cost Price
  //           Ã¢â‚¬Â¢ Quantity (with per-location breakdown for owner/admin on create)
  //           Ã¢â‚¬Â¢ IMEI / serialisation tracking toggle
  //           Ã¢â‚¬Â¢ Minimum Stock, Measurement Unit
  //           Ã¢â‚¬Â¢ Barcode + 'Generate' button, Warranty months
  //           Ã¢â‚¬Â¢ Expiry Date picker + Reminder mode (WEEK / MONTH / CUSTOM)
  //           Ã¢â‚¬Â¢ Supplier dropdown
  //           Ã¢â‚¬Â¢ Category attribute fields (text, num, boolean, select)
  //         Validation: price > 0; min price Ã¢â€°Â¤ price; location required (create);
  //                     all IMEI fields filled when tracking is on.
  //         Returns _ProductDialogResult? (null = cancelled).
  // WHERE : Called from the Inventory/Products tab when the Add or Edit
  //         action button is pressed.
  // TODO  : Add image picker field; barcode scanner integration;
  //         client-side SKU uniqueness check before submission.
  // ---------------------------------------------------------------------------
  Future<_ProductDialogResult?> _showProductDialog({
    _ProductItem? existing,
    String? initialSupplierId,
    String? name,
    String? initialLocationId,
    String? barcode,
  }) async {
    final self = this;
    final idController = TextEditingController(
      text:
          existing?.id ?? 'P${DateTime.now().millisecondsSinceEpoch % 100000}',
    );
    final nameController = TextEditingController(
      text: existing?.name ?? name ?? '',
    );
    final barcodeController = TextEditingController(
      text: existing?.barcode ?? (barcode != null && barcode.trim().isNotEmpty ? barcode.trim() : _generateBarcodeValue()),
    );
    final priceController = TextEditingController(
      text: existing?.price.toString() ?? '0',
    );
    final minPriceController = TextEditingController(
      text: existing?.minPrice.toString() ?? '0',
    );
    final stockController = TextEditingController(
      text: existing?.stock.toString() ?? '0',
    );
    final minStockController = TextEditingController(
      text: existing?.minStock.toString() ?? '0',
    );
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final costController = TextEditingController(
      text: existing?.costPrice?.toString() ?? '',
    );
    final warrantyController = TextEditingController(
      text: (existing?.warrantyMonths ?? 0).toString(),
    );
    String? selectedImagePath = existing?.imageUrl;
    DateTime? selectedExpiryDate = existing?.expiryDate;
    String selectedExpiryReminderMode = (existing?.expiryReminderMode ?? 'WEEK')
        .toUpperCase();
    final expiryReminderDaysController = TextEditingController(
      text: (existing?.expiryReminderDays ?? 7).toString(),
    );
    String selectedType = (existing?.productType.toUpperCase() == 'SERVICE')
        ? 'Service'
        : 'Unit';
    String selectedMeasureUnit =
        (existing?.measureUnit.trim().isNotEmpty ?? false)
        ? existing!.measureUnit.trim().toUpperCase()
        : 'PIECE';
    final attributeValues = Map<String, dynamic>.from(
      existing?.attributeValues ?? <String, dynamic>{},
    );
    String selectedSupplierId = existing?.supplierId ?? initialSupplierId ?? '';
    if (selectedSupplierId.isNotEmpty &&
        !self._suppliers.any((s) => s.id == selectedSupplierId)) {
      selectedSupplierId = '';
    }
    const measureUnits = [
      'PIECE',
      'BAG',
      'BOX',
      'ROLL',
      'KG',
      'GRAM',
      'LITER',
      'ML',
      'METER',
      'PACK',
      'BOTTLE',
      'CAN',
      'DRUM',
      'FEET',
      'SQFT',
      'SET',
    ];

    bool allowLooseSales = existing?.allowLooseSales ??
        (attributeValues['allowLooseSales'] == true);
    String selectedSecondaryUnit = existing?.secondaryUnit ??
        (attributeValues['secondaryUnit']?.toString() ?? 'KG');
    final conversionRatioController = TextEditingController(
      text: existing != null && existing.unitConversionRatio > 0
          ? (existing.unitConversionRatio.truncateToDouble() ==
                  existing.unitConversionRatio
              ? existing.unitConversionRatio.toInt().toString()
              : existing.unitConversionRatio.toString())
          : (attributeValues['unitConversionRatio']?.toString() ?? '50'),
    );
    final secondaryPriceController = TextEditingController(
      text: existing?.secondaryPrice != null
          ? (existing!.secondaryPrice!.truncateToDouble() ==
                  existing.secondaryPrice
              ? existing.secondaryPrice!.toInt().toString()
              : existing.secondaryPrice!.toString())
          : (attributeValues['secondaryPrice']?.toString() ?? ''),
    );

    final locControllers = <String, TextEditingController>{};
    final locChecked = <String, bool>{};
    final singleImeiControllers = <TextEditingController>[];
    final locImeiControllers = <String, List<TextEditingController>>{};
    if (existing == null && (_isOwner || _isAdmin)) {
      final defaultLoc = initialLocationId ?? _activeLocationForWrites;
      for (final locName in _availableLocationNames) {
        locControllers[locName] = TextEditingController(text: '0');
        locChecked[locName] = locName == defaultLoc;
      }
    }

    final result = await showGeneralDialog<_ProductDialogResult>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: 'AddProduct',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        final categories = _productCategories.isEmpty
            ? ['General']
            : List<String>.from(_productCategories);
        String selectedCategory = existing?.category.isNotEmpty == true
            ? existing!.category
            : categories.first;
        final newCategoryController = TextEditingController();

        var localImeis = <String>[];
        var hasInitializedImeis = false;
        var trackImei = false;

        if (!categories.any(
          (c) => c.toLowerCase() == selectedCategory.toLowerCase(),
        )) {
          categories.add(selectedCategory);
        }

        return StatefulBuilder(
          builder: (context, setLocal) {
            if (!hasInitializedImeis) {
              if (existing != null &&
                  existing.imeis != null &&
                  existing.imeis!.isNotEmpty) {
                try {
                  final decoded = jsonDecode(existing.imeis!);
                  if (decoded is List) {
                    localImeis = List<String>.from(decoded);
                    trackImei = true;
                    final q = existing.stock;
                    for (int i = 0; i < q; i++) {
                      final val = i < localImeis.length ? localImeis[i] : '';
                      singleImeiControllers.add(
                        TextEditingController(text: val),
                      );
                    }
                  }
                } catch (_) {}
              }
              hasInitializedImeis = true;
            }
            final categoryAttributeDefs =
                _categoryAttributes[selectedCategory] ??
                const <_CategoryAttributeDef>[];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final isMobile = MediaQuery.of(context).size.width < 600;

            InputDecoration dec(
              String label, {
              String? hint,
              Widget? prefixIcon,
              Widget? suffixIcon,
              String? suffixText,
            }) {
              return InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                suffixText: suffixText,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 1.8,
                  ),
                ),
              );
            }

            Widget cardSection({
              required String title,
              required IconData icon,
              required Color color,
              required List<Widget> children,
            }) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 18, color: color),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...children,
                  ],
                ),
              );
            }

            return Align(
              alignment: isMobile ? Alignment.center : Alignment.centerRight,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: math.min(MediaQuery.of(context).size.width, 620.0),
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).viewInsets.bottom,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                color: Color(0xFF6366F1),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    existing == null
                                        ? 'Add New Product'
                                        : 'Edit Product',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    existing == null
                                        ? 'Enter product details to add to inventory'
                                        : 'Update product information and stock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Scrollable Body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            16 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section 1: Basic Info
                              cardSection(
                                title: 'Basic Information',
                                icon: Icons.shopping_bag_outlined,
                                color: const Color(0xFF6366F1),
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1F2937)
                                              : const Color(0xFFF3F4F6),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF374151)
                                                : const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: selectedImagePath != null &&
                                                File(selectedImagePath!).existsSync()
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(11),
                                                child: Image.file(
                                                  File(selectedImagePath!),
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(
                                                Icons.add_photo_alternate_outlined,
                                                size: 32,
                                                color: isDark
                                                    ? Colors.grey[500]
                                                    : Colors.grey[400],
                                              ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Product Image',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'JPG, PNG or WebP. Displayed on POS tiles and receipts.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () async {
                                                    final result = await FilePicker.platform.pickFiles(
                                                      type: FileType.image,
                                                      allowMultiple: false,
                                                    );
                                                    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
                                                      final srcPath = result.files.single.path!;
                                                      final appDocDir = await getApplicationDocumentsDirectory();
                                                      final imagesDir = Directory('${appDocDir.path}/product_images');
                                                      if (!await imagesDir.exists()) {
                                                        await imagesDir.create(recursive: true);
                                                      }
                                                      final ext = srcPath.split('.').last;
                                                      final destFile = File('${imagesDir.path}/prod_${DateTime.now().millisecondsSinceEpoch}.$ext');
                                                      await File(srcPath).copy(destFile.path);
                                                      setLocal(() {
                                                        selectedImagePath = destFile.path;
                                                      });
                                                    }
                                                  },
                                                  icon: const Icon(Icons.upload_file_outlined, size: 15),
                                                  label: Text(
                                                    selectedImagePath != null ? 'Change Image' : 'Upload Image',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.brandIndigo,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                ),
                                                if (selectedImagePath != null) ...[
                                                  const SizedBox(width: 8),
                                                  TextButton(
                                                    onPressed: () => setLocal(() => selectedImagePath = null),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.redAccent,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    child: const Text('Remove', style: TextStyle(fontSize: 12)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: nameController,
                                    decoration: dec(
                                      'Product Name *',
                                      hint:
                                          'e.g. Wireless Mouse / Apple iPhone 15',
                                      prefixIcon: const Icon(
                                        Icons.label_outlined,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: descriptionController,
                                    maxLines: 2,
                                    decoration: dec(
                                      'Description',
                                      hint:
                                          'Optional product specifications or notes...',
                                      prefixIcon: const Icon(
                                        Icons.notes_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: idController,
                                          decoration: dec(
                                            'SKU / Code *',
                                            prefixIcon: const Icon(
                                              Icons.qr_code_rounded,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value:
                                              categories.contains(
                                                selectedCategory,
                                              )
                                              ? selectedCategory
                                              : (categories.isNotEmpty
                                                    ? categories.first
                                                    : null),
                                          decoration: dec('Category *'),
                                          items: categories
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c,
                                                  child: Text(c),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setLocal(
                                              () => selectedCategory = v,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: selectedType,
                                          decoration: dec('Product Type'),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Unit',
                                              child: Text('Unit'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Service',
                                              child: Text('Service'),
                                            ),
                                          ],
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setLocal(() => selectedType = v);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value:
                                              measureUnits.contains(
                                                selectedMeasureUnit,
                                              )
                                              ? selectedMeasureUnit
                                              : 'PIECE',
                                          decoration: dec('Unit of Measure'),
                                          items: measureUnits
                                              .map(
                                                (unit) => DropdownMenuItem(
                                                  value: unit,
                                                  child: Text(unit),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setLocal(
                                              () => selectedMeasureUnit = v,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Section 2: Pricing & Cost
                              cardSection(
                                title: 'Pricing & Cost',
                                icon: Icons.payments_outlined,
                                color: const Color(0xFF10B981),
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: priceController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: dec(
                                            'Selling Price *',
                                            prefixIcon: const Icon(
                                              Icons.attach_money_rounded,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: minPriceController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: dec('Min Price'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: costController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: dec('Cost Price'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: minStockController,
                                          keyboardType: TextInputType.number,
                                          decoration: dec(
                                            'Alert Stock Limit',
                                            prefixIcon: const Icon(
                                              Icons.warning_amber_rounded,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: warrantyController,
                                          keyboardType: TextInputType.number,
                                          decoration: dec(
                                            'Warranty (Months)',
                                            prefixIcon: const Icon(
                                              Icons.verified_user_outlined,
                                              size: 20,
                                            ),
                                            suffixText: 'mo',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (existing != null ||
                                      !(_isOwner || _isAdmin)) ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: stockController,
                                      keyboardType: TextInputType.number,
                                      decoration: dec(
                                        'Quantity / Stock',
                                        prefixIcon: const Icon(
                                          Icons.inventory_rounded,
                                          size: 20,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final q = int.tryParse(val.trim()) ?? 0;
                                        setLocal(() {
                                          if (singleImeiControllers.length <
                                              q) {
                                            while (singleImeiControllers
                                                    .length <
                                                q) {
                                              singleImeiControllers.add(
                                                TextEditingController(),
                                              );
                                            }
                                          } else if (singleImeiControllers
                                                  .length >
                                              q) {
                                            while (singleImeiControllers
                                                    .length >
                                                q) {
                                              final removed =
                                                  singleImeiControllers
                                                      .removeLast();
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback(
                                                    (_) => removed.dispose(),
                                                  );
                                            }
                                          }
                                        });
                                      },
                                    ),
                                    if (trackImei) ...[
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Enter IMEI / Serial Numbers:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...singleImeiControllers
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                            final idx = entry.key;
                                            final controller = entry.value;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: TextField(
                                                controller: controller,
                                                decoration: dec(
                                                  'IMEI ${idx + 1}',
                                                  hint: 'Scan or type IMEI',
                                                ),
                                              ),
                                            );
                                          }),
                                    ],
                                  ],
                                ],
                              ),

                              // Section 2.5: Dual Unit / Loose Selling
                              cardSection(
                                title: 'Dual Unit / Loose Selling',
                                icon: Icons.scale_rounded,
                                color: const Color(0xFF0EA5E9),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: allowLooseSales
                                          ? const Color(
                                              0xFF0EA5E9,
                                            ).withValues(alpha: 0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: allowLooseSales
                                            ? const Color(
                                                0xFF0EA5E9,
                                              ).withValues(alpha: 0.3)
                                            : (isDark
                                                  ? Colors.white12
                                                  : Colors.grey.shade300),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Enable Loose / Fractional Selling',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.5,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.grey.shade900,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Sell in bulk (e.g. $selectedMeasureUnit) and also broken/loose (e.g. KG, Meter, Pcs)',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: isDark
                                                      ? Colors.grey.shade400
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: allowLooseSales,
                                          activeThumbColor:
                                              const Color(0xFF0EA5E9),
                                          onChanged: (val) {
                                            setLocal(() => allowLooseSales = val);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (allowLooseSales) ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                            initialValue: measureUnits.contains(
                                                  selectedSecondaryUnit,
                                                )
                                                ? selectedSecondaryUnit
                                                : 'KG',
                                            decoration: dec(
                                              'Secondary Loose Unit *',
                                            ),
                                            items: measureUnits
                                                .where(
                                                  (u) =>
                                                      u !=
                                                      selectedMeasureUnit,
                                                )
                                                .map(
                                                  (u) => DropdownMenuItem(
                                                    value: u,
                                                    child: Text(u),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (v) {
                                              if (v != null) {
                                                setLocal(
                                                  () =>
                                                      selectedSecondaryUnit = v,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                conversionRatioController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: dec(
                                              '1 $selectedMeasureUnit = ? $selectedSecondaryUnit',
                                              hint: 'e.g. 50',
                                              prefixIcon: const Icon(
                                                Icons.calculate_outlined,
                                                size: 20,
                                              ),
                                            ),
                                            onChanged: (_) => setLocal(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                secondaryPriceController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: dec(
                                              'Selling Price per $selectedSecondaryUnit *',
                                              hint: 'e.g. 50.00',
                                              prefixIcon: const Icon(
                                                Icons.payments_outlined,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Builder(
                                      builder: (context) {
                                        final r = double.tryParse(
                                              conversionRatioController.text
                                                  .trim(),
                                            ) ??
                                            50.0;
                                        final frac = r > 0
                                            ? (1.0 / r).toStringAsFixed(3)
                                            : '0';
                                        return Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.grey.shade900
                                                : const Color(0xFFF0F9FF),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF0EA5E9,
                                              ).withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.info_outline,
                                                size: 16,
                                                color: Color(0xFF0EA5E9),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Selling 1 $selectedSecondaryUnit will deduct $frac $selectedMeasureUnit from inventory.',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: isDark
                                                        ? Colors.grey.shade300
                                                        : const Color(
                                                            0xFF0369A1,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),

                              // Section 3: Barcode & Serialization
                              cardSection(
                                title: 'Barcode & Serialization',
                                icon: Icons.qr_code_scanner_rounded,
                                color: const Color(0xFFF59E0B),
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: barcodeController,
                                          decoration: dec(
                                            'Barcode',
                                            prefixIcon: const Icon(
                                              Icons.barcode_reader,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          barcodeController.text =
                                              _generateBarcodeValue();
                                        },
                                        icon: const Icon(
                                          Icons.autorenew_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Generate'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_enableMobileShopFeatures) ...[
                                    const SizedBox(height: 8),
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text(
                                        'Track IMEI (Serialization)',
                                      ),
                                      value: trackImei,
                                      onChanged: (val) {
                                        setLocal(() {
                                          trackImei = val ?? false;
                                          if (trackImei) {
                                            if (existing == null) {
                                              for (final locName
                                                  in _availableLocationNames) {
                                                if (locChecked[locName] ==
                                                    true) {
                                                  final q =
                                                      int.tryParse(
                                                        locControllers[locName]
                                                                ?.text ??
                                                            '0',
                                                      ) ??
                                                      0;
                                                  final list =
                                                      locImeiControllers[locName] ??
                                                      [];
                                                  if (list.length < q) {
                                                    while (list.length < q) {
                                                      list.add(
                                                        TextEditingController(),
                                                      );
                                                    }
                                                  } else if (list.length > q) {
                                                    while (list.length > q) {
                                                      list
                                                          .removeLast()
                                                          .dispose();
                                                    }
                                                  }
                                                  locImeiControllers[locName] =
                                                      list;
                                                }
                                              }
                                            } else {
                                              final q =
                                                  int.tryParse(
                                                    stockController.text,
                                                  ) ??
                                                  0;
                                              if (singleImeiControllers.length <
                                                  q) {
                                                while (singleImeiControllers
                                                        .length <
                                                    q) {
                                                  singleImeiControllers.add(
                                                    TextEditingController(),
                                                  );
                                                }
                                              } else if (singleImeiControllers
                                                      .length >
                                                  q) {
                                                while (singleImeiControllers
                                                        .length >
                                                    q) {
                                                  final removed =
                                                      singleImeiControllers
                                                          .removeLast();
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                        (_) =>
                                                            removed.dispose(),
                                                      );
                                                }
                                              }
                                            }
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),

                              // Section 4: Location Stock (if Owner/Admin)
                              if (existing == null && (_isOwner || _isAdmin))
                                cardSection(
                                  title: 'Stock at Locations *',
                                  icon: Icons.store_rounded,
                                  color: const Color(0xFF3B82F6),
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.grey.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            _availableLocationNames.length,
                                        separatorBuilder: (context, index) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final locName =
                                              _availableLocationNames[index];
                                          return CheckboxListTile(
                                            value: locChecked[locName] ?? false,
                                            title: Text(
                                              locName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle:
                                                locChecked[locName] == true
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          const Text('Qty: '),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          SizedBox(
                                                            width: 120,
                                                            height: 38,
                                                            child: TextField(
                                                              controller:
                                                                  locControllers[locName],
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              onChanged: (val) {
                                                                final q =
                                                                    int.tryParse(
                                                                      val.trim(),
                                                                    ) ??
                                                                    0;
                                                                setLocal(() {
                                                                  final list =
                                                                      locImeiControllers[locName] ??
                                                                      [];
                                                                  if (list.length <
                                                                      q) {
                                                                    while (list
                                                                            .length <
                                                                        q) {
                                                                      list.add(
                                                                        TextEditingController(),
                                                                      );
                                                                    }
                                                                  } else if (list
                                                                          .length >
                                                                      q) {
                                                                    while (list
                                                                            .length >
                                                                        q) {
                                                                      list
                                                                          .removeLast()
                                                                          .dispose();
                                                                    }
                                                                  }
                                                                  locImeiControllers[locName] =
                                                                      list;
                                                                });
                                                              },
                                                              decoration: dec(
                                                                'Quantity',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (trackImei) ...[
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        const Text(
                                                          'IMEI Numbers:',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        ...(locImeiControllers[locName] ??
                                                                [])
                                                            .asMap()
                                                            .entries
                                                            .map((entry) {
                                                              final idx =
                                                                  entry.key;
                                                              final controller =
                                                                  entry.value;
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      bottom: 6,
                                                                    ),
                                                                child: TextField(
                                                                  controller:
                                                                      controller,
                                                                  decoration: dec(
                                                                    'IMEI ${idx + 1}',
                                                                  ),
                                                                ),
                                                              );
                                                            }),
                                                      ],
                                                    ],
                                                  )
                                                : Text(
                                                    'Not assigned to this branch',
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? Colors.grey[500]
                                                          : Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                            onChanged: (checked) {
                                              setLocal(() {
                                                locChecked[locName] =
                                                    checked ?? false;
                                                if (checked == true &&
                                                    trackImei) {
                                                  final q =
                                                      int.tryParse(
                                                        locControllers[locName]
                                                                ?.text ??
                                                            '0',
                                                      ) ??
                                                      0;
                                                  final list =
                                                      locImeiControllers[locName] ??
                                                      [];
                                                  if (list.length < q) {
                                                    while (list.length < q) {
                                                      list.add(
                                                        TextEditingController(),
                                                      );
                                                    }
                                                  } else if (list.length > q) {
                                                    while (list.length > q) {
                                                      list
                                                          .removeLast()
                                                          .dispose();
                                                    }
                                                  }
                                                  locImeiControllers[locName] =
                                                      list;
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                              // Section 5: Expiry Date & Reminders
                              cardSection(
                                title: 'Expiry Date & Reminders',
                                icon: Icons.event_available_rounded,
                                color: const Color(0xFFEC4899),
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InputDecorator(
                                          decoration: dec('Expiry Date'),
                                          child: Text(
                                            selectedExpiryDate == null
                                                ? 'No expiry date selected'
                                                : '${selectedExpiryDate!.year}-${selectedExpiryDate!.month.toString().padLeft(2, '0')}-${selectedExpiryDate!.day.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              color: selectedExpiryDate == null
                                                  ? (isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600])
                                                  : (isDark
                                                        ? Colors.white
                                                        : Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final defaultDate = DateTime.now()
                                              .add(const Duration(days: 30));
                                          final initialDate =
                                              selectedExpiryDate != null &&
                                                  !selectedExpiryDate!.isBefore(
                                                    DateTime.now().subtract(
                                                      const Duration(days: 1),
                                                    ),
                                                  )
                                              ? selectedExpiryDate!
                                              : defaultDate;
                                          final picked = await showDatePicker(
                                            context: self.context,
                                            initialDate: initialDate,
                                            firstDate: DateTime.now().subtract(
                                              const Duration(days: 1),
                                            ),
                                            lastDate: DateTime.now().add(
                                              const Duration(days: 3650),
                                            ),
                                          );
                                          if (picked == null) return;
                                          setLocal(
                                            () => selectedExpiryDate = picked,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.event_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Pick Date'),
                                      ),
                                      if (selectedExpiryDate != null) ...[
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () => setLocal(
                                            () => selectedExpiryDate = null,
                                          ),
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue:
                                              selectedExpiryReminderMode,
                                          decoration: dec('Reminder'),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'WEEK',
                                              child: Text('Before a week'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'MONTH',
                                              child: Text('Before a month'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'CUSTOM',
                                              child: Text('Custom days'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setLocal(
                                              () => selectedExpiryReminderMode =
                                                  value,
                                            );
                                          },
                                        ),
                                      ),
                                      if (selectedExpiryReminderMode ==
                                          'CUSTOM') ...[
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 140,
                                          child: TextField(
                                            controller:
                                                expiryReminderDaysController,
                                            keyboardType: TextInputType.number,
                                            decoration: dec('Days'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),

                              // Section 6: Supplier & Extra Category Attributes
                              cardSection(
                                title: 'Supplier & Additional Info',
                                icon: Icons.local_shipping_outlined,
                                color: const Color(0xFF8B5CF6),
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedSupplierId.isEmpty
                                        ? null
                                        : selectedSupplierId,
                                    decoration: dec('Supplier (Optional)'),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: '',
                                        child: Text('No Supplier'),
                                      ),
                                      ..._suppliers.map(
                                        (s) => DropdownMenuItem<String>(
                                          value: s.id,
                                          child: Text(s.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null)
                                        setLocal(() => selectedSupplierId = v);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: newCategoryController,
                                          decoration: dec(
                                            'Create New Category',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          final value = newCategoryController
                                              .text
                                              .trim();
                                          if (value.isEmpty) return;
                                          if (categories.any(
                                            (c) =>
                                                c.toLowerCase() ==
                                                value.toLowerCase(),
                                          ))
                                            return;
                                          setLocal(() {
                                            categories.add(value);
                                            selectedCategory = value;
                                            _categoryAttributes[value] =
                                                const <_CategoryAttributeDef>[];
                                          });
                                          newCategoryController.clear();
                                        },
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  ),
                                  if (categoryAttributeDefs.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Category Attributes',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    for (final attribute
                                        in categoryAttributeDefs)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${attribute.name}${attribute.required ? ' *' : ''}',
                                            ),
                                            const SizedBox(height: 6),
                                            if (attribute.type == 'boolean')
                                              DropdownButtonFormField<String>(
                                                initialValue:
                                                    (attributeValues[attribute
                                                                    .name]
                                                                ?.toString() ??
                                                            '')
                                                        .isEmpty
                                                    ? null
                                                    : attributeValues[attribute
                                                              .name]
                                                          ?.toString(),
                                                decoration: dec(attribute.name),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'true',
                                                    child: Text('Yes'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'false',
                                                    child: Text('No'),
                                                  ),
                                                ],
                                                onChanged: (value) =>
                                                    attributeValues[attribute
                                                            .name] =
                                                        value,
                                              )
                                            else
                                              TextFormField(
                                                initialValue:
                                                    attributeValues[attribute
                                                            .name]
                                                        ?.toString() ??
                                                    '',
                                                keyboardType:
                                                    attribute.type == 'num'
                                                    ? TextInputType.number
                                                    : TextInputType.text,
                                                onChanged: (value) =>
                                                    attributeValues[attribute
                                                            .name] =
                                                        value,
                                                decoration: dec(attribute.name),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer Actions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (existing == null &&
                                    (_isOwner || _isAdmin)) {
                                  final hasChecked = locChecked.values.any(
                                    (val) => val == true,
                                  );
                                  if (!hasChecked) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please select at least one location.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                if (trackImei) {
                                  if (existing == null &&
                                      (_isOwner || _isAdmin)) {
                                    for (final locName
                                        in _availableLocationNames) {
                                      if (locChecked[locName] == true) {
                                        final q =
                                            int.tryParse(
                                              locControllers[locName]?.text ??
                                                  '0',
                                            ) ??
                                            0;
                                        final imeis =
                                            locImeiControllers[locName] ?? [];
                                        if (imeis.length != q) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Please fill all IMEI fields for $locName.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                        for (int i = 0; i < imeis.length; i++) {
                                          if (imeis[i].text.trim().isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Please enter IMEI ${i + 1} for $locName.',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                        }
                                      }
                                    }
                                  } else {
                                    final q =
                                        int.tryParse(
                                          stockController.text.trim(),
                                        ) ??
                                        0;
                                    if (singleImeiControllers.length != q) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please fill all IMEI fields.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    for (
                                      int i = 0;
                                      i < singleImeiControllers.length;
                                      i++
                                    ) {
                                      if (singleImeiControllers[i].text
                                          .trim()
                                          .isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please enter IMEI ${i + 1}.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                    }
                                  }
                                }

                                for (final attribute in categoryAttributeDefs) {
                                  final value =
                                      attributeValues[attribute.name]
                                          ?.toString()
                                          .trim() ??
                                      '';
                                  if (attribute.required && value.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please provide ${attribute.name}',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                final enteredPrice =
                                    double.tryParse(
                                      priceController.text.trim(),
                                    ) ??
                                    0.0;
                                final enteredMinPrice =
                                    double.tryParse(
                                      minPriceController.text.trim(),
                                    ) ??
                                    0.0;
                                if (enteredPrice <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid standard selling price.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (enteredMinPrice > enteredPrice) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Minimum selling price cannot be greater than standard selling price.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final looseRatio = double.tryParse(
                                      conversionRatioController.text.trim(),
                                    ) ??
                                    0.0;
                                if (allowLooseSales && looseRatio <= 1.0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Conversion ratio must be greater than 1 for loose unit selling.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                if (allowLooseSales) {
                                  attributeValues['allowLooseSales'] = true;
                                  attributeValues['secondaryUnit'] =
                                      selectedSecondaryUnit.trim().toUpperCase();
                                  attributeValues['unitConversionRatio'] =
                                      looseRatio;
                                  final secP = double.tryParse(
                                    secondaryPriceController.text.trim(),
                                  );
                                  if (secP != null && secP > 0) {
                                    attributeValues['secondaryPrice'] = secP;
                                  } else {
                                    attributeValues.remove('secondaryPrice');
                                  }
                                } else {
                                  attributeValues.remove('allowLooseSales');
                                  attributeValues.remove('secondaryUnit');
                                  attributeValues.remove('unitConversionRatio');
                                  attributeValues.remove('secondaryPrice');
                                }

                                final item = _ProductItem(
                                  id: idController.text.trim(),
                                  name: nameController.text.trim(),
                                  category: selectedCategory,
                                  barcode: barcodeController.text.trim(),
                                  description: descriptionController.text
                                      .trim(),
                                  price: enteredPrice,
                                  minPrice: enteredMinPrice,
                                  costPrice: double.tryParse(
                                    costController.text.trim(),
                                  ),
                                  stock: trackImei
                                      ? (existing == null &&
                                                (_isOwner || _isAdmin)
                                            ? 0.0
                                            : singleImeiControllers.length
                                                  .toDouble())
                                      : (existing == null &&
                                                (_isOwner || _isAdmin)
                                            ? 0.0
                                            : (double.tryParse(
                                                    stockController.text.trim(),
                                                  ) ??
                                                  0.0)),
                                  minStock:
                                      double.tryParse(
                                        minStockController.text.trim(),
                                      ) ??
                                      0.0,
                                  measureUnit: selectedMeasureUnit,
                                  productType: selectedType == 'Service'
                                      ? 'SERVICE'
                                      : 'PRODUCT',
                                  warrantyMonths:
                                      int.tryParse(
                                        warrantyController.text.trim(),
                                      ) ??
                                      0,
                                  expiryDate: selectedExpiryDate,
                                  expiryReminderMode:
                                      selectedExpiryReminderMode,
                                  expiryReminderDays:
                                      selectedExpiryReminderMode == 'CUSTOM'
                                      ? (int.tryParse(
                                              expiryReminderDaysController.text
                                                  .trim(),
                                            ) ??
                                            7)
                                      : (selectedExpiryReminderMode == 'MONTH'
                                            ? 30
                                            : 7),
                                  attributeValues: Map<String, dynamic>.from(
                                    attributeValues,
                                  ),
                                  supplierId: selectedSupplierId,
                                  locationId:
                                      existing == null && (_isOwner || _isAdmin)
                                      ? ''
                                      : (initialLocationId ??
                                            _activeLocationForWrites),
                                  imeis: trackImei
                                      ? (existing == null &&
                                                (_isOwner || _isAdmin)
                                            ? null
                                            : jsonEncode(
                                                singleImeiControllers
                                                    .map((c) => c.text.trim())
                                                    .toList(),
                                              ))
                                      : null,
                                  imageUrl: selectedImagePath,
                                );

                                if (existing == null &&
                                    (_isOwner || _isAdmin)) {
                                  final selectedLocationStocks =
                                      <String, double>{};
                                  final selectedLocationImeis =
                                      <String, List<String>>{};
                                  for (final locName
                                      in _availableLocationNames) {
                                    if (locChecked[locName] == true) {
                                      final qty =
                                          double.tryParse(
                                            locControllers[locName]!.text
                                                .trim(),
                                          ) ??
                                          0.0;
                                      selectedLocationStocks[locName] = qty;
                                      if (trackImei) {
                                        selectedLocationImeis[locName] =
                                            locImeiControllers[locName]
                                                ?.map((c) => c.text.trim())
                                                .toList() ??
                                            [];
                                      }
                                    }
                                  }
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Navigator.pop(
                                    context,
                                    _ProductDialogResult(
                                      product: item,
                                      locationStocks: selectedLocationStocks,
                                      locationImeis: selectedLocationImeis,
                                    ),
                                  );
                                } else {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Navigator.pop(
                                    context,
                                    _ProductDialogResult(
                                      product: item,
                                      locationStocks: null,
                                      locationImeis: null,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandIndigo,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                existing == null
                                    ? 'Create Product'
                                    : 'Update Product',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );
    Future.delayed(const Duration(milliseconds: 350), () {
      idController.dispose();
      nameController.dispose();
      barcodeController.dispose();
      priceController.dispose();
      minPriceController.dispose();
      stockController.dispose();
      minStockController.dispose();
      descriptionController.dispose();
      costController.dispose();
      warrantyController.dispose();
      expiryReminderDaysController.dispose();
      for (final controller in locControllers.values) {
        controller.dispose();
      }
      for (final list in locImeiControllers.values) {
        for (final controller in list) {
          controller.dispose();
        }
      }
      for (final controller in singleImeiControllers) {
        controller.dispose();
      }
    });
    return result;
  }

  // ---------------------------------------------------------------------------
  // SECTION: Add / Edit Customer Dialog
  // WHAT  : Right-drawer slide-in dialog (460 px wide) for creating or
  //         editing a customer record.  Fields:
  //           Ã¢â‚¬Â¢ Name *, Vehicle number, Credit limit, Credit due days
  //           Ã¢â‚¬Â¢ Phone *, Email
  //           Ã¢â‚¬Â¢ Customer type (RETAIL / WHOLESALE / VIP)
  //           Ã¢â‚¬Â¢ Discount %, Address *
  //           Ã¢â‚¬Â¢ Shipping address (shown only when _enableCod is true)
  //           Ã¢â‚¬Â¢ Notes
  //         Validation: name + phone + address are required.
  //         Returns _CustomerItem? (null = cancelled).
  // WHERE : Called from the Customers tab Add / Edit actions.
  // TODO  : Show loyalty-points balance in edit mode; add phone-number
  //         formatter / validator; support multiple contact numbers.
  // ---------------------------------------------------------------------------
  Future<_CustomerItem?> _showCustomerDialog({_CustomerItem? existing}) async {
    final self = this;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final vehicleController = TextEditingController(
      text: existing?.vehicleNumber ?? '',
    );
    final addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    final shippingAddressController = TextEditingController(
      text: existing?.shippingAddress ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final creditLimitController = TextEditingController(
      text: (existing?.creditLimit ?? 0).toString(),
    );
    final creditDueDaysController = TextEditingController(
      text: (existing?.creditDueDays ?? 30).toString(),
    );

    final discountController = TextEditingController(
      text: (existing?.discountPercent ?? 0.0).toString(),
    );
    String selectedCustomerType = existing?.customerType ?? 'RETAIL';

    final created = await showGeneralDialog<_CustomerItem>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: 'AddCustomer',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: ResponsiveLayout.adaptiveDialogWidth(context, 460),
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).viewInsets.bottom,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              existing == null
                                  ? 'Add New Customer'
                                  : 'Edit Customer',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            20 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Customer Name *'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter customer name',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Vehicle Number (License Plate)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: vehicleController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g., ABC-1234',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Credit Limit'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: creditLimitController,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 14),
                              const Text('Credit Due Days'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: creditDueDaysController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'e.g., 30',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Phone Number *'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Enter phone number',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Email Address'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter email address',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Customer Type *'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedCustomerType,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'RETAIL',
                                    child: Text('Retail'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'WHOLESALE',
                                    child: Text('Wholesale'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'VIP',
                                    child: Text('VIP'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(
                                      () => selectedCustomerType = val,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 14),
                              const Text('Discount Percentage (%)'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: discountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'e.g., 5.0',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Address *'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: addressController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Enter address',
                                ),
                              ),
                              if (self._enableCod) ...[
                                const SizedBox(height: 14),
                                const Text('Shipping Address (for COD)'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: shippingAddressController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Enter shipping address for delivery',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              const Text('Notes'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: notesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Additional notes',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                final name = nameController.text.trim();
                                final phone = phoneController.text.trim();
                                final address = addressController.text.trim();

                                if (name.isEmpty ||
                                    phone.isEmpty ||
                                    address.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Customer name, phone number, and address are required.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final id =
                                    existing?.id ??
                                    'C${DateTime.now().microsecondsSinceEpoch}';
                                Navigator.pop(
                                  context,
                                  _CustomerItem(
                                    id: id,
                                    name: name,
                                    vehicleNumber: vehicleController.text
                                        .trim(),
                                    phone: phone,
                                    email: emailController.text.trim(),
                                    address: address,
                                    notes: notesController.text.trim(),
                                    shippingAddress: self._enableCod
                                        ? shippingAddressController.text.trim()
                                        : (existing?.shippingAddress ?? ''),
                                    creditLimit:
                                        double.tryParse(
                                          creditLimitController.text.trim(),
                                        ) ??
                                        0,
                                    creditDueDays:
                                        int.tryParse(
                                          creditDueDaysController.text.trim(),
                                        )?.clamp(1, 3650).toInt() ??
                                        30,
                                    currentBalance:
                                        existing?.currentBalance ?? 0,
                                    loyaltyPoints: existing?.loyaltyPoints ?? 0,
                                    customerType: selectedCustomerType,
                                    discountPercent:
                                        double.tryParse(
                                          discountController.text.trim(),
                                        ) ??
                                        0.0,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandIndigo,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                existing == null
                                    ? 'Create Customer'
                                    : 'Update Customer',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );

    // Delay disposal of controllers to prevent "TextEditingController was used after being disposed"
    // or "_dependents.isEmpty: is not true" during the transition out animation (220ms).
    Future.delayed(const Duration(milliseconds: 300), () {
      nameController.dispose();
      vehicleController.dispose();
      addressController.dispose();
      shippingAddressController.dispose();
      notesController.dispose();
      phoneController.dispose();
      emailController.dispose();
      creditLimitController.dispose();
      creditDueDaysController.dispose();
      discountController.dispose();
    });

    return created;
  }

  // ---------------------------------------------------------------------------
  // SECTION: Add / Edit Attendance Dialog
  // WHAT  : Right-drawer slide-in dialog for creating or editing an attendance
  //         record.  Fields:
  //           Ã¢â‚¬Â¢ Employee selector (dropdown over _employees list)
  //           Ã¢â‚¬Â¢ Date (tappable field that opens a DatePicker)
  //           Ã¢â‚¬Â¢ Clock-in / Clock-out time fields with 30-min autocomplete list
  //           Ã¢â‚¬Â¢ Regular hours, Overtime hours
  //           Ã¢â‚¬Â¢ Status (Present / Absent / Late / Half Day / Leave)
  //           Ã¢â‚¬Â¢ Is Holiday toggle, Notes
  //         Validation: employee selected; clock-in before clock-out.
  //         Returns _AttendanceRecordItem? (null = cancelled).
  // WHERE : Called from the HR / Attendance tab Add / Edit actions.
  // TODO  : Auto-calculate regular & overtime hours from clock-in/out times;
  //         support multiple shifts per day; add leave-balance display.
  // ---------------------------------------------------------------------------
  Future<_AttendanceRecordItem?> _showAttendanceDialog({
    _AttendanceRecordItem? existing,
  }) async {
    final self = this;
    final dateController = TextEditingController(
      text: existing != null
          ? _formatDate(existing.date)
          : _formatDate(DateTime.now()),
    );
    final inController = TextEditingController(
      text: existing?.clockIn == '--:--' ? '' : (existing?.clockIn ?? ''),
    );
    final outController = TextEditingController(
      text: existing?.clockOut == '--:--' ? '' : (existing?.clockOut ?? ''),
    );
    final regularHoursController = TextEditingController(
      text: existing?.regularHours.toStringAsFixed(1) ?? '0',
    );
    final overtimeHoursController = TextEditingController(
      text: existing?.overtimeHours.toStringAsFixed(1) ?? '0',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String selectedEmployeeId =
        existing?.employeeId ??
        (self._employees.isEmpty ? '' : self._employees.first.id);
    String status = existing?.status ?? 'Present';
    bool isHoliday = existing?.isHoliday ?? false;
    final timeOptions = List<String>.generate(48, (index) {
      final hour = (index ~/ 2).toString().padLeft(2, '0');
      final minute = index.isEven ? '00' : '30';
      return '$hour:$minute';
    });

    TimeOfDay? parseTime(String raw) {
      final value = raw.trim();
      if (value.isEmpty) return null;

      final normalized = value.toUpperCase().replaceAll('.', '');
      final amPmMatch = RegExp(
        r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      ).firstMatch(normalized);
      if (amPmMatch != null) {
        final hour12 = int.tryParse(amPmMatch.group(1) ?? '');
        final minute = int.tryParse(amPmMatch.group(2) ?? '');
        final meridiem = amPmMatch.group(3);
        if (hour12 == null || minute == null) return null;
        if (hour12 < 1 || hour12 > 12 || minute < 0 || minute > 59) {
          return null;
        }
        final hour24 = (hour12 % 12) + (meridiem == 'PM' ? 12 : 0);
        return TimeOfDay(hour: hour24, minute: minute);
      }

      final hhmmMatch = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
      if (hhmmMatch == null) return null;
      final hour = int.tryParse(hhmmMatch.group(1) ?? '');
      final minute = int.tryParse(hhmmMatch.group(2) ?? '');
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    void recalculateWorkedHours(void Function(VoidCallback) updateUi) {
      if (status != 'Present' || isHoliday) {
        updateUi(() {
          regularHoursController.text = '0.0';
          overtimeHoursController.text = '0.0';
        });
        return;
      }

      final inTime = parseTime(inController.text);
      final outTime = parseTime(outController.text);
      if (inTime == null || outTime == null) {
        updateUi(() {
          regularHoursController.text = '0.0';
          overtimeHoursController.text = '0.0';
        });
        return;
      }

      var inMinutes = inTime.hour * 60 + inTime.minute;
      var outMinutes = outTime.hour * 60 + outTime.minute;
      if (outMinutes < inMinutes) {
        outMinutes += 24 * 60;
      }

      final totalHours = ((outMinutes - inMinutes) / 60)
          .clamp(0, 24)
          .toDouble();
      final regular = totalHours > 8 ? 8.0 : totalHours;
      final overtime = (totalHours - regular).clamp(0, 24).toDouble();

      updateUi(() {
        regularHoursController.text = regular.toStringAsFixed(1);
        overtimeHoursController.text = overtime.toStringAsFixed(1);
      });
    }

    final created = await showGeneralDialog<_AttendanceRecordItem>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: 'AddAttendance',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final dialogCompact =
                MediaQuery.of(context).size.width < UiBreakpoints.tablet;
            return Align(
              alignment: Alignment.centerRight,
              child: SafeArea(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: SizedBox(
                    width: _adaptiveWidth(
                      620,
                      minWidth: 320,
                      horizontalPadding: 0,
                    ),
                    height:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).viewInsets.bottom,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  existing == null
                                      ? 'Add New Attendance Record'
                                      : 'Edit Attendance Record',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: dialogCompact ? 26 : 34,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              20 + MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Employee *'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedEmployeeId.isEmpty
                                      ? null
                                      : selectedEmployeeId,
                                  items: self._employees
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e.id,
                                          child: Text(e.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setLocal(() => selectedEmployeeId = value);
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (dialogCompact)
                                  Column(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Date'),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: dateController,
                                            readOnly: true,
                                            onTap: () async {
                                              final parsed =
                                                  DateTime.tryParse(
                                                    dateController.text,
                                                  ) ??
                                                  DateTime.now();
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate: parsed,
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime.now()
                                                        .add(
                                                          const Duration(
                                                            days: 365,
                                                          ),
                                                        ),
                                                  );
                                              if (picked != null) {
                                                setLocal(() {
                                                  dateController.text =
                                                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                                });
                                              }
                                            },
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              suffixIcon: Icon(
                                                Icons.calendar_today_outlined,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Status'),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<String>(
                                            initialValue: status,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'Present',
                                                child: Text('Present'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Absent',
                                                child: Text('Absent'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Leave',
                                                child: Text('Leave'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value == null) return;
                                              setLocal(() => status = value);
                                              recalculateWorkedHours(setLocal);
                                            },
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Date'),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: dateController,
                                              readOnly: true,
                                              onTap: () async {
                                                final parsed =
                                                    DateTime.tryParse(
                                                      dateController.text,
                                                    ) ??
                                                    DateTime.now();
                                                final picked =
                                                    await showDatePicker(
                                                      context: context,
                                                      initialDate: parsed,
                                                      firstDate: DateTime(2000),
                                                      lastDate: DateTime.now()
                                                          .add(
                                                            const Duration(
                                                              days: 365,
                                                            ),
                                                          ),
                                                    );
                                                if (picked != null) {
                                                  setLocal(() {
                                                    dateController.text =
                                                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                                  });
                                                }
                                              },
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                suffixIcon: Icon(
                                                  Icons.calendar_today_outlined,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Status'),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              initialValue: status,
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'Present',
                                                  child: Text('Present'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'Absent',
                                                  child: Text('Absent'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'Leave',
                                                  child: Text('Leave'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                if (value == null) return;
                                                setLocal(() => status = value);
                                                recalculateWorkedHours(
                                                  setLocal,
                                                );
                                              },
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                if (dialogCompact)
                                  Column(
                                    children: [
                                      _buildAttendanceTimeField(
                                        label: 'In (HH:mm or h:mm AM/PM)',
                                        controller: inController,
                                        timeOptions: timeOptions,
                                        onChanged: () =>
                                            recalculateWorkedHours(setLocal),
                                        setLocal: setLocal,
                                      ),
                                      const SizedBox(height: 10),
                                      _buildAttendanceTimeField(
                                        label: 'Out (HH:mm or h:mm AM/PM)',
                                        controller: outController,
                                        timeOptions: timeOptions,
                                        onChanged: () =>
                                            recalculateWorkedHours(setLocal),
                                        setLocal: setLocal,
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildAttendanceTimeField(
                                          label: 'In (HH:mm or h:mm AM/PM)',
                                          controller: inController,
                                          timeOptions: timeOptions,
                                          onChanged: () =>
                                              recalculateWorkedHours(setLocal),
                                          setLocal: setLocal,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildAttendanceTimeField(
                                          label: 'Out (HH:mm or h:mm AM/PM)',
                                          controller: outController,
                                          timeOptions: timeOptions,
                                          onChanged: () =>
                                              recalculateWorkedHours(setLocal),
                                          setLocal: setLocal,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                if (dialogCompact)
                                  Column(
                                    children: [
                                      _labeledTextField(
                                        'Regular Hours',
                                        regularHoursController,
                                        keyboardType: TextInputType.number,
                                        readOnly: true,
                                      ),
                                      const SizedBox(height: 10),
                                      _labeledTextField(
                                        'Overtime Hours',
                                        overtimeHoursController,
                                        keyboardType: TextInputType.number,
                                        readOnly: true,
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _labeledTextField(
                                          'Regular Hours',
                                          regularHoursController,
                                          keyboardType: TextInputType.number,
                                          readOnly: true,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _labeledTextField(
                                          'Overtime Hours',
                                          overtimeHoursController,
                                          keyboardType: TextInputType.number,
                                          readOnly: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                _labeledTextField(
                                  'Notes',
                                  notesController,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 10),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: isHoliday,
                                  onChanged: (value) {
                                    setLocal(() => isHoliday = value ?? false);
                                    recalculateWorkedHours(setLocal);
                                  },
                                  title: const Text('Mark as Holiday'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (selectedEmployeeId.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Select an employee before saving attendance.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final employeeIndex = self._employees
                                      .indexWhere(
                                        (e) => e.id == selectedEmployeeId,
                                      );
                                  if (employeeIndex < 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Selected employee was not found. Please reselect employee.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final employee =
                                      self._employees[employeeIndex];
                                  final dateParts = dateController.text
                                      .trim()
                                      .split('/');
                                  DateTime parsedDate = DateTime.now();
                                  if (dateParts.length == 3) {
                                    parsedDate = DateTime(
                                      int.tryParse(dateParts[2]) ??
                                          DateTime.now().year,
                                      int.tryParse(dateParts[0]) ??
                                          DateTime.now().month,
                                      int.tryParse(dateParts[1]) ??
                                          DateTime.now().day,
                                    );
                                  }

                                  final parsedInTime = parseTime(
                                    inController.text,
                                  );
                                  final parsedOutTime = parseTime(
                                    outController.text,
                                  );
                                  if (status == 'Present' &&
                                      !isHoliday &&
                                      (parsedInTime == null ||
                                          parsedOutTime == null)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Enter valid In and Out times (for example 09:00 or 9:00 AM).',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  recalculateWorkedHours((fn) => fn());

                                  Navigator.pop(
                                    context,
                                    _AttendanceRecordItem(
                                      id:
                                          existing?.id ??
                                          'AT${DateTime.now().microsecondsSinceEpoch}',
                                      employeeId: employee.id,
                                      employeeName: employee.name,
                                      date: parsedDate,
                                      status: status,
                                      clockIn: inController.text.trim().isEmpty
                                          ? '--:--'
                                          : inController.text.trim(),
                                      clockOut:
                                          outController.text.trim().isEmpty
                                          ? '--:--'
                                          : outController.text.trim(),
                                      regularHours:
                                          double.tryParse(
                                            regularHoursController.text.trim(),
                                          ) ??
                                          0,
                                      overtimeHours:
                                          double.tryParse(
                                            overtimeHoursController.text.trim(),
                                          ) ??
                                          0,
                                      notes: notesController.text.trim(),
                                      isHoliday: isHoliday,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brandIndigo,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  existing == null
                                      ? 'Create Attendance'
                                      : 'Update Attendance',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      dateController.dispose();
      inController.dispose();
      outController.dispose();
      regularHoursController.dispose();
      overtimeHoursController.dispose();
      notesController.dispose();
    });

    return created;
  }

  // ---------------------------------------------------------------------------
  // SECTION: Add / Edit Payroll Record Dialog
  // WHAT  : Right-drawer slide-in dialog for creating or editing a payroll
  //         record.  Fields:
  //           Ã¢â‚¬Â¢ Employee selector
  //           Ã¢â‚¬Â¢ Pay period (month + year dropdowns)
  //           Ã¢â‚¬Â¢ Base salary, Overtime pay, Deductions, Bonuses
  //           Ã¢â‚¬Â¢ Notes
  //         Computes: net pay = base + overtime + bonuses - deductions.
  //         Returns _PayrollRecordItem? (null = cancelled).
  // WHERE : Called from the HR / Payroll tab Add / Edit actions.
  // TODO  : Auto-populate base salary from the selected employee record;
  //         auto-compute overtime from attendance data;
  //         add payslip PDF generation / email sending.
  // ---------------------------------------------------------------------------
  Future<_PayrollRecordItem?> _showPayrollDialog({
    _PayrollRecordItem? existing,
  }) async {
    final self = this;
    String selectedEmployeeId =
        existing?.employeeId ??
        (self._employees.isEmpty ? '' : self._employees.first.id);
    final baseSalaryController = TextEditingController(
      text: existing != null ? existing.baseSalary.toStringAsFixed(2) : '',
    );
    final overtimeController = TextEditingController(
      text: existing?.overtime.toStringAsFixed(2) ?? '0',
    );
    final bonusController = TextEditingController(
      text: existing?.bonus.toStringAsFixed(2) ?? '0',
    );
    final deductionsController = TextEditingController(
      text: existing?.deductions.toStringAsFixed(2) ?? '0',
    );
    final taxController = TextEditingController(
      text: existing?.tax.toStringAsFixed(2) ?? '0',
    );
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    String formatDateInput(DateTime value) {
      final mm = value.month.toString().padLeft(2, '0');
      final dd = value.day.toString().padLeft(2, '0');
      return '$mm/$dd/${value.year}';
    }

    DateTime? parseFlexibleDate(String value) {
      final raw = value.trim();
      if (raw.isEmpty) return null;

      final iso = DateTime.tryParse(raw);
      if (iso != null) {
        return DateTime(iso.year, iso.month, iso.day);
      }

      final parts = raw.split(RegExp(r'[/-]'));
      if (parts.length != 3) return null;

      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a == null || b == null || c == null) return null;

      if (parts[0].length == 4) {
        return DateTime(a, b, c);
      }
      return DateTime(c, a, b);
    }

    final payPeriodStartController = TextEditingController(
      text: existing?.payPeriodStart.isNotEmpty == true
          ? existing!.payPeriodStart
          : formatDateInput(monthStart),
    );
    final payPeriodEndController = TextEditingController(
      text: existing?.payPeriodEnd.isNotEmpty == true
          ? existing!.payPeriodEnd
          : formatDateInput(monthEnd),
    );
    final payDateController = TextEditingController(
      text: existing?.payDate.isNotEmpty == true
          ? existing!.payDate
          : formatDateInput(now),
    );
    final daysWorkedController = TextEditingController(
      text: existing?.daysWorked.toString() ?? '0',
    );
    final hoursWorkedController = TextEditingController(
      text: existing?.hoursWorked.toStringAsFixed(1) ?? '0',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');

    // Auto-populate from attendance records for the period
    void autoFillFromAttendance(
      String empId,
      void Function(VoidCallback) setStateLocal,
    ) {
      final employee = self._employees.firstWhere(
        (e) => e.id == empId,
        orElse: () => _EmployeeItem(id: '', name: '', role: '', active: true),
      );
      final start = parseFlexibleDate(payPeriodStartController.text);
      final end = parseFlexibleDate(payPeriodEndController.text);
      if (start == null || end == null) return;
      final records = self._attendanceRecords
          .where(
            (r) =>
                r.employeeId == empId &&
                !r.date.isBefore(start) &&
                !r.date.isAfter(end) &&
                r.status == 'Present',
          )
          .toList();
      final totalRegular = records.fold<double>(
        0,
        (s, r) => s + r.regularHours,
      );
      final totalOt = records.fold<double>(0, (s, r) => s + r.overtimeHours);
      final days = records.length;
      final otRate = double.tryParse(self._payrollOtRate) ?? 1.5;
      setStateLocal(() {
        daysWorkedController.text = days.toString();
        hoursWorkedController.text = (totalRegular + totalOt).toStringAsFixed(
          1,
        );
        if (employee.paymentType == 'Hourly') {
          final hourlyPay = totalRegular * employee.baseSalary;
          final otPay = totalOt * employee.baseSalary * otRate;
          baseSalaryController.text = hourlyPay.toStringAsFixed(2);
          overtimeController.text = otPay.toStringAsFixed(2);
        }
      });
    }

    void recalculateWorkedHours(void Function(VoidCallback) setStateLocal) {
      final empId = selectedEmployeeId;
      if (empId.isNotEmpty) {
        autoFillFromAttendance(empId, setStateLocal);
        return;
      }
      final start = parseFlexibleDate(payPeriodStartController.text);
      final end = parseFlexibleDate(payPeriodEndController.text);
      if (start == null || end == null || end.isBefore(start)) {
        return;
      }
      final workedDays = end.difference(start).inDays + 1;
      setStateLocal(() {
        daysWorkedController.text = workedDays.toString();
        hoursWorkedController.text = (workedDays * 8).toStringAsFixed(1);
      });
    }

    if (self._employees.isNotEmpty && existing == null) {
      baseSalaryController.text = self._employees.first.baseSalary
          .toStringAsFixed(2);
    }

    final created = await showGeneralDialog<_PayrollRecordItem>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: 'AddPayroll',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogCtx, setLocal) {
            void safeSetLocal(VoidCallback fn) {
              if (dialogCtx.mounted) {
                setLocal(fn);
              }
            }

            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Theme.of(dialogCtx).colorScheme.surface,
                child: SizedBox(
                  width: ResponsiveLayout.adaptiveDialogWidth(dialogCtx, 760),
                  height:
                      MediaQuery.of(dialogCtx).size.height -
                      MediaQuery.of(dialogCtx).viewInsets.bottom,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(dialogCtx).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              existing == null
                                  ? 'Add Payroll Record'
                                  : 'Edit Payroll Record',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            20 + MediaQuery.of(dialogCtx).viewInsets.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Employee *'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue:
                                    self._employees.any(
                                      (e) => e.id == selectedEmployeeId,
                                    )
                                    ? selectedEmployeeId
                                    : (self._employees.isNotEmpty
                                          ? self._employees.first.id
                                          : null),
                                items: self._employees
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.id,
                                        child: Text(e.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  final employee = self._employees.firstWhere(
                                    (e) => e.id == value,
                                    orElse: () => _EmployeeItem(
                                      id: '',
                                      name: '',
                                      role: '',
                                      active: true,
                                    ),
                                  );
                                  safeSetLocal(() {
                                    selectedEmployeeId = value;
                                    if (employee.paymentType != 'Hourly') {
                                      baseSalaryController.text = employee
                                          .baseSalary
                                          .toStringAsFixed(2);
                                    }
                                  });
                                  autoFillFromAttendance(value, safeSetLocal);
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Builder(
                                      builder: (_) {
                                        final emp = self._employees.firstWhere(
                                          (e) => e.id == selectedEmployeeId,
                                          orElse: () => _EmployeeItem(
                                            id: '',
                                            name: '',
                                            role: '',
                                            active: true,
                                          ),
                                        );
                                        final isHourly =
                                            emp.paymentType == 'Hourly';
                                        return _labeledTextField(
                                          isHourly
                                              ? 'Hourly Rate Pay (auto-calc)'
                                              : 'Base Salary *',
                                          baseSalaryController,
                                          keyboardType: TextInputType.number,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Builder(
                                      builder: (_) {
                                        final emp = self._employees.firstWhere(
                                          (e) => e.id == selectedEmployeeId,
                                          orElse: () => _EmployeeItem(
                                            id: '',
                                            name: '',
                                            role: '',
                                            active: true,
                                          ),
                                        );
                                        return _labeledTextField(
                                          emp.paymentType == 'Hourly'
                                              ? 'Overtime Pay (auto-calc)'
                                              : 'Overtime',
                                          overtimeController,
                                          keyboardType: TextInputType.number,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _labeledTextField(
                                      'Bonus',
                                      bonusController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      'Deductions',
                                      deductionsController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _labeledTextField(
                                      'Tax',
                                      taxController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      'Pay Period Start *',
                                      payPeriodStartController,
                                      readOnly: true,
                                      onTap: () async {
                                        final parsed =
                                            parseFlexibleDate(
                                              payPeriodStartController.text,
                                            ) ??
                                            DateTime.now();
                                        final picked = await showDatePicker(
                                          context: dialogCtx,
                                          initialDate: parsed,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 3650),
                                          ),
                                        );
                                        if (picked != null) {
                                          safeSetLocal(() {
                                            payPeriodStartController.text =
                                                formatDateInput(picked);
                                          });
                                          recalculateWorkedHours(safeSetLocal);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _labeledTextField(
                                      'Pay Period End *',
                                      payPeriodEndController,
                                      readOnly: true,
                                      onTap: () async {
                                        final parsed =
                                            parseFlexibleDate(
                                              payPeriodEndController.text,
                                            ) ??
                                            DateTime.now();
                                        final picked = await showDatePicker(
                                          context: dialogCtx,
                                          initialDate: parsed,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 3650),
                                          ),
                                        );
                                        if (picked != null) {
                                          safeSetLocal(() {
                                            payPeriodEndController.text =
                                                formatDateInput(picked);
                                          });
                                          recalculateWorkedHours(safeSetLocal);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      'Pay Date *',
                                      payDateController,
                                      readOnly: true,
                                      onTap: () async {
                                        final parsed =
                                            parseFlexibleDate(
                                              payDateController.text,
                                            ) ??
                                            DateTime.now();
                                        final picked = await showDatePicker(
                                          context: dialogCtx,
                                          initialDate: parsed,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 3650),
                                          ),
                                        );
                                        if (picked != null) {
                                          safeSetLocal(() {
                                            payDateController.text =
                                                formatDateInput(picked);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _labeledTextField(
                                      'Days Worked',
                                      daysWorkedController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      'Hours Worked',
                                      hoursWorkedController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    recalculateWorkedHours(safeSetLocal),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text(
                                  'Recalculate from Attendance',
                                ),
                              ),
                              const SizedBox(height: 10),
                              _labeledTextField(
                                'Notes',
                                notesController,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(dialogCtx).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                final employee = self._employees.firstWhere(
                                  (e) => e.id == selectedEmployeeId,
                                  orElse: () => _EmployeeItem(
                                    id: 'EMP',
                                    name: 'Employee',
                                    role: 'STAFF',
                                    active: true,
                                  ),
                                );
                                final baseSalary =
                                    double.tryParse(
                                      baseSalaryController.text.trim(),
                                    ) ??
                                    0;
                                final overtime =
                                    double.tryParse(
                                      overtimeController.text.trim(),
                                    ) ??
                                    0;
                                final bonus =
                                    double.tryParse(
                                      bonusController.text.trim(),
                                    ) ??
                                    0;
                                final deductions =
                                    double.tryParse(
                                      deductionsController.text.trim(),
                                    ) ??
                                    0;
                                final tax =
                                    double.tryParse(
                                      taxController.text.trim(),
                                    ) ??
                                    0;
                                Navigator.pop(
                                  dialogCtx,
                                  _PayrollRecordItem(
                                    id:
                                        existing?.id ??
                                        'PR${DateTime.now().millisecondsSinceEpoch}',
                                    employeeId: employee.id,
                                    employeeName: employee.name,
                                    paymentType: employee.paymentType,
                                    baseSalary: baseSalary,
                                    overtime: overtime,
                                    bonus: bonus,
                                    deductions: deductions,
                                    tax: tax,
                                    payPeriodStart: payPeriodStartController
                                        .text
                                        .trim(),
                                    payPeriodEnd: payPeriodEndController.text
                                        .trim(),
                                    payDate: payDateController.text.trim(),
                                    daysWorked:
                                        int.tryParse(
                                          daysWorkedController.text.trim(),
                                        ) ??
                                        0,
                                    hoursWorked:
                                        double.tryParse(
                                          hoursWorkedController.text.trim(),
                                        ) ??
                                        0,
                                    notes: notesController.text.trim(),
                                    status: existing?.status ?? 'Pending',
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandIndigo,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                existing == null
                                    ? 'Create Payroll Record'
                                    : 'Update Payroll Record',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      baseSalaryController.dispose();
      overtimeController.dispose();
      bonusController.dispose();
      deductionsController.dispose();
      taxController.dispose();
      payPeriodStartController.dispose();
      payPeriodEndController.dispose();
      payDateController.dispose();
      daysWorkedController.dispose();
      hoursWorkedController.dispose();
      notesController.dispose();
    });

    return created;
  }

  // ---------------------------------------------------------------------------
  // SECTION: Add / Edit Employee Dialog
  // WHAT  : Right-drawer slide-in dialog for creating or editing an employee
  //         profile.  Fields:
  //           Ã¢â‚¬Â¢ Name *, Phone *, Email
  //           Ã¢â‚¬Â¢ Role (dropdown from predefined list)
  //           Ã¢â‚¬Â¢ Department, Join date, Base salary
  //           Ã¢â‚¬Â¢ Address, Notes
  //         Validation: name + phone required.
  //         Returns _EmployeeItem? (null = cancelled).
  // WHERE : Called from the HR / Employees tab Add / Edit actions.
  // TODO  : Add profile photo upload; integrate base salary auto-fill into
  //         payroll dialog; add emergency contact field.
  // ---------------------------------------------------------------------------
  Future<_EmployeeItem?> _showEmployeeDialog({_EmployeeItem? existing}) async {
    final self = this;
    final firstNameController = TextEditingController(
      text: existing?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: existing?.lastName ?? '',
    );
    final emailController = TextEditingController(text: existing?.email ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final positionController = TextEditingController(
      text: existing?.position ?? existing?.role ?? '',
    );
    final departmentController = TextEditingController(
      text: existing?.department ?? '',
    );
    String paymentType = existing?.paymentType.isNotEmpty == true
        ? existing!.paymentType
        : 'Monthly';
    final baseSalaryController = TextEditingController(
      text: existing == null ? '0' : existing.baseSalary.toStringAsFixed(2),
    );
    final hireDateController = TextEditingController(
      text: existing?.hireDate ?? 'mm/dd/yyyy',
    );
    bool active = existing?.active ?? true;
    final bankAccountController = TextEditingController(
      text: existing?.bankAccount ?? '',
    );
    final addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    final emergencyContactController = TextEditingController(
      text: existing?.emergencyContact ?? '',
    );
    final emergencyPhoneController = TextEditingController(
      text: existing?.emergencyPhone ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final locationOptions = self._availableLocationNames;
    final permissionOptions = _DashboardScreenState._userPermissionOptions;
    // Prefer the currently selected branch so a newly created employee is
    // visible under the same location filter the user is viewing.
    final defaultLocations = <String>[];
    if (existing == null) {
      final currentScope = self._selectedLocationScope.trim();
      final isAllLocations =
          currentScope.isEmpty ||
          currentScope.toLowerCase() ==
              _DashboardScreenState._allLocationsLabel.toLowerCase();
      if (!isAllLocations) {
        final match = locationOptions.firstWhere(
          (l) => l.trim().toLowerCase() == currentScope.toLowerCase(),
          orElse: () => '',
        );
        if (match.isNotEmpty) {
          defaultLocations.add(match);
        } else {
          defaultLocations.add(currentScope);
        }
      } else if (locationOptions.isNotEmpty) {
        defaultLocations.add(locationOptions.first);
      }
    }
    final selectedLocations = <String>{
      ...(existing?.assignedLocations ?? defaultLocations),
    };
    selectedLocations.removeWhere((l) => !locationOptions.contains(l));
    if (selectedLocations.isEmpty && locationOptions.isNotEmpty) {
      selectedLocations.add(locationOptions.first);
    }
    final selectedPermissions = <String>{
      ...(existing?.permissions ?? const <String>[]),
    };
    if (selectedPermissions.isEmpty) {
      selectedPermissions.addAll(const {'POS', 'SALES', 'CUSTOMERS'});
    }

    final created = await showGeneralDialog<_EmployeeItem>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: 'AddEmployee',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: ResponsiveLayout.adaptiveDialogWidth(context, 760),
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).viewInsets.bottom,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              existing == null
                                  ? 'Add New Employee'
                                  : 'Edit Employee',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            20 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _labeledTextField(
                                      'First Name *',
                                      firstNameController,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      'Last Name *',
                                      lastNameController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _labeledTextField(
                                      'Email',
                                      emailController,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      'Phone',
                                      phoneController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _labeledTextField(
                                      'Position',
                                      positionController,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      'Department',
                                      departmentController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Payment Type *'),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          initialValue: paymentType,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Monthly',
                                              child: Text('Monthly'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Hourly',
                                              child: Text('Hourly'),
                                            ),
                                          ],
                                          onChanged: (v) => setLocal(
                                            () =>
                                                paymentType = v ?? paymentType,
                                          ),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      paymentType == 'Hourly'
                                          ? 'Hourly Rate'
                                          : 'Monthly Salary',
                                      baseSalaryController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _labeledTextField(
                                      'Hire Date *',
                                      hireDateController,
                                      readOnly: true,
                                      onTap: () async {
                                        DateTime initialDate = DateTime.now();
                                        final parsed = DateTime.tryParse(
                                          hireDateController.text.trim(),
                                        );
                                        if (parsed != null) {
                                          initialDate = parsed;
                                        } else {
                                          final parts = hireDateController.text
                                              .trim()
                                              .split('/');
                                          if (parts.length == 3) {
                                            final month = int.tryParse(
                                              parts[0],
                                            );
                                            final day = int.tryParse(parts[1]);
                                            final year = int.tryParse(parts[2]);
                                            if (month != null &&
                                                day != null &&
                                                year != null) {
                                              initialDate = DateTime(
                                                year,
                                                month,
                                                day,
                                              );
                                            }
                                          }
                                        }

                                        final picked = await showDatePicker(
                                          context: self.context,
                                          initialDate: initialDate,
                                          firstDate: DateTime(1970),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 3650),
                                          ),
                                        );
                                        if (picked == null) return;
                                        setLocal(() {
                                          hireDateController.text =
                                              '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      'Bank Account',
                                      bankAccountController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Active'),
                                value: active,
                                onChanged: (value) =>
                                    setLocal(() => active = value),
                              ),
                              const SizedBox(height: 12),
                              _labeledTextField(
                                'Address',
                                addressController,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _labeledTextField(
                                      'Emergency Contact',
                                      emergencyContactController,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledTextField(
                                      'Emergency Phone',
                                      emergencyPhoneController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _labeledTextField(
                                'Notes',
                                notesController,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              const Text('Assigned Locations'),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: locationOptions
                                      .map(
                                        (loc) => FilterChip(
                                          label: Text(loc),
                                          selected: selectedLocations.contains(
                                            loc,
                                          ),
                                          onSelected: (selected) {
                                            setLocal(() {
                                              if (selected) {
                                                selectedLocations.add(loc);
                                              } else {
                                                selectedLocations.remove(loc);
                                              }
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('Permissions'),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: permissionOptions
                                      .map(
                                        (option) => FilterChip(
                                          label: Text(option.label),
                                          selected: selectedPermissions
                                              .contains(
                                                option.label.toUpperCase(),
                                              ),
                                          onSelected: (selected) {
                                            setLocal(() {
                                              final value = option.label
                                                  .toUpperCase();
                                              if (selected) {
                                                selectedPermissions.add(value);
                                              } else {
                                                selectedPermissions.remove(
                                                  value,
                                                );
                                              }
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                final firstName = firstNameController.text
                                    .trim();
                                final lastName = lastNameController.text.trim();
                                final fullName = '$firstName $lastName'.trim();
                                Navigator.pop(
                                  context,
                                  _EmployeeItem(
                                    id:
                                        existing?.id ??
                                        'E${DateTime.now().microsecondsSinceEpoch}',
                                    name: fullName.isEmpty
                                        ? 'Employee'
                                        : fullName,
                                    role: positionController.text.trim().isEmpty
                                        ? 'STAFF'
                                        : positionController.text
                                              .trim()
                                              .toUpperCase(),
                                    active: active,
                                    firstName: firstName,
                                    lastName: lastName,
                                    email: emailController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    position: positionController.text.trim(),
                                    department: departmentController.text
                                        .trim(),
                                    paymentType: paymentType,
                                    baseSalary:
                                        double.tryParse(
                                          baseSalaryController.text.trim(),
                                        ) ??
                                        0,
                                    hireDate: hireDateController.text.trim(),
                                    bankAccount: bankAccountController.text
                                        .trim(),
                                    address: addressController.text.trim(),
                                    emergencyContact: emergencyContactController
                                        .text
                                        .trim(),
                                    emergencyPhone: emergencyPhoneController
                                        .text
                                        .trim(),
                                    notes: notesController.text.trim(),
                                    assignedLocations: selectedLocations
                                        .toList(),
                                    permissions: selectedPermissions.toList(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandIndigo,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                existing == null
                                    ? 'Create Employee'
                                    : 'Update Employee',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );

    // Delay disposal of controllers to prevent "TextEditingController was used after being disposed"
    // or "_dependents.isEmpty: is not true" during the transition out animation (220ms).
    Future.delayed(const Duration(milliseconds: 300), () {
      firstNameController.dispose();
      lastNameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      positionController.dispose();
      departmentController.dispose();
      baseSalaryController.dispose();
      hireDateController.dispose();
      bankAccountController.dispose();
      addressController.dispose();
      emergencyContactController.dispose();
      emergencyPhoneController.dispose();
      notesController.dispose();
    });

    return created;
  }

  // ---------------------------------------------------------------------------
  // SECTION: Labeled Text Field Helper Widget
  // WHAT  : Convenience wrapper that renders a label Text, a 6-px gap, and a
  //         TextField in a Column.  Reduces boilerplate in form dialogs.
  // WHERE : Used inside _showAttendanceDialog, _showEmployeeDialog, and other
  //         dialog form layouts throughout this file.
  // TODO  : Extract to a shared 'widgets/labeled_field.dart' so all dialog
  //         forms across the app use a consistent implementation.
  // ---------------------------------------------------------------------------
  Widget _labeledTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final self = this;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Attendance Time Field Builder
  // WHAT  : Builds a time-input field with an Autocomplete dropdown populated
  //         from a list of 30-minute interval slots (00:00 Ã¢â€ â€™ 23:30).  The
  //         user can type any HH:mm or select from the dropdown.
  // WHERE : Used for the Clock-in and Clock-out fields in _showAttendanceDialog.
  // TODO  : Offer a clock-face TimePicker as an alternative for touch-first
  //         devices; validate the typed value on focus-lost.
  // ---------------------------------------------------------------------------
  Widget _buildAttendanceTimeField({
    required String label,
    required TextEditingController controller,
    required List<String> timeOptions,
    required VoidCallback onChanged,
    required void Function(VoidCallback) setLocal,
  }) {
    final self = this;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (_) => onChanged(),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Select Time',
              onSelected: (value) {
                setLocal(() {
                  controller.text = value;
                });
                onChanged();
              },
              itemBuilder: (context) {
                return timeOptions
                    .map(
                      (time) => PopupMenuItem(value: time, child: Text(time)),
                    )
                    .toList();
              },
              icon: const Icon(Icons.arrow_drop_down),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Add / Edit POS User Dialog
  // WHAT  : Right-drawer slide-in dialog (580 px wide) for managing POS user
  //         accounts.  Fields:
  //           Ã¢â‚¬Â¢ Name *, Username *, Password (* required on create only)
  //           Ã¢â‚¬Â¢ Role (Cashier / Manager / Admin)
  //           Ã¢â‚¬Â¢ Location assignment (multi-select for owners/admins)
  //           Ã¢â‚¬Â¢ Module permission toggles (POS, Inventory, Customers, HR,
  //             Reports, Purchase Orders, Settings)
  //           Ã¢â‚¬Â¢ Granular Sales sub-permissions:
  //               SALES_DISCOUNT, SALES_REFUND, SALES_VOID,
  //               SALES_COST_PRICE_VIEW, SALES_CREDIT, SALES_HOLD, etc.
  //         Validation: name + username required; password required on create.
  //         Returns _UserDialogResult? (null = cancelled).
  // WHERE : Called from the Settings / Users tab Add / Edit actions.
  // TODO  : Add 2-FA toggle (TOTP); enforce configurable password-strength rules;
  //         show last-login timestamp in edit mode.
  // ---------------------------------------------------------------------------
  Future<_UserDialogResult?> _showUserDialog({_UserItem? existing}) async {
    final self = this;
    final idController = TextEditingController(
      text: existing?.id ?? 'U${DateTime.now().microsecondsSinceEpoch}',
    );
    final nameController = TextEditingController(text: existing?.name ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final passwordController = TextEditingController();
    final locationOptions = self._isBranchAdmin
        ? (self._currentUserAssignedLocations.isNotEmpty
            ? self._currentUserAssignedLocations
            : self._availableLocationNames)
        : self._availableLocationNames;
    final allowedRoles = self._isBranchAdmin
        ? const ['CASHIER', 'AGENT', 'DELIVERY']
        : const ['OWNER', 'ADMIN', 'BRANCH ADMIN', 'MANAGER', 'CASHIER', 'AGENT', 'DELIVERY'];
    String role = existing?.role.toUpperCase() ?? 'CASHIER';
    if (!allowedRoles.contains(role)) {
      role = allowedRoles.first;
    }
    bool active = existing?.active ?? true;
    bool showPassword = false;
    final permissionOptions = _DashboardScreenState._userPermissionOptions;
    final selectedPermissions = <String>{
      ...(existing?.permissions ??
          [
            'POS',
            'SALES',
            'PRODUCTS',
            'CUSTOMERS',
          ].map((item) => item.toUpperCase())),
    };
    selectedPermissions.addAll(
      (existing?.permissions ?? const <String>[])
          .map((item) => item.trim().toUpperCase())
          .where((item) => item.isNotEmpty),
    );
    final selectedLocations = <String>{
      ...(existing?.locations ?? const <String>[]),
    };
    if (self._isBranchAdmin) {
      selectedLocations.clear();
      selectedLocations.addAll(locationOptions);
    } else if (selectedLocations.isEmpty && locationOptions.isNotEmpty) {
      selectedLocations.add(locationOptions.first);
    }
    selectedLocations.removeWhere((item) => !locationOptions.contains(item));

    String? dialogError;

    return showGeneralDialog<_UserDialogResult>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: 'UserDialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final screenWidth = MediaQuery.of(context).size.width;
            final dialogCompact = screenWidth < 768;
            final isPhoneScreen = screenWidth < 600;
            return Align(
              alignment: isPhoneScreen
                  ? Alignment.center
                  : Alignment.centerRight,
              child: SafeArea(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 100),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: SizedBox(
                      width: isPhoneScreen
                          ? double.infinity
                          : _adaptiveWidth(
                              560,
                              minWidth: 320,
                              horizontalPadding: 0,
                            ),
                      height: double.infinity,
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    existing == null ? 'Add User' : 'Edit User',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: dialogCompact ? 22 : 32,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                          // Scrollable body
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (dialogError != null) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              dialogError!,
                                              style: TextStyle(
                                                color: Colors.red.shade800,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Text('User ID'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: idController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Auto-generated',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text('Name *'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: nameController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text('Email *'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    existing == null
                                        ? 'Password *'
                                        : 'Password (leave empty to keep current)',
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: !showPassword,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        tooltip: showPassword
                                            ? 'Hide password'
                                            : 'Show password',
                                        icon: Icon(
                                          showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setLocal(
                                            () => showPassword = !showPassword,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text('Role'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey<String>(role),
                                    initialValue: role,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    items: allowedRoles
                                         .map(
                                           (r) => DropdownMenuItem(
                                             value: r,
                                             child: Text(r),
                                           ),
                                         )
                                         .toList(),
                                    onChanged: (v) =>
                                        setLocal(() => role = v ?? role),
                                  ),
                                  const SizedBox(height: 10),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Active'),
                                    value: active,
                                    onChanged: (v) =>
                                        setLocal(() => active = v),
                                  ),
                                  const SizedBox(height: 14),
                                  // Page Access Controls
                                  Row(
                                    children: [
                                      Text(
                                        'Page Access Controls',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () => setLocal(
                                          () => selectedPermissions.addAll(
                                            permissionOptions.map(
                                              (option) => option.viewPermission,
                                            ),
                                          ),
                                        ),
                                        child: const Text('View All'),
                                      ),
                                      TextButton(
                                        onPressed: () => setLocal(
                                          () => selectedPermissions.addAll(
                                            permissionOptions.expand(
                                              (option) => <String>{
                                                option.viewPermission,
                                                option.editPermission,
                                                option.deletePermission,
                                              },
                                            ),
                                          ),
                                        ),
                                        child: const Text('Full'),
                                      ),
                                      TextButton(
                                        onPressed: () => setLocal(
                                          () => selectedPermissions.clear(),
                                        ),
                                        child: const Text('None'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Page / Function',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 60,
                                                child: Text(
                                                  'View',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 60,
                                                child: Text(
                                                  'Edit',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 60,
                                                child: Text(
                                                  'Delete',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1),
                                        ...permissionOptions.map(
                                          (option) => SizedBox(
                                            height: 44,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Text(
                                                      option.label,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 60,
                                                  child: Checkbox(
                                                    value: selectedPermissions
                                                        .contains(
                                                          option.viewPermission,
                                                        ),
                                                    onChanged: (value) {
                                                      setLocal(() {
                                                        if (value ?? false) {
                                                          selectedPermissions.add(
                                                            option
                                                                .viewPermission,
                                                          );
                                                        } else {
                                                          selectedPermissions
                                                              .remove(
                                                                option
                                                                    .viewPermission,
                                                              );
                                                          selectedPermissions
                                                              .remove(
                                                                option
                                                                    .editPermission,
                                                              );
                                                          selectedPermissions
                                                              .remove(
                                                                option
                                                                    .deletePermission,
                                                              );
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 60,
                                                  child: Checkbox(
                                                    value: selectedPermissions
                                                        .contains(
                                                          option.editPermission,
                                                        ),
                                                    onChanged: (value) {
                                                      setLocal(() {
                                                        if (value ?? false) {
                                                          selectedPermissions.add(
                                                            option
                                                                .viewPermission,
                                                          );
                                                          selectedPermissions.add(
                                                            option
                                                                .editPermission,
                                                          );
                                                        } else {
                                                          selectedPermissions
                                                              .remove(
                                                                option
                                                                    .editPermission,
                                                              );
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 60,
                                                  child: Checkbox(
                                                    value: selectedPermissions
                                                        .contains(
                                                          option
                                                              .deletePermission,
                                                        ),
                                                    onChanged: (value) {
                                                      setLocal(() {
                                                        if (value ?? false) {
                                                          selectedPermissions.add(
                                                            option
                                                                .viewPermission,
                                                          );
                                                          selectedPermissions.add(
                                                            option
                                                                .deletePermission,
                                                          );
                                                        } else {
                                                          selectedPermissions
                                                              .remove(
                                                                option
                                                                    .deletePermission,
                                                              );
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Sales Action Permissions (sub-permissions)
                                  Row(
                                    children: [
                                      Text(
                                        'Sales Action Permissions',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(width: 6),
                                      Tooltip(
                                        message:
                                            'These permissions control specific invoice actions.\nActive only when SALES page access is enabled above.',
                                        child: Icon(
                                          Icons.info_outline,
                                          size: 15,
                                          color: const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildSalesSubPermissionToggle(
                                          context: context,
                                          label: 'Edit Bill',
                                          subtitle:
                                              'Allow editing completed invoices',
                                          icon: Icons.edit_note_outlined,
                                          permKey: 'SALES:EDIT_BILL',
                                          selectedPermissions:
                                              selectedPermissions,
                                          setLocal: setLocal,
                                        ),
                                        const Divider(height: 1),
                                        _buildSalesSubPermissionToggle(
                                          context: context,
                                          label: 'Create Duplicate',
                                          subtitle:
                                              'Allow duplicating a past invoice',
                                          icon: Icons.copy_all_outlined,
                                          permKey: 'SALES:CREATE_DUPLICATE',
                                          selectedPermissions:
                                              selectedPermissions,
                                          setLocal: setLocal,
                                        ),
                                        const Divider(height: 1),
                                        _buildSalesSubPermissionToggle(
                                          context: context,
                                          label: 'Cancel Invoice',
                                          subtitle:
                                              'Allow cancelling a completed invoice',
                                          icon: Icons.cancel_outlined,
                                          permKey: 'SALES:CANCEL_INVOICE',
                                          selectedPermissions:
                                              selectedPermissions,
                                          setLocal: setLocal,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  const Text(
                                    'Locations',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: locationOptions
                                        .map(
                                          (loc) => FilterChip(
                                            label: Text(loc),
                                            selected: selectedLocations
                                                .contains(loc),
                                            onSelected: self._isBranchAdmin
                                                ? null
                                                : (selected) {
                                                    setLocal(() {
                                                      if (selected) {
                                                        selectedLocations.add(loc);
                                                      } else {
                                                        selectedLocations.remove(loc);
                                                      }
                                                    });
                                                  },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                          // Footer
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final name = nameController.text.trim();
                                    final email = emailController.text.trim();
                                    final password = passwordController.text
                                        .trim();

                                    if (name.isEmpty) {
                                      setLocal(
                                        () => dialogError =
                                            'Please enter user name.',
                                      );
                                      return;
                                    }
                                    if (email.isEmpty || !email.contains('@')) {
                                      setLocal(
                                        () => dialogError =
                                            'Please enter a valid email address.',
                                      );
                                      return;
                                    }
                                    if (existing == null && password.isEmpty) {
                                      setLocal(
                                        () => dialogError =
                                            'Please enter a password for the new user.',
                                      );
                                      return;
                                    }
                                    if (password.isNotEmpty &&
                                        password.length < 4) {
                                      setLocal(
                                        () => dialogError =
                                            'Password must be at least 4 characters long.',
                                      );
                                      return;
                                    }
                                    if (selectedLocations.isEmpty) {
                                      setLocal(
                                        () => dialogError =
                                            'Please select at least 1 location.',
                                      );
                                      return;
                                    }

                                    setLocal(() => dialogError = null);
                                    Navigator.pop(
                                      context,
                                      _UserDialogResult(
                                        user: _UserItem(
                                          id:
                                              idController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? idController.text.trim()
                                              : 'U${DateTime.now().microsecondsSinceEpoch}',
                                          name: name,
                                          email: email,
                                          role: role,
                                          active: active,
                                          permissions: selectedPermissions
                                              .toList(),
                                          locations: selectedLocations.toList(),
                                        ),
                                        password: password,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandIndigo,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    existing == null ? 'Create User' : 'Save',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Create Coupon Dialog
  // WHAT  : Dialog for creating a new discount coupon.  Fields:
  //           Ã¢â‚¬Â¢ Coupon code (manual entry)
  //           Ã¢â‚¬Â¢ Discount type: Percentage (%) or Fixed Amount
  //           Ã¢â‚¬Â¢ Discount value
  //           Ã¢â‚¬Â¢ Optional expiry date
  //         Returns _CouponItem? (null = cancelled).
  // WHERE : Called from the Marketing / Coupons tab 'Add Coupon' button.
  // TODO  : Add a usage-limit field (max redemptions); generate unique codes
  //         automatically; support minimum order value threshold.
  // ---------------------------------------------------------------------------
  Future<_CouponItem?> _showCouponDialog() async {
    final self = this;
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final discountController = TextEditingController(text: '5');

    return showDialog<_CouponItem>(
      context: self.context,
      builder: (context) => AlertDialog(
        title: const Text('Create Coupon'),
        content: SizedBox(
          width: ResponsiveLayout.adaptiveDialogWidth(context, 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Discount %'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                _CouponItem(
                  code: codeController.text.trim(),
                  description: descriptionController.text.trim(),
                  discountPercent:
                      double.tryParse(discountController.text.trim()) ?? 0,
                  active: true,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Add / Edit Service Job Dialog
  // WHAT  : Right-drawer slide-in dialog for creating or editing a service job.
  //         Fields:
  //           Ã¢â‚¬Â¢ Customer selector, Technician assignment
  //           Ã¢â‚¬Â¢ Device info (make, model, serial number)
  //           Ã¢â‚¬Â¢ Job description, Status, Estimated cost
  //           Ã¢â‚¬Â¢ Parts used (dynamic list), Notes
  //         Returns _ServiceJobItem? (null = cancelled).
  // WHERE : Called from the Service tab job list Add / Edit actions.
  // TODO  : Add file attachment support for before/after device photos;
  //         send SMS/notification to customer on status change.
  // ---------------------------------------------------------------------------
  Future<_ServiceJobItem?> _showServiceDialog({
    _ServiceJobItem? existing,
  }) async {
    final self = this;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final skuController = TextEditingController(text: existing?.sku ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final priceController = TextEditingController(
      text: (existing?.defaultPrice ?? 0).toString(),
    );
    bool active = existing?.active ?? true;
    final isEdit = existing != null;

    return showGeneralDialog<_ServiceJobItem>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: isEdit ? 'EditService' : 'AddService',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: ResponsiveLayout.adaptiveDialogWidth(context, 760),
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).viewInsets.bottom,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isEdit ? 'Edit Service' : 'Add New Service',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            20 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Service Name *'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter service name',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('SKU *'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: skuController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter SKU',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Description'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: descriptionController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Enter service description',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Default Price *'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  hintText: 'Enter price',
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'This is the suggested price. Actual price can be customized at checkout.',
                                style: TextStyle(color: Color(0xFF7E8495)),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Checkbox(
                                    value: active,
                                    onChanged: (v) =>
                                        setLocal(() => active = v ?? true),
                                  ),
                                  const Text(
                                    'Active (available in POS)',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  _ServiceJobItem(
                                    id:
                                        existing?.id ??
                                        'SRV${DateTime.now().microsecondsSinceEpoch}',
                                    title: titleController.text.trim(),
                                    sku: skuController.text.trim(),
                                    description: descriptionController.text
                                        .trim(),
                                    defaultPrice:
                                        double.tryParse(
                                          priceController.text.trim(),
                                        ) ??
                                        0,
                                    active: active,
                                    technician: existing?.technician ?? '',
                                    warranty: existing?.warranty ?? false,
                                    status: existing?.status ?? 'PENDING',
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandIndigo,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                isEdit ? 'Save Changes' : 'Create Service',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Job Card Print Dialog
  // WHAT  : Full-screen dialog that renders a printable Job Card view with:
  //           Ã¢â‚¬Â¢ Customer + technician info header
  //           Ã¢â‚¬Â¢ Service description and device details
  //           Ã¢â‚¬Â¢ Parts list with quantities and unit prices
  //           Ã¢â‚¬Â¢ Cost breakdown (labour + parts) and total
  //           Ã¢â‚¬Â¢ Signature area placeholder
  //         Returns _ServiceJobItem? (null = closed without action).
  // WHERE : Called from the Service tab 'View / Print Job Card' action.
  // TODO  : Integrate with the flutter_printing package to send directly
  //         to a thermal or A4 printer; add company logo to the header.
  // ---------------------------------------------------------------------------

  ({String name, double cost}) _parseJobItemCost(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return (name: '', cost: 0.0);
    if (trimmed.contains('|')) {
      final parts = trimmed.split('|');
      final name = parts[0].trim();
      final costStr = parts
          .sublist(1)
          .join('|')
          .replaceAll(RegExp(r'[^\d.]'), '');
      final cost = double.tryParse(costStr) ?? 0.0;
      return (name: name, cost: cost);
    }
    if (trimmed.contains(':')) {
      final lastColonIdx = trimmed.lastIndexOf(':');
      final name = trimmed.substring(0, lastColonIdx).trim();
      final costStr = trimmed
          .substring(lastColonIdx + 1)
          .replaceAll(RegExp(r'[^\d.]'), '');
      final cost = double.tryParse(costStr);
      if (cost != null) {
        return (name: name, cost: cost);
      }
    }
    return (name: trimmed, cost: 0.0);
  }

  Future<_ServiceJobItem?> _showJobCardDialog({
    _ServiceJobItem? existing,
  }) async {
    final self = this;
    final isEdit = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final phoneController = TextEditingController(
      text: existing?.customerPhone ?? '',
    );
    final emailController = TextEditingController(
      text: existing?.customerEmail ?? '',
    );
    final scheduledDateController = TextEditingController(
      text: existing?.scheduledDate ?? '',
    );
    final scheduledTimeController = TextEditingController(
      text: existing?.scheduledTime ?? '',
    );
    final durationController = TextEditingController(
      text: existing?.estimatedDurationMinutes ?? '0',
    );
    final locationController = TextEditingController(
      text: existing?.location ?? '',
    );
    final deviceInfoController = TextEditingController(
      text: existing?.deviceInfo ?? '',
    );
    final discountController = TextEditingController(
      text: existing != null ? existing.discount.toStringAsFixed(0) : '0',
    );
    final taxController = TextEditingController(
      text: existing != null ? existing.taxAmount.toStringAsFixed(0) : '0',
    );
    final internalNotesController = TextEditingController(
      text: existing?.internalNotes ?? '',
    );
    final customerNotesController = TextEditingController(
      text: existing?.customerNotes ?? '',
    );
    final tagsController = TextEditingController(text: existing?.tags ?? '');

    final List<TextEditingController> serviceNameControllers = [];
    final List<TextEditingController> serviceCostControllers = [];
    if (existing != null && existing.services.isNotEmpty) {
      for (final s in existing.services) {
        final parsed = _parseJobItemCost(s);
        serviceNameControllers.add(TextEditingController(text: parsed.name));
        serviceCostControllers.add(
          TextEditingController(
            text: parsed.cost > 0
                ? (parsed.cost % 1 == 0
                      ? parsed.cost.toInt().toString()
                      : parsed.cost.toStringAsFixed(2))
                : '',
          ),
        );
      }
    } else {
      serviceNameControllers.add(TextEditingController());
      serviceCostControllers.add(TextEditingController());
    }

    final List<TextEditingController> materialNameControllers = [];
    final List<TextEditingController> materialCostControllers = [];
    if (existing != null && existing.materials.isNotEmpty) {
      for (final m in existing.materials) {
        final parsed = _parseJobItemCost(m);
        materialNameControllers.add(TextEditingController(text: parsed.name));
        materialCostControllers.add(
          TextEditingController(
            text: parsed.cost > 0
                ? (parsed.cost % 1 == 0
                      ? parsed.cost.toInt().toString()
                      : parsed.cost.toStringAsFixed(2))
                : '',
          ),
        );
      }
    } else {
      materialNameControllers.add(TextEditingController());
      materialCostControllers.add(TextEditingController());
    }

    final catalogServices = self._serviceJobs
        .where(
          (s) =>
              s.active &&
              s.customerName.isEmpty &&
              s.services.isEmpty &&
              s.materials.isEmpty,
        )
        .toList();

    String selectedPriority = existing?.priority ?? 'NORMAL';
    String selectedStatus = existing?.status ?? 'OPEN';
    String selectedCustomerId = existing != null
        ? (self._customers.any((c) => c.name == existing.customerName)
              ? self._customers
                    .firstWhere((c) => c.name == existing.customerName)
                    .id
              : (self._customers.isNotEmpty ? self._customers.first.id : ''))
        : (self._customers.isNotEmpty ? self._customers.first.id : '');

    if (!isEdit && self._customers.isNotEmpty) {
      final first = self._customers.first;
      phoneController.text = first.phone;
      emailController.text = first.email;
    }

    final created = await showGeneralDialog<_ServiceJobItem>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: 'CreateJobCard',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            double calcServicesCost() {
              double total = 0;
              for (final c in serviceCostControllers) {
                total += double.tryParse(c.text.trim()) ?? 0;
              }
              return total;
            }

            double calcMaterialsCost() {
              double total = 0;
              for (final c in materialCostControllers) {
                total += double.tryParse(c.text.trim()) ?? 0;
              }
              return total;
            }

            final servicesSubtotal = calcServicesCost();
            final materialsSubtotal = calcMaterialsCost();
            final discountVal =
                double.tryParse(discountController.text.trim()) ?? 0;
            final taxVal = double.tryParse(taxController.text.trim()) ?? 0;
            final grandTotal =
                servicesSubtotal + materialsSubtotal - discountVal + taxVal;

            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: ResponsiveLayout.adaptiveDialogWidth(context, 760),
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).viewInsets.bottom,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              isEdit ? 'Edit Job Card' : 'Create New Job Card',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Basic Information',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title *',
                                  hintText:
                                      'e.g., AC Installation, Laptop Repair',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: descriptionController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  hintText: 'Brief description of the job',
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Customer Information',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: selectedCustomerId.isEmpty
                                    ? null
                                    : selectedCustomerId,
                                decoration: const InputDecoration(
                                  labelText: 'Customer *',
                                  border: OutlineInputBorder(),
                                ),
                                items: self._customers
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  final selected = self._customers.firstWhere(
                                    (c) => c.id == value,
                                  );
                                  setLocal(() {
                                    selectedCustomerId = value;
                                    phoneController.text = selected.phone;
                                    emailController.text = selected.email;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Phone'),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: phoneController,
                                          decoration: const InputDecoration(
                                            labelText: 'Phone',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Email'),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: emailController,
                                          decoration: const InputDecoration(
                                            labelText: 'Email',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Services *',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(serviceNameControllers.length, (
                                i,
                              ) {
                                final nameCtrl = serviceNameControllers[i];
                                final costCtrl = serviceCostControllers[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: nameCtrl,
                                          onChanged: (_) => setLocal(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'Service Name',
                                            hintText: 'e.g., Engine Repair',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: costCtrl,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          onChanged: (_) => setLocal(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'Cost',
                                            hintText: '0.00',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      if (serviceNameControllers.length >
                                          1) ...[
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Color(0xFFEF4444),
                                            size: 20,
                                          ),
                                          tooltip: 'Remove Service',
                                          onPressed: () {
                                            setLocal(() {
                                              serviceNameControllers.removeAt(
                                                i,
                                              );
                                              serviceCostControllers.removeAt(
                                                i,
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (catalogServices.isNotEmpty)
                                    PopupMenuButton<_ServiceJobItem>(
                                      tooltip: 'Select from catalog',
                                      onSelected: (srv) {
                                        setLocal(() {
                                          serviceNameControllers.add(
                                            TextEditingController(
                                              text: srv.title,
                                            ),
                                          );
                                          serviceCostControllers.add(
                                            TextEditingController(
                                              text: srv.defaultPrice > 0
                                                  ? (srv.defaultPrice % 1 == 0
                                                        ? srv.defaultPrice
                                                              .toInt()
                                                              .toString()
                                                        : srv.defaultPrice
                                                              .toStringAsFixed(
                                                                2,
                                                              ))
                                                  : '',
                                            ),
                                          );
                                        });
                                      },
                                      itemBuilder: (ctx) => catalogServices
                                          .map(
                                            (
                                              srv,
                                            ) => PopupMenuItem<_ServiceJobItem>(
                                              value: srv,
                                              child: Text(
                                                '${srv.title} (${self._money(srv.defaultPrice)})',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      child: OutlinedButton.icon(
                                        onPressed: null,
                                        style: OutlinedButton.styleFrom(
                                          disabledForegroundColor:
                                              AppTheme.brandIndigo,
                                        ),
                                        icon: const Icon(
                                          Icons.list_alt,
                                          size: 16,
                                        ),
                                        label: const Text('From Catalog'),
                                      ),
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setLocal(() {
                                        serviceNameControllers.add(
                                          TextEditingController(),
                                        );
                                        serviceCostControllers.add(
                                          TextEditingController(),
                                        );
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.brandIndigo,
                                      side: const BorderSide(
                                        color: AppTheme.brandIndigo,
                                      ),
                                    ),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Service'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Materials (Optional)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(materialNameControllers.length, (
                                i,
                              ) {
                                final nameCtrl = materialNameControllers[i];
                                final costCtrl = materialCostControllers[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: nameCtrl,
                                          onChanged: (_) => setLocal(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'Material Name',
                                            hintText: 'e.g., Oil Filter',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: costCtrl,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          onChanged: (_) => setLocal(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'Cost',
                                            hintText: '0.00',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      if (materialNameControllers.length >
                                          1) ...[
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Color(0xFFEF4444),
                                            size: 20,
                                          ),
                                          tooltip: 'Remove Material',
                                          onPressed: () {
                                            setLocal(() {
                                              materialNameControllers.removeAt(
                                                i,
                                              );
                                              materialCostControllers.removeAt(
                                                i,
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setLocal(() {
                                      materialNameControllers.add(
                                        TextEditingController(),
                                      );
                                      materialCostControllers.add(
                                        TextEditingController(),
                                      );
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.brandIndigo,
                                    side: const BorderSide(
                                      color: AppTheme.brandIndigo,
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Material'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Status & Scheduling',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'OPEN',
                                    child: Text('Open'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'IN_PROGRESS',
                                    child: Text('In Progress'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'COMPLETED',
                                    child: Text('Completed'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CANCELLED',
                                    child: Text('Cancelled'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setLocal(() {
                                    selectedStatus = value ?? 'OPEN';
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedPriority,
                                      decoration: const InputDecoration(
                                        labelText: 'Priority',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'NORMAL',
                                          child: Text('Normal'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'LOW',
                                          child: Text('Low'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'MEDIUM',
                                          child: Text('Medium'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'HIGH',
                                          child: Text('High'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setLocal(() {
                                          selectedPriority = value ?? 'NORMAL';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: scheduledDateController,
                                      decoration: const InputDecoration(
                                        labelText: 'Scheduled Date',
                                        hintText: 'mm/dd/yyyy',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: scheduledTimeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Scheduled Time',
                                        hintText: '--:--',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: durationController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Estimated Duration (minutes)',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: locationController,
                                      decoration: const InputDecoration(
                                        labelText: 'Location',
                                        hintText: 'e.g., Workshop, On-site',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: deviceInfoController,
                                      decoration: const InputDecoration(
                                        labelText: 'Device/Asset Info',
                                        hintText: 'model, serial number, etc.',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Cost Adjustments',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: discountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      onChanged: (_) => setLocal(() {}),
                                      decoration: const InputDecoration(
                                        labelText: 'Discount',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: taxController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      onChanged: (_) => setLocal(() {}),
                                      decoration: const InputDecoration(
                                        labelText: 'Tax',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest
                                      : const Color(0xFFF7F3FB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _summaryLine('Services', servicesSubtotal),
                                    _summaryLine(
                                      'Materials',
                                      materialsSubtotal,
                                    ),
                                    _summaryLine('Discount', -discountVal),
                                    _summaryLine('Tax', taxVal),
                                    const Divider(),
                                    Row(
                                      children: [
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          self._money(grandTotal),
                                          style: const TextStyle(
                                            color: AppTheme.brandIndigo,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Notes',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: internalNotesController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Internal Notes',
                                  hintText: 'Notes for internal use only',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: customerNotesController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Customer Notes',
                                  hintText: 'Notes visible to customer',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: tagsController,
                                      decoration: const InputDecoration(
                                        labelText: 'Tags',
                                        hintText: 'Add a tag',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () {},
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                final selectedCustomer = self._customers
                                    .firstWhere(
                                      (c) => c.id == selectedCustomerId,
                                      orElse: () => _CustomerItem(
                                        id: 'WALKIN',
                                        name: 'Walk-in Customer',
                                        phone: phoneController.text.trim(),
                                        email: emailController.text.trim(),
                                      ),
                                    );

                                final servicesList = <String>[];
                                for (
                                  int i = 0;
                                  i < serviceNameControllers.length;
                                  i++
                                ) {
                                  final name = serviceNameControllers[i].text
                                      .trim();
                                  final costStr = serviceCostControllers[i].text
                                      .trim();
                                  final cost = double.tryParse(costStr) ?? 0;
                                  if (name.isNotEmpty) {
                                    servicesList.add(
                                      cost > 0 ? '$name | $cost' : name,
                                    );
                                  }
                                }

                                final materialsList = <String>[];
                                for (
                                  int i = 0;
                                  i < materialNameControllers.length;
                                  i++
                                ) {
                                  final name = materialNameControllers[i].text
                                      .trim();
                                  final costStr = materialCostControllers[i]
                                      .text
                                      .trim();
                                  final cost = double.tryParse(costStr) ?? 0;
                                  if (name.isNotEmpty) {
                                    materialsList.add(
                                      cost > 0 ? '$name | $cost' : name,
                                    );
                                  }
                                }

                                final servicesTotal = calcServicesCost();
                                final materialsTotal = calcMaterialsCost();
                                final discount =
                                    double.tryParse(
                                      discountController.text.trim(),
                                    ) ??
                                    0;
                                final tax =
                                    double.tryParse(
                                      taxController.text.trim(),
                                    ) ??
                                    0;
                                final total =
                                    servicesTotal +
                                    materialsTotal -
                                    discount +
                                    tax;

                                Navigator.pop(
                                  context,
                                  _ServiceJobItem(
                                    id:
                                        existing?.id ??
                                        'JOB${DateTime.now().millisecondsSinceEpoch}',
                                    title: titleController.text.trim().isEmpty
                                        ? 'Service Job'
                                        : titleController.text.trim(),
                                    sku:
                                        existing?.sku ??
                                        'JC-${DateTime.now().millisecondsSinceEpoch % 100000}',
                                    description: descriptionController.text
                                        .trim(),
                                    defaultPrice: total,
                                    active: true,
                                    technician: existing?.technician ?? '',
                                    warranty: existing?.warranty ?? false,
                                    status: selectedStatus,
                                    priority: selectedPriority,
                                    customerName: selectedCustomer.name,
                                    customerPhone: phoneController.text.trim(),
                                    customerEmail: emailController.text.trim(),
                                    scheduledDate: scheduledDateController.text
                                        .trim(),
                                    scheduledTime: scheduledTimeController.text
                                        .trim(),
                                    estimatedDurationMinutes: durationController
                                        .text
                                        .trim(),
                                    location: locationController.text.trim(),
                                    deviceInfo: deviceInfoController.text
                                        .trim(),
                                    discount: discount,
                                    taxAmount: tax,
                                    internalNotes: internalNotesController.text
                                        .trim(),
                                    customerNotes: customerNotesController.text
                                        .trim(),
                                    services: servicesList,
                                    materials: materialsList,
                                    tags: tagsController.text.trim(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandIndigo,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(isEdit ? 'Update' : 'Create'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      titleController.dispose();
      descriptionController.dispose();
      phoneController.dispose();
      emailController.dispose();
      scheduledDateController.dispose();
      scheduledTimeController.dispose();
      durationController.dispose();
      locationController.dispose();
      deviceInfoController.dispose();
      discountController.dispose();
      taxController.dispose();
      internalNotesController.dispose();
      customerNotesController.dispose();
      tagsController.dispose();
      for (final controller in serviceNameControllers) {
        controller.dispose();
      }
      for (final controller in serviceCostControllers) {
        controller.dispose();
      }
      for (final controller in materialNameControllers) {
        controller.dispose();
      }
      for (final controller in materialCostControllers) {
        controller.dispose();
      }
    });

    return created;
  }

  // ---------------------------------------------------------------------------
  // SECTION: Summary Line Helper Widget
  // WHAT  : Renders a single row with a label on the left and a formatted
  //         currency amount (_money helper) on the right.  Used in receipt
  //         and summary sections.
  // WHERE : Used in the Job Card dialog cost breakdown and POS receipt summary.
  // TODO  : Support multi-currency display using the store's configured
  //         currency symbol instead of the hard-coded default.
  // ---------------------------------------------------------------------------
  Widget _summaryLine(String label, double value) {
    final self = this;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF666F87))),
          const Spacer(),
          Text(
            self._money(value),
            style: const TextStyle(color: Color(0xFF5A6480)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Image Path Picker
  // WHAT  : Opens the platform file picker filtered to common image formats
  //         (jpg, jpeg, png, gif, webp) and returns the selected file path,
  //         or null if the user cancels.
  // WHERE : Used in _showProductDialog and _showEmployeeDialog for photo
  //         upload fields.
  // TODO  : Add image resizing / compression before saving to local DB;
  //         support camera capture on mobile/tablet form factors.
  // ---------------------------------------------------------------------------
  Future<String?> _pickImagePath() async {
    final self = this;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single.path;
  }

  // ---------------------------------------------------------------------------
  // SECTION: Add / Edit Supplier Dialog
  // WHAT  : Right-drawer slide-in dialog for creating or editing a supplier
  //         record.  Fields:
  //           Ã¢â‚¬Â¢ Name *, Phone *, Email
  //           Ã¢â‚¬Â¢ Address, Contact person, Notes
  //         Validation: name + phone required.
  //         Returns _SupplierItem? (null = cancelled).
  // WHERE : Called from the Purchase Orders / Suppliers tab Add / Edit actions.
  // TODO  : Add bank account / payment details field for payment tracking;
  //         add a 'Lead time (days)' field for procurement planning.
  // ---------------------------------------------------------------------------
  Future<_SupplierItem?> _showSupplierDialog({_SupplierItem? existing}) async {
    final self = this;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final companyNameController = TextEditingController(
      text: existing?.companyName ?? '',
    );
    final contactController = TextEditingController(
      text: existing?.contact ?? '',
    );
    final emailController = TextEditingController(text: existing?.email ?? '');
    final addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    final taxIdController = TextEditingController(text: existing?.taxId ?? '');
    final websiteController = TextEditingController(
      text: existing?.website ?? '',
    );
    final imageController = TextEditingController(
      text: existing?.imagePath ?? '',
    );
    final idCard1Controller = TextEditingController(
      text: existing?.idCardImage1 ?? '',
    );
    final idCard2Controller = TextEditingController(
      text: existing?.idCardImage2 ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String validationMessage = '';

    Widget fieldLabel(String label) => Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    );

    Widget browseRow({
      required TextEditingController controller,
      required String hint,
      required void Function(void Function()) setLocal,
      required String previewPath,
    }) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: self._supplierImagePreview(previewPath),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  onChanged: (_) => setLocal(() {}),
                  decoration: InputDecoration(hintText: hint),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final path = await self._pickImagePath();
                      if (path == null) return;
                      setLocal(() => controller.text = path);
                    },
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Browse'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return showGeneralDialog<_SupplierItem>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: 'AddSupplier',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SizedBox(
                  width: ResponsiveLayout.adaptiveDialogWidth(context, 460),
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).viewInsets.bottom,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.brandIndigo.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(
                                Icons.local_shipping_outlined,
                                color: AppTheme.brandIndigo,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                existing == null
                                    ? 'Add New Supplier'
                                    : 'Edit Supplier',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            20 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              fieldLabel('Company Name'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: companyNameController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g., Acme Distributors',
                                ),
                              ),
                              const SizedBox(height: 14),
                              fieldLabel('Supplier Contact Name *'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter contact person name',
                                ),
                              ),
                              const SizedBox(height: 14),
                              fieldLabel('Phone / Contact *'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: contactController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Enter phone number',
                                ),
                              ),
                              const SizedBox(height: 14),
                              fieldLabel('Email Address'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'Enter email address',
                                ),
                              ),
                              const SizedBox(height: 14),
                              fieldLabel('Physical Address'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: addressController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Enter physical address',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        fieldLabel('Tax ID / VAT'),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: taxIdController,
                                          decoration: const InputDecoration(
                                            hintText: 'Optional',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        fieldLabel('Website URL'),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: websiteController,
                                          decoration: const InputDecoration(
                                            hintText: 'Optional',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Divider(),
                              const SizedBox(height: 10),
                              fieldLabel('Supplier Image'),
                              const SizedBox(height: 6),
                              browseRow(
                                controller: imageController,
                                hint: 'Image path or URL',
                                setLocal: setLocal,
                                previewPath: imageController.text,
                              ),
                              const SizedBox(height: 16),
                              fieldLabel('ID Document 1'),
                              const SizedBox(height: 6),
                              browseRow(
                                controller: idCard1Controller,
                                hint: 'Document path or URL',
                                setLocal: setLocal,
                                previewPath: idCard1Controller.text,
                              ),
                              const SizedBox(height: 16),
                              fieldLabel('ID Document 2'),
                              const SizedBox(height: 6),
                              browseRow(
                                controller: idCard2Controller,
                                hint: 'Document path or URL',
                                setLocal: setLocal,
                                previewPath: idCard2Controller.text,
                              ),
                              const SizedBox(height: 18),
                              const Divider(),
                              const SizedBox(height: 10),
                              fieldLabel('Notes'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: notesController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Optional internal notes',
                                ),
                              ),
                              if (validationMessage.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDECEC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFF5C2C2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Color(0xFFD32F2F),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          validationMessage,
                                          style: const TextStyle(
                                            color: Color(0xFFD32F2F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final company = companyNameController.text
                                      .trim();
                                  final name = nameController.text.trim();
                                  final contact = contactController.text.trim();
                                  if (company.isEmpty && name.isEmpty) {
                                    setLocal(
                                      () => validationMessage =
                                          'Add a company name or contact name.',
                                    );
                                    return;
                                  }
                                  if (contact.isEmpty) {
                                    setLocal(
                                      () => validationMessage =
                                          'Contact phone is required.',
                                    );
                                    return;
                                  }

                                  Navigator.pop(
                                    context,
                                    _SupplierItem(
                                      id:
                                          existing?.id ??
                                          'SUP${DateTime.now().millisecondsSinceEpoch}',
                                      name: name.isEmpty ? company : name,
                                      contact: contact,
                                      email: emailController.text.trim(),
                                      companyName: company,
                                      address: addressController.text.trim(),
                                      taxId: taxIdController.text.trim(),
                                      website: websiteController.text.trim(),
                                      imagePath: imageController.text.trim(),
                                      idCardImage1: idCard1Controller.text
                                          .trim(),
                                      idCardImage2: idCard2Controller.text
                                          .trim(),
                                      notes: notesController.text.trim(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brandIndigo,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  existing == null
                                      ? 'Create Supplier'
                                      : 'Update',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Create Purchase Order Dialog
  // WHAT  : Right-drawer slide-in dialog (700 px wide) for creating a new
  //         Purchase Order.  Fields:
  //           Ã¢â‚¬Â¢ Supplier selector (required)
  //           Ã¢â‚¬Â¢ Expected delivery date
  //           Ã¢â‚¬Â¢ Line items Ã¢â‚¬â€œ dynamic list of (product, qty, unit price)
  //             with Add / Remove row controls
  //           Ã¢â‚¬Â¢ Subtotal, Tax %, Discount amount, Total (auto-computed)
  //           Ã¢â‚¬Â¢ Notes
  //         Validation: supplier selected; Ã¢â€°Â¥1 line item; all quantities > 0.
  //         Returns _PurchaseOrderItem? (null = cancelled).
  // WHERE : Called from the Purchase Orders tab 'New Order' button.
  // TODO  : Add draft-save support (save without submitting);
  //         auto-populate unit price from last purchase price per supplier;
  //         support multi-currency PO amounts.
  // ---------------------------------------------------------------------------
  Future<_PurchaseOrderItem?> _showPurchaseOrderDialog() async {
    final self = this;
    final notesController = TextEditingController();
    final expectedDateController = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .split('T')
          .first,
    );
    final suppliers = self._suppliers.isEmpty
        ? [
            _SupplierItem(
              id: 'SUP-FALLBACK',
              name: 'Astronauts',
              contact: '',
              email: '',
            ),
          ]
        : self._suppliers;

    return showGeneralDialog<_PurchaseOrderItem>(
      context: self.context,
      barrierDismissible: true,
      barrierLabel: 'CreateOrder',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        String selectedSupplierId = suppliers.first.id;
        String selectedSupplierName = suppliers.first.name;
        final locationNames = self._locations
            .map((loc) => loc.name.trim())
            .where((name) => name.isNotEmpty)
            .toList();
        String selectedLocationName = self._activeLocationForWrites;
        if (selectedLocationName.isEmpty ||
            !locationNames.contains(selectedLocationName)) {
          selectedLocationName = locationNames.isNotEmpty
              ? locationNames.first
              : '';
        }
        bool matchesLocation(_ProductItem product) {
          final location = product.locationId.trim();
          return location.isEmpty || location == selectedLocationName;
        }

        List<_ProductItem> eligibleProducts() {
          return self._products
              .where(
                (p) => p.supplierId == selectedSupplierId && matchesLocation(p),
              )
              .toList();
        }

        final initialEligible = eligibleProducts();
        final initialProductId = initialEligible.isNotEmpty
            ? initialEligible.first.id
            : '';
        final initialPrice = initialEligible.isNotEmpty
            ? initialEligible.first.price.toStringAsFixed(2)
            : '0';
        final initialQty = initialEligible.isNotEmpty ? '1' : '0';
        final items = <Map<String, dynamic>>[
          {
            'productId': initialProductId,
            'qtyController': TextEditingController(text: initialQty),
            'priceController': TextEditingController(text: initialPrice),
          },
        ];

        return StatefulBuilder(
          builder: (context, setLocal) {
            double rowTotal(Map<String, dynamic> row) {
              final qty =
                  int.tryParse(
                    (row['qtyController'] as TextEditingController).text.trim(),
                  ) ??
                  0;
              final unitPrice =
                  double.tryParse(
                    (row['priceController'] as TextEditingController).text
                        .trim(),
                  ) ??
                  0;
              return qty * unitPrice;
            }

            double grandTotal() {
              return items.fold<double>(0, (sum, row) => sum + rowTotal(row));
            }

            final supplierProducts = eligibleProducts();
            final hasSupplierProducts = supplierProducts.isNotEmpty;
            final dialogCompact =
                MediaQuery.of(context).size.width < UiBreakpoints.tablet;
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: dialogCompact ? 10 : 120,
                vertical: dialogCompact ? 16 : 40,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: dialogCompact ? double.infinity : 860,
                height: dialogCompact ? null : 700,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: dialogCompact
                        ? MainAxisSize.min
                        : MainAxisSize.max,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Create Order',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: dialogCompact ? 28 : 40,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            20 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location *'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedLocationName.isEmpty
                                    ? null
                                    : selectedLocationName,
                                isExpanded: true,
                                items: locationNames
                                    .map(
                                      (name) => DropdownMenuItem(
                                        value: name,
                                        child: Text(name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setLocal(() {
                                    selectedLocationName = v;
                                    final linkedProducts = eligibleProducts();
                                    for (final row in items) {
                                      final qtyController =
                                          row['qtyController']
                                              as TextEditingController;
                                      final priceController =
                                          row['priceController']
                                              as TextEditingController;
                                      if (linkedProducts.isEmpty) {
                                        row['productId'] = '';
                                        qtyController.text = '0';
                                        priceController.text = '0';
                                      } else {
                                        final currentId =
                                            row['productId'] as String;
                                        if (!linkedProducts.any(
                                          (p) => p.id == currentId,
                                        )) {
                                          final first = linkedProducts.first;
                                          row['productId'] = first.id;
                                          priceController.text = first.price
                                              .toStringAsFixed(2);
                                          if (qtyController.text
                                                  .trim()
                                                  .isEmpty ||
                                              qtyController.text.trim() ==
                                                  '0') {
                                            qtyController.text = '1';
                                          }
                                        }
                                      }
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              const Text('Supplier *'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedSupplierId,
                                isExpanded: true,
                                items: suppliers
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final selected = suppliers.firstWhere(
                                    (s) => s.id == v,
                                    orElse: () => suppliers.first,
                                  );
                                  setLocal(() {
                                    selectedSupplierId = v;
                                    selectedSupplierName = selected.name;
                                    final linkedProducts = eligibleProducts();
                                    for (final row in items) {
                                      final qtyController =
                                          row['qtyController']
                                              as TextEditingController;
                                      final priceController =
                                          row['priceController']
                                              as TextEditingController;
                                      if (linkedProducts.isEmpty) {
                                        row['productId'] = '';
                                        qtyController.text = '0';
                                        priceController.text = '0';
                                      } else {
                                        final currentId =
                                            row['productId'] as String;
                                        if (!linkedProducts.any(
                                          (p) => p.id == currentId,
                                        )) {
                                          final first = linkedProducts.first;
                                          row['productId'] = first.id;
                                          priceController.text = first.price
                                              .toStringAsFixed(2);
                                          if (qtyController.text
                                                  .trim()
                                                  .isEmpty ||
                                              qtyController.text.trim() ==
                                                  '0') {
                                            qtyController.text = '1';
                                          }
                                        }
                                      }
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('Items *'),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      if (!hasSupplierProducts) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No linked products for this supplier.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      final first = supplierProducts.first;
                                      setLocal(() {
                                        items.add({
                                          'productId': first.id,
                                          'qtyController':
                                              TextEditingController(text: '1'),
                                          'priceController':
                                              TextEditingController(
                                                text: first.price
                                                    .toStringAsFixed(2),
                                              ),
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Item'),
                                  ),
                                ],
                              ),
                              if (!hasSupplierProducts)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'No linked products for this supplier.',
                                    style: TextStyle(color: Color(0xFFD32F2F)),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    if (!dialogCompact) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                          left: 4,
                                          right: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Text(
                                                'PRODUCT',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.4,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: 100,
                                              child: Text(
                                                'QTY',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.4,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: 120,
                                              child: Text(
                                                'UNIT PRICE',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.4,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: 120,
                                              child: Text(
                                                'TOTAL',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.4,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 44),
                                          ],
                                        ),
                                      ),
                                      Divider(
                                        height: 1,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    ...items.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final row = entry.value;
                                      final qtyController =
                                          row['qtyController']
                                              as TextEditingController;
                                      final priceController =
                                          row['priceController']
                                              as TextEditingController;
                                      final productId =
                                          row['productId'] as String;
                                      final selectedProduct = supplierProducts
                                          .firstWhere(
                                            (p) => p.id == productId,
                                            orElse: () => self._products.isEmpty
                                                ? _ProductItem(
                                                    id: '',
                                                    name: 'No Product',
                                                    category: '',
                                                    price: 0,
                                                    stock: 0,
                                                    minStock: 0,
                                                  )
                                                : self._products.first,
                                          );
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: dialogCompact
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    initialValue:
                                                        hasSupplierProducts
                                                        ? selectedProduct.id
                                                        : null,
                                                    isExpanded: true,
                                                    items: hasSupplierProducts
                                                        ? supplierProducts
                                                              .map(
                                                                (
                                                                  p,
                                                                ) => DropdownMenuItem(
                                                                  value: p.id,
                                                                  child: Text(
                                                                    '${p.name} (${p.id})',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              )
                                                              .toList()
                                                        : const [
                                                            DropdownMenuItem(
                                                              value: '',
                                                              child: Text(
                                                                'No linked products',
                                                              ),
                                                            ),
                                                          ],
                                                    onChanged: (v) {
                                                      if (!hasSupplierProducts) {
                                                        return;
                                                      }
                                                      if (v == null) return;
                                                      final product =
                                                          supplierProducts
                                                              .firstWhere(
                                                                (p) =>
                                                                    p.id == v,
                                                              );
                                                      setLocal(() {
                                                        row['productId'] = v;
                                                        priceController
                                                            .text = product
                                                            .price
                                                            .toStringAsFixed(2);
                                                      });
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Product',
                                                        ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextField(
                                                          controller:
                                                              qtyController,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    'Quantity',
                                                              ),
                                                          onChanged: (_) =>
                                                              setLocal(() {}),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: TextField(
                                                          controller:
                                                              priceController,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    'Unit Price',
                                                              ),
                                                          onChanged: (_) =>
                                                              setLocal(() {}),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: InputDecorator(
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    'Total',
                                                              ),
                                                          child: Text(
                                                            rowTotal(
                                                              row,
                                                            ).toStringAsFixed(
                                                              2,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      IconButton(
                                                        onPressed:
                                                            items.length <= 1
                                                            ? null
                                                            : () => setLocal(
                                                                () => items
                                                                    .removeAt(
                                                                      index,
                                                                    ),
                                                              ),
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Color(
                                                            0xFFE35D5D,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                children: [
                                                  Expanded(
                                                    flex: 4,
                                                    child: DropdownButtonFormField<String>(
                                                      initialValue:
                                                          hasSupplierProducts
                                                          ? selectedProduct.id
                                                          : null,
                                                      isExpanded: true,
                                                      items: hasSupplierProducts
                                                          ? supplierProducts
                                                                .map(
                                                                  (
                                                                    p,
                                                                  ) => DropdownMenuItem(
                                                                    value: p.id,
                                                                    child: Text(
                                                                      '${p.name} (${p.id})',
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList()
                                                          : const [
                                                              DropdownMenuItem(
                                                                value: '',
                                                                child: Text(
                                                                  'No linked products',
                                                                ),
                                                              ),
                                                            ],
                                                      onChanged: (v) {
                                                        if (!hasSupplierProducts) {
                                                          return;
                                                        }
                                                        if (v == null) return;
                                                        final product =
                                                            supplierProducts
                                                                .firstWhere(
                                                                  (p) =>
                                                                      p.id == v,
                                                                );
                                                        setLocal(() {
                                                          row['productId'] = v;
                                                          priceController
                                                              .text = product
                                                              .price
                                                              .toStringAsFixed(
                                                                2,
                                                              );
                                                        });
                                                      },
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Product',
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  SizedBox(
                                                    width: 100,
                                                    child: TextField(
                                                      controller: qtyController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Quantity',
                                                          ),
                                                      onChanged: (_) =>
                                                          setLocal(() {}),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  SizedBox(
                                                    width: 120,
                                                    child: TextField(
                                                      controller:
                                                          priceController,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Unit Price',
                                                          ),
                                                      onChanged: (_) =>
                                                          setLocal(() {}),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  SizedBox(
                                                    width: 120,
                                                    child: InputDecorator(
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText: 'Total',
                                                          ),
                                                      child: Text(
                                                        rowTotal(
                                                          row,
                                                        ).toStringAsFixed(2),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    onPressed: items.length <= 1
                                                        ? null
                                                        : () => setLocal(
                                                            () =>
                                                                items.removeAt(
                                                                  index,
                                                                ),
                                                          ),
                                                    icon: const Icon(
                                                      Icons.close,
                                                      color: Color(0xFFE35D5D),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Order Total ${self._money(grandTotal())}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Expected Delivery Date'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: expectedDateController,
                                decoration: const InputDecoration(
                                  hintText: 'YYYY-MM-DD',
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text('Notes'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: notesController,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final lines = items
                                    .map((row) {
                                      final productId =
                                          (row['productId'] as String?) ?? '';
                                      final product = self._products.firstWhere(
                                        (p) => p.id == productId,
                                        orElse: () => _ProductItem(
                                          id: productId,
                                          name: 'Unknown Product',
                                          category: '',
                                          price: 0,
                                          stock: 0,
                                          minStock: 0,
                                        ),
                                      );
                                      final qty =
                                          double.tryParse(
                                            (row['qtyController']
                                                    as TextEditingController)
                                                .text
                                                .trim(),
                                          ) ??
                                          0;
                                      final unitPrice =
                                          double.tryParse(
                                            (row['priceController']
                                                    as TextEditingController)
                                                .text
                                                .trim(),
                                          ) ??
                                          0;
                                      return _PurchaseOrderLine(
                                        productId: productId,
                                        productName: product.name,
                                        qty: qty,
                                        costPrice: unitPrice,
                                        sellingPrice: product.price,
                                      );
                                    })
                                    .where((line) => line.qty > 0)
                                    .toList();

                                final count = lines.fold<double>(
                                  0,
                                  (sum, line) => sum + line.qty,
                                );
                                final total = lines.fold<double>(
                                  0,
                                  (sum, line) =>
                                      sum +
                                      (line.qty * line.costPrice).toDouble(),
                                );
                                Navigator.pop(
                                  context,
                                  _PurchaseOrderItem(
                                    id: 'PO${DateTime.now().millisecondsSinceEpoch}',
                                    supplier: selectedSupplierName,
                                    supplierId: selectedSupplierId,
                                    locationId: selectedLocationName,
                                    status: 'PENDING',
                                    expectedDate: expectedDateController.text
                                        .trim(),
                                    notes: notesController.text.trim(),
                                    items: lines,
                                    updatedAt: DateTime.now()
                                        .toUtc()
                                        .toIso8601String(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandIndigo,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Create Order'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Purchase Order Status Updater
  // WHAT  : Async method that writes a status transition
  //         (PENDING Ã¢â€ â€™ APPROVED Ã¢â€ â€™ RECEIVED, or CANCELLED) to the local DB
  //         and enqueues a sync operation.
  //         Special behaviour on RECEIVED:
  //           Ã¢â‚¬Â¢ Iterates each line item and increments inventory stock
  //             for the receiving location.
  //         Triggers a setState after completion to refresh the PO list.
  // WHERE : Called by Approve / Receive Stock / Cancel Order buttons inside
  //         _showPurchaseOrderDetails, and by the inline status dropdown.
  // TODO  : Add partial-receipt support (receive fewer units than ordered);
  //         record a receiving log entry per line item;
  //         notify the supplier via email on approval.
  // ---------------------------------------------------------------------------
  Future<void> _updatePurchaseOrderStatus(
    _PurchaseOrderItem order,
    String nextStatus,
  ) async {
    final self = this;
    if ((order.status == 'RECEIVED' || order.status == 'CANCELLED') &&
        order.status != nextStatus) {
      return;
    }
    if (order.status == nextStatus) return;
    final previousStatus = order.status;

    final liveIdx = self._purchaseOrders.indexWhere((p) => p.id == order.id);
    if (liveIdx >= 0) {
      final livePo = self._purchaseOrders[liveIdx];
      self.setState(() {
        livePo.status = nextStatus;
        livePo.updatedAt = DateTime.now().toUtc().toIso8601String();
      });
      order.status = livePo.status;
      order.updatedAt = livePo.updatedAt;
    } else {
      self.setState(() {
        order.status = nextStatus;
        order.updatedAt = DateTime.now().toUtc().toIso8601String();
      });
    }

    final shouldApplyStock =
        nextStatus == 'RECEIVED' && previousStatus != 'RECEIVED';
    if (shouldApplyStock) {
      final targetLocation = order.locationId.trim().isEmpty
          ? self._activeLocationForWrites
          : order.locationId.trim();
      for (final line in order.items) {
        _ProductItem? baseProduct;
        if (line.productId.isNotEmpty) {
          final idx = self._products.indexWhere((p) => p.id == line.productId);
          if (idx >= 0) {
            baseProduct = self._products[idx];
          }
        }

        if (baseProduct == null) {
          // Fallback to match by SKU/barcode or product name in global catalogue
          final idx = self._products.indexWhere(
            (p) =>
                (p.barcode.isNotEmpty &&
                    p.barcode.trim().toLowerCase() ==
                        line.productId.trim().toLowerCase()) ||
                p.name.trim().toLowerCase() ==
                    line.productName.trim().toLowerCase(),
          );
          if (idx >= 0) {
            baseProduct = self._products[idx];
          }
        }

        if (baseProduct == null) {
          // Create a new product entirely at targetLocation if it doesn't exist anywhere
          final newProdId = line.productId.isNotEmpty
              ? line.productId
              : 'PROD-PO-${DateTime.now().millisecondsSinceEpoch}-${order.items.indexOf(line)}';
          final newProduct = _ProductItem(
            id: newProdId,
            name: line.productName.trim().isNotEmpty
                ? line.productName.trim()
                : 'PO Product',
            barcode:
                'SKU-${DateTime.now().millisecondsSinceEpoch}-${order.items.indexOf(line)}',
            category: self._productCategories.isNotEmpty
                ? self._productCategories.first
                : 'General',
            price: line.sellingPrice > 0
                ? line.sellingPrice
                : line.costPrice * 1.5,
            costPrice: line.costPrice,
            stock: line.quantity,
            minStock: 0.0,
            locationId: targetLocation,
            supplierId: order.supplierId,
          );

          self.setState(() {
            self._products.add(newProduct);
            line.productId = newProdId;
          });

          if (self._productRepository != null) {
            await self._productRepository!.insertProduct(
              self._toDomainProduct(newProduct),
            );
            await self._refreshPendingSyncQueue();
            await self._triggerImmediateSync(
              action: 'INSERT',
              module: 'products',
              reference: newProdId,
            );
          } else {
            await self._enqueueSync('INSERT', 'products', newProdId);
          }
          continue;
        }

        // We have a baseProduct, check if we need to clone it or update it at targetLocation
        final base = baseProduct;
        final targetIndex = self._products.indexWhere(
          (p) =>
              p.locationId == targetLocation &&
              ((p.barcode.isNotEmpty &&
                      base.barcode.isNotEmpty &&
                      p.barcode.trim().toLowerCase() ==
                          base.barcode.trim().toLowerCase()) ||
                  (p.name.trim().toLowerCase() ==
                      base.name.trim().toLowerCase())),
        );

        if (targetIndex >= 0) {
          final product = self._products[targetIndex];
          product.stock += line.quantity;
          if (line.unitPrice > 0) {
            product.costPrice = line.unitPrice;
          }
          if (line.sellingPrice > 0) {
            product.price = line.sellingPrice;
          }

          if (self._productRepository != null) {
            await self._productRepository!.updateProduct(
              self._toDomainProduct(product),
            );
            await self._refreshPendingSyncQueue();
            await self._triggerImmediateSync(
              action: 'UPDATE',
              module: 'products',
              reference: product.id,
            );
          } else {
            await self._enqueueSync('UPDATE', 'products', product.id);
          }
        } else {
          // Clone base to targetLocation
          final newProdId =
              'PROD-CLONE-${DateTime.now().millisecondsSinceEpoch}-${self._products.length}-${order.items.indexOf(line)}';
          final newProduct = _ProductItem(
            id: newProdId,
            name: base.name,
            barcode: base.barcode,
            category: base.category,
            price: line.sellingPrice > 0 ? line.sellingPrice : base.price,
            costPrice: line.unitPrice > 0 ? line.unitPrice : base.costPrice,
            stock: line.quantity,
            minStock: base.minStock,
            locationId: targetLocation,
            supplierId: order.supplierId.isNotEmpty
                ? order.supplierId
                : base.supplierId,
            measureUnit: base.measureUnit,
            productType: base.productType,
            description: base.description,
            warrantyMonths: base.warrantyMonths,
            expiryDate: base.expiryDate,
            expiryReminderMode: base.expiryReminderMode,
            expiryReminderDays: base.expiryReminderDays,
            attributeValues: Map.from(base.attributeValues),
          );

          self.setState(() {
            self._products.add(newProduct);
            line.productId = newProdId;
          });

          if (self._productRepository != null) {
            await self._productRepository!.insertProduct(
              self._toDomainProduct(newProduct),
            );
            await self._refreshPendingSyncQueue();
            await self._triggerImmediateSync(
              action: 'INSERT',
              module: 'products',
              reference: newProdId,
            );
          } else {
            await self._enqueueSync('INSERT', 'products', newProdId);
          }
        }
      }
    }

    await self._persistWorkspaceData();
    await self._enqueueSync('UPDATE', 'purchase_orders', order.id);
  }

  // ---------------------------------------------------------------------------
  // SECTION: Purchase Order Details Panel
  // WHAT  : Full-width side panel (via showGeneralDialog) that renders a
  //         read-only Purchase Order detail view:
  //           Ã¢â‚¬Â¢ Supplier name, status badge, created/expected dates
  //           Ã¢â‚¬Â¢ Line-item DataTable (product, qty, unit price, total)
  //           Ã¢â‚¬Â¢ Order total (right-aligned)
  //           Ã¢â‚¬Â¢ Notes section
  //           Ã¢â‚¬Â¢ Inline status-change dropdown
  //           Ã¢â‚¬Â¢ Action buttons: Approve, Receive Stock, Cancel Order, Close
  //         Actions are disabled when status is RECEIVED or CANCELLED.
  // WHERE : Called when a purchase order row is tapped in the PO list.
  // TODO  : Add print / export to PDF; show receiving history log per order;
  //         display a diff of ordered vs. actually received quantities.
  // ---------------------------------------------------------------------------
  Future<void> _showPurchaseOrderDetails(_PurchaseOrderItem order) async {
    final self = this;
    final supplier = order.supplierId.isNotEmpty
        ? self._suppliers.firstWhere(
            (s) => s.id == order.supplierId,
            orElse: () => _SupplierItem(
              id: order.supplierId,
              name: order.supplier,
              contact: '',
              email: '',
            ),
          )
        : self._suppliers.firstWhere(
            (s) => s.name == order.supplier,
            orElse: () => _SupplierItem(
              id: '',
              name: order.supplier,
              contact: '',
              email: '',
            ),
          );

    bool isProcessing = false;

    await showDialog<void>(
      context: self.context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          final isLocked =
              order.status == 'RECEIVED' || order.status == 'CANCELLED';
          final disableActions = isLocked || isProcessing;
          final locationName = order.locationId.trim().isNotEmpty
              ? order.locationId
              : self._storeLocation;
          final statusOptions = [
            'DRAFT',
            'PENDING',
            'APPROVED',
            'RECEIVED',
            'CANCELLED',
          ];
          final statusValue = statusOptions.contains(order.status)
              ? order.status
              : 'PENDING';

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 30),
            child: SizedBox(
              width: ResponsiveLayout.adaptiveDialogWidth(context, 760),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Purchase Order ${order.id}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        20 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (supplier.companyName.isNotEmpty)
                            Text(supplier.companyName),
                          if (supplier.contact.isNotEmpty ||
                              supplier.email.isNotEmpty)
                            Text(
                              [
                                supplier.contact,
                                supplier.email,
                              ].where((v) => v.trim().isNotEmpty).join('  -  '),
                              style: const TextStyle(color: Color(0xFF6D7383)),
                            ),
                          const SizedBox(height: 14),
                          const Text('Location'),
                          const SizedBox(height: 6),
                          Text(locationName.isEmpty ? 'Not set' : locationName),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Expected Date'),
                                    const SizedBox(height: 6),
                                    Text(
                                      order.expectedDate.isEmpty
                                          ? 'Not set'
                                          : order.expectedDate,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Status'),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: statusValue,
                                      items: statusOptions
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: disableActions
                                          ? null
                                          : (v) async {
                                              if (v == null) return;
                                              setLocal(
                                                () => isProcessing = true,
                                              );
                                              await _updatePurchaseOrderStatus(
                                                order,
                                                v,
                                              );
                                              setLocal(
                                                () => isProcessing = false,
                                              );
                                              setLocal(() {});
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (order.items.isEmpty)
                            const Text('No line items saved for this order.')
                          else
                            DataTable(
                              columns: const [
                                DataColumn(label: Text('PRODUCT')),
                                DataColumn(label: Text('QTY')),
                                DataColumn(label: Text('UNIT PRICE')),
                                DataColumn(label: Text('TOTAL')),
                              ],
                              rows: order.items.map((line) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(line.productName)),
                                    DataCell(Text('${line.quantity}')),
                                    DataCell(Text(self._money(line.unitPrice))),
                                    DataCell(Text(self._money(line.lineTotal))),
                                  ],
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total ${self._money(order.amount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (order.notes.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(order.notes),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: disableActions
                              ? null
                              : () async {
                                  setLocal(() => isProcessing = true);
                                  await _updatePurchaseOrderStatus(
                                    order,
                                    'CANCELLED',
                                  );
                                  setLocal(() => isProcessing = false);
                                  setLocal(() {});
                                },
                          child: const Text('Cancel Order'),
                        ),
                        ElevatedButton(
                          onPressed:
                              disableActions || order.status == 'APPROVED'
                              ? null
                              : () async {
                                  setLocal(() => isProcessing = true);
                                  await _updatePurchaseOrderStatus(
                                    order,
                                    'APPROVED',
                                  );
                                  setLocal(() => isProcessing = false);
                                  setLocal(() {});
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandIndigo,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approve'),
                        ),
                        if (!isLocked)
                          ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    setLocal(() => isProcessing = true);
                                    await _updatePurchaseOrderStatus(
                                      order,
                                      'RECEIVED',
                                    );
                                    setLocal(() => isProcessing = false);
                                    setLocal(() {});
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Receive Stock'),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION: Sales Sub-Permission Toggle Helper
  // WHAT  : SwitchListTile widget that adds or removes a single permission
  //         key from the mutable Set<String> passed in.  Calls setLocal to
  //         rebuild the parent StatefulBuilder after each toggle.
  //         Example keys: 'SALES_DISCOUNT', 'SALES_REFUND', 'SALES_VOID',
  //                        'SALES_COST_PRICE_VIEW', 'SALES_CREDIT'.
  // WHERE : Used inside _showUserDialog to render the granular Sales
  //         permissions section of the user permission form.
  // TODO  : Group related toggles under collapsible ExpansionTile sections
  //         to reduce visual clutter when many permissions are listed.
  // ---------------------------------------------------------------------------
  Widget _buildSalesSubPermissionToggle({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required String permKey,
    required Set<String> selectedPermissions,
    required void Function(VoidCallback) setLocal,
  }) {
    final hasAccess = selectedPermissions.contains(permKey.toUpperCase());
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(label),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6D7383)),
      ),
      value: hasAccess,
      onChanged: (v) {
        setLocal(() {
          if (v) {
            selectedPermissions.add(permKey.toUpperCase());
          } else {
            selectedPermissions.remove(permKey.toUpperCase());
          }
        });
      },
    );
  }
}
