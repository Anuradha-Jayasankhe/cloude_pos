part of '../dashboard_screen.dart';

extension _point_of_saleExt on _DashboardScreenState {
  Future<void> _triggerOpenRegisterDialog() async {
    double previousKeptCash = 0.0;
    try {
      final locationId = _activeLocationForWrites;
      final prev = _cashierSessions.firstWhere(
        (s) => s.status == 'CLOSED' && s.locationId == locationId,
      );
      previousKeptCash = prev.keptCash;
    } catch (_) {}

    final openingCashStr = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final ctrl = TextEditingController(
          text: previousKeptCash > 0 ? previousKeptCash.toStringAsFixed(2) : '5000.00',
        );
        return StatefulBuilder(
          builder: (context, setDlgState) {
            void addAmount(double add) {
              final cur = double.tryParse(ctrl.text.trim()) ?? 0.0;
              setDlgState(() {
                ctrl.text = (cur + add).toStringAsFixed(2);
              });
            }

            void setAmount(double amt) {
              setDlgState(() {
                ctrl.text = amt.toStringAsFixed(2);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: Color(0xFF6366F1),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Open Cashier Shift',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: ResponsiveLayout.adaptiveDialogWidth(context, 460),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF6366F1),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cashier: $_currentUserName  •  Location: ${_activeLocationForWrites.isEmpty ? "Main Store" : _activeLocationForWrites}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (previousKeptCash > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.savings_outlined,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Previous closed shift left ${_money(previousKeptCash)} kept in drawer change.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF065F46),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Text(
                        'Enter starting cash float (Plot) in drawer to open register:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              'Starting Cash Float (${_currency == 'LKR' ? 'Rs.' : _currency})*',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDlgState(() {}),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Quick Float Presets:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: const Text('+1,000'),
                            onPressed: () => addAmount(1000),
                          ),
                          ActionChip(
                            label: const Text('+2,000'),
                            onPressed: () => addAmount(2000),
                          ),
                          ActionChip(
                            label: const Text('+5,000'),
                            onPressed: () => addAmount(5000),
                          ),
                          ActionChip(
                            label: const Text('+10,000'),
                            onPressed: () => addAmount(10000),
                          ),
                          ActionChip(
                            label: const Text('Exact 5,000'),
                            onPressed: () => setAmount(5000),
                          ),
                          ActionChip(
                            label: const Text('Exact 10,000'),
                            onPressed: () => setAmount(10000),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  onPressed: () {
                    final amt = double.tryParse(ctrl.text.trim());
                    if (amt == null || amt < 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a valid starting cash amount',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, ctrl.text.trim());
                  },
                  label: const Text(
                    'Start Shift / Open Drawer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (openingCashStr == null) {
      return;
    }

    final openingCash = double.tryParse(openingCashStr) ?? 0.0;
    await _openSession(_currentUserId, _currentUserName, openingCash);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Register session opened for $_currentUserName with ${_currency == 'LKR' ? 'Rs.' : _currency} ${openingCash.toStringAsFixed(2)}',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Widget _buildPosActiveShiftBanner(_CashierSession session) {
    final breakdown = _calculateSessionBreakdown(session);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expCash = breakdown['expected'] ?? session.openingCash;
    final cashSales = breakdown['cashSales'] ?? 0.0;
    final cardSales = breakdown['cardSales'] ?? 0.0;
    final totalTurnover = breakdown['totalSales'] ?? (cashSales + cardSales);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Shift: ${session.userName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  'Float: ${_money(session.openingCash)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  'Cash in Drawer: ${_money(expCash)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
                Text(
                  'Total Sales: ${_money(totalTurnover)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.lock_clock_rounded, size: 13),
            label: const Text(
              'Close Shift',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _triggerCloseShiftFromPos(session),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerCloseShiftFromPos(_CashierSession session) async {
    final breakdown = _calculateSessionBreakdown(session);
    final expected = breakdown['expected'] ?? session.openingCash;
    final actualCtrl = TextEditingController(text: expected.toStringAsFixed(2));
    final keptCtrl = TextEditingController(text: '0.0');
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final double act = double.tryParse(actualCtrl.text.trim()) ?? 0.0;
          final double diff = act - expected;
          final double kept = double.tryParse(keptCtrl.text.trim()) ?? 0.0;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Close Cashier Shift — ${session.userName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Opened: ${_formatDateTime(session.openingTime)}',
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: ResponsiveLayout.adaptiveDialogWidth(context, 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Expected Drawer Cash Hero Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPECTED CASH IN DRAWER',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'මුදල් ලාච්චුවේ තිබිය යුතු මුදල',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _money(expected),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Drawer Flow Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
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
                          _posBreakdownRow('Opening Float (Plot)', _money(breakdown['opening']!)),
                          _posBreakdownRow('Cash Sales (+)', '+ ${_money(breakdown['cashSales']!)}'),
                          if (breakdown['codSales']! > 0)
                            _posBreakdownRow('COD Completed (+)', '+ ${_money(breakdown['codSales']!)}'),
                          if (breakdown['creditCollected']! > 0)
                            _posBreakdownRow('Credit Payments (+)', '+ ${_money(breakdown['creditCollected']!)}'),
                          if (breakdown['installmentsCollected']! > 0)
                            _posBreakdownRow('Installments Collected (+)', '+ ${_money(breakdown['installmentsCollected']!)}'),
                          if (breakdown['drawerExpenses']! > 0)
                            _posBreakdownRow('Drawer Expenses (-)', '- ${_money(breakdown['drawerExpenses']!)}', isNegative: true),
                          if (breakdown['cashRefunds']! > 0)
                            _posBreakdownRow('Refunds / Cash OUT (-)', '- ${_money(breakdown['cashRefunds']!)}', isNegative: true),
                          const Divider(),
                          _posBreakdownRow('Card Sales (Bank Settlement)', _money(breakdown['cardSales']!)),
                          _posBreakdownRow('Total Shift Sales', _money(breakdown['totalSales'] ?? (breakdown['cashSales']! + breakdown['cardSales']!)), isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actual Cash Input
                    TextFormField(
                      controller: actualCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Actual Physical Cash Count (ගණන් කළ මුදල)*',
                        hintText: 'Enter drawer cash counted',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Reset to Expected',
                          onPressed: () {
                            setDlgState(() {
                              actualCtrl.text = expected.toStringAsFixed(2);
                            });
                          },
                        ),
                      ),
                      onChanged: (_) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 10),

                    // Difference Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: diff == 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : diff < 0
                                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                : Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: diff == 0
                              ? const Color(0xFF10B981)
                              : diff < 0
                                  ? const Color(0xFFEF4444)
                                  : Colors.blue,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            diff == 0
                                ? Icons.check_circle_outline_rounded
                                : diff < 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline_rounded,
                            size: 18,
                            color: diff == 0
                                ? const Color(0xFF10B981)
                                : diff < 0
                                    ? const Color(0xFFEF4444)
                                    : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              diff == 0
                                  ? 'Balanced — Drawer matches expected cash exactly.'
                                  : diff < 0
                                      ? 'SHORTAGE of ${_money(diff.abs())} — Counted is less than expected.'
                                      : 'EXCESS / OVERAGE of ${_money(diff)} — Counted is more than expected.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: diff == 0
                                    ? const Color(0xFF10B981)
                                    : diff < 0
                                        ? const Color(0xFFEF4444)
                                        : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Kept Cash in Drawer Input
                    TextFormField(
                      controller: keptCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Kept Cash in Drawer for Next Shift (ඊළඟ මුරයට තබන මුදල)',
                        border: OutlineInputBorder(),
                        helperText: 'Amount remaining in drawer for next shift float (default: 0.00)',
                      ),
                      onChanged: (_) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Closing Notes Input
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Shift Closing Notes (අමතර සටහන්)',
                        hintText: 'Any notes regarding count, discrepancy, or handover',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: (_isOwner || _isAdmin)
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6366F1),
                ),
                onPressed: () async {
                  final actVal = double.tryParse(actualCtrl.text.trim());
                  if (actVal == null || actVal < 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid cash amount')),
                    );
                    return;
                  }
                  final keptVal = double.tryParse(keptCtrl.text.trim()) ?? 0.0;
                  final notes = notesCtrl.text.trim();

                  Navigator.pop(ctx);
                  await _closeSession(
                    session,
                    actVal,
                    keptCash: keptVal,
                    notes: notes.isNotEmpty ? notes : null,
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (_isOwner || _isAdmin)
                            ? 'Shift closed & verified by Admin.'
                            : 'Shift close request submitted. Waiting for Admin verification.',
                      ),
                      backgroundColor: (_isOwner || _isAdmin)
                          ? const Color(0xFF10B981)
                          : Colors.amber.shade800,
                    ),
                  );
                },
                child: Text(
                  (_isOwner || _isAdmin)
                      ? 'Verify & Close Shift'
                      : 'Submit Shift Close Request',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _posBreakdownRow(
    String label,
    String value, {
    bool isNegative = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? const Color(0xFFEF4444) : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isNegative ? const Color(0xFFEF4444) : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBarcodeOrSearchScan(String val) async {
    final trimmedVal = val.trim();
    if (trimmedVal.isEmpty) return;

    // 1. Check IMEI match first
    final imeiMatchedProduct = _findProductByImei(trimmedVal);
    if (imeiMatchedProduct != null) {
      final exactImei = imeiMatchedProduct.imeiList.firstWhere(
        (x) => x.toLowerCase() == trimmedVal.toLowerCase(),
        orElse: () => trimmedVal,
      );
      _addToCartWithImeiSelection(imeiMatchedProduct, exactImei);
      _productSearchController.clear();
      _posProductSearchFocusNode.requestFocus();
      return;
    }

    // 2. Check Barcode or ID / SKU match
    final matchedList = _scopedProducts
        .where(
          (p) =>
              (p.barcode.trim().isNotEmpty &&
                  p.barcode.trim().toLowerCase() == trimmedVal.toLowerCase()) ||
              p.id.trim().toLowerCase() == trimmedVal.toLowerCase(),
        )
        .toList();

    if (matchedList.isNotEmpty) {
      if (matchedList.length > 1) {
        _showProductSkuSelectionDialog(matchedList);
      } else {
        final p = matchedList.first;
        final sameNameProducts = _scopedProducts
            .where(
              (sp) =>
                  sp.name.trim().toLowerCase() == p.name.trim().toLowerCase(),
            )
            .toList();

        if (sameNameProducts.length > 1) {
          _showProductSkuSelectionDialog(sameNameProducts);
        } else {
          if (p.allowLooseSales) {
            _showDualUnitSelectionDialog(p);
          } else {
            _addToCartWithImeiSelection(p);
          }
          _productSearchController.clear();
          _posProductSearchFocusNode.requestFocus();
        }
      }
      return;
    }

    // 3. Fallback exact Name match
    final exactNameMatched = _scopedProducts
        .where((p) => p.name.trim().toLowerCase() == trimmedVal.toLowerCase())
        .toList();
    if (exactNameMatched.length == 1) {
      final p = exactNameMatched.first;
      if (p.allowLooseSales) {
        _showDualUnitSelectionDialog(p);
      } else {
        _addToCartWithImeiSelection(p);
      }
      _productSearchController.clear();
      _posProductSearchFocusNode.requestFocus();
      return;
    }

    // 3.5 Check partial product name / category matches
    final partialMatches = _scopedProducts
        .where(
          (p) =>
              p.name.toLowerCase().contains(trimmedVal.toLowerCase()) ||
              p.category.toLowerCase().contains(trimmedVal.toLowerCase()),
        )
        .toList();

    if (partialMatches.length == 1) {
      final p = partialMatches.first;
      if (p.allowLooseSales) {
        _showDualUnitSelectionDialog(p);
      } else {
        _addToCartWithImeiSelection(p);
      }
      _productSearchController.clear();
      _posProductSearchFocusNode.requestFocus();
      return;
    } else if (partialMatches.length > 1) {
      // Multiple items match the name/category search, unfocus so cashier can pick from grid!
      _posProductSearchFocusNode.unfocus();
      return;
    }

    // 4. Barcode not registered: Offer prompt to add new product with this barcode
    if (!mounted) return;
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Barcode Not Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trimmedVal,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This barcode is not registered in your product catalog. Would you like to create and add this new product to inventory now?',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Product & Add to Cart'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );

    if (shouldAdd == true && mounted) {
      final result = await _showProductDialog(barcode: trimmedVal);
      if (result != null && mounted) {
        await _handleProductCreation(result);
        if (!mounted) return;
        final createdProduct = _products.firstWhere(
          (p) => p.id == result.product.id || p.barcode == result.product.barcode,
          orElse: () => result.product,
        );
        if (createdProduct.allowLooseSales) {
          _showDualUnitSelectionDialog(createdProduct);
        } else {
          _addToCartWithImeiSelection(createdProduct);
        }
        _productSearchController.clear();
        _posProductSearchFocusNode.requestFocus();
      }
    } else {
      _productSearchController.clear();
      _posProductSearchFocusNode.requestFocus();
    }
  }

  Future<_ServiceJobItem?> _showPosServicePickerDialog() async {
    final activeServices = _serviceJobs
        .where((service) => service.active)
        .toList();
    if (activeServices.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active services available. Add services first.'),
        ),
      );
      return null;
    }

    return showDialog<_ServiceJobItem>(
      context: context,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final filtered = activeServices.where((service) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              return service.title.toLowerCase().contains(q) ||
                  service.sku.toLowerCase().contains(q) ||
                  service.description.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              title: const Text('Add Service to Bill'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) => setLocalState(() => query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search services',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No services found'),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final service = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(service.title),
                                  subtitle: Text(
                                    '${service.sku.isEmpty ? service.id : service.sku} • ${service.description.isEmpty ? 'Service item' : service.description}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    _money(service.defaultPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onTap: () =>
                                      Navigator.of(context).pop(service),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPosValidationGuideDialog({
    required String title,
    required String sinhalaTitle,
    required String reason,
    required String guide,
    required IconData icon,
    required Color color,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sinhalaTitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 16),
              // Reason / හේතුව box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, size: 15, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'මෙම ගැටළුව මතු වූයේ ඇයි? (Why this happened)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Guide / කළ යුතු දේ box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 15, color: color),
                        const SizedBox(width: 6),
                        Text(
                          'විසඳුම / කළ යුතු දේ (Action Guide)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      guide,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('තේරුම් ගත්තා (Close)'),
            ),
            if (actionLabel != null && onAction != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onAction();
                },
                icon: const Icon(Icons.touch_app_rounded, size: 16),
                label: Text(actionLabel),
              ),
          ],
        );
      },
    );
  }

  Future<bool> _showExtendCreditLimitDialog(
    _CustomerItem customer,
    double currentOutstanding,
    double outstandingAmount,
  ) async {
    final nextBalance = currentOutstanding + outstandingAmount;
    final controller = TextEditingController(
      text: customer.creditLimit.toStringAsFixed(2),
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'Credit Limit Exceeded',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer: ${customer.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.6),
                    1: FlexColumnWidth(1.2),
                  },
                  children: [
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Credit Limit:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _money(customer.creditLimit),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Current Outstanding:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _money(currentOutstanding),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Current Sale Credit:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _money(outstandingAmount),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'New Outstanding Balance:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _money(nextBalance),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'This sale exceeds the customer\'s credit limit. Would you like to extend their credit limit to proceed?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'New Credit Limit (LKR)',
                    prefixText: 'LKR ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel Sale'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), // Purple theme color
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newLimit = double.tryParse(controller.text.trim());
                if (newLimit == null || newLimit < nextBalance) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid credit limit of at least ${_money(nextBalance)}',
                      ),
                    ),
                  );
                  return;
                }

                // Update customer locally and in database
                setState(() {
                  customer.creditLimit = newLimit;
                });

                if (_customerRepository != null) {
                  await _customerRepository!.updateCustomer(
                    _toDomainCustomer(customer),
                  );
                }

                await _refreshPendingSyncQueue();
                await _triggerImmediateSync(
                  action: 'UPDATE',
                  module: 'customers',
                  reference: customer.id,
                );

                Navigator.of(ctx).pop(true);
              },
              child: const Text('Update & Proceed'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _buildPosPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = MediaQuery.of(context).size.width < 1100;
    final isAllLocations =
        _selectedLocationScope == _DashboardScreenState._allLocationsLabel;

    final activeSession = _activeSessionFor(_currentUserId);
    final pendingSession = _pendingSessionFor(_currentUserId);
    if (activeSession == null &&
        pendingSession == null &&
        !_hasPromptedOpenRegisterThisVisit) {
      _hasPromptedOpenRegisterThisVisit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerOpenRegisterDialog();
      });
    }

    _onPosCheckoutRequested = _handlePosEnterKeyFlow;

    final rawFilteredProducts = _scopedProducts.where((p) {
      final q = _productSearchController.text.trim().toLowerCase();
      final selectedCategory = _posCategoryFilter.trim().toLowerCase();
      final matchCategory = _posCategoryFilter == 'All Categories' ||
          p.category.trim().toLowerCase() == selectedCategory;

      if (q.isEmpty) {
        return matchCategory;
      }

      // Check all query words against product name, category, id/sku, barcode, description
      final queryTokens =
          q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final matchesQuery = queryTokens.every((token) =>
          p.name.toLowerCase().contains(token) ||
          p.category.toLowerCase().contains(token) ||
          p.id.toLowerCase().contains(token) ||
          p.barcode.toLowerCase().contains(token) ||
          p.description.toLowerCase().contains(token));

      if (!matchesQuery) return false;

      // If user searched a category or matches selected filter or viewing all
      return matchCategory ||
          _posCategoryFilter == 'All Categories' ||
          p.category.toLowerCase().contains(q);
    }).toList();

    final List<_ProductItem> filteredProducts;
    final Map<String, List<String>> stockBreakdown = {};

    final groupedMap = <String, _ProductItem>{};
    for (final p in rawFilteredProducts) {
      final key = p.name.trim().toLowerCase();

      final locName = p.locationId.trim().isEmpty
          ? 'Main Branch'
          : p.locationId;
      stockBreakdown.putIfAbsent(key, () => []).add('$locName: ${p.stock}');

      if (groupedMap.containsKey(key)) {
        final existing = groupedMap[key]!;
        existing.stock += p.stock;
        if ((existing.imageUrl == null || existing.imageUrl!.trim().isEmpty) &&
            p.imageUrl != null &&
            p.imageUrl!.trim().isNotEmpty) {
          existing.imageUrl = p.imageUrl;
        }
      } else {
        groupedMap[key] = _ProductItem(
          id: p.id,
          name: p.name,
          locationId: p.locationId,
          category: p.category,
          barcode: p.barcode,
          measureUnit: p.measureUnit,
          productType: p.productType,
          description: p.description,
          costPrice: p.costPrice,
          warrantyMonths: p.warrantyMonths,
          expiryDate: p.expiryDate,
          expiryReminderMode: p.expiryReminderMode,
          expiryReminderDays: p.expiryReminderDays,
          attributeValues: p.attributeValues,
          price: p.price,
          minPrice: p.minPrice,
          stock: p.stock,
          minStock: p.minStock,
          supplierId: p.supplierId,
          imageUrl: p.imageUrl,
        );
      }
    }
    filteredProducts = groupedMap.values.toList();

    final discountCustomer = _selectedCustomerId == null
        ? _CustomerItem(
            id: 'C001',
            name: 'Walk-in Customer',
            locationId: _activeLocationForWrites,
            phone: 'N/A',
            email: '',
          )
        : _scopedCustomers.firstWhere(
            (c) => c.id == _selectedCustomerId,
            orElse: () => _CustomerItem(
              id: 'C001',
              name: 'Walk-in Customer',
              locationId: _activeLocationForWrites,
              phone: 'N/A',
              email: '',
            ),
          );

    final cartItems = _cart.entries
        .map((e) {
          final product = _resolveCartItemProduct(e.key);
          if (product == null) return null;
          final discount =
              _posLineDiscounts[e.key] ?? _autoDiscountForProduct(product);
          return _CartLine(
            product: product,
            qty: e.value,
            discountValue: discount?.value ?? 0.0,
            discountType: discount?.type ?? 'FIXED',
            discountLabel: discount?.label ?? '',
          );
        })
        .whereType<_CartLine>()
        .toList();
    final rawSubtotal = cartItems.fold<double>(0, (s, c) => s + c.totalPrice);
    double invoiceDiscountAmount = 0.0;
    if (_posInvoiceDiscountType == 'PERCENT') {
      invoiceDiscountAmount = rawSubtotal * (_posInvoiceDiscountValue / 100);
    } else {
      invoiceDiscountAmount = _posInvoiceDiscountValue;
    }
    final subtotal = (rawSubtotal - invoiceDiscountAmount).clamp(
      0.0,
      double.infinity,
    );

    final taxRate = double.tryParse(_taxRate) ?? 0;
    final taxAmount = _posApplyTax ? subtotal * (taxRate / 100) : 0.0;
    final paymentMethod = _paymentMethodController.text.isEmpty
        ? 'CASH'
        : _paymentMethodController.text;
    final isCodPayment = paymentMethod == 'COD';
    final shippingCharges =
        (_enableShippingCharges || isCodPayment) ? _posShippingCharges : 0.0;
    final grandTotal = subtotal + taxAmount + shippingCharges;
    final isChequePayment = paymentMethod == 'CHEQUE';
    final isInstallmentPayment = paymentMethod == 'INSTALLMENT';
    final allowsManualPaidAmount = _allowsManualPaidAmount(paymentMethod);
    final rawPaidAmount =
        double.tryParse(_amountPaidController.text.trim()) ?? 0;
    final effectivePaidAmount = allowsManualPaidAmount
        ? (paymentMethod == 'CASH' && _amountPaidController.text.trim().isEmpty
            ? grandTotal
            : rawPaidAmount)
        : grandTotal;
    final balanceAmount = (grandTotal - effectivePaidAmount)
        .clamp(0, double.infinity)
        .toDouble();
    final changeAmount = (effectivePaidAmount - grandTotal)
        .clamp(0, double.infinity)
        .toDouble();

    if (!allowsManualPaidAmount) {
      final autoPaidText = grandTotal.toStringAsFixed(2);
      if (_amountPaidController.text != autoPaidText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _amountPaidController.text = autoPaidText;
        });
      }
    }

    final posCategories = ['All Categories', ..._productCategories];
    final scopedCustomers = _scopedCustomers;
    final selectedCustomer = discountCustomer;
    final selectedCustomerOutstanding = _customerOutstandingBalance(
      selectedCustomer.id,
      fallback: selectedCustomer.currentBalance,
    );
    final hasOverdueCredit = _hasOverdueCreditForCustomer(selectedCustomer);
    final oldestOverdueDate = _oldestOverdueDateForCustomer(selectedCustomer);
    if (_posCustomerSearchController.text.trim().isEmpty) {
      if (_selectedCustomerId != null &&
          selectedCustomer.name.toLowerCase() != 'walk-in customer') {
        _posCustomerSearchController.text = selectedCustomer.name;
      } else {
        _posCustomerSearchController.clear();
      }
    }

