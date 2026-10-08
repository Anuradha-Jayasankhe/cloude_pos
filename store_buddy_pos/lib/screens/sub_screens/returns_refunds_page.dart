part of '../dashboard_screen.dart';

extension _returns_refunds_pageExt on _DashboardScreenState {
  Future<void> _exportReturnsPdf(List<_ReturnItem> items) async {
    final doc = pw.Document();
    final headers = [
      'RMA',
      'Product',
      'Supplier',
      'Qty',
      'Condition',
      'Customer',
      'Reason',
      'Amount',
      'Method',
      'Status',
      'Date',
    ];
    final data = items.map((item) {
      final dateText =
          DateTime.tryParse(
            item.createdAt,
          )?.toLocal().toString().split(' ').first ??
          item.createdAt.split('T').first;
      return [
        item.rmaNumber,
        item.productName,
        item.supplier.trim().isNotEmpty
            ? item.supplier.trim()
            : _supplierLabelForProductId(item.productId),
        '${item.qty}',
        item.condition,
        item.customerName,
        item.reason,
        _money(item.amount),
        item.refundMethod,
        item.status,
        dateText,
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Returns & Refunds',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(headers: headers, data: data),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'returns_refunds.pdf',
    );
  }

  Future<void> _exportDamagedPdf(List<_DamagedInventoryItem> items) async {
    final doc = pw.Document();
    final headers = [
      'Date',
      'Product',
      'Supplier',
      'Qty',
      'Condition',
      'Reason',
      'Return Ref',
      'Status',
    ];
    final data = items.map((item) {
      final dateText =
          DateTime.tryParse(
            item.createdAt,
          )?.toLocal().toString().split(' ').first ??
          item.createdAt.split('T').first;
      return [
        dateText,
        item.productName,
        _supplierLabelForProductId(item.productId),
        '${item.qty}',
        item.condition,
        item.reason,
        item.returnId,
        item.status,
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Damaged / Scrap Inventory',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(headers: headers, data: data),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'damaged_inventory.pdf',
    );
  }

  // ── Status update with inventory + cash side-effects ─────────────────────
  Future<void> _updateReturnStatus(_ReturnItem item, String newStatus) async {
    if (item.status == newStatus) return;
    final now = DateTime.now().toIso8601String();

    if (newStatus == 'Approved' && item.status == 'Pending') {
      if (item.condition == 'Good' && item.productId.isNotEmpty) {
        final bool isLoose = item.productId.startsWith('LOOSE:');
        final String baseId =
            isLoose ? item.productId.substring(6) : item.productId;
        final idx = _products.indexWhere((p) => p.id == baseId);
        if (idx >= 0) {
          final p = _products[idx];
          final restockQty = isLoose && p.unitConversionRatio > 0
              ? (item.qty / p.unitConversionRatio)
              : item.qty;
          setState(() => p.stock += restockQty);
          await _enqueueSync('UPDATE', 'products', baseId);
        }
      } else if (item.condition != 'Good' && item.condition != '') {
        final dmg = _DamagedInventoryItem(
          id: 'DMG-${DateTime.now().millisecondsSinceEpoch}',
          productId: item.productId,
          productName: item.productName,
          qty: item.qty,
          reason: item.reason,
          condition: item.condition,
          returnId: item.id,
          status: 'QUARANTINE',
          createdAt: now,
        );
        setState(() => _damagedInventory.add(dmg));
        await _enqueueSync('INSERT', 'damaged_inventory', dmg.id);
      }
    }

    if (newStatus == 'Refunded' &&
        item.amount > 0 &&
        item.refundMethod != 'NO_PAYOUT' &&
        !item.cashImpact) {
      if (item.refundMethod == 'CASH') {
        final before = _cashInHand;
        final after = before - item.amount;
        final tx = _CashTransactionItem(
          id: 'CTX-${DateTime.now().millisecondsSinceEpoch}',
          type: 'OUT',
          referenceType: 'RETURN',
          referenceId: item.id,
          amount: item.amount,
          balanceBefore: before,
          balanceAfter: after,
          note: 'Cash refund for ${item.rmaNumber}',
          createdAt: now,
        );
        setState(() {
          _cashTransactions.add(tx);
          item.cashImpact = true;
          item.cashAdjustmentId = tx.id;
        });
        await _enqueueSync('INSERT', 'cash_transactions', tx.id);
      } else if (item.refundMethod == 'BANK' || item.refundMethod == 'CARD') {
        final tx = _BankTransaction(
          id: 'BTX-${DateTime.now().millisecondsSinceEpoch}',
          type: 'MANUAL_WITHDRAW',
          amount: item.amount,
          referenceId: item.id,
          notes: '${item.refundMethod} refund for ${item.rmaNumber}',
          createdAt: DateTime.now(),
        );
        setState(() {
          _bankTransactions.add(tx);
          _bankAccountBalance -= item.amount;
          item.cashImpact = true;
          item.cashAdjustmentId = tx.id;
        });
        await _enqueueSync('INSERT', 'bank_transactions', tx.id);
      }
      _addNotification(
        title: 'Return Refund Completed',
        message:
            'Refund of ${_money(item.amount)} issued for ${item.rmaNumber} via ${item.refundMethod}',
        type: 'RETURN_REFUNDED',
        targetLocation: _activeLocationForWrites,
        referenceId: item.id,
      );
      _addNotification(
        title: 'Return Refund Completed (HQ)',
        message:
            'Refund ${_money(item.amount)} issued at ${_activeLocationForWrites} (${item.rmaNumber})',
        type: 'RETURN_REFUNDED',
        targetLocation: 'Main Branch',
        referenceId: item.id,
      );
    }

    setState(() {
      item.status = newStatus;
      item.updatedAt = now;
    });
    await _persistWorkspaceData();
    await _enqueueSync('UPDATE', 'returns', item.id);
  }

  Future<void> _showEditReturnDialog(_ReturnItem item) async {
    final productCtrl = TextEditingController(text: item.productName);
    final customerCtrl = TextEditingController(text: item.customerName);
    final reasonCtrl = TextEditingController(text: item.reason);
    final supplierCtrl = TextEditingController(text: item.supplier);
    final qtyCtrl = TextEditingController(text: '${item.qty}');
    final amountCtrl = TextEditingController(
      text: item.amount.toStringAsFixed(2),
    );
    String condition = item.condition;
    String refundMethod = item.refundMethod;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text('Edit Return - ${item.rmaNumber}'),
              content: SizedBox(
                width: ResponsiveLayout.adaptiveDialogWidth(ctx, 420),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: productCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Refund Amount',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: customerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: supplierCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: condition,
                        decoration: const InputDecoration(
                          labelText: 'Product Condition',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                                  'Good',
                                  'Damaged',
                                  'Opened Box',
                                  'Used',
                                  'Expired',
                                  'Missing Parts',
                                ]
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) setLocal(() => condition = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: refundMethod,
                        decoration: const InputDecoration(
                          labelText: 'Refund Method',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'CASH',
                            child: Text('Cash Refund'),
                          ),
                          DropdownMenuItem(
                            value: 'STORE_CREDIT',
                            child: Text('Store Credit'),
                          ),
                          DropdownMenuItem(
                            value: 'EXCHANGE',
                            child: Text('Product Exchange'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setLocal(() => refundMethod = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      productCtrl.dispose();
      customerCtrl.dispose();
      reasonCtrl.dispose();
      supplierCtrl.dispose();
      qtyCtrl.dispose();
      amountCtrl.dispose();
      return;
    }

    final newQty = int.tryParse(qtyCtrl.text.trim()) ?? item.qty;
    final newAmount = double.tryParse(amountCtrl.text.trim()) ?? item.amount;

    setState(() {
      item.productName = productCtrl.text.trim().isEmpty
          ? item.productName
          : productCtrl.text.trim();
      item.customerName = customerCtrl.text.trim();
      item.reason = reasonCtrl.text.trim();
      item.supplier = supplierCtrl.text.trim();
      item.qty = newQty < 1 ? 1.0 : newQty.toDouble();
      item.amount = newAmount < 0 ? 0 : newAmount;
      item.condition = condition;
      item.refundMethod = refundMethod;
      item.updatedAt = DateTime.now().toIso8601String();
    });
    await _persistWorkspaceData();
    await _enqueueSync('UPDATE', 'returns', item.id);

    productCtrl.dispose();
    customerCtrl.dispose();
    reasonCtrl.dispose();
    supplierCtrl.dispose();
    qtyCtrl.dispose();
    amountCtrl.dispose();
  }

  double _returnedQtyForSaleItem(String saleId, String productId) {
    if (saleId.isEmpty || productId.isEmpty) return 0.0;
    return _returns
        .where(
          (r) =>
              r.saleId == saleId &&
              r.productId == productId &&
              r.status != 'Rejected',
        )
        .fold<double>(0, (sum, r) => sum + r.qty);
  }

  String _supplierLabelForProductId(String productId) {
    if (productId.isEmpty) return 'N/A';
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      if (product.supplierId.isEmpty) return 'N/A';
      final supplier = _suppliers.firstWhere(
        (s) => s.id == product.supplierId,
        orElse: () =>
            _SupplierItem(id: '', name: 'Unknown', contact: '', email: ''),
      );
      final name = supplier.name.isNotEmpty
          ? supplier.name
          : supplier.companyName;
      final contact = supplier.contact.trim();
      return contact.isEmpty ? name : '$name - $contact';
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> _updateDamagedInventoryStatus(
    _DamagedInventoryItem item,
    String newStatus,
  ) async {
    if (item.status == newStatus) return;
    final previous = item.status;
    setState(() => item.status = newStatus);

    final shouldLog = previous == 'QUARANTINE' && newStatus != 'QUARANTINE';
    if (shouldLog) {
      final index = _products.indexWhere((p) => p.id == item.productId);
      if (index >= 0) {
        final product = _products[index];
        final before = product.stock;
        final after = product.stock;
        final reason = newStatus == 'SCRAPPED'
            ? 'Damaged item scrapped'
            : 'Damaged item returned to supplier';
        final audit = _StockAdjustmentItem(
          id: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          productName: product.name,
          delta: 0,
          beforeStock: before,
          afterStock: after,
          reason: reason,
          performedBy: _profileName,
          unitCost: product.costPrice,
          adjustedStockValue: 0,
          createdAt: DateTime.now(),
        );
        setState(() => _stockAdjustments.insert(0, audit));
        await _enqueueSync('INSERT', 'stock_adjustments', audit.id);
      }
    }

    await _persistWorkspaceData();
    await _enqueueSync('UPDATE', 'damaged_inventory', item.id);
  }

  // ── Create return (always Pending) ────────────────────────────────────────
  Future<void> _createReturn() async {
    final created = await _showReturnDialog();
    if (created == null || created.isEmpty) return;
    String? updatedSaleId;
    String? updatedStatus;
    setState(() {
      for (final item in created.reversed) {
        _returns.insert(0, item);
      }
      final saleId = created.first.saleId;
      if (saleId.isNotEmpty) {
        final sIdx = _sales.indexWhere((s) => s.id == saleId);
        if (sIdx >= 0) {
          final s = _sales[sIdx];
          double totalSold = s.items.fold<double>(0, (sum, i) => sum + i.quantity);
          double totalReturned = 0;
          for (final item in s.items) {
            totalReturned += _returnedQtyForSaleItem(s.id, item.productId);
          }
          final isUnpaidCod = s.status == 'COD_PENDING' || (s.paymentMethod == 'COD' && s.amountPaid <= 0);
          final newStatus = totalReturned >= totalSold
              ? (isUnpaidCod ? 'CANCELLED' : 'RETURNED')
              : 'PARTIALLY_RETURNED';
          _sales[sIdx].status = newStatus;
          updatedSaleId = s.id;
          updatedStatus = newStatus;
        }
      }
    });

    if (updatedSaleId != null && updatedStatus != null) {
      if (_saleRepository != null) {
        await _saleRepository!.updateSaleStatus(
          saleId: updatedSaleId!,
          status: updatedStatus!,
        );
      }
      await _enqueueSync('UPDATE', 'sales', updatedSaleId!);
    }

    await _persistWorkspaceData();
    for (final item in created) {
      await _enqueueSync('INSERT', 'returns', item.id);
      _addNotification(
        title: 'Return Submitted',
        message: 'New Return ${item.rmaNumber} for ${item.productName} (${_money(item.amount)})',
        type: 'RETURN_SUBMITTED',
        targetLocation: _activeLocationForWrites,
        referenceId: item.id,
      );
      if (_activeLocationForWrites != 'Main Branch') {
        _addNotification(
          title: 'Return Submitted (HQ)',
          message:
              'New Return ${item.rmaNumber} at $_activeLocationForWrites for ${item.productName} (${_money(item.amount)})',
          type: 'RETURN_SUBMITTED',
          targetLocation: 'Main Branch',
          referenceId: item.id,
        );
      }
    }
    final creditItems = created
        .where(
          (item) =>
              item.refundMethod == 'STORE_CREDIT' ||
              item.refundMethod == 'EXCHANGE',
        )
        .toList();
    if (creditItems.isNotEmpty) {
      final total = creditItems.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );
      final seed = creditItems.first;
      final aggregate = _ReturnItem(
        id: 'RTN-${DateTime.now().millisecondsSinceEpoch}-BATCH',
        saleId: seed.saleId,
        customerId: seed.customerId,
        rmaNumber: seed.rmaNumber,
        productId: seed.productId,
        productName: seed.productName,
        customerName: seed.customerName,
        reason: seed.reason,
        supplier: seed.supplier,
        amount: total,
        qty: seed.qty,
        condition: seed.condition,
        refundMethod: seed.refundMethod,
        status: seed.status,
        createdAt: seed.createdAt,
      );
      await _startStoreCreditExchange(aggregate);
    }
  }

  // ── Store-credit / Exchange helper ────────────────────────────────────────
  Future<void> _startStoreCreditExchange(_ReturnItem item) async {
    final amt = item.amount.abs();
    if (amt <= 0) return;
    final cartId = _returnStoreCreditCartItemId(item.id);
    final custId = item.customerId.isNotEmpty
        ? item.customerId
        : _findCustomerIdByName(item.customerName);
    setState(() {
      _temporaryCartProducts[cartId] = _ProductItem(
        id: cartId,
        name: 'Return Credit ${item.rmaNumber}',
        locationId: _activeLocationForWrites,
        category: 'Return Credit',
        barcode: item.id,
        productType: 'SERVICE',
        description: 'Store credit from ${item.rmaNumber}',
        price: -amt,
        stock: 1,
        minStock: 0,
      );
      _cart
        ..clear()
        ..[cartId] = 1;
      if (custId != null && custId.isNotEmpty) _selectedCustomerId = custId;
      _selectedNavKey = 'pos';
      _paymentMethodController.text = 'CASH';
      _amountPaidController.clear();
      _chequeNumberController.clear();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Store credit ${_money(amt)} added to POS. Add replacement items then complete the sale.',
        ),
      ),
    );
  }

  // ── Main page ────────────────────────────────────────────────────────────
  Widget _buildReturnsRefundsPage() {
    final today = DateTime.now();
    final q = _returnsSearchController.text.trim().toLowerCase();
    final filtered = _scopedReturns.where((item) {
      final stOk =
          _returnsStatusFilter == 'All Statuses' ||
          item.status == _returnsStatusFilter;
      final reOk =
          _returnsReasonFilter == 'All Reasons' ||
          item.reason == _returnsReasonFilter;
      if (!stOk || !reOk) return false;
      if (q.isEmpty) return true;
      return item.rmaNumber.toLowerCase().contains(q) ||
          item.productName.toLowerCase().contains(q) ||
          item.customerName.toLowerCase().contains(q);
    }).toList();

    final reasons = [
      'All Reasons',
      ..._scopedReturns.map((e) => e.reason).toSet(),
    ];
    final pending = _scopedReturns.where((e) => e.status == 'Pending').length;
    final approved = _scopedReturns.where((e) => e.status == 'Approved').length;
    final refunded = _scopedReturns.where((e) => e.status == 'Refunded').length;
    final totalRefund = _scopedReturns
        .where((e) => e.status == 'Refunded')
        .fold<double>(0, (s, e) => s + e.amount);
    final cashSales = _scopedSales
        .where(
          (s) =>
              s.paymentMethod == 'CASH' &&
              s.createdAt.year == today.year &&
              s.createdAt.month == today.month &&
              s.createdAt.day == today.day,
        )
        .fold<double>(0, (s, e) => s + e.total);
    final cashRefunds = _scopedCashTransactions
        .where(
          (t) =>
              t.type == 'OUT' &&
              (DateTime.tryParse(t.createdAt)?.day == today.day),
        )
        .fold<double>(0, (s, e) => s + e.amount);

    const cardW = 210.0;
    final cards = [
      _rCard(
        'Total Returns',
        '${_scopedReturns.length}',
        const Color(0xFF7A68A5),
        Icons.assignment_return_rounded,
        cardW,
      ),
      _rCard(
        'Pending',
        '$pending',
        const Color(0xFFD78E12),
        Icons.pending_actions_rounded,
        cardW,
      ),
      _rCard(
        'Approved',
        '$approved',
        const Color(0xFF8F5DDE),
        Icons.verified_rounded,
        cardW,
      ),
      _rCard(
        'Refunded',
        '$refunded',
        const Color(0xFF179C52),
        Icons.published_with_changes_rounded,
        cardW,
      ),
      _rCard(
        'Total Refunds',
        _money(totalRefund),
        AppTheme.brandIndigo,
        Icons.payments_rounded,
        cardW,
      ),
      _rCard(
        'Cash Sales (Today)',
        _money(cashSales),
        const Color(0xFF1976D2),
        Icons.point_of_sale_rounded,
        cardW,
      ),
      _rCard(
        'Cash Refunds (Today)',
        _money(cashRefunds),
        const Color(0xFFD32F2F),
        Icons.money_off_rounded,
        cardW,
      ),
      _rCard(
        'Net Cash Balance',
        _money(_cashInHand),
        const Color(0xFF009688),
        Icons.account_balance_wallet_rounded,
        cardW,
      ),
    ];

    // SizedBox.expand forces this page to take the full shell height so
    // Expanded + TabBarView get a real viewport. Each tab body is itself
    // vertically scrollable so filters, empty states, and table rows at
    // the bottom are never clipped.
    return SizedBox.expand(
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Returns & Refunds',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Manage returns, refunds and inventory adjustments',
                        style: TextStyle(
                          color: Color(0xFF6D7383),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _createReturn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandIndigo,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Return'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => cards[i],
              ),
            ),
            const SizedBox(height: 8),
            const TabBar(
              tabs: [
                Tab(text: 'Returns & Refunds'),
                Tab(text: 'Damaged / Scrap'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildReturnListTab(filtered, reasons),
                  _buildDamagedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rCard(String title, String value, Color accent, IconData iconData, double w) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  iconData,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnListTab(List<_ReturnItem> filtered, List<String> reasons) {
    // Whole tab body scrolls vertically so filters, list title, empty state,
    // and every table row (including bottom actions) stay reachable.
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: _adaptiveWidth(
                          400,
                          minWidth: 200,
                          horizontalPadding: 40,
                        ),
                        child: TextField(
                          controller: _returnsSearchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search RMA, product, customer...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<String>(
                          initialValue: _returnsStatusFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          items:
                              [
                                    'All Statuses',
                                    'Pending',
                                    'Approved',
                                    'Refunded',
                                    'Rejected',
                                  ]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(
                            () => _returnsStatusFilter = v ?? 'All Statuses',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: DropdownButtonFormField<String>(
                          initialValue: reasons.contains(_returnsReasonFilter)
                              ? _returnsReasonFilter
                              : 'All Reasons',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          items: reasons
                              .map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis)),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () => _returnsReasonFilter = v ?? 'All Reasons',
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: filtered.isEmpty
                            ? null
                            : () => _exportReturnsPdf(filtered),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Export PDF'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Returns List (${filtered.length})',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    SizedBox(
                      height: math.max(220.0, constraints.maxHeight - 180),
                      child: const Center(
                        child: Text(
                          'No returns found',
                          style: TextStyle(
                            color: Color(0xFF8780A0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  else
                    Scrollbar(
                      notificationPredicate: (n) =>
                          n.metrics.axis == Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        primary: false,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: math.max(constraints.maxWidth, 1280.0),
                          ),
                          child: DataTable(
                            columnSpacing: 16,
                            horizontalMargin: 12,
                            headingRowColor: WidgetStateProperty.all(
                              _tableHeaderColor,
                            ),
                            columns: const [
                              DataColumn(label: Text('RMA')),
                              DataColumn(label: Text('PRODUCT')),
                              DataColumn(label: Text('SUPPLIER')),
                              DataColumn(label: Text('QTY')),
                              DataColumn(label: Text('CONDITION')),
                              DataColumn(label: Text('CUSTOMER')),
                              DataColumn(label: Text('REASON')),
                              DataColumn(label: Text('AMOUNT')),
                              DataColumn(label: Text('METHOD')),
                              DataColumn(label: Text('STATUS')),
                              DataColumn(label: Text('DATE')),
                              DataColumn(label: Text('ACTIONS')),
                            ],
                            rows: filtered.map((item) {
                              final validStatuses = [
                                'Pending',
                                'Approved',
                                'Refunded',
                                'Rejected',
                              ];
                              final currentStatus =
                                  validStatuses.contains(item.status)
                                  ? item.status
                                  : 'Pending';
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item.rmaNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        item.productName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        item.supplier.trim().isNotEmpty
                                            ? item.supplier.trim()
                                            : _supplierLabelForProductId(
                                                item.productId,
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${item.qty}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(_conditionChip(item.condition)),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        item.customerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        item.reason,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _money(item.amount),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      item.refundMethod,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    DropdownButton<String>(
                                      value: currentStatus,
                                      underline: const SizedBox(),
                                      isDense: true,
                                      dropdownColor: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      iconEnabledColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      items: validStatuses
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s,
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          _updateReturnStatus(item, v);
                                        }
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      DateTime.tryParse(item.createdAt)
                                              ?.toLocal()
                                              .toString()
                                              .split(' ')
                                              .first ??
                                          item.createdAt.split('T').first,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      tooltip: 'Edit Return',
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _showEditReturnDialog(item),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _conditionChip(String condition) {
    final color = condition == 'Good'
        ? const Color(0xFF179C52)
        : condition == 'Damaged'
        ? const Color(0xFFD32F2F)
        : const Color(0xFFD78E12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.trim().toUpperCase();
    final color = normalized == 'QUARANTINE'
        ? const Color(0xFFD78E12)
        : normalized == 'SCRAPPED'
        ? const Color(0xFFD32F2F)
        : const Color(0xFF2E7D32);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDamagedTab() {
    final filteredDamaged = _damagedFilter == 'All'
        ? _scopedDamagedInventory
        : _scopedDamagedInventory
              .where((d) => d.condition == _damagedFilter)
              .toList();

    // Same pattern as returns tab: full vertical scroll so empty state and
    // bottom rows are always reachable.
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Damaged / Scrap Inventory (${filteredDamaged.length})',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: filteredDamaged.isEmpty
                            ? null
                            : () => _exportDamagedPdf(filteredDamaged),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Export PDF'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterButton('All'),
                      _filterButton('Damaged'),
                      _filterButton('Expired'),
                      _filterButton('Removed'),
                      _filterButton('Returned'),
                      const SizedBox(width: 8),
                      _statusChip('QUARANTINE'),
                      _statusChip('SCRAPPED'),
                      _statusChip('RETURNED_TO_SUPPLIER'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filteredDamaged.isEmpty)
                    SizedBox(
                      height: math.max(220.0, constraints.maxHeight - 160),
                      child: const Center(
                        child: Text(
                          'No damaged items logged',
                          style: TextStyle(
                            color: Color(0xFF8780A0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  else
                    Scrollbar(
                      notificationPredicate: (n) =>
                          n.metrics.axis == Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        primary: false,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: math.max(constraints.maxWidth, 980.0),
                          ),
                          child: DataTable(
                            columnSpacing: 16,
                            horizontalMargin: 12,
                            headingRowColor: WidgetStateProperty.all(
                              _tableHeaderColor,
                            ),
                            columns: const [
                              DataColumn(label: Text('DATE')),
                              DataColumn(label: Text('PRODUCT')),
                              DataColumn(label: Text('SUPPLIER')),
                              DataColumn(label: Text('QTY')),
                              DataColumn(label: Text('CONDITION')),
                              DataColumn(label: Text('REASON')),
                              DataColumn(label: Text('RETURN REF')),
                              DataColumn(label: Text('STATUS')),
                            ],
                            rows: filteredDamaged.map((d) {
                              final supplierName = _supplierLabelForProductId(
                                d.productId,
                              );

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      DateTime.tryParse(d.createdAt)
                                              ?.toLocal()
                                              .toString()
                                              .split(' ')
                                              .first ??
                                          d.createdAt.split('T').first,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        d.productName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        supplierName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '${d.qty}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(_conditionChip(d.condition)),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        d.reason,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      d.returnId,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DataCell(
                                    DropdownButton<String>(
                                      value:
                                          [
                                            'QUARANTINE',
                                            'SCRAPPED',
                                            'RETURNED_TO_SUPPLIER',
                                          ].contains(d.status)
                                          ? d.status
                                          : 'QUARANTINE',
                                      underline: const SizedBox(),
                                      isDense: true,
                                      dropdownColor: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      iconEnabledColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      items:
                                          [
                                                'QUARANTINE',
                                                'SCRAPPED',
                                                'RETURNED_TO_SUPPLIER',
                                              ]
                                              .map(
                                                (s) => DropdownMenuItem(
                                                  value: s,
                                                  child: Text(
                                                    s,
                                                    style: TextStyle(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (v) {
                                        if (v == null) return;
                                        _updateDamagedInventoryStatus(d, v);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filterButton(String label) {
    final selected = _damagedFilter == label;
    return OutlinedButton(
      onPressed: () => setState(() => _damagedFilter = label),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primary
            : null,
        foregroundColor: selected ? Colors.white : null,
      ),
      child: Text(label),
    );
  }

  // â”€â”€ Create Return Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<List<_ReturnItem>?> _showReturnDialog({
    _SaleRecord? preloadedSale,
  }) async {
    final saleCtrl = TextEditingController(text: preloadedSale?.id ?? '');
    final manualProductCtrl = TextEditingController();
    final customerCtrl = TextEditingController(
      text: preloadedSale?.customerName ?? '',
    );
    final reasonCtrl = TextEditingController();
    final manualAmountCtrl = TextEditingController(text: '0');
    final manualQtyCtrl = TextEditingController(text: '1');
    String refundMethod = 'CASH';
    String condition = 'Good';
    String infoText = preloadedSale != null
        ? 'Sale ${preloadedSale.id} loaded.'
        : '';
    bool manualEntry = preloadedSale != null;
    _SaleRecord? matchedSale = preloadedSale;

    final selectedProductIds = <String, bool>{};
    final returnQuantities = <String, double>{};
    bool refundDeliveryFee = false;

    void initSale(_SaleRecord sale) {
      matchedSale = sale;
      customerCtrl.text = sale.customerName;
      selectedProductIds.clear();
      returnQuantities.clear();
      refundDeliveryFee = false;
      for (final item in sale.items) {
        final returned = _returnedQtyForSaleItem(sale.id, item.productId);
        final available = item.quantity - returned;
        if (available > 0) {
          selectedProductIds[item.productId] = true;
          returnQuantities[item.productId] = available >= 1.0 ? 1.0 : available;
        } else {
          selectedProductIds[item.productId] = false;
          returnQuantities[item.productId] = 0.0;
        }
      }
      manualEntry = true;
    }

    if (preloadedSale != null) {
      initSale(preloadedSale);
    }

    return showGeneralDialog<List<_ReturnItem>>(
      context: context,
      barrierLabel: 'CreateReturn',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim, _) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final compact =
                MediaQuery.of(ctx).size.width < UiBreakpoints.tablet;
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final hasSale = matchedSale != null;
            final isUnpaidCod = hasSale &&
                (matchedSale!.status == 'COD_PENDING' ||
                    (matchedSale!.paymentMethod == 'COD' && (matchedSale!.amountPaid ?? 0) <= 0));
            final saleItems = matchedSale?.items ?? const <_SaleItemSnapshot>[];

            // Helper to compute exact unit refund breakdown for a sale line item
            Map<String, double> getSaleItemRefundBreakdown(_SaleItemSnapshot item) {
              if (matchedSale == null || item.quantity <= 0) {
                return {
                  'unitBasePrice': item.unitPrice,
                  'unitDiscount': 0.0,
                  'unitSubtotal': item.unitPrice,
                  'unitTax': 0.0,
                  'unitRefund': item.unitPrice,
                };
              }
              final sale = matchedSale!;
              final saleSubtotal = sale.subtotal > 0
                  ? sale.subtotal
                  : sale.items.fold<double>(
                      0.0,
                      (s, i) => s + (i.lineTotal > 0 ? i.lineTotal : i.unitPrice * i.quantity),
                    );

              final lineVal = item.lineTotal > 0 ? item.lineTotal : item.unitPrice * item.quantity;
              final ratio = saleSubtotal > 0 ? (lineVal / saleSubtotal) : (1.0 / (sale.items.isNotEmpty ? sale.items.length : 1));

              // Proportionate invoice discount
              final propInvoiceDiscount = (sale.discount > 0) ? (ratio * sale.discount) : 0.0;
              final netLineSubtotal = (lineVal - propInvoiceDiscount).clamp(0.0, double.infinity);

              // Proportionate tax
              final netSaleTaxable = (saleSubtotal - sale.discount).clamp(0.0, double.infinity);
              final propTax = (sale.tax > 0 && netSaleTaxable > 0)
                  ? ((netLineSubtotal / netSaleTaxable) * sale.tax)
                  : 0.0;

              final totalLineNetPaid = netLineSubtotal + propTax;
              final unitRefund = totalLineNetPaid / item.quantity;
              final unitDiscount = (lineVal - netLineSubtotal) / item.quantity;
              final unitTax = propTax / item.quantity;
              final unitBasePrice = (lineVal / item.quantity);

              return {
                'unitBasePrice': unitBasePrice,
                'unitDiscount': unitDiscount,
                'unitSubtotal': netLineSubtotal / item.quantity,
                'unitTax': unitTax,
                'unitRefund': unitRefund,
              };
            }

            double rawItemsRefundValue = 0.0;
            if (hasSale) {
              for (final item in saleItems) {
                if (selectedProductIds[item.productId] == true) {
                  final q = returnQuantities[item.productId] ?? 0.0;
                  final bd = getSaleItemRefundBreakdown(item);
                  rawItemsRefundValue += bd['unitRefund']! * q;
                }
              }
            } else {
              rawItemsRefundValue = double.tryParse(manualAmountCtrl.text.trim()) ?? 0.0;
            }

            final double deliveryFee = (hasSale && (matchedSale!.shippingCharges > 0))
                ? matchedSale!.shippingCharges
                : 0.0;
            final double shippingRefund = (!isUnpaidCod && refundDeliveryFee && hasSale)
                ? deliveryFee
                : 0.0;

            final double totalRefund = isUnpaidCod
                ? 0.0
                : (rawItemsRefundValue + shippingRefund).clamp(
                    0.0,
                    (matchedSale?.amountPaid != null && matchedSale!.amountPaid > 0)
                        ? matchedSale!.amountPaid
                        : double.infinity,
                  );
            final originalTotal = matchedSale?.total ?? rawItemsRefundValue;
            final retainedTotal = (originalTotal - totalRefund).clamp(0.0, double.infinity);

            if (isUnpaidCod && refundMethod != 'NO_PAYOUT') {
              refundMethod = 'NO_PAYOUT';
            }

            bool canSubmit = false;
            if (hasSale) {
              final anySelected = saleItems.any(
                (item) =>
                    selectedProductIds[item.productId] == true &&
                    (returnQuantities[item.productId] ?? 0) > 0,
              );
              canSubmit = anySelected &&
                  customerCtrl.text.trim().isNotEmpty &&
                  reasonCtrl.text.trim().isNotEmpty &&
                  (isUnpaidCod || rawItemsRefundValue > 0 || shippingRefund > 0);
            } else {
              canSubmit = manualProductCtrl.text.trim().isNotEmpty &&
                  customerCtrl.text.trim().isNotEmpty &&
                  reasonCtrl.text.trim().isNotEmpty &&
                  (double.tryParse(manualQtyCtrl.text.trim()) ?? 0) > 0 &&
                  rawItemsRefundValue > 0;
            }

            return _SideSheetContainer(
              title: 'Create Return',
              width: compact ? MediaQuery.of(ctx).size.width * 0.95 : 820,
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: canSubmit
                        ? () {
                            final now = DateTime.now().toUtc();
                            final custId =
                                _findCustomerIdByName(
                                  customerCtrl.text.trim(),
                                ) ??
                                '';
                            if (matchedSale != null) {
                              final results = <_ReturnItem>[];
                              for (final item in saleItems) {
                                if (selectedProductIds[item.productId] != true) {
                                  continue;
                                }
                                final qty = returnQuantities[item.productId] ?? 0.0;
                                if (qty <= 0) continue;
                                final bd = getSaleItemRefundBreakdown(item);
                                final unitRefund = isUnpaidCod ? 0.0 : bd['unitRefund']!;
                                final lineAmount = unitRefund * qty;
                                final lineSubtotal = (bd['unitSubtotal'] ?? 0.0) * qty;
                                final lineDiscount = (bd['unitDiscount'] ?? 0.0) * qty;
                                final lineTax = (bd['unitTax'] ?? 0.0) * qty;

                                results.add(
                                  _ReturnItem(
                                    id: 'RTN-${now.millisecondsSinceEpoch}-${results.length}',
                                    saleId: matchedSale!.id,
                                    customerId: custId,
                                    rmaNumber:
                                        'RMA-${now.millisecondsSinceEpoch % 100000}',
                                    productId: item.productId,
                                    productName: item.productName,
                                    customerName: customerCtrl.text.trim(),
                                    reason: reasonCtrl.text.trim().isNotEmpty
                                        ? reasonCtrl.text.trim()
                                        : (isUnpaidCod ? 'Unpaid COD Order Cancelled / Restocked' : 'Customer Return'),
                                    supplier: '',
                                    amount: lineAmount,
                                    qty: qty,
                                    subtotalAmount: lineSubtotal,
                                    discountAmount: lineDiscount,
                                    taxAmount: lineTax,
                                    condition: condition,
                                    refundMethod: isUnpaidCod ? 'NO_PAYOUT' : refundMethod,
                                    status: 'Pending',
                                    createdAt: now.toIso8601String(),
                                  ),
                                );
                              }
                              if (results.isEmpty) return;
                              if (!isUnpaidCod && refundDeliveryFee && shippingRefund > 0) {
                                final first = results.first;
                                results[0] = _ReturnItem(
                                  id: first.id,
                                  saleId: first.saleId,
                                  customerId: first.customerId,
                                  rmaNumber: first.rmaNumber,
                                  productId: first.productId,
                                  productName: first.productName,
                                  customerName: customerCtrl.text.trim(),
                                  reason: '${first.reason} [Incl. Delivery Fee: ${_money(shippingRefund)}]',
                                  supplier: first.supplier,
                                  amount: first.amount + shippingRefund,
                                  qty: first.qty,
                                  subtotalAmount: first.subtotalAmount,
                                  discountAmount: first.discountAmount,
                                  taxAmount: first.taxAmount,
                                  condition: first.condition,
                                  refundMethod: first.refundMethod,
                                  status: first.status,
                                  createdAt: first.createdAt,
                                );
                              }
                              Navigator.pop(ctx, results);
                              return;
                            }

                            final manualQty = double.tryParse(manualQtyCtrl.text.trim()) ?? 1.0;
                            Navigator.pop(ctx, [
                              _ReturnItem(
                                id: 'RTN-${now.millisecondsSinceEpoch}',
                                saleId: '',
                                customerId: custId,
                                rmaNumber:
                                    'RMA-${now.millisecondsSinceEpoch % 100000}',
                                productId: '',
                                productName: manualProductCtrl.text.trim(),
                                customerName: customerCtrl.text.trim(),
                                reason: reasonCtrl.text.trim(),
                                supplier: '',
                                amount: totalRefund,
                                qty: manualQty,
                                condition: condition,
                                refundMethod: refundMethod,
                                status: 'Pending',
                                createdAt: now.toIso8601String(),
                              ),
                            ]);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                      disabledForegroundColor: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF9CA3AF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      isUnpaidCod
                          ? 'Cancel Order & Restock Items'
                          : (totalRefund > 0
                              ? 'Submit Return (${_money(totalRefund)})'
                              : 'Submit Return'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 1: Search Invoice (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: saleCtrl,
                            decoration: InputDecoration(
                              hintText: 'Receipt/Invoice number or customer name...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: saleCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setLocal(() {
                                          saleCtrl.clear();
                                          matchedSale = null;
                                          selectedProductIds.clear();
                                          returnQuantities.clear();
                                          infoText = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(UiRadius.md),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (term) {
                              final sq = term.trim().toLowerCase();
                              if (sq.isEmpty) return;
                              final sale = _scopedSales
                                  .cast<_SaleRecord?>()
                                  .firstWhere(
                                    (r) =>
                                        r!.id.toLowerCase().contains(sq) ||
                                        r.customerName.toLowerCase().contains(sq),
                                    orElse: () => null,
                                  );
                              if (sale != null) {
                                setLocal(() {
                                  initSale(sale);
                                  infoText = 'Sale ${sale.id} loaded.';
                                });
                              } else {
                                setLocal(() {
                                  infoText = 'No sale found matching "$sq".';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UiRadius.md),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onPressed: () {
                            final sq = saleCtrl.text.trim().toLowerCase();
                            if (sq.isEmpty) {
                              setLocal(() => infoText = 'Enter invoice number to search.');
                              return;
                            }
                            final sale = _scopedSales
                                .cast<_SaleRecord?>()
                                .firstWhere(
                                  (r) =>
                                      r!.id.toLowerCase().contains(sq) ||
                                      r.customerName.toLowerCase().contains(sq),
                                  orElse: () => null,
                                );
                            if (sale != null) {
                              setLocal(() {
                                initSale(sale);
                                infoText = 'Sale ${sale.id} loaded.';
                              });
                            } else {
                              setLocal(() {
                                infoText = 'No sale found matching "$sq".';
                              });
                            }
                          },
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => setLocal(() {
                            manualEntry = true;
                            matchedSale = null;
                            selectedProductIds.clear();
                            returnQuantities.clear();
                            infoText = 'Manual Entry Mode';
                          }),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UiRadius.md),
                            ),
                          ),
                          child: const Text('Skip - Manual Entry'),
                        ),
                        if (matchedSale != null) ...[
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () => setLocal(() {
                              matchedSale = null;
                              saleCtrl.clear();
                              selectedProductIds.clear();
                              returnQuantities.clear();
                              infoText = '';
                            }),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Clear Loaded Sale'),
                          ),
                        ],
                      ],
                    ),
                    if (infoText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          infoText,
                          style: TextStyle(
                            color: matchedSale != null
                                ? const Color(0xFF10B981)
                                : Theme.of(ctx).colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    if (manualEntry) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),

                      if (isUnpaidCod)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            border: Border.all(
                              color: Colors.amber.shade700.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.amber, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'COD Order - Payment Pending (Unpaid)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Customer has not made any payment yet. Submitting this return will restock inventory and cancel this order without issuing a cash payout or deducting from store revenue.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.amber.shade100 : Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Return Items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasSale && saleItems.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                final anyUnselected = saleItems.any(
                                  (item) {
                                    final ret = _returnedQtyForSaleItem(matchedSale!.id, item.productId);
                                    final avail = item.quantity - ret;
                                    return avail > 0 && selectedProductIds[item.productId] != true;
                                  },
                                );
                                setLocal(() {
                                  for (final item in saleItems) {
                                    final ret = _returnedQtyForSaleItem(matchedSale!.id, item.productId);
                                    final avail = item.quantity - ret;
                                    if (avail > 0) {
                                      selectedProductIds[item.productId] = anyUnselected;
                                      if (anyUnselected && (returnQuantities[item.productId] ?? 0) <= 0) {
                                        returnQuantities[item.productId] = 1.0;
                                      }
                                    }
                                  }
                                });
                              },
                              child: Text(
                                saleItems.any((item) => selectedProductIds[item.productId] == true)
                                    ? 'Deselect All'
                                    : 'Select All Returnable',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (hasSale) ...[
                        if (saleItems.isEmpty)
                          const Text('No items in this invoice.')
                        else ...[
                          Column(
                            children: saleItems.map((item) {
                              final returnedQty = _returnedQtyForSaleItem(
                                matchedSale!.id,
                                item.productId,
                              );
                              final availableQty = item.quantity - returnedQty;
                              final isSelected = selectedProductIds[item.productId] == true;
                              final currentQty = returnQuantities[item.productId] ?? 1.0;
                              final bd = getSaleItemRefundBreakdown(item);
                              final unitRefund = isUnpaidCod ? 0.0 : bd['unitRefund']!;
                              final lineRefund = isSelected ? unitRefund * currentQty : 0.0;
                              final canReturn = availableQty > 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? const Color(0xFF312E81).withValues(alpha: 0.3)
                                          : const Color(0xFFEEF2FF))
                                      : (isDark
                                          ? const Color(0xFF1F2937)
                                          : const Color(0xFFF9FAFB)),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF6366F1)
                                        : (isDark
                                            ? const Color(0xFF374151)
                                            : const Color(0xFFE5E7EB)),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(UiRadius.md),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: canReturn
                                          ? (v) {
                                              setLocal(() {
                                                selectedProductIds[item.productId] = v ?? false;
                                                if (v == true && (returnQuantities[item.productId] ?? 0) <= 0) {
                                                  returnQuantities[item.productId] = 1.0;
                                                }
                                              });
                                            }
                                          : null,
                                      activeColor: const Color(0xFF6366F1),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              decoration: canReturn ? null : TextDecoration.lineThrough,
                                              color: canReturn ? null : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Sold: ${item.quantity.toInt()}',
                                                  style: const TextStyle(fontSize: 11.5),
                                                ),
                                              ),
                                              if (returnedQty > 0)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Returned: ${returnedQty.toInt()}',
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: Colors.orange,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: canReturn
                                                      ? Colors.green.withValues(alpha: 0.15)
                                                      : Colors.red.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  canReturn
                                                      ? 'Available: ${availableQty.toInt()}'
                                                      : 'Already Fully Returned',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: canReturn ? Colors.green : Colors.red,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'Price: ${_money(bd['unitBasePrice']!)}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              if ((bd['unitDiscount'] ?? 0) > 0)
                                                Text(
                                                  'Disc: -${_money(bd['unitDiscount']!)}',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFD97706),
                                                  ),
                                                ),
                                              if ((bd['unitTax'] ?? 0) > 0)
                                                Text(
                                                  'Tax: +${_money(bd['unitTax']!)}',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              Text(
                                                'Refund/unit: ${_money(unitRefund)}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (canReturn && isSelected) ...[
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: currentQty > 1
                                                  ? () => setLocal(() {
                                                        returnQuantities[item.productId] = currentQty - 1;
                                                      })
                                                  : null,
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(Icons.remove, size: 16),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '${currentQty.toInt()}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: currentQty < availableQty
                                                  ? () => setLocal(() {
                                                        returnQuantities[item.productId] = currentQty + 1;
                                                      })
                                                  : null,
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(Icons.add, size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (availableQty > 1)
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: () => setLocal(() {
                                            returnQuantities[item.productId] = availableQty;
                                          }),
                                          child: const Text('Max', style: TextStyle(fontSize: 11)),
                                        ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 100,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Refund', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                            Text(
                                              _money(lineRefund),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFE11D48),
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ] else ...[
                        TextField(
                          controller: manualProductCtrl,
                          decoration: InputDecoration(
                            labelText: 'Product Name *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(UiRadius.md),
                            ),
                          ),
                          onChanged: (_) => setLocal(() {}),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: manualQtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Quantity *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(UiRadius.md),
                                  ),
                                ),
                                onChanged: (_) => setLocal(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: manualAmountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Total Refund Amount *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(UiRadius.md),
                                  ),
                                ),
                                onChanged: (_) => setLocal(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      TextField(
                        controller: customerCtrl,
                        decoration: InputDecoration(
                          labelText: 'Customer *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(UiRadius.md),
                          ),
                        ),
                        onChanged: (_) => setLocal(() {}),
                      ),
                      const SizedBox(height: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Return Reason *',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              'Defective / Damaged',
                              'Wrong Item',
                              'Customer Changed Mind',
                              'Expired',
                              'Size / Variant Swap',
                            ].map((tag) {
                              final isSelected = reasonCtrl.text == tag;
                              return ChoiceChip(
                                label: Text(tag, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (sel) {
                                  setLocal(() {
                                    reasonCtrl.text = sel ? tag : '';
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: reasonCtrl,
                            decoration: InputDecoration(
                              hintText: 'Or enter custom reason / notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(UiRadius.md),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (_) => setLocal(() {}),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: condition,
                              decoration: InputDecoration(
                                labelText: 'Product Condition',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(UiRadius.md),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Good', child: Text('Good (Restock to Inventory)')),
                                DropdownMenuItem(value: 'Damaged', child: Text('Damaged (Scrap Inventory)')),
                                DropdownMenuItem(value: 'Expired', child: Text('Expired (Write Off)')),
                              ],
                              onChanged: (v) => setLocal(() => condition = v ?? 'Good'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: isUnpaidCod ? 'NO_PAYOUT' : refundMethod,
                              decoration: InputDecoration(
                                labelText: 'Refund Method',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(UiRadius.md),
                                ),
                              ),
                              items: isUnpaidCod
                                  ? const [
                                      DropdownMenuItem(
                                        value: 'NO_PAYOUT',
                                        child: Text('No Payout (Unpaid COD Cancellation)'),
                                      ),
                                    ]
                                  : const [
                                      DropdownMenuItem(value: 'CASH', child: Text('Cash Refund')),
                                      DropdownMenuItem(value: 'BANK', child: Text('Bank Transfer Refund')),
                                      DropdownMenuItem(value: 'STORE_CREDIT', child: Text('Store Credit')),
                                      DropdownMenuItem(value: 'CARD', child: Text('Card Refund')),
                                    ],
                              onChanged: isUnpaidCod
                                  ? null
                                  : (v) => setLocal(() => refundMethod = v ?? 'CASH'),
                            ),
                          ),
                        ],
                      ),
                      if (hasSale && deliveryFee > 0 && !isUnpaidCod) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: refundDeliveryFee
                                ? (isDark ? const Color(0xFF312E81).withValues(alpha: 0.3) : const Color(0xFFEEF2FF))
                                : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB)),
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            border: Border.all(
                              color: refundDeliveryFee
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: refundDeliveryFee,
                            title: Text(
                              'Refund Delivery Fee (${_money(deliveryFee)})',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              refundDeliveryFee
                                  ? 'Customer will receive delivery fee back (Total refund: ${_money(totalRefund)}).'
                                  : 'Delivery fee will be kept by store (Not refunded).',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            onChanged: (val) => setLocal(() => refundDeliveryFee = val ?? false),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Live Financial Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(UiRadius.lg),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calculate_outlined, size: 20, color: Color(0xFF6366F1)),
                                SizedBox(width: 8),
                                Text(
                                  'Financial Return Summary',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Original Invoice',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _money(originalTotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (deliveryFee > 0)
                                        Text(
                                          'Delivery: ${_money(deliveryFee)}',
                                          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(height: 36, width: 1, color: Colors.grey.shade400),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isUnpaidCod ? 'Refund Payable' : 'Refund Value',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFFE11D48)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isUnpaidCod
                                            ? 'LKR 0.00 (No Payout)'
                                            : '- ${_money(totalRefund)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFFE11D48),
                                        ),
                                      ),
                                      if (shippingRefund > 0)
                                        Text(
                                          'Incl. Fee: +${_money(shippingRefund)}',
                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFFE11D48)),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(height: 36, width: 1, color: Colors.grey.shade400),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isUnpaidCod ? 'Restocked Value' : 'Retained Sales Value',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isUnpaidCod
                                            ? _money(rawItemsRefundValue)
                                            : _money(retainedTotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
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
              ),
            );
          },
        );
      },
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }
}
