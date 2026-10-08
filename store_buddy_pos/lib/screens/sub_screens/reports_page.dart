// ignore_for_file: invalid_use_of_protected_member

part of '../dashboard_screen.dart';

extension _ReportsPageExt on _DashboardScreenState {
  Widget _buildReportsPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _reportsSearchController.text.trim().toLowerCase();

    final categoryOptions = ['All Categories', ..._productCategories];
    final supplierLabels = <String, String>{'All Suppliers': 'All Suppliers'};
    for (final s in _suppliers) {
      if (s.name.trim().isNotEmpty) {
        supplierLabels['id::${s.id}'] = s.name.trim();
      }
    }
    final supplierOptions = supplierLabels.keys.toList();

    // Contextual filtering helper
    List<T> filterByPeriod<T>(List<T> list, DateTime Function(T) dateGetter) {
      return list.where((item) => _matchesTimeFilter(dateGetter(item), _reportsTimeFilter)).toList();
    }

    // 1. Sales & Revenue Calculations
    final scopedSales = _scopedSales.where((sale) {
      if (_isCashier && _currentUserId.trim().isNotEmpty) {
        return sale.employeeId == _currentUserId;
      }
      return true;
    }).toList();

    final periodSales = filterByPeriod(scopedSales, (s) => s.createdAt);
    final filteredSales = periodSales.where((sale) {
      if (_reportsPaymentFilter != 'ALL') {
        if (_reportsPaymentFilter == 'SERVICE') {
          if (!_saleHasServiceItems(sale)) return false;
        } else if (sale.paymentMethod != _reportsPaymentFilter) {
          return false;
        }
      }
      if (_reportsStatusFilter != 'ALL' && sale.status != _reportsStatusFilter) {
        return false;
      }
      if (_reportsCashierFilter != 'ALL') {
        final matchesEmp = sale.employeeId == _reportsCashierFilter;
        final matchesName = sale.cashierName.trim().toLowerCase() == _reportsCashierFilter.trim().toLowerCase();
        if (!matchesEmp && !matchesName) return false;
      }
      if (query.isEmpty) return true;

      final itemHit = sale.items.any(
        (item) => item.productName.toLowerCase().contains(query),
      );
      return sale.id.toLowerCase().contains(query) ||
          sale.customerName.toLowerCase().contains(query) ||
          sale.cashierName.toLowerCase().contains(query) ||
          sale.paymentMethod.toLowerCase().contains(query) ||
          itemHit;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final completedSales = filteredSales
        .where((s) => s.status.toUpperCase() == 'COMPLETED')
        .toList();
    final returnedSales = filteredSales
        .where((s) => s.status.toUpperCase() == 'RETURNED')
        .toList();
    final cancelledSales = filteredSales
        .where((s) => s.status.toUpperCase() == 'CANCELLED')
        .toList();
    final codPendingSales = filteredSales
        .where((s) => s.status.toUpperCase() == 'COD_PENDING')
        .toList();

    // Valid realized sales exclude cancelled orders and pending/unpaid COD orders
    final realizedSales = filteredSales.where((s) {
      final st = s.status.toUpperCase();
      if (st == 'CANCELLED' ||
          st == 'COD_PENDING' ||
          st == 'PENDING' ||
          st == 'OUT_FOR_DELIVERY' ||
          st == 'DELIVERED_TO_CUSTOMER') return false;
      if (s.paymentMethod.toUpperCase() == 'COD' && st != 'COMPLETED') return false;
      if ((st == 'RETURNED' || st == 'PARTIALLY_RETURNED') &&
          s.paymentMethod.toUpperCase() == 'COD' &&
          s.amountPaid <= 0) {
        return false;
      }
      return true;
    }).toList();

    final filteredSaleIds = filteredSales.map((s) => s.id).toSet();
    final totalRefundedReturns = _returns.where((r) {
      if (r.status == 'Rejected') return false;
      if (r.refundMethod == 'NO_PAYOUT' || r.amount <= 0) return false;
      final rDate = DateTime.tryParse(r.createdAt) ?? DateTime.now();
      if (!_matchesTimeFilter(rDate, _reportsTimeFilter)) return false;
      if (r.saleId.isNotEmpty) {
        _SaleRecord? parentSale;
        for (final s in _sales) {
          if (s.id == r.saleId) {
            parentSale = s;
            break;
          }
        }
        if (parentSale != null &&
            parentSale.paymentMethod.toUpperCase() == 'COD' &&
            parentSale.amountPaid <= 0) {
          return false;
        }
      }
      return r.saleId.isEmpty || filteredSaleIds.contains(r.saleId);
    }).fold<double>(0.0, (sum, r) => sum + r.amount);

    final grossRevenue = realizedSales.fold<double>(
      0.0,
      (sum, s) => sum + s.total,
    );
    final refundedValue = totalRefundedReturns;
    final netRevenue = (grossRevenue - refundedValue).clamp(0.0, double.infinity);
    final avgOrder = realizedSales.isEmpty ? 0.0 : netRevenue / realizedSales.length;

    final soldUnits = realizedSales.fold<double>(
      0,
      (sum, sale) => sum + sale.items.fold<double>(0, (inner, item) => inner + item.quantity),
    );

    // Sales Profit Calculations (Item level lookup)
    double getSaleProfit(_SaleRecord sale) {
      double profit = 0.0;
      for (final item in sale.items) {
        final prodIdx = _products.indexWhere((p) => p.id == item.productId);
        final unitCost = prodIdx >= 0 ? _unitInventoryCost(_products[prodIdx]) : 0.0;
        final itemCost = unitCost * item.quantity;
        profit += (item.lineTotal - itemCost);
      }
      return profit;
    }

    final totalSalesProfit = filteredSales.fold<double>(
      0.0,
      (sum, sale) => sum + (sale.status.toUpperCase() == 'CANCELLED' ? 0.0 : getSaleProfit(sale)),
    );

    // Filter the products list for the inventory report
    final filteredInventoryProducts = _scopedProducts.where((p) {
      if (_reportsInventoryCategoryFilter != 'All Categories' && p.category != _reportsInventoryCategoryFilter) {
        return false;
      }
      if (_reportsInventorySupplierFilter != 'All Suppliers') {
        final targetId = _reportsInventorySupplierFilter.startsWith('id::') 
            ? _reportsInventorySupplierFilter.substring(4) 
            : _reportsInventorySupplierFilter;
        if (p.supplierId != targetId) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        if (!p.name.toLowerCase().contains(query) &&
            !p.category.toLowerCase().contains(query) &&
            !p.barcode.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    // 2. Inventory Metrics
    final lowStockProducts = filteredInventoryProducts.where((p) => p.stock <= p.minStock).toList();
    final outOfStockProducts = filteredInventoryProducts.where((p) => p.stock <= 0).toList();
    final inventoryValCost = filteredInventoryProducts.fold<double>(
      0.0,
      (sum, p) => sum + (_unitInventoryCost(p) * p.stock),
    );
    final inventoryValRetail = filteredInventoryProducts.fold<double>(
      0.0,
      (sum, p) => sum + (p.price * p.stock),
    );
    final potentialMargin = (inventoryValRetail - inventoryValCost).clamp(0.0, double.infinity);

    // Credit calculations
    final totalReceivables = _scopedCustomers.fold<double>(
      0.0,
      (sum, c) => sum + _customerOutstandingBalance(c.id, fallback: c.currentBalance),
    );
    final totalPayables = _scopedPurchaseOrders
        .where((po) => po.status == 'RECEIVED')
        .fold<double>(0.0, (sum, po) => sum + po.amountDue);
    final netOutstandingCredit = totalReceivables - totalPayables;

    // Installments calculations
    final periodPlans = filterByPeriod(_scopedInstallmentPlans, (ip) => ip.createdAt);
    final totalFinanced = periodPlans.fold<double>(0.0, (sum, ip) => sum + ip.totalAmount);
    final remainingReceivable = periodPlans.fold<double>(0.0, (sum, ip) => sum + ip.remainingAmount);
    final totalCollected = (totalFinanced - remainingReceivable).clamp(0.0, double.infinity);

    // COD calculations
    final codSales = filteredSales.where((s) => s.paymentMethod.toUpperCase() == 'COD').toList();
    final completedCod = codSales.where((s) => s.status.toUpperCase() == 'COMPLETED').toList();
    final pendingCod = codSales.where((s) => s.status.toUpperCase() != 'COMPLETED' && s.status.toUpperCase() != 'CANCELLED').toList();
    final cancelledCod = codSales.where((s) => s.status.toUpperCase() == 'CANCELLED').toList();
    final completedCodValue = completedCod.fold<double>(0.0, (sum, s) => sum + s.total);
    final pendingCodValue = pendingCod.fold<double>(0.0, (sum, s) => sum + s.total);
    final codRate = codSales.isEmpty ? 0.0 : (completedCod.length / codSales.length) * 100;

    // PO calculations
    final periodPOs = filterByPeriod(_scopedPurchaseOrders, (po) => DateTime.tryParse(po.createdAt) ?? DateTime.now());
    final totalPOAmount = periodPOs.fold<double>(0.0, (sum, po) => sum + po.amount);
    final totalPOPaid = periodPOs.fold<double>(0.0, (sum, po) => sum + po.amountPaid);
    final totalPODue = periodPOs.fold<double>(0.0, (sum, po) => sum + po.amountDue);

    // Reload calculations
    final periodReloads = filterByPeriod(_mobileReloads, (r) => r.createdAt);
    final filteredReloads = periodReloads.where((r) {
      if (query.isEmpty) return true;
      return r.phoneNumber.contains(query) || r.operator.toLowerCase().contains(query);
    }).toList();
    final totalReloadAmount = filteredReloads.fold<double>(0.0, (sum, r) => sum + r.amount);
    final totalReloadCommissions = filteredReloads.fold<double>(0.0, (sum, r) => sum + r.commission);
    final totalOwedToOperators = totalReloadAmount - totalReloadCommissions;

    final periodSettlements = filterByPeriod(_scopedCashTransactions, (tx) => DateTime.tryParse(tx.createdAt) ?? DateTime.now());
    final filteredSettlements = periodSettlements.where((tx) {
      if (tx.type != 'OUT' || tx.referenceType != 'OPERATOR_SETTLEMENT') return false;
      if (query.isEmpty) return true;
      return tx.referenceId.toLowerCase().contains(query) || tx.note.toLowerCase().contains(query);
    }).toList();
    final totalSettledAmount = filteredSettlements.fold<double>(0.0, (sum, tx) => sum + tx.amount);
    final outstandingOwed = totalOwedToOperators - totalSettledAmount;


    // Helper Cards
    Widget metricCard(
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color accentColor,
    ) {
      return Container(
        width: _adaptiveWidth(240, minWidth: 160, horizontalPadding: 40),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      );
    }

    Widget sectionCard(String title, Widget child, {Widget? trailing}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing,
                ],
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      );
    }

    Widget buildReportTabItem(String type, String label, IconData icon) {
      final isSelected = _selectedReportType == type;
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ChoiceChip(
          avatar: Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.7),
          ),
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          selected: isSelected,
          selectedColor: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedReportType = type;
              });
            }
          },
        ),
      );
    }

    return _moduleCard(
      title: 'Reports & Analytics',
      action: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _canRunSync && !_syncInProgress ? _runManualSync : null,
            icon: const Icon(Icons.sync),
            label: Text(_syncInProgress ? 'Syncing...' : 'Sync Now'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _lastSyncError == null
                  ? const Color(0xFFE6F7EE)
                  : const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _lastSyncError == null
                  ? 'Synced ${_lastSyncAt == null ? 'Never' : _formatDate(_lastSyncAt!.toLocal())}'
                  : 'Sync issue',
              style: TextStyle(
                color: _lastSyncError == null
                    ? const Color(0xFF19713F)
                    : const Color(0xFFB3261E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _exportReportsPdf,
            icon: const Icon(Icons.download),
            label: const Text('Export Summary'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Horizontal Category Tabs Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildReportTabItem('sales', 'Sales Trend', Icons.trending_up_rounded),
                buildReportTabItem('inventory', 'Inventory Valuation', Icons.inventory_2_outlined),
                buildReportTabItem('credit', 'Credit & Receivables', Icons.account_balance_wallet_outlined),
                buildReportTabItem('installments', 'Installment Agreements', Icons.event_note_rounded),
                buildReportTabItem('cod', 'COD Shipments', Icons.local_shipping_outlined),
                buildReportTabItem('po', 'Purchase Restocks', Icons.assignment_outlined),
                if (_mobileReloadEnabled)
                  buildReportTabItem('mobileReload', 'Mobile Reloads', Icons.phone_android_rounded),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Filter Rows
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _reportsSearchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search items, cashier, invoice...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: _reportsTimeFilter,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Today', child: Text('Today', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'This Week', child: Text('This Week', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'This Month', child: Text('This Month', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'This Year', child: Text('This Year', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'All Time', child: Text('All Time', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _reportsTimeFilter = v);
                  },
                ),
              ),
              // Show payment/status sub-filters for relevant tabs
              if (_selectedReportType == 'sales' || _selectedReportType == 'cod') ...[
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: _reportsPaymentFilter,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('All Payments', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'CASH', child: Text('Cash', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'CARD', child: Text('Card', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'CREDIT', child: Text('Credit', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'INSTALLMENT', child: Text('Installment', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'SERVICE', child: Text('Service', overflow: TextOverflow.ellipsis)),
                      if (_enableCod)
                        const DropdownMenuItem(value: 'COD', child: Text('COD', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _reportsPaymentFilter = v);
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: _reportsStatusFilter,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('All Statuses', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'COMPLETED', child: Text('Completed', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'RETURNED', child: Text('Returned', overflow: TextOverflow.ellipsis)),
                      const DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled', overflow: TextOverflow.ellipsis)),
                      if (_enableCod)
                        const DropdownMenuItem(value: 'COD_PENDING', child: Text('COD Pending', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _reportsStatusFilter = v);
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: _reportsCashierFilter,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('All Cashiers / Staff', overflow: TextOverflow.ellipsis)),
                      ..._scopedUsers
                          .where((u) => u.role.trim().toLowerCase() != 'delivery')
                          .map((u) => DropdownMenuItem(
                                value: u.id,
                                child: Text('${u.name} (${u.role})', overflow: TextOverflow.ellipsis),
                              )),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _reportsCashierFilter = v);
                    },
                  ),
                ),
              ],
              if (_selectedReportType == 'inventory') ...[
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _reportsInventoryCategoryFilter,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    items: categoryOptions.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _reportsInventoryCategoryFilter = v);
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _reportsInventorySupplierFilter,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    items: supplierOptions.map((sKey) {
                      return DropdownMenuItem(value: sKey, child: Text(supplierLabels[sKey] ?? 'Supplier', overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _reportsInventorySupplierFilter = v);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // 3. Dynamic Tab Content Rendering
          if (_selectedReportType == 'sales') ...[
            // ─── SALES TAB ───
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metricCard('Gross Sales', _money(grossRevenue), '${realizedSales.length} Invoices', Icons.monetization_on_outlined, const Color(0xFF3B82F6)),
                metricCard('Net Revenue', _money(netRevenue), 'Refunded ${_money(refundedValue)}', Icons.payments_outlined, const Color(0xFF10B981)),
                metricCard('Calculated Profit', _money(totalSalesProfit), 'Cost margin base', Icons.trending_up_rounded, const Color(0xFF8B5CF6)),
                metricCard('Avg Ticket', _money(avgOrder), '$soldUnits units sold total', Icons.receipt_long_outlined, const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 18),
            // Custom Line Chart for Revenue trend
            sectionCard(
              'Sales Trend ($_reportsTimeFilter)',
              SizedBox(
                height: 220,
                child: () {
                  final trendData = <MapEntry<String, double>>[];
                  if (_reportsTimeFilter == 'Today') {
                    final hourly = List<double>.filled(24, 0.0);
                    for (final s in filteredSales) {
                      hourly[s.createdAt.hour] += s.total;
                    }
                    for (int i = 0; i < 24; i++) {
                      if (i % 2 == 0) {
                        trendData.add(MapEntry('${i.toString().padLeft(2, '0')}:00', hourly[i]));
                      }
                    }
                  } else if (_reportsTimeFilter == 'This Week') {
                    final daily = List<double>.filled(7, 0.0);
                    for (final s in filteredSales) {
                      final weekday = s.createdAt.weekday - 1;
                      if (weekday >= 0 && weekday < 7) daily[weekday] += s.total;
                    }
                    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    for (int i = 0; i < 7; i++) {
                      trendData.add(MapEntry(days[i], daily[i]));
                    }
                  } else if (_reportsTimeFilter == 'This Month') {
                    final daily = <int, double>{};
                    for (final s in filteredSales) {
                      daily[s.createdAt.day] = (daily[s.createdAt.day] ?? 0.0) + s.total;
                    }
                    for (int i = 1; i <= 31; i += 3) {
                      double val = 0.0;
                      for (int j = i; j < i + 3 && j <= 31; j++) {
                        val += daily[j] ?? 0.0;
                      }
                      trendData.add(MapEntry('$i-${(i + 2).clamp(1, 31)}', val));
                    }
                  } else if (_reportsTimeFilter == 'This Year') {
                    final monthly = List<double>.filled(12, 0.0);
                    for (final s in filteredSales) {
                      final m = s.createdAt.month - 1;
                      if (m >= 0 && m < 12) monthly[m] += s.total;
                    }
                    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    for (int i = 0; i < 12; i++) {
                      trendData.add(MapEntry(months[i], monthly[i]));
                    }
                  } else {
                    final yearly = <int, double>{};
                    for (final s in filteredSales) {
                      yearly[s.createdAt.year] = (yearly[s.createdAt.year] ?? 0.0) + s.total;
                    }
                    final sortedYears = yearly.keys.toList()..sort();
                    for (final yr in sortedYears) {
                      trendData.add(MapEntry(yr.toString(), yearly[yr] ?? 0.0));
                    }
                    if (trendData.isEmpty) {
                      trendData.add(MapEntry(DateTime.now().year.toString(), 0.0));
                    }
                  }
                  return _CustomLineChart(
                    data: trendData,
                    yAxisPrefix: '$_currency ',
                    gradientColors: const [Color(0xFF3B82F6), Color(0xFF10B981)],
                  );
                }(),
              ),
            ),
            const SizedBox(height: 18),
            // Top Product Categories Bar Chart
            () {
              final categoryMap = <String, Map<String, double>>{};
              for (final sale in realizedSales) {
                for (final item in sale.items) {
                  final prodIdx = _products.indexWhere((p) => p.id == item.productId);
                  final cat = prodIdx >= 0 && _products[prodIdx].category.trim().isNotEmpty
                      ? _products[prodIdx].category.trim()
                      : 'General';
                  final unitCost = prodIdx >= 0 ? _unitInventoryCost(_products[prodIdx]) : 0.0;
                  final margin = item.lineTotal - (unitCost * item.quantity);

                  final data = categoryMap.putIfAbsent(cat, () => {'revenue': 0.0, 'margin': 0.0});
                  data['revenue'] = (data['revenue'] ?? 0.0) + item.lineTotal;
                  data['margin'] = (data['margin'] ?? 0.0) + margin;
                }
              }

              final sortedCategories = categoryMap.entries.toList()
                ..sort((a, b) => b.value['revenue']!.compareTo(a.value['revenue']!));
              final topCategories = sortedCategories.take(5).toList();

              if (topCategories.isEmpty) {
                return const SizedBox.shrink();
              }

              final barGroups = topCategories.map((e) {
                return _BarGroup(
                  e.key.length > 14 ? '${e.key.substring(0, 12)}..' : e.key,
                  e.value['revenue'] ?? 0.0,
                  (e.value['margin'] ?? 0.0).clamp(0.0, double.infinity),
                );
              }).toList();

              return sectionCard(
                'Top Product Categories (Revenue vs Margin)',
                SizedBox(
                  height: 240,
                  child: _CustomBarChart(
                    groups: barGroups,
                    label1: 'Revenue',
                    label2: 'Gross Margin',
                    color1: const Color(0xFF3B82F6),
                    color2: const Color(0xFF10B981),
                    yAxisPrefix: '$_currency ',
                  ),
                ),
              );
            }(),
            const SizedBox(height: 18),

            // COD Settlement & Fulfillment Status (if any COD orders exist)
            () {
              final codSales = filteredSales.where((s) => s.paymentMethod.toUpperCase() == 'COD').toList();
              if (codSales.isEmpty) return const SizedBox.shrink();

              final codCollected = codSales.where((s) => s.status.toUpperCase() == 'COMPLETED').toList();
              final codPending = codSales.where((s) => s.status.toUpperCase() == 'COD_PENDING').toList();
              final codCancelled = codSales.where((s) => s.status.toUpperCase() == 'CANCELLED' || s.status.toUpperCase() == 'RETURNED').toList();

              final collectedAmt = codCollected.fold<double>(0.0, (sum, s) => sum + s.total);
              final pendingAmt = codPending.fold<double>(0.0, (sum, s) => sum + s.total);
              final cancelledAmt = codCancelled.fold<double>(0.0, (sum, s) => sum + s.total);
              final totalCodAmt = collectedAmt + pendingAmt + cancelledAmt;
              final collectionRate = totalCodAmt > 0 ? (collectedAmt / totalCodAmt) * 100 : 0.0;

              final codSegments = [
                if (collectedAmt > 0)
                  _DonutSegment('Delivered & Collected', collectedAmt, const Color(0xFF10B981)),
                if (pendingAmt > 0)
                  _DonutSegment('Pending Collection', pendingAmt, const Color(0xFFF97316)),
                if (cancelledAmt > 0)
                  _DonutSegment('Returned / Cancelled', cancelledAmt, const Color(0xFFEF4444)),
              ];

              return Column(
                children: [
                  sectionCard(
                    'Cash on Delivery (COD) Fulfillment & Settlement',
                    LayoutBuilder(builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final summaryPills = [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('COD Collected (Recognized)', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_money(collectedAmt), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                              Text('${codCollected.length} orders delivered & settled', style: const TextStyle(fontSize: 11, color: Color(0xFF059669))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('COD Pending Delivery', style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_money(pendingAmt), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                              Text('${codPending.length} orders in transit (unrecognized)', style: const TextStyle(fontSize: 11, color: Color(0xFFD97706))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Collection Success Rate', style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${collectionRate.toStringAsFixed(1)}%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.primary)),
                              Text('${codSales.length} total COD orders', style: TextStyle(fontSize: 11, color: colorScheme.primary)),
                            ],
                          ),
                        ),
                      ];

                      return isWide
                          ? Row(
                              children: [
                                if (codSegments.isNotEmpty)
                                  Expanded(
                                    flex: 4,
                                    child: _CustomDonutChart(
                                      segments: codSegments,
                                      centerLabel: 'COD Total',
                                      centerValue: _money(totalCodAmt),
                                    ),
                                  ),
                                if (codSegments.isNotEmpty)
                                  const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      summaryPills[0],
                                      const SizedBox(height: 8),
                                      summaryPills[1],
                                      const SizedBox(height: 8),
                                      summaryPills[2],
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                if (codSegments.isNotEmpty)
                                  _CustomDonutChart(
                                    segments: codSegments,
                                    centerLabel: 'COD Total',
                                    centerValue: _money(totalCodAmt),
                                  ),
                                const SizedBox(height: 12),
                                ...summaryPills.map((w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w)),
                              ],
                            );
                    }),
                  ),
                  const SizedBox(height: 18),
                ],
              );
            }(),

            // Payment Mix and Cashier performance side-by-side
            LayoutBuilder(builder: (context, boxConstraints) {
              final isWide = boxConstraints.maxWidth > 700;
              final paymentMixData = <String, Map<String, num>>{};
              for (final sale in filteredSales) {
                if (sale.status.toUpperCase() == 'CANCELLED') continue;
                if ((sale.status.toUpperCase() == 'RETURNED' || sale.status.toUpperCase() == 'PARTIALLY_RETURNED') &&
                    sale.paymentMethod.toUpperCase() == 'COD' &&
                    sale.amountPaid <= 0) {
                  continue;
                }
                String method = sale.paymentMethod.toUpperCase();
                if (sale.status.toUpperCase() == 'COD_PENDING') {
                  method = 'COD (PENDING)';
                } else if (method == 'COD') {
                  method = 'COD (COLLECTED)';
                }
                final map = paymentMixData.putIfAbsent(method, () => {'count': 0, 'amount': 0.0});
                map['count'] = (map['count'] ?? 0) + 1;
                map['amount'] = (map['amount'] ?? 0) + sale.total;
              }

              final List<_DonutSegment> donutSegments = paymentMixData.entries.map((e) {
                Color c = const Color(0xFF3B82F6);
                if (e.key == 'CASH') c = const Color(0xFF10B981);
                if (e.key == 'CARD') c = const Color(0xFFEC4899);
                if (e.key == 'CHEQUE') c = const Color(0xFFF59E0B);
                if (e.key == 'CREDIT') c = const Color(0xFFEF4444);
                if (e.key == 'INSTALLMENT') c = const Color(0xFF8B5CF6);
                if (e.key == 'COD (COLLECTED)') c = const Color(0xFF059669);
                if (e.key == 'COD (PENDING)') c = const Color(0xFFF97316);
                return _DonutSegment(e.key, (e.value['amount'] ?? 0.0).toDouble(), c);
              }).toList();

              final cashierData = <String, Map<String, num>>{};
              for (final sale in filteredSales) {
                final cashier = sale.cashierName.trim().isEmpty ? 'Staff' : sale.cashierName.trim();
                final map = cashierData.putIfAbsent(cashier, () => {'count': 0, 'amount': 0.0, 'cash': 0.0, 'codSettled': 0.0});
                map['count'] = (map['count'] ?? 0) + 1;
                map['amount'] = (map['amount'] ?? 0) + sale.total;
                if (sale.paymentMethod == 'CASH') {
                  map['cash'] = (map['cash'] ?? 0) + sale.amountPaid;
                } else if (sale.paymentMethod == 'COD' && sale.deliveryStatus == 'SETTLED') {
                  map['codSettled'] = (map['codSettled'] ?? 0) + sale.amountPaid;
                }
              }
              final sortedCashiers = cashierData.entries.toList()..sort((a, b) => b.value['amount']!.compareTo(a.value['amount']!));

              final kids = [
                sectionCard(
                  'Payment Mix',
                  _CustomDonutChart(
                    segments: donutSegments,
                    centerLabel: 'Revenue',
                    centerValue: _money(netRevenue),
                  ),
                ),
                sectionCard(
                  'Cashier Breakdown & Performance',
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedCashiers.length,
                    separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withOpacity(0.4)),
                    itemBuilder: (context, index) {
                      final item = sortedCashiers[index];
                      final count = item.value['count'] ?? 0;
                      final cashAmt = (item.value['cash'] ?? 0.0).toDouble();
                      final codAmt = (item.value['codSettled'] ?? 0.0).toDouble();
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Text(item.key.substring(0, 1).toUpperCase(), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(item.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$count orders  •  Cash: ${_money(cashAmt)}  •  COD Settled: ${_money(codAmt)}', style: const TextStyle(fontSize: 11)),
                        trailing: Text(_money(item.value['amount']!.toDouble()), style: const TextStyle(fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
                ),
              ];

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: kids[0]),
                        const SizedBox(width: 18),
                        Expanded(child: kids[1]),
                      ],
                    )
                  : Column(
                      children: [
                        kids[0],
                        const SizedBox(height: 18),
                        kids[1],
                      ],
                    );
            }),
            const SizedBox(height: 18),
            // Item-wise sales report table
            sectionCard(
              'Item-Wise Performance (Sales)',
              () {
                final productSummary = <String, Map<String, dynamic>>{};
                for (final sale in filteredSales) {
                  for (final item in sale.items) {
                    final key = item.productId;
                    final map = productSummary.putIfAbsent(
                      key,
                      () => {'name': item.productName, 'category': '', 'qty': 0, 'revenue': 0.0, 'profit': 0.0},
                    );
                    map['qty'] = (map['qty'] ?? 0) + item.quantity;
                    map['revenue'] = (map['revenue'] ?? 0.0) + item.lineTotal;

                    // calculate item profit
                    final prodIdx = _products.indexWhere((p) => p.id == item.productId);
                    if (prodIdx >= 0) {
                      final prod = _products[prodIdx];
                      map['category'] = prod.category;
                      final unitCost = _unitInventoryCost(prod);
                      map['profit'] = (map['profit'] ?? 0.0) + (item.lineTotal - (unitCost * item.quantity));
                    } else {
                      map['profit'] = (map['profit'] ?? 0.0) + item.lineTotal;
                    }
                  }
                }
                final sortedSummary = productSummary.entries.toList()
                  ..sort((a, b) => b.value['revenue']!.compareTo(a.value['revenue']!));

                if (sortedSummary.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('No item sales details found.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Units Sold'), numeric: true),
                      DataColumn(label: Text('Revenue'), numeric: true),
                      DataColumn(label: Text('Margin Profit'), numeric: true),
                      DataColumn(label: Text('Margin %'), numeric: true),
                    ],
                    rows: sortedSummary.take(15).map((entry) {
                      final val = entry.value;
                      final double revenue = val['revenue'] ?? 0.0;
                      final double profit = val['profit'] ?? 0.0;
                      final double marginPct = revenue <= 0 ? 0.0 : (profit / revenue) * 100;
                      return DataRow(
                        cells: [
                          DataCell(Text(val['name'] ?? 'Unknown Item')),
                          DataCell(Text(val['category'] ?? 'General')),
                          DataCell(Text('${val['qty']}', textAlign: TextAlign.right)),
                          DataCell(Text(_money(revenue), textAlign: TextAlign.right)),
                          DataCell(Text(_money(profit), textAlign: TextAlign.right)),
                          DataCell(Text('${marginPct.toStringAsFixed(1)}%', textAlign: TextAlign.right)),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }(),
            ),
          ] else if (_selectedReportType == 'inventory') ...[
            // ─── INVENTORY VALUATION TAB ───
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metricCard('Total Tracked Products', '${filteredInventoryProducts.length} Items', 'Across branch locations', Icons.inventory_2_outlined, const Color(0xFF3B82F6)),
                metricCard('Valuation at Cost', _money(inventoryValCost), 'Current restock investment', Icons.monetization_on_outlined, const Color(0xFF10B981)),
                metricCard('Valuation at Retail', _money(inventoryValRetail), 'Expected total cash-in', Icons.storefront, const Color(0xFF8B5CF6)),
                metricCard('Potential Markup', _money(potentialMargin), 'Proj profit margin: ${filteredInventoryProducts.isEmpty ? 0 : (potentialMargin / (inventoryValRetail > 0 ? inventoryValRetail : 1) * 100).toStringAsFixed(1)}%', Icons.trending_up_rounded, const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 18),
            // Category Shares & Stock Alert Side-By-Side
            LayoutBuilder(builder: (context, boxConstraints) {
              final isWide = boxConstraints.maxWidth > 700;

              // Compute Category shares
              final catValuations = <String, double>{};
              for (final p in filteredInventoryProducts) {
                final cost = _unitInventoryCost(p) * p.stock;
                catValuations[p.category] = (catValuations[p.category] ?? 0.0) + cost;
              }
              final catSegments = catValuations.entries.map((e) {
                final hash = e.key.hashCode;
                final color = Color((hash & 0xFFFFFF) | 0xFF000000);
                return _DonutSegment(e.key, e.value, color);
              }).toList()..sort((a, b) => b.value.compareTo(a.value));

              final kids = [
                sectionCard(
                  'Valuation Share by Category',
                  _CustomDonutChart(
                    segments: catSegments.take(6).toList(),
                    centerLabel: 'Total Value',
                    centerValue: _money(inventoryValCost),
                  ),
                ),
                sectionCard(
                  'Critical Stock Warnings (${lowStockProducts.length})',
                  SizedBox(
                    height: 200,
                    child: lowStockProducts.isEmpty
                        ? const Center(child: Text('No stock alerts. All inventory healthy!'))
                        : ListView.separated(
                            itemCount: lowStockProducts.length,
                            separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withOpacity(0.4)),
                            itemBuilder: (context, index) {
                              final p = lowStockProducts[index];
                              final isOut = p.stock <= 0;
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.warning_amber_rounded, color: isOut ? Colors.red : Colors.orange),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('SKU: ${p.barcode.isEmpty ? p.id : p.barcode} • Min stock: ${p.minStock}'),
                                trailing: Text(
                                  isOut ? 'OUT OF STOCK' : '${p.stock} units left',
                                  style: TextStyle(
                                    color: isOut ? Colors.red : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ];

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: kids[0]),
                        const SizedBox(width: 18),
                        Expanded(child: kids[1]),
                      ],
                    )
                  : Column(
                      children: [
                        kids[0],
                        const SizedBox(height: 18),
                        kids[1],
                      ],
                    );
            }),
            const SizedBox(height: 18),
            // Item-wise Valuation Table
            sectionCard(
              'Item-Wise Inventory Valuation & Profit Margins',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => _exportInventoryPdf(filteredInventoryProducts),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('PDF'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _exportInventoryCsv(filteredInventoryProducts),
                    icon: const Icon(Icons.grid_on_rounded, size: 18),
                    label: const Text('CSV'),
                  ),
                ],
              ),
              () {
                if (filteredInventoryProducts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('No inventory records found.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Stock Quantity'), numeric: true),
                      DataColumn(label: Text('Unit Cost'), numeric: true),
                      DataColumn(label: Text('Unit Price'), numeric: true),
                      DataColumn(label: Text('Valuation (Cost)'), numeric: true),
                      DataColumn(label: Text('Valuation (Retail)'), numeric: true),
                      DataColumn(label: Text('Profit Markup %'), numeric: true),
                    ],
                    rows: filteredInventoryProducts.map((p) {
                      final cost = _unitInventoryCost(p);
                      final valCost = cost * p.stock;
                      final valRetail = p.price * p.stock;
                      final margin = p.price <= 0 ? 0.0 : ((p.price - cost) / p.price) * 100;
                      return DataRow(
                        cells: [
                          DataCell(Text(p.name)),
                          DataCell(Text(p.category)),
                          DataCell(Text('${p.stock}', textAlign: TextAlign.right)),
                          DataCell(Text(_money(cost), textAlign: TextAlign.right)),
                          DataCell(Text(_money(p.price), textAlign: TextAlign.right)),
                          DataCell(Text(_money(valCost), textAlign: TextAlign.right)),
                          DataCell(Text(_money(valRetail), textAlign: TextAlign.right)),
                          DataCell(Text('${margin.toStringAsFixed(1)}%', textAlign: TextAlign.right)),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }(),
            ),
          ] else if (_selectedReportType == 'credit') ...[
            // ─── CREDIT & BILLS TAB ───

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metricCard('Accounts Receivable', _money(totalReceivables), 'To collect from customers', Icons.assignment_returned_rounded, const Color(0xFF3B82F6)),
                metricCard('Accounts Payable', _money(totalPayables), 'To pay to suppliers', Icons.assignment_late_rounded, const Color(0xFFEF4444)),
                metricCard('Net Credit Position', _money(netOutstandingCredit), netOutstandingCredit >= 0 ? 'Surplus credit receivable' : 'Deficit credit payable', Icons.account_balance_outlined, netOutstandingCredit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 18),
            // Custom Bar Chart comparing Receivables vs Payables
            sectionCard(
              'Credit Profile Comparison',
              SizedBox(
                height: 240,
                child: _CustomBarChart(
                  groups: [
                    _BarGroup('Current Outstanding', totalReceivables, totalPayables),
                  ],
                  label1: 'Receivables (Collect from Customers)',
                  label2: 'Payables (Owed to Suppliers)',
                  color1: const Color(0xFF3B82F6),
                  color2: const Color(0xFFEF4444),
                  yAxisPrefix: '$_currency ',
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Debtors vs Creditors Lists
            LayoutBuilder(builder: (context, boxConstraints) {
              final isWide = boxConstraints.maxWidth > 700;

              final debtors = _scopedCustomers
                  .where((c) => _customerOutstandingBalance(c.id, fallback: c.currentBalance) > 0)
                  .toList()
                ..sort((a, b) => _customerOutstandingBalance(b.id, fallback: b.currentBalance)
                    .compareTo(_customerOutstandingBalance(a.id, fallback: a.currentBalance)));

              final supplierOwes = <String, Map<String, dynamic>>{};
              for (final po in _scopedPurchaseOrders) {
                if (po.status == 'RECEIVED' && po.amountDue > 0) {
                  final map = supplierOwes.putIfAbsent(po.supplier, () => {'name': po.supplier, 'due': 0.0, 'poCount': 0});
                  map['due'] = (map['due'] ?? 0.0) + po.amountDue;
                  map['poCount'] = (map['poCount'] ?? 0) + 1;
                }
              }
              final creditors = supplierOwes.values.toList()..sort((a, b) => b['due'].compareTo(a['due']));

              final kids = [
                sectionCard(
                  'Top Customer Debtors (Receivables)',
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: debtors.take(6).length,
                    separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withOpacity(0.4)),
                    itemBuilder: (context, index) {
                      final c = debtors[index];
                      final balance = _customerOutstandingBalance(c.id, fallback: c.currentBalance);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c.phone.isEmpty ? 'No Phone' : c.phone),
                        trailing: Text(_money(balance), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                sectionCard(
                  'Owed Supplier Creditors (Payables)',
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: creditors.take(6).length,
                    separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withOpacity(0.4)),
                    itemBuilder: (context, index) {
                      final item = creditors[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: const Icon(Icons.local_shipping, color: Colors.red),
                        ),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['poCount']} restocks pending payment'),
                        trailing: Text(_money(item['due']), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
              ];

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: kids[0]),
                        const SizedBox(width: 18),
                        Expanded(child: kids[1]),
                      ],
                    )
                  : Column(
                      children: [
                        kids[0],
                        const SizedBox(height: 18),
                        kids[1],
                      ],
                    );
            }),
          ] else if (_selectedReportType == 'installments') ...[
            // ─── INSTALLMENTS TAB ───

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metricCard('Active Plans Count', '${periodPlans.length} plans', 'Installment agreements', Icons.event_note_rounded, const Color(0xFF3B82F6)),
                metricCard('Total Financed Value', _money(totalFinanced), 'Principal amount financed', Icons.monetization_on_outlined, const Color(0xFF8B5CF6)),
                metricCard('Paid Collections', _money(totalCollected), 'Already collected from customer', Icons.check_circle_outline, const Color(0xFF10B981)),
                metricCard('Remaining Receivable', _money(remainingReceivable), 'Outstanding future collections', Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 18),
            // Charts section
            LayoutBuilder(builder: (context, boxConstraints) {
              final isWide = boxConstraints.maxWidth > 700;

              // Upcoming schedules in next 30 days
              final now = DateTime.now();
              final thirtyDaysLimit = now.add(const Duration(days: 30));
              final upcomingSchedules = <Map<String, dynamic>>[];
              for (final plan in periodPlans) {
                for (final s in plan.schedules) {
                  if (!s.isPaid && s.dueDate.isAfter(now) && s.dueDate.isBefore(thirtyDaysLimit)) {
                    upcomingSchedules.add({
                      'customer': plan.customerName,
                      'phone': plan.customerPhone,
                      'dueDate': s.dueDate,
                      'amount': s.amount,
                      'installmentNo': s.installmentNo,
                      'planId': plan.id,
                    });
                  }
                }
              }
              upcomingSchedules.sort((a, b) => (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));

              final kids = [
                sectionCard(
                  'Collections Progress',
                  _CustomDonutChart(
                    segments: [
                      _DonutSegment('Paid Collections', totalCollected, const Color(0xFF10B981)),
                      _DonutSegment('Remaining Due', remainingReceivable, const Color(0xFFF59E0B)),
                    ],
                    centerLabel: 'Remaining',
                    centerValue: _money(remainingReceivable),
                  ),
                ),
                sectionCard(
                  'Upcoming Collections Calendar (Next 30 Days)',
                  SizedBox(
                    height: 200,
                    child: upcomingSchedules.isEmpty
                        ? const Center(child: Text('No upcoming collections in next 30 days'))
                        : ListView.separated(
                            itemCount: upcomingSchedules.length,
                            separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withOpacity(0.4)),
                            itemBuilder: (context, index) {
                              final item = upcomingSchedules[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
                                title: Text('${item['customer']} (Plan ID: ${item['planId']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Due: ${_formatDate(item['dueDate'] as DateTime)} • Installment #${item['installmentNo']}'),
                                trailing: Text(_money(item['amount'] as double), style: const TextStyle(fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
                  ),
                ),
              ];

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: kids[0]),
                        const SizedBox(width: 18),
                        Expanded(child: kids[1]),
                      ],
                    )
                  : Column(
                      children: [
                        kids[0],
                        const SizedBox(height: 18),
                        kids[1],
                      ],
                    );
            }),
            const SizedBox(height: 18),
            // Installment Registry Table
            sectionCard(
              'Active Installment Agreements',
              () {
                if (periodPlans.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('No installment records found.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Customer Name')),
                      DataColumn(label: Text('Financed Date')),
                      DataColumn(label: Text('Total Principal'), numeric: true),
                      DataColumn(label: Text('Down Payment'), numeric: true),
                      DataColumn(label: Text('Amount Paid'), numeric: true),
                      DataColumn(label: Text('Amount Remaining'), numeric: true),
                      DataColumn(label: Text('Intervals'), numeric: true),
                      DataColumn(label: Text('Progress'), numeric: true),
                    ],
                    rows: periodPlans.map((plan) {
                      final paid = (plan.totalAmount - plan.remainingAmount).clamp(0.0, double.infinity);
                      final progress = plan.totalAmount <= 0 ? 0.0 : (paid / plan.totalAmount);
                      return DataRow(
                        cells: [
                          DataCell(Text(plan.customerName)),
                          DataCell(Text(_formatDate(plan.createdAt))),
                          DataCell(Text(_money(plan.totalAmount), textAlign: TextAlign.right)),
                          DataCell(Text(_money(plan.downPayment), textAlign: TextAlign.right)),
                          DataCell(Text(_money(paid), textAlign: TextAlign.right)),
                          DataCell(Text(_money(plan.remainingAmount), textAlign: TextAlign.right)),
                          DataCell(Text('${plan.numberOfInstallments} pmts', textAlign: TextAlign.right)),
                          DataCell(
                            Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    borderRadius: BorderRadius.circular(4),
                                    backgroundColor: colorScheme.outlineVariant,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${(progress * 100).toStringAsFixed(0)}%'),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }(),
            ),
          ] else if (_selectedReportType == 'cod') ...[
            // ─── COD TAB ───

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metricCard('COD Invoices Count', '${codSales.length} Invoices', 'Total cash on delivery orders', Icons.local_shipping_outlined, const Color(0xFF3B82F6)),
                metricCard('Successful Delivery Rate', '${codRate.toStringAsFixed(1)}%', 'Successful / Total deliveries', Icons.check_circle_outline, const Color(0xFF10B981)),
                metricCard('Completed COD Revenue', _money(completedCodValue), 'Revenue collected & locked', Icons.monetization_on_outlined, const Color(0xFF10B981)),
                metricCard('Pending Delivery Value', _money(pendingCodValue), 'Cash in transit: ${pendingCod.length} orders', Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 18),
            // Layout with Donut chart & shipping orders
            LayoutBuilder(builder: (context, boxConstraints) {
              final isWide = boxConstraints.maxWidth > 700;

              final kids = [
                sectionCard(
                  'COD Status Distribution',
                  _CustomDonutChart(
                    segments: [
                      _DonutSegment('Completed', completedCod.length.toDouble(), const Color(0xFF10B981)),
                      _DonutSegment('Pending Transit', pendingCod.length.toDouble(), const Color(0xFFF59E0B)),
                      _DonutSegment('Cancelled', cancelledCod.length.toDouble(), const Color(0xFFEF4444)),
                    ],
                    centerLabel: 'Deliveries',
                    centerValue: '${codSales.length}',
                  ),
                ),
                sectionCard(
                  'COD Shipments Routes Log',
                  SizedBox(
                    height: 200,
                    child: codSales.isEmpty
                        ? const Center(child: Text('No cash on delivery records found'))
                        : ListView.separated(
                            itemCount: codSales.length,
                            separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withOpacity(0.4)),
                            itemBuilder: (context, index) {
                              final sale = codSales[index];
                              final isCompleted = sale.status.toUpperCase() == 'COMPLETED';
                              final isPending = !isCompleted && sale.status.toUpperCase() != 'CANCELLED';
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.local_shipping_outlined,
                                  color: isCompleted
                                      ? Colors.green
                                      : isPending
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                                title: Text('${sale.customerName.isEmpty ? "Walk-in" : sale.customerName} (${_formatDisplayInvoiceNumber(sale)})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Address: ${sale.shippingAddress.isEmpty ? 'No shipping address' : sale.shippingAddress}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(_money(sale.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      sale.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted
                                            ? Colors.green
                                            : isPending
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ];

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: kids[0]),
                        const SizedBox(width: 18),
                        Expanded(child: kids[1]),
                      ],
                    )
                  : Column(
                      children: [
                        kids[0],
                        const SizedBox(height: 18),
                        kids[1],
                      ],
                    );
            }),
          ] else if (_selectedReportType == 'po') ...[
            // ─── PURCHASE ORDERS TAB ───

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metricCard('Purchase Orders Count', '${periodPOs.length} Restocks', 'Restock restructures', Icons.assignment_outlined, const Color(0xFF3B82F6)),
                metricCard('Total Restocked Value', _money(totalPOAmount), 'Invested sum total', Icons.monetization_on_outlined, const Color(0xFF8B5CF6)),
                metricCard('Paid to Suppliers', _money(totalPOPaid), 'Direct cash out flow', Icons.check_circle_outline, const Color(0xFF10B981)),
                metricCard('Outstanding Owed', _money(totalPODue), 'Accounts payable balance', Icons.warning_amber_rounded, const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 18),
            // Supplier aggregates and PO status side-by-side
            LayoutBuilder(builder: (context, boxConstraints) {
              final isWide = boxConstraints.maxWidth > 700;

              // Group restocks by Supplier
              final supplierPOStats = <String, Map<String, dynamic>>{};
              for (final po in periodPOs) {
                final map = supplierPOStats.putIfAbsent(po.supplier, () => {'name': po.supplier, 'amount': 0.0, 'paid': 0.0, 'due': 0.0, 'count': 0});
                map['amount'] = (map['amount'] ?? 0.0) + po.amount;
                map['paid'] = (map['paid'] ?? 0.0) + po.amountPaid;
                map['due'] = (map['due'] ?? 0.0) + po.amountDue;
                map['count'] = (map['count'] ?? 0) + 1;
              }
              final sortedSupplierStats = supplierPOStats.values.toList()..sort((a, b) => b['amount'].compareTo(a['amount']));

              final kids = [
                sectionCard(
                  'PO Payment Breakdown',
                  _CustomDonutChart(
                    segments: [
                      _DonutSegment('Paid to Suppliers', totalPOPaid, const Color(0xFF10B981)),
                      _DonutSegment('Owed Due', totalPODue, const Color(0xFFEF4444)),
                    ],
                    centerLabel: 'Total Owed',
                    centerValue: _money(totalPODue),
                  ),
                ),
                sectionCard(
                  'Supplier Restock Volumes',
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedSupplierStats.take(5).length,
                    separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withOpacity(0.4)),
                    itemBuilder: (context, index) {
                      final s = sortedSupplierStats[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.secondary.withOpacity(0.1),
                          child: const Icon(Icons.local_shipping_outlined, size: 18),
                        ),
                        title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s['count']} orders • Due: ${_money(s['due'])}'),
                        trailing: Text(_money(s['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
                ),
              ];

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: kids[0]),
                        const SizedBox(width: 18),
                        Expanded(child: kids[1]),
                      ],
                    )
                  : Column(
                      children: [
                        kids[0],
                        const SizedBox(height: 18),
                        kids[1],
                      ],
                    );
            }),
            const SizedBox(height: 18),
            // Restocks history log list
            sectionCard(
              'Restocks & Purchase Orders History',
              () {
                if (periodPOs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('No restock records found.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('PO ID')),
                      DataColumn(label: Text('Supplier')),
                      DataColumn(label: Text('Restocked Date')),
                      DataColumn(label: Text('Method')),
                      DataColumn(label: Text('Amount'), numeric: true),
                      DataColumn(label: Text('Paid'), numeric: true),
                      DataColumn(label: Text('Due Balance'), numeric: true),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: periodPOs.map((po) {
                      final poDate = DateTime.tryParse(po.createdAt) ?? DateTime.now();
                      return DataRow(
                        cells: [
                          DataCell(Text(po.id)),
                          DataCell(Text(po.supplier)),
                          DataCell(Text(_formatDate(poDate))),
                          DataCell(Text(po.paymentMethod)),
                          DataCell(Text(_money(po.amount), textAlign: TextAlign.right)),
                          DataCell(Text(_money(po.amountPaid), textAlign: TextAlign.right)),
                          DataCell(Text(_money(po.amountDue), textAlign: TextAlign.right)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: po.status == 'RECEIVED'
                                    ? const Color(0xFF10B981).withOpacity(0.15)
                                    : Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                po.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: po.status == 'RECEIVED' ? const Color(0xFF10B981) : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }(),
            ),
          ] else if (_selectedReportType == 'mobileReload') ...[
            // ─── MOBILE RELOADS TAB ───

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                metricCard('Reload Sales Volume', _money(totalReloadAmount), '${filteredReloads.length} Reloads processed', Icons.phone_android_rounded, const Color(0xFF3B82F6)),
                metricCard('Earned Commissions', _money(totalReloadCommissions), 'Net reload profit margin', Icons.monetization_on_outlined, const Color(0xFF10B981)),
                metricCard('Total Settled Owed', _money(totalSettledAmount), 'Paid out to telecom companies', Icons.payments_outlined, const Color(0xFF8B5CF6)),
                metricCard('Outstanding Owed', _money(outstandingOwed), 'Pending settlement balance', Icons.warning_amber_rounded, outstandingOwed > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 18),
            // Operator breakdown and detailed list side-by-side or stacked
            LayoutBuilder(builder: (context, boxConstraints) {
              final isWide = boxConstraints.maxWidth > 700;

              // Group by Operator
              final opStats = <String, Map<String, dynamic>>{};
              for (final r in filteredReloads) {
                final map = opStats.putIfAbsent(r.operator, () => {'name': r.operator, 'amount': 0.0, 'commission': 0.0, 'count': 0});
                map['amount'] = (map['amount'] ?? 0.0) + r.amount;
                map['commission'] = (map['commission'] ?? 0.0) + r.commission;
                map['count'] = (map['count'] ?? 0) + 1;
              }
              final List<_DonutSegment> donutSegments = opStats.entries.map((e) {
                Color c = const Color(0xFF9E9E9E);
                if (e.key == 'Dialog') c = const Color(0xFFE91E63);
                if (e.key == 'Mobitel') c = const Color(0xFF4CAF50);
                if (e.key == 'Hutch') c = const Color(0xFFFF9800);
                if (e.key == 'Airtel') c = const Color(0xFFF44336);
                if (e.key == 'SLT') c = const Color(0xFF2196F3);
                if (e.key == 'eZ Cash') c = const Color(0xFF673AB7);
                return _DonutSegment(e.key, (e.value['amount'] ?? 0.0).toDouble(), c);
              }).toList();

              final kids = [
                sectionCard(
                  'Operator Breakdown',
                  _CustomDonutChart(
                    segments: donutSegments,
                    centerLabel: 'Profit',
                    centerValue: _money(totalReloadCommissions),
                  ),
                ),
                sectionCard(
                  'Operator Sales Summary',
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: opStats.length,
                    separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withOpacity(0.4)),
                    itemBuilder: (context, index) {
                      final key = opStats.keys.elementAt(index);
                      final val = opStats[key]!;
                      Color c = const Color(0xFF9E9E9E);
                      if (key == 'Dialog') c = const Color(0xFFE91E63);
                      if (key == 'Mobitel') c = const Color(0xFF4CAF50);
                      if (key == 'Hutch') c = const Color(0xFFFF9800);
                      if (key == 'Airtel') c = const Color(0xFFF44336);
                      if (key == 'SLT') c = const Color(0xFF2196F3);
                      if (key == 'eZ Cash') c = const Color(0xFF673AB7);
                      
                      // Calculate Owed for this operator
                      final double opOwed = val['amount'] - val['commission'];
                      double opSettled = 0.0;
                      for (final tx in _cashTransactions) {
                        if (tx.type == 'OUT' &&
                            tx.referenceType == 'OPERATOR_SETTLEMENT' &&
                            tx.referenceId == key.toUpperCase()) {
                          opSettled += tx.amount;
                        }
                      }
                      final opOutstanding = opOwed - opSettled;

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: c.withOpacity(0.1),
                          child: Icon(
                            key == 'eZ Cash' ? Icons.wallet_rounded : Icons.phone_iphone_rounded,
                            color: c,
                            size: 18,
                          ),
                        ),
                        title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${val['count']} reloads • Comm: ${_money(val['commission'])} • Outstanding Owed: ${_money(opOutstanding)}'),
                        trailing: Text(_money(val['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
                ),
              ];

              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: kids[0]),
                        const SizedBox(width: 18),
                        Expanded(child: kids[1]),
                      ],
                    )
                  : Column(
                      children: [
                        kids[0],
                        const SizedBox(height: 18),
                        kids[1],
                      ],
                    );
            }),
            const SizedBox(height: 18),
            // Detailed reload transactions history table
            sectionCard(
              'Detailed Reload History',
              () {
                if (filteredReloads.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('No reload records found.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Transaction ID')),
                      DataColumn(label: Text('Operator')),
                      DataColumn(label: Text('Phone Number')),
                      DataColumn(label: Text('Date & Time')),
                      DataColumn(label: Text('Reload Amount'), numeric: true),
                      DataColumn(label: Text('Earned Commission'), numeric: true),
                    ],
                    rows: filteredReloads.map((r) {
                      return DataRow(
                        cells: [
                          DataCell(Text(r.id)),
                          DataCell(Text(r.operator)),
                          DataCell(Text(r.phoneNumber)),
                          DataCell(Text(_formatDate(r.createdAt))),
                          DataCell(Text(_money(r.amount), textAlign: TextAlign.right)),
                          DataCell(Text(_money(r.commission), textAlign: TextAlign.right, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600))),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _exportInventoryPdf(List<_ProductItem> products) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Inventory Valuation PDF',
        fileName: 'Inventory_Valuation_Report.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (outputPath == null) return;

      final doc = pw.Document();
      final fontRegular = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (ctx) {
            double totalCost = 0.0;
            double totalRetail = 0.0;
            for (final p in products) {
              final cost = _unitInventoryCost(p);
              totalCost += cost * p.stock;
              totalRetail += p.price * p.stock;
            }
            final totalProfit = (totalRetail - totalCost).clamp(0.0, double.infinity);

            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _companyName.trim().isEmpty ? 'StoreBuddy POS' : _companyName.trim(),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: fontBold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Inventory Valuation & Profit Markup Report',
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, font: fontRegular),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: ${_formatDate(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 10, font: fontRegular),
                      ),
                      pw.Text(
                        'Filtered Category: $_reportsInventoryCategoryFilter',
                        style: pw.TextStyle(fontSize: 10, font: fontRegular),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Cost Value: ${_money(totalCost)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold)),
                  pw.Text('Total Retail Value: ${_money(totalRetail)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold)),
                  pw.Text('Expected Margin: ${_money(totalProfit)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold)),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Cost', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Retail Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Val. Cost', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Val. Retail', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Markup %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold))),
                    ],
                  ),
                  ...products.map((p) {
                    final cost = _unitInventoryCost(p);
                    final valCost = cost * p.stock;
                    final valRetail = p.price * p.stock;
                    final margin = p.price <= 0 ? 0.0 : ((p.price - cost) / p.price) * 100;
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.name, style: pw.TextStyle(font: fontRegular))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.category, style: pw.TextStyle(font: fontRegular))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${p.stock}', style: pw.TextStyle(font: fontRegular))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_money(cost), style: pw.TextStyle(font: fontRegular))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_money(p.price), style: pw.TextStyle(font: fontRegular))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_money(valCost), style: pw.TextStyle(font: fontRegular))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_money(valRetail), style: pw.TextStyle(font: fontRegular))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${margin.toStringAsFixed(1)}%', style: pw.TextStyle(font: fontRegular))),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      final pdfBytes = await doc.save();
      await File(outputPath).writeAsBytes(pdfBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved Inventory PDF successfully to $outputPath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  Future<void> _exportInventoryCsv(List<_ProductItem> products) async {
    try {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Inventory Valuation CSV',
        fileName: 'Inventory_Valuation_Report.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (outputPath == null) return;

      final csvLines = <String>[];
      csvLines.add('Product,Category,Stock Quantity,Unit Cost,Unit Price,Valuation (Cost),Valuation (Retail),Profit Markup %');
      for (final p in products) {
        final cost = _unitInventoryCost(p);
        final valCost = cost * p.stock;
        final valRetail = p.price * p.stock;
        final margin = p.price <= 0 ? 0.0 : ((p.price - cost) / p.price) * 100;
        final nameEsc = p.name.replaceAll('"', '""');
        final catEsc = p.category.replaceAll('"', '""');
        csvLines.add('"$nameEsc","$catEsc",${p.stock},${cost.toStringAsFixed(2)},${p.price.toStringAsFixed(2)},${valCost.toStringAsFixed(2)},${valRetail.toStringAsFixed(2)},${margin.toStringAsFixed(1)}%');
      }

      final csvContent = csvLines.join('\n');
      await File(outputPath).writeAsString(csvContent);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved Inventory CSV successfully to $outputPath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
  }
}

// ─── CUSTOM CANVAS CHART PAINTERS ───

class _CustomLineChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final String yAxisPrefix;
  final List<Color> gradientColors;
  final double height;

  const _CustomLineChart({
    required this.data,
    this.yAxisPrefix = '',
    this.gradientColors = const [Color(0xFF3B82F6), Color(0xFF10B981)],
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _CustomLineChartPainter(
        data: data,
        yAxisPrefix: yAxisPrefix,
        gradientColors: gradientColors,
        isDark: isDark,
      ),
    );
  }
}

class _CustomLineChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final String yAxisPrefix;
  final List<Color> gradientColors;
  final bool isDark;

  _CustomLineChartPainter({
    required this.data,
    required this.yAxisPrefix,
    required this.gradientColors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'No data available',
          style: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2));
      return;
    }

    const double paddingLeft = 55.0;
    const double paddingRight = 20.0;
    const double paddingTop = 20.0;
    const double paddingBottom = 30.0;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    final double maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double maxScale = maxVal == 0 ? 1.0 : maxVal;

    // Draw Grid Lines (Y-Axis)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)
      ..strokeWidth = 1;

    final labelStyle = TextStyle(
      color: isDark ? Colors.white54 : Colors.black54,
      fontSize: 10,
      fontFamily: 'monospace',
    );

    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + height - (i / 4.0) * height;
      canvas.drawLine(Offset(paddingLeft, y), Offset(paddingLeft + width, y), gridPaint);

      // Label
      final gridVal = (i / 4.0) * maxScale;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$yAxisPrefix${_formatCompact(gridVal)}',
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Coordinates of data points
    final points = <Offset>[];
    final double stepX = data.length > 1 ? width / (data.length - 1) : width;

    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + i * stepX;
      final y = paddingTop + height - (data[i].value / maxScale) * height;
      points.add(Offset(x, y));
    }

    // Draw area gradient
    if (points.isNotEmpty) {
      final fillPath = Path()
        ..moveTo(paddingLeft, paddingTop + height);
      for (int i = 0; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, paddingTop + height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradientColors.first.withOpacity(0.35),
            gradientColors.last.withOpacity(0.00),
          ],
        ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, width, height));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw smooth line
    if (points.isNotEmpty) {
      final linePath = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      final linePaint = Paint()
        ..shader = LinearGradient(
          colors: gradientColors,
        ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, width, height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw points & labels & X axis
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dotStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..strokeWidth = 2;

    // Show text labels for X-axis
    final labelInterval = (data.length / 5).ceil().clamp(1, 99);

    for (int i = 0; i < data.length; i++) {
      final pt = points[i];

      // Draw dot
      dotPaint.color = gradientColors.first;
      canvas.drawCircle(pt, 5.0, dotPaint);
      canvas.drawCircle(pt, 5.0, dotStroke);

      // Draw label
      if (i % labelInterval == 0 || i == data.length - 1) {
        final xLabelPainter = TextPainter(
          text: TextSpan(
            text: data[i].key,
            style: labelStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        xLabelPainter.paint(
          canvas,
          Offset(pt.dx - xLabelPainter.width / 2, paddingTop + height + 8),
        );
      }
    }
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000.0).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000.0).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  @override
  bool shouldRepaint(covariant _CustomLineChartPainter oldDelegate) => true;
}

class _BarGroup {
  final String label;
  final double val1;
  final double val2;
  _BarGroup(this.label, this.val1, this.val2);
}

class _CustomBarChart extends StatelessWidget {
  final List<_BarGroup> groups;
  final String label1;
  final String label2;
  final Color color1;
  final Color color2;
  final String yAxisPrefix;
  final double height;

  const _CustomBarChart({
    required this.groups,
    required this.label1,
    this.label2 = '',
    this.color1 = const Color(0xFF3B82F6),
    this.color2 = const Color(0xFFEF4444),
    this.yAxisPrefix = '',
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        CustomPaint(
          size: Size(double.infinity, height),
          painter: _CustomBarChartPainter(
            groups: groups,
            color1: color1,
            color2: color2,
            yAxisPrefix: yAxisPrefix,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color1, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 6),
                Text(label1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            if (label2.isNotEmpty) ...[
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color2, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text(label2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CustomBarChartPainter extends CustomPainter {
  final List<_BarGroup> groups;
  final Color color1;
  final Color color2;
  final String yAxisPrefix;
  final bool isDark;

  _CustomBarChartPainter({
    required this.groups,
    required this.color1,
    required this.color2,
    required this.yAxisPrefix,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (groups.isEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'No data available',
          style: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2));
      return;
    }

    const double paddingLeft = 55.0;
    const double paddingRight = 20.0;
    const double paddingTop = 20.0;
    const double paddingBottom = 30.0;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    double maxVal = 0.0;
    for (final g in groups) {
      if (g.val1 > maxVal) maxVal = g.val1;
      if (g.val2 > maxVal) maxVal = g.val2;
    }
    final double maxScale = maxVal == 0 ? 1.0 : maxVal;

    // Draw Grid Lines (Y-Axis)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)
      ..strokeWidth = 1;

    final labelStyle = TextStyle(
      color: isDark ? Colors.white54 : Colors.black54,
      fontSize: 10,
      fontFamily: 'monospace',
    );

    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + height - (i / 4.0) * height;
      canvas.drawLine(Offset(paddingLeft, y), Offset(paddingLeft + width, y), gridPaint);

      // Label
      final gridVal = (i / 4.0) * maxScale;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$yAxisPrefix${_formatCompact(gridVal)}',
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    final double groupWidth = width / groups.length;
    final double barWidth = groups[0].val2 == 0 && groups.every((g) => g.val2 == 0) ? 22 : 12;
    const double spacing = 4.0;

    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final double groupCenterX = paddingLeft + i * groupWidth + groupWidth / 2;

      // Draw first bar
      final bar1Height = (group.val1 / maxScale) * height;
      if (bar1Height > 0) {
        final paint1 = Paint()..color = color1;
        final x1 = group.val2 != 0 || !groups.every((g) => g.val2 == 0)
            ? groupCenterX - barWidth - spacing / 2
            : groupCenterX - barWidth / 2;
        final y1 = paddingTop + height - bar1Height;
        final rect1 = RRect.fromRectAndCorners(
          Rect.fromLTWH(x1, y1, barWidth, bar1Height),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect1, paint1);
      }

      // Draw second bar
      if (group.val2 > 0) {
        final bar2Height = (group.val2 / maxScale) * height;
        final paint2 = Paint()..color = color2;
        final x2 = groupCenterX + spacing / 2;
        final y2 = paddingTop + height - bar2Height;
        final rect2 = RRect.fromRectAndCorners(
          Rect.fromLTWH(x2, y2, barWidth, bar2Height),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(rect2, paint2);
      }

      // X-Axis labels
      final textPainter = TextPainter(
        text: TextSpan(
          text: group.label,
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(groupCenterX - textPainter.width / 2, paddingTop + height + 8),
      );
    }
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000.0).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000.0).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  @override
  bool shouldRepaint(covariant _CustomBarChartPainter oldDelegate) => true;
}

class _DonutSegment {
  final String label;
  final double value;
  final Color color;
  _DonutSegment(this.label, this.value, this.color);
}

class _CustomDonutChart extends StatelessWidget {
  final List<_DonutSegment> segments;
  final String centerLabel;
  final String centerValue;
  final double height;

  const _CustomDonutChart({
    required this.segments,
    this.centerLabel = 'Total',
    required this.centerValue,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double total = segments.fold(0, (sum, s) => sum + s.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: SizedBox(
                height: height,
                child: CustomPaint(
                  painter: _CustomDonutChartPainter(
                    segments: segments,
                    centerLabel: centerLabel,
                    centerValue: centerValue,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: segments.map((seg) {
                  final pct = total <= 0 ? 0.0 : (seg.value / total) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: seg.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            seg.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomDonutChartPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final String centerLabel;
  final String centerValue;
  final bool isDark;

  _CustomDonutChartPainter({
    required this.segments,
    required this.centerLabel,
    required this.centerValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = segments.fold(0.0, (sum, s) => sum + s.value);
    final double center = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = math.min(center, centerY) * 0.85;
    final double strokeWidth = radius * 0.35;

    final rect = Rect.fromCircle(center: Offset(center, centerY), radius: radius - strokeWidth / 2);

    if (total == 0) {
      final paint = Paint()
        ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(Offset(center, centerY), radius - strokeWidth / 2, paint);

      // Center text
      _drawCenterText(canvas, center, centerY);
      return;
    }

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweepAngle = (seg.value / total) * (2 * math.pi);

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Center text
    _drawCenterText(canvas, center, centerY);
  }

  void _drawCenterText(Canvas canvas, double centerX, double centerY) {
    final titleStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    );

    final titlePainter = TextPainter(
      text: TextSpan(text: centerLabel, style: titleStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final valuePainter = TextPainter(
      text: TextSpan(text: centerValue, style: valueStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    titlePainter.paint(canvas, Offset(centerX - titlePainter.width / 2, centerY - 14));
    valuePainter.paint(canvas, Offset(centerX - valuePainter.width / 2, centerY));
  }

  @override
  bool shouldRepaint(covariant _CustomDonutChartPainter oldDelegate) => true;
}