    final installmentCount = _posInstallmentCount.clamp(1, 60).toInt();
    final installmentIntervalDays = _posInstallmentIntervalDays
        .clamp(1, 365)
        .toInt();
    final installmentDueDates =
        _posInstallmentDueDates.length == installmentCount
        ? List<DateTime>.from(_posInstallmentDueDates)
        : _generateInstallmentDueDates(
            installments: installmentCount,
            intervalDays: installmentIntervalDays,
          );
    _syncPosInstallmentAmounts(balanceAmount);
    final installmentAmounts = List<double>.from(_posInstallmentAmounts);
    final installmentPlannedTotal = installmentAmounts.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final installmentDifference = (balanceAmount - installmentPlannedTotal)
        .toDouble();
    const toolbarControlHeight = 52.0;
    final toolbarBgColor = isDark
        ? const Color(0xFF111827)
        : const Color.fromARGB(255, 255, 255, 255);
    final toolbarBorderColor = isDark
        ? const Color(0xFF1E2D45)
        : const Color.fromARGB(255, 226, 226, 226);
    final controlBorderColor = isDark
        ? const Color(0xFF1E2D45)
        : const Color.fromARGB(255, 222, 222, 222);

    final colorScheme = Theme.of(context).colorScheme;

    // Whole page scrolls (like other screens). No nested box-only scroll.
    final mainContent = SingleChildScrollView(
      primary: false,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 20,
        isCompact ? 12 : 20,
        isCompact ? 12 : 20,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        UiGradients.brand.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    child: Text(
                      'Point of Sale',
                      style: TextStyle(
                        fontSize: isCompact ? 28 : 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Process sales transactions quickly and efficiently.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _showPosShortcutsGuideDialog,
                    icon: const Icon(Icons.keyboard_outlined, size: 18),
                    label: const Text('Shortcuts (කෙටිමං)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_isCashier && activeSession != null)
                    Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade700,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'CASH IN HAND',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            _money(
                              _calculateSessionBreakdown(
                                    activeSession,
                                  )['expected'] ??
                                  activeSession.openingCash,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 14),
      // Avoid Flexible/Expanded inside scroll view (causes blank layout).
          // Build product + cart as normal children; page scrolls as a whole.
          Builder(
            builder: (context) {
              final productPanel = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: toolbarBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: toolbarBorderColor),
                    ),
                    child: isCompact
                        ? Column(
                            children: [
                              SizedBox(
                                height: toolbarControlHeight,
                                child: TextField(
                                  controller: _productSearchController,
                                  focusNode: _posProductSearchFocusNode,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: _handleBarcodeOrSearchScan,
                                  decoration: InputDecoration(
                                    hintText: 'Search products, category or scan...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _productSearchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: () {
                                              _productSearchController.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF2F2B48)
                                        : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: controlBorderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: controlBorderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: controlBorderColor,
                                        width: 1.4,
                                      ),
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: toolbarControlHeight,
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF2E9C64,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFBFE6CF),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.qr_code_scanner,
                                          size: 16,
                                        ),
                                        label: const Text('Scanner'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: toolbarControlHeight,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final service =
                                              await _showPosServicePickerDialog();
                                          if (service == null) return;
                                          final serviceCartId =
                                              'SV:${service.id}';
                                          setState(() {
                                            _cart[serviceCartId] =
                                                (_cart[serviceCartId] ?? 0) + 1;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.brandIndigo,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              UiRadius.md,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Add Service'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: toolbarControlHeight,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2F2B48)
                                      : Colors.white,
                                  border: Border.all(color: controlBorderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _posCategoryFilter,
                                    isExpanded: true,
                                    items: posCategories
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _posCategoryFilter = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: toolbarControlHeight,
                                  child: TextField(
                                    controller: _productSearchController,
                                    focusNode: _posProductSearchFocusNode,
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: _handleBarcodeOrSearchScan,
                                    decoration: InputDecoration(
                                      hintText: 'Search products, category or scan...',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: _productSearchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 18),
                                              onPressed: () {
                                                _productSearchController.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF2F2B48)
                                          : Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: controlBorderColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: controlBorderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: controlBorderColor,
                                          width: 1.4,
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: toolbarControlHeight,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _posProductSearchFocusNode.requestFocus();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Barcode Scanner Ready - Scan product barcode or press Enter'),
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E9C64),
                                    side: const BorderSide(
                                      color: Color(0xFFBFE6CF),
                                    ),
                                    minimumSize: const Size(
                                      0,
                                      toolbarControlHeight,
                                    ),
                                    maximumSize: const Size(
                                      double.infinity,
                                      toolbarControlHeight,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.qr_code_scanner,
                                    size: 16,
                                  ),
                                  label: const Text('Scanner Active'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                height: toolbarControlHeight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2F2B48)
                                      : Colors.white,
                                  border: Border.all(color: controlBorderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _posCategoryFilter,
                                    items: posCategories
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _posCategoryFilter = v);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: toolbarControlHeight,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final service =
                                        await _showPosServicePickerDialog();
                                    if (service == null) return;
                                    final serviceCartId = 'SV:${service.id}';
                                    setState(() {
                                      _cart[serviceCartId] =
                                          (_cart[serviceCartId] ?? 0) + 1;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandIndigo,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: Size(0, toolbarControlHeight),
                                    maximumSize: Size(
                                      double.infinity,
                                      toolbarControlHeight,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        UiRadius.md,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Add Service'),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final int crossAxisCount;
                      final double childAspectRatio;

                      if (availableWidth < 340) {
                        crossAxisCount = 1;
                        childAspectRatio = 1.5;
                      } else if (availableWidth < 540) {
                        crossAxisCount = 2;
                        childAspectRatio = 0.95;
                      } else if (availableWidth < 850) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.97;
                      } else if (availableWidth < 1200) {
                        crossAxisCount = 4;
                        childAspectRatio = 0.97;
                      } else {
                        crossAxisCount = 5;
                        childAspectRatio = 1.0;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = filteredProducts[index];
                          final key = p.name.trim().toLowerCase();
                          final locStocksList = stockBreakdown[key] ?? [];
                          final locStocksSummary = locStocksList.join(' | ');
                          final locStocksTooltip = locStocksList.join('\n');

                          final matches = _scopedProducts
                              .where(
                                (sp) =>
                                    sp.name.trim().toLowerCase() ==
                                    p.name.trim().toLowerCase(),
                              )
                              .toList();

                          final activeMatches = matches
                              .where((m) => m.stock > 0)
                              .toList();
                          final displayMatches = activeMatches.isNotEmpty
                              ? activeMatches
                              : matches;

                          final displayPriceText = displayMatches
                              .map((m) => _money(m.price))
                              .join(' / ');
                          final displaySkus = displayMatches
                              .map(
                                (m) =>
                                    m.barcode.trim().isNotEmpty ? m.barcode : m.id,
                              )
                              .join(', ');
                          final displayStock = displayMatches.fold<double>(
                            0,
                            (sum, m) => sum + m.stock,
                          );
                          final isOutOfStock = displayStock <= 0;

                          Widget cardContent = GlassContainer(
                            padding: const EdgeInsets.all(8),
                            borderRadius: UiRadius.md,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final matchedWithImg = displayMatches.firstWhere(
                                          (m) =>
                                              m.imageUrl != null &&
                                              m.imageUrl!.trim().isNotEmpty,
                                          orElse: () => p,
                                        );
                                        final imgPath = (p.imageUrl != null &&
                                                p.imageUrl!.trim().isNotEmpty)
                                            ? p.imageUrl
                                            : (matchedWithImg.imageUrl != null &&
                                                    matchedWithImg.imageUrl!.trim().isNotEmpty)
                                                ? matchedWithImg.imageUrl
                                                : null;

                                        Widget imageWidget;
                                        if (imgPath != null && imgPath.trim().isNotEmpty) {
                                          imageWidget = Container(
                                            height: 96,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                UiRadius.sm,
                                              ),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.08)
                                                    : Colors.black.withValues(alpha: 0.06),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: AppImage(
                                              imageUrl: imgPath,
                                              height: 96,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              borderRadius: BorderRadius.circular(UiRadius.sm),
                                              placeholder: Container(
                                                color: isDark
                                                    ? const Color(0xFF262338)
                                                    : const Color(0xFFF1F5F9),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  color: isDark ? Colors.white38 : Colors.grey[400],
                                                  size: 26,
                                                ),
                                              ),
                                              errorWidget: Container(
                                                color: isDark
                                                    ? const Color(0xFF262338)
                                                    : const Color(0xFFF1F5F9),
                                                alignment: Alignment.center,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.inventory_2_outlined,
                                                      color: isDark
                                                          ? const Color(0xFFA5B4FC)
                                                          : const Color(0xFF6366F1),
                                                      size: 22,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      p.name.isNotEmpty
                                                          ? p.name[0].toUpperCase()
                                                          : 'P',
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? const Color(0xFFA5B4FC)
                                                            : const Color(0xFF4F46E5),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          imageWidget = Container(
                                            height: 96,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF262338)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(
                                                UiRadius.sm,
                                              ),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF3B3556)
                                                    : const Color(0xFFE2E8F0),
                                                width: 0.8,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.inventory_2_outlined,
                                                  color: isDark
                                                      ? const Color(0xFFA5B4FC)
                                                      : const Color(0xFF6366F1),
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (isDark
                                                            ? const Color(0xFF6366F1)
                                                            : const Color(0xFF4F46E5))
                                                        .withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Text(
                                                    p.name.isNotEmpty
                                                        ? p.name[0].toUpperCase()
                                                        : 'P',
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? const Color(0xFFA5B4FC)
                                                          : const Color(0xFF4F46E5),
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        if (p.category.trim().isNotEmpty) {
                                          return Stack(
                                            children: [
                                              imageWidget,
                                              Positioned(
                                                top: 5,
                                                left: 5,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.65),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.category_outlined,
                                                        size: 9.5,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      ConstrainedBox(
                                                        constraints: const BoxConstraints(maxWidth: 85),
                                                        child: Text(
                                                          p.category.trim(),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return imageWidget;
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    Tooltip(
                                      message: p.name,
                                      child: Text(
                                        p.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          height: 1.25,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      displayMatches.length > 1
                                          ? 'Variants: $displaySkus'
                                          : 'SKU: $displaySkus',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (isAllLocations &&
                                        locStocksSummary.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        locStocksSummary,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withValues(
                                            alpha: 0.55,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayPriceText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppTheme.brandIndigo,
                                          fontWeight: FontWeight.w800,
                                          fontSize: displayMatches.length > 1
                                              ? 11.5
                                              : 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Tooltip(
                                      message: isAllLocations
                                          ? locStocksTooltip
                                          : 'Stock at current branch',
                                      child: StatusChip(
                                        label: p.allowLooseSales
                                            ? _formatDualStock(
                                                displayStock,
                                                p.measureUnit,
                                                p.secondaryUnit,
                                                p.unitConversionRatio,
                                              )
                                            : 'Stock: ${displayStock.toStringAsFixed(displayStock.truncateToDouble() == displayStock ? 0 : 2)}',
                                        color: isOutOfStock
                                            ? AppTheme.brandRose
                                            : AppTheme.brandEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );

                          if (isAllLocations && locStocksTooltip.isNotEmpty) {
                            cardContent = Tooltip(
                              message: locStocksTooltip,
                              child: cardContent,
                            );
                          }

                      return InkWell(
                        onTap: () {
                          if (isAllLocations) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select a specific branch from the top dropdown to start selling.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          final matches = _scopedProducts
                              .where(
                                (sp) =>
                                    sp.name.trim().toLowerCase() ==
                                    p.name.trim().toLowerCase(),
                              )
                              .toList();

                          if (matches.length > 1) {
                            _showProductSkuSelectionDialog(matches);
                          } else {
                            final target = matches.isNotEmpty
                                ? matches.first
                                : p;
                            if (target.stock <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('This product is out of stock!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              return;
                            }
                            _showAddToCartQuantityDialog(target);
                          }
                        },
                        child: cardContent,
                      );
                    },
                  );
                },
              ),
            ],
              );

              final cartPanel = GlassContainer(
                borderRadius: UiRadius.lg,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _editingSaleId != null
                                ? 'Editing Bill: $_editingSaleId'
                                : 'Shopping Cart (${cartItems.length})',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _editingSaleId != null
                                  ? const Color(0xFFE35D5D)
                                  : null,
                            ),
                          ),
                        ),
                        if (_editingSaleId != null)
                          IconButton(
                            tooltip: 'Cancel Edit',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Color(0xFFE35D5D),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _editingSaleId = null;
                                _cart.clear();
                                _posLineDiscounts.clear();
                                _posLinePrices.clear();
                                _resetPosDiscountState();
                                _selectedCustomerId = null;
                                _posCustomerSearchController.clear();
                                _posShippingCharges = 0.0;
                                _posShippingController.clear();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invoice editing cancelled.'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    if (isAllLocations) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.amber.shade700.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please select a specific location from the top dropdown to perform sales.',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (activeSession != null) ...[
                      const SizedBox(height: 8),
                      _buildPosActiveShiftBanner(activeSession),
                    ],
                    const SizedBox(height: 8),
                    // ── QUICK ACTIONS TOOLBAR ──
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: cartItems.isEmpty
                                ? null
                                : () async {
                                    await _showCurrentCartBillPreview();
                                  },
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.receipt_long_outlined, size: 15),
                            label: const Text('Preview', style: TextStyle(fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: cartItems.isEmpty
                                ? null
                                : () async {
                                    await _holdCurrentCart();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Bill held successfully'),
                                      ),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.pause_circle_outline, size: 15),
                            label: const Text('Hold', style: TextStyle(fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _heldCarts.isEmpty
                                ? null
                                : () async {
                                    await _resumeHeldCart();
                                  },
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.play_circle_outline, size: 15),
                            label: Text('Resume (${_heldCarts.length})', style: const TextStyle(fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: cartItems.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _removeTemporaryCartProducts(
                                      cartItems.map((line) => line.product.id),
                                    );
                                    _cart.clear();
                                    _posLineDiscounts.clear();
                                    _posLinePrices.clear();
                                    _editingSaleId = null;
                                    _paymentMethodController.text = 'CASH';
                                    _amountPaidController.clear();
                                    _chequeNumberController.clear();
                                    _posInstallmentCount = 3;
                                    _posInstallmentIntervalDays = 30;
                                    _resetPosInstallmentSchedule();
                                    _resetPosDiscountState();
                                    _selectedCustomerId = null;
                                    _posCustomerSearchController.clear();
                                  });
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: BorderSide(
                              color: cartItems.isEmpty
                                  ? (isDark ? Colors.white10 : Colors.black12)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.4),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 15),
                          label: const Text('Clear', style: TextStyle(fontSize: 11.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ── CARD 1: ORDER ITEMS CONTAINER ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2433).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(UiRadius.md),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 15,
                                    color: AppTheme.brandIndigo,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ORDER ITEMS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(UiRadius.pill),
                                ),
                                child: Text(
                                  '${cartItems.length} lines',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.brandIndigo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (cartItems.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A344A) : const Color(0xFFEEF2F6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.remove_shopping_cart_outlined,
                                      size: 24,
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your cart is empty',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap items on the left or scan barcode to add',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: cartItems.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 12,
                                  color: isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (context, index) {
                                  final line = cartItems[index];
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Product initial avatar
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          line.product.name.isNotEmpty
                                              ? line.product.name[0].toUpperCase()
                                              : 'P',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.brandIndigo,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Product details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              line.product.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 1),
                                            Row(
                                              children: [
                                                Text(
                                                  _money(line.unitPriceAfterDiscount),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                                  ),
                                                ),
                                                if (line.discountValue > 0) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _money(line.product.price),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(3),
                                                    ),
                                                    child: Text(
                                                      line.discountType == 'PERCENT'
                                                          ? '-${line.discountValue}%'
                                                          : '-${_money(line.discountValue)}',
                                                      style: const TextStyle(
                                                        color: Color(0xFFEF4444),
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (_enableMobileShopFeatures &&
                                                line.product.imeis != null &&
                                                line.product.imeis!.trim().isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              ...List.generate(line.qty.toInt(), (i) {
                                                final selectedList = _selectedCartImeis[line.product.id] ?? [];
                                                while (selectedList.length <= i) {
                                                  selectedList.add('');
                                                }
                                                final currentVal = selectedList[i];
                                                final allImeis = line.product.imeiList;
                                                final availableForThisIndex = allImeis.where((imei) {
                                                  for (int otherIdx = 0; otherIdx < line.qty; otherIdx++) {
                                                    if (otherIdx != i &&
                                                        otherIdx < selectedList.length &&
                                                        selectedList[otherIdx] == imei) {
                                                      return false;
                                                    }
                                                  }
                                                  return true;
                                                }).toList();

                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 4),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Unit ${i + 1} IMEI: ',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      DropdownButtonHideUnderline(
                                                        child: DropdownButton<String>(
                                                          isDense: true,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.blue,
                                                          ),
                                                          value: currentVal.isEmpty ? null : currentVal,
                                                          hint: const Text('Select IMEI', style: TextStyle(fontSize: 11)),
                                                          items: availableForThisIndex.map((imei) => DropdownMenuItem(
                                                            value: imei,
                                                            child: Text(imei, style: const TextStyle(fontSize: 11)),
                                                          )).toList(),
                                                          onChanged: (newVal) {
                                                            if (newVal != null) {
                                                              setState(() {
                                                                selectedList[i] = newVal;
                                                                _selectedCartImeis[line.product.id] = selectedList;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Discount icon button
                                      IconButton(
                                        onPressed: () => _showLineDiscountDialog(line.product),
                                        icon: const Icon(Icons.local_offer_outlined, size: 15),
                                        color: AppTheme.brandIndigo,
                                        tooltip: 'Discount',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                      ),
                                      // Quantity controls
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF2A344A) : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF3B4863) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => _decrementCartImei(line.product),
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                child: Icon(Icons.remove, size: 13),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _showEditCartQuantityDialog(line),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                child: Text(
                                                  line.qty.toStringAsFixed(
                                                    line.qty.truncateToDouble() == line.qty ? 0 : 2,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11.5,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _addToCartWithImeiSelection(line.product),
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                child: Icon(Icons.add, size: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Delete button
                                      IconButton(
                                        onPressed: () {
                                          _removeCartImei(line.product);
                                          setState(() {
                                            _posLineDiscounts.remove(line.product.id);
                                          });
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 16),
                                        color: const Color(0xFFEF4444),
                                        tooltip: 'Remove',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                      ),
                                      const SizedBox(width: 2),
                                      // Line Total
                                      SizedBox(
                                        width: 68,
                                        child: Text(
                                          _money(line.totalPrice),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── CARD 2: BILL SUMMARY & HERO TOTAL CONTAINER ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2433).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(UiRadius.md),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 15, color: AppTheme.brandIndigo),
                              const SizedBox(width: 6),
                              Text(
                                'BILL SUMMARY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Subtotal row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                _money(rawSubtotal),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Discount row with inline Add/Edit
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Discount',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  if (_posInvoiceDiscountValue > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _posInvoiceDiscountType == 'PERCENT'
                                            ? '${_posInvoiceDiscountValue}%'
                                            : _money(_posInvoiceDiscountValue),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Material(
                                    color: _posInvoiceDiscountValue > 0
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                        : AppTheme.brandIndigo.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    child: InkWell(
                                      onTap: _showInvoiceDiscountDialog,
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _posInvoiceDiscountValue > 0
                                                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                                : AppTheme.brandIndigo.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _posInvoiceDiscountValue > 0
                                                  ? Icons.edit_rounded
                                                  : Icons.add_rounded,
                                              size: 13,
                                              color: _posInvoiceDiscountValue > 0
                                                  ? const Color(0xFFEF4444)
                                                  : AppTheme.brandIndigo,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              _posInvoiceDiscountValue > 0 ? 'Edit' : 'Add',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: _posInvoiceDiscountValue > 0
                                                    ? const Color(0xFFEF4444)
                                                    : AppTheme.brandIndigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                invoiceDiscountAmount > 0 ? '-${_money(invoiceDiscountAmount)}' : _money(0),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: invoiceDiscountAmount > 0 ? const Color(0xFFEF4444) : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Tax row with inline checkbox
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Tax (${taxRate.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: Checkbox(
                                      value: _posApplyTax,
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) {
                                        if (val != null) setState(() => _posApplyTax = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _money(taxAmount),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          // Shipping Charges
                          if (shippingCharges > 0 || (paymentMethod == 'COD' && _posShippingCharges > 0)) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  paymentMethod == 'COD' ? _t('Delivery Fee:') : 'Shipping:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  _money(shippingCharges),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                    // Agent commission inputs (only when enabled in Settings)
                    if (_enableAgentCommission) ...[
                      const SizedBox(height: 4),
                      const Divider(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Agent Commission',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // ── Agent name: locked mode vs selectable mode ──
                      if (_agentCommissionLockToLogin) ...[
                        // LOCKED: show the logged-in user as a read-only chip
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_person_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentUserName.isEmpty
                                      ? 'Agent: (not set)'
                                      : _currentUserName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'LOCKED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // SELECTABLE: searchable autocomplete dropdown
                        Builder(
                          builder: (context) {
                            // Build combined agent list: employees + users from dashboard state
                            final agentOptions = <Map<String, String>>[];
                            final seen = <String>{};
                            for (final emp in _employees) {
                              if (!seen.contains(emp.id)) {
                                seen.add(emp.id);
                                agentOptions.add({
                                  'id': emp.id,
                                  'name': emp.name,
                                  'role': emp.role,
                                  'commissionType': 'PERCENT',
                                  'commissionValue': '0',
                                });
                              }
                            }
                            // Also add app users not already in the list
                            for (final u in _users) {
                              if (!seen.contains(u.id) &&
                                  !agentOptions.any(
                                    (e) =>
                                        e['name']?.toLowerCase() ==
                                        u.name.toLowerCase(),
                                  )) {
                                seen.add(u.id);
                                agentOptions.add({
                                  'id': u.id,
                                  'name': u.name,
                                  'role': u.role,
                                  'commissionType': 'PERCENT',
                                  'commissionValue': '0',
                                });
                              }
                            }

                            return Autocomplete<Map<String, String>>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                    final q = textEditingValue.text
                                        .trim()
                                        .toLowerCase();
                                    if (q.isEmpty) return agentOptions;
                                    return agentOptions.where(
                                      (opt) =>
                                          (opt['name'] ?? '')
                                              .toLowerCase()
                                              .contains(q) ||
                                          (opt['role'] ?? '')
                                              .toLowerCase()
                                              .contains(q),
                                    );
                                  },
                              displayStringForOption: (opt) =>
                                  opt['name'] ?? '',
                              initialValue: TextEditingValue(
                                text: _posAgentName,
                              ),
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onSubmitted,
                                  ) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                        labelText: 'Agent Name',
                                        hintText:
                                            'Search or type agent name...',
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          size: 16,
                                        ),
                                        suffixIcon: _posAgentName.isNotEmpty
                                            ? IconButton(
                                                iconSize: 14,
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  controller.clear();
                                                  setState(() {
                                                    _posAgentName = '';
                                                    _posAgentId = '';
                                                    _posAgentCommission = 0.0;
                                                    _posAgentCommissionController
                                                        .clear();
                                                  });
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (v) {
                                        setState(() {
                                          _posAgentName = v.trim();
                                          // Clear the stored ID if the user manually edits
                                          _posAgentId = '';
                                        });
                                      },
                                    );
                                  },
                              optionsViewBuilder: (context, onSelected, options) {
                                final optList = options.toList();
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 6,
                                    borderRadius: BorderRadius.circular(8),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 220,
                                        maxWidth: 320,
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: optList.length,
                                        itemBuilder: (context, index) {
                                          final opt = optList[index];
                                          final name = opt['name'] ?? '';
                                          final role = opt['role'] ?? '';
                                          return InkWell(
                                            onTap: () => onSelected(opt),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.12,
                                                            ),
                                                    child: Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                                .toUpperCase()
                                                          : '?',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          name,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                        if (role.isNotEmpty)
                                                          Text(
                                                            role,
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
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
                                    ),
                                  ),
                                );
                              },
                              onSelected: (Map<String, String> selection) {
                                final name = selection['name'] ?? '';
                                final id = selection['id'] ?? '';
                                setState(() {
                                  _posAgentName = name;
                                  _posAgentId = id;
                                  _posAgentNameController.text = name;
                                });
                                // Try to auto-fill commission rate from employee DB record
                                _appDatabase
                                    ?.getAllEmployees()
                                    .then((emps) {
                                      final emp = emps.firstWhere(
                                        (e) =>
                                            e.id == id ||
                                            e.name.toLowerCase() ==
                                                name.toLowerCase(),
                                        orElse: () =>
                                            throw StateError('not found'),
                                      );
                                      final commType =
                                          emp.commissionType.toUpperCase() ==
                                              'FIXED'
                                          ? 'FIXED'
                                          : 'PERCENT';
                                      final commValue = emp.commissionValue;
                                      if (commValue > 0 && mounted) {
                                        setState(() {
                                          _posAgentCommissionType = commType;
                                          _posAgentCommission = commValue;
                                          _posAgentCommissionController.text =
                                              commValue.toStringAsFixed(
                                                commType == 'FIXED' ? 2 : 1,
                                              );
                                        });
                                      }
                                    })
                                    .catchError((_) {
                                      // Agent is a system user without an employee record —
                                      // commission type/value fields stay at their current values.
                                    });
                              },
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Commission Type toggle + amount input
                      Row(
                        children: [
                          // Type selector (PERCENT / FIXED)
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _posAgentCommissionType,
                              isDense: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                labelText: 'Type',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'PERCENT',
                                  child: Text('% Percent'),
                                ),
                                DropdownMenuItem(
                                  value: 'FIXED',
                                  child: Text('Fixed'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _posAgentCommissionType = v;
                                    _posAgentCommission = 0.0;
                                    _posAgentCommissionController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Commission amount / percent input
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _posAgentCommissionController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: const OutlineInputBorder(),
                                labelText: _posAgentCommissionType == 'PERCENT'
                                    ? 'Commission (%)'
                                    : 'Fixed Amount',
                                hintText: '0',
                                suffixText: _posAgentCommissionType == 'PERCENT'
                                    ? '%'
                                    : _currency,
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _posAgentCommission =
                                      double.tryParse(v) ?? 0.0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Pay Now / Pay Later
                      DropdownButtonFormField<bool>(
                        value: _posAgentCommissionPaid,
                        isDense: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          labelText: 'Commission Payment',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: false,
                            child: Text('Pay Later (Record as Unpaid)'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Pay Now (Mark as Paid)'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _posAgentCommissionPaid = v);
                          }
                        },
                      ),
                      // Commission preview row
                      if (_posAgentName.isNotEmpty && _posAgentCommission > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _overviewRow(
                            _posAgentCommissionType == 'PERCENT'
                                ? 'Commission (${_posAgentCommission.toStringAsFixed(1)}%):'
                                : 'Commission (Fixed):',
                            _money(
                              _posAgentCommissionType == 'PERCENT'
                                  ? grandTotal * (_posAgentCommission / 100)
                                  : _posAgentCommission,
                            ),
                          ),
                        ),
                    ],
                          // ── HERO GRAND TOTAL & STATUS BANNER ──
                          Container(
                            margin: const EdgeInsets.only(top: 14),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1B4B)
                                  : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(UiRadius.md),
                              border: Border.all(
                                color: AppTheme.brandIndigo.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'GRAND TOTAL',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                            color: AppTheme.brandIndigo,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _money(grandTotal),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E1B4B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Dynamic status badge
                                    if (changeAmount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(UiRadius.pill),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.currency_exchange_rounded,
                                              size: 16,
                                              color: Color(0xFF059669),
                                            ),
                                            const SizedBox(width: 6),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'CHANGE',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                                Text(
                                                  _money(changeAmount),
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (balanceAmount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(UiRadius.pill),
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.schedule_rounded,
                                              size: 16,
                                              color: Color(0xFFD97706),
                                            ),
                                            const SizedBox(width: 6),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'BALANCE DUE',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFFD97706),
                                                  ),
                                                ),
                                                Text(
                                                  _money(balanceAmount),
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFFD97706),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(UiRadius.pill),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 15,
                                              color: Color(0xFF059669),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'PAID IN FULL',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (effectivePaidAmount > 0) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Paid Amount:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                          ),
                                        ),
                                        Text(
                                          _money(effectivePaidAmount),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Collapsible / Compact Coupon & Gift Card Section
                          if (_coupons.any((c) => c.active)) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _posCouponController,
                                      style: const TextStyle(fontSize: 12.5),
                                      decoration: InputDecoration(
                                        hintText: 'Enter coupon code',
                                        prefixIcon: const Icon(
                                          Icons.confirmation_number_outlined,
                                          size: 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final code = _posCouponController.text.trim().toLowerCase();
                                      if (code.isEmpty) return;
                                      final match = _coupons.firstWhere(
                                        (c) => c.active && c.code.trim().toLowerCase() == code,
                                        orElse: () => _CouponItem(
                                          code: '',
                                          description: '',
                                          discountPercent: 0,
                                          active: false,
                                        ),
                                      );
                                      if (match.code.isNotEmpty && match.discountPercent > 0) {
                                        setState(() {
                                          _posInvoiceDiscountType = 'PERCENT';
                                          _posInvoiceDiscountValue = match.discountPercent;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Coupon applied: ${match.discountPercent}% discount (${match.code})',
                                            ),
                                            backgroundColor: AppTheme.brandEmerald,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Invalid or inactive coupon code'),
                                            backgroundColor: AppTheme.brandRose,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                    ),
                                    child: const Text('Apply'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: TextField(
                                    controller: _posGiftCardController,
                                    style: const TextStyle(fontSize: 12.5),
                                    decoration: InputDecoration(
                                      hintText: 'Enter gift card code',
                                      prefixIcon: const Icon(
                                        Icons.card_giftcard_outlined,
                                        size: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 38,
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── CARD 3: CUSTOMER SELECTION ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131D2E) : Colors.white,
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
                          Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Text(
                                  'Customer',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                if (paymentMethod == 'COD')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'COD Required',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                    ),
                                  )
                                else if (_isCreditPaymentMethod(paymentMethod))
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'Credit Required',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Optional (Cash/Card)',
                                      style: TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              _posCustomerSearchController.clear();
                              final customer = await _showCustomerDialog();
                              if (customer == null) return;
                              customer.locationId = _activeLocationForWrites;

                              try {
                                setState(() {
                                  _customers.removeWhere(
                                    (item) => item.id == customer.id,
                                  );
                                  _customers.add(customer);
                                  _selectedCustomerId = customer.id;
                                  _posCustomerSearchController.text =
                                      '${customer.name} (${customer.phone.isEmpty ? 'N/A' : customer.phone})';
                                  if (customer.discountPercent > 0) {
                                    _posInvoiceDiscountType = 'PERCENT';
                                    _posInvoiceDiscountValue =
                                        customer.discountPercent;
                                  }
                                });
                                await _persistWorkspaceData();

                                if (_customerRepository != null) {
                                  try {
                                    await _customerRepository!.insertCustomer(
                                      _toDomainCustomer(customer),
                                    );
                                  } catch (_) {
                                    // Fall back to update for ID collisions from legacy short IDs.
                                    await _customerRepository!.updateCustomer(
                                      _toDomainCustomer(customer),
                                    );
                                  }
                                  await _refreshPendingSyncQueue();
                                  await _triggerImmediateSync(
                                    action: 'INSERT',
                                    module: 'customers',
                                    reference: customer.id,
                                  );
                                } else {
                                  await _enqueueSync(
                                    'INSERT',
                                    'customers',
                                    customer.id,
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Unable to add customer: $e'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Add Customer'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RawAutocomplete<_CustomerItem>(
                        textEditingController: _posCustomerSearchController,
                        focusNode: _posCustomerSearchFocusNode,
                        displayStringForOption: (customer) =>
                            '${customer.name} (${customer.phone.isEmpty ? 'N/A' : customer.phone})',
                        optionsBuilder: (textEditingValue) {
                          final query = textEditingValue.text
                              .trim()
                              .toLowerCase();
                          return _scopedCustomers.where((customer) {
                            if (query.isEmpty) return true;
                            return customer.name.toLowerCase().contains(query) ||
                                customer.phone.toLowerCase().contains(query) ||
                                customer.id.toLowerCase().contains(query);
                          });
                        },
                        onSelected: (customer) {
                          setState(() {
                            _selectedCustomerId = customer.id;
                            _posCustomerSearchController.text =
                                '${customer.name} (${customer.phone.isEmpty ? 'N/A' : customer.phone})';
                            if (customer.discountPercent > 0) {
                              _posInvoiceDiscountType = 'PERCENT';
                              _posInvoiceDiscountValue = customer.discountPercent;
                            } else {
                              _posInvoiceDiscountType = 'FIXED';
                              _posInvoiceDiscountValue = 0.0;
                            }
                          });
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search customer by name, phone, or ID',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  if (val.trim().isEmpty) {
                                    setState(() {
                                      _selectedCustomerId = null;
                                    });
                                  }
                                },
                                onSubmitted: (_) => onFieldSubmitted(),
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          final optionList = options.toList();
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                  maxHeight: 220,
                                ),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: optionList.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final customer = optionList[index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(customer.name),
                                      subtitle: Text(
                                        '${customer.id} • ${customer.phone.isEmpty ? 'N/A' : customer.phone}',
                                      ),
                                      onTap: () => onSelected(customer),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_selectedCustomerId == null) ...[
                        if (paymentMethod == 'COD') ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDBA74)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.local_shipping_outlined,
                                  color: Color(0xFFEA580C),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'COD ඇණවුම් සඳහා Customer තොරතුරු අත්‍යවශ්‍යයි',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                          color: Color(0xFF9A3412),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'ඩිලිවරි රයිඩර්ට බාරදීමට පාරිභෝගිකයාගේ නම, ලිපිනය සහ දුරකථන අංකය අවශ්‍ය වේ. කරුණාකර Customer තෝරන්න හෝ "+ Add Customer" ඔබන්න.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFC2410C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_isCreditPaymentMethod(paymentMethod)) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Color(0xFF2563EB),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'ණය (Credit) සඳහා ලියාපදිංචි Customer කෙනෙකු තෝරන්න',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                          color: Color(0xFF1E40AF),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'ණය ගිණුම සටහන් කිරීම සඳහා Walk-in Customer භාවිතා කළ නොහැක. කරුණාකර ලියාපදිංචි Customer කෙනෙක් තෝරන්න හෝ ලියාපදිංචි කරන්න.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      if (_selectedCustomerId != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 14, color: AppTheme.brandIndigo),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      selectedCustomer.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedCustomerId = null;
                                        _posCustomerSearchController.clear();
                                        _posInvoiceDiscountType = 'FIXED';
                                        _posInvoiceDiscountValue = 0.0;
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Address: ${selectedCustomer.address.isEmpty ? 'N/A' : selectedCustomer.address}',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Credit: ',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  Text(
                                    _money(selectedCustomerOutstanding),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selectedCustomerOutstanding > 0 ? const Color(0xFFE11D48) : null,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  Text(
                                    ' / Limit: ${selectedCustomer.creditLimit <= 0 ? 'No limit' : _money(selectedCustomer.creditLimit)}',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasOverdueCredit) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEFEF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFF2B6B6)),
                                  ),
                                  child: Text(
                                    oldestOverdueDate == null
                                        ? 'Overdue credit detected. Clear overdue balance before creating new credit sale.'
                                        : 'Overdue credit since ${_formatDate(oldestOverdueDate)}. Clear overdue balance before creating new credit sale.',
                                    style: const TextStyle(
                                      color: Color(0xFFB43E3E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ── CHECKOUT ACTION BUTTON ──
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: (cartItems.isEmpty || isAllLocations)
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFCBD5E1))
                            : const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                      child: ElevatedButton(
                        onPressed: (cartItems.isEmpty || isAllLocations)
                            ? null
                            : () => _startPosCheckoutFlow(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white38,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(UiRadius.md),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _editingSaleId != null
                                  ? Icons.save_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _editingSaleId != null
                                  ? 'Update Bill • ${_money(grandTotal)}'
                                  : 'Complete Sale (${_posShortcuts['completeSale'] ?? 'Enter'}) • ${_money(grandTotal)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    productPanel,
                    const SizedBox(height: 12),
                    cartPanel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: productPanel),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: cartPanel),
                ],
              );
            },
          ),
        ],
      ),
    );

    if (activeSession == null) {
      return Stack(
        children: [
          AbsorbPointer(
            absorbing: true,
            child: Opacity(opacity: 0.35, child: mainContent),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Center(
                  child: Container(
                    width: ResponsiveLayout.adaptiveDialogWidth(context, 480),
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1B29).withOpacity(0.92)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: pendingSession != null
                            ? Colors.amber.withOpacity(0.4)
                            : Colors.purple.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: pendingSession != null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.hourglass_top_rounded,
                                  color: Colors.amber,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Shift Close Pending Approval',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your shift close request has been submitted to Admin.\n\nCounted Cash: ${_money(pendingSession.actualCash ?? 0.0)}\nExpected Cash: ${_money(pendingSession.expectedCash)}\n\nPlease wait until Admin approves or verifies the shift before starting a new one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_isOwner || _isAdmin) ...[
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    minimumSize: const Size(double.infinity, 46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text(
                                    'Admin: Verify & Approve Now',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    await _approveCloseSession(pendingSession);
                                    if (mounted) setState(() {});
                                  },
                                ),
                                const SizedBox(height: 10),
                              ],
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Refresh Status'),
                                onPressed: () {
                                  setState(() {});
                                },
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.point_of_sale_rounded,
                                  color: Colors.purple,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Open Cashier Shift Required',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You must open a cashier shift with a starting cash float (Plot) to perform POS sales transactions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _triggerOpenRegisterDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                                  label: const Text(
                                    'Open Cashier Shift',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return mainContent;
  }

  Widget _posPaymentButton(
    String key,
    String label,
    String selected,
    double grandTotal,
  ) {
    final isSelected = key == selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData getIcon(String k) {
      switch (k.toUpperCase()) {
        case 'CASH':
          return Icons.payments_outlined;
        case 'CARD':
          return Icons.credit_card_outlined;
        case 'CHEQUE':
          return Icons.sticky_note_2_outlined;
        case 'CREDIT':
          return Icons.badge_outlined;
        case 'INSTALLMENT':
          return Icons.calendar_month_outlined;
        case 'COD':
          return Icons.local_shipping_outlined;
        default:
          return Icons.payment_outlined;
      }
    }

    return Expanded(
      child: Material(
        color: isSelected
            ? (isDark
                  ? AppTheme.brandIndigo.withValues(alpha: 0.15)
                  : AppTheme.brandIndigo.withValues(alpha: 0.08))
            : (isDark ? const Color(0xFF111827) : Colors.white),
        borderRadius: BorderRadius.circular(UiRadius.md),
        child: InkWell(
          onTap: () => _applyPosPaymentMethod(key, grandTotal),
          borderRadius: BorderRadius.circular(UiRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiRadius.md),
              border: Border.all(
                color: isSelected
                    ? AppTheme.brandIndigo
                    : (isDark
                          ? const Color(0xFF1E2D45)
                          : const Color(0xFFE8EAFF)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getIcon(key),
                  size: 18,
                  color: isSelected
                      ? AppTheme.brandIndigo
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.brandIndigo
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155)),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _posPaymentCompactButton(
    String key,
    String label,
    String selected,
    double grandTotal,
  ) {
    final isSelected = key == selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData getIcon(String k) {
      switch (k.toUpperCase()) {
        case 'CASH':
          return Icons.payments_outlined;
        case 'CARD':
          return Icons.credit_card_outlined;
        case 'CHEQUE':
          return Icons.sticky_note_2_outlined;
        case 'CREDIT':
          return Icons.badge_outlined;
        case 'INSTALLMENT':
          return Icons.calendar_month_outlined;
        case 'COD':
          return Icons.local_shipping_outlined;
        default:
          return Icons.payment_outlined;
      }
    }

    return SizedBox(
      width: 104,
      child: Material(
        color: isSelected
            ? (isDark
                  ? AppTheme.brandIndigo.withValues(alpha: 0.15)
                  : AppTheme.brandIndigo.withValues(alpha: 0.08))
            : (isDark ? const Color(0xFF111827) : Colors.white),
        borderRadius: BorderRadius.circular(UiRadius.md),
        child: InkWell(
          onTap: () => _applyPosPaymentMethod(key, grandTotal),
          borderRadius: BorderRadius.circular(UiRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiRadius.md),
              border: Border.all(
                color: isSelected
                    ? AppTheme.brandIndigo
                    : (isDark
                          ? const Color(0xFF1E2D45)
                          : const Color(0xFFE8EAFF)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getIcon(key),
                  size: 16,
                  color: isSelected
                      ? AppTheme.brandIndigo
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.brandIndigo
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155)),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLineDiscountDialog(_ProductItem product) {
    final TextEditingController valueController = TextEditingController(
      text: _posLineDiscounts[product.id]?.value.toString() ?? '',
    );
    String type = _posLineDiscounts[product.id]?.type ?? 'FIXED';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Discount for ${product.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Fixed Amount'),
                          value: 'FIXED',
                          groupValue: type,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Percentage (%)'),
                          value: 'PERCENT',
                          groupValue: type,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'PERCENT'
                          ? 'Discount %'
                          : 'Discount Amount',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _posLineDiscounts.remove(product.id);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(valueController.text) ?? 0.0;
                    if (value > 0) {
                      setState(() {
                        _posLineDiscounts[product.id] = _DiscountData(
                          value: type == 'PERCENT'
                              ? value.clamp(0, 100)
                              : value,
                          type: type,
                        );
                      });
                    } else {
                      setState(() {
                        _posLineDiscounts.remove(product.id);
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInvoiceDiscountDialog() {
    final TextEditingController valueController = TextEditingController(
      text: _posInvoiceDiscountValue > 0
          ? _posInvoiceDiscountValue.toString()
          : '',
    );
    String type = _posInvoiceDiscountType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Invoice Discount'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Fixed Amount'),
                          value: 'FIXED',
                          groupValue: type,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Percentage (%)'),
                          value: 'PERCENT',
                          groupValue: type,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'PERCENT'
                          ? 'Discount %'
                          : 'Discount Amount',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _posInvoiceDiscountValue = 0.0;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(valueController.text) ?? 0.0;
                    setState(() {
                      _posInvoiceDiscountValue = type == 'PERCENT'
                          ? value.clamp(0, 100)
                          : value;
                      _posInvoiceDiscountType = type;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showProductSkuSelectionDialog(
    List<_ProductItem> options,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiRadius.lg),
          ),
          title: const Text(
            'Select Variant / Batch',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: ResponsiveLayout.adaptiveDialogWidth(context, 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multiple products share this barcode or name. Please select the correct batch / price variant:',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = options[index];
                      final expText = item.expiryDate != null
                          ? ' • Exp: ${item.expiryDate!.toLocal().toString().split(' ').first}'
                          : '';
                      final branchText = item.locationId.isNotEmpty && item.locationId != 'LOC_MAIN'
                          ? ' • Loc: ${item.locationId}'
                          : '';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandIndigo.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.brandIndigo.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      'Batch #${index + 1}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.brandIndigo,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _money(item.price),
                              style: TextStyle(
                                color: AppTheme.brandIndigo,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'SKU/Bar: ${item.barcode.trim().isNotEmpty ? item.barcode : item.id} • Cost: ${_money(item.costPrice ?? 0.0)}$expText$branchText',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Stock: ${item.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.stock <= item.minStock
                                      ? AppTheme.brandRose
                                      : AppTheme.brandEmerald,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          Icons.add_shopping_cart_rounded,
                          color: colorScheme.primary,
                        ),
                        onTap: () {
                          if (item.stock <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This batch is out of stock!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          _showAddToCartQuantityDialog(item);
                          _productSearchController.clear();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  _ProductItem? _findProductByImei(String query) {
    if (!_enableMobileShopFeatures) return null;
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    for (final p in _scopedProducts) {
      if (p.imeis != null && p.imeis!.isNotEmpty) {
        final imeisList = p.imeiList;
        for (final imei in imeisList) {
          if (imei.toLowerCase() == trimmed) {
            return p;
          }
        }
      }
    }
    return null;
  }

  void _addToCartWithImeiSelection(_ProductItem item, [String? imei]) {
    final currentQty = _cart[item.id] ?? 0;
    if (currentQty >= item.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot exceed available stock of ${item.stock}!'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _cart[item.id] = currentQty + 1;

      if (_enableMobileShopFeatures &&
          item.imeis != null &&
          item.imeis!.trim().isNotEmpty) {
        final availableImeis = item.imeiList;
        if (availableImeis.isNotEmpty) {
          final currentSelected = _selectedCartImeis[item.id] ?? [];
          final nextSelected = List<String>.from(currentSelected);

          if (imei != null &&
              availableImeis.contains(imei) &&
              !nextSelected.contains(imei)) {
            nextSelected.add(imei);
          } else {
            final unselected = availableImeis.firstWhere(
              (x) => !nextSelected.contains(x),
              orElse: () => '',
            );
            nextSelected.add(unselected);
          }
          _selectedCartImeis[item.id] = nextSelected;
        }
      }
    });
  }

  void _decrementCartImei(_ProductItem item) {
    setState(() {
      final currentQty = _cart[item.id] ?? 0;
      final next = currentQty - 1;
      if (next <= 0) {
        _removeTemporaryCartProducts([item.id]);
        _cart.remove(item.id);
        _selectedCartImeis.remove(item.id);
      } else {
        _cart[item.id] = next;
        if (_enableMobileShopFeatures &&
            _selectedCartImeis.containsKey(item.id)) {
          final list = _selectedCartImeis[item.id]!;
          if (list.isNotEmpty) {
            list.removeLast();
          }
        }
      }
    });
  }

  void _removeCartImei(_ProductItem item) {
    setState(() {
      _removeTemporaryCartProducts([item.id]);
      _cart.remove(item.id);
      _selectedCartImeis.remove(item.id);
    });
  }

  Future<void> _showEditCartQuantityDialog(_CartLine line) async {
    final controller = TextEditingController(
      text: line.qty.truncateToDouble() == line.qty
          ? line.qty.toInt().toString()
          : line.qty.toString(),
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit Quantity - ${line.product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity (${line.product.measureUnit})',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text.trim());
                if (val == null) return;
                setState(() {
                  if (val <= 0) {
                    _removeCartImei(line.product);
                  } else {
                    _cart[line.product.id] = (val * 100).round() / 100.0;
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  List<String> get _posAvailablePaymentMethods {
    final list = ['CASH', 'CARD', 'CHEQUE', 'CREDIT', 'INSTALLMENT'];
    if (_enableCod) {
      list.add('COD');
    }
    return list;
  }

  double _calculateCurrentGrandTotal() {
    final cartItems = _cart.entries
        .map((e) {
          final product = _resolveCartItemProduct(e.key);
          if (product == null) return null;
          final discount =
              _posLineDiscounts[e.key] ?? _autoDiscountForProduct(product);
          return _CartLine(
            product: product,
            qty: e.value,
            discountValue: discount?.value ?? 0.0,
            discountType: discount?.type ?? 'FIXED',
            discountLabel: discount?.label ?? '',
          );
        })
        .whereType<_CartLine>()
        .toList();
    final rawSubtotal = cartItems.fold<double>(0, (s, c) => s + c.totalPrice);
    double invoiceDiscountAmount = 0.0;
    if (_posInvoiceDiscountType == 'PERCENT') {
      invoiceDiscountAmount = rawSubtotal * (_posInvoiceDiscountValue / 100);
    } else {
      invoiceDiscountAmount = _posInvoiceDiscountValue;
    }
    final subtotal = (rawSubtotal - invoiceDiscountAmount).clamp(
      0.0,
      double.infinity,
    );

    final taxRate = double.tryParse(_taxRate) ?? 0;
    final taxAmount = _posApplyTax ? subtotal * (taxRate / 100) : 0.0;
    final paymentMethod = _paymentMethodController.text.isEmpty
        ? 'CASH'
        : _paymentMethodController.text;
    final isCodPayment = paymentMethod == 'COD';
    final shippingCharges =
        (_enableShippingCharges || isCodPayment) ? _posShippingCharges : 0.0;
    return subtotal + taxAmount + shippingCharges;
  }

  void _focusPaymentMethod() {
    if (!mounted) return;
    _posPaymentMethodFocusNode.requestFocus();
    if (_paymentMethodController.text.trim().isEmpty) {
      final total = _calculateCurrentGrandTotal();
      _applyPosPaymentMethod('CASH', total);
    }
    setState(() {});
  }

  void _cyclePaymentMethod(int step, double grandTotal) {
    final methods = _posAvailablePaymentMethods;
    if (methods.isEmpty) return;
    final current = _paymentMethodController.text.trim().toUpperCase().isEmpty
        ? 'CASH'
        : _paymentMethodController.text.trim().toUpperCase();
    int idx = methods.indexOf(current);
    if (idx == -1) idx = 0;
    int nextIdx = (idx + step) % methods.length;
    if (nextIdx < 0) nextIdx += methods.length;
    final nextMethod = methods[nextIdx];
    _applyPosPaymentMethod(nextMethod, grandTotal);
    setState(() {});
  }

  void _focusAmountPaid([double? total]) {
    if (!mounted) return;
    final grandTotal = total ?? _calculateCurrentGrandTotal();
    final currentMethod = _paymentMethodController.text.trim().toUpperCase().isEmpty
        ? 'CASH'
        : _paymentMethodController.text.trim().toUpperCase();
    final allowsManual = _allowsManualPaidAmount(currentMethod);

    if (allowsManual) {
      if (_amountPaidController.text.trim().isEmpty ||
          _amountPaidController.text.trim() == '0' ||
          _amountPaidController.text.trim() == '0.00') {
        _amountPaidController.text = grandTotal.toStringAsFixed(2);
      }
      _amountPaidController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _amountPaidController.text.length,
      );
    } else {
      _amountPaidController.text = grandTotal.toStringAsFixed(2);
      _amountPaidController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _amountPaidController.text.length,
      );
    }
    _amountPaidFocusNode.requestFocus();
    setState(() {});
  }

  void _handlePosEnterKeyFlow() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart එක හිස්ව පවතී. කරුණාකර භාණ්ඩ Cart එකට එක් කරන්න.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _startPosCheckoutFlow();
  }

  Future<void> _startPosCheckoutFlow() async {
    if (_isPosCheckoutProcessing) return;

    final isAllLocations =
        _selectedLocationScope == _DashboardScreenState._allLocationsLabel;
    if (isAllLocations) {
      await _showPosValidationGuideDialog(
        title: 'Branch / Location Selection Required',
        sinhalaTitle: 'අලෙවිසැල් ශාඛාව (Branch) තෝරන්න',
        reason: 'ඔබ දැනට සිටින්නේ "All Locations" (සියලුම ශාඛා) බැලීමේ ආකාරයේය. තොග අඩු කිරීමට සහ මුදල් රෙජිස්ටරය නිවැරදිව පවත්වා ගැනීමට නිශ්චිත ශාඛාවක් තෝරාගත යුතුය.',
        guide: 'ඉහළ ඇති Location dropdown එකෙන් ඔබගේ අලෙවිසැල් ශාඛාව (Branch) තෝරා ගන්න.',
        icon: Icons.store_mall_directory_outlined,
        color: Colors.deepOrange,
      );
      return;
    }

    final cartItems = _cart.entries
        .map((e) {
          final product = _resolveCartItemProduct(e.key);
          if (product == null) return null;
          final discount =
              _posLineDiscounts[e.key] ?? _autoDiscountForProduct(product);
          return _CartLine(
            product: product,
            qty: e.value,
            discountValue: discount?.value ?? 0.0,
            discountType: discount?.type ?? 'FIXED',
            discountLabel: discount?.label ?? '',
          );
        })
        .whereType<_CartLine>()
        .toList();

    if (cartItems.isEmpty) {
      await _showPosValidationGuideDialog(
        title: 'Cart is Empty',
        sinhalaTitle: 'Cart එක හිස්ව පවතී',
        reason: 'Checkout කිරීමට පෙර අවම වශයෙන් එක් භාණ්ඩයක් හෝ Cart එකට ඇතුළත් කළ යුතුය.',
        guide: 'භාණ්ඩ ලැයිස්තුවෙන් හෝ Barcode Scanner එක මඟින් භාණ්ඩ Cart එකට එක් කරන්න.',
        icon: Icons.shopping_cart_outlined,
        color: Colors.amber.shade800,
      );
      return;
    }

    final activeSession = _activeSessionFor(_currentUserId);
    if (activeSession == null) {
      await _showPosValidationGuideDialog(
        title: 'Cash Register Session Required',
        sinhalaTitle: 'මුදල් රෙජිස්ටරය (Register) විවෘත කරන්න',
        reason: 'විකිණුම් සිදුකිරීමට පෙර මුදල් රෙජිස්ටරය (Cashier Shift) ආරම්භ කර තිබිය යුතුය.',
        guide: 'ඉහළ ඇති "Open Register" හෝ Shift බොත්තම ඔබා ආරම්භක මුදල ඇතුළත් කර Shift එක ආරම්භ කරන්න.',
        icon: Icons.lock_clock_outlined,
        color: Colors.blueAccent,
        actionLabel: 'Open Register Now',
        onAction: () => _triggerOpenRegisterDialog(),
      );
      return;
    }

    final confirmed = await _showPosCheckoutModalFlow();
    if (confirmed == true && mounted) {
      // Prompt for shopping bag selection before final checkout (if enabled in settings)
      if (_enableShoppingBagCharges) {
        // Wait for checkout modal to finish popping completely to avoid Navigator transition conflicts
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;

        final bagResult = await _showShoppingBagConfirmationDialog(
          parentContext: context,
          currentGrandTotal: _calculateCurrentGrandTotal(),
          paymentMethod: _paymentMethodController.text,
        );

        if (bagResult == null) {
          // Cashier closed or cancelled with Escape
          if (mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Sale completion cancelled.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        if (bagResult.hasBags) {
          bagResult.applyToCart(_temporaryCartProducts, _cart);
          final bagCost = bagResult.totalCost;
          final currentPaid =
              double.tryParse(_amountPaidController.text.trim()) ?? 0.0;
          final newGrandTotal = _calculateCurrentGrandTotal();

          final currentMethod =
              _paymentMethodController.text.trim().toUpperCase();
          if (currentMethod == 'CASH') {
            if ((currentPaid - (newGrandTotal - bagCost)).abs() < 0.05 ||
                currentPaid < newGrandTotal) {
              _amountPaidController.text = newGrandTotal.toStringAsFixed(2);
            }
          } else if (currentMethod != 'CREDIT') {
            _amountPaidController.text = newGrandTotal.toStringAsFixed(2);
          }
        }
      }

      await _processPosCheckout();
    }
  }

  Future<_CustomerItem?> _handleAddNewCustomerFromPos() async {
    final customer = await _showCustomerDialog();
    if (customer == null) return null;
    customer.locationId = _activeLocationForWrites;

    try {
      setState(() {
        _customers.removeWhere((item) => item.id == customer.id);
        _customers.add(customer);
        _selectedCustomerId = customer.id;
        _posCustomerSearchController.text =
            '${customer.name} (${customer.phone.isEmpty ? 'N/A' : customer.phone})';
        if (customer.discountPercent > 0) {
          _posInvoiceDiscountType = 'PERCENT';
          _posInvoiceDiscountValue = customer.discountPercent;
        }
      });
      await _persistWorkspaceData();

      if (_customerRepository != null) {
        try {
          await _customerRepository!.insertCustomer(_toDomainCustomer(customer));
        } catch (_) {
          await _customerRepository!.updateCustomer(_toDomainCustomer(customer));
        }
        await _refreshPendingSyncQueue();
        await _triggerImmediateSync(
          action: 'INSERT',
          module: 'customers',
          reference: customer.id,
        );
      } else {
        await _enqueueSync('INSERT', 'customers', customer.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to add customer: $e')),
        );
      }
    }
    return customer;
  }

  Future<bool?> _showPosCheckoutModalFlow() async {
    final availableMethods = _posAvailablePaymentMethods;
    if (availableMethods.isEmpty) return false;

    String currentMethod = _paymentMethodController.text.trim().toUpperCase();
    if (!availableMethods.contains(currentMethod)) {
      currentMethod = 'CASH';
    }

    final total = _calculateCurrentGrandTotal();
    final TextEditingController modalPaidController = TextEditingController(
      text: _amountPaidController.text.trim().isNotEmpty &&
              double.tryParse(_amountPaidController.text.trim()) != null
          ? _amountPaidController.text.trim()
          : total.toStringAsFixed(2),
    );
    final TextEditingController modalCustomerSearchCtrl = TextEditingController();

    // Steps:
    // 0: Payment Method
    // 1: Customer Prompt (Ow / Na? for Cash/Card/Cheque)
    // 2: Customer Selection & Details (Search, Add New, COD rider, Credit limit)
    // 3: Tender & Payment Amount (Amount paid, change)
    // 4: Confirm Bill & Complete Sale
    int currentStep = 0;
    bool customerWasSkipped = false;
    int highlightedCustomerIndex = 0;
    bool promptChoiceAddCustomer = false;

    final FocusNode stepFocusNode = FocusNode();
    final FocusNode paidInputFocus = FocusNode();
    final FocusNode customerSearchFocus = FocusNode();

    StateSetter? dialogSetState;
    BuildContext? activeDialogContext;

    void onMethodChosen() {
      final grandTotal = _calculateCurrentGrandTotal();
      _applyPosPaymentMethod(currentMethod, grandTotal);

      final isCreditOrCodOrInst =
          currentMethod == 'CREDIT' || currentMethod == 'COD' || currentMethod == 'INSTALLMENT';

      if (isCreditOrCodOrInst) {
        customerWasSkipped = false;
        highlightedCustomerIndex = 0;
        dialogSetState?.call(() {
          currentStep = 2; // Jump straight to Customer Selection
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          customerSearchFocus.requestFocus();
        });
      } else {
        if (_selectedCustomerId != null) {
          customerWasSkipped = false;
          dialogSetState?.call(() {
            currentStep = 3;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            paidInputFocus.requestFocus();
            modalPaidController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: modalPaidController.text.length,
            );
          });
        } else {
          promptChoiceAddCustomer = false;
          dialogSetState?.call(() {
            currentStep = 1;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            stepFocusNode.requestFocus();
          });
        }
      }
    }

    void onCustomerPromptAnswer(bool wantsCustomer) {
      if (wantsCustomer) {
        customerWasSkipped = false;
        highlightedCustomerIndex = 0;
        dialogSetState?.call(() {
          currentStep = 2;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          customerSearchFocus.requestFocus();
        });
      } else {
        customerWasSkipped = true;
        dialogSetState?.call(() {
          currentStep = 3;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          paidInputFocus.requestFocus();
          modalPaidController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: modalPaidController.text.length,
          );
        });
      }
    }

    void onCustomerStepNext() {
      final isCreditOrCodOrInst =
          currentMethod == 'CREDIT' || currentMethod == 'COD' || currentMethod == 'INSTALLMENT';

      if (_selectedCustomerId == null) {
        final query = modalCustomerSearchCtrl.text.trim().toLowerCase();
        final matchingCustomers = query.isEmpty
            ? _scopedCustomers.take(5).toList()
            : _scopedCustomers.where((c) =>
                c.name.toLowerCase().contains(query) ||
                c.phone.toLowerCase().contains(query) ||
                c.id.toLowerCase().contains(query)).take(5).toList();

        if (matchingCustomers.isNotEmpty) {
          final validIdx = highlightedCustomerIndex.clamp(0, matchingCustomers.length - 1);
          final c = matchingCustomers[validIdx];
          setState(() {
            _selectedCustomerId = c.id;
            _posCustomerSearchController.text =
                '${c.name} (${c.phone.isEmpty ? 'N/A' : c.phone})';
            if (c.discountPercent > 0) {
              _posInvoiceDiscountType = 'PERCENT';
              _posInvoiceDiscountValue = c.discountPercent;
            }
          });
          dialogSetState?.call(() {});
          return; // Customer is selected; user can inspect or press Enter again to advance to Tender
        }
      }

      if (isCreditOrCodOrInst && _selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$currentMethod සඳහා කරුණාකර Customer කෙනෙක් තෝරන්න හෝ "+ Add New Customer" ඔබන්න.'),
            backgroundColor: Colors.deepOrange,
          ),
        );
        return;
      }

      final grandTotal = _calculateCurrentGrandTotal();
      if (currentMethod == 'CASH') {
        if (modalPaidController.text.trim().isEmpty ||
            double.tryParse(modalPaidController.text.trim()) == null ||
            double.tryParse(modalPaidController.text.trim())! <= 0) {
          modalPaidController.text = grandTotal.toStringAsFixed(2);
        }
      } else if (currentMethod == 'CREDIT') {
        modalPaidController.text = '0.00';
      } else {
        modalPaidController.text = grandTotal.toStringAsFixed(2);
      }

      dialogSetState?.call(() {
        currentStep = 3;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        paidInputFocus.requestFocus();
        modalPaidController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: modalPaidController.text.length,
        );
      });
    }

    void onTenderStepNext() {
      final grandTotal = _calculateCurrentGrandTotal();
      final typed = double.tryParse(modalPaidController.text.trim());
      if (currentMethod == 'CASH') {
        if (typed == null || typed <= 0) {
          modalPaidController.text = grandTotal.toStringAsFixed(2);
        }
      }

      _paymentMethodController.text = currentMethod;
      _amountPaidController.text = modalPaidController.text.trim();

      dialogSetState?.call(() {
        currentStep = 4;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stepFocusNode.requestFocus();
      });
    }

    void completeFinal() {
      _paymentMethodController.text = currentMethod;
      _amountPaidController.text = modalPaidController.text.trim();

      if (activeDialogContext != null && Navigator.canPop(activeDialogContext!)) {
        Navigator.pop(activeDialogContext!, true);
      }
    }

    void goBackOneStep() {
      final isCreditOrCodOrInst =
          currentMethod == 'CREDIT' || currentMethod == 'COD' || currentMethod == 'INSTALLMENT';

      if (currentStep == 4) {
        dialogSetState?.call(() => currentStep = 3);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          paidInputFocus.requestFocus();
          modalPaidController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: modalPaidController.text.length,
          );
        });
      } else if (currentStep == 3) {
        if (customerWasSkipped) {
          dialogSetState?.call(() => currentStep = 1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            stepFocusNode.requestFocus();
          });
        } else if (isCreditOrCodOrInst || _selectedCustomerId != null) {
          dialogSetState?.call(() => currentStep = 2);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            customerSearchFocus.requestFocus();
          });
        } else {
          dialogSetState?.call(() => currentStep = 0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            stepFocusNode.requestFocus();
          });
        }
      } else if (currentStep == 2) {
        if (isCreditOrCodOrInst) {
          dialogSetState?.call(() => currentStep = 0);
        } else {
          dialogSetState?.call(() => currentStep = 1);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stepFocusNode.requestFocus();
        });
      } else if (currentStep == 1) {
        dialogSetState?.call(() => currentStep = 0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stepFocusNode.requestFocus();
        });
      } else {
        if (activeDialogContext != null && Navigator.canPop(activeDialogContext!)) {
          Navigator.pop(activeDialogContext!, false);
        }
      }
    }

    paidInputFocus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
           event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
        onTenderStepNext();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };

    bool handleHardwareKey(KeyEvent event) {
      if (event is! KeyDownEvent) return false;

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        goBackOneStep();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (currentStep == 0) {
          onMethodChosen();
          return true;
        } else if (currentStep == 1) {
          onCustomerPromptAnswer(promptChoiceAddCustomer);
          return true;
        } else if (currentStep == 2) {
          onCustomerStepNext();
          return true;
        } else if (currentStep == 3) {
          onTenderStepNext();
          return true;
        } else if (currentStep == 4) {
          completeFinal();
          return true;
        }
      }

      if (currentStep == 0) {
        final currentIdx = availableMethods.indexOf(currentMethod);
        final count = availableMethods.length;
        const cols = 3;

        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          final nextIdx = (currentIdx + 1) % count;
          currentMethod = availableMethods[nextIdx];
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          final prevIdx = (currentIdx - 1 + count) % count;
          currentMethod = availableMethods[prevIdx];
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          int nextIdx = currentIdx + cols;
          if (nextIdx >= count) {
            nextIdx = currentIdx % cols;
          }
          currentMethod = availableMethods[nextIdx];
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          int nextIdx = currentIdx - cols;
          if (nextIdx < 0) {
            final wrapped = currentIdx + cols;
            nextIdx = wrapped < count ? wrapped : currentIdx;
          }
          currentMethod = availableMethods[nextIdx];
          dialogSetState?.call(() {});
          return true;
        } else if ((event.logicalKey == LogicalKeyboardKey.digit1 ||
                    event.logicalKey == LogicalKeyboardKey.numpad1) &&
                   count > 0) {
          currentMethod = availableMethods[0];
          dialogSetState?.call(() {});
          return true;
        } else if ((event.logicalKey == LogicalKeyboardKey.digit2 ||
                    event.logicalKey == LogicalKeyboardKey.numpad2) &&
                   count > 1) {
          currentMethod = availableMethods[1];
          dialogSetState?.call(() {});
          return true;
        } else if ((event.logicalKey == LogicalKeyboardKey.digit3 ||
                    event.logicalKey == LogicalKeyboardKey.numpad3) &&
                   count > 2) {
          currentMethod = availableMethods[2];
          dialogSetState?.call(() {});
          return true;
        } else if ((event.logicalKey == LogicalKeyboardKey.digit4 ||
                    event.logicalKey == LogicalKeyboardKey.numpad4) &&
                   count > 3) {
          currentMethod = availableMethods[3];
          dialogSetState?.call(() {});
          return true;
        } else if ((event.logicalKey == LogicalKeyboardKey.digit5 ||
                    event.logicalKey == LogicalKeyboardKey.numpad5) &&
                   count > 4) {
          currentMethod = availableMethods[4];
          dialogSetState?.call(() {});
          return true;
        } else if ((event.logicalKey == LogicalKeyboardKey.digit6 ||
                    event.logicalKey == LogicalKeyboardKey.numpad6) &&
                   count > 5) {
          currentMethod = availableMethods[5];
          dialogSetState?.call(() {});
          return true;
        }
      } else if (currentStep == 1) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowUp) {
          promptChoiceAddCustomer = false;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                   event.logicalKey == LogicalKeyboardKey.arrowDown) {
          promptChoiceAddCustomer = true;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
          promptChoiceAddCustomer = false;
          onCustomerPromptAnswer(false);
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
          promptChoiceAddCustomer = true;
          onCustomerPromptAnswer(true);
          return true;
        }
      } else if (currentStep == 2) {
        if (_selectedCustomerId == null) {
          final query = modalCustomerSearchCtrl.text.trim().toLowerCase();
          final matchingCustomers = query.isEmpty
              ? _scopedCustomers.take(5).toList()
              : _scopedCustomers.where((c) =>
                  c.name.toLowerCase().contains(query) ||
                  c.phone.toLowerCase().contains(query) ||
                  c.id.toLowerCase().contains(query)).take(5).toList();

          if (matchingCustomers.isNotEmpty) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              highlightedCustomerIndex = (highlightedCustomerIndex + 1) % matchingCustomers.length;
              dialogSetState?.call(() {});
              return true;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              highlightedCustomerIndex = (highlightedCustomerIndex - 1 + matchingCustomers.length) % matchingCustomers.length;
              dialogSetState?.call(() {});
              return true;
            }
          }
        }
      }

      return false;
    }

    HardwareKeyboard.instance.addHandler(handleHardwareKey);

    bool? dialogResult;
    try {
      dialogResult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dlgCtx) {
          activeDialogContext = dlgCtx;
          final isDark = Theme.of(dlgCtx).brightness == Brightness.dark;

          return StatefulBuilder(
            builder: (context, setDlgState) {
              dialogSetState = setDlgState;
              final grandTotal = _calculateCurrentGrandTotal();
              final rawPaid = double.tryParse(modalPaidController.text.trim()) ?? 0.0;
              final changeAmount = (rawPaid - grandTotal).clamp(0.0, double.infinity);
              final dueAmount = (grandTotal - rawPaid).clamp(0.0, double.infinity);

              final selectedCustomer = _selectedCustomerId == null
                  ? _CustomerItem(
                      id: 'C001',
                      name: 'Walk-in Customer',
                      locationId: _activeLocationForWrites,
                      phone: 'N/A',
                      email: '',
                    )
                  : _scopedCustomers.firstWhere(
                      (c) => c.id == _selectedCustomerId,
                      orElse: () => _CustomerItem(
                        id: 'C001',
                        name: 'Walk-in Customer',
                        locationId: _activeLocationForWrites,
                        phone: 'N/A',
                        email: '',
                      ),
                    );

              IconData getMethodIcon(String k) {
                switch (k.toUpperCase()) {
                  case 'CASH':
                    return Icons.payments_outlined;
                  case 'CARD':
                    return Icons.credit_card_outlined;
                  case 'CHEQUE':
                    return Icons.sticky_note_2_outlined;
                  case 'CREDIT':
                    return Icons.badge_outlined;
                  case 'INSTALLMENT':
                    return Icons.calendar_month_outlined;
                  case 'COD':
                    return Icons.local_shipping_outlined;
                  default:
                    return Icons.payment_outlined;
                }
              }

              return Focus(
                focusNode: stepFocusNode,
                autofocus: true,
                child: AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              currentStep == 0
                                  ? Icons.credit_card_rounded
                                  : currentStep == 1 || currentStep == 2
                                      ? Icons.person_rounded
                                      : currentStep == 3
                                          ? Icons.point_of_sale_rounded
                                          : Icons.task_alt_rounded,
                              color: AppTheme.brandIndigo,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentStep == 0
                                      ? '1. Payment Method (ගෙවීම් ක්‍රමය)'
                                      : currentStep == 1
                                          ? '2. Customer Confirmation'
                                          : currentStep == 2
                                              ? '2. Customer Details (පාරිභෝගිකයා)'
                                              : currentStep == 3
                                                  ? '3. Tender & Payment (ගෙවීම)'
                                                  : '4. Confirm Bill (බිල්පත තහවුරු කිරීම)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentStep == 0
                                      ? 'ගෙවීම් ක්‍රමය තෝරා Enter ඔබන්න'
                                      : currentStep == 1
                                          ? 'Customer කෙනෙක් ඇතුළත් කරනවාද? (Ow/Na)'
                                          : currentStep == 2
                                              ? '$currentMethod සඳහා පාරිභෝගික තොරතුරු තෝරන්න හෝ එක් කරන්න'
                                              : currentStep == 3
                                                  ? 'ගෙවූ මුදල (Amount Paid) තහවුරු කර Enter ඔබන්න'
                                                  : 'බිල්පතේ විස්තර පරීක්ෂා කර සම්පූර්ණ කරන්න',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              _money(grandTotal),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandIndigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStepProgressChip('1. Payment', currentStep > 0, currentStep == 0, isDark),
                          _buildStepProgressDivider(currentStep > 0, isDark),
                          _buildStepProgressChip('2. Customer', currentStep > 2, currentStep == 1 || currentStep == 2, isDark),
                          _buildStepProgressDivider(currentStep > 2, isDark),
                          _buildStepProgressChip('3. Tender', currentStep > 3, currentStep == 3, isDark),
                          _buildStepProgressDivider(currentStep > 3, isDark),
                          _buildStepProgressChip('4. Confirm', currentStep == 4, currentStep == 4, isDark),
                        ],
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 530,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: currentStep == 0
                          ? _buildStep0PaymentMethods(
                              methods: availableMethods,
                              selected: currentMethod,
                              grandTotal: grandTotal,
                              isDark: isDark,
                              onSelect: (m) {
                                currentMethod = m;
                                onMethodChosen();
                              },
                              getIcon: getMethodIcon,
                            )
                          : currentStep == 1
                              ? _buildStep1CustomerPrompt(
                                  isDark: isDark,
                                  wantsCustomer: promptChoiceAddCustomer,
                                  onToggleChoice: (val) {
                                    promptChoiceAddCustomer = val;
                                    setDlgState(() {});
                                  },
                                  onSkip: () => onCustomerPromptAnswer(false),
                                  onAddCustomer: () => onCustomerPromptAnswer(true),
                                )
                              : currentStep == 2
                                  ? _buildStep2CustomerDetails(
                                      currentMethod: currentMethod,
                                      selectedCustomer: selectedCustomer,
                                      isDark: isDark,
                                      grandTotal: grandTotal,
                                      searchController: modalCustomerSearchCtrl,
                                      searchFocusNode: customerSearchFocus,
                                      highlightedCustomerIndex: highlightedCustomerIndex,
                                      setDlgState: setDlgState,
                                      onCustomerPicked: (c) {
                                        setState(() {
                                          _selectedCustomerId = c.id;
                                          _posCustomerSearchController.text =
                                              '${c.name} (${c.phone.isEmpty ? 'N/A' : c.phone})';
                                          if (c.discountPercent > 0) {
                                            _posInvoiceDiscountType = 'PERCENT';
                                            _posInvoiceDiscountValue = c.discountPercent;
                                          }
                                        });
                                        setDlgState(() {});
                                      },
                                      onAddNewCustomer: () async {
                                        final c = await _handleAddNewCustomerFromPos();
                                        if (c != null) {
                                          setDlgState(() {});
                                        }
                                      },
                                      onRemoveCustomer: () {
                                        setState(() {
                                          _selectedCustomerId = null;
                                          _posCustomerSearchController.clear();
                                        });
                                        highlightedCustomerIndex = 0;
                                        setDlgState(() {});
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          customerSearchFocus.requestFocus();
                                        });
                                      },
                                      onSubmitted: (_) => onCustomerStepNext(),
                                    )
                                  : currentStep == 3
                                      ? _buildStep3TenderInput(
                                          method: currentMethod,
                                          grandTotal: grandTotal,
                                          paidController: modalPaidController,
                                          paidInputFocus: paidInputFocus,
                                          rawPaid: rawPaid,
                                          changeAmount: changeAmount,
                                          dueAmount: dueAmount,
                                          isDark: isDark,
                                          onExact: () {
                                            modalPaidController.text = grandTotal.toStringAsFixed(2);
                                            setDlgState(() {});
                                          },
                                          onChip: (val) {
                                            modalPaidController.text = val.toStringAsFixed(2);
                                            setDlgState(() {});
                                          },
                                          onSubmitted: (_) => onTenderStepNext(),
                                          setDlgState: setDlgState,
                                          selectedCustomer: selectedCustomer,
                                        )
                                      : _buildStep4BillConfirmation(
                                          method: currentMethod,
                                          grandTotal: grandTotal,
                                          rawPaid: rawPaid,
                                          changeAmount: changeAmount,
                                          dueAmount: dueAmount,
                                          isDark: isDark,
                                          selectedCustomer: selectedCustomer,
                                          cartItemCount: _cart.length,
                                        ),
                    ),
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: goBackOneStep,
                      icon: Icon(
                        currentStep > 0 ? Icons.arrow_back_rounded : Icons.close_rounded,
                        size: 16,
                      ),
                      label: Text(
                        currentStep > 0
                            ? 'Back (Esc) • ආපසු'
                            : 'Cancel (Esc) • අවලංගු කරන්න',
                      ),
                    ),
                    if (currentStep == 0)
                      ElevatedButton.icon(
                        onPressed: onMethodChosen,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Next (Enter) • ඉදිරියට'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandIndigo,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else if (currentStep == 1)
                      ElevatedButton.icon(
                        onPressed: () => onCustomerPromptAnswer(promptChoiceAddCustomer),
                        icon: Icon(
                          promptChoiceAddCustomer
                              ? Icons.person_add_alt_1_rounded
                              : Icons.flash_on_rounded,
                          size: 16,
                        ),
                        label: Text(
                          promptChoiceAddCustomer
                              ? 'Add Customer (Enter) • ඔව්'
                              : 'Skip (Enter) • නැත (Walk-in)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: promptChoiceAddCustomer
                              ? const Color(0xFF10B981)
                              : AppTheme.brandIndigo,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else if (currentStep == 2)
                      ElevatedButton.icon(
                        onPressed: onCustomerStepNext,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Next: Tender (Enter) • ඉදිරියට'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandIndigo,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else if (currentStep == 3)
                      ElevatedButton.icon(
                        onPressed: onTenderStepNext,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Next: Confirm (Enter) • ඉදිරියට'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandIndigo,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: completeFinal,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: Text('Complete Sale (Enter) • ${_money(grandTotal)}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      HardwareKeyboard.instance.removeHandler(handleHardwareKey);
      modalPaidController.dispose();
      modalCustomerSearchCtrl.dispose();
      paidInputFocus.dispose();
      stepFocusNode.dispose();
      customerSearchFocus.dispose();
    }
    return dialogResult;
  }

  Widget _buildStepProgressChip(String label, bool isCompleted, bool isActive, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.brandIndigo.withValues(alpha: 0.15)
              : isCompleted
                  ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? AppTheme.brandIndigo
                : isCompleted
                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                    : (isDark ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? AppTheme.brandIndigo
                : (isDark ? Colors.grey.shade400 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressDivider(bool isCompleted, bool isDark) {
    return Container(
      width: 10,
      height: 2,
      color: isCompleted
          ? AppTheme.brandIndigo
          : (isDark ? Colors.white12 : Colors.black12),
    );
  }

  Widget _buildStep0PaymentMethods({
    required List<String> methods,
    required String selected,
    required double grandTotal,
    required bool isDark,
    required ValueChanged<String> onSelect,
    required IconData Function(String) getIcon,
  }) {
    return Column(
      key: const ValueKey(0),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'තෝරාගැනීමට Arrow keys (← → ↑ ↓) හෝ අංක (1-6) ඔබන්න:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < methods.length; i++)
              () {
                final m = methods[i];
                final isSel = m == selected;
                return InkWell(
                  canRequestFocus: false,
                  onTap: () => onSelect(m),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 155,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (isDark
                              ? AppTheme.brandIndigo.withValues(alpha: 0.25)
                              : AppTheme.brandIndigo.withValues(alpha: 0.12))
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel
                            ? AppTheme.brandIndigo
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppTheme.brandIndigo.withValues(alpha: 0.2)
                                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            getIcon(m),
                            size: 18,
                            color: isSel ? AppTheme.brandIndigo : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${i + 1}. ',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? AppTheme.brandIndigo : Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      m,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                        color: isSel
                                            ? (isDark ? Colors.white : AppTheme.brandIndigo)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isSel)
                                const Text(
                                  'Selected (තෝරා ඇත)',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }(),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1CustomerPrompt({
    required bool isDark,
    required bool wantsCustomer,
    required ValueChanged<bool> onToggleChoice,
    required VoidCallback onSkip,
    required VoidCallback onAddCustomer,
  }) {
    Widget buildChoiceCard({
      required bool isSelected,
      required Color activeColor,
      required IconData icon,
      required String title,
      required String shortcutHint,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          canRequestFocus: false,
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor
                  : (isDark ? const Color(0xFF0F172A) : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                width: isSelected ? 2.0 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? Colors.white : activeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    shortcutHint,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 32,
                  color: AppTheme.brandIndigo,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add Customer to this Bill?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'බිල්පතට පාරිභෝගිකයෙකුගේ තොරතුරු සම්බන්ධ කරනවාද?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandIndigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.brandIndigo.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_outlined, size: 14, color: AppTheme.brandIndigo),
                    const SizedBox(width: 5),
                    Text(
                      '◄ ► ඊතල (Arrow keys) මඟින් තෝරා Enter ඔබන්න  •  [N / Y කෙටිමං]',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandIndigo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  buildChoiceCard(
                    isSelected: !wantsCustomer,
                    activeColor: AppTheme.brandIndigo,
                    icon: Icons.flash_on_rounded,
                    title: 'නැත (Walk-in)',
                    shortcutHint: !wantsCustomer ? '[Enter / N] • තෝරා ඇත' : '[N] කෙටිමඟ',
                    onTap: onSkip,
                  ),
                  const SizedBox(width: 12),
                  buildChoiceCard(
                    isSelected: wantsCustomer,
                    activeColor: const Color(0xFF10B981),
                    icon: Icons.person_search_rounded,
                    title: 'ඔව් (Add Customer)',
                    shortcutHint: wantsCustomer ? '[Enter / Y] • තෝරා ඇත' : '[Y] කෙටිමඟ',
                    onTap: onAddCustomer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2CustomerDetails({
    required String currentMethod,
    required _CustomerItem selectedCustomer,
    required bool isDark,
    required double grandTotal,
    required TextEditingController searchController,
    required FocusNode searchFocusNode,
    required int highlightedCustomerIndex,
    required StateSetter setDlgState,
    required ValueChanged<_CustomerItem> onCustomerPicked,
    required VoidCallback onAddNewCustomer,
    required VoidCallback onRemoveCustomer,
    ValueChanged<String>? onSubmitted,
  }) {
    final bool hasCustomer = _selectedCustomerId != null;
    final double outstanding = hasCustomer ? _customerOutstandingBalance(selectedCustomer.id) : 0.0;
    final oldestOverdue = hasCustomer ? _oldestOverdueDateForCustomer(selectedCustomer) : null;
    final bool hasOverdue = oldestOverdue != null;

    final query = searchController.text.trim().toLowerCase();
    final matchingCustomers = query.isEmpty
        ? _scopedCustomers.take(5).toList()
        : _scopedCustomers.where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.phone.toLowerCase().contains(query) ||
            c.id.toLowerCase().contains(query)).take(5).toList();

    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasCustomer) ...[
          // Search input & Add Customer row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Search Customer (නම, දුරකථන, ID)',
                    hintText: 'Customer සෙවීමට type කරන්න හෝ ↑ ↓ ඊතල ඔබන්න...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              searchController.clear();
                              setDlgState(() {});
                            },
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setDlgState(() {}),
                  onSubmitted: onSubmitted,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAddNewCustomer,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('+ Add New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Matches list
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: matchingCustomers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_off_outlined, color: Colors.grey, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            query.isEmpty ? 'No customers found.' : 'No customer matches "$query".',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: onAddNewCustomer,
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Add as New Customer', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: matchingCustomers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = matchingCustomers[index];
                      final isHighlighted = index == highlightedCustomerIndex;
                      return InkWell(
                        canRequestFocus: false,
                        onTap: () => onCustomerPicked(c),
                        child: Container(
                          color: isHighlighted
                              ? (isDark
                                  ? AppTheme.brandIndigo.withValues(alpha: 0.25)
                                  : AppTheme.brandIndigo.withValues(alpha: 0.12))
                              : Colors.transparent,
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: isHighlighted
                                  ? AppTheme.brandIndigo
                                  : AppTheme.brandIndigo.withValues(alpha: 0.15),
                              child: Text(
                                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isHighlighted ? Colors.white : AppTheme.brandIndigo,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: TextStyle(
                                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13,
                                      color: isHighlighted
                                          ? (isDark ? Colors.white : AppTheme.brandIndigo)
                                          : null,
                                    ),
                                  ),
                                ),
                                if (isHighlighted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandIndigo,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Enter තෝරන්න',
                                      style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${c.phone.isNotEmpty ? c.phone : 'No Phone'} • ${c.address.isNotEmpty ? c.address : 'No Address'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isHighlighted
                                    ? (isDark ? Colors.grey.shade300 : const Color(0xFF334155))
                                    : Colors.grey,
                              ),
                            ),
                            trailing: Icon(
                              isHighlighted ? Icons.check_circle : Icons.check_circle_outline,
                              size: 18,
                              color: isHighlighted ? AppTheme.brandIndigo : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ] else ...[
          // Selected customer card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCustomer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Phone: ${selectedCustomer.phone.isNotEmpty ? selectedCustomer.phone : 'N/A'} • ID: ${selectedCustomer.id}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text('Change Customer', style: TextStyle(fontSize: 12)),
                      onPressed: onRemoveCustomer,
                    ),
                  ],
                ),
                if (selectedCustomer.address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Address: ${selectedCustomer.address}',
                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : const Color(0xFF475569)),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Outstanding: ${_money(outstanding)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: outstanding > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Credit Limit: ${_money(selectedCustomer.creditLimit)}',
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Payment Method-specific requirements & warnings
        if (currentMethod == 'CREDIT') ...[
          const SizedBox(height: 10),
          if (hasOverdue)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Overdue Warning: මෙම පාරිභෝගිකයාට ගෙවීමට ප්‍රමාද වූ ණය පවතී (${_formatDate(oldestOverdue)} සිට).',
                      style: const TextStyle(fontSize: 11.5, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          if (hasCustomer && selectedCustomer.creditLimit > 0 && (outstanding + grandTotal) > selectedCustomer.creditLimit) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Credit Limit Warning: මෙම බිලත් සමඟ ණය සීමාව (${_money(selectedCustomer.creditLimit)}) ඉක්මවා යයි.',
                      style: const TextStyle(fontSize: 11.5, color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else if (currentMethod == 'COD') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, color: Colors.amber, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'COD Delivery Rider Assignment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: 'Assign Delivery Driver',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  value: _posSelectedDeliveryDriverId,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Unassigned (පසුව බාරදෙන්න)', style: TextStyle(fontSize: 12)),
                    ),
                    ..._scopedUsers
                        .where((u) => u.active && (u.role.toLowerCase() == 'driver' || u.role.toLowerCase() == 'delivery'))
                        .map((u) => DropdownMenuItem<String?>(
                              value: u.id,
                              child: Text(u.name, style: const TextStyle(fontSize: 12)),
                            )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _posSelectedDeliveryDriverId = val;
                    });
                    setDlgState(() {});
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Checkbox(
                      value: _posCodPaymentCollectedUpfront,
                      onChanged: (val) {
                        setState(() {
                          _posCodPaymentCollectedUpfront = val ?? false;
                        });
                        setDlgState(() {});
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Payment collected upfront (දැනටමත් මුදල් ගෙවා ඇත)',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else if (currentMethod == 'INSTALLMENT') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Installment Sale: Customer තොරතුරු සහ දුරකථන අංකය නිවැරදි බව තහවුරු කරගන්න.',
                    style: TextStyle(fontSize: 11.5, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3TenderInput({
    required String method,
    required double grandTotal,
    required TextEditingController paidController,
    required FocusNode paidInputFocus,
    required double rawPaid,
    required double changeAmount,
    required double dueAmount,
    required bool isDark,
    required VoidCallback onExact,
    required ValueChanged<double> onChip,
    required ValueChanged<String> onSubmitted,
    required StateSetter setDlgState,
    required _CustomerItem selectedCustomer,
  }) {
    final allowsManual = _allowsManualPaidAmount(method);

    return Column(
      key: const ValueKey(3),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.brandIndigo.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        method,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.brandIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${selectedCustomer.name}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Bill Grand Total', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                Text(
                  _money(grandTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (allowsManual) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: paidController,
                  focusNode: paidInputFocus,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Amount Paid (ගෙවූ මුදල)',
                    prefixText: 'LKR ',
                    hintText: grandTotal.toStringAsFixed(2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        paidController.clear();
                        setDlgState(() {});
                      },
                    ),
                  ),
                  onChanged: (_) => setDlgState(() {}),
                  onSubmitted: onSubmitted,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                focusNode: FocusNode(canRequestFocus: false),
                onPressed: onExact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Exact Cash', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final chipAmount in [100.0, 500.0, 1000.0, 5000.0, 10000.0])
                ActionChip(
                  focusNode: FocusNode(canRequestFocus: false),
                  label: Text('Rs. ${chipAmount.toInt()}'),
                  labelStyle: const TextStyle(fontSize: 11.5),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () => onChip(chipAmount),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: rawPaid >= grandTotal
                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                  : (isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: rawPaid >= grandTotal
                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      rawPaid >= grandTotal
                          ? Icons.change_circle_rounded
                          : Icons.account_balance_wallet_outlined,
                      color: rawPaid >= grandTotal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rawPaid >= grandTotal
                          ? 'Change to Return (ඉතිරි මුදල):'
                          : 'Due Balance (ඉතිරි ණය):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: rawPaid >= grandTotal
                            ? (isDark ? Colors.green.shade200 : const Color(0xFF065F46))
                            : (isDark ? Colors.orange.shade200 : const Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
                Text(
                  _money(rawPaid >= grandTotal ? changeAmount : dueAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: rawPaid >= grandTotal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  method == 'CREDIT'
                      ? 'Credit Sale (ණය මුදල)'
                      : '$method Payment',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  _money(grandTotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.brandIndigo,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (method == 'CHEQUE') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _chequeNumberController,
            decoration: const InputDecoration(
              labelText: 'Cheque Number (චෙක්පත් අංකය)',
              prefixIcon: Icon(Icons.sticky_note_2_outlined, size: 20),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep4BillConfirmation({
    required String method,
    required double grandTotal,
    required double rawPaid,
    required double changeAmount,
    required double dueAmount,
    required bool isDark,
    required _CustomerItem selectedCustomer,
    required int cartItemCount,
  }) {
    return Column(
      key: const ValueKey(4),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Invoice Items', '$cartItemCount items in cart', isDark),
              const Divider(height: 12),
              _buildSummaryRow('Payment Method', method, isDark, boldValue: true),
              const Divider(height: 12),
              _buildSummaryRow('Customer', selectedCustomer.name, isDark),
              if (selectedCustomer.phone.isNotEmpty && selectedCustomer.phone != 'N/A')
                _buildSummaryRow('Customer Phone', selectedCustomer.phone, isDark),
              const Divider(height: 12),
              _buildSummaryRow('Grand Total (මුළු එකතුව)', _money(grandTotal), isDark,
                  boldValue: true, valueColor: AppTheme.brandIndigo, valueSize: 16),
              if (_allowsManualPaidAmount(method)) ...[
                const Divider(height: 12),
                _buildSummaryRow('Amount Paid (ගෙවූ මුදල)', _money(rawPaid), isDark),
                const Divider(height: 12),
                _buildSummaryRow('Change to Return (ඉතිරි)', _money(changeAmount), isDark,
                    boldValue: true, valueColor: const Color(0xFF10B981), valueSize: 15),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF10B981), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'මෙම බිල්පත සම්පූර්ණ කර අවසන් කිරීමට "Complete Sale (Enter)" ඔබන්න.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    bool boldValue = false,
    Color? valueColor,
    double valueSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: boldValue ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }



  Future<_ShoppingBagSelectionResult?> _showShoppingBagConfirmationDialog({
    required BuildContext parentContext,
    required double currentGrandTotal,
    required String paymentMethod,
  }) async {
    final List<_ShoppingBagEntry> bagEntries = [
      _ShoppingBagEntry(
        id: 'BAG_SM_5',
        name: 'Shopping Bag (Small - කුඩා)',
        price: _posBagPriceSmall,
        quantity: 0,
        label: 'Small Bag (කුඩා)',
        shortcutKey: '1',
      ),
      _ShoppingBagEntry(
        id: 'BAG_MD_10',
        name: 'Shopping Bag (Medium - මධ්‍යම)',
        price: _posBagPriceMedium,
        quantity: 0,
        label: 'Medium Bag (මධ්‍යම)',
        shortcutKey: '2',
      ),
      _ShoppingBagEntry(
        id: 'BAG_LG_20',
        name: 'Shopping Bag (Large - විශාල)',
        price: _posBagPriceLarge,
        quantity: 0,
        label: 'Large Bag (විශාල)',
        shortcutKey: '3',
      ),
      _ShoppingBagEntry(
        id: 'BAG_CUSTOM',
        name: 'Shopping Bag (Custom - වෙනත්)',
        price: _posBagPriceCustom,
        quantity: 0,
        label: 'Custom Bag (වෙනත්)',
        shortcutKey: '4',
        isCustom: true,
      ),
    ];

    bool addBags = false;
    int focusedBagIndex = 0;
    final customPriceController = TextEditingController(
      text: _posBagPriceCustom.toStringAsFixed(0),
    );
    final FocusNode customPriceFocus = FocusNode();

    StateSetter? dialogSetState;
    BuildContext? activeDialogContext;
    bool isPopped = false;

    void safePop([_ShoppingBagSelectionResult? res]) {
      if (isPopped) return;
      isPopped = true;
      if (activeDialogContext != null && Navigator.canPop(activeDialogContext!)) {
        Navigator.pop(activeDialogContext!, res);
      }
    }

    bool handleHardwareKey(KeyEvent event) {
      if (event is! KeyDownEvent) return false;

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        safePop(null);
        return true;
      }

      // If user is editing the custom price, do not intercept digits/shortcuts
      if (customPriceFocus.hasFocus) {
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          customPriceFocus.unfocus();
          return true;
        }
        return false;
      }

      if (!addBags) {
        // Choice mode: "නැත" vs "ඔව්"
        if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.keyY) {
          addBags = true;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                   event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                   event.logicalKey == LogicalKeyboardKey.keyN) {
          safePop(_ShoppingBagSelectionResult(hasBags: false));
          return true;
        }
      } else {
        // Bag selection mode
        if (event.logicalKey == LogicalKeyboardKey.keyN) {
          addBags = false;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          focusedBagIndex = (focusedBagIndex - 1 + bagEntries.length) % bagEntries.length;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          focusedBagIndex = (focusedBagIndex + 1) % bagEntries.length;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                   event.logicalKey == LogicalKeyboardKey.add ||
                   event.logicalKey == LogicalKeyboardKey.equal) {
          bagEntries[focusedBagIndex].quantity++;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                   event.logicalKey == LogicalKeyboardKey.minus) {
          if (bagEntries[focusedBagIndex].quantity > 0) {
            bagEntries[focusedBagIndex].quantity--;
            dialogSetState?.call(() {});
          }
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.digit1 ||
                   event.logicalKey == LogicalKeyboardKey.numpad1) {
          bagEntries[0].quantity++;
          focusedBagIndex = 0;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
                   event.logicalKey == LogicalKeyboardKey.numpad2) {
          bagEntries[1].quantity++;
          focusedBagIndex = 1;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
                   event.logicalKey == LogicalKeyboardKey.numpad3) {
          bagEntries[2].quantity++;
          focusedBagIndex = 2;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
                   event.logicalKey == LogicalKeyboardKey.numpad4) {
          bagEntries[3].quantity++;
          focusedBagIndex = 3;
          dialogSetState?.call(() {});
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                   event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          final totalQty = bagEntries.fold<int>(0, (s, b) => s + b.quantity);
          if (totalQty == 0) {
            safePop(_ShoppingBagSelectionResult(hasBags: false));
          } else {
            safePop(
              _ShoppingBagSelectionResult(
                hasBags: true,
                bags: bagEntries.where((b) => b.quantity > 0).toList(),
              ),
            );
          }
          return true;
        }
      }

      return false;
    }

    HardwareKeyboard.instance.addHandler(handleHardwareKey);

    try {
      final result = await showDialog<_ShoppingBagSelectionResult>(
        context: parentContext,
        barrierDismissible: false,
        builder: (dlgCtx) {
          activeDialogContext = dlgCtx;
          final isDark = Theme.of(dlgCtx).brightness == Brightness.dark;

          return StatefulBuilder(
            builder: (context, setDlgState) {
              dialogSetState = setDlgState;
              final totalBagCount = bagEntries.fold<int>(0, (s, b) => s + b.quantity);
              final totalBagAmount = bagEntries.fold<double>(0.0, (s, b) => s + (b.price * b.quantity));
              final newGrandTotal = currentGrandTotal + (addBags ? totalBagAmount : 0.0);

              return Dialog(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: 580,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppTheme.brandIndigo,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Shopping Bag Charges (ෂොපින් බෑග්)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'මෙම Sale එක සඳහා Shopping Bag ගාස්තු එකතු කරනවාද?',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => safePop(null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Choice row: [නැත (No Bags)] vs [ඔව් (Add Bags)]
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setDlgState(() => addBags = false);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: !addBags
                                      ? (isDark ? Colors.red.withValues(alpha: 0.18) : const Color(0xFFFEF2F2))
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: !addBags
                                        ? Colors.redAccent
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: !addBags ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      !addBags ? Icons.cancel_rounded : Icons.radio_button_unchecked,
                                      color: !addBags ? Colors.redAccent : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'නැත (No Bags)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: !addBags ? Colors.redAccent : (isDark ? Colors.white : Colors.black87),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ගාස්තු නැත [Enter / N]',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setDlgState(() => addBags = true);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: addBags
                                      ? (isDark ? AppTheme.brandIndigo.withValues(alpha: 0.22) : const Color(0xFFEEF2FF))
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: addBags
                                        ? AppTheme.brandIndigo
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: addBags ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      addBags ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                      color: addBags ? AppTheme.brandIndigo : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ඔව් (Add Bags)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: addBags ? AppTheme.brandIndigo : (isDark ? Colors.white : Colors.black87),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'බෑග් එකතු කරන්න [Y / →]',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
                        ],
                      ),
                      const SizedBox(height: 16),

                      // If !addBags: Show fast checkout guide
                      if (!addBags) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'බෑග් ගාස්තු එකතු නොකර Sale එක සම්පූර්ණ කිරීමට Enter ඔබන්න.\nබෑග් එකතු කිරීමට නම් ඉහත "ඔව්" තෝරන්න හෝ [Y] ඔබන්න.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // 4 Bag Selection Cards
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (int i = 0; i < bagEntries.length; i++)
                              () {
                                final bag = bagEntries[i];
                                final isFocused = focusedBagIndex == i;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    setDlgState(() {
                                      focusedBagIndex = i;
                                    });
                                  },
                                  child: Container(
                                    width: 256,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isFocused
                                          ? (isDark
                                              ? AppTheme.brandIndigo.withValues(alpha: 0.18)
                                              : const Color(0xFFEEF2FF))
                                          : (isDark
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isFocused
                                            ? AppTheme.brandIndigo
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        width: isFocused ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '[${bag.shortcutKey}]',
                                                    style: const TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                      color: AppTheme.brandIndigo,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  bag.label,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (bag.quantity > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _money(bag.totalPrice),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11.5,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              'මිල: ',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                              ),
                                            ),
                                            if (bag.isCustom)
                                              SizedBox(
                                                width: 80,
                                                height: 28,
                                                child: TextField(
                                                  controller: customPriceController,
                                                  focusNode: customPriceFocus,
                                                  keyboardType: TextInputType.number,
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                  decoration: const InputDecoration(
                                                    prefixText: 'Rs. ',
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  onChanged: (val) {
                                                    final p = double.tryParse(val) ?? 0.0;
                                                    _posBagPriceCustom = p;
                                                    bag.price = p;
                                                    setDlgState(() {});
                                                  },
                                                ),
                                              )
                                            else
                                              Text(
                                                _money(bag.price),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            const Spacer(),
                                            // Stepper [-] Qty [+]
                                            InkWell(
                                              onTap: () {
                                                if (bag.quantity > 0) {
                                                  setDlgState(() {
                                                    bag.quantity--;
                                                    focusedBagIndex = i;
                                                  });
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(4),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.remove, size: 14),
                                              ),
                                            ),
                                            Container(
                                              constraints: const BoxConstraints(minWidth: 28),
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                '${bag.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setDlgState(() {
                                                  bag.quantity++;
                                                  focusedBagIndex = i;
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(4),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.brandIndigo,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.add, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Navigation keyboard hints
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Shortcuts: [← →] තෝරන්න • [↑ / +] එකතු කරන්න • [↓ / -] අඩු කරන්න • [1-4] Quick Add',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Grand total display bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 18, color: AppTheme.brandIndigo),
                                const SizedBox(width: 8),
                                Text(
                                  addBags && totalBagCount > 0
                                      ? 'Bags: $totalBagCount pcs (+${_money(totalBagAmount)})'
                                      : 'Shopping Bags: None (Rs. 0.00)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Grand Total: ${_money(newGrandTotal)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: addBags && totalBagCount > 0
                                    ? const Color(0xFF10B981)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Action Buttons
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => safePop(null),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text('Back (Esc) • ආපසු'),
                          ),
                          const Spacer(),
                          if (addBags) ...[
                            OutlinedButton(
                              onPressed: () {
                                setDlgState(() => addBags = false);
                              },
                              child: const Text('Cancel Bags (N)'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                final totalQty = bagEntries.fold<int>(0, (s, b) => s + b.quantity);
                                if (totalQty == 0) {
                                  safePop(_ShoppingBagSelectionResult(hasBags: false));
                                } else {
                                  safePop(
                                    _ShoppingBagSelectionResult(
                                      hasBags: true,
                                      bags: bagEntries.where((b) => b.quantity > 0).toList(),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: Text(
                                totalBagCount > 0
                                    ? 'Complete Sale with Bags • [Enter]'
                                    : 'Complete Sale (0 Bags) • [Enter]',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                            ),
                          ] else ...[
                            ElevatedButton.icon(
                              onPressed: () {
                                safePop(_ShoppingBagSelectionResult(hasBags: false));
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('Complete Sale (No Bags) • [Enter]'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandIndigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      return result;
    } finally {
      HardwareKeyboard.instance.removeHandler(handleHardwareKey);
      customPriceController.dispose();
      customPriceFocus.dispose();
    }
  }

  static bool _isPosCheckoutProcessing = false;

  Future<void> _processPosCheckout() async {
    if (_isPosCheckoutProcessing) return;
    _isPosCheckoutProcessing = true;
    try {
      final isAllLocations =
          _selectedLocationScope == _DashboardScreenState._allLocationsLabel;

      if (isAllLocations) {
        await _showPosValidationGuideDialog(
          title: 'Branch / Location Selection Required',
          sinhalaTitle: 'අලෙවිසැල් ශාඛාව (Branch) තෝරන්න',
          reason: 'ඔබ දැනට සිටින්නේ "All Locations" (සියලුම ශාඛා) බැලීමේ ආකාරයේය. තොග අඩු කිරීමට සහ මුදල් රෙජිස්ටරය නිවැරදිව පවත්වා ගැනීමට නිශ්චිත ශාඛාවක් තෝරාගත යුතුය.',
          guide: 'ඉහළ ඇති Location dropdown එකෙන් ඔබගේ අලෙවිසැල් ශාඛාව (Branch) තෝරා ගන්න.',
          icon: Icons.store_mall_directory_outlined,
          color: Colors.deepOrange,
        );
        return;
      }

      final cartItems = _cart.entries
          .map((e) {
            final product = _resolveCartItemProduct(e.key);
            if (product == null) return null;
            final discount =
                _posLineDiscounts[e.key] ?? _autoDiscountForProduct(product);
            return _CartLine(
              product: product,
              qty: e.value,
              discountValue: discount?.value ?? 0.0,
              discountType: discount?.type ?? 'FIXED',
              discountLabel: discount?.label ?? '',
            );
          })
          .whereType<_CartLine>()
          .toList();

      if (cartItems.isEmpty) {
        await _showPosValidationGuideDialog(
          title: 'Cart is Empty',
          sinhalaTitle: 'Cart එක හිස්ව පවතී',
          reason: 'Checkout කිරීමට පෙර අවම වශයෙන් එක් භාණ්ඩයක් හෝ Cart එකට ඇතුළත් කළ යුතුය.',
          guide: 'භාණ්ඩ ලැයිස්තුවෙන් හෝ Barcode Scanner එක මඟින් භාණ්ඩ Cart එකට එක් කරන්න.',
          icon: Icons.shopping_cart_outlined,
          color: Colors.amber.shade800,
        );
        return;
      }

      final rawSubtotal = cartItems.fold<double>(0, (s, c) => s + c.totalPrice);
      double invoiceDiscountAmount = 0.0;
      if (_posInvoiceDiscountType == 'PERCENT') {
        invoiceDiscountAmount = rawSubtotal * (_posInvoiceDiscountValue / 100);
      } else {
        invoiceDiscountAmount = _posInvoiceDiscountValue;
      }
      final subtotal = (rawSubtotal - invoiceDiscountAmount).clamp(
        0.0,
        double.infinity,
      );

      final taxRate = double.tryParse(_taxRate) ?? 0;
      final taxAmount = _posApplyTax ? subtotal * (taxRate / 100) : 0.0;
      final paymentMethod = _paymentMethodController.text.isEmpty
          ? 'CASH'
          : _paymentMethodController.text;
      final isCodPayment = paymentMethod == 'COD';
      final shippingCharges =
          (_enableShippingCharges || isCodPayment) ? _posShippingCharges : 0.0;
      final grandTotal = subtotal + taxAmount + shippingCharges;
      final isChequePayment = paymentMethod == 'CHEQUE';
      final isInstallmentPayment = paymentMethod == 'INSTALLMENT';

      final selectedCustomer = _selectedCustomerId == null
          ? _CustomerItem(
              id: 'C001',
              name: 'Walk-in Customer',
              locationId: _activeLocationForWrites,
              phone: 'N/A',
              email: '',
            )
          : _scopedCustomers.firstWhere(
              (c) => c.id == _selectedCustomerId,
              orElse: () => _CustomerItem(
                id: 'C001',
                name: 'Walk-in Customer',
                locationId: _activeLocationForWrites,
                phone: 'N/A',
                email: '',
              ),
            );
      final selectedCustomerOutstanding =
          _customerOutstandingBalance(selectedCustomer.id);

      final installmentCount = _posInstallmentCount.clamp(1, 60).toInt();
      final installmentIntervalDays =
          _posInstallmentIntervalDays.clamp(1, 365).toInt();


                          if (isAllLocations) {
                            await _showPosValidationGuideDialog(
                              title: 'Branch / Location Selection Required',
                              sinhalaTitle: 'අලෙවිසැල් ශාඛාව (Branch) තෝරන්න',
                              reason: 'ඔබ දැනට සිටින්නේ "All Locations" (සියලුම ශාඛා) බැලීමේ ආකාරයේය. තොග අඩු කිරීමට සහ මුදල් රෙජිස්ටරය නිවැරදිව පවත්වා ගැනීමට නිශ්චිත ශාඛාවක් තෝරාගත යුතුය.',
                              guide: 'ඉහළ ඇති Location dropdown එකෙන් ඔබගේ අලෙවිසැල් ශාඛාව (Branch) තෝරා ගන්න.',
                              icon: Icons.store_mall_directory_outlined,
                              color: Colors.deepOrange,
                            );
                            return;
                          }

                          if (cartItems.isEmpty) {
                            await _showPosValidationGuideDialog(
                              title: 'Cart is Empty',
                              sinhalaTitle: 'Cart එක හිස්ව පවතී',
                              reason: 'Checkout කිරීමට පෙර අවම වශයෙන් එක් භාණ්ඩයක් හෝ Cart එකට ඇතුළත් කළ යුතුය.',
                              guide: 'භාණ්ඩ ලැයිස්තුවෙන් හෝ Barcode Scanner එක මඟින් භාණ්ඩ Cart එකට එක් කරන්න.',
                              icon: Icons.shopping_cart_outlined,
                              color: Colors.amber.shade800,
                            );
                            return;
                          }

                          // Enforce an active cashier session exists before checking out
                          final activeSession = _activeSessionFor(
                            _currentUserId,
                          );
                          if (activeSession == null) {
                            await _triggerOpenRegisterDialog();
                            if (_activeSessionFor(_currentUserId) ==
                                null) {
                              return;
                            }
                          }

                                final linkedReturnIds = <String>{
                                  for (final line in cartItems)
                                    if (_isReturnStoreCreditCartItemId(
                                      line.product.id,
                                    ))
                                      _returnIdFromStoreCreditCartItemId(
                                            line.product.id,
                                          ) ??
                                          '',
                                }..remove('');
                                final hasReturnStoreCredit =
                                    linkedReturnIds.isNotEmpty;
                                final replacementItemsTotal = cartItems
                                    .where(
                                      (line) => !_isReturnStoreCreditCartItemId(
                                        line.product.id,
                                      ),
                                    )
                                    .fold<double>(
                                      0,
                                      (sum, line) =>
                                          sum + (line.product.price * line.qty),
                                    );
                                final isCreditSale = _isCreditPaymentMethod(
                                  paymentMethod,
                                );
                                final chequeNumber = _chequeNumberController
                                    .text
                                    .trim();
                                final rawPaidText =
                                    _amountPaidController.text.trim();
                                final parsedPaid =
                                    double.tryParse(rawPaidText);
                                final double paidAmount;
                                if (paymentMethod == 'CASH' &&
                                    (rawPaidText.isEmpty ||
                                        parsedPaid == null ||
                                        parsedPaid == 0)) {
                                  // Cashier hasn't manually entered custom cash tender -> default to exact cash!
                                  paidAmount = grandTotal;
                                } else {
                                  paidAmount = parsedPaid ?? 0.0;
                                }
                                final sanitizedPaidAmount =
                                    paymentMethod == 'COD'
                                        ? (_posCodPaymentCollectedUpfront
                                              ? grandTotal
                                              : 0.0)
                                        : (_allowsManualPaidAmount(paymentMethod)
                                                  ? paidAmount
                                                  : grandTotal)
                                              .clamp(0, double.infinity)
                                              .toDouble();
                                final outstandingAmount =
                                    paymentMethod == 'COD'
                                        ? (_posCodPaymentCollectedUpfront
                                              ? 0.0
                                              : grandTotal)
                                        : (grandTotal - sanitizedPaidAmount)
                                              .clamp(0, double.infinity)
                                              .toDouble();
                                final balanceAmount =
                                    (grandTotal - sanitizedPaidAmount)
                                        .clamp(0, double.infinity)
                                        .toDouble();

                                if (hasReturnStoreCredit &&
                                    replacementItemsTotal <= 0) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Store-credit returns need at least one replacement item before checkout.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (hasReturnStoreCredit && grandTotal < 0) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Replacement sale total cannot be below zero after store credit is applied.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                for (final line in cartItems) {
                                  if (!line.product.id.startsWith('SV:')) {
                                    final bool isLoose = line.product.id
                                        .startsWith('LOOSE:');
                                    final String baseProductId = isLoose
                                        ? line.product.id.substring(6)
                                        : line.product.id;

                                    _ProductItem? baseProduct;
                                    for (final p in _products) {
                                      if (p.id == baseProductId) {
                                        baseProduct = p;
                                        break;
                                      }
                                    }
                                    final targetProduct =
                                        baseProduct ?? line.product;
                                    final ratio = isLoose &&
                                            targetProduct
                                                    .unitConversionRatio >
                                                0
                                        ? targetProduct.unitConversionRatio
                                        : 1.0;
                                    final deductQtyInBaseUnit = isLoose
                                        ? (line.qty / ratio)
                                        : line.qty;

                                    if (deductQtyInBaseUnit >
                                        targetProduct.stock) {
                                      if (!mounted) return;
                                      await _showPosValidationGuideDialog(
                                        title: 'Insufficient Stock Available',
                                        sinhalaTitle: 'භාණ්ඩ තොග ප්‍රමාණවත් නොවේ',
                                        reason: '${line.product.name} සඳහා Cart එකේ ඇති ප්‍රමාණය (${_formatQty(line.qty)} ${line.product.measureUnit}), පවතින තොග ප්‍රමාණයට (${_formatQty(targetProduct.stock)} ${targetProduct.measureUnit}) වඩා වැඩිය.',
                                        guide: 'Cart එකෙහි ඇති අදාළ භාණ්ඩයේ Quantity එක අඩු කරන්න, නැතහොත් Inventory කළමනාකරණය වෙත ගොස් තොග ප්‍රමාණය Update කරන්න.',
                                        icon: Icons.inventory_2_outlined,
                                        color: Colors.red,
                                      );
                                      return;
                                    }
                                  }
                                }

                                if (paymentMethod == 'CASH' &&
                                    sanitizedPaidAmount + 0.0001 < grandTotal) {
                                  if (!mounted) return;
                                  final missingAmt = grandTotal - sanitizedPaidAmount;
                                  await _showPosValidationGuideDialog(
                                    title: 'Full Payment Required for Cash Sale',
                                    sinhalaTitle: 'Cash විකුණුම් සඳහා සම්පූර්ණ මුදල අවශ්‍ය වේ',
                                    reason: 'Cash ගෙවීම් ක්‍රමයේදී ඉතිරි හිඟ මුදලක් (Due Balance: ${_money(missingAmt)}) තබාගෙන බිල්පත සම්පූර්ණ කළ නොහැක. Cash විකුණුමකදී මුළු මුදලම ලැබිය යුතුය.',
                                    guide: '1. පාරිභෝගිකයා සම්පූර්ණ මුදල ගෙවූයේ නම් පහත "Set Exact Amount" ඔබන්න.\n2. මුදල කොටසක් පමණක් ගෙවා ඉතිරිය පසුව ගෙවන්නේ නම් Payment Method එක "CREDIT" හෝ "INSTALLMENT" ලෙස මාරු කරන්න.',
                                    icon: Icons.payments_outlined,
                                    color: Colors.amber.shade800,
                                    actionLabel: 'Set Exact Amount (${_money(grandTotal)})',
                                    onAction: () {
                                      setState(() {
                                        _amountPaidController.text = grandTotal.toStringAsFixed(2);
                                      });
                                    },
                                  );
                                  return;
                                }

                                if (paymentMethod == 'CREDIT' &&
                                    outstandingAmount <= 0) {
                                  if (!mounted) return;
                                  await _showPosValidationGuideDialog(
                                    title: 'Credit Sale Requires Due Balance',
                                    sinhalaTitle: 'ණය විකුණුමක ඉතිරි මුදලක් පැවතිය යුතුය',
                                    reason: 'ඔබ සම්පූර්ණ මුදලම ගෙවීම් ලෙස සටහන් කර ඇත (Amount Paid = ${_money(sanitizedPaidAmount)}). ණය (Credit) ක්‍රමයක් සඳහා ඉතිරි ගෙවීමට ඇති මුදලක් (Due Balance) තිබිය යුතුය.',
                                    guide: 'සම්පූර්ණ මුදල දැන් ගෙවන්නේ නම් Payment Method එක "CASH" හෝ "CARD" ලෙස මාරු කරන්න, නැතහොත් Amount Paid මුදල අඩු කරන්න.',
                                    icon: Icons.info_outline,
                                    color: Colors.blueGrey,
                                  );
                                  return;
                                }

                                if (paymentMethod == 'INSTALLMENT' &&
                                    outstandingAmount <= 0) {
                                  if (!mounted) return;
                                  await _showPosValidationGuideDialog(
                                    title: 'Installment Sale Requires Due Balance',
                                    sinhalaTitle: 'වාරික (Installment) සඳහා ඉතිරි මුදලක් තිබිය යුතුය',
                                    reason: 'සම්පූර්ණ මුදලම දැන් ගෙවා ඇති බැවින් වාරික සැලසුමක් සෑදිය නොහැක.',
                                    guide: 'Payment Method එක "CASH" හෝ "CARD" ලෙස මාරු කරන්න, නැතහොත් මූලික ගෙවීම (Down Payment) අඩු කරන්න.',
                                    icon: Icons.calendar_month_outlined,
                                    color: Colors.purple,
                                  );
                                  return;
                                }

                                if (_enableMobileShopFeatures) {
                                  for (final line in cartItems) {
                                    if (line.product.imeis != null &&
                                        line.product.imeis!.trim().isNotEmpty) {
                                      final selectedList =
                                          _selectedCartImeis[line.product.id] ??
                                          [];
                                      bool missing = false;
                                      for (int i = 0; i < line.qty; i++) {
                                        if (i >= selectedList.length ||
                                            selectedList[i].trim().isEmpty) {
                                          missing = true;
                                          break;
                                        }
                                      }
                                      if (missing) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please select an IMEI for all units of ${line.product.name}.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }
                                  }
                                }

                                if (isChequePayment && chequeNumber.isEmpty) {
                                  if (!mounted) return;
                                  await _showPosValidationGuideDialog(
                                    title: 'Cheque Number Required',
                                    sinhalaTitle: 'චෙක්පත් අංකය ඇතුළත් කිරීම අනිවාර්යයි',
                                    reason: 'චෙක්පත් මඟින් ගෙවීම් කිරීමේදී බැංකු ගිණුම් සමඟ සංසන්දනය කිරීම සඳහා චෙක්පත් අංකය (Cheque Number) සටහන් කිරීම අනිවාර්ය වේ.',
                                    guide: 'Tender & Payment කොටසේ ඇති "Cheque Number" කොටුවෙහි අදාළ චෙක්පත් අංකය ඇතුළත් කර නැවත Checkout කරන්න.',
                                    icon: Icons.subtitles_outlined,
                                    color: Colors.teal,
                                  );
                                  return;
                                }

                                if (paymentMethod == 'COD') {
                                  final isWalkIn =
                                      selectedCustomer.id == 'C001' ||
                                      selectedCustomer.name.trim().isEmpty ||
                                      selectedCustomer.name
                                              .trim()
                                              .toLowerCase() ==
                                          'walk-in customer';
                                  if (isWalkIn) {
                                    if (!mounted) return;
                                    await _showPosValidationGuideDialog(
                                      title: 'Customer Details Required for COD',
                                      sinhalaTitle: 'COD ඇණවුම් සඳහා Customer තොරතුරු අත්‍යවශ්‍යයි',
                                      reason: 'භාණ්ඩ ගෙදරට ගෙනගොස් මුදල් අයකර ගැනීමට (Cash on Delivery) නම්, ඩිලිවරි රයිඩර්ට බාරදීමට පාරිභෝගිකයාගේ නම, ලිපිනය සහ දුරකථන අංකය අවශ්‍ය වේ. Walk-in Customer සඳහා COD ඇණවුම් නිකුත් කළ නොහැක.',
                                      guide: 'පහත "Add Customer" බොත්තම ඔබා නව පාරිභෝගිකයෙකුගේ විස්තර ඇතුළත් කරන්න, නැතහොත් පාරිභෝගික ලැයිස්තුවෙන් දැනට සිටින පාරිභෝගිකයෙකු තෝරන්න.',
                                      icon: Icons.local_shipping_outlined,
                                      color: Colors.deepOrange,
                                      actionLabel: 'Add Customer (නව Customer එක් කරන්න)',
                                      onAction: () async {
                                        final c = await _showCustomerDialog();
                                        if (c != null) {
                                          c.locationId = _activeLocationForWrites;
                                          setState(() {
                                            _customers.removeWhere((item) => item.id == c.id);
                                            _customers.add(c);
                                            _selectedCustomerId = c.id;
                                            _posCustomerSearchController.text = '${c.name} (${c.phone.isEmpty ? 'N/A' : c.phone})';
                                          });
                                          await _persistWorkspaceData();
                                        }
                                      },
                                    );
                                    return;
                                  }
                                }

                                if (isCreditSale &&
                                    selectedCustomer.id == 'C001') {
                                  if (!mounted) return;
                                  await _showPosValidationGuideDialog(
                                    title: 'Registered Customer Required for Credit',
                                    sinhalaTitle: 'ණය විකුණුම් සඳහා ලියාපදිංචි Customer කෙනෙකු තෝරන්න',
                                    reason: 'ණය මුදල් පසු කලෙකදී අයකර ගැනීම සහ පාරිභෝගිකයාගේ ණය ගිණුම/ණය සීමාව (Credit Limit) සටහන් කිරීම සඳහා ලියාපදිංචි පාරිභෝගික ගිණුමක් අවශ්‍ය වේ. Walk-in Customer සඳහා Credit ලබාදිය නොහැක.',
                                    guide: 'පහත "Add Customer" බොත්තම ඔබා පාරිභෝගිකයා ලියාපදිංචි කරන්න, නැතහොත් Customer Search කොටුවෙන් පාරිභෝගිකයා තෝරන්න.',
                                    icon: Icons.account_balance_wallet_outlined,
                                    color: const Color(0xFF6366F1),
                                    actionLabel: 'Add Customer (නව Customer එක් කරන්න)',
                                    onAction: () async {
                                      final c = await _showCustomerDialog();
                                      if (c != null) {
                                        c.locationId = _activeLocationForWrites;
                                        setState(() {
                                          _customers.removeWhere((item) => item.id == c.id);
                                          _customers.add(c);
                                          _selectedCustomerId = c.id;
                                          _posCustomerSearchController.text = '${c.name} (${c.phone.isEmpty ? 'N/A' : c.phone})';
                                        });
                                        await _persistWorkspaceData();
                                      }
                                    },
                                  );
                                  return;
                                }

                                if (isCreditSale &&
                                    _hasOverdueCreditForCustomer(
                                      selectedCustomer,
                                    )) {
                                  final overdueDate =
                                      _oldestOverdueDateForCustomer(
                                        selectedCustomer,
                                      );
                                  if (!mounted) return;
                                  await _showPosValidationGuideDialog(
                                    title: 'Customer Has Overdue Credit',
                                    sinhalaTitle: 'පාරිභෝගිකයාට කල් ඉකුත් වූ ණය පවතී',
                                    reason: overdueDate == null
                                        ? 'මෙම පාරිභෝගිකයාට කලින් ලබාගත් ණය සඳහා ගෙවීමේ දිනය ඉක්මවා ගිය (Overdue) හිඟ මුදල් පවතී.'
                                        : 'මෙම පාරිභෝගිකයාට ${_formatDate(overdueDate)} දින සිට කල් ඉකුත් වූ හිඟ ණය පවතී. පැරණි ණය පියවන තුරු නව ණය විකුණුම් අවහිර කර ඇත.',
                                    guide: 'පාරිභෝගිකයාගේ පැරණි හිඟ මුදල මුලින්ම පියවා ගැනීමට කටයුතු කරන්න. ඉන්පසු නව ණය බිල්පතක් නිකුත් කළ හැක.',
                                    icon: Icons.warning_amber_rounded,
                                    color: Colors.red,
                                  );
                                  return;
                                }

                                if (isCreditSale &&
                                    selectedCustomer.creditLimit > 0) {
                                  final currentOutstanding =
                                      _customerOutstandingBalance(
                                        selectedCustomer.id,
                                        fallback:
                                            selectedCustomer.currentBalance,
                                      );
                                  final nextBalance =
                                      currentOutstanding + outstandingAmount;
                                  if (nextBalance >
                                      selectedCustomer.creditLimit) {
                                    if (!mounted) return;
                                    final proceed =
                                        await _showExtendCreditLimitDialog(
                                          selectedCustomer,
                                          currentOutstanding,
                                          outstandingAmount,
                                        );
                                    if (!proceed) return;
                                  }
                                }

                                final saleCreatedAt = DateTime.now().toUtc();

                                final shouldCreateInstallmentPlan =
                                    paymentMethod == 'INSTALLMENT' &&
                                    outstandingAmount > 0;
                                final planDueDates =
                                    _posInstallmentDueDates.length ==
                                        installmentCount
                                    ? List<DateTime>.from(
                                        _posInstallmentDueDates,
                                      )
                                    : _generateInstallmentDueDates(
                                        installments: installmentCount,
                                        intervalDays: installmentIntervalDays,
                                        startFrom: saleCreatedAt,
                                      );
                                final planInstallmentAmounts =
                                    (paymentMethod == 'INSTALLMENT' &&
                                        _posInstallmentAmounts.length ==
                                            installmentCount)
                                    ? List<double>.from(_posInstallmentAmounts)
                                    : _splitInstallmentAmounts(
                                        outstandingAmount,
                                        installmentCount,
                                      );
                                final planSchedules =
                                    List<_InstallmentScheduleItem>.generate(
                                      installmentCount,
                                      (index) => _InstallmentScheduleItem(
                                        installmentNo: index + 1,
                                        amount: planInstallmentAmounts[index],
                                        dueDate: planDueDates[index],
                                      ),
                                    );

                                final customerName = selectedCustomer.name;
                                final customerOutstandingBefore =
                                    selectedCustomerOutstanding;
                                final customerOutstandingAfter =
                                    (selectedCustomerOutstanding +
                                            outstandingAmount)
                                        .clamp(0, double.infinity)
                                        .toDouble();
                                final selectedAgentId = _posAgentId.trim();
                                final generatedInvoiceNo =
                                    await _buildInvoiceNumber(saleCreatedAt);
                                _UserItem? assignedDriver;
                                if (paymentMethod == 'COD' && _posSelectedDeliveryDriverId != null) {
                                  for (final u in _scopedUsers) {
                                    if (u.id == _posSelectedDeliveryDriverId) {
                                      assignedDriver = u;
                                      break;
                                    }
                                  }
                                }
                                final hasAssignedDriver = assignedDriver != null;
                                final codDeliveryOtp = paymentMethod == 'COD'
                                    ? (1000 + math.Random().nextInt(9000)).toString()
                                    : null;

                                final sale = _SaleRecord(
                                  id: _buildLocalSaleId(saleCreatedAt),
                                  invoiceNumber: generatedInvoiceNo,
                                  locationId: _activeLocationForWrites,
                                  customerName: customerName,
                                  customerId: selectedCustomer.id,
                                  customerPhone: selectedCustomer.phone,
                                  customerAddress: selectedCustomer.address,
                                  shippingAddress: paymentMethod == 'COD'
                                      ? (selectedCustomer.shippingAddress ?? '')
                                      : '',
                                  customerOutstandingBefore:
                                      customerOutstandingBefore,
                                  customerOutstandingAfter:
                                      isCreditSale ||
                                          paymentMethod == 'INSTALLMENT'
                                      ? customerOutstandingAfter
                                      : customerOutstandingBefore,
                                  employeeId: _currentUserId,
                                  cashierName: _currentUserName,
                                  paymentMethod: paymentMethod,
                                  items: cartItems
                                      .map(
                                        (line) => _SaleItemSnapshot(
                                          productId: line.product.id,
                                          productName: line.product.name,
                                          quantity: line.qty,
                                          unitPrice:
                                              line.unitPriceAfterDiscount,
                                          discount: line.discountValue,
                                          discountType: line.discountType,
                                          lineTotal: line.totalPrice,
                                          productType: line.product.productType,
                                        ),
                                      )
                                      .toList(),
                                  subtotal: subtotal,
                                  tax: taxAmount,
                                  discount: invoiceDiscountAmount,
                                  total: grandTotal,
                                  amountPaid: sanitizedPaidAmount,
                                  balance: grandTotal - sanitizedPaidAmount,
                                  chequeNumber: chequeNumber,
                                  shippingCharges: shippingCharges,
                                  agentName: _posAgentName,
                                  agentCommission: _posAgentCommission,
                                  agentCommissionType: _posAgentCommissionType,
                                  agentCommissionPaid: _posAgentCommissionPaid,
                                  deliveryPersonId: hasAssignedDriver ? assignedDriver.id : null,
                                  deliveryPersonName: hasAssignedDriver ? assignedDriver.name : null,
                                  deliveryStatus: hasAssignedDriver
                                      ? 'ASSIGNED'
                                      : (paymentMethod == 'COD' ? 'PENDING' : null),
                                  deliveryOtp: codDeliveryOtp,
                                  status: paymentMethod == 'COD'
                                      ? (_posCodPaymentCollectedUpfront
                                            ? 'COMPLETED'
                                            : (hasAssignedDriver ? 'OUT_FOR_DELIVERY' : 'COD_PENDING'))
                                      : 'COMPLETED',
                                  notes: () {
                                    final customNotes = _posNotesController.text
                                        .trim();
                                    if (!_enableMobileShopFeatures) {
                                      return customNotes;
                                    }
                                    final soldMap = <String, List<String>>{};
                                    for (final line in cartItems) {
                                      if (line.product.imeis != null &&
                                          line.product.imeis!
                                              .trim()
                                              .isNotEmpty) {
                                        final selected =
                                            _selectedCartImeis[line
                                                .product
                                                .id] ??
                                            [];
                                        final soldImeis = selected
                                            .take(line.qty.toInt())
                                            .toList();
                                        if (soldImeis.isNotEmpty) {
                                          soldMap[line.product.id] = soldImeis;
                                        }
                                      }
                                    }
                                    if (soldMap.isEmpty) {
                                      return customNotes;
                                    }
                                    return jsonEncode({
                                      'custom': customNotes,
                                      'imeis': soldMap,
                                    });
                                  }(),
                                  createdAt: saleCreatedAt,
                                  installmentSchedules:
                                      paymentMethod == 'INSTALLMENT'
                                      ? planSchedules
                                      : <_InstallmentScheduleItem>[],
                                );
                                final domainSale = _toDomainSale(
                                  sale,
                                  cartItems,
                                );
                                final installmentPlan =
                                    shouldCreateInstallmentPlan
                                    ? _InstallmentPlan(
                                        id: 'IP${DateTime.now().microsecondsSinceEpoch}',
                                        saleId: sale.id,
                                        invoiceNumber: sale.invoiceNumber ?? '',
                                        customerId: selectedCustomer.id,
                                        locationId: _activeLocationForWrites,
                                        customerName: selectedCustomer.name,
                                        customerPhone: selectedCustomer.phone,
                                        customerAddress:
                                            selectedCustomer.address,
                                        totalAmount: grandTotal,
                                        subtotal: subtotal,
                                        taxAmount: taxAmount,
                                        downPayment: sanitizedPaidAmount,
                                        remainingAmount: outstandingAmount,
                                        paymentMethod: paymentMethod,
                                        chequeNumber: chequeNumber,
                                        numberOfInstallments: installmentCount,
                                        intervalDays: installmentIntervalDays,
                                        createdAt: saleCreatedAt,
                                        items: sale.items,
                                        schedules: planSchedules,
                                      )
                                    : null;
                                final creditSaleSyncId =
                                    isCreditSale && outstandingAmount > 0
                                    ? 'CS${DateTime.now().microsecondsSinceEpoch}'
                                    : null;
                                final stockAuditEntries =
                                    <_StockAdjustmentItem>[];

                                var saleSavedLocally = false;
                                String? syncWarning;

                                Future<void>
                                persistSaleAndQueueSideEffects() async {
                                  if (_editingSaleId != null) {
                                    if (_saleRepository != null) {
                                      await _saleRepository!.updateSale(
                                        domainSale,
                                      );
                                    } else {
                                      await _enqueueSync(
                                        'UPDATE',
                                        'sales',
                                        sale.id,
                                      );
                                    }
                                  } else {
                                    if (_saleRepository != null) {
                                      await _saleRepository!.insertSale(
                                        domainSale,
                                      );
                                    } else {
                                      await _enqueueSync(
                                        'INSERT',
                                        'sales',
                                        sale.id,
                                      );
                                    }
                                  }
                                  saleSavedLocally = true;

                                  setState(() {
                                    final currentOutstanding =
                                        _customerOutstandingBalance(
                                          selectedCustomer.id,
                                          fallback:
                                              selectedCustomer.currentBalance,
                                        );
                                    selectedCustomer.loyaltyPoints +=
                                        _loyaltyPointsForAmount(grandTotal);
                                    if (isCreditSale && outstandingAmount > 0) {
                                      selectedCustomer.currentBalance =
                                          currentOutstanding +
                                          outstandingAmount;
                                    }

                                    if (isCreditSale && outstandingAmount > 0) {
                                      final creditEntry = _CreditSaleEntry(
                                        id: creditSaleSyncId!,
                                        saleId: sale.id,
                                        invoiceNumber: sale.invoiceNumber ?? '',
                                        locationId: _activeLocationForWrites,
                                        customerId: selectedCustomer.id,
                                        customerName: selectedCustomer.name,
                                        customerPhone: selectedCustomer.phone,
                                        customerAddress:
                                            selectedCustomer.address,
                                        customerOutstandingBefore:
                                            currentOutstanding,
                                        customerOutstandingAfter:
                                            currentOutstanding +
                                            outstandingAmount,
                                        subtotal: subtotal,
                                        tax: taxAmount,
                                        total: grandTotal,
                                        amountPaidOnSale: sanitizedPaidAmount,
                                        outstandingAmount: outstandingAmount,
                                        paymentMethod: paymentMethod,
                                        items: cartItems
                                            .map(
                                              (line) =>
                                                  '${line.product.name} x${line.qty} @ ${_money(line.product.price)} = ${_money(line.product.price * line.qty)}',
                                            )
                                            .toList(),
                                        createdAt: sale.createdAt,
                                      );

                                      _customerCreditSales
                                          .putIfAbsent(
                                            selectedCustomer.id,
                                            () => [],
                                          )
                                          .insert(0, creditEntry);
                                    }
                                    if (installmentPlan != null) {
                                      _installmentPlans.insert(
                                        0,
                                        installmentPlan,
                                      );
                                    }

                                    if (_editingSaleId != null) {
                                      final idx = _sales.indexWhere(
                                        (s) => s.id == _editingSaleId,
                                      );
                                      if (idx >= 0) {
                                        _sales[idx] = sale;
                                      } else {
                                        _sales.insert(0, sale);
                                      }
                                    } else {
                                      _sales.insert(0, sale);
                                    }
                                    for (final line in cartItems) {
                                      if (!line.product.id.startsWith('SV:')) {
                                        final bool isLoose = line.product.id
                                            .startsWith('LOOSE:');
                                        final String baseProductId = isLoose
                                            ? line.product.id.substring(6)
                                            : line.product.id;

                                        _ProductItem? baseProduct;
                                        for (final p in _products) {
                                          if (p.id == baseProductId) {
                                            baseProduct = p;
                                            break;
                                          }
                                        }
                                        final targetProduct =
                                            baseProduct ?? line.product;
                                        final ratio = isLoose &&
                                                targetProduct
                                                        .unitConversionRatio >
                                                    0
                                            ? targetProduct.unitConversionRatio
                                            : 1.0;
                                        final deductQtyInBaseUnit = isLoose
                                            ? (line.qty / ratio)
                                            : line.qty;

                                        final beforeStock =
                                            targetProduct.stock;
                                        final afterStock =
                                            (beforeStock - deductQtyInBaseUnit)
                                                .clamp(0.0, 1000000000.0);
                                        targetProduct.stock = afterStock;
                                        if (baseProduct != null &&
                                            line.product != baseProduct) {
                                          line.product.stock = afterStock;
                                        }

                                        if (_enableMobileShopFeatures &&
                                            line.product.imeis != null &&
                                            line.product.imeis!
                                                .trim()
                                                .isNotEmpty) {
                                          final currentImeis =
                                              line.product.imeiList;
                                          final sold =
                                              _selectedCartImeis[line
                                                  .product
                                                  .id] ??
                                              [];
                                          final remaining = currentImeis
                                              .where((x) => !sold.contains(x))
                                              .toList();
                                          line.product.imeis = jsonEncode(
                                            remaining,
                                          );
                                        }

                                        final appliedDelta =
                                            afterStock - beforeStock;
                                        if (appliedDelta != 0) {
                                          final unitCost =
                                              targetProduct.costPrice;
                                          stockAuditEntries.add(
                                            _StockAdjustmentItem(
                                              id: 'SA${DateTime.now().microsecondsSinceEpoch}-${targetProduct.id}',
                                              productId: targetProduct.id,
                                              productName: isLoose
                                                  ? '${targetProduct.name} (${line.qty.toStringAsFixed(line.qty.truncateToDouble() == line.qty ? 0 : 2)} ${targetProduct.secondaryUnit} loose)'
                                                  : targetProduct.name,
                                              delta: appliedDelta,
                                              beforeStock: beforeStock,
                                              afterStock: afterStock,
                                              reason: isLoose
                                                  ? 'Sale ${sale.id} (${line.qty} ${targetProduct.secondaryUnit} sold = ${deductQtyInBaseUnit.toStringAsFixed(3)} ${targetProduct.measureUnit})'
                                                  : 'Sale ${sale.id} completed',
                                              performedBy: _currentUserName,
                                              unitCost: unitCost,
                                              adjustedStockValue:
                                                  unitCost == null
                                                  ? null
                                                  : afterStock * unitCost,
                                              createdAt: DateTime.now(),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    _stockAdjustments.insertAll(
                                      0,
                                      stockAuditEntries,
                                    );
                                    for (final returnId in linkedReturnIds) {
                                      for (final item in _returns) {
                                        if (item.id != returnId) {
                                          continue;
                                        }
                                        item.status = 'Refunded';
                                        item.exchangeSaleId = sale.id;
                                        item.updatedAt = DateTime.now()
                                            .toUtc()
                                            .toIso8601String();
                                        break;
                                      }
                                    }
                                    _removeTemporaryCartProducts(
                                      cartItems.map((line) => line.product.id),
                                    );
                                    _cart.clear();
                                    _selectedCartImeis.clear();
                                    _posLineDiscounts.clear();
                                    _posLinePrices.clear();
                                    _editingSaleId = null;
                                    _paymentMethodController.text = 'CASH';
                                    _amountPaidController.clear();
                                    _chequeNumberController.clear();
                                    _posNotesController.clear();
                                    _posInstallmentCount = 3;
                                    _posInstallmentIntervalDays = 30;
                                    _resetPosInstallmentSchedule();
                                    _resetPosDiscountState();
                                    _selectedCustomerId = null;
                                    _posCustomerSearchController.clear();
                                    // Reset shipping & agent commission for next sale
                                    _posShippingCharges = 0.0;
                                    _posShippingController.clear();
                                    // Re-fill agent name based on mode
                                    if (_agentCommissionLockToLogin ||
                                        _isAgent) {
                                      // Locked mode OR user is an agent role → always use login user
                                      _posAgentName = _currentUserName;
                                      _posAgentId = _currentUserId;
                                      _posAgentNameController.text =
                                          _currentUserName;
                                    } else {
                                      _posAgentName = '';
                                      _posAgentId = '';
                                      _posAgentNameController.clear();
                                    }
                                    _posAgentCommission = 0.0;
                                    _posAgentCommissionController.clear();
                                    _posAgentCommissionType = 'PERCENT';
                                    _posAgentCommissionPaid = false;
                                    _posCodPaymentCollectedUpfront = false;
                                    _posSelectedDeliveryDriverId = null;
                                  });
                                  await _persistWorkspaceData();

                                  if (installmentPlan != null) {
                                    await _enqueueSync(
                                      'INSERT',
                                      'installments',
                                      installmentPlan.id,
                                    );
                                  }
                                  if (creditSaleSyncId != null) {
                                    await _enqueueSync(
                                      'INSERT',
                                      'credit_sales',
                                      creditSaleSyncId,
                                    );
                                  }
                                  if (isCreditSale && outstandingAmount > 0) {
                                    if (_customerRepository != null) {
                                      await _customerRepository!.updateCustomer(
                                        _toDomainCustomer(selectedCustomer),
                                      );
                                    } else {
                                      await _enqueueSync(
                                        'UPDATE',
                                        'customers',
                                        selectedCustomer.id,
                                      );
                                    }
                                  }

                                  final soldProductIds = <String>{
                                    for (final line in cartItems)
                                      if (!line.product.id.startsWith('SV:'))
                                        line.product.id.startsWith('LOOSE:')
                                            ? line.product.id.substring(6)
                                            : line.product.id,
                                  };
                                  if (_productRepository != null) {
                                    for (final productId in soldProductIds) {
                                      _ProductItem? product;
                                      for (final item in _products) {
                                        if (item.id == productId) {
                                          product = item;
                                          break;
                                        }
                                      }
                                      if (product == null) continue;
                                      await _productRepository!.updateProduct(
                                        _toDomainProduct(product),
                                      );
                                    }
                                  } else {
                                    for (final productId in soldProductIds) {
                                      await _enqueueSync(
                                        'UPDATE',
                                        'inventory',
                                        productId,
                                      );
                                    }
                                  }
                                  for (final audit in stockAuditEntries) {
                                    await _enqueueSync(
                                      'INSERT',
                                      'stock_adjustments',
                                      audit.id,
                                    );
                                  }
                                  for (final returnId in linkedReturnIds) {
                                    await _enqueueSync(
                                      'UPDATE',
                                      'returns',
                                      returnId,
                                    );
                                  }
                                }

                                try {
                                  if (_syncService != null) {
                                    await _syncService!.runWithoutAutoSync(
                                      persistSaleAndQueueSideEffects,
                                    );
                                  } else {
                                    await persistSaleAndQueueSideEffects();
                                  }
                                } catch (e) {
                                  if (!saleSavedLocally) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to save sale locally: $e',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  syncWarning =
                                      'Sale saved locally, but some follow-up sync actions failed: $e';
                                }

                                // ── Agent commission log ──────────────────
                                if (_enableAgentCommission &&
                                    sale.agentName.isNotEmpty &&
                                    sale.agentCommission > 0 &&
                                    _appDatabase != null) {
                                  try {
                                    // Always load the full employees list once
                                    final dbEmps = await _appDatabase!
                                        .getAllEmployees();

                                    // Start with the stored ID from the dropdown (captured before state resets)
                                    String agentEmployeeId = selectedAgentId;

                                    // Validate/Lookup employee ID
                                    if (agentEmployeeId.isNotEmpty) {
                                      final existsInDb = dbEmps.any(
                                        (e) => e.id == agentEmployeeId,
                                      );
                                      if (!existsInDb) {
                                        // Check if they exist in in-memory _users list to get their details
                                        final userRecord = _users.firstWhere(
                                          (u) => u.id == agentEmployeeId,
                                          orElse: () => _UserItem(
                                            id: '',
                                            name: '',
                                            email: '',
                                            role: '',
                                            active: false,
                                          ),
                                        );
                                        final userName =
                                            userRecord.id.isNotEmpty
                                            ? userRecord.name
                                            : sale.agentName;

                                        // Auto-create employee record using their user ID so it's consistent
                                        await _appDatabase!.insertEmployee(
                                          db.EmployeesCompanion(
                                            id: Value(agentEmployeeId),
                                            tenantId: Value(
                                              _activeTenantId ?? 'local',
                                            ),
                                            name: Value(userName),
                                            email: Value(
                                              userRecord.id.isNotEmpty
                                                  ? userRecord.email
                                                  : '',
                                            ),
                                            locationId: Value(
                                              _activeLocationForWrites,
                                            ),
                                            role: Value(
                                              userRecord.id.isNotEmpty
                                                  ? userRecord.role
                                                  : 'AGENT',
                                            ),
                                            isAgent: const Value(true),
                                            synced: const Value(false),
                                            createdAt: Value(
                                              DateTime.now().toUtc(),
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      // If no ID is stored (typed manually), look up by name in employee DB
                                      for (final emp in dbEmps) {
                                        if (emp.name.trim().toLowerCase() ==
                                            sale.agentName.toLowerCase()) {
                                          agentEmployeeId = emp.id;
                                          break;
                                        }
                                      }

                                      // If not in employee DB, look up by name in _users list
                                      if (agentEmployeeId.isEmpty) {
                                        final userRecord = _users.firstWhere(
                                          (u) =>
                                              u.name.trim().toLowerCase() ==
                                              sale.agentName.toLowerCase(),
                                          orElse: () => _UserItem(
                                            id: '',
                                            name: '',
                                            email: '',
                                            role: '',
                                            active: false,
                                          ),
                                        );
                                        if (userRecord.id.isNotEmpty) {
                                          agentEmployeeId = userRecord.id;
                                          // Auto-create employee record using their user ID
                                          await _appDatabase!.insertEmployee(
                                            db.EmployeesCompanion(
                                              id: Value(agentEmployeeId),
                                              tenantId: Value(
                                                _activeTenantId ?? 'local',
                                              ),
                                              name: Value(userRecord.name),
                                              email: Value(userRecord.email),
                                              locationId: Value(
                                                _activeLocationForWrites,
                                              ),
                                              role: Value(userRecord.role),
                                              isAgent: const Value(true),
                                              synced: const Value(false),
                                              createdAt: Value(
                                                DateTime.now().toUtc(),
                                              ),
                                            ),
                                          );
                                        }
                                      }

                                      // If still empty (neither employee nor user exists), auto-create with a deterministic ID
                                      if (agentEmployeeId.isEmpty) {
                                        agentEmployeeId =
                                            'AGT-${sale.agentName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
                                        await _appDatabase!.insertEmployee(
                                          db.EmployeesCompanion(
                                            id: Value(agentEmployeeId),
                                            tenantId: Value(
                                              _activeTenantId ?? 'local',
                                            ),
                                            name: Value(sale.agentName),
                                            email: const Value(''),
                                            locationId: Value(
                                              _activeLocationForWrites,
                                            ),
                                            role: const Value('AGENT'),
                                            isAgent: const Value(true),
                                            synced: const Value(false),
                                            createdAt: Value(
                                              DateTime.now().toUtc(),
                                            ),
                                          ),
                                        );
                                      }
                                    }

                                    // Use the type stored IN the sale record — NOT the
                                    // mutable state variable — so the calculation is
                                    // always consistent with what was captured at
                                    // checkout time (prevents Pay Now vs Pay Later drift).
                                    final agentType = sale.agentCommissionType
                                        .trim()
                                        .toUpperCase();
                                    final commissionAmount =
                                        agentType == 'FIXED'
                                        ? sale.agentCommission
                                        : double.parse(
                                            (grandTotal *
                                                    (sale.agentCommission /
                                                        100))
                                                .toStringAsFixed(2),
                                          );
                                    final logId =
                                        'CL-AGENT-${sale.id}-$agentEmployeeId';
                                    await _appDatabase!.insertCommissionLog(
                                      db.CommissionLogsCompanion(
                                        id: Value(logId),
                                        tenantId: Value(
                                          _activeTenantId ?? 'local',
                                        ),
                                        saleId: Value(sale.id),
                                        employeeId: Value(agentEmployeeId),
                                        saleAmount: Value(grandTotal),
                                        commissionAmount: Value(
                                          commissionAmount,
                                        ),
                                        commissionType: Value(
                                          sale.agentCommissionType,
                                        ),
                                        isPaid: Value(sale.agentCommissionPaid),
                                        paidAt: Value(
                                          sale.agentCommissionPaid
                                              ? DateTime.now().toUtc()
                                              : null,
                                        ),
                                        createdAt: Value(
                                          DateTime.now().toUtc(),
                                        ),
                                      ),
                                    );
                                  } catch (commErr) {
                                    // Surface the error — non-critical but useful
                                    if (mounted) {
                                      ScaffoldMessenger.maybeOf(
                                        context,
                                      )?.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Commission note: could not record commission log. $commErr',
                                          ),
                                          duration: const Duration(seconds: 6),
                                          backgroundColor: Colors.orange,
                                          action: SnackBarAction(
                                            label: 'OK',
                                            textColor: Colors.white,
                                            onPressed: () {},
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                                // ──────────────────────────────────────────

                                  // 1. Print receipt immediately - primary customer document
                                  String? printWarning;
                                  try {
                                    await _printReceipt(
                                      sale: sale,
                                      lines: cartItems,
                                    );
                                  } catch (e) {
                                    debugPrint('Receipt print error: $e');
                                    printWarning =
                                        'Sale saved, but receipt printing failed: $e';
                                  }

                                  // 2. Trigger Cash Drawer kick AFTER receipt job is safely dispatched to spooler
                                  // This completely eliminates USB port lock collisions between raw drawer pulse & receipt!
                                  if (_localCashDrawerEnabled && (paymentMethod.toUpperCase().contains('CASH') || paymentMethod == 'COD')) {
                                    try {
                                      // Wait 700ms so Windows Spooler has queued the receipt job
                                      await Future.delayed(const Duration(milliseconds: 700));
                                      await _maybeOpenCashDrawer(paymentMethod: paymentMethod);
                                    } catch (cdErr) {
                                      debugPrint('Cash drawer kick error: $cdErr');
                                    }
                                  }

                                 // Sync queue update runs asynchronously in background so
                                 // receipt printing and checkout UI are never blocked by cloud HTTP latency
                                 unawaited(() async {
                                   try {
                                     await _refreshPendingSyncQueue();
                                     await _triggerImmediateSync(
                                       action: 'INSERT',
                                       module: 'sales',
                                       reference: sale.id,
                                     );
                                   } catch (syncErr) {
                                     debugPrint('Background sync after sale complete error: $syncErr');
                                   }
                                 }());

                                 final bool isDeliveryOrder = paymentMethod == 'COD' ||
                                     sale.shippingAddress.trim().isNotEmpty ||
                                     (sale.customerAddress.trim().isNotEmpty && sale.customerName != 'Walk-in Customer');

                                 if (isDeliveryOrder) {
                                   // Give Windows Spooler 500ms between jobs so USB port is ready
                                   await Future.delayed(const Duration(milliseconds: 1000));
                                    try {
                                      await _printDeliveryNote(sale, prompt: _localPromptDeliveryLabel);
                                   } catch (dnErr) {
                                     debugPrint('Delivery note print error: $dnErr');
                                   }
                                 }

                                if (paymentMethod == 'COD' && _enableWhatsappCodNotifications) {
                                  final customerPhone = sale.customerPhone.isNotEmpty
                                      ? sale.customerPhone
                                      : selectedCustomer.phone;
                                  if (customerPhone.isNotEmpty) {
                                    try {
                                      final ws = WhatsAppService(context.read<ApiClient>());
                                      ws.sendDeliveryNote(
                                        customerPhone: customerPhone,
                                        customerName: sale.customerName,
                                        invoiceNumber: sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : sale.id,
                                        deliveryOtp: codDeliveryOtp,
                                        totalAmount: sale.total,
                                        shippingAddress: sale.shippingAddress,
                                        assignedDriverName: sale.deliveryPersonName,
                                        storeName: _companyName.isNotEmpty ? _companyName : 'StoreBuddy Store',
                                      ).then((res) {
                                        if (res['success'] == true) {
                                          _addNotification(
                                            title: 'WhatsApp Delivery Note Sent',
                                            message: 'WhatsApp delivery note & OTP sent to customer ($customerPhone) for invoice ${sale.id}',
                                            type: 'delivery',
                                            targetLocation: sale.locationId,
                                            referenceId: sale.id,
                                          );
                                        }
                                      }).catchError((_) {});
                                    } catch (_) {}
                                  }
                                }

                                if (!mounted || !context.mounted) return;
                                 try {
                                   final sm = ScaffoldMessenger.maybeOf(context);
                                   sm?.clearSnackBars();

                                   final invoiceNo = sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : sale.id;
                                   final displayMsg = printWarning ??
                                       syncWarning ??
                                       (installmentPlan != null
                                           ? 'Installment plan created ($invoiceNo)'
                                           : isCreditSale
                                           ? 'Credit sale recorded ($invoiceNo)'
                                           : 'Sale completed successfully! ($invoiceNo)');

                                   sm?.showSnackBar(
                                     SnackBar(
                                       behavior: SnackBarBehavior.floating,
                                       elevation: 6,
                                       shape: RoundedRectangleBorder(
                                         borderRadius: BorderRadius.circular(12),
                                       ),
                                       backgroundColor: printWarning != null
                                           ? const Color(0xFFE11D48)
                                           : const Color(0xFF10B981),
                                       duration: Duration(
                                         milliseconds: printWarning != null ? 4000 : 2500,
                                       ),
                                       showCloseIcon: true,
                                       closeIconColor: Colors.white,
                                       content: Row(
                                         children: [
                                           Icon(
                                             printWarning != null
                                                 ? Icons.warning_amber_rounded
                                                 : Icons.check_circle_rounded,
                                             color: Colors.white,
                                             size: 20,
                                           ),
                                           const SizedBox(width: 10),
                                           Expanded(
                                             child: Text(
                                               displayMsg,
                                               style: const TextStyle(
                                                 color: Colors.white,
                                                 fontWeight: FontWeight.w600,
                                                 fontSize: 13.5,
                                               ),
                                               overflow: TextOverflow.ellipsis,
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                   );
                                 } catch (_) {}

    } finally {
      _isPosCheckoutProcessing = false;
    }
  }

  Future<void> _showAddToCartQuantityDialog(_ProductItem product) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryUnit = product.measureUnit.isNotEmpty ? product.measureUnit : 'Unit';
    final secondaryUnit = product.secondaryUnit.isNotEmpty ? product.secondaryUnit : 'Loose';
    final ratio = product.unitConversionRatio > 0
        ? product.unitConversionRatio
        : 1.0;
    final loosePrice = product.secondaryPrice ??
        (ratio > 0 ? (product.price / ratio) : product.price);

    final bool hasLooseSales = product.allowLooseSales;
    bool isLooseSelected = false;
    double chosenQty = 1.0;
    final qtyController = TextEditingController(text: '1');
    qtyController.selection = const TextSelection(baseOffset: 0, extentOffset: 1);
    final focusNode = FocusNode();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (focusNode.canRequestFocus && !focusNode.hasFocus) {
                focusNode.requestFocus();
                qtyController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: qtyController.text.length,
                );
              }
            });

            final activeUnit = (hasLooseSales && isLooseSelected)
                ? secondaryUnit
                : primaryUnit;
            final activeUnitPrice = (hasLooseSales && isLooseSelected)
                ? loosePrice
                : product.price;
            final lineTotal = activeUnitPrice * chosenQty;

            final totalLooseStock =
                ratio > 0 ? (product.stock * ratio) : product.stock;
            final maxStock = (hasLooseSales && isLooseSelected)
                ? totalLooseStock
                : product.stock;
            final stockWarning = chosenQty > maxStock;

            void updateQty(double newQty) {
              if (newQty < 0.001) newQty = 0.001;
              setLocal(() {
                chosenQty = (newQty * 1000).round() / 1000.0;
                final text = chosenQty.truncateToDouble() == chosenQty
                    ? chosenQty.toInt().toString()
                    : chosenQty.toString();
                qtyController.text = text;
                qtyController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: text.length,
                );
              });
            }

            void submitAdd() {
              final typed = double.tryParse(qtyController.text.trim());
              if (typed != null && typed > 0) {
                chosenQty = typed;
              }
              if (chosenQty <= 0) return;
              final targetCartId = (hasLooseSales && isLooseSelected)
                  ? 'LOOSE:${product.id}'
                  : product.id;
              final currentQty = _cart[targetCartId] ?? 0;
              final newQty = currentQty + chosenQty;

              if (newQty > maxStock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Warning: Stock limit ($maxStock $activeUnit) exceeded. Added to bill.',
                    ),
                    backgroundColor: Colors.amber.shade900,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              setState(() {
                _cart[targetCartId] = (newQty * 1000).round() / 1000.0;

                if (!isLooseSelected &&
                    _enableMobileShopFeatures &&
                    product.imeis != null &&
                    product.imeis!.trim().isNotEmpty) {
                  final availableImeis = product.imeiList;
                  if (availableImeis.isNotEmpty) {
                    final currentSelected = _selectedCartImeis[product.id] ?? [];
                    final nextSelected = List<String>.from(currentSelected);
                    for (int i = 0; i < chosenQty.toInt(); i++) {
                      final unselected = availableImeis.firstWhere(
                        (x) => !nextSelected.contains(x),
                        orElse: () => '',
                      );
                      if (unselected.isNotEmpty) {
                        nextSelected.add(unselected);
                      }
                    }
                    _selectedCartImeis[product.id] = nextSelected;
                  }
                }
              });

              _productSearchController.clear();
              Navigator.pop(dialogCtx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_posProductSearchFocusNode.canRequestFocus) { _posProductSearchFocusNode.requestFocus(); }
              });
            }

            return Focus(
              autofocus: false,
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                  submitAdd();
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                  Navigator.pop(dialogCtx);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasLooseSales
                            ? const Color(0xFF0EA5E9).withValues(alpha: 0.12)
                            : const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasLooseSales
                            ? Icons.scale_rounded
                            : Icons.add_shopping_cart_rounded,
                        color: hasLooseSales
                            ? const Color(0xFF0EA5E9)
                            : const Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                hasLooseSales
                                    ? 'Stock: ${_formatDualStock(product.stock, primaryUnit, secondaryUnit, ratio)}'
                                    : 'Stock: ${_formatQty(product.stock)} $primaryUnit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: product.stock <= product.minStock
                                      ? AppTheme.brandRose
                                      : AppTheme.brandEmerald,
                                ),
                              ),
                              if (product.barcode.isNotEmpty)
                                Text(
                                  '• ${product.barcode}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasLooseSales) ...[
                          Text(
                            _t('Select Selling Unit (විකිණීමේ ඒකකය):'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setLocal(() {
                                      isLooseSelected = false;
                                      updateQty(1.0);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !isLooseSelected
                                          ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.04)
                                              : Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !isLooseSelected
                                            ? const Color(0xFF6366F1)
                                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                                        width: !isLooseSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 22,
                                          color: !isLooseSelected
                                              ? const Color(0xFF6366F1)
                                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Full $primaryUnit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: !isLooseSelected
                                                ? const Color(0xFF6366F1)
                                                : (isDark ? Colors.white : Colors.grey.shade800),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _money(product.price),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: !isLooseSelected
                                                ? const Color(0xFF6366F1)
                                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setLocal(() {
                                      isLooseSelected = true;
                                      updateQty(1.0);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLooseSelected
                                          ? const Color(0xFF0EA5E9).withValues(alpha: 0.12)
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.04)
                                              : Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isLooseSelected
                                            ? const Color(0xFF0EA5E9)
                                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                                        width: isLooseSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.scale_rounded,
                                          size: 22,
                                          color: isLooseSelected
                                              ? const Color(0xFF0EA5E9)
                                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Loose $secondaryUnit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: isLooseSelected
                                                ? const Color(0xFF0EA5E9)
                                                : (isDark ? Colors.white : Colors.grey.shade800),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_money(loosePrice)} / $secondaryUnit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isLooseSelected
                                                ? const Color(0xFF0EA5E9)
                                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        Text(
                          _t('Quick Quantity (කෙටි ප්‍රමාණ):'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (hasLooseSales && isLooseSelected
                                  ? [0.25, 0.5, 1.0, 2.0, 5.0, 10.0]
                                  : [1.0, 2.0, 3.0, 5.0, 10.0, 20.0])
                              .map((chipQty) {
                            final isSel = chosenQty == chipQty;
                            final themeColor = (hasLooseSales && isLooseSelected)
                                ? const Color(0xFF0EA5E9)
                                : const Color(0xFF6366F1);
                            return InkWell(
                              onTap: () => updateQty(chipQty),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? themeColor
                                      : (isDark
                                          ? Colors.white10
                                          : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (hasLooseSales && isLooseSelected)
                                      ? '+${chipQty.truncateToDouble() == chipQty ? chipQty.toInt() : chipQty} $secondaryUnit'
                                      : '+${chipQty.toInt()} $primaryUnit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSel
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.grey.shade800),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          _t('Quantity (ප්‍රමාණය ඇතුළත් කරන්න):'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: () {
                                final step = (hasLooseSales && isLooseSelected) ? 0.25 : 1.0;
                                updateQty((chosenQty - step).clamp(0.01, 999999.0));
                              },
                              icon: const Icon(Icons.remove_rounded),
                              color: AppTheme.brandRose,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: qtyController,
                                focusNode: focusNode,
                                autofocus: true,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  suffixText: activeUnit,
                                  suffixStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (val) {
                                  final v = double.tryParse(val.trim());
                                  if (v != null && v > 0) {
                                    setLocal(() {
                                      chosenQty = v;
                                    });
                                  }
                                },
                                onSubmitted: (_) => submitAdd(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () {
                                final step = (hasLooseSales && isLooseSelected) ? 0.25 : 1.0;
                                updateQty(chosenQty + step);
                              },
                              icon: const Icon(Icons.add_rounded),
                              color: AppTheme.brandEmerald,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: stockWarning
                                  ? Colors.redAccent
                                  : (isDark ? Colors.white10 : Colors.grey.shade300),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _t('Line Total (මුළු මුදල):'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _money(lineTotal),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: (hasLooseSales && isLooseSelected)
                                          ? const Color(0xFF0EA5E9)
                                          : const Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                              if (hasLooseSales && isLooseSelected) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Stock Deduction:',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '${(chosenQty / ratio).toStringAsFixed(3)} $primaryUnit',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (stockWarning) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Exceeds available stock ($maxStock $activeUnit)!',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Cancel (Esc)'),
                  ),
                  ElevatedButton.icon(
                    onPressed: submitAdd,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text('Add to Bill (Enter)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (hasLooseSales && isLooseSelected)
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    focusNode.dispose();
    qtyController.dispose();
  }

  Future<void> _showDualUnitSelectionDialog(_ProductItem product) async {
    return _showAddToCartQuantityDialog(product);
  }

  void _showPosShortcutsGuideDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final shortcutsList = [
          {
            'key': _posShortcuts['completeSale'] ?? 'Enter',
            'title': 'Complete Sale (බිල අවසන් කිරීම)',
            'desc': 'Fast checkout with exact cash or current payment method'
          },
          {
            'key': _posShortcuts['focusSearch'] ?? 'F1',
            'title': 'Search Product (භාණ්ඩ සෙවීම)',
            'desc': 'Focus product search bar immediately'
          },
          {
            'key': _posShortcuts['payCash'] ?? 'F2',
            'title': 'Cash Payment (මුදල් ගෙවීම)',
            'desc': 'Switch payment method to Cash'
          },
          {
            'key': _posShortcuts['payCard'] ?? 'F3',
            'title': 'Card Payment (කාඩ්පත්)',
            'desc': 'Switch payment method to Card'
          },
          {
            'key': _posShortcuts['holdCart'] ?? 'F4',
            'title': 'Hold Cart (බිල රඳවා තැබීම)',
            'desc': 'Hold active cart to serve another customer'
          },
          {
            'key': _posShortcuts['resumeCart'] ?? 'F5',
            'title': 'Resume Cart (රඳවාගත් බිල නැවත ලබාගැනීම)',
            'desc': 'Restore the last held customer cart'
          },
          {
            'key': _posShortcuts['clearCart'] ?? 'F6',
            'title': 'Clear Cart (හිස් කිරීම)',
            'desc': 'Clear all items in current cart'
          },
          {
            'key': _posShortcuts['billPreview'] ?? 'F7',
            'title': 'Bill Preview (බිල්පත පෙරදසුන)',
            'desc': 'Preview printed receipt before finalizing sale'
          },
          {
            'key': _posShortcuts['openDiscount'] ?? 'F8',
            'title': 'Apply Discount (වට්ටම් ලබා දීම)',
            'desc': 'Open bill discount window'
          },
          {
            'key': _posShortcuts['addCustomer'] ?? 'F9',
            'title': 'Select Customer (පාරිභෝගිකයා තෝරාගැනීම)',
            'desc': 'Focus customer search to link customer'
          },
          {
            'key': 'Click Item',
            'title': 'Quick Qty & Loose Popup',
            'desc': 'Click any item card to pick quantity or loose/box selling unit, then press Enter'
          },
        ];

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.keyboard_rounded, color: Color(0xFF6366F1), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('POS Keyboard Shortcuts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('යතුරුපුවරු කෙටිමං මඟින් ඉතා ඉක්මනින් බිල්පත් සකස් කරන්න', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: shortcutsList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final sc = shortcutsList[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      sc['key']!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  title: Text(sc['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(sc['desc']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close (වසන්න)'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _settingsTab = 'shortcuts';
                  _selectedNavKey = 'settings';
                });
              },
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Customize Shortcuts (සැකසුම්)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

double _posBagPriceSmall = 5.0;
double _posBagPriceMedium = 10.0;
double _posBagPriceLarge = 20.0;
double _posBagPriceCustom = 15.0;

class _ShoppingBagEntry {
  final String id;
  final String name;
  double price;
  int quantity;
  final String label;
  final String shortcutKey;
  final bool isCustom;

  _ShoppingBagEntry({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 0,
    required this.label,
    required this.shortcutKey,
    this.isCustom = false,
  });

  double get totalPrice => price * quantity;
}

class _ShoppingBagSelectionResult {
  final bool hasBags;
  final List<_ShoppingBagEntry> bags;

  _ShoppingBagSelectionResult({
    required this.hasBags,
    this.bags = const [],
  });

  double get totalCost =>
      bags.fold(0.0, (sum, b) => sum + (b.price * b.quantity));

  void applyToCart(
    Map<String, _ProductItem> temporaryCartProducts,
    Map<String, double> cart,
  ) {
    if (!hasBags) return;
    for (final bag in bags) {
      if (bag.quantity <= 0) continue;
      final itemId = 'SV:${bag.id}';
      temporaryCartProducts[itemId] = _ProductItem(
        id: itemId,
        name: bag.name,
        category: 'Packaging',
        price: bag.price,
        costPrice: 0.0,
        stock: 999999,
        minStock: 0,
        productType: 'SERVICE',
        barcode: 'BAG-${bag.price.toInt()}',
      );
      cart[itemId] = (cart[itemId] ?? 0.0) + bag.quantity.toDouble();
    }
  }
}
