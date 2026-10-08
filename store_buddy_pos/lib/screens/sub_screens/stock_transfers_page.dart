part of '../dashboard_screen.dart';

extension _stock_transfers_pageExt on _DashboardScreenState {
  String _normalizeLocationName(String value) => value.trim().toLowerCase();

  bool _sameLocationName(String a, String b) =>
      _normalizeLocationName(a) == _normalizeLocationName(b);

  bool _isTransferDestination(_StockTransferItem transfer) =>
      _sameLocationName(transfer.toLocation, _activeLocationForWrites);

  Color _getTransferStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return const Color(0xFF64748B); // Slate
      case 'SENT':
        return const Color(0xFFD97706); // Amber
      case 'RESOLVED':
        return const Color(0xFF0D9488); // Teal
      case 'RECEIVED':
        return const Color(0xFF059669); // Emerald
      case 'PARTIALLY_RECEIVED':
        return const Color(0xFFEA580C); // Dark Orange
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getTransferStatusBg(String status) {
    return _getTransferStatusColor(status).withValues(alpha: 0.12);
  }

  Color _getStockRequestStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFD97706); // Amber
      case 'APPROVED':
        return const Color(0xFF059669); // Emerald
      case 'PARTIALLY_APPROVED':
        return const Color(0xFFEA580C); // Dark Orange
      case 'REJECTED':
        return const Color(0xFFDC2626); // Red
      case 'TRANSFERRED':
        return const Color(0xFF0D9488); // Teal
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStockRequestStatusBg(String status) {
    return _getStockRequestStatusColor(status).withValues(alpha: 0.12);
  }

  Widget _buildTransferTabPill({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: () => setState(() => _stockTransfersTabIndex = index),
      borderRadius: BorderRadius.circular(UiRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF312E81) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(UiRadius.sm),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? AppTheme.brandIndigo : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? (isDark ? Colors.white : const Color(0xFF1E293B)) : Colors.grey,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildStockTransfersPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter transfers
    final transferQuery = _salesSearchController.text.trim().toLowerCase();
    final transfers = _scopedStockTransfers.where((item) {
      if (transferQuery.isEmpty) return true;
      return item.referenceNo.toLowerCase().contains(transferQuery) ||
          item.fromLocation.toLowerCase().contains(transferQuery) ||
          item.toLocation.toLowerCase().contains(transferQuery) ||
          item.status.toLowerCase().contains(transferQuery);
    }).toList();

    // Filter requests
    final requestQuery = _stockRequestsSearchQuery.trim().toLowerCase();
    final requests = _scopedStockRequests.where((item) {
      if (requestQuery.isEmpty) return true;
      return item.requestNo.toLowerCase().contains(requestQuery) ||
          item.fromLocation.toLowerCase().contains(requestQuery) ||
          item.toLocation.toLowerCase().contains(requestQuery) ||
          item.reason.toLowerCase().contains(requestQuery) ||
          item.status.toLowerCase().contains(requestQuery);
    }).toList();

    final pendingCount = _scopedStockRequests
        .where((r) => r.status.toUpperCase() == 'PENDING')
        .length;

    return Padding(
      padding: const EdgeInsets.all(UiSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: UiSize.pageMaxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) =>
                              UiGradients.brand.createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: const Text(
                            'Stock Transfers & Requests',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transfer stock across locations and manage branch restock requests.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final req = await _showCreateStockRequestDialog();
                          if (!mounted) return;
                          if (req == null) return;
                          setState(() => _stockRequests.insert(0, req));
                          await _persistWorkspaceData();
                          await _enqueueSync('INSERT', 'stock_requests', req.id);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.brandIndigo,
                          side: const BorderSide(color: AppTheme.brandIndigo),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(UiRadius.md),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                        label: const Text(
                          'Request Stock',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _canManageEmployees
                            ? () async {
                                final transfer = await _showCreateTransferDialog();
                                if (!mounted) return;
                                if (transfer == null) return;
                                setState(() => _stockTransfers.insert(0, transfer));
                                await _persistWorkspaceData();
                                await _enqueueSync(
                                  'INSERT',
                                  'stock_transfers',
                                  transfer.id,
                                );
                                _addNotification(
                                  title: 'Stock Transfer Created',
                                  message:
                                      'Transfer #${transfer.referenceNo} (${transfer.items.length} items) from ${transfer.fromLocation} to ${transfer.toLocation}.',
                                  type: 'transfer',
                                  targetLocation: transfer.toLocation,
                                  referenceId: transfer.id,
                                );
                                _addNotification(
                                  title: 'Stock Transfer (HQ)',
                                  message:
                                      'New transfer #${transfer.referenceNo} from ${transfer.fromLocation} to ${transfer.toLocation}.',
                                  type: 'transfer',
                                  targetLocation: 'Main Branch',
                                  referenceId: transfer.id,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandIndigo,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(UiRadius.md),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Create Transfer',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: UiSpacing.md),

              // Tab Bar Pills
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(UiRadius.md),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTransferTabPill(
                      index: 0,
                      label: 'Stock Transfers (${transfers.length})',
                      icon: Icons.local_shipping_outlined,
                      isSelected: _stockTransfersTabIndex == 0,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 4),
                    _buildTransferTabPill(
                      index: 1,
                      label: 'Stock Requests (${requests.length})',
                      icon: Icons.pending_actions_rounded,
                      isSelected: _stockTransfersTabIndex == 1,
                      isDark: isDark,
                      badgeCount: pendingCount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UiSpacing.md),

              // Tab Views
              if (_stockTransfersTabIndex == 0) ...[
                // Search input for transfers
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : Colors.white,
                    borderRadius: BorderRadius.circular(UiRadius.md),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
                    ),
                    boxShadow: UiShadows.card,
                  ),
                  child: TextField(
                    controller: _salesSearchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search transfers by reference, locations, or status...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 13.5,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: UiSpacing.md),
                // Data list view
                Expanded(
                  child: transfers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 56,
                                color: colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: UiSpacing.sm),
                              Text(
                                'No stock transfers available.',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 14.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 185,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: transfers.length,
                          itemBuilder: (context, index) {
                            final transfer = transfers[index];
                            final totalQty = transfer.items.fold<double>(
                              0,
                              (sum, line) => sum + line.requestedQty,
                            );
                            final isDest = _isTransferDestination(transfer);
                            final statusColor =
                                _getTransferStatusColor(transfer.status);
                            final statusBg =
                                _getTransferStatusBg(transfer.status);

                            String chipText = transfer.status;
                            if (transfer.status == 'SENT' && isDest) {
                              chipText = 'VERIFY RECV';
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF111827)
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(UiRadius.lg),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF1E2D45)
                                      : const Color(0xFFE8EAFF),
                                ),
                                boxShadow: UiShadows.card,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            transfer.referenceNo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14.5,
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBg,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            chipText.replaceAll('_', ' '),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Location Flow Row
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.storefront_rounded,
                                          size: 16,
                                          color: Colors.blueAccent,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            transfer.fromLocation,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.warehouse_rounded,
                                          size: 16,
                                          color: Colors.purpleAccent,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            transfer.toLocation,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${transfer.items.length} items  •  Total Qty: $totalQty\n${_formatDate(transfer.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                        height: 1.3,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 32,
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                await _showTransferDetailsDialog(
                                                  transfer,
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: transfer.status ==
                                                              'SENT' &&
                                                          isDest
                                                      ? AppTheme.brandIndigo
                                                      : (isDark
                                                          ? const Color(
                                                              0xFF1E2D45,
                                                            )
                                                          : const Color(
                                                              0xFFE2E8F0,
                                                            )),
                                                ),
                                                foregroundColor:
                                                    transfer.status == 'SENT' &&
                                                            isDest
                                                        ? AppTheme.brandIndigo
                                                        : colorScheme.onSurface,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    UiRadius.md,
                                                  ),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              icon: Icon(
                                                transfer.status == 'SENT' &&
                                                        isDest
                                                    ? Icons
                                                        .assignment_turned_in_outlined
                                                    : Icons.checklist_rounded,
                                                size: 15,
                                              ),
                                              label: Text(
                                                transfer.status == 'SENT' &&
                                                        isDest
                                                    ? 'Verify & Receive'
                                                    : 'Checklist / Details',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: PopupMenuButton<String>(
                                            padding: EdgeInsets.zero,
                                            tooltip: 'Bills & Exports',
                                            icon: Icon(
                                              Icons.print_outlined,
                                              size: 17,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.65),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                UiRadius.md,
                                              ),
                                            ),
                                            onSelected: (action) async {
                                              switch (action) {
                                                case 'print_dispatch':
                                                  await _printTransferDispatchBill(
                                                    transfer,
                                                  );
                                                  break;
                                                case 'export_dispatch':
                                                  await _exportTransferDispatchCsv(
                                                    transfer,
                                                  );
                                                  break;
                                                case 'print_grn':
                                                  await _printGoodsReceivedNote(
                                                    transfer,
                                                  );
                                                  break;
                                                case 'export_grn':
                                                  await _exportGoodsReceivedNoteCsv(
                                                    transfer,
                                                  );
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'print_dispatch',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.print_outlined,
                                                      size: 16,
                                                      color:
                                                          AppTheme.brandIndigo,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Print Dispatch Bill (A4)',
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'export_dispatch',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.table_chart_outlined,
                                                      size: 16,
                                                      color: Colors.blueGrey,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Export Dispatch CSV',
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (transfer.status ==
                                                      'RECEIVED' ||
                                                  transfer.status ==
                                                      'PARTIALLY_RECEIVED' ||
                                                  transfer.status ==
                                                      'RESOLVED') ...[
                                                const PopupMenuDivider(),
                                                const PopupMenuItem(
                                                  value: 'print_grn',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .assignment_turned_in_outlined,
                                                        size: 16,
                                                        color:
                                                            Color(0xFF0D9488),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Print GRN Note (A4)',
                                                        style: TextStyle(
                                                          fontSize: 12.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'export_grn',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .file_download_outlined,
                                                        size: 16,
                                                        color:
                                                            Color(0xFF0D9488),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Export GRN CSV',
                                                        style: TextStyle(
                                                          fontSize: 12.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ] else ...[
                // Stock Requests Tab View
                Expanded(
                  child: _buildStockRequestsView(
                    requests,
                    isDark,
                    colorScheme,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockRequestsView(
    List<_StockRequestItem> requests,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final statusFiltered = requests.where((item) {
      if (_stockRequestStatusFilter == 'ALL') return true;
      return item.status.toUpperCase() == _stockRequestStatusFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(UiRadius.md),
            border: Border.all(
              color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
            ),
            boxShadow: UiShadows.card,
          ),
          child: TextField(
            onChanged: (val) => setState(() => _stockRequestsSearchQuery = val),
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search requests by request#, branch, reason, or status...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 13.5,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
              suffixIcon: _stockRequestsSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _stockRequestsSearchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filterKey in [
                'ALL',
                'PENDING',
                'APPROVED',
                'PARTIALLY_APPROVED',
                'TRANSFERRED',
                'REJECTED',
              ]) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filterKey.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _stockRequestStatusFilter == filterKey
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _stockRequestStatusFilter == filterKey
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                    selected: _stockRequestStatusFilter == filterKey,
                    selectedColor: AppTheme.brandIndigo,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() {
                        _stockRequestStatusFilter = selected ? filterKey : 'ALL';
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UiRadius.sm),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: UiSpacing.md),

        // Requests Grid / List
        Expanded(
          child: statusFiltered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pending_actions_rounded,
                        size: 56,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: UiSpacing.sm),
                      Text(
                        'No stock requests available.',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final req = await _showCreateStockRequestDialog();
                          if (!mounted) return;
                          if (req == null) return;
                          setState(() => _stockRequests.insert(0, req));
                          await _persistWorkspaceData();
                          await _enqueueSync('INSERT', 'stock_requests', req.id);
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: const Text('Create New Request'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 440,
                    mainAxisExtent: 215,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: statusFiltered.length,
                  itemBuilder: (context, index) {
                    final req = statusFiltered[index];
                    final totalRequested = req.items.fold<double>(
                      0,
                      (sum, line) => sum + line.requestedQty,
                    );
                    final totalApproved = req.items.fold<double>(
                      0,
                      (sum, line) => sum + line.approvedQty,
                    );
                    final statusColor = _getStockRequestStatusColor(req.status);
                    final statusBg = _getStockRequestStatusBg(req.status);

                    final isPending = req.status.toUpperCase() == 'PENDING';
                    final isSupplying = _sameLocationName(req.fromLocation, _activeLocationForWrites);
                    final canReview = isPending && (isSupplying || _isOwner || _isAdmin || _isManager);

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111827) : Colors.white,
                        borderRadius: BorderRadius.circular(UiRadius.lg),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
                        ),
                        boxShadow: UiShadows.card,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    req.requestNo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    req.status.replaceAll('_', ' '),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Branch Route Row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SUPPLYING BRANCH',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        req.fromLocation,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'REQUESTING BRANCH',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        req.toLocation,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Details / items summary
                            Row(
                              children: [
                                Text(
                                  '${req.items.length} items (${totalRequested.toStringAsFixed(totalRequested.truncateToDouble() == totalRequested ? 0 : 2)} units requested)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                if (totalApproved > 0 && req.status != 'PENDING') ...[
                                  Text(
                                    ' • ${totalApproved.toStringAsFixed(totalApproved.truncateToDouble() == totalApproved ? 0 : 2)} approved',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (req.reason.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Reason: ${req.reason}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const Spacer(),

                            // Footer button row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'By ${req.requestedBy} • ${_formatDate(req.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _showStockRequestReviewDialog(req),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canReview
                                        ? AppTheme.brandIndigo
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                    foregroundColor: canReview
                                        ? Colors.white
                                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(UiRadius.md),
                                    ),
                                  ),
                                  icon: Icon(
                                    canReview
                                        ? Icons.rate_review_rounded
                                        : Icons.visibility_outlined,
                                    size: 15,
                                  ),
                                  label: Text(
                                    canReview ? 'Review & Fulfill' : 'View Details',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<_StockRequestItem?> _showCreateStockRequestDialog() async {
    final locations = _availableLocationNames
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (locations.length < 2) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least two locations are required for branch stock requests.')),
      );
      return null;
    }

    var toLocation = _activeLocationForWrites;
    if (!locations.contains(toLocation)) {
      toLocation = locations.first;
    }
    var fromLocation = locations.firstWhere(
      (loc) => _sameLocationName(loc, 'Main Branch') && !_sameLocationName(loc, toLocation),
      orElse: () => locations.firstWhere(
        (loc) => !_sameLocationName(loc, toLocation),
        orElse: () => locations.first,
      ),
    );

    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    final lines = <_StockRequestLine>[];
    String searchQuery = '';

    final created = await showGeneralDialog<_StockRequestItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CreateStockRequestDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogContext, setLocal) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final colorScheme = theme.colorScheme;
            final overlayBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

            final catalogProducts = _products.fold<Map<String, _ProductItem>>({}, (map, p) {
              if (!map.containsKey(p.id)) {
                map[p.id] = p;
              }
              return map;
            }).values.toList();

            final totalUnits = lines.fold<double>(0, (s, l) => s + l.requestedQty);

            return _SideSheetContainer(
              title: 'Create Stock Request',
              width: 780,
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: (lines.isEmpty || _sameLocationName(fromLocation, toLocation))
                        ? null
                        : () {
                            final now = DateTime.now();
                            final reqItem = _StockRequestItem(
                              id: 'REQ${now.microsecondsSinceEpoch}',
                              requestNo: 'REQ-${now.millisecondsSinceEpoch}',
                              fromLocation: fromLocation,
                              toLocation: toLocation,
                              reason: reasonController.text.trim().isEmpty
                                  ? 'Stock replenishment'
                                  : reasonController.text.trim(),
                              notes: notesController.text.trim(),
                              status: 'PENDING',
                              requestedBy: _currentUserName,
                              createdAt: now,
                              items: lines,
                            );

                            _addNotification(
                              title: 'New Stock Request',
                              message:
                                  'Request #${reqItem.requestNo} for ${reqItem.items.length} items from ${reqItem.toLocation}.',
                              type: 'stock_request',
                              targetLocation: reqItem.fromLocation,
                              referenceId: reqItem.id,
                            );
                            _addNotification(
                              title: 'Stock Request (HQ)',
                              message:
                                  '${reqItem.toLocation} requested ${reqItem.items.length} items from ${reqItem.fromLocation}.',
                              type: 'stock_request',
                              targetLocation: 'Main Branch',
                              referenceId: reqItem.id,
                            );

                            Navigator.pop(dialogContext, reqItem);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandIndigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 17),
                    label: Text(
                      lines.isEmpty
                          ? 'Submit Request'
                          : 'Submit Request (${lines.length} items)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: toLocation,
                            decoration: const InputDecoration(
                              labelText: 'Requesting Branch (Your Branch)',
                              prefixIcon: Icon(Icons.storefront_rounded),
                            ),
                            items: locations
                                .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setLocal(() {
                                toLocation = val;
                                if (_sameLocationName(fromLocation, toLocation)) {
                                  fromLocation = locations.firstWhere(
                                    (l) => !_sameLocationName(l, toLocation),
                                    orElse: () => locations.first,
                                  );
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: fromLocation,
                            decoration: const InputDecoration(
                              labelText: 'Supplying Branch (Source)',
                              prefixIcon: Icon(Icons.warehouse_rounded),
                            ),
                            items: locations
                                .where((loc) => !_sameLocationName(loc, toLocation))
                                .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setLocal(() => fromLocation = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Stock Request',
                        hintText: 'e.g. Low stock alert, weekly restock, high customer demand',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes / Instructions (Optional)',
                        hintText: 'Urgent priority, special packaging instructions...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Products to Request',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Check products below and set required quantities (${lines.length} items, ${totalUnits.toStringAsFixed(totalUnits.truncateToDouble() == totalUnits ? 0 : 2)} units)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (lines.isNotEmpty)
                          TextButton(
                            onPressed: () => setLocal(() => lines.clear()),
                            child: const Text('Clear All', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      onChanged: (val) => setLocal(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search product name, barcode, or category (filters instantly)...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setLocal(() => searchQuery = ''),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Builder(
                      builder: (context) {
                        final q = searchQuery.trim().toLowerCase();
                        final filtered = catalogProducts.where((p) {
                          if (q.isEmpty) return true;
                          return p.name.toLowerCase().contains(q) ||
                              (p.barcode?.toLowerCase().contains(q) ?? false) ||
                              p.category.toLowerCase().contains(q);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(UiRadius.md),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'No matching products found in catalog.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: overlayBgColor,
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, idx) {
                              final product = filtered[idx];
                              final isSelected = lines.any((l) => l.productId == product.id);
                              final lineIdx = lines.indexWhere((l) => l.productId == product.id);
                              final reqQty = isSelected ? lines[lineIdx].requestedQty : 1.0;

                              final supplyProduct = _products.firstWhere(
                                (p) => p.id == product.id && _sameLocationName(p.locationId, fromLocation),
                                orElse: () => product,
                              );
                              final myProduct = _products.firstWhere(
                                (p) => p.id == product.id && _sameLocationName(p.locationId, toLocation),
                                orElse: () => product,
                              );

                              return InkWell(
                                onTap: () {
                                  setLocal(() {
                                    if (isSelected) {
                                      lines.removeAt(lineIdx);
                                    } else {
                                      lines.add(_StockRequestLine(
                                        productId: product.id,
                                        productName: product.name,
                                        requestedQty: 1.0,
                                        approvedQty: 0.0,
                                      ));
                                    }
                                  });
                                },
                                child: Container(
                                  color: isSelected
                                      ? (isDark
                                          ? const Color(0xFF312E81).withValues(alpha: 0.3)
                                          : const Color(0xFFEEF2FF))
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (checked) {
                                          setLocal(() {
                                            if (checked == true) {
                                              if (!isSelected) {
                                                lines.add(_StockRequestLine(
                                                  productId: product.id,
                                                  productName: product.name,
                                                  requestedQty: 1.0,
                                                  approvedQty: 0.0,
                                                ));
                                              }
                                            } else {
                                              if (isSelected) {
                                                lines.removeAt(lineIdx);
                                              }
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                fontSize: 13.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'At $fromLocation: ${supplyProduct.stock}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Current at $toLocation: ${myProduct.stock}',
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 19),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              onPressed: () {
                                                setLocal(() {
                                                  if (lines[lineIdx].requestedQty > 1) {
                                                    lines[lineIdx].requestedQty--;
                                                  } else {
                                                    lines.removeAt(lineIdx);
                                                  }
                                                });
                                              },
                                            ),
                                            Container(
                                              width: 38,
                                              alignment: Alignment.center,
                                              child: Text(
                                                reqQty.toStringAsFixed(reqQty.truncateToDouble() == reqQty ? 0 : 2),
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              onPressed: () {
                                                setLocal(() {
                                                  lines[lineIdx].requestedQty++;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),
                    Text(
                      'Requested Items Basket (${lines.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    if (lines.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                        child: const Center(
                          child: Text(
                            'No items selected. Tick products above to request them.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UiRadius.md),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      line.productName,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                        onPressed: () {
                                          setLocal(() {
                                            if (line.requestedQty > 1) {
                                              line.requestedQty--;
                                            } else {
                                              lines.removeAt(index);
                                            }
                                          });
                                        },
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          line.requestedQty.toStringAsFixed(line.requestedQty.truncateToDouble() == line.requestedQty ? 0 : 2),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                        onPressed: () {
                                          setLocal(() => line.requestedQty++);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      setLocal(() => lines.removeAt(index));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
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

    reasonController.dispose();
    notesController.dispose();
    return created;
  }

  Future<void> _showStockRequestReviewDialog(_StockRequestItem request) async {
    final responseNotesCtrl = TextEditingController(text: request.responseNotes);
    final approvedQuantities = <String, double>{};
    final lineNotesControllers = <String, TextEditingController>{};

    for (final item in request.items) {
      final srcProd = _products.firstWhere(
        (p) => p.id == item.productId && _sameLocationName(p.locationId, request.fromLocation),
        orElse: () => _products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => _ProductItem(id: item.productId, name: item.productName, category: '', price: 0, stock: 0, minStock: 0),
        ),
      );

      if (request.status == 'PENDING') {
        final defaultApproved = math.min(item.requestedQty, srcProd.stock.clamp(0.0, 1000000.0));
        approvedQuantities[item.productId] = item.approvedQty > 0 ? item.approvedQty : defaultApproved;
      } else {
        approvedQuantities[item.productId] = item.approvedQty;
      }
      lineNotesControllers[item.productId] = TextEditingController(text: item.notes);
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StockRequestReviewDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogContext, setLocal) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final colorScheme = theme.colorScheme;
            final isPending = request.status == 'PENDING';
            final canReview = isPending &&
                (_sameLocationName(request.fromLocation, _activeLocationForWrites) ||
                    _isOwner ||
                    _isAdmin ||
                    _isManager);

            final statusColor = _getStockRequestStatusColor(request.status);
            final statusBg = _getStockRequestStatusBg(request.status);

            return _SideSheetContainer(
              title: 'Stock Request: ${request.requestNo}',
              width: 800,
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                  if (canReview) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: dialogContext,
                          builder: (c) => AlertDialog(
                            title: const Text('Reject Stock Request'),
                            content: Text('Are you sure you want to reject request ${request.requestNo}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Yes, Reject'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        request.status = 'REJECTED';
                        request.responseNotes = responseNotesCtrl.text.trim();
                        request.approvedBy = _currentUserName;
                        request.updatedAt = DateTime.now();

                        for (final item in request.items) {
                          item.approvedQty = 0.0;
                          item.notes = lineNotesControllers[item.productId]?.text.trim() ?? '';
                        }

                        await _persistWorkspaceData();
                        await _enqueueSync('UPDATE', 'stock_requests', request.id);

                        _addNotification(
                          title: 'Stock Request Rejected',
                          message: 'Request #${request.requestNo} was rejected by ${request.fromLocation}.',
                          type: 'stock_request',
                          targetLocation: request.toLocation,
                          referenceId: request.id,
                        );
                        _addNotification(
                          title: 'Stock Request Rejected (HQ)',
                          message: 'Request #${request.requestNo} from ${request.toLocation} was rejected.',
                          type: 'stock_request',
                          targetLocation: 'Main Branch',
                          referenceId: request.id,
                        );

                        if (!mounted) return;
                        setState(() {});
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Stock request rejected.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Reject Request'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        double totalApproved = 0;
                        for (final item in request.items) {
                          final approved = approvedQuantities[item.productId] ?? 0.0;
                          item.approvedQty = approved;
                          item.notes = lineNotesControllers[item.productId]?.text.trim() ?? '';
                          totalApproved += approved;
                        }

                        if (totalApproved <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please approve at least 1 unit of an item before dispatching transfer.'),
                            ),
                          );
                          return;
                        }

                        final allFull = request.items.every(
                          (item) => (approvedQuantities[item.productId] ?? 0) >= item.requestedQty,
                        );
                        final newStatus = allFull ? 'APPROVED' : 'PARTIALLY_APPROVED';

                        final transferLines = <_StockTransferLine>[];
                        for (final item in request.items) {
                          final approved = approvedQuantities[item.productId] ?? 0.0;
                          if (approved > 0) {
                            transferLines.add(_StockTransferLine(
                              productId: item.productId,
                              productName: item.productName,
                              requestedQty: approved,
                              sentQty: approved,
                              receivedQty: 0.0,
                              checked: false,
                            ));
                          }
                        }

                        final now = DateTime.now();
                        final transfer = _StockTransferItem(
                          id: 'TR${now.microsecondsSinceEpoch}',
                          referenceNo: 'TR-${now.millisecondsSinceEpoch}',
                          fromLocation: request.fromLocation,
                          toLocation: request.toLocation,
                          reason: request.reason,
                          notes: 'Dispatched for Request #${request.requestNo}. ${responseNotesCtrl.text.trim()}',
                          status: 'SENT',
                          createdBy: _currentUserName,
                          createdAt: now,
                          items: transferLines,
                        );

                        // Deduct stock at supplying location and add stock adjustment logs
                        for (final line in transfer.items) {
                          final srcIdx = _products.indexWhere(
                            (p) => p.id == line.productId && _sameLocationName(p.locationId, request.fromLocation),
                          );
                          if (srcIdx >= 0) {
                            final src = _products[srcIdx];
                            final before = src.stock;
                            src.stock = (src.stock - line.sentQty).clamp(0.0, 1000000000.0);
                            if (_productRepository != null) {
                              await _productRepository!.updateProduct(_toDomainProduct(src));
                            }
                            final adj = _StockAdjustmentItem(
                              id: 'SA${DateTime.now().microsecondsSinceEpoch}-${line.productId}-dsp',
                              productId: src.id,
                              productName: src.name,
                              delta: -line.sentQty,
                              beforeStock: before,
                              afterStock: src.stock,
                              reason: 'Dispatched for Request #${request.requestNo} (${transfer.referenceNo})',
                              performedBy: _currentUserName,
                              createdAt: DateTime.now(),
                            );
                            _stockAdjustments.insert(0, adj);
                            await _enqueueSync('INSERT', 'stock_adjustments', adj.id);
                          }
                        }

                        request.status = newStatus;
                        request.transferId = transfer.id;
                        request.approvedBy = _currentUserName;
                        request.responseNotes = responseNotesCtrl.text.trim();
                        request.updatedAt = now;

                        _stockTransfers.insert(0, transfer);

                        await _persistWorkspaceData();
                        await _enqueueSync('UPDATE', 'stock_requests', request.id);
                        await _enqueueSync('INSERT', 'stock_transfers', transfer.id);

                        _addNotification(
                          title: 'Stock Request Approved',
                          message:
                              'Request #${request.requestNo} was ${newStatus == 'APPROVED' ? 'fully' : 'partially'} approved! Transfer #${transfer.referenceNo} dispatched from ${request.fromLocation}.',
                          type: 'stock_request',
                          targetLocation: request.toLocation,
                          referenceId: request.id,
                        );
                        _addNotification(
                          title: 'Stock Transfer Dispatched (HQ)',
                          message:
                              'Transfer #${transfer.referenceNo} dispatched for Request #${request.requestNo} from ${request.fromLocation} to ${request.toLocation}.',
                          type: 'transfer',
                          targetLocation: 'Main Branch',
                          referenceId: transfer.id,
                        );

                        if (!mounted) return;
                        setState(() {});
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Request approved! Transfer ${transfer.referenceNo} dispatched to ${request.toLocation}.',
                            ),
                            action: SnackBarAction(
                              label: 'View Transfer',
                              onPressed: () => _showTransferDetailsDialog(transfer),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                      label: const Text(
                        'Approve & Create Transfer',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(UiRadius.lg),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Request Status:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  request.status.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Date: ${_formatDate(request.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Supplying Branch (Source)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      request.fromLocation,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Requesting Branch (Destination)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      request.toLocation,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (request.reason.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Reason: ${request.reason}',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ],
                          if (request.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Notes from requester: ${request.notes}',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Text(
                          'Requested Items & Fulfillment Quantities',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (canReview)
                          Text(
                            'Adjust approved quantities based on stock availability',
                            style: TextStyle(fontSize: 11.5, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: request.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final item = request.items[idx];
                        final srcProd = _products.firstWhere(
                          (p) => p.id == item.productId && _sameLocationName(p.locationId, request.fromLocation),
                          orElse: () => _products.firstWhere(
                            (p) => p.id == item.productId,
                            orElse: () => _ProductItem(id: item.productId, name: item.productName, category: '', price: 0, stock: 0, minStock: 0),
                          ),
                        );
                        final currentApproved = approvedQuantities[item.productId] ?? 0.0;
                        final hasShortage = srcProd.stock < item.requestedQty;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            border: Border.all(
                              color: currentApproved < item.requestedQty
                                  ? const Color(0xFFEA580C).withValues(alpha: 0.5)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: hasShortage
                                                    ? Colors.amber.withValues(alpha: 0.15)
                                                    : Colors.green.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Stock at ${request.fromLocation}: ${srcProd.stock}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: hasShortage ? const Color(0xFFD97706) : const Color(0xFF059669),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Requested: ${item.requestedQty.toStringAsFixed(item.requestedQty.truncateToDouble() == item.requestedQty ? 0 : 2)} units',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (canReview) ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Approved Qty', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                              onPressed: () {
                                                setLocal(() {
                                                  if (currentApproved > 0) {
                                                    approvedQuantities[item.productId] = currentApproved - 1;
                                                  }
                                                });
                                              },
                                            ),
                                            Container(
                                              width: 44,
                                              alignment: Alignment.center,
                                              child: Text(
                                                currentApproved.toStringAsFixed(currentApproved.truncateToDouble() == currentApproved ? 0 : 2),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: currentApproved < item.requestedQty
                                                      ? const Color(0xFFEA580C)
                                                      : const Color(0xFF059669),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                              onPressed: () {
                                                setLocal(() {
                                                  if (currentApproved < srcProd.stock) {
                                                    approvedQuantities[item.productId] = currentApproved + 1;
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Cannot approve more than available stock at source.'),
                                                        duration: Duration(seconds: 1),
                                                      ),
                                                    );
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Approved Qty', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.approvedQty.toStringAsFixed(item.approvedQty.truncateToDouble() == item.approvedQty ? 0 : 2),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              if (canReview) ...[
                                const SizedBox(height: 8),
                                TextField(
                                  controller: lineNotesControllers[item.productId],
                                  style: const TextStyle(fontSize: 12),
                                  decoration: const InputDecoration(
                                    hintText: 'Item note (e.g. only 5 dispatched, balance backordered)...',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    if (canReview) ...[
                      TextField(
                        controller: responseNotesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Fulfillment & Dispatch Notes',
                          hintText: 'e.g. Dispatched via morning courier, driver contact: 0771234567',
                        ),
                      ),
                    ] else if (request.responseNotes.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fulfillment Notes from Supplying Branch:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(request.responseNotes, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],

                    if (request.transferId != null && request.transferId!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final tr = _stockTransfers.firstWhere(
                            (t) => t.id == request.transferId,
                            orElse: () => _StockTransferItem(
                              id: request.transferId!,
                              referenceNo: request.transferId!,
                              fromLocation: request.fromLocation,
                              toLocation: request.toLocation,
                              reason: request.reason,
                              notes: '',
                              status: 'SENT',
                              createdBy: '',
                              createdAt: DateTime.now(),
                              items: [],
                            ),
                          );
                          Navigator.pop(dialogContext);
                          _showTransferDetailsDialog(tr);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.local_shipping_outlined, size: 16),
                        label: Text('View Dispatched Transfer (${request.transferId})'),
                      ),
                    ],
                  ],
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

    responseNotesCtrl.dispose();
    for (final c in lineNotesControllers.values) {
      c.dispose();
    }
  }

  Future<_StockTransferItem?> _showCreateTransferDialog() async {
    final locations = _availableLocationNames
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (locations.length < 2) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create at least two locations first.')),
      );
      return null;
    }

    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    var fromLocation = _activeLocationForWrites;
    if (!locations.contains(fromLocation)) {
      fromLocation = locations.first;
    }
    var toLocation = locations.firstWhere(
      (location) => location != fromLocation,
      orElse: () => locations.first,
    );

    final items = <_StockTransferLine>[];
    String searchQuery = '';

    final created = await showGeneralDialog<_StockTransferItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CreateTransferDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final sourceProducts = _products
                .where((product) => _sameLocationName(product.locationId, fromLocation))
                .toList();

            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final colorScheme = theme.colorScheme;
            final overlayBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

            return _SideSheetContainer(
              title: 'Create Stock Transfer',
              width: 720,
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: (items.isEmpty || fromLocation == toLocation)
                        ? null
                        : () {
                            final now = DateTime.now();
                            Navigator.pop(
                              context,
                              _StockTransferItem(
                                id: 'TR${now.microsecondsSinceEpoch}',
                                referenceNo: 'TR-${now.millisecondsSinceEpoch}',
                                fromLocation: fromLocation,
                                toLocation: toLocation,
                                reason: reasonController.text.trim(),
                                notes: notesController.text.trim(),
                                status: 'DRAFT',
                                createdBy: _currentUserName,
                                createdAt: now,
                                items: items,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandIndigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                    ),
                    child: const Text('Create Transfer'),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: fromLocation,
                            decoration: const InputDecoration(labelText: 'From Location'),
                            items: locations
                                .map(
                                  (loc) => DropdownMenuItem(
                                    value: loc,
                                    child: Text(loc),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setLocal(() {
                                fromLocation = value;
                                items.clear(); // Clear cart items if source location changes
                                final toCandidates = locations
                                    .where((loc) => loc != fromLocation)
                                    .toList();
                                if (toCandidates.isEmpty) {
                                  toLocation = fromLocation;
                                } else if (!toCandidates.contains(toLocation)) {
                                  toLocation = toCandidates.first;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: toLocation,
                            decoration: const InputDecoration(labelText: 'To Location'),
                            items: locations
                                .where((loc) => loc != fromLocation)
                                .map(
                                  (loc) => DropdownMenuItem(
                                    value: loc,
                                    child: Text(loc),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setLocal(() {
                                toLocation = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Transfer',
                        hintText: 'e.g. Stock replenishment, low inventory',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        hintText: 'Optional notes for receiver...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Product Selection Catalog
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Products to Transfer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${sourceProducts.length} products available at $fromLocation • ${items.length} selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sourceProducts.isNotEmpty) ...[
                          TextButton.icon(
                            onPressed: () {
                              setLocal(() {
                                final inStock = sourceProducts.where((p) => p.stock > 0).toList();
                                final allSelected = inStock.isNotEmpty &&
                                    inStock.every((p) => items.any((l) => l.productId == p.id));
                                if (allSelected) {
                                  items.clear();
                                } else {
                                  for (final p in inStock) {
                                    if (!items.any((l) => l.productId == p.id)) {
                                      items.add(_StockTransferLine(
                                        productId: p.id,
                                        productName: p.name,
                                        requestedQty: 1.0,
                                        sentQty: 1.0,
                                        receivedQty: 0.0,
                                        checked: false,
                                      ));
                                    }
                                  }
                                }
                              });
                            },
                            icon: const Icon(Icons.select_all_rounded, size: 16),
                            label: Text(
                              sourceProducts.where((p) => p.stock > 0).isNotEmpty &&
                                      sourceProducts.where((p) => p.stock > 0).every((p) => items.any((l) => l.productId == p.id))
                                  ? 'Deselect All'
                                  : 'Select All In-Stock',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Search field with clear button
                    TextField(
                      onChanged: (val) {
                        setLocal(() => searchQuery = val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search product name, barcode, or category (filters instantly)...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setLocal(() => searchQuery = ''),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Product Catalog List (Always visible, filtered dynamically from 1st letter)
                    Builder(
                      builder: (context) {
                        final q = searchQuery.trim().toLowerCase();
                        final filtered = sourceProducts.where((p) {
                          if (q.isEmpty) return true;
                          return p.name.toLowerCase().contains(q) ||
                              (p.barcode?.toLowerCase().contains(q) ?? false) ||
                              p.category.toLowerCase().contains(q);
                        }).toList();

                        if (filtered.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(UiRadius.md),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                sourceProducts.isEmpty
                                    ? 'No products found at $fromLocation.'
                                    : 'No products matching "$searchQuery".',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: overlayBgColor,
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, idx) {
                              final product = filtered[idx];
                              final isSelected = items.any((l) => l.productId == product.id);
                              final itemIndex = items.indexWhere((l) => l.productId == product.id);
                              final selectedQty = isSelected ? items[itemIndex].requestedQty : 1.0;
                              final inStock = product.stock > 0;

                              return InkWell(
                                onTap: !inStock
                                    ? null
                                    : () {
                                        setLocal(() {
                                          if (isSelected) {
                                            items.removeAt(itemIndex);
                                          } else {
                                            items.add(_StockTransferLine(
                                              productId: product.id,
                                              productName: product.name,
                                              requestedQty: 1.0,
                                              sentQty: 1.0,
                                              receivedQty: 0.0,
                                              checked: false,
                                            ));
                                          }
                                        });
                                      },
                                child: Container(
                                  color: isSelected
                                      ? (isDark
                                          ? const Color(0xFF312E81).withValues(alpha: 0.3)
                                          : const Color(0xFFEEF2FF))
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: !inStock
                                            ? null
                                            : (checked) {
                                                setLocal(() {
                                                  if (checked == true) {
                                                    if (!isSelected) {
                                                      items.add(_StockTransferLine(
                                                        productId: product.id,
                                                        productName: product.name,
                                                        requestedQty: 1.0,
                                                        sentQty: 1.0,
                                                        receivedQty: 0.0,
                                                        checked: false,
                                                      ));
                                                    }
                                                  } else {
                                                    if (isSelected) {
                                                      items.removeAt(itemIndex);
                                                    }
                                                  }
                                                });
                                              },
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                fontSize: 13.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                if (product.category.isNotEmpty) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      product.category,
                                                      style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                                                  Text(
                                                    'Barcode: ${product.barcode}',
                                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: inStock
                                                        ? const Color(0xFF059669).withValues(alpha: 0.12)
                                                        : Colors.red.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    inStock ? 'Stock: ${product.stock}' : 'Out of stock',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: inStock ? const Color(0xFF059669) : Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 19),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              onPressed: () {
                                                setLocal(() {
                                                  if (items[itemIndex].requestedQty > 1) {
                                                    items[itemIndex].requestedQty--;
                                                    items[itemIndex].sentQty = items[itemIndex].requestedQty;
                                                  } else {
                                                    items.removeAt(itemIndex);
                                                  }
                                                });
                                              },
                                            ),
                                            Container(
                                              width: 38,
                                              alignment: Alignment.center,
                                              child: Text(
                                                selectedQty.toStringAsFixed(selectedQty.truncateToDouble() == selectedQty ? 0 : 2),
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                              onPressed: () {
                                                setLocal(() {
                                                  if (items[itemIndex].requestedQty < product.stock) {
                                                    items[itemIndex].requestedQty++;
                                                    items[itemIndex].sentQty = items[itemIndex].requestedQty;
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Cannot transfer more than available stock.'),
                                                        duration: Duration(seconds: 1),
                                                      ),
                                                    );
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),
                    // Selected Items Summary Table
                    Row(
                      children: [
                        Text(
                          'Transfer Items (${items.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        if (items.isNotEmpty)
                          TextButton(
                            onPressed: () => setLocal(() => items.clear()),
                            child: const Text('Clear All', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                        child: const Center(
                          child: Text(
                            'No items selected. Check products from the catalog above to add them.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final line = items[index];
                          final product = sourceProducts.firstWhere(
                            (p) => p.id == line.productId,
                            orElse: () => _ProductItem(
                              id: line.productId,
                              name: line.productName,
                              category: '',
                              price: 0,
                              stock: 0,
                              minStock: 0,
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UiRadius.md),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.productName,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Available Stock: ${product.stock}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                        onPressed: () {
                                          setLocal(() {
                                            if (line.requestedQty > 1) {
                                              line.requestedQty--;
                                              line.sentQty = line.requestedQty;
                                            } else {
                                              items.removeAt(index);
                                            }
                                          });
                                        },
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          line.requestedQty.toStringAsFixed(line.requestedQty.truncateToDouble() == line.requestedQty ? 0 : 2),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                        onPressed: () {
                                          setLocal(() {
                                            if (line.requestedQty < product.stock) {
                                              line.requestedQty++;
                                              line.sentQty = line.requestedQty;
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Cannot transfer more than available stock.'),
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      setLocal(() => items.removeAt(index));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
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

    reasonController.dispose();
    notesController.dispose();
    return created;
  }

  Future<void> _showTransferDetailsDialog(_StockTransferItem transfer) async {
    final receivedValues = <String, double>{};
    var receivedValuesInitialized = false;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'TransferDetailsDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogContext, setLocal) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final colorScheme = theme.colorScheme;
            final canSend =
                transfer.status == 'DRAFT' &&
                _sameLocationName(
                  transfer.fromLocation,
                  _activeLocationForWrites,
                );
            final canReceive =
                transfer.status == 'SENT' &&
                _sameLocationName(transfer.toLocation, _activeLocationForWrites);
            final canSwitchToReceive =
                transfer.status == 'SENT' &&
                !_sameLocationName(
                  transfer.toLocation,
                  _activeLocationForWrites,
                ) &&
                (_isOwner || _isManager || _canManageEmployees);

            Future<void> persistUpdate(String status) async {
              transfer.status = status;
              try {
                await _persistWorkspaceData();
                await _enqueueSync('UPDATE', 'stock_transfers', transfer.id);
              } catch (e, st) {
                // ignore: avoid_print
                print('persistUpdate error: $e\n$st');
              }
              if (!mounted) return;
              setState(() {});
            }

            Future<void> dispatchTransfer() async {
              Future<void> applyDispatchUpdates() async {
                for (final line in transfer.items) {
                  final sourceIndex = _products.indexWhere(
                    (p) =>
                        p.id == line.productId &&
                        _sameLocationName(p.locationId, transfer.fromLocation),
                  );
                  if (sourceIndex < 0) {
                    continue;
                  }

                  final source = _products[sourceIndex];
                  final sourceBefore = source.stock;
                  source.stock = (source.stock - line.sentQty).clamp(0.0, 1000000000.0);
                  if (_productRepository != null) {
                    await _productRepository!.updateProduct(
                      _toDomainProduct(source),
                    );
                  }

                  final adjustment = _StockAdjustmentItem(
                    id: 'SA${DateTime.now().microsecondsSinceEpoch}-${line.productId}-dsp',
                    productId: source.id,
                    productName: source.name,
                    delta: -line.sentQty,
                    beforeStock: sourceBefore,
                    afterStock: source.stock,
                    reason: 'Stock transfer ${transfer.referenceNo} dispatched',
                    performedBy: _currentUserName,
                    createdAt: DateTime.now(),
                  );
                  _stockAdjustments.insert(0, adjustment);
                  await _enqueueSync(
                    'INSERT',
                    'stock_adjustments',
                    adjustment.id,
                  );
                }
                await persistUpdate('SENT');
                _addNotification(
                  title: 'Incoming Stock Transfer',
                  message: 'Transfer ${transfer.referenceNo} dispatched from ${transfer.fromLocation} to ${transfer.toLocation} (${transfer.items.length} items).',
                  type: 'transfer',
                  targetLocation: transfer.toLocation,
                  referenceId: transfer.id,
                );
              }

              if (_syncService != null) {
                await _syncService!.runWithoutAutoSync(applyDispatchUpdates);
              } else {
                await applyDispatchUpdates();
              }
              await _refreshPendingSyncQueue();
            }

            Future<void> completeTransfer() async {
              Future<void> applyTransferUpdates() async {
                for (final line in transfer.items) {
                  final receivedQty = line.receivedQty.clamp(0.0, line.sentQty);
                  final shortage = (line.sentQty - receivedQty).clamp(0.0, line.sentQty);
                  line.shortageQty = shortage;
                  if (receivedQty <= 0) {
                    continue;
                  }

                  final sourceIndex = _products.indexWhere(
                    (p) =>
                        p.id == line.productId &&
                        _sameLocationName(p.locationId, transfer.fromLocation),
                  );
                  _ProductItem? source;
                  if (sourceIndex >= 0) {
                    source = _products[sourceIndex];
                  }

                  final targetIndex = _products.indexWhere(
                    (p) =>
                        _sameLocationName(p.locationId, transfer.toLocation) &&
                        (p.id == line.productId ||
                            (source != null &&
                                source.barcode.trim().isNotEmpty &&
                                p.barcode.trim().toLowerCase() ==
                                    source.barcode.trim().toLowerCase()) ||
                            (source != null &&
                                p.name.trim().toLowerCase() ==
                                    source.name.trim().toLowerCase())),
                  );

                  double targetBefore = 0.0;
                  _ProductItem targetProduct;

                  if (targetIndex >= 0) {
                    targetProduct = _products[targetIndex];
                    targetBefore = targetProduct.stock;
                    targetProduct.stock += receivedQty;
                    if (_productRepository != null) {
                      await _productRepository!.updateProduct(
                        _toDomainProduct(targetProduct),
                      );
                    }
                  } else {
                    if (source == null) continue;
                    final normalizedLocation = transfer.toLocation
                        .trim()
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
                    targetProduct = _ProductItem(
                      id: '${source.id}_${normalizedLocation}_${DateTime.now().microsecondsSinceEpoch}',
                      name: line.productName,
                      category: source.category,
                      barcode: source.barcode,
                      measureUnit: source.measureUnit,
                      productType: source.productType,
                      description: source.description,
                      costPrice: source.costPrice,
                      warrantyMonths: source.warrantyMonths,
                      expiryDate: source.expiryDate,
                      expiryReminderMode: source.expiryReminderMode,
                      expiryReminderDays: source.expiryReminderDays,
                      attributeValues: Map<String, dynamic>.from(
                        source.attributeValues,
                      ),
                      price: source.price,
                      minPrice: source.minPrice,
                      stock: receivedQty,
                      minStock: source.minStock,
                      supplierId: source.supplierId,
                      locationId: transfer.toLocation,
                    );
                    _products.add(targetProduct);
                    if (_productRepository != null) {
                      await _productRepository!.insertProduct(
                        _toDomainProduct(targetProduct),
                      );
                    }
                  }

                  final adjustment = _StockAdjustmentItem(
                    id: 'SA${DateTime.now().microsecondsSinceEpoch}-${line.productId}-rcv',
                    productId: targetProduct.id,
                    productName: targetProduct.name,
                    delta: receivedQty,
                    beforeStock: targetBefore,
                    afterStock: targetProduct.stock,
                    reason: 'Stock transfer ${transfer.referenceNo} received',
                    performedBy: _currentUserName,
                    createdAt: DateTime.now(),
                  );
                  _stockAdjustments.insert(0, adjustment);
                  await _enqueueSync(
                    'INSERT',
                    'stock_adjustments',
                    adjustment.id,
                  );
                }

                final allReceived = transfer.items.every(
                  (item) => item.receivedQty >= item.sentQty,
                );
                await persistUpdate(
                  allReceived ? 'RECEIVED' : 'PARTIALLY_RECEIVED',
                );

                if (allReceived) {
                  _addNotification(
                    title: 'Transfer Fully Received',
                    message: 'Transfer ${transfer.referenceNo} was fully accepted at ${transfer.toLocation} by $_currentUserName.',
                    type: 'transfer',
                    targetLocation: transfer.fromLocation,
                    referenceId: transfer.id,
                  );
                } else {
                  double totalShortage = 0.0;
                  for (final item in transfer.items) {
                    if (item.shortageQty > 0) totalShortage += item.shortageQty;
                  }
                  _addNotification(
                    title: 'Transfer Discrepancy Alert',
                    message: 'Transfer ${transfer.referenceNo} was received at ${transfer.toLocation} with shortage of ${totalShortage.toStringAsFixed(1)} units.',
                    type: 'transfer',
                    targetLocation: transfer.fromLocation,
                    referenceId: transfer.id,
                  );
                }
              }

              if (_syncService != null) {
                await _syncService!.runWithoutAutoSync(applyTransferUpdates);
              } else {
                await applyTransferUpdates();
              }

              await _refreshPendingSyncQueue();
            }

            if (!receivedValuesInitialized) {
              for (final line in transfer.items) {
                final double initial = line.receivedQty > 0
                    ? line.receivedQty
                    : (canReceive ? line.sentQty : 0.0);
                receivedValues[line.productId] = initial;
                line.receivedQty = initial;
                line.checked = initial > 0;
              }
              receivedValuesInitialized = true;
            }

            final checkedItems = transfer.items.where((line) => receivedValues[line.productId] == line.sentQty).length;
            final progressPercent = transfer.items.isEmpty ? 1.0 : checkedItems / transfer.items.length;

            return _SideSheetContainer(
              title: 'Transfer Checklist Verification',
              width: 680,
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                  if (canSend) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await dispatchTransfer();
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                      child: const Text('Send Checklist'),
                    ),
                  ],
                  if (canReceive) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: transfer.items.any((item) => item.receivedQty > 0)
                          ? () async {
                              double totalShortage = 0.0;
                              for (final item in transfer.items) {
                                final shortage = item.sentQty - item.receivedQty;
                                if (shortage > 0) {
                                  totalShortage += shortage;
                                }
                              }

                              if (totalShortage > 0) {
                                final confirm = await showDialog<bool>(
                                  context: dialogContext,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Report Discrepancy?'),
                                    content: Text(
                                      'There is a shortage of $totalShortage item(s). '
                                      'Do you want to report this discrepancy and mark the transfer as partially received?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.brandIndigo,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                              }

                              await completeTransfer();
                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                      child: const Text('Mark Received'),
                    ),
                  ],
                  if (transfer.status == 'PARTIALLY_RECEIVED' &&
                      (_isOwner || _isManager || _canManageEmployees)) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await _showResolveDiscrepancyDialog(dialogContext, transfer);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                      child: const Text('Resolve Discrepancy'),
                    ),
                  ],
                  if (canSwitchToReceive) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _selectedLocationScope = transfer.toLocation;
                        });
                        await _persistWorkspaceData();
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                      child: const Text('Switch to Transfer Location'),
                    ),
                  ],
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location flow card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SOURCE LOCATION', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(transfer.fromLocation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('DESTINATION LOCATION', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(transfer.toLocation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Reference: ${transfer.referenceNo}', style: const TextStyle(fontSize: 12.5)),
                              Text('Status: ${transfer.status}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _getTransferStatusColor(transfer.status))),
                            ],
                          ),
                          if (transfer.reason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Reason: ${transfer.reason}', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                            ),
                          ],
                          if (transfer.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Notes: ${transfer.notes}', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                            ),
                          ],
                          Builder(
                            builder: (context) {
                              double shortageCount = 0.0;
                              for (final item in transfer.items) {
                                final diff = item.sentQty - item.receivedQty;
                                if (diff > 0) {
                                  shortageCount += diff;
                                }
                              }
                              if (shortageCount > 0) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Shortage: $shortageCount item(s) detected',
                                          style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Document Actions Ribbon
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _printTransferDispatchBill(transfer),
                          icon: const Icon(Icons.print_outlined, size: 15),
                          label: const Text('Dispatch Bill (PDF)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.brandIndigo,
                            side: const BorderSide(color: AppTheme.brandIndigo),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiRadius.sm)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _exportTransferDispatchCsv(transfer),
                          icon: const Icon(Icons.table_chart_outlined, size: 15),
                          label: const Text('Export Dispatch CSV', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiRadius.sm)),
                          ),
                        ),
                        if (transfer.status == 'RECEIVED' ||
                            transfer.status == 'PARTIALLY_RECEIVED' ||
                            transfer.status == 'RESOLVED') ...[
                          ElevatedButton.icon(
                            onPressed: () => _printGoodsReceivedNote(transfer),
                            icon: const Icon(Icons.assignment_turned_in_outlined, size: 15),
                            label: const Text('Print GRN Note (PDF)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiRadius.sm)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _exportGoodsReceivedNoteCsv(transfer),
                            icon: const Icon(Icons.file_download_outlined, size: 15),
                            label: const Text('Export GRN CSV', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0D9488),
                              side: const BorderSide(color: Color(0xFF0D9488)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UiRadius.sm)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Progress Checklist Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items Checklist',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          '$checkedItems / ${transfer.items.length} Checked',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 6,
                        backgroundColor: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
                        color: progressPercent == 1.0 ? Colors.green : AppTheme.brandIndigo,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Verification Checklist Items list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transfer.items.length,
                      itemBuilder: (context, idx) {
                        final line = transfer.items[idx];
                        final initialValue = receivedValues[line.productId] ?? 0;
                        final isFullyChecked = initialValue == line.sentQty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            border: Border.all(
                              color: isFullyChecked
                                  ? Colors.green.withValues(alpha: 0.5)
                                  : (isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0)),
                              width: isFullyChecked ? 1.5 : 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            line.productName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Requested: ${line.requestedQty.toStringAsFixed(line.requestedQty.truncateToDouble() == line.requestedQty ? 0 : 2)}  •  Sent: ${line.sentQty.toStringAsFixed(line.sentQty.truncateToDouble() == line.sentQty ? 0 : 2)}',
                                            style: TextStyle(
                                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (canReceive) ...[
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: Colors.redAccent),
                                            onPressed: () {
                                              if (receivedValues[line.productId]! > 0) {
                                                setLocal(() {
                                                  receivedValues[line.productId] = receivedValues[line.productId]! - 1;
                                                  line.receivedQty = receivedValues[line.productId]!;
                                                  line.shortageQty = line.sentQty - line.receivedQty;
                                                  line.checked = line.receivedQty > 0;
                                                });
                                              }
                                            },
                                          ),
                                          Container(
                                            constraints: const BoxConstraints(minWidth: 32),
                                            child: Text(
                                              '${initialValue.toStringAsFixed(initialValue.truncateToDouble() == initialValue ? 0 : 2)}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Colors.green),
                                            onPressed: () {
                                              if (receivedValues[line.productId]! < line.sentQty) {
                                                setLocal(() {
                                                  receivedValues[line.productId] = receivedValues[line.productId]! + 1;
                                                  line.receivedQty = receivedValues[line.productId]!;
                                                  line.shortageQty = line.sentQty - line.receivedQty;
                                                  line.checked = line.receivedQty > 0;
                                                });
                                              }
                                            },
                                          ),
                                          Text(' / ${line.sentQty.toStringAsFixed(line.sentQty.truncateToDouble() == line.sentQty ? 0 : 2)}', style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isFullyChecked ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isFullyChecked ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                              size: 14,
                                              color: isFullyChecked ? Colors.green : Colors.amber,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isFullyChecked ? 'Checked (${line.receivedQty.toStringAsFixed(line.receivedQty.truncateToDouble() == line.receivedQty ? 0 : 2)})' : 'Verified (${line.receivedQty.toStringAsFixed(line.receivedQty.truncateToDouble() == line.receivedQty ? 0 : 2)}/${line.sentQty.toStringAsFixed(line.sentQty.truncateToDouble() == line.sentQty ? 0 : 2)})',
                                              style: TextStyle(
                                                color: isFullyChecked ? Colors.green : Colors.amber,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (canReceive && initialValue < line.sentQty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Shortage: ${(line.sentQty - initialValue).toStringAsFixed(1)}',
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.orange),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: line.shortageReason,
                                            onChanged: (val) {
                                              line.shortageReason = val.trim();
                                              line.shortageQty = line.sentQty - initialValue;
                                            },
                                            decoration: const InputDecoration(
                                              hintText: 'Discrepancy reason (e.g. damaged, broken, missing)...',
                                              hintStyle: TextStyle(fontSize: 11),
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              border: OutlineInputBorder(),
                                            ),
                                            style: const TextStyle(fontSize: 11.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (!canReceive && (line.shortageQty > 0 || line.sentQty > line.receivedQty)) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Shortage: ${(line.shortageQty > 0 ? line.shortageQty : (line.sentQty - line.receivedQty)).toStringAsFixed(1)} units${line.shortageReason.isNotEmpty ? " • Reason: ${line.shortageReason}" : ""}',
                                      style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
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

  Future<void> _showResolveDiscrepancyDialog(
    BuildContext parentContext,
    _StockTransferItem transfer,
  ) async {
    String selectedResolution = 'DAMAGED_LOSS';
    final courierController = TextEditingController();

    final resolved = await showDialog<bool>(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Resolve Stock Transfer Discrepancy'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select how to reconcile the shortage of items in this transfer:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedResolution,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Option',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'DAMAGED_LOSS',
                        child: Text('Mark as Damaged / Lost'),
                      ),
                      DropdownMenuItem(
                        value: 'RETURN_SOURCE',
                        child: Text('Return to Source Location'),
                      ),
                      DropdownMenuItem(
                        value: 'COURIER_CHARGE',
                        child: Text('Charge to Driver / Courier'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setLocal(() => selectedResolution = val);
                      }
                    },
                  ),
                  if (selectedResolution == 'COURIER_CHARGE') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: courierController,
                      decoration: const InputDecoration(
                        labelText: 'Driver / Courier Name',
                        hintText: 'Enter name of driver or courier',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Resolve'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resolved != true) {
      courierController.dispose();
      return;
    }

    double totalShortage = 0.0;
    for (final line in transfer.items) {
      final shortage = line.sentQty - line.receivedQty;
      if (shortage > 0) {
        totalShortage += shortage;
      }
    }

    String resolutionNote = '';

    Future<void> applyResolution() async {
      if (selectedResolution == 'RETURN_SOURCE') {
        for (final line in transfer.items) {
          final shortage = line.sentQty - line.receivedQty;
          if (shortage <= 0) continue;

          final sourceIndex = _products.indexWhere(
            (p) =>
                p.id == line.productId &&
                _sameLocationName(p.locationId, transfer.fromLocation),
          );
          if (sourceIndex >= 0) {
            final source = _products[sourceIndex];
            final beforeStock = source.stock;
            source.stock += shortage;

            if (_productRepository != null) {
              await _productRepository!.updateProduct(
                _toDomainProduct(source),
              );
            }

            final adjustment = _StockAdjustmentItem(
              id: 'SA${DateTime.now().microsecondsSinceEpoch}-${line.productId}-ret',
              productId: source.id,
              productName: source.name,
              delta: shortage,
              beforeStock: beforeStock,
              afterStock: source.stock,
              reason: 'Discrepancy resolution: Returned shortage of transfer ${transfer.referenceNo} to source',
              performedBy: _currentUserName,
              createdAt: DateTime.now(),
            );
            _stockAdjustments.insert(0, adjustment);
            await _enqueueSync(
              'INSERT',
              'stock_adjustments',
              adjustment.id,
            );
          }
        }
        resolutionNote = 'Resolved: Shortage of $totalShortage items returned to source location by $_currentUserName.';
      } else if (selectedResolution == 'COURIER_CHARGE') {
        final driverName = courierController.text.trim().isNotEmpty ? courierController.text.trim() : 'Unspecified';
        resolutionNote = 'Resolved: Shortage of $totalShortage items charged to driver/courier ($driverName) by $_currentUserName.';
      } else {
        resolutionNote = 'Resolved: Shortage of $totalShortage items written off as Damage/Loss by $_currentUserName.';
      }

      if (transfer.notes.isNotEmpty) {
        transfer.notes += '\n$resolutionNote';
      } else {
        transfer.notes = resolutionNote;
      }
      transfer.status = 'RESOLVED';

      try {
        await _persistWorkspaceData();
        await _enqueueSync('UPDATE', 'stock_transfers', transfer.id);
      } catch (e, st) {
        // ignore: avoid_print
        print('persistUpdate error: $e\n$st');
      }
    }

    if (_syncService != null) {
      await _syncService!.runWithoutAutoSync(applyResolution);
    } else {
      await applyResolution();
    }
    await _refreshPendingSyncQueue();

    courierController.dispose();
    if (!mounted) return;
    setState(() {});
    Navigator.of(parentContext).pop();
  }

  // ── Dispatch Bill (Lorry Note) PDF & CSV ──────────────────────────────────
  Future<void> _printTransferDispatchBill(_StockTransferItem transfer) async {
    final doc = pw.Document();
    final headers = ['#', 'Product Name', 'Requested Qty', 'Dispatched Qty'];
    final data = <List<String>>[];
    double totalSent = 0.0;
    for (var i = 0; i < transfer.items.length; i++) {
      final line = transfer.items[i];
      totalSent += line.sentQty;
      data.add([
        '${i + 1}',
        line.productName,
        line.requestedQty.toStringAsFixed(line.requestedQty.truncateToDouble() == line.requestedQty ? 0 : 2),
        line.sentQty.toStringAsFixed(line.sentQty.truncateToDouble() == line.sentQty ? 0 : 2),
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STORE BUDDY CLOUD',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.Text(
                    'Inter-Branch Stock Transfer Dispatch Bill (Lorry Note)',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'REF: ${transfer.referenceNo}',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Date: ${_formatDate(transfer.createdAt)}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Status: ${transfer.status}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),

          // Location summary cards
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SOURCE BRANCH (DISPATCH FROM)', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(transfer.fromLocation, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('Dispatched by: ${transfer.createdBy}', style: const pw.TextStyle(fontSize: 9.5)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DESTINATION BRANCH (DELIVER TO)', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(transfer.toLocation, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      if (transfer.reason.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Reason: ${transfer.reason}', style: const pw.TextStyle(fontSize: 9.5)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (transfer.notes.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Transfer Notes: ${transfer.notes}', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
          ],
          pw.SizedBox(height: 16),

          // Dispatched Items Table
          pw.Text('DISPATCHED INVENTORY ITEMS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
            cellStyle: const pw.TextStyle(fontSize: 9.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 8),

          // Summary box
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Dispatched Qty:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('${totalSent.toStringAsFixed(totalSent.truncateToDouble() == totalSent ? 0 : 2)} units', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.indigo900)),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 36),

          // Signatures Area
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Dispatched By (Sender)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  pw.Text(transfer.createdBy, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Driver / Transporter', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  pw.Text('(Vehicle & Signature)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Received By (Destination)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  pw.Text('(Stamp & Signature)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Dispatch_Bill_${transfer.referenceNo}.pdf',
    );
  }

  Future<void> _exportTransferDispatchCsv(_StockTransferItem transfer) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Transfer Dispatch Bill CSV',
        fileName: 'Dispatch_Bill_${transfer.referenceNo}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (outputPath == null) return;

      final csvLines = <String>[];
      csvLines.add('STORE BUDDY CLOUD - STOCK TRANSFER DISPATCH BILL');
      csvLines.add('Transfer Reference,"${transfer.referenceNo}"');
      csvLines.add('Dispatch Date,"${transfer.createdAt.toIso8601String()}"');
      csvLines.add('Source Branch,"${transfer.fromLocation}"');
      csvLines.add('Destination Branch,"${transfer.toLocation}"');
      csvLines.add('Status,"${transfer.status}"');
      csvLines.add('Dispatched By,"${transfer.createdBy}"');
      csvLines.add('Reason,"${transfer.reason.replaceAll('"', '""')}"');
      csvLines.add('Notes,"${transfer.notes.replaceAll('"', '""')}"');
      csvLines.add('');
      csvLines.add('#,Product ID,Product Name,Requested Qty,Sent Qty');

      double totalSent = 0.0;
      for (var i = 0; i < transfer.items.length; i++) {
        final line = transfer.items[i];
        totalSent += line.sentQty;
        final nameEsc = line.productName.replaceAll('"', '""');
        csvLines.add('${i + 1},"${line.productId}","$nameEsc",${line.requestedQty},${line.sentQty}');
      }
      csvLines.add('');
      csvLines.add('TOTAL SENT UNITS,,,$totalSent');

      await File(outputPath).writeAsString(csvLines.join('\n'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispatch Bill CSV exported successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  // ── Goods Received Note (GRN) PDF & CSV ──────────────────────────────────
  Future<void> _printGoodsReceivedNote(_StockTransferItem transfer) async {
    final doc = pw.Document();
    final headers = ['#', 'Product Name', 'Sent Qty', 'Accepted Qty', 'Shortage', 'Discrepancy / Remarks'];
    final data = <List<String>>[];
    double totalSent = 0.0;
    double totalAccepted = 0.0;
    double totalShortage = 0.0;

    for (var i = 0; i < transfer.items.length; i++) {
      final line = transfer.items[i];
      final accepted = line.receivedQty;
      final shortage = line.shortageQty > 0 ? line.shortageQty : (line.sentQty - line.receivedQty).clamp(0.0, 1000000.0);
      totalSent += line.sentQty;
      totalAccepted += accepted;
      totalShortage += shortage;

      data.add([
        '${i + 1}',
        line.productName,
        line.sentQty.toStringAsFixed(line.sentQty.truncateToDouble() == line.sentQty ? 0 : 2),
        accepted.toStringAsFixed(accepted.truncateToDouble() == accepted ? 0 : 2),
        shortage > 0 ? shortage.toStringAsFixed(shortage.truncateToDouble() == shortage ? 0 : 2) : '-',
        line.shortageReason.isNotEmpty ? line.shortageReason : (shortage > 0 ? 'Discrepancy reported' : 'OK / Full Match'),
      ]);
    }

    final hasShortage = totalShortage > 0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STORE BUDDY CLOUD',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                  pw.Text(
                    'GOODS RECEIVED NOTE (GRN) / ACCEPTANCE BILL',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'GRN REF: GRN-${transfer.referenceNo}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Transfer Ref: ${transfer.referenceNo}',
                    style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Receipt Date: ${_formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                  ),
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 4),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: hasShortage ? PdfColors.orange100 : PdfColors.green100,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      hasShortage ? 'PARTIALLY RECEIVED' : 'FULLY RECEIVED',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: hasShortage ? PdfColors.orange900 : PdfColors.green900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),

          // Location summaries
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DISPATCHED FROM (SOURCE)', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(transfer.fromLocation, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('Dispatched: ${_formatDate(transfer.createdAt)}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ACCEPTED AT (DESTINATION)', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(transfer.toLocation, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('Received by: $_currentUserName', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (transfer.notes.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Transfer / Discrepancy Notes: ${transfer.notes}', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
          ],
          pw.SizedBox(height: 16),

          // Items Verification Table
          pw.Text('VERIFIED ITEMS & ACCEPTANCE SUMMARY', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerLeft,
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerLeft,
            },
          ),
          pw.SizedBox(height: 10),

          // Acceptance Summary
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 250,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Dispatched Qty:', style: const pw.TextStyle(fontSize: 9.5)),
                      pw.Text(totalSent.toStringAsFixed(totalSent.truncateToDouble() == totalSent ? 0 : 2), style: const pw.TextStyle(fontSize: 9.5)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Accepted Qty:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                      pw.Text(totalAccepted.toStringAsFixed(totalAccepted.truncateToDouble() == totalAccepted ? 0 : 2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                    ],
                  ),
                  if (hasShortage) ...[
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Shortage / Loss:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                        pw.Text(totalShortage.toStringAsFixed(totalShortage.truncateToDouble() == totalShortage ? 0 : 2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 36),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Received & Verified By', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  pw.Text('$_currentUserName (Store Receiver)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Approved & Authorized By', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  pw.Text('(Branch Manager / Admin)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'GRN_${transfer.referenceNo}.pdf',
    );
  }

  Future<void> _exportGoodsReceivedNoteCsv(_StockTransferItem transfer) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Goods Received Note (GRN) CSV',
        fileName: 'GRN_${transfer.referenceNo}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (outputPath == null) return;

      final csvLines = <String>[];
      csvLines.add('STORE BUDDY CLOUD - GOODS RECEIVED NOTE (GRN)');
      csvLines.add('GRN Reference,"GRN-${transfer.referenceNo}"');
      csvLines.add('Transfer Reference,"${transfer.referenceNo}"');
      csvLines.add('Receipt Date,"${DateTime.now().toIso8601String()}"');
      csvLines.add('Dispatch Date,"${transfer.createdAt.toIso8601String()}"');
      csvLines.add('Source Branch,"${transfer.fromLocation}"');
      csvLines.add('Destination Branch,"${transfer.toLocation}"');
      csvLines.add('Status,"${transfer.status}"');
      csvLines.add('Received By,"$_currentUserName"');
      csvLines.add('Notes,"${transfer.notes.replaceAll('"', '""')}"');
      csvLines.add('');
      csvLines.add('#,Product ID,Product Name,Sent Qty,Accepted Qty,Shortage Qty,Discrepancy Reason');

      double totalSent = 0.0;
      double totalAccepted = 0.0;
      double totalShortage = 0.0;
      for (var i = 0; i < transfer.items.length; i++) {
        final line = transfer.items[i];
        final accepted = line.receivedQty;
        final shortage = line.shortageQty > 0 ? line.shortageQty : (line.sentQty - line.receivedQty).clamp(0.0, 1000000.0);
        totalSent += line.sentQty;
        totalAccepted += accepted;
        totalShortage += shortage;
        final nameEsc = line.productName.replaceAll('"', '""');
        final reasonEsc = line.shortageReason.replaceAll('"', '""');
        csvLines.add('${i + 1},"${line.productId}","$nameEsc",${line.sentQty},$accepted,$shortage,"$reasonEsc"');
      }
      csvLines.add('');
      csvLines.add('TOTALS,,,$totalSent,$totalAccepted,$totalShortage,');

      await File(outputPath).writeAsString(csvLines.join('\n'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GRN CSV exported successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }
}
