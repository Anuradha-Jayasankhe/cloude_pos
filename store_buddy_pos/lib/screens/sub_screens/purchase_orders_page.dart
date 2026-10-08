part of '../dashboard_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _purchase_orders_pageExt on _DashboardScreenState {
  // ─── helpers ────────────────────────────────────────────────────────────────

  Color _poStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return const Color(0xFF64748B);
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'APPROVED':
        return const Color(0xFF2563EB);
      case 'RECEIVED':
        return const Color(0xFF059669);
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _poStatusBg(String status) =>
      _poStatusColor(status).withValues(alpha: 0.12);

  IconData _poStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Icons.edit_note_rounded;
      case 'PENDING':
        return Icons.hourglass_top_rounded;
      case 'APPROVED':
        return Icons.thumb_up_rounded;
      case 'RECEIVED':
        return Icons.inventory_2_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _paymentColor(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return const Color(0xFF059669);
      case 'CARD':
        return const Color(0xFF2563EB);
      case 'CHEQUE':
        return const Color(0xFF7C3AED);
      case 'CREDIT':
        return const Color(0xFFDC2626);
      case 'PARTIAL':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }

  // ─── main page ──────────────────────────────────────────────────────────────

  Widget _buildPurchaseOrdersPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _purchaseOrderSearchController.text.trim().toLowerCase();
    final filtered = _scopedPurchaseOrders.where((po) {
      if (_purchaseOrderStatusFilter != 'All Statuses' &&
          po.status != _purchaseOrderStatusFilter)
        return false;
      if (query.isEmpty) return true;
      return po.id.toLowerCase().contains(query) ||
          po.supplier.toLowerCase().contains(query);
    }).toList();

    // Summary stats
    final totalValue = _scopedPurchaseOrders.fold<double>(
      0,
      (s, po) => s + po.amount,
    );
    final outstanding = _scopedPurchaseOrders.fold<double>(
      0,
      (s, po) => s + po.amountDue,
    );
    final receivedCount = _scopedPurchaseOrders
        .where((po) => po.status == 'RECEIVED')
        .length;

    Future<void> createOrder() async {
      final po = await _showCreatePurchaseOrderDialog();
      if (po == null) return;
      setState(() => _purchaseOrders.insert(0, po));
      await _persistWorkspaceData();
      await _enqueueSync('INSERT', 'purchase_orders', po.id);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header ──────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Purchase Orders',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Manage supplier orders, costs & inventory restocking',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_canManageCatalog)
                ElevatedButton.icon(
                  onPressed: createOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UiRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Create Order',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── stats bar ───────────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 36) / 4;
              final useGrid = cardWidth < 155;

              if (useGrid) {
                return Column(
                  children: [
                    Row(
                      children: [
                        _poStatCard(
                          label: 'Total Orders',
                          value: '${_purchaseOrders.length}',
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFF6366F1),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        _poStatCard(
                          label: 'Total Value',
                          value: _money(totalValue),
                          icon: Icons.attach_money_rounded,
                          color: const Color(0xFF059669),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _poStatCard(
                          label: 'Outstanding Credit',
                          value: _money(outstanding),
                          icon: Icons.account_balance_wallet_rounded,
                          color: outstanding > 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF64748B),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        _poStatCard(
                          label: 'Received',
                          value: '$receivedCount',
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFF059669),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  _poStatCard(
                    label: 'Total Orders',
                    value: '${_purchaseOrders.length}',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _poStatCard(
                    label: 'Total Value',
                    value: _money(totalValue),
                    icon: Icons.attach_money_rounded,
                    color: const Color(0xFF059669),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _poStatCard(
                    label: 'Outstanding Credit',
                    value: _money(outstanding),
                    icon: Icons.account_balance_wallet_rounded,
                    color: outstanding > 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _poStatCard(
                    label: 'Received',
                    value: '$receivedCount',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF059669),
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // ── filters ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(UiRadius.md),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _purchaseOrderSearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by PO number or supplier...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(UiRadius.sm),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _purchaseOrderStatusFilter,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(UiRadius.sm),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'All Statuses',
                        child: Text('All Statuses'),
                      ),
                      DropdownMenuItem(
                        value: 'PENDING',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'APPROVED',
                        child: Text('Approved'),
                      ),
                      DropdownMenuItem(
                        value: 'RECEIVED',
                        child: Text('Received'),
                      ),
                      DropdownMenuItem(
                        value: 'CANCELLED',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _purchaseOrderStatusFilter = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── list ────────────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No purchase orders yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create your first order to start tracking supplier purchases.',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_canManageCatalog)
                          ElevatedButton.icon(
                            onPressed: createOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandIndigo,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create First Order'),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final po = filtered[index];
                      return _buildPOCard(po, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _poStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(UiRadius.md),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: UiShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPOCard(_PurchaseOrderItem po, bool isDark) {
    final statusColor = _poStatusColor(po.status);
    final statusBg = _poStatusBg(po.status);
    final supplier = _suppliers.firstWhere(
      (s) => s.id == po.supplierId,
      orElse: () =>
          _SupplierItem(id: '', name: po.supplier, contact: '', email: ''),
    );

    return InkWell(
      onTap: () => _showPODetailsDialog(po),
      borderRadius: BorderRadius.circular(UiRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(UiRadius.lg),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
          ),
          boxShadow: UiShadows.card,
        ),
        child: Row(
          children: [
            // Status icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _poStatusIcon(po.status),
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        po.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          po.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (po.status == 'RECEIVED')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: po.amountDue > 0
                                ? const Color(
                                    0xFFD97706,
                                  ).withValues(alpha: 0.12)
                                : const Color(
                                    0xFF059669,
                                  ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            po.amountDue > 0
                                ? (po.amountPaid > 0
                                      ? 'PARTIAL'
                                      : 'PENDING PAYMENT')
                                : 'PAID',
                            style: TextStyle(
                              color: po.amountDue > 0
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (po.amountDue > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFDC2626,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'DUE ${_money(po.amountDue)}',
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supplier.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${po.itemsCount} items  •  ${po.expectedDate.isNotEmpty ? po.expectedDate : "No date set"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(po.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (po.amountPaid > 0 && po.amountDue > 0)
                  Text(
                    'Paid ${_money(po.amountPaid)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _paymentColor(
                      po.paymentMethod,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    po.paymentMethod,
                    style: TextStyle(
                      color: _paymentColor(po.paymentMethod),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Create PO Dialog ───────────────────────────────────────────────────────

  Future<_PurchaseOrderItem?> _showCreatePurchaseOrderDialog({
    _PurchaseOrderItem? existing,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchCtrl = TextEditingController();
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final expectedDateCtrl = TextEditingController(
      text: existing?.expectedDate ?? '',
    );

    // Pick supplier
    String? selectedSupplierId = existing?.supplierId.isNotEmpty == true
        ? existing!.supplierId
        : (_suppliers.isNotEmpty ? _suppliers.first.id : null);

    // Pick target branch / location safely
    final rawAvailable = _availableLocationNames.isNotEmpty
        ? _availableLocationNames
        : <String>[_activeLocationForWrites];

    final initialLoc = existing?.locationId.isNotEmpty == true
        ? existing!.locationId
        : (_selectedLocationScope != _DashboardScreenState._allLocationsLabel
              ? _selectedLocationScope
              : rawAvailable.first);

    final matchedLoc = rawAvailable.firstWhere(
      (loc) => loc.trim().toLowerCase() == initialLoc.trim().toLowerCase(),
      orElse: () => initialLoc,
    );

    String selectedLocation = matchedLoc;

    // Cart lines — copy from existing or start fresh
    final lines = <_PurchaseOrderLine>[
      if (existing != null)
        for (final l in existing.items)
          _PurchaseOrderLine(
            productId: l.productId,
            productName: l.productName,
            qty: l.qty,
            costPrice: l.costPrice,
            sellingPrice: l.sellingPrice,
          ),
    ];

    String searchQuery = '';

    return showGeneralDialog<_PurchaseOrderItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CreatePO',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, animation, _) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            // Deduplicate & validate location options for DropdownButtonFormField
            final locationItems = <String>{
              ..._availableLocationNames,
              if (selectedLocation.isNotEmpty) selectedLocation,
            }.toList();

            final currentLocValue = locationItems.contains(selectedLocation)
                ? selectedLocation
                : (locationItems.isNotEmpty ? locationItems.first : null);

            // Deduplicate & validate supplier options for DropdownButtonFormField
            final supplierMap = <String, String>{};
            for (final s in _suppliers) {
              supplierMap.putIfAbsent(s.id, () => s.name);
            }
            final validSupplierId =
                (selectedSupplierId != null &&
                        supplierMap.containsKey(selectedSupplierId))
                    ? selectedSupplierId
                    : (supplierMap.isNotEmpty ? supplierMap.keys.first : null);

            final supplier = validSupplierId != null
                ? _suppliers.firstWhere(
                    (s) => s.id == validSupplierId,
                    orElse: () => _suppliers.isNotEmpty
                        ? _suppliers.first
                        : _SupplierItem(
                            id: '',
                            name: '',
                            contact: '',
                            email: '',
                          ),
                  )
                : null;

            final sourceProducts = _products.where((p) {
              final q = searchQuery.trim().toLowerCase();
              if (q.isEmpty) return true;
              return p.name.toLowerCase().contains(q) ||
                  p.barcode.toLowerCase().contains(q);
            }).toList();

            final totalCost = lines.fold<double>(0, (s, l) => s + l.lineTotal);

            return _SideSheetContainer(
              title: existing == null
                  ? 'Create Purchase Order'
                  : 'Edit Order ${existing.id}',
              width: 780,
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${_money(totalCost)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(UiRadius.md),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed:
                            (lines.isEmpty ||
                                validSupplierId == null ||
                                validSupplierId.isEmpty)
                            ? null
                            : () {
                                final sup = _suppliers.firstWhere(
                                  (s) => s.id == validSupplierId,
                                  orElse: () => _SupplierItem(
                                    id: validSupplierId,
                                    name: 'General Supplier',
                                    contact: '',
                                    email: '',
                                  ),
                                );
                                final now = DateTime.now().toUtc();
                                final po = _PurchaseOrderItem(
                                  id:
                                      existing?.id ??
                                      'PO-${now.millisecondsSinceEpoch}',
                                  supplier: sup.name,
                                  supplierId: sup.id,
                                  locationId: currentLocValue ?? selectedLocation,
                                  status: existing?.status ?? 'PENDING',
                                  expectedDate: expectedDateCtrl.text.trim(),
                                  notes: notesCtrl.text.trim(),
                                  items: List.from(lines),
                                  paymentMethod:
                                      existing?.paymentMethod ?? 'CASH',
                                  amountPaid: existing?.amountPaid ?? 0,
                                  amountDue: existing?.amountDue ?? 0,
                                  createdAt:
                                      existing?.createdAt ??
                                      now.toIso8601String(),
                                  updatedAt: now.toIso8601String(),
                                );
                                Navigator.pop(ctx, po);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandIndigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(UiRadius.md),
                          ),
                        ),
                        child: Text(
                          existing == null ? 'Create Order' : 'Save Changes',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Supplier & Date ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: validSupplierId,
                            decoration: const InputDecoration(
                              labelText: 'Supplier *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_shipping_outlined),
                            ),
                            items: supplierMap.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setLocal(() => selectedSupplierId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Add New Supplier',
                          child: IconButton.outlined(
                            onPressed: () async {
                              final newSupplier = await _showSupplierDialog();
                              if (newSupplier != null) {
                                setState(() {
                                  _suppliers.removeWhere(
                                    (s) => s.id == newSupplier.id,
                                  );
                                  _suppliers.insert(0, newSupplier);
                                });
                                await _persistWorkspaceData();
                                await _enqueueSync(
                                  'INSERT',
                                  'suppliers',
                                  newSupplier.id,
                                );
                                setLocal(() {
                                  selectedSupplierId = newSupplier.id;
                                });
                              }
                            },
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: expectedDateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Expected Delivery Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                              hintText: 'e.g. 2024-12-31',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: currentLocValue,
                      decoration: const InputDecoration(
                        labelText: 'Target Branch / Location *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: locationItems
                          .map(
                            (loc) =>
                                DropdownMenuItem(value: loc, child: Text(loc)),
                          )
                          .toList(),
                      onChanged:
                          (_isOwner || _isAdmin) &&
                              (_selectedLocationScope ==
                                  _DashboardScreenState._allLocationsLabel)
                          ? (v) {
                              if (v != null) {
                                setLocal(() => selectedLocation = v);
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes_rounded),
                        hintText: 'Optional order notes...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // ── Product Search ─────────────────────────────────────
                    // ── Product Search & Quick Pick ───────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Products',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await _showProductDialog(
                              initialSupplierId: selectedSupplierId,
                              name: searchQuery.trim().isNotEmpty
                                  ? searchQuery.trim()
                                  : null,
                              initialLocationId: selectedLocation,
                            );
                            if (result != null && mounted) {
                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );
                              if (!mounted) return;
                              await _handleProductCreation(result);
                              final newProd = result.product;
                              setLocal(() {
                                final idx = lines.indexWhere(
                                  (l) => l.productId == newProd.id,
                                );
                                if (idx >= 0) {
                                  lines[idx].qty++;
                                } else {
                                  lines.add(
                                    _PurchaseOrderLine(
                                      productId: newProd.id,
                                      productName: newProd.name,
                                      qty: 1,
                                      costPrice:
                                          newProd.costPrice ??
                                          newProd.price,
                                      sellingPrice: newProd.price,
                                    ),
                                  );
                                }
                                searchQuery = '';
                                searchCtrl.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text(
                            'Add Manually / New Product',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtrl,
                      onChanged: (v) => setLocal(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search product name or barcode...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setLocal(() => searchQuery = '');
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Products List Container (Filtered or Shop Inventory)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: UiShadows.card,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          if (searchQuery.trim().isNotEmpty) ...[
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.add_circle_rounded,
                                color: AppTheme.brandIndigo,
                              ),
                              title: Text(
                                'Create & Add Product: "${searchQuery.trim()}"',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.brandIndigo,
                                ),
                              ),
                              subtitle: const Text(
                                'Add this product to inventory and insert into order',
                                style: TextStyle(fontSize: 11),
                              ),
                              onTap: () async {
                                final result = await _showProductDialog(
                                  initialSupplierId: selectedSupplierId,
                                  name: searchQuery.trim(),
                                  initialLocationId: selectedLocation,
                                );
                                if (result != null && mounted) {
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );
                                  if (!mounted) return;
                                  await _handleProductCreation(result);
                                  final newProd = result.product;
                                  setLocal(() {
                                    final idx = lines.indexWhere(
                                      (l) => l.productId == newProd.id,
                                    );
                                    if (idx >= 0) {
                                      lines[idx].qty++;
                                    } else {
                                      lines.add(
                                        _PurchaseOrderLine(
                                          productId: newProd.id,
                                          productName: newProd.name,
                                          qty: 1,
                                          costPrice:
                                              newProd.costPrice ??
                                              newProd.price,
                                          sellingPrice: newProd.price,
                                        ),
                                      );
                                    }
                                    searchQuery = '';
                                    searchCtrl.clear();
                                  });
                                }
                              },
                            ),
                            const Divider(height: 1, thickness: 1),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Shop Catalogue Products (${sourceProducts.length})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Tap any item to add',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, thickness: 1),
                          ],
                          if (sourceProducts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  searchQuery.trim().isEmpty
                                      ? 'No products found in shop catalogue. Tap "Add Manually" above.'
                                      : 'No matching products found. Tap "Create & Add Product" above.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          else
                            ...sourceProducts.take(50).map((product) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                                subtitle: Text(
                                  'Stock: ${product.stock}  •  Cost: ${_money(product.costPrice ?? product.price)}  •  Sell: ${_money(product.price)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: AppTheme.brandIndigo,
                                ),
                                onTap: () {
                                  setLocal(() {
                                    final idx = lines.indexWhere(
                                      (l) => l.productId == product.id,
                                    );
                                    if (idx >= 0) {
                                      lines[idx].qty++;
                                    } else {
                                      lines.add(
                                        _PurchaseOrderLine(
                                          productId: product.id,
                                          productName: product.name,
                                          qty: 1,
                                          costPrice:
                                              product.costPrice ??
                                              product.price,
                                          sellingPrice: product.price,
                                        ),
                                      );
                                    }
                                  });
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Cart Lines ─────────────────────────────────────────
                    if (lines.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Search and add products above.',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 740,
                          child: Column(
                            children: [
                              // Header row
                              Container(
                                decoration: BoxDecoration(
                                  color: _tableHeaderColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Product',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 96,
                                      child: Text(
                                        'Qty',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        'Cost Price',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        'Sell Price',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        'Total',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 36),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              ...lines.asMap().entries.map((entry) {
                                final i = entry.key;
                                final line = entry.value;
                                return _POLineEditorRow(
                                  line: line,
                                  isDark: isDark,
                                  moneyFormatter: _money,
                                  onChanged: () => setLocal(() {}),
                                  onRemove: () => setLocal(() => lines.removeAt(i)),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── PO Details / Receive Dialog ────────────────────────────────────────────

  Future<void> _showPODetailsDialog(_PurchaseOrderItem po) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PODetails',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) {
        // Build map of item mappings keyed by line object
        final mappings = <_PurchaseOrderLine, _LineMappingState>{};
        final searchQueries = <_PurchaseOrderLine, String>{};

        for (final line in po.items) {
          final exists = _products.any((p) => p.id == line.productId);
          final defaultSku =
              'SKU-${DateTime.now().millisecondsSinceEpoch}-${mappings.length + 1}';
          final defaultCat = _productCategories.isNotEmpty
              ? _productCategories.first
              : 'General';
          mappings[line] = _LineMappingState(
            mappingType: exists ? 'SAME' : 'NEW',
            linkedProduct: exists
                ? _products.firstWhere((p) => p.id == line.productId)
                : null,
            newProductName: line.productName,
            newProductSku: defaultSku,
            newProductCost: line.costPrice,
            newProductSell: line.sellingPrice,
            newProductCategory: defaultCat,
            updateCatalogPrices: true,
          );
          searchQueries[line] = '';
        }

        final customCatControllers =
            <_PurchaseOrderLine, TextEditingController>{};
        for (final line in po.items) {
          customCatControllers[line] = TextEditingController();
        }

        String selectedPaymentMethod = po.paymentMethod == 'CREDIT'
            ? 'CREDIT'
            : 'CASH';
        double partialAmount = po.amountPaid > 0 ? po.amountPaid : po.amount;
        final partialCtrl = TextEditingController(
          text: partialAmount.toStringAsFixed(2),
        );
        final paymentDueDateCtrl = TextEditingController(
          text: po.paymentDueDate ?? '',
        );
        final chequeNumberCtrl = TextEditingController();

        // Extra details for partial portion
        String partialPaidPortionMethod = 'CASH';
        final partialChequeNumberCtrl = TextEditingController();

        bool showReceivePanel = false;
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final canEdit = po.status == 'PENDING' || po.status == 'DRAFT';
            final canReceive =
                po.status == 'PENDING' || po.status == 'APPROVED';

            Future<void> doReceive() async {
              if (po.status == 'RECEIVED' || isProcessing) return;

              // 1. Validation
              for (final entry in mappings.entries) {
                final m = entry.value;
                if (m.mappingType == 'LINK' && m.linkedProduct == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select a matched product for all linked lines.',
                      ),
                    ),
                  );
                  return;
                }
                if (m.mappingType == 'NEW') {
                  if (m.newProductName.trim().isEmpty ||
                      m.newProductSku.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter name and SKU for all new products.',
                        ),
                      ),
                    );
                    return;
                  }
                }
              }

              setLocal(() => isProcessing = true);

              try {
                double paid = 0;
                double due = 0;
                String noteText = '';

                if (selectedPaymentMethod == 'CASH') {
                  paid = po.amount;
                  due = 0;
                  noteText = 'Paid via Cash';
                } else if (selectedPaymentMethod == 'CARD') {
                  paid = po.amount;
                  due = 0;
                  noteText = 'Paid via Card';
                } else if (selectedPaymentMethod == 'CHEQUE') {
                  paid = po.amount;
                  due = 0;
                  noteText = 'Paid via Cheque #${chequeNumberCtrl.text.trim()}';
                } else if (selectedPaymentMethod == 'CREDIT') {
                  paid = 0;
                  due = po.amount;
                  noteText = 'Outstanding Balance';
                } else if (selectedPaymentMethod == 'INSTALLMENT' ||
                    selectedPaymentMethod == 'PARTIAL') {
                  // Partial or Installment
                  paid = double.tryParse(partialCtrl.text) ?? 0;
                  if (paid > po.amount) paid = po.amount;
                  due = po.amount - paid;
                  if (due < 0) due = 0;

                  final methodName =
                      selectedPaymentMethod == 'INSTALLMENT'
                          ? 'Installment'
                          : 'Partial';
                  if (partialPaidPortionMethod == 'CHEQUE') {
                    noteText =
                        '$methodName Payment: Paid ${_money(paid)} via Cheque #${partialChequeNumberCtrl.text.trim()}, remainder ${_money(due)} on Credit';
                  } else {
                    noteText =
                        '$methodName Payment: Paid ${_money(paid)} via $partialPaidPortionMethod, remainder ${_money(due)} on Credit';
                  }
                } else {
                  paid = po.amount;
                  due = 0;
                  noteText = 'Paid via $selectedPaymentMethod';
                }

                final targetLocation = po.locationId.trim().isEmpty
                    ? _activeLocationForWrites
                    : po.locationId.trim();

                final repoUpdates = <Future<void> Function()>[];
                final syncQueueOperations = <Future<void> Function()>[];

                // 2. Perform Inventory Updates In Memory
                final liveIdx = _purchaseOrders.indexWhere(
                  (p) => p.id == po.id,
                );
                final nowUtc = DateTime.now().toUtc().toIso8601String();
                final nowLocal = DateTime.now();

                if (liveIdx >= 0) {
                  final livePo = _purchaseOrders[liveIdx];
                  livePo.status = 'RECEIVED';
                  livePo.paymentMethod = selectedPaymentMethod;
                  livePo.amountPaid = paid;
                  livePo.amountDue = due;
                  livePo.receivedAt = nowLocal;
                  livePo.updatedAt = nowUtc;
                  if (paymentDueDateCtrl.text.isNotEmpty) {
                    livePo.paymentDueDate = paymentDueDateCtrl.text;
                  }
                  // Sync dialog's local reference
                  po.status = 'RECEIVED';
                  po.paymentMethod = selectedPaymentMethod;
                  po.amountPaid = paid;
                  po.amountDue = due;
                  po.receivedAt = livePo.receivedAt;
                  po.updatedAt = livePo.updatedAt;
                  po.paymentDueDate = livePo.paymentDueDate;
                } else {
                  po.status = 'RECEIVED';
                  po.paymentMethod = selectedPaymentMethod;
                  po.amountPaid = paid;
                  po.amountDue = due;
                  po.receivedAt = nowLocal;
                  po.updatedAt = nowUtc;
                  if (paymentDueDateCtrl.text.isNotEmpty) {
                    po.paymentDueDate = paymentDueDateCtrl.text;
                  }
                }

                // Process item by item mapping without premature mid-loop rebuilds
                for (final line in po.items) {
                  final mapping = mappings[line];
                  if (mapping == null) continue;

                  if (mapping.mappingType == 'SAME' ||
                      mapping.mappingType == 'LINK') {
                    final targetProd = mapping.linkedProduct;
                    final idx = targetProd == null
                        ? -1
                        : _products.indexWhere(
                            (p) =>
                                p.locationId == targetLocation &&
                                ((p.barcode.isNotEmpty &&
                                        targetProd.barcode.isNotEmpty &&
                                        p.barcode.trim().toLowerCase() ==
                                            targetProd.barcode
                                                .trim()
                                                .toLowerCase()) ||
                                    (p.name.trim().toLowerCase() ==
                                        targetProd.name.trim().toLowerCase())),
                          );

                    if (idx >= 0) {
                      final beforeStock = _products[idx].stock;
                      _products[idx].stock += line.qty;
                      if (mapping.updateCatalogPrices) {
                        _products[idx].costPrice = line.costPrice;
                        _products[idx].price = line.sellingPrice;
                      }
                      line.productId = _products[idx].id;
                      final afterStock = _products[idx].stock;
                      final updatedProduct = _products[idx];

                      final audit = _StockAdjustmentItem(
                        id: 'SA${DateTime.now().microsecondsSinceEpoch}_${po.items.indexOf(line)}',
                        productId: updatedProduct.id,
                        productName: updatedProduct.name,
                        delta: line.qty,
                        beforeStock: beforeStock,
                        afterStock: afterStock,
                        reason: 'PO Received — ${po.id}',
                        performedBy: _currentUserName,
                        unitCost: line.costPrice,
                        adjustedStockValue: afterStock * line.costPrice,
                        createdAt: DateTime.now(),
                      );
                      _stockAdjustments.insert(0, audit);

                      syncQueueOperations.add(
                        () => _enqueueSync(
                          'INSERT',
                          'stock_adjustments',
                          audit.id,
                        ),
                      );

                      if (_productRepository != null) {
                        repoUpdates.add(
                          () => _productRepository!.updateProduct(
                            _toDomainProduct(updatedProduct),
                          ),
                        );
                      }
                      syncQueueOperations.add(
                        () => _enqueueSync(
                          'UPDATE',
                          'products',
                          updatedProduct.id,
                        ),
                      );
                    } else if (targetProd != null) {
                      // Clone targetProd to targetLocation
                      final newProdId =
                          'PROD-CLONE-${DateTime.now().millisecondsSinceEpoch}-${_products.length}-${po.items.indexOf(line)}';
                      final newProduct = _ProductItem(
                        id: newProdId,
                        name: targetProd.name,
                        barcode: targetProd.barcode,
                        category: targetProd.category,
                        price: mapping.updateCatalogPrices
                            ? line.sellingPrice
                            : targetProd.price,
                        costPrice: mapping.updateCatalogPrices
                            ? line.costPrice
                            : targetProd.costPrice,
                        stock: line.qty,
                        minStock: targetProd.minStock,
                        locationId: targetLocation,
                        supplierId: po.supplierId.isNotEmpty
                            ? po.supplierId
                            : targetProd.supplierId,
                        measureUnit: targetProd.measureUnit,
                        productType: targetProd.productType,
                        description: targetProd.description,
                        warrantyMonths: targetProd.warrantyMonths,
                        expiryDate: targetProd.expiryDate,
                        expiryReminderMode: targetProd.expiryReminderMode,
                        expiryReminderDays: targetProd.expiryReminderDays,
                        attributeValues: Map.from(targetProd.attributeValues),
                      );

                      _products.add(newProduct);
                      line.productId = newProdId;

                      final audit = _StockAdjustmentItem(
                        id: 'SA${DateTime.now().microsecondsSinceEpoch}_${po.items.indexOf(line)}',
                        productId: newProdId,
                        productName: newProduct.name,
                        delta: line.qty,
                        beforeStock: 0,
                        afterStock: line.qty,
                        reason: 'PO Received — ${po.id}',
                        performedBy: _currentUserName,
                        unitCost: newProduct.costPrice ?? line.costPrice,
                        adjustedStockValue:
                            line.qty * (newProduct.costPrice ?? line.costPrice),
                        createdAt: DateTime.now(),
                      );
                      _stockAdjustments.insert(0, audit);

                      syncQueueOperations.add(
                        () => _enqueueSync(
                          'INSERT',
                          'stock_adjustments',
                          audit.id,
                        ),
                      );

                      if (_productRepository != null) {
                        repoUpdates.add(
                          () => _productRepository!.insertProduct(
                            _toDomainProduct(newProduct),
                          ),
                        );
                      }
                      syncQueueOperations.add(
                        () => _enqueueSync('INSERT', 'products', newProdId),
                      );
                    }
                  } else {
                    // Create New Product
                    final customCat =
                        customCatControllers[line]?.text.trim() ?? '';
                    final chosenCategory = customCat.isNotEmpty
                        ? customCat
                        : mapping.newProductCategory;

                    if (!_productCategories.any(
                      (c) => c.toLowerCase() == chosenCategory.toLowerCase(),
                    )) {
                      _productCategories.add(chosenCategory);
                    }

                    final newProdId =
                        'PROD-PO-${DateTime.now().millisecondsSinceEpoch}-${mappings.values.toList().indexOf(mapping)}';
                    final newProduct = _ProductItem(
                      id: newProdId,
                      name: mapping.newProductName.trim(),
                      barcode: mapping.newProductSku.trim(),
                      category: chosenCategory,
                      price: mapping.newProductSell,
                      costPrice: mapping.newProductCost,
                      stock: line.qty,
                      minStock: 0,
                      locationId: targetLocation,
                      supplierId: po.supplierId,
                    );

                    _products.add(newProduct);
                    line.productName = mapping.newProductName.trim();
                    line.productId = newProdId;

                    final audit = _StockAdjustmentItem(
                      id: 'SA${DateTime.now().microsecondsSinceEpoch}_${po.items.indexOf(line)}',
                      productId: newProdId,
                      productName: mapping.newProductName.trim(),
                      delta: line.qty,
                      beforeStock: 0,
                      afterStock: line.qty,
                      reason: 'PO Received — ${po.id}',
                      performedBy: _currentUserName,
                      unitCost: mapping.newProductCost,
                      adjustedStockValue: line.qty * mapping.newProductCost,
                      createdAt: DateTime.now(),
                    );
                    _stockAdjustments.insert(0, audit);

                    syncQueueOperations.add(
                      () =>
                          _enqueueSync('INSERT', 'stock_adjustments', audit.id),
                    );

                    if (_productRepository != null) {
                      repoUpdates.add(
                        () => _productRepository!.insertProduct(
                          _toDomainProduct(newProduct),
                        ),
                      );
                    }
                    syncQueueOperations.add(
                      () => _enqueueSync('INSERT', 'products', newProdId),
                    );
                  }
                }

                setState(() {});

                // 3. Create expense record for paid amount
                String? createdExpenseId;
                String? createdBankTxId;
                if (paid > 0 && _appDatabase != null) {
                  final expenseId =
                      'EXP-PO-${DateTime.now().millisecondsSinceEpoch}';
                  createdExpenseId = expenseId;
                  final sup = _suppliers.firstWhere(
                    (s) => s.id == po.supplierId,
                    orElse: () => _SupplierItem(
                      id: '',
                      name: po.supplier,
                      contact: '',
                      email: '',
                    ),
                  );
                  await _appDatabase!.insertExpense(
                    db.ExpensesCompanion(
                      id: Value(expenseId),
                      tenantId: Value(_appDatabase?.tenantId ?? ''),
                      category: const Value('STOCK_PURCHASE'),
                      description: Value(
                        'Stock Purchase — ${po.id} (${sup.name})',
                      ),
                      amount: Value(paid),
                      locationId: Value(targetLocation),
                      notes: Value('PO ${po.id} — $noteText'),
                      expenseDate: Value(DateTime.now()),
                      createdAt: Value(DateTime.now()),
                    ),
                  );

                  // Deduct from bank ledger
                  final bankTxId = 'TX-BANK-${DateTime.now().millisecondsSinceEpoch}';
                  createdBankTxId = bankTxId;
                  _bankAccountBalance -= paid;
                  _bankTransactions.insert(
                    0,
                    _BankTransaction(
                      id: bankTxId,
                      type: 'PO_PAYMENT',
                      amount: paid,
                      referenceId: po.id,
                      notes: 'PO stock purchase: ${po.id} (${sup.name})',
                      createdAt: DateTime.now(),
                    ),
                  );
                }

                // 4. Persist to SharedPreferences FIRST before any DB or sync operations run
                await _persistWorkspaceData();

                // 5. Update SQLite Database for products
                for (final update in repoUpdates) {
                  await update();
                }

                // 6. Enqueue sync operations
                for (final syncOp in syncQueueOperations) {
                  await syncOp();
                }

                // 7. Enqueue Purchase Order update sync
                await _enqueueSync('UPDATE', 'purchase_orders', po.id);
                if (createdExpenseId != null) {
                  await _enqueueSync('INSERT', 'expenses', createdExpenseId);
                }
                if (createdBankTxId != null) {
                  await _enqueueSync('INSERT', 'bank_transactions', createdBankTxId);
                }

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Order received! Inventory updated. ${due > 0 ? "Outstanding balance: ${_money(due)}" : "Fully paid."}',
                    ),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to receive order: $e')),
                  );
                }
              } finally {
                setLocal(() => isProcessing = false);
              }
            }

            return _SideSheetContainer(
              title: 'Purchase Order — ${po.id}',
              width: 760,
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canEdit)
                    OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              final updated =
                                  await _showCreatePurchaseOrderDialog(
                                    existing: po,
                                  );
                              if (updated == null) return;
                              setState(() {
                                final idx = _purchaseOrders.indexWhere(
                                  (p) => p.id == po.id,
                                );
                                if (idx >= 0) _purchaseOrders[idx] = updated;
                              });
                              await _persistWorkspaceData();
                              await _enqueueSync(
                                'UPDATE',
                                'purchase_orders',
                                po.id,
                              );
                            },
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Order'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                    ),
                  if (po.status == 'RECEIVED' && po.amountDue > 0) ...[
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              await _showPayNowDialog(po);
                              setLocal(() {});
                            },
                      icon: const Icon(Icons.payment_rounded, size: 16),
                      label: Text('Pay Now (${_money(po.amountDue)})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                    ),
                  ],
                  if (canReceive && !showReceivePanel) ...[
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => setLocal(() => showReceivePanel = true),
                      icon: const Icon(Icons.inventory_2_rounded, size: 16),
                      label: const Text('Receive Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── PO Info Card ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
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
                                  const Text(
                                    'SUPPLIER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    po.supplier,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _poStatusBg(po.status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      po.status,
                                      style: TextStyle(
                                        color: _poStatusColor(po.status),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (po.status == 'RECEIVED') ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: po.amountDue > 0
                                            ? const Color(
                                                0xFFD97706,
                                              ).withValues(alpha: 0.12)
                                            : const Color(
                                                0xFF059669,
                                              ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        po.amountDue > 0
                                            ? (po.amountPaid > 0
                                                  ? 'PARTIAL PAYMENT'
                                                  : 'PENDING PAYMENT')
                                            : 'PAYMENT COMPLETED',
                                        style: TextStyle(
                                          color: po.amountDue > 0
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF059669),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              _poInfoCell('Total Amount', _money(po.amount)),
                              _poInfoCell('Payment Method', po.paymentMethod),
                              _poInfoCell('Paid', _money(po.amountPaid)),
                              _poInfoCell('Due', _money(po.amountDue)),
                            ],
                          ),
                          if (po.expectedDate.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Expected: ${po.expectedDate}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                          if (po.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Notes: ${po.notes}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Receive Mapping & Items Table ──────────────────────────
                    if (showReceivePanel) ...[
                      const Text(
                        'Inventory Mapping Configuration',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Specify how each purchased item matches your stock database. Set different items or create new entries when costs fluctuate to prevent margin issues.',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...po.items.map((line) {
                        final mapping = mappings[line] ??
                            _LineMappingState(
                              mappingType: 'NEW',
                              newProductName: line.productName,
                              newProductSku:
                                  'SKU-${DateTime.now().millisecondsSinceEpoch}',
                              newProductCost: line.costPrice,
                              newProductSell: line.sellingPrice,
                              newProductCategory: _productCategories.isNotEmpty
                                  ? _productCategories.first
                                  : 'General',
                              updateCatalogPrices: true,
                            );
                        final lineQuery = searchQueries[line] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E2D45)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Line Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      line.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _money(line.lineTotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Purchased Qty: ${line.qty}  •  Cost: ${_money(line.costPrice)}  •  Sell: ${_money(line.sellingPrice)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey,
                                ),
                              ),
                              const Divider(height: 16),

                              // Segmented Mapping Choice
                              Row(
                                children: [
                                  _mappingOptionBtn(
                                    label: '📥 Same Product',
                                    active: mapping.mappingType == 'SAME',
                                    onTap: () {
                                      // Only allow Same Product if we actually have a linked product
                                      if (mapping.linkedProduct != null) {
                                        setLocal(
                                          () => mapping.mappingType = 'SAME',
                                        );
                                      } else {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No original product found. Use "Match Different" to link one.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _mappingOptionBtn(
                                    label: '🔍 Match Different',
                                    active: mapping.mappingType == 'LINK',
                                    onTap: () {
                                      setLocal(
                                        () => mapping.mappingType = 'LINK',
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _mappingOptionBtn(
                                    label: '🆕 Create New',
                                    active: mapping.mappingType == 'NEW',
                                    onTap: () {
                                      setLocal(
                                        () => mapping.mappingType = 'NEW',
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Detail Panels depending on selection
                              if (mapping.mappingType == 'SAME') ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Linked Product: ${mapping.linkedProduct?.name ?? ""}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Current Catalog Cost: ${_money(mapping.linkedProduct?.costPrice ?? 0.0)}  •  Current Catalog Sell: ${_money(mapping.linkedProduct?.price ?? 0.0)}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value:
                                                  mapping.updateCatalogPrices,
                                              onChanged: (v) {
                                                setLocal(
                                                  () =>
                                                      mapping.updateCatalogPrices =
                                                          v ?? true,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Update catalog prices to PO prices (recommended)',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (mapping.mappingType == 'LINK') ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (mapping.linkedProduct != null) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Linked Match: ${mapping.linkedProduct?.name ?? ""}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setLocal(
                                                  () => mapping.linkedProduct =
                                                      null,
                                                );
                                              },
                                              child: const Text('Change'),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Current Catalog Cost: ${_money(mapping.linkedProduct?.costPrice ?? 0.0)}  •  Current Catalog Sell: ${_money(mapping.linkedProduct?.price ?? 0.0)}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Checkbox(
                                                value:
                                                    mapping.updateCatalogPrices,
                                                onChanged: (v) {
                                                  setLocal(
                                                    () =>
                                                        mapping.updateCatalogPrices =
                                                            v ?? true,
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Update catalog prices to PO prices',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        TextField(
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Search inventory product to link...',
                                            prefixIcon: Icon(
                                              Icons.search,
                                              size: 16,
                                            ),
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) {
                                            setLocal(() {
                                              searchQueries[line] = val;
                                            });
                                          },
                                        ),
                                        if (lineQuery.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            constraints: const BoxConstraints(
                                              maxHeight: 140,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.grey.shade50,
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: ListView(
                                              shrinkWrap: true,
                                              padding: EdgeInsets.zero,
                                              children: _products
                                                  .where((p) {
                                                    if (_activeLocationForWrites
                                                            .isNotEmpty &&
                                                        p
                                                            .locationId
                                                            .isNotEmpty &&
                                                        p.locationId !=
                                                            _activeLocationForWrites)
                                                      return false;
                                                    return p.name
                                                            .toLowerCase()
                                                            .contains(
                                                              lineQuery
                                                                  .toLowerCase(),
                                                            ) ||
                                                        p.barcode
                                                            .toLowerCase()
                                                            .contains(
                                                              lineQuery
                                                                  .toLowerCase(),
                                                            );
                                                  })
                                                  .take(5)
                                                  .map((match) {
                                                    return ListTile(
                                                      dense: true,
                                                      title: Text(match.name),
                                                      subtitle: Text(
                                                        'SKU: ${match.barcode}  •  Stock: ${match.stock}',
                                                      ),
                                                      onTap: () {
                                                        setLocal(() {
                                                          mapping
                                                                  .linkedProduct =
                                                              match;
                                                          mapping.mappingType =
                                                              'SAME';
                                                          searchQueries[line] =
                                                              '';
                                                        });
                                                      },
                                                    );
                                                  })
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                              ] else if (mapping.mappingType == 'NEW') ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Create Brand New Catalog Product Entry',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppTheme.brandIndigo,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue:
                                                  mapping.newProductName,
                                              decoration: const InputDecoration(
                                                labelText: 'Product Name',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (val) {
                                                mapping.newProductName = val;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue:
                                                  mapping.newProductSku,
                                              decoration: const InputDecoration(
                                                labelText: 'SKU / Barcode',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (val) {
                                                mapping.newProductSku = val;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              value:
                                                  _productCategories.contains(
                                                    mapping.newProductCategory,
                                                  )
                                                  ? mapping.newProductCategory
                                                  : (_productCategories
                                                            .isNotEmpty
                                                        ? _productCategories
                                                              .first
                                                        : 'General'),
                                              decoration: const InputDecoration(
                                                labelText: 'Select Category',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              items:
                                                  (_productCategories.isEmpty
                                                          ? ['General']
                                                          : _productCategories)
                                                      .map(
                                                        (cat) =>
                                                            DropdownMenuItem(
                                                              value: cat,
                                                              child: Text(cat),
                                                            ),
                                                      )
                                                      .toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setLocal(() {
                                                    mapping.newProductCategory =
                                                        val;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  customCatControllers[line],
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Or Custom Category Name',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: mapping
                                                  .newProductCost
                                                  .toStringAsFixed(2),
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Cost Price',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (val) {
                                                mapping.newProductCost =
                                                    double.tryParse(val) ?? 0.0;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: mapping
                                                  .newProductSell
                                                  .toStringAsFixed(2),
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Selling Price',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (val) {
                                                mapping.newProductSell =
                                                    double.tryParse(val) ?? 0.0;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),

                      const Divider(height: 32),

                      // ── Receive Payments Section ─────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.brandIndigo.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.brandIndigo.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Confirm Receipt & Payments',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  [
                                    'CASH',
                                    'CARD',
                                    'CHEQUE',
                                    'CREDIT',
                                    'PARTIAL',
                                    'INSTALLMENT',
                                  ].map<Widget>((method) {
                                    final isSelected =
                                        selectedPaymentMethod == method;
                                    return ChoiceChip(
                                      label: Text(method),
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setLocal(() {
                                            selectedPaymentMethod = method;
                                          });
                                        }
                                      },
                                      selectedColor: AppTheme.brandIndigo,
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // Conditional payment inputs
                            if (selectedPaymentMethod == 'CHEQUE') ...[
                              TextField(
                                controller: chequeNumberCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Cheque Number *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.confirmation_number_outlined,
                                  ),
                                ),
                              ),
                            ] else if (selectedPaymentMethod == 'CREDIT') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: paymentDueDateCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Payment Due Date',
                                        border: OutlineInputBorder(),
                                        hintText: 'YYYY-MM-DD',
                                        prefixIcon: Icon(
                                          Icons.calendar_today_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.calendar_month_rounded,
                                    ),
                                    onPressed: () async {
                                      final date = await showDatePicker(
                                        context: ctx,
                                        initialDate: DateTime.now().add(
                                          const Duration(days: 30),
                                        ),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                      );
                                      if (date != null) {
                                        setLocal(() {
                                          paymentDueDateCtrl.text = date
                                              .toIso8601String()
                                              .split('T')
                                              .first;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Full amount ${_money(po.amount)} will be tracked as Accounts Payable.',
                                style: const TextStyle(
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ] else if (selectedPaymentMethod == 'PARTIAL' ||
                                selectedPaymentMethod == 'INSTALLMENT') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: partialCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText:
                                            'Paid Amount (Total: ${_money(po.amount)})',
                                        border: const OutlineInputBorder(),
                                        prefixText:
                                            '${_currency == 'LKR'
                                                ? 'Rs.'
                                                : _currency == 'USD'
                                                ? '\$'
                                                : _currency} ',
                                      ),
                                      onChanged: (v) {
                                        setLocal(() {
                                          partialAmount =
                                              double.tryParse(v) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: paymentDueDateCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Due Date',
                                              border: OutlineInputBorder(),
                                              hintText: 'YYYY-MM-DD',
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.calendar_month_rounded,
                                          ),
                                          onPressed: () async {
                                            final date = await showDatePicker(
                                              context: ctx,
                                              initialDate: DateTime.now().add(
                                                const Duration(days: 30),
                                              ),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(
                                                const Duration(days: 365),
                                              ),
                                            );
                                            if (date != null) {
                                              setLocal(() {
                                                paymentDueDateCtrl.text = date
                                                    .toIso8601String()
                                                    .split('T')
                                                    .first;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Paid Portion Method',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: ['CASH', 'CARD', 'CHEQUE'].map((
                                  subM,
                                ) {
                                  final isSelected =
                                      partialPaidPortionMethod == subM;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(subM),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setLocal(
                                            () =>
                                                partialPaidPortionMethod = subM,
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (partialPaidPortionMethod == 'CHEQUE') ...[
                                const SizedBox(height: 8),
                                TextField(
                                  controller: partialChequeNumberCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Paid Portion Cheque Number *',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                'Remaining Balance Due: ${_money((po.amount - partialAmount).clamp(0.0, po.amount))}',
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isProcessing ? null : doReceive,
                                icon: isProcessing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_rounded),
                                label: Text(
                                  isProcessing
                                      ? 'Processing...'
                                      : 'Confirm Receipt & Update Inventory',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      UiRadius.md,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // ── Items Table (Read Only) ──────────────────────────────
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...po.items.map(
                        (line) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111827)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E2D45)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Qty: ${line.qty}  •  Cost: ${_money(line.costPrice)}  •  Sell: ${_money(line.sellingPrice)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _money(line.lineTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _mappingOptionBtn({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: active
              ? AppTheme.brandIndigo.withValues(alpha: 0.15)
              : null,
          side: BorderSide(
            color: active ? AppTheme.brandIndigo : Colors.grey.shade400,
            width: active ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.brandIndigo : Colors.grey.shade700,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _poInfoCell(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Pay Now Dialog (for outstanding credit POs) ────────────────────────────

  Future<void> _showPayNowDialog(_PurchaseOrderItem po) async {
    final amountCtrl = TextEditingController(
      text: po.amountDue.toStringAsFixed(2),
    );
    String selectedMethod = 'CASH';
    final chequeNumberCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Pay Outstanding Balance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Outstanding balance for order ${po.id}: ${_money(po.amountDue)}',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount to Pay',
                  border: const OutlineInputBorder(),
                  prefixText:
                      '${_currency == 'LKR'
                          ? 'Rs.'
                          : _currency == 'USD'
                          ? '\$'
                          : _currency} ',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['CASH', 'CARD', 'CHEQUE'].map((method) {
                  final isSelected = selectedMethod == method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(method),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setS(() => selectedMethod = method);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              if (selectedMethod == 'CHEQUE') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: chequeNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cheque Number *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMethod == 'CHEQUE' &&
                    chequeNumberCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter Cheque Number.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final paying = double.tryParse(amountCtrl.text) ?? 0;
    if (paying <= 0) return;

    final actualPay = paying > po.amountDue ? po.amountDue : paying;

    final liveIdx = _purchaseOrders.indexWhere((p) => p.id == po.id);
    if (liveIdx >= 0) {
      final livePo = _purchaseOrders[liveIdx];
      setState(() {
        livePo.amountPaid += actualPay;
        livePo.amountDue -= actualPay;
        if (livePo.amountDue < 0) livePo.amountDue = 0;
        livePo.updatedAt = DateTime.now().toUtc().toIso8601String();
      });
      // Sync dialog's local reference
      po.amountPaid = livePo.amountPaid;
      po.amountDue = livePo.amountDue;
      po.updatedAt = livePo.updatedAt;
    } else {
      setState(() {
        po.amountPaid += actualPay;
        po.amountDue -= actualPay;
        if (po.amountDue < 0) po.amountDue = 0;
        po.updatedAt = DateTime.now().toUtc().toIso8601String();
      });
    }

    String noteText = 'Credit Payment — ${po.id}';
    if (selectedMethod == 'CHEQUE') {
      noteText += ' via Cheque #${chequeNumberCtrl.text.trim()}';
    } else {
      noteText += ' via $selectedMethod';
    }

    // Create expense entry for this payment under STOCK_PURCHASE
    if (_appDatabase != null) {
      final payExpId = 'EXP-PAY-${DateTime.now().millisecondsSinceEpoch}';
      final payBankTxId = 'TX-BANK-${DateTime.now().millisecondsSinceEpoch}';
      await _appDatabase!.insertExpense(
        db.ExpensesCompanion(
          id: Value(payExpId),
          tenantId: Value(_appDatabase?.tenantId ?? ''),
          category: const Value('STOCK_PURCHASE'),
          description: Value('Credit Payment — ${po.id} (${po.supplier})'),
          amount: Value(actualPay),
          locationId: Value(_activeLocationForWrites),
          notes: Value(noteText),
          expenseDate: Value(DateTime.now()),
          createdAt: Value(DateTime.now()),
        ),
      );

      // Deduct from bank ledger
      _bankAccountBalance -= actualPay;
      _bankTransactions.insert(
        0,
        _BankTransaction(
          id: payBankTxId,
          type: 'PO_PAYMENT',
          amount: actualPay,
          referenceId: po.id,
          notes: 'PO credit payment: ${po.id} (${po.supplier})',
          createdAt: DateTime.now(),
        ),
      );

      await _enqueueSync('INSERT', 'expenses', payExpId);
      await _enqueueSync('INSERT', 'bank_transactions', payBankTxId);
    }

    await _persistWorkspaceData();
    await _enqueueSync('UPDATE', 'purchase_orders', po.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment of ${_money(actualPay)} recorded. ${po.amountDue > 0 ? "Remaining: ${_money(po.amountDue)}" : "Fully paid!"}',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}

class _LineMappingState {
  String mappingType; // 'SAME', 'LINK', 'NEW'
  _ProductItem? linkedProduct;
  String newProductName;
  String newProductSku;
  double newProductCost;
  double newProductSell;
  String newProductCategory;
  bool updateCatalogPrices;

  _LineMappingState({
    required this.mappingType,
    this.linkedProduct,
    required this.newProductName,
    required this.newProductSku,
    required this.newProductCost,
    required this.newProductSell,
    required this.newProductCategory,
    this.updateCatalogPrices = true,
  });
}

class _POLineEditorRow extends StatefulWidget {
  final _PurchaseOrderLine line;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final String Function(double) moneyFormatter;

  const _POLineEditorRow({
    required this.line,
    required this.isDark,
    required this.onChanged,
    required this.onRemove,
    required this.moneyFormatter,
  });

  @override
  State<_POLineEditorRow> createState() => _POLineEditorRowState();
}

class _POLineEditorRowState extends State<_POLineEditorRow> {
  late TextEditingController qtyCtrl;
  late TextEditingController costCtrl;
  late TextEditingController sellCtrl;
  bool _qtyError = false;

  @override
  void initState() {
    super.initState();
    qtyCtrl = TextEditingController(text: widget.line.qty.toString());
    costCtrl = TextEditingController(
      text: widget.line.costPrice.toStringAsFixed(2),
    );
    sellCtrl = TextEditingController(
      text: widget.line.sellingPrice.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(covariant _POLineEditorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.line.qty.toString() != qtyCtrl.text && !_qtyError) {
      qtyCtrl.text = widget.line.qty.toString();
    }
    if (widget.line.costPrice.toStringAsFixed(2) != costCtrl.text) {
      costCtrl.text = widget.line.costPrice.toStringAsFixed(2);
    }
    if (widget.line.sellingPrice.toStringAsFixed(2) != sellCtrl.text) {
      sellCtrl.text = widget.line.sellingPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    qtyCtrl.dispose();
    costCtrl.dispose();
    sellCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDark
              ? const Color(0xFF1E2D45)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                widget.line.productName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ── Qty ──────────────────────────────────────────────
          SizedBox(
            width: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus button
                GestureDetector(
                  onTap: () {
                    if (widget.line.qty > 1) {
                      setState(() {
                        widget.line.qty--;
                        qtyCtrl.text = widget.line.qty.toString();
                        _qtyError = false;
                      });
                      widget.onChanged();
                    }
                  },
                  child: const Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                ),
                // Qty text field
                SizedBox(
                  width: 38,
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus && _qtyError) {
                        setState(() {
                          _qtyError = false;
                          qtyCtrl.text = widget.line.qty.toString();
                        });
                      }
                    },
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _qtyError ? Colors.red : null,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) {
                        final n = double.tryParse(v);
                        if (n != null && n > 0) {
                          setState(() => _qtyError = false);
                          widget.line.qty = n;
                          widget.onChanged();
                        } else {
                          setState(() => _qtyError = true);
                        }
                      },
                    ),
                  ),
                ),
                // Plus button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.line.qty++;
                      qtyCtrl.text = widget.line.qty.toString();
                      _qtyError = false;
                    });
                    widget.onChanged();
                  },
                  child: const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Cost Price ───────────────────────────────────────
          SizedBox(
            width: 90,
            child: TextField(
              controller: costCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
              ),
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null && n >= 0) {
                  widget.line.costPrice = n;
                  widget.onChanged();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // ── Sell Price ───────────────────────────────────────
          SizedBox(
            width: 90,
            child: TextField(
              controller: sellCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
              ),
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null && n >= 0) {
                  widget.line.sellingPrice = n;
                  widget.onChanged();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // ── Line Total ───────────────────────────────────────
          SizedBox(
            width: 80,
            child: Text(
              widget.moneyFormatter(widget.line.lineTotal),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          // ── Remove ──────────────────────────────────────────
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
