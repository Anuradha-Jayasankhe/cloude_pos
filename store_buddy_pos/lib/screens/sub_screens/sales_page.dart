part of '../dashboard_screen.dart';

extension _sales_pageExt on _DashboardScreenState {
  bool get _canClearSalesData => _isOwner;

  Future<bool> _confirmSalesDataDelete({
    required int orderCount,
    required double revenue,
    required bool clearAll,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(clearAll ? 'Clear All Sales Data' : 'Delete Sales Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orders to delete: $orderCount'),
            const SizedBox(height: 6),
            Text('Revenue affected: ${_money(revenue)}'),
            const SizedBox(height: 12),
            const Text(
              'This removes sales-related records only (sales, linked installments, linked credit entries, and linked stock adjustment logs). Products, customers, and catalog data are not deleted.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(clearAll ? 'Clear All Sales' : 'Delete Selected'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _deleteSalesData(List<_SaleRecord> salesToDelete) async {
    if (salesToDelete.isEmpty) return;

    final saleIds = salesToDelete.map((sale) => sale.id).toSet();
    final installmentIdsToDelete = _installmentPlans
        .where((plan) => saleIds.contains(plan.saleId))
        .map((plan) => plan.id)
        .toList();

    final creditSaleIdsToDelete = <String>[];
    final affectedCustomerIds = <String>{};
    for (final entry in _customerCreditSales.entries) {
      for (final creditSale in entry.value) {
        if (!saleIds.contains(creditSale.saleId)) continue;
        creditSaleIdsToDelete.add(creditSale.id);
        affectedCustomerIds.add(entry.key);
      }
    }

    bool referencesDeletedSale(_StockAdjustmentItem adjustment) {
      for (final saleId in saleIds) {
        if (adjustment.reason.contains(saleId)) {
          return true;
        }
      }
      return false;
    }

    final stockAdjustmentIdsToDelete = _stockAdjustments
        .where(referencesDeletedSale)
        .map((item) => item.id)
        .toList();

    setState(() {
      _sales.removeWhere((sale) => saleIds.contains(sale.id));
      _installmentPlans.removeWhere((plan) => saleIds.contains(plan.saleId));
      _stockAdjustments.removeWhere(
        (entry) => stockAdjustmentIdsToDelete.contains(entry.id),
      );

      final emptyCreditCustomers = <String>[];
      _customerCreditSales.forEach((customerId, creditSales) {
        creditSales.removeWhere(
          (creditSale) => saleIds.contains(creditSale.saleId),
        );
        if (creditSales.isEmpty) {
          emptyCreditCustomers.add(customerId);
        }
      });
      for (final customerId in emptyCreditCustomers) {
        _customerCreditSales.remove(customerId);
      }

      for (final customer in _customers) {
        customer.currentBalance = _customerOutstandingBalance(
          customer.id,
          fallback: 0,
        );
      }
    });

    if (_saleRepository != null) {
      await _saleRepository!.deleteSalesByIds(saleIds);
    }

    await _persistWorkspaceData();

    for (final saleId in saleIds) {
      await _enqueueSync('DELETE', 'sales', saleId);
    }
    for (final installmentId in installmentIdsToDelete) {
      await _enqueueSync('DELETE', 'installments', installmentId);
    }
    for (final creditSaleId in creditSaleIdsToDelete) {
      await _enqueueSync('DELETE', 'credit_sales', creditSaleId);
    }
    for (final stockAdjustmentId in stockAdjustmentIdsToDelete) {
      await _enqueueSync('DELETE', 'stock_adjustments', stockAdjustmentId);
    }
    for (final customerId in affectedCustomerIds) {
      await _enqueueSync('UPDATE', 'customers', customerId);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${saleIds.length} sale record(s).')),
    );
  }

  Future<void> _openSalesDataClearingPage() async {
    if (!_canClearSalesData) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin can clear sales data.')),
      );
      return;
    }

    DateTimeRange? selectedRange;
    final selectedSaleIds = <String>{};

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pageContext) => StatefulBuilder(
          builder: (pageContext, setLocal) {
            bool inRange(DateTime createdAt) {
              if (selectedRange == null) return true;
              final day = DateTime(
                createdAt.year,
                createdAt.month,
                createdAt.day,
              );
              final start = DateTime(
                selectedRange!.start.year,
                selectedRange!.start.month,
                selectedRange!.start.day,
              );
              final end = DateTime(
                selectedRange!.end.year,
                selectedRange!.end.month,
                selectedRange!.end.day,
              );
              return !day.isBefore(start) && !day.isAfter(end);
            }

            String formatShortDate(DateTime value) {
              return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
            }

            final scopedSales =
                _scopedSales.where((sale) => inRange(sale.createdAt)).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            selectedSaleIds.removeWhere(
              (id) => !scopedSales.any((sale) => sale.id == id),
            );

            final selectedSales = scopedSales
                .where((sale) => selectedSaleIds.contains(sale.id))
                .toList();
            final selectedRevenue = selectedSales.fold<double>(
              0,
              (sum, sale) => sum + sale.total,
            );
            final allScopedRevenue = scopedSales.fold<double>(
              0,
              (sum, sale) => sum + sale.total,
            );
            final allSelected =
                scopedSales.isNotEmpty &&
                scopedSales.every((sale) => selectedSaleIds.contains(sale.id));

            Future<void> deleteSelectedSales() async {
              if (selectedSales.isEmpty) return;
              final confirmed = await _confirmSalesDataDelete(
                orderCount: selectedSales.length,
                revenue: selectedRevenue,
                clearAll: false,
              );
              if (!confirmed) return;
              await _deleteSalesData(selectedSales);
              setLocal(() {
                selectedSaleIds.removeWhere(
                  (id) => !_scopedSales.any((sale) => sale.id == id),
                );
              });
            }

            Future<void> deleteAllScopedSales() async {
              if (scopedSales.isEmpty) return;
              final confirmed = await _confirmSalesDataDelete(
                orderCount: scopedSales.length,
                revenue: allScopedRevenue,
                clearAll: true,
              );
              if (!confirmed) return;
              await _deleteSalesData(scopedSales);
              setLocal(() => selectedSaleIds.clear());
            }

            return Scaffold(
              appBar: AppBar(title: const Text('Data Clearing')),
              body: Padding(
                padding: const EdgeInsets.all(UiSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permanently remove only sales data. Products and customers are kept.',
                      style: TextStyle(color: Color(0xFF6D7383)),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 980;
                          final salesCard = Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UiRadius.lg),
                              side: BorderSide(
                                color: Theme.of(
                                  pageContext,
                                ).colorScheme.outline,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(UiSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      FilledButton.tonalIcon(
                                        onPressed: scopedSales.isEmpty
                                            ? null
                                            : deleteAllScopedSales,
                                        icon: const Icon(
                                          Icons.delete_sweep_outlined,
                                        ),
                                        label: const Text('Clear All'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final now = DateTime.now();
                                          final picked =
                                              await showDateRangePicker(
                                                context: pageContext,
                                                firstDate: DateTime(
                                                  now.year - 5,
                                                ),
                                                lastDate: now,
                                                initialDateRange: selectedRange,
                                              );
                                          if (picked == null) return;
                                          setLocal(
                                            () => selectedRange = picked,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.calendar_month_outlined,
                                        ),
                                        label: Text(
                                          selectedRange == null
                                              ? 'Date Range'
                                              : '${formatShortDate(selectedRange!.start)} to ${formatShortDate(selectedRange!.end)}',
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: scopedSales.isEmpty
                                            ? null
                                            : () {
                                                setLocal(() {
                                                  if (allSelected) {
                                                    selectedSaleIds.clear();
                                                  } else {
                                                    selectedSaleIds
                                                      ..clear()
                                                      ..addAll(
                                                        scopedSales.map(
                                                          (sale) => sale.id,
                                                        ),
                                                      );
                                                  }
                                                });
                                              },
                                        icon: const Icon(
                                          Icons.playlist_add_check_outlined,
                                        ),
                                        label: Text(
                                          allSelected
                                              ? 'Unselect Orders'
                                              : 'Select Orders',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text('${selectedSales.length} selected'),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(
                                            pageContext,
                                          ).colorScheme.outline,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          UiRadius.md,
                                        ),
                                      ),
                                      child: scopedSales.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No sales available for selected range.',
                                              ),
                                            )
                                          : ListView.separated(
                                              itemCount: scopedSales.length,
                                              separatorBuilder: (_, _) =>
                                                  const Divider(height: 1),
                                              itemBuilder: (context, index) {
                                                final sale = scopedSales[index];
                                                final selected = selectedSaleIds
                                                    .contains(sale.id);
                                                return CheckboxListTile(
                                                  value: selected,
                                                  controlAffinity:
                                                      ListTileControlAffinity
                                                          .leading,
                                                  onChanged: (value) {
                                                    setLocal(() {
                                                      if (value == true) {
                                                        selectedSaleIds.add(
                                                          sale.id,
                                                        );
                                                      } else {
                                                        selectedSaleIds.remove(
                                                          sale.id,
                                                        );
                                                      }
                                                    });
                                                  },
                                                  title: Text(sale.id),
                                                  subtitle: Text(
                                                    '${sale.createdAt.month}/${sale.createdAt.day}/${sale.createdAt.year} ${sale.createdAt.hour.toString().padLeft(2, '0')}:${sale.createdAt.minute.toString().padLeft(2, '0')}',
                                                  ),
                                                  secondary: Text(
                                                    _money(sale.total),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          final summaryCard = Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UiRadius.lg),
                              side: BorderSide(
                                color: Theme.of(
                                  pageContext,
                                ).colorScheme.outline,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(UiSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Summary',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: UiSpacing.sm),
                                  _overviewRow(
                                    'Orders to delete',
                                    '${selectedSales.length}',
                                  ),
                                  _overviewRow(
                                    'Revenue affected',
                                    _money(selectedRevenue),
                                  ),
                                  const SizedBox(height: UiSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4DE),
                                      borderRadius: BorderRadius.circular(
                                        UiRadius.md,
                                      ),
                                    ),
                                    child: const Text(
                                      'Deleted sales will be removed from reports, dashboards, and sales statistics.',
                                      style: TextStyle(
                                        color: Color(0xFF8A5A00),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(46),
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: selectedSales.isEmpty
                                        ? null
                                        : deleteSelectedSales,
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(
                                      'Clear ${selectedSales.length} Order(s)',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (compact) {
                            return Column(
                              children: [
                                Expanded(child: salesCard),
                                const SizedBox(height: UiSpacing.sm),
                                SizedBox(height: 230, child: summaryCard),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: salesCard),
                              const SizedBox(width: UiSpacing.sm),
                              SizedBox(
                                width: _adaptiveWidth(
                                  300,
                                  minWidth: 240,
                                  horizontalPadding: 40,
                                ),
                                child: summaryCard,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSalesPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final query = _salesSearchController.text.trim().toLowerCase();
    final periodFiltered = _scopedSales.where((sale) {
      if (_salesTimeFilter == 'All Time') return true;
      final day = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_salesTimeFilter == 'Today') {
        return day.isAtSameMomentAs(today);
      }
      if (_salesTimeFilter == 'This Week') {
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return !day.isBefore(startOfWeek);
      }
      if (_salesTimeFilter == 'This Month') {
        return day.year == today.year && day.month == today.month;
      }
      if (_salesTimeFilter == 'This Year') {
        return day.year == today.year;
      }
      return true;
    }).toList();

    final cashierUsers = _scopedUsers
        .where((u) => u.role.trim().toLowerCase() != 'delivery')
        .toList();
    final cashierById = <String, _UserItem>{
      for (final user in cashierUsers) user.id: user,
    };
    final cashierIdByNameLower = <String, String>{
      for (final user in cashierUsers)
        if (user.name.trim().isNotEmpty)
          user.name.trim().toLowerCase(): user.id,
    };

    String? resolveCashierUserId(_SaleRecord sale) {
      final employeeId = sale.employeeId.trim();
      if (employeeId.isNotEmpty && cashierById.containsKey(employeeId)) {
        return employeeId;
      }

      final cashierName = sale.cashierName.trim().toLowerCase();
      if (cashierName.isNotEmpty) {
        return cashierIdByNameLower[cashierName];
      }

      return null;
    }

    String resolveCashierDisplayName(_SaleRecord sale) {
      final resolvedId = resolveCashierUserId(sale);
      if (resolvedId != null) {
        final resolved = cashierById[resolvedId];
        if (resolved != null && resolved.name.trim().isNotEmpty) {
          return resolved.name.trim();
        }
      }

      final fallback = sale.cashierName.trim();
      return fallback.isEmpty ? 'Staff' : fallback;
    }

    Future<void> printSaleBill(_SaleRecord sale) async {
      final lines = sale.items.map((item) {
        final discountType = item.discountType.toUpperCase();
        final discountValue = item.discount;
        final originalPrice = discountType == 'PERCENT'
            ? (discountValue >= 100
                  ? item.unitPrice
                  : item.unitPrice / (1 - (discountValue / 100)))
            : item.unitPrice + discountValue;
        return _CartLine(
          product: _ProductItem(
            id: item.productId,
            name: item.productName,
            category: 'Item',
            price: originalPrice,
            stock: 0,
            minStock: 0,
          ),
          qty: item.quantity,
          discountValue: discountValue,
          discountType: discountType,
          discountLabel: '',
        );
      }).toList();
      await _printReceipt(sale: sale, lines: lines);
    }

    final scopedSales = periodFiltered.where((s) {
      if (_isCashier && _currentUserId.trim().isNotEmpty) {
        return resolveCashierUserId(s) == _currentUserId;
      }
      if (_isAgent) {
        if (s.employeeId.isNotEmpty &&
            _currentUserId.isNotEmpty &&
            s.employeeId == _currentUserId) {
          return true;
        }
        if (s.agentName.isNotEmpty &&
            _currentUserName.isNotEmpty &&
            s.agentName.toLowerCase() == _currentUserName.toLowerCase()) {
          return true;
        }
        return false;
      }
      return true;
    }).toList();

    final cashierLabels = <String, String>{'All Cashiers': 'All Cashiers'};
    if (_isCashier && _currentUserId.trim().isNotEmpty) {
      final ownName = _currentUserName.trim().isEmpty
          ? 'Cashier'
          : _currentUserName.trim();
      cashierLabels['id::$_currentUserId'] = ownName;
    } else {
      for (final user in cashierUsers) {
        final display = user.name.trim().isNotEmpty
            ? user.name.trim()
            : user.email.trim();
        cashierLabels['id::${user.id}'] = display.isEmpty ? 'Staff' : display;
      }
    }

    for (final sale in scopedSales) {
      final resolvedCashierId = resolveCashierUserId(sale);
      if (resolvedCashierId != null) {
        final key = 'id::$resolvedCashierId';
        final user = cashierById[resolvedCashierId];
        final label = (user?.name.trim().isNotEmpty ?? false)
            ? user!.name.trim()
            : (user?.email.trim().isNotEmpty ?? false)
            ? user!.email.trim()
            : resolveCashierDisplayName(sale);
        cashierLabels.putIfAbsent(key, () => label);
      }
    }

    final cashierOptions = cashierLabels.keys.toList();
    final customerOptions = {
      'All Customers',
      ...scopedSales.map(
        (s) => s.customerName.trim().isEmpty
            ? 'Walk-in Customer'
            : s.customerName.trim(),
      ),
    }.toList();
    const itemOptions = ['All Items', '1 Item', '2+ Items', '5+ Items'];

    final agentLabels = <String, String>{'All Agents': 'All Agents'};
    if (_isAgent) {
      final ownName = _currentUserName.trim().isEmpty
          ? 'Agent'
          : _currentUserName.trim();
      agentLabels[ownName] = ownName;
    } else {
      final agentNames = scopedSales
          .map((s) => s.agentName.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      for (final name in agentNames) {
        agentLabels[name] = name;
      }
    }
    final agentOptions = agentLabels.keys.toList();
    final categoryOptions = ['All Categories', ..._productCategories];

    final selectedCashier = cashierOptions.contains(_salesCashierFilter)
        ? _salesCashierFilter
        : 'All Cashiers';
    final selectedAgent = agentOptions.contains(_salesAgentFilter)
        ? _salesAgentFilter
        : 'All Agents';
    final selectedCategory = categoryOptions.contains(_salesCategoryFilter)
        ? _salesCategoryFilter
        : 'All Categories';
    final selectedCustomer = customerOptions.contains(_salesCustomerFilter)
        ? _salesCustomerFilter
        : 'All Customers';
    final selectedItemBucket = itemOptions.contains(_salesItemsFilter)
        ? _salesItemsFilter
        : 'All Items';

    final filtered = scopedSales.where((s) {
      if (query.isNotEmpty) {
        if (!s.id.toLowerCase().contains(query) &&
            !s.customerName.toLowerCase().contains(query) &&
            !s.paymentMethod.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (_salesFilterStatus != 'ALL' && s.status != _salesFilterStatus) {
        return false;
      }
      if (_salesFilterPayment != 'ALL') {
        if (_salesFilterPayment == 'SERVICE') {
          if (!_saleHasServiceItems(s)) {
            return false;
          }
        } else if (s.paymentMethod != _salesFilterPayment) {
          return false;
        }
      }

      if (selectedCashier != 'All Cashiers') {
        final selectedId = selectedCashier.startsWith('id::')
            ? selectedCashier.substring(4)
            : selectedCashier;
        final saleCashierId = resolveCashierUserId(s);
        if (selectedId.isNotEmpty) {
          final matchedUser = cashierById[selectedId];
          final matchedByName = matchedUser != null &&
              matchedUser.name.trim().isNotEmpty &&
              s.cashierName.trim().toLowerCase() == matchedUser.name.trim().toLowerCase();
          if (saleCashierId != selectedId && !matchedByName && s.employeeId != selectedId) {
            return false;
          }
        }
      }

      if (selectedAgent != 'All Agents') {
        if (s.agentName != selectedAgent) {
          return false;
        }
      }

      if (selectedCategory != 'All Categories') {
        final matches = s.items.any((item) {
          final prod = _products.firstWhere(
            (p) => p.id == item.productId,
            orElse: () => _ProductItem(
              id: '',
              name: '',
              locationId: '',
              category: '',
              barcode: '',
              measureUnit: '',
              productType: '',
              description: '',
              price: 0,
              stock: 0,
              minStock: 0,
            ),
          );
          return prod.category == selectedCategory;
        });
        if (!matches) {
          return false;
        }
      }

      final customerName = s.customerName.trim().isEmpty
          ? 'Walk-in Customer'
          : s.customerName.trim();
      if (selectedCustomer != 'All Customers' &&
          customerName != selectedCustomer) {
        return false;
      }

      final soldItemCount = s.items.fold<double>(
        0,
        (sum, item) => sum + item.quantity,
      );
      if (selectedItemBucket == '1 Item' && soldItemCount != 1) {
        return false;
      }
      if (selectedItemBucket == '2+ Items' && soldItemCount < 2) {
        return false;
      }
      if (selectedItemBucket == '5+ Items' && soldItemCount < 5) {
        return false;
      }

      return true;
    }).toList();

    final totalRevenue = filtered.fold<double>(0, (sum, s) => sum + s.total);
    final productRevenue = filtered.fold<double>(
      0,
      (sum, s) => sum + _saleProductRevenue(s),
    );
    final serviceRevenue = filtered.fold<double>(
      0,
      (sum, s) => sum + _saleServiceRevenue(s),
    );
    final avgOrder = filtered.isEmpty ? 0.0 : totalRevenue / filtered.length;
    final itemCount = filtered.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget customerActionButton({
      required String tooltip,
      required VoidCallback? onPressed,
      required IconData icon,
      Color? color,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: onPressed == null
              ? Colors.transparent
              : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9)),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                icon,
                size: 16,
                color: onPressed == null
                    ? (isDark ? Colors.white24 : Colors.black26)
                    : (color ??
                          (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569))),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(UiSpacing.lg),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GradientIconBox(
                          icon: Icons.receipt_long_rounded,
                          size: 42,
                          iconSize: 21,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) =>
                                  UiGradients.brand.createShader(
                                    Rect.fromLTWH(
                                      0,
                                      0,
                                      bounds.width,
                                      bounds.height,
                                    ),
                                  ),
                              child: const Text(
                                'Sales Management',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'View, filter, and audit sales transactions.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _exportSalesPdf(filtered),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF1E2D45)
                                  : const Color(0xFFE8EAFF),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(UiRadius.md),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.download_outlined, size: 16),
                          label: const Text(
                            'Export Data',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_canClearSalesData)
                          OutlinedButton.icon(
                            onPressed: _openSalesDataClearingPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.brandRose,
                              side: BorderSide(
                                color: AppTheme.brandRose.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  UiRadius.md,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(
                              Icons.delete_forever_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Data Clearing',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: UiSpacing.md),
                // Summary cards row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _salesSummaryCard(
                        'Total Sales',
                        '${filtered.length}',
                        icon: Icons.point_of_sale_rounded,
                        accent: UiGradients.brand,
                      ),
                      const SizedBox(width: UiSpacing.sm),
                      _salesSummaryCard(
                        'Total Revenue',
                        _money(totalRevenue),
                        icon: Icons.payments_rounded,
                        accent: UiGradients.success,
                      ),
                      const SizedBox(width: UiSpacing.sm),
                      _salesSummaryCard(
                        'Product Revenue',
                        _money(productRevenue),
                        subtitle: '$itemCount items sold',
                        icon: Icons.inventory_2_rounded,
                        accent: UiGradients.teal,
                      ),
                      const SizedBox(width: UiSpacing.sm),
                      _salesSummaryCard(
                        'Service Revenue',
                        _money(serviceRevenue),
                        subtitle:
                            '${filtered.where(_saleHasServiceItems).length} service sales',
                        icon: Icons.build_rounded,
                        accent: UiGradients.amber,
                      ),
                      const SizedBox(width: UiSpacing.sm),
                      _salesSummaryCard(
                        'Avg Order Value',
                        _money(avgOrder),
                        icon: Icons.trending_up_rounded,
                        accent: UiGradients.brandWide,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UiSpacing.md),
                // Filter section
                Container(
                  padding: const EdgeInsets.all(UiSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : Colors.white,
                    borderRadius: BorderRadius.circular(UiRadius.md),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E2D45)
                          : const Color(0xFFE8EAFF),
                    ),
                    boxShadow: UiShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 15,
                              color: AppTheme.brandIndigo.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Filter records',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: UiSpacing.xs,
                        runSpacing: UiSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: _adaptiveWidth(
                              360,
                              minWidth: 220,
                              horizontalPadding: 40,
                            ),
                            child: TextField(
                              controller: _salesSearchController,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search sales, customers...',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFFFAFAFF),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    UiRadius.md,
                                  ),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF1E2D45)
                                        : const Color(0xFFE8EAFF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    UiRadius.md,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.brandIndigo,
                                    width: 1.5,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    UiRadius.md,
                                  ),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF1E2D45)
                                        : const Color(0xFFE8EAFF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: _adaptiveWidth(
                              170,
                              minWidth: 150,
                              horizontalPadding: 40,
                            ),
                            child: _salesFilterDropdown(
                              value: selectedCashier,
                              items: cashierOptions,
                              onChanged: (v) =>
                                  setState(() => _salesCashierFilter = v),
                              labelMapper: (value) =>
                                  cashierLabels[value] ?? 'Cashier',
                            ),
                          ),
                          SizedBox(
                            width: _adaptiveWidth(
                              180,
                              minWidth: 160,
                              horizontalPadding: 40,
                            ),
                            child: _salesFilterDropdown(
                              value: selectedCustomer,
                              items: customerOptions,
                              onChanged: (v) =>
                                  setState(() => _salesCustomerFilter = v),
                            ),
                          ),
                          SizedBox(
                            width: _adaptiveWidth(
                              200,
                              minWidth: 170,
                              horizontalPadding: 40,
                            ),
                            child: _salesFilterDropdown(
                              value: _salesFilterPayment,
                              items: const [
                                'ALL',
                                'CASH',
                                'CARD',
                                'CHEQUE',
                                'CREDIT',
                                'INSTALLMENT',
                                'SERVICE',
                              ],
                              onChanged: (v) =>
                                  setState(() => _salesFilterPayment = v),
                              labelMapper: (v) =>
                                  v == 'ALL' ? 'All Payment Methods' : v,
                            ),
                          ),
                          SizedBox(
                            width: _adaptiveWidth(
                              160,
                              minWidth: 150,
                              horizontalPadding: 40,
                            ),
                            child: _salesFilterDropdown(
                              value: selectedItemBucket,
                              items: itemOptions,
                              onChanged: (v) =>
                                  setState(() => _salesItemsFilter = v),
                            ),
                          ),
                          SizedBox(
                            width: _adaptiveWidth(
                              160,
                              minWidth: 150,
                              horizontalPadding: 40,
                            ),
                            child: _salesFilterDropdown(
                              value: _salesTimeFilter,
                              items: const [
                                'All Time',
                                'Today',
                                'This Week',
                                'This Month',
                                'This Year',
                              ],
                              onChanged: (v) =>
                                  setState(() => _salesTimeFilter = v),
                            ),
                          ),
                          SizedBox(
                            width: _adaptiveWidth(
                              170,
                              minWidth: 150,
                              horizontalPadding: 40,
                            ),
                            child: _salesFilterDropdown(
                              value: selectedAgent,
                              items: agentOptions,
                              onChanged: (v) =>
                                  setState(() => _salesAgentFilter = v),
                              labelMapper: (value) =>
                                  agentLabels[value] ?? 'Agent',
                            ),
                          ),
                          SizedBox(
                            width: _adaptiveWidth(
                              170,
                              minWidth: 150,
                              horizontalPadding: 40,
                            ),
                            child: _salesFilterDropdown(
                              value: selectedCategory,
                              items: categoryOptions,
                              onChanged: (v) =>
                                  setState(() => _salesCategoryFilter = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: UiSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(UiRadius.lg),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E2D45)
                        : const Color(0xFFE8EAFF),
                  ),
                  boxShadow: UiShadows.card,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(UiRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(UiSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              size: 17,
                              color: AppTheme.brandIndigo.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Records (${filtered.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: UiSpacing.sm),
                        filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.brandIndigo
                                              .withValues(
                                                alpha: isDark ? 0.12 : 0.08,
                                              ),
                                        ),
                                        child: Icon(
                                          Icons.receipt_long_outlined,
                                          size: 30,
                                          color: AppTheme.brandIndigo
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: UiSpacing.sm),
                                      Text(
                                        'No sales records found for selected filters.',
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                          fontSize: 13.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth,
                                          ),
                                          child: Theme(
                                            data: Theme.of(context).copyWith(
                                              dividerColor: isDark
                                                  ? const Color(0xFF1E2D45)
                                                  : const Color(0xFFE8EAFF),
                                            ),
                                            child: DataTable(
                                              horizontalMargin: UiSpacing.sm,
                                              columnSpacing: UiSpacing.md,
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                    isDark
                                                        ? const Color(
                                                            0xFF1F2937,
                                                          ).withValues(
                                                            alpha: 0.4,
                                                          )
                                                        : const Color(
                                                            0xFFF1F5F9,
                                                          ),
                                                  ),
                                              columns: const [
                                                DataColumn(
                                                  label: Text('RECEIPT #'),
                                                ),
                                                DataColumn(
                                                  label: Text('DATE & TIME'),
                                                ),
                                                DataColumn(
                                                  label: Text('CASHIER'),
                                                ),
                                                DataColumn(
                                                  label: Text('CUSTOMER'),
                                                ),
                                                DataColumn(
                                                  label: Text('ITEMS'),
                                                ),
                                                DataColumn(
                                                  label: Text('TOTAL'),
                                                ),
                                                DataColumn(
                                                  label: Text('PAYMENT'),
                                                ),
                                                DataColumn(
                                                  label: Text('ACTIONS'),
                                                ),
                                              ],
                                              rows: filtered.map((sale) {
                                                return DataRow(
                                                  onSelectChanged: (_) => _showOrderActionsModal(sale),
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        _formatDisplayInvoiceNumber(sale),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      onTap: () => _showOrderActionsModal(sale),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '${sale.createdAt.month}/${sale.createdAt.day}/${sale.createdAt.year}, ${sale.createdAt.hour.toString().padLeft(2, '0')}:${sale.createdAt.minute.toString().padLeft(2, '0')} ${sale.createdAt.hour >= 12 ? 'PM' : 'AM'}',
                                                        style: TextStyle(
                                                          color: colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                          fontSize: 12.5,
                                                        ),
                                                      ),
                                                      onTap: () => _showOrderActionsModal(sale),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        resolveCashierDisplayName(
                                                          sale,
                                                        ),
                                                        style: TextStyle(
                                                          color: colorScheme
                                                              .onSurface,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      onTap: () => _showOrderActionsModal(sale),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        sale
                                                                .customerName
                                                                .isEmpty
                                                            ? 'Walk-in'
                                                            : sale.customerName,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              sale
                                                                  .customerName
                                                                  .isEmpty
                                                              ? FontWeight
                                                                    .normal
                                                              : FontWeight.w500,
                                                          color:
                                                              sale
                                                                  .customerName
                                                                  .isEmpty
                                                              ? colorScheme
                                                                    .onSurface
                                                                    .withValues(
                                                                      alpha:
                                                                          0.5,
                                                                    )
                                                              : colorScheme
                                                                    .onSurface,
                                                        ),
                                                      ),
                                                      onTap: () => _showOrderActionsModal(sale),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '${_formatQty(sale.items.fold<double>(0, (sum, item) => sum + item.quantity))} Items',
                                                        style: TextStyle(
                                                          color: colorScheme
                                                              .onSurface,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      onTap: () => _showOrderActionsModal(sale),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _money(sale.total),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      onTap: () => _showOrderActionsModal(sale),
                                                    ),
                                                    DataCell(
                                                      Builder(
                                                        builder: (context) {
                                                          final isCodPending = sale.status == 'COD_PENDING';
                                                          final isOutForDelivery = sale.status == 'OUT_FOR_DELIVERY';
                                                          final isDeliveredToCustomer = sale.status == 'DELIVERED_TO_CUSTOMER';
                                                          final isReturned = sale.status == 'RETURNED';
                                                          final isPartiallyReturned = sale.status == 'PARTIALLY_RETURNED';
                                                          final isCancelled = sale.status == 'CANCELLED';

                                                          final Color badgeColor = isCodPending
                                                              ? Colors.orange
                                                              : isOutForDelivery
                                                                  ? Colors.purple
                                                                  : isDeliveredToCustomer
                                                                      ? Colors.deepOrange
                                                                      : isReturned
                                                                          ? const Color(0xFFEF4444)
                                                                          : isPartiallyReturned
                                                                              ? const Color(0xFFF59E0B)
                                                                              : isCancelled
                                                                                  ? const Color(0xFF6B7280)
                                                                                  : AppTheme.statusColor(
                                                                                      _saleHasServiceItems(sale)
                                                                                          ? 'PENDING'
                                                                                          : 'ACTIVE',
                                                                                    );

                                                          final String badgeText = isCodPending
                                                              ? 'cod  •  pending'
                                                              : isOutForDelivery
                                                                  ? 'out for delivery'
                                                                  : isDeliveredToCustomer
                                                                      ? 'delivered  •  cash with driver'
                                                                      : isReturned
                                                                          ? 'returned'
                                                                          : isPartiallyReturned
                                                                              ? 'partially returned'
                                                                              : isCancelled
                                                                                  ? (sale.paymentMethod == 'COD'
                                                                                      ? 'cod  •  cancelled'
                                                                                      : 'cancelled')
                                                                                  : (_saleHasServiceItems(sale)
                                                                                      ? 'service  •  ' + sale.paymentMethod.toLowerCase()
                                                                                      : sale.paymentMethod.toLowerCase());

                                                          return Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: badgeColor.withValues(alpha: 0.12),
                                                              borderRadius: BorderRadius.circular(UiRadius.pill),
                                                              border: Border.all(
                                                                color: badgeColor.withValues(alpha: 0.25),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              badgeText,
                                                              style: TextStyle(
                                                                color: badgeColor,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w700,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Builder(
                                                        builder: (context) {
                                                          final isDarkTheme =
                                                              Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark;
                                                          return PopupMenuButton<
                                                            String
                                                          >(
                                                            tooltip:
                                                                'More Actions',
                                                            onSelected: (value) {
                                                              switch (value) {
                                                                case 'edit':
                                                                  _showDirectEditBillDialog(
                                                                    sale,
                                                                  );
                                                                  break;
                                                                case 'preview':
                                                                  _showSaleDetails(
                                                                    sale,
                                                                  );
                                                                  break;
                                                                case 'send':
                                                                  _showSendBillDialog(
                                                                    sale,
                                                                  );
                                                                  break;
                                                                case 'share':
                                                                  _showShareDialog(
                                                                    sale,
                                                                  );
                                                                  break;
                                                                case 'print':
                                                                  if (!_allowReprintSalesBill && !_isOwner && !_isAdmin) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      const SnackBar(
                                                                        content: Text('Re-printing sales bills is disabled in settings. Only Admin/Owner can re-print.'),
                                                                        backgroundColor: Colors.orange,
                                                                      ),
                                                                    );
                                                                    break;
                                                                  }
                                                                  printSaleBill(
                                                                    sale,
                                                                  );
                                                                  break;
                                                                case 'mark_received':
                                                                  _markSaleAsReceived(
                                                                    sale,
                                                                  );
                                                                  break;
                                                                case 'assign_delivery':
                                                                  _showAssignDeliveryDialog(sale);
                                                                  break;
                                                                case 'delivered_to_customer':
                                                                  _showMarkDeliveredDialog(sale);
                                                                  break;
                                                                case 'complete_cod':
                                                                  _showCompleteCodDeliveryDialog(
                                                                    sale,
                                                                  );
                                                                  break;
                                                                case 'delivery_note':
                                                                  _printDeliveryNote(
                                                                    sale,
                                                                  );
                                                                  break;
                                                                case 'duplicate':
                                                                  _loadSaleIntoPOS(
                                                                    sale,
                                                                    isEdit:
                                                                        false,
                                                                  );
                                                                  break;
                                                                case 'sales_return':
                                                                  _makeSalesReturnForSale(
                                                                    sale,
                                                                  );
                                                                  break;
                                                                case 'cancel':
                                                                  _cancelSaleInvoice(
                                                                    sale,
                                                                  );
                                                                  break;
                                                              }
                                                            },
                                                            itemBuilder: (context) => [
                                                              PopupMenuItem<
                                                                String
                                                              >(
                                                                value: 'edit',
                                                                enabled:
                                                                    _canEditBill,
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .edit_note_outlined,
                                                                      size: 20,
                                                                      color:
                                                                          _canEditBill
                                                                          ? Colors.blue
                                                                          : Colors.grey,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    const Text(
                                                                      'Edit Bill',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              PopupMenuItem<
                                                                String
                                                              >(
                                                                value:
                                                                    'duplicate',
                                                                enabled:
                                                                    _canCreateDuplicate,
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .copy_all_outlined,
                                                                      size: 20,
                                                                      color:
                                                                          _canCreateDuplicate
                                                                          ? Colors.cyan
                                                                          : Colors.grey,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    const Text(
                                                                      'Create Duplicate',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const PopupMenuDivider(),
                                                              const PopupMenuItem<
                                                                String
                                                              >(
                                                                value:
                                                                    'preview',
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .visibility_outlined,
                                                                      size: 20,
                                                                      color: Colors
                                                                          .indigo,
                                                                    ),
                                                                    SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Text(
                                                                      'Preview Bill',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              PopupMenuItem<
                                                                String
                                                              >(
                                                                value: 'print',
                                                                enabled: _allowReprintSalesBill || _isOwner || _isAdmin,
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .print_outlined,
                                                                      size: 20,
                                                                      color: (_allowReprintSalesBill || _isOwner || _isAdmin)
                                                                          ? Colors.teal
                                                                          : Colors.grey,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Text(
                                                                      'Print',
                                                                      style: TextStyle(
                                                                        color: (_allowReprintSalesBill || _isOwner || _isAdmin)
                                                                            ? null
                                                                            : Colors.grey,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const PopupMenuItem<
                                                                String
                                                              >(
                                                                value:
                                                                    'delivery_note',
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .local_shipping_outlined,
                                                                      size: 20,
                                                                      color: Colors
                                                                          .orange,
                                                                    ),
                                                                    SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Text(
                                                                      'Make Delivery Note',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              if (sale.paymentMethod == 'COD') ...[
                                                                if (sale.status == 'COD_PENDING' || (sale.deliveryPersonId ?? '').isEmpty)
                                                                  const PopupMenuItem<String>(
                                                                    value: 'assign_delivery',
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(Icons.person_add_alt_1_outlined, size: 20, color: Colors.blue),
                                                                        SizedBox(width: 8),
                                                                        Text('Assign Delivery Driver'),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                if (sale.status == 'OUT_FOR_DELIVERY')
                                                                  const PopupMenuItem<String>(
                                                                    value: 'delivered_to_customer',
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.deepOrange),
                                                                        SizedBox(width: 8),
                                                                        Text('Mark Delivered to Customer'),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                if (sale.status == 'DELIVERED_TO_CUSTOMER' || sale.status == 'COD_PENDING' || sale.status == 'OUT_FOR_DELIVERY')
                                                                  const PopupMenuItem<String>(
                                                                    value: 'complete_cod',
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(Icons.price_check_outlined, size: 20, color: Colors.green),
                                                                        SizedBox(width: 8),
                                                                        Text('Receive Cash from Driver & Settle'),
                                                                      ],
                                                                    ),
                                                                  ),
                                                              ],
                                                              const PopupMenuDivider(),
                                                              const PopupMenuItem<
                                                                String
                                                              >(
                                                                value: 'send',
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .send_outlined,
                                                                      size: 20,
                                                                      color: Colors
                                                                          .deepOrange,
                                                                    ),
                                                                    SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Text(
                                                                      'Send',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const PopupMenuItem<
                                                                String
                                                              >(
                                                                value: 'share',
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .share_outlined,
                                                                      size: 20,
                                                                      color: Colors
                                                                          .purple,
                                                                    ),
                                                                    SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Text(
                                                                      'Share',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const PopupMenuDivider(),
                                                              if (sale.paymentMethod != 'COD')
                                                              PopupMenuItem<
                                                                String
                                                              >(
                                                                value:
                                                                    'mark_received',
                                                                enabled:
                                                                    sale.status !=
                                                                        'COMPLETED' &&
                                                                    sale.status !=
                                                                        'CANCELLED',
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .check_circle_outline,
                                                                      size: 20,
                                                                      color:
                                                                          (sale.status !=
                                                                                  'COMPLETED' &&
                                                                              sale.status !=
                                                                                  'CANCELLED')
                                                                          ? Colors.green
                                                                          : Colors.grey,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    const Text(
                                                                      'Mark as Received',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              PopupMenuItem<
                                                                String
                                                              >(
                                                                value:
                                                                    'sales_return',
                                                                enabled:
                                                                    sale.status !=
                                                                    'CANCELLED',
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .settings_backup_restore_outlined,
                                                                      size: 20,
                                                                      color:
                                                                          sale.status !=
                                                                              'CANCELLED'
                                                                          ? Colors.blueGrey
                                                                          : Colors.grey,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    const Text(
                                                                      'Make Sales Return',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const PopupMenuDivider(),
                                                              PopupMenuItem<
                                                                String
                                                              >(
                                                                value: 'cancel',
                                                                enabled:
                                                                    _canCancelInvoice &&
                                                                    sale.status !=
                                                                        'CANCELLED',
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .cancel_outlined,
                                                                      size: 20,
                                                                      color:
                                                                          (_canCancelInvoice &&
                                                                              sale.status !=
                                                                                  'CANCELLED')
                                                                          ? Colors.red
                                                                          : Colors.grey,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Text(
                                                                      'Cancel Invoice',
                                                                      style: TextStyle(
                                                                        color:
                                                                            (_canCancelInvoice &&
                                                                                sale.status !=
                                                                                    'CANCELLED')
                                                                            ? Colors.red
                                                                            : Colors.grey,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                            child: Container(
                                                              width: 32,
                                                              height: 32,
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    isDarkTheme
                                                                    ? const Color(
                                                                        0xFF1F2937,
                                                                      )
                                                                    : const Color(
                                                                        0xFFF1F5F9,
                                                                      ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .more_vert_rounded,
                                                                size: 18,
                                                                color:
                                                                    isDarkTheme
                                                                    ? const Color(
                                                                        0xFFE5E7EB,
                                                                      )
                                                                    : const Color(
                                                                        0xFF374151,
                                                                      ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _salesSummaryCard(
    String title,
    String value, {
    String subtitle = '',
    IconData icon = Icons.receipt_long_rounded,
    Gradient accent = UiGradients.brand,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 178,
      height: 118,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(UiRadius.lg),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
          ),
          boxShadow: UiShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UiRadius.lg),
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -18,
                child: Opacity(
                  opacity: isDark ? 0.14 : 0.08,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: accent,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: accent,
                            borderRadius: BorderRadius.circular(UiRadius.xs),
                          ),
                          child: Icon(icon, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 28,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 16,
                      child: subtitle.isEmpty
                          ? const SizedBox.shrink()
                          : Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.45,
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
  }

  Widget _salesFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String Function(String)? labelMapper,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFFAFAFF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(UiRadius.md),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(UiRadius.md),
            borderSide: BorderSide(color: AppTheme.brandIndigo, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(UiRadius.md),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
            ),
          ),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: isDark ? const Color(0xFF111827) : Colors.white,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  labelMapper == null ? item : labelMapper(item),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
      ),
    );
  }

  void _loadSaleIntoPOS(_SaleRecord sale, {required bool isEdit}) {
    setState(() {
      _cart.clear();
      _posLineDiscounts.clear();
      _posLinePrices.clear();
      _selectedCustomerId = sale.customerId.isEmpty ? null : sale.customerId;

      for (final item in sale.items) {
        _cart[item.productId] = item.quantity;
        if (item.discount > 0) {
          _posLineDiscounts[item.productId] = _DiscountData(
            value: item.discount,
            type: item.discountType,
            label: '',
          );
        }
      }

      _posShippingCharges = sale.shippingCharges;
      _posAgentName = sale.agentName;
      _posAgentId = '';
      for (final user in _users) {
        if (user.name == sale.agentName) {
          _posAgentId = user.id;
          break;
        }
      }
      _posAgentCommission = sale.agentCommission;
      _posAgentCommissionType = sale.agentCommissionType;
      _posAgentCommissionPaid = sale.agentCommissionPaid;
      _posInvoiceDiscountValue = sale.discount;
      _posInvoiceDiscountType = 'FIXED';

      if (isEdit) {
        _editingSaleId = sale.id;
      } else {
        _editingSaleId = null;
      }

      _selectedNavKey = 'pos';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit
              ? 'Invoice ${sale.id} loaded for editing.'
              : 'Invoice duplicated. Ready to checkout as a new sale.',
        ),
      ),
    );
  }

  void _showSendBillDialog(_SaleRecord sale) {
    final emailCtrl = TextEditingController(
      text: sale.customerPhone.contains('@') ? sale.customerPhone : '',
    );
    final phoneCtrl = TextEditingController(
      text: !sale.customerPhone.contains('@') ? sale.customerPhone : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Invoice Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice #: ${sale.id}'),
            Text('Customer: ${sale.customerName}'),
            Text('Total: ${_money(sale.total)}'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'customer@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                hintText: '+94771234567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invoice details sent to ${emailCtrl.text.isNotEmpty ? emailCtrl.text : phoneCtrl.text}',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _showShareDialog(_SaleRecord sale) async {
    final settings = await _currentPrintSettings();
    final domainSale = _toDomainSale(
      sale,
      sale.items.map((item) {
        final discountType = item.discountType.toUpperCase();
        final discountValue = item.discount;
        final originalPrice = discountType == 'PERCENT'
            ? (discountValue >= 100
                  ? item.unitPrice
                  : item.unitPrice / (1 - (discountValue / 100)))
            : item.unitPrice + discountValue;
        return _CartLine(
          product: _ProductItem(
            id: item.productId,
            name: item.productName,
            category: 'Item',
            price: originalPrice,
            stock: 0,
            minStock: 0,
          ),
          qty: item.quantity,
          discountValue: discountValue,
          discountType: discountType,
          discountLabel: '',
        );
      }).toList(),
    );

    final invoiceText =
        'Invoice *${_formatDisplayInvoiceNumber(sale)}*\n'
        'Date: ${sale.createdAt.year}-${sale.createdAt.month.toString().padLeft(2, '0')}-${sale.createdAt.day.toString().padLeft(2, '0')}\n'
        'Customer: ${sale.customerName}\n'
        '---------------------------\n'
        '${sale.items.map((item) => '${item.productName} x ${item.quantity.toInt()} = ${_money(item.lineTotal)}').join('\n')}\n'
        '---------------------------\n'
        'Subtotal: ${_money(sale.subtotal)}\n'
        'Tax: ${_money(sale.tax)}\n'
        'Discount: ${_money(sale.discount)}\n'
        'Total: *${_money(sale.total)}*\n'
        'Paid: ${_money(sale.amountPaid)}\n'
        'Balance: ${_money(sale.balance)}\n'
        'Thank you for shopping with us!';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.green),
              title: const Text('Share to WhatsApp (PDF)'),
              subtitle: const Text(
                'Copies PDF to clipboard and opens WhatsApp',
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pdfBytes = await PrintService.generateReceiptPdf(
                    sale: domainSale,
                    settings: settings,
                    currencySymbol: _currency == 'LKR'
                        ? 'Rs.'
                        : _currency == 'USD'
                        ? '\$'
                        : _currency,
                    storeName: _companyName,
                    storeAddress: _companyAddress.trim().isEmpty
                        ? _storeLocation
                        : _companyAddress,
                    storePhone: _companyPhone,
                  );
                  final tempDir = Directory.systemTemp;
                  final tempFile = File(
                    '${tempDir.path}/Invoice_${sale.id}.pdf',
                  );
                  await tempFile.writeAsBytes(pdfBytes);

                  final escapedPath = tempFile.path.replaceAll("'", "''");
                  await Process.run('powershell.exe', [
                    '-Command',
                    'Set-Clipboard -Path \'$escapedPath\'',
                  ]);

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Invoice PDF copied to clipboard! Paste (Ctrl+V) directly into WhatsApp.',
                      ),
                    ),
                  );

                  await Process.run('cmd.exe', [
                    '/c',
                    'start',
                    '',
                    'https://api.whatsapp.com/send',
                  ]);
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Failed to share PDF: $e')),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
                color: Colors.red,
              ),
              title: const Text('Save as PDF'),
              subtitle: const Text('Export receipt as a PDF file offline'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final outputPath = await FilePicker.platform.saveFile(
                    dialogTitle: 'Save Invoice PDF',
                    fileName: 'Invoice_${sale.id}.pdf',
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (outputPath != null) {
                    final pdfDoc = pw.Document();
                    pw.ThemeData? theme;
                    try {
                      final ttfData = await rootBundle.load(
                        'assets/fonts/NotoSans-Regular.ttf',
                      );
                      theme = pw.ThemeData.withFont(base: pw.Font.ttf(ttfData));
                    } catch (_) {}

                    final isA4Printer =
                        settings.printerType.trim().toUpperCase() == 'A4';
                    if (isA4Printer) {
                      pdfDoc.addPage(
                        pw.MultiPage(
                          pageFormat: PdfPageFormat.a4,
                          margin: pw.EdgeInsets.all(settings.marginTop),
                          theme: theme,
                          build: (ctx) => PrintService.buildA4Invoice(
                            sale: domainSale,
                            settings: settings,
                            currencySymbol: _currency == 'LKR'
                                ? 'Rs.'
                                : _currency == 'USD'
                                ? '\$'
                                : _currency,
                            storeName: _companyName,
                            storeAddress: _companyAddress.trim().isEmpty
                                ? _storeLocation
                                : _companyAddress,
                            storePhone: _companyPhone,
                          ),
                        ),
                      );
                    } else {
                      pdfDoc.addPage(
                        pw.Page(
                          pageFormat: PrintService.getThermalPaperFormat(
                            settings.paperSize,
                          ),
                          margin: pw.EdgeInsets.only(
                            top: settings.marginTop,
                            left: settings.marginLeft,
                            right: settings.marginLeft,
                            bottom: 10,
                          ),
                          theme: theme,
                          build: (ctx) => PrintService.buildThermalReceipt(
                            sale: domainSale,
                            settings: settings,
                            currencySymbol: _currency == 'LKR'
                                ? 'Rs.'
                                : _currency == 'USD'
                                ? '\$'
                                : _currency,
                            storeName: _companyName,
                            storeAddress: _companyAddress.trim().isEmpty
                                ? _storeLocation
                                : _companyAddress,
                            storePhone: _companyPhone,
                          ),
                        ),
                      );
                    }
                    final pdfBytes = await pdfDoc.save();
                    await File(outputPath).writeAsBytes(pdfBytes);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Saved PDF successfully to $outputPath'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Error saving PDF: $e')),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Colors.blue),
              title: const Text('Save as Image'),
              subtitle: const Text('Rasterize and save receipt as PNG'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pdfDoc = pw.Document();
                  pw.ThemeData? theme;
                  try {
                    final ttfData = await rootBundle.load(
                      'assets/fonts/NotoSans-Regular.ttf',
                    );
                    theme = pw.ThemeData.withFont(base: pw.Font.ttf(ttfData));
                  } catch (_) {}

                  final isA4Printer =
                      settings.printerType.trim().toUpperCase() == 'A4';
                  if (isA4Printer) {
                    pdfDoc.addPage(
                      pw.MultiPage(
                        pageFormat: PdfPageFormat.a4,
                        margin: pw.EdgeInsets.all(settings.marginTop),
                        theme: theme,
                        build: (ctx) => PrintService.buildA4Invoice(
                          sale: domainSale,
                          settings: settings,
                          currencySymbol: _currency == 'LKR'
                              ? 'Rs.'
                              : _currency == 'USD'
                              ? '\$'
                              : _currency,
                          storeName: _companyName,
                          storeAddress: _companyAddress.trim().isEmpty
                              ? _storeLocation
                              : _companyAddress,
                          storePhone: _companyPhone,
                        ),
                      ),
                    );
                  } else {
                    pdfDoc.addPage(
                      pw.Page(
                        pageFormat: PrintService.getThermalPaperFormat(
                          settings.paperSize,
                        ),
                        margin: pw.EdgeInsets.only(
                          top: settings.marginTop,
                          left: settings.marginLeft,
                          right: settings.marginLeft,
                          bottom: 10,
                        ),
                        theme: theme,
                        build: (ctx) => PrintService.buildThermalReceipt(
                          sale: domainSale,
                          settings: settings,
                          currencySymbol: _currency == 'LKR'
                              ? 'Rs.'
                              : _currency == 'USD'
                              ? '\$'
                              : _currency,
                          storeName: _companyName,
                          storeAddress: _companyAddress.trim().isEmpty
                              ? _storeLocation
                              : _companyAddress,
                          storePhone: _companyPhone,
                        ),
                      ),
                    );
                  }
                  final pdfBytes = await pdfDoc.save();

                  await for (final page in Printing.raster(
                    pdfBytes,
                    pages: [0],
                    dpi: 250,
                  )) {
                    final pngBytes = await page.toPng();
                    final outputPath = await FilePicker.platform.saveFile(
                      dialogTitle: 'Save Invoice Image',
                      fileName: 'Invoice_${sale.id}.png',
                      type: FileType.custom,
                      allowedExtensions: ['png'],
                    );
                    if (outputPath != null) {
                      await File(outputPath).writeAsBytes(pngBytes);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Saved image successfully to $outputPath',
                          ),
                        ),
                      );
                    }
                    break;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Error saving image: $e')),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.purple),
              title: const Text('System Share Sheet'),
              subtitle: const Text('Share PDF via native OS share card'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final pdfDoc = pw.Document();
                  pw.ThemeData? theme;
                  try {
                    final ttfData = await rootBundle.load(
                      'assets/fonts/NotoSans-Regular.ttf',
                    );
                    theme = pw.ThemeData.withFont(base: pw.Font.ttf(ttfData));
                  } catch (_) {}

                  final isA4Printer =
                      settings.printerType.trim().toUpperCase() == 'A4';
                  if (isA4Printer) {
                    pdfDoc.addPage(
                      pw.MultiPage(
                        pageFormat: PdfPageFormat.a4,
                        margin: pw.EdgeInsets.all(settings.marginTop),
                        theme: theme,
                        build: (ctx) => PrintService.buildA4Invoice(
                          sale: domainSale,
                          settings: settings,
                          currencySymbol: _currency == 'LKR'
                              ? 'Rs.'
                              : _currency == 'USD'
                              ? '\$'
                              : _currency,
                          storeName: _companyName,
                          storeAddress: _companyAddress.trim().isEmpty
                              ? _storeLocation
                              : _companyAddress,
                          storePhone: _companyPhone,
                        ),
                      ),
                    );
                  } else {
                    pdfDoc.addPage(
                      pw.Page(
                        pageFormat: PrintService.getThermalPaperFormat(
                          settings.paperSize,
                        ),
                        margin: pw.EdgeInsets.only(
                          top: settings.marginTop,
                          left: settings.marginLeft,
                          right: settings.marginLeft,
                          bottom: 10,
                        ),
                        theme: theme,
                        build: (ctx) => PrintService.buildThermalReceipt(
                          sale: domainSale,
                          settings: settings,
                          currencySymbol: _currency == 'LKR'
                              ? 'Rs.'
                              : _currency == 'USD'
                              ? '\$'
                              : _currency,
                          storeName: _companyName,
                          storeAddress: _companyAddress.trim().isEmpty
                              ? _storeLocation
                              : _companyAddress,
                          storePhone: _companyPhone,
                        ),
                      ),
                    );
                  }
                  final pdfBytes = await pdfDoc.save();
                  await Printing.sharePdf(
                    bytes: pdfBytes,
                    filename: 'Invoice_${sale.id}.pdf',
                  );
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Error sharing invoice: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeSalesReturnForSale(_SaleRecord sale) async {
    final created = await _showReturnDialog(preloadedSale: sale);
    if (created == null || created.isEmpty) return;
    setState(() {
      for (final item in created.reversed) {
        _returns.insert(0, item);
      }
    });
    final saleId = created.first.saleId;
    if (saleId.isNotEmpty) {
      final saleIdx = _sales.indexWhere((s) => s.id == saleId);
      if (saleIdx >= 0) {
        final targetSale = _sales[saleIdx];
        final totalSold = targetSale.items.fold<double>(0, (sum, it) => sum + it.quantity);
        final totalReturned = targetSale.items.fold<double>(
          0,
          (sum, it) => sum + _returnedQtyForSaleItem(saleId, it.productId),
        );
        final isUnpaidCod = targetSale.status == 'COD_PENDING' ||
            (targetSale.paymentMethod == 'COD' && targetSale.amountPaid <= 0);
        if (totalReturned >= totalSold && totalSold > 0) {
          targetSale.status = isUnpaidCod ? 'CANCELLED' : 'RETURNED';
        } else if (totalReturned > 0) {
          targetSale.status = 'PARTIALLY_RETURNED';
        }
        if (created.first.reason.isNotEmpty) {
          targetSale.returnReason = created.first.reason;
        }
        if (_saleRepository != null) {
          await _saleRepository!.updateSaleStatus(
            saleId: targetSale.id,
            status: targetSale.status,
          );
        }
        await _enqueueSync('UPDATE', 'sales', targetSale.id);
      }
    }

    await _persistWorkspaceData();
    for (final item in created) {
      await _enqueueSync('INSERT', 'returns', item.id);
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

  Future<void> _markSaleAsReceived(_SaleRecord sale) async {
    if (sale.status == 'COMPLETED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This invoice is already completed/received.'),
        ),
      );
      return;
    }

    setState(() {
      sale.status = 'COMPLETED';
    });

    if (_saleRepository != null) {
      await _saleRepository!.updateSaleStatus(
        saleId: sale.id,
        status: 'COMPLETED',
      );
    } else {
      await _enqueueSync('UPDATE', 'sales', sale.id);
    }

    await _persistWorkspaceData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice ${sale.id} marked as received/completed.'),
        ),
      );
    }
  }

  void _showDirectEditBillDialog(_SaleRecord sale) async {
    final settings = await _currentPrintSettings();
    final currencySymbol = _currency == 'LKR'
        ? 'Rs.'
        : _currency == 'USD'
        ? '\$'
        : _currency;
    final storeAddress = _companyAddress.trim().isEmpty
        ? _storeLocation
        : _companyAddress;

    // Convert sale items to editable items
    final List<_EditableSaleItem> tempItems = sale.items.map((item) {
      final discountType = item.discountType.toUpperCase();
      final discountValue = item.discount;
      final originalPrice = discountType == 'PERCENT'
          ? (discountValue >= 100
                ? item.unitPrice
                : item.unitPrice / (1 - (discountValue / 100)))
          : item.unitPrice + discountValue;

      return _EditableSaleItem(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity.toDouble(),
        unitPrice: item.unitPrice,
        originalPrice: originalPrice,
        discount: discountValue,
        discountType: discountType,
        total: item.lineTotal,
      );
    }).toList();

    String? selectedCustomerId = sale.customerId.isEmpty
        ? null
        : sale.customerId;
    if (selectedCustomerId != null &&
        !_customers.any((c) => c.id == selectedCustomerId)) {
      selectedCustomerId = null;
    }
    String paymentMethod = sale.paymentMethod;
    double discountValue = sale.discount;
    String discountType = 'FIXED'; // default to fixed or try to guess from sale
    double shippingCharges = sale.shippingCharges;
    double amountPaid = sale.amountPaid ?? sale.total;

    final discountCtrl = TextEditingController(
      text: discountValue.toStringAsFixed(2),
    );
    final shippingCtrl = TextEditingController(
      text: shippingCharges.toStringAsFixed(2),
    );
    final amountPaidCtrl = TextEditingController(
      text: amountPaid.toStringAsFixed(2),
    );

    // Keep track of controllers for item fields to avoid rebuild focus loss
    final Map<String, TextEditingController> qtyControllers = {};
    final Map<String, TextEditingController> priceControllers = {};

    int pdfVersion = 0;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Re-calculate subtotal
            double subtotal = 0.0;
            for (final item in tempItems) {
              subtotal += item.quantity * item.unitPrice;
            }

            // Re-calculate tax
            final taxRate = double.tryParse(_taxRate) ?? 0.0;
            final taxAmount = _posApplyTax ? subtotal * (taxRate / 100) : 0.0;

            // Re-calculate discount
            final discountAmount = discountType == 'PERCENT'
                ? subtotal * (discountValue / 100)
                : discountValue;

            // Re-calculate grand total
            final grandTotal =
                (subtotal + taxAmount + shippingCharges - discountAmount).clamp(
                  0.0,
                  double.infinity,
                );

            // If non-credit, force amountPaid to grandTotal
            final bool isCreditOrInstallment =
                paymentMethod == 'CREDIT' || paymentMethod == 'INSTALLMENT';
            if (!isCreditOrInstallment) {
              amountPaid = grandTotal;
              amountPaidCtrl.text = amountPaid.toStringAsFixed(2);
            }
            final balance = (grandTotal - amountPaid).clamp(
              0.0,
              double.infinity,
            );

            // Rebuild domain sale for real-time PDF generation
            final currentDomainSale = domain.Sale(
              id: sale.id,
              tenantId: _activeTenantId ?? 'local',
              customerId: selectedCustomerId,
              employeeId: sale.employeeId.isEmpty
                  ? _currentUserId
                  : sale.employeeId,
              total: grandTotal,
              tax: taxAmount,
              discount: discountAmount,
              paymentMethod: paymentMethod,
              status: sale.status,
              locationId: sale.locationId,
              synced: false,
              createdAt: sale.createdAt,
              updatedAt: DateTime.now(),
              shippingCharges: shippingCharges,
              amountPaid: amountPaid,
              balance: balance,
              cashierName: sale.cashierName,
              customerOutstandingBefore: sale.customerOutstandingBefore,
              customerOutstandingAfter: sale.customerOutstandingAfter,
              agentName: sale.agentName,
              agentCommission: sale.agentCommission,
              agentCommissionType: sale.agentCommissionType,
              agentCommissionPaid: sale.agentCommissionPaid,
              items: tempItems.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                return domain.SaleItem(
                  id: '${sale.id}-$idx',
                  saleId: sale.id,
                  productId: item.productId,
                  productName: item.productName,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  originalPrice: item.originalPrice,
                  discount: item.discount,
                  discountType: item.discountType,
                  total: item.total,
                  tenantId: _activeTenantId ?? 'local',
                );
              }).toList(),
              customer: selectedCustomerId != null
                  ? () {
                      final custs = _customers.where(
                        (c) => c.id == selectedCustomerId,
                      );
                      if (custs.isNotEmpty) {
                        return _toDomainCustomer(custs.first);
                      }
                      return null;
                    }()
                  : null,
            );

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.95,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Dialog Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note_outlined,
                              size: 28,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Edit Bill #${sale.id}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Split screen body
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Column: Edit Form
                          Expanded(
                            flex: 11,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Section: General Settings
                                  Card(
                                    elevation: 0,
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.03),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).dividerColor.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Invoice Settings',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<String?>(
                                                  value: selectedCustomerId,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Customer',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                  items: [
                                                    const DropdownMenuItem<
                                                      String?
                                                    >(
                                                      value: null,
                                                      child: Text(
                                                        'Walk-in Customer',
                                                      ),
                                                    ),
                                                    ..._customers.map(
                                                      (c) =>
                                                          DropdownMenuItem<
                                                            String?
                                                          >(
                                                            value: c.id,
                                                            child: Text(c.name),
                                                          ),
                                                    ),
                                                  ],
                                                  onChanged: (val) {
                                                    setState(() {
                                                      selectedCustomerId = val;
                                                      pdfVersion++;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  value: paymentMethod,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Payment Method',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 'CASH',
                                                      child: Text('Cash'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'CARD',
                                                      child: Text('Card'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'CHEQUE',
                                                      child: Text('Cheque'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'CREDIT',
                                                      child: Text('Credit'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'INSTALLMENT',
                                                      child: Text(
                                                        'Installment',
                                                      ),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'COD',
                                                      child: Text('COD'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'SPLIT',
                                                      child: Text('Split'),
                                                    ),
                                                  ],
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      setState(() {
                                                        paymentMethod = val;
                                                        pdfVersion++;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            discountCtrl,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration: const InputDecoration(
                                                          labelText: 'Discount',
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                        ),
                                                        onChanged: (val) {
                                                          setState(() {
                                                            discountValue =
                                                                double.tryParse(
                                                                  val,
                                                                ) ??
                                                                0.0;
                                                            pdfVersion++;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: Theme.of(
                                                            context,
                                                          ).dividerColor,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child:
                                                          DropdownButton<
                                                            String
                                                          >(
                                                            value: discountType,
                                                            underline:
                                                                const SizedBox(),
                                                            items: const [
                                                              DropdownMenuItem(
                                                                value: 'FIXED',
                                                                child: Text(
                                                                  'LKR',
                                                                ),
                                                              ),
                                                              DropdownMenuItem(
                                                                value:
                                                                    'PERCENT',
                                                                child: Text(
                                                                  '%',
                                                                ),
                                                              ),
                                                            ],
                                                            onChanged: (val) {
                                                              if (val != null) {
                                                                setState(() {
                                                                  discountType =
                                                                      val;
                                                                  pdfVersion++;
                                                                });
                                                              }
                                                            },
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextField(
                                                  controller: shippingCtrl,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Shipping Charges',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      shippingCharges =
                                                          double.tryParse(
                                                            val,
                                                          ) ??
                                                          0.0;
                                                      pdfVersion++;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (isCreditOrInstallment) ...[
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: amountPaidCtrl,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Amount Paid',
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        amountPaid =
                                                            double.tryParse(
                                                              val,
                                                            ) ??
                                                            0.0;
                                                        pdfVersion++;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: InputDecorator(
                                                    decoration: const InputDecoration(
                                                      labelText:
                                                          'Balance / Outstanding',
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '$currencySymbol ${balance.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Section: Add Product Autocomplete
                                  Autocomplete<_ProductItem>(
                                    displayStringForOption: (option) =>
                                        '${option.name} (${option.barcode}) - Rs. ${option.price.toStringAsFixed(2)}',
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                          if (textEditingValue.text.isEmpty) {
                                            return const Iterable<
                                              _ProductItem
                                            >.empty();
                                          }
                                          return _products.where((product) {
                                            final nameMatches = product.name
                                                .toLowerCase()
                                                .contains(
                                                  textEditingValue.text
                                                      .toLowerCase(),
                                                );
                                            final barcodeMatches = product
                                                .barcode
                                                .toLowerCase()
                                                .contains(
                                                  textEditingValue.text
                                                      .toLowerCase(),
                                                );
                                            return nameMatches ||
                                                barcodeMatches;
                                          });
                                        },
                                    onSelected: (_ProductItem selection) {
                                      setState(() {
                                        final existingIndex = tempItems
                                            .indexWhere(
                                              (item) =>
                                                  item.productId ==
                                                  selection.id,
                                            );
                                        if (existingIndex >= 0) {
                                          tempItems[existingIndex].quantity +=
                                              1.0;
                                          tempItems[existingIndex].total =
                                              tempItems[existingIndex]
                                                  .quantity *
                                              tempItems[existingIndex]
                                                  .unitPrice;
                                          final qtyCtrl =
                                              qtyControllers[selection.id];
                                          if (qtyCtrl != null) {
                                            qtyCtrl.text =
                                                tempItems[existingIndex]
                                                    .quantity
                                                    .toString();
                                          }
                                        } else {
                                          tempItems.add(
                                            _EditableSaleItem(
                                              productId: selection.id,
                                              productName: selection.name,
                                              quantity: 1.0,
                                              unitPrice: selection.price,
                                              originalPrice: selection.price,
                                              discount: 0.0,
                                              discountType: 'FIXED',
                                              total: selection.price,
                                            ),
                                          );
                                        }
                                        pdfVersion++;
                                      });
                                    },
                                    fieldViewBuilder:
                                        (
                                          context,
                                          controller,
                                          focusNode,
                                          onFieldSubmitted,
                                        ) {
                                          return TextField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            decoration: InputDecoration(
                                              labelText:
                                                  'Search product to add...',
                                              prefixIcon: const Icon(
                                                Icons.search,
                                              ),
                                              suffixIcon:
                                                  controller.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                        Icons.clear,
                                                      ),
                                                      onPressed: () {
                                                        controller.clear();
                                                        setState(() {});
                                                      },
                                                    )
                                                  : null,
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                          );
                                        },
                                  ),
                                  const SizedBox(height: 16),

                                  // Section: Editable Items Table
                                  const Text(
                                    'Invoice Items',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (tempItems.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No items in this invoice. Add products above.',
                                        ),
                                      ),
                                    )
                                  else
                                    ...tempItems.map((item) {
                                      final qtyCtrl = qtyControllers
                                          .putIfAbsent(
                                            item.productId,
                                            () => TextEditingController(
                                              text: item.quantity.toString(),
                                            ),
                                          );
                                      final priceCtrl = priceControllers
                                          .putIfAbsent(
                                            item.productId,
                                            () => TextEditingController(
                                              text: item.unitPrice
                                                  .toStringAsFixed(2),
                                            ),
                                          );

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).dividerColor.withOpacity(0.02),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).dividerColor.withOpacity(0.1),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.productName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Total: $currencySymbol ${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller: priceCtrl,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Price',
                                                      prefixText: 'Rs.',
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 6,
                                                          ),
                                                    ),
                                                onChanged: (val) {
                                                  final double? parsed =
                                                      double.tryParse(val);
                                                  if (parsed != null) {
                                                    setState(() {
                                                      item.unitPrice = parsed;
                                                      item.total =
                                                          item.quantity *
                                                          parsed;
                                                      pdfVersion++;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller: qtyCtrl,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Qty',
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 6,
                                                          ),
                                                    ),
                                                onChanged: (val) {
                                                  final double? parsed =
                                                      double.tryParse(val);
                                                  if (parsed != null) {
                                                    setState(() {
                                                      item.quantity = parsed;
                                                      item.total =
                                                          parsed *
                                                          item.unitPrice;
                                                      pdfVersion++;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  tempItems.removeWhere(
                                                    (i) =>
                                                        i.productId ==
                                                        item.productId,
                                                  );
                                                  qtyControllers.remove(
                                                    item.productId,
                                                  );
                                                  priceControllers.remove(
                                                    item.productId,
                                                  );
                                                  pdfVersion++;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          ),

                          // Vertical divider
                          VerticalDivider(
                            width: 24,
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.15),
                          ),

                          // Right Column: Live PDF Preview
                          Expanded(
                            flex: 9,
                            child: Card(
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withOpacity(0.15),
                                ),
                              ),
                              child: PdfPreview(
                                key: ValueKey(
                                  'pdf_preview_edit_${sale.id}_$pdfVersion',
                                ),
                                build: (format) =>
                                    PrintService.generateReceiptPdf(
                                      sale: currentDomainSale,
                                      settings: settings,
                                      currencySymbol: currencySymbol,
                                      storeName: _companyName,
                                      storeAddress: storeAddress,
                                      storePhone: _companyPhone,
                                    ),
                                useActions: false,
                                dynamicLayout: false,
                                loadingWidget: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 24),
                    // Action Buttons (Save/Cancel)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: tempItems.isEmpty
                              ? null
                              : () async {
                                  Navigator.pop(dialogContext);
                                  try {
                                    if (_saleRepository != null) {
                                      await _saleRepository!.updateSale(
                                        currentDomainSale,
                                      );
                                      await _loadCoreDataFromRepositories();
                                      setState(() {});
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Invoice updated successfully!',
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Sale repository is not available. Changes not saved.',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to update invoice: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save Changes'),
                        ),
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
  }
}

class _EditableSaleItem {
  final String productId;
  final String productName;
  double quantity;
  double unitPrice;
  double originalPrice;
  double discount;
  String discountType;
  double total;

  _EditableSaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.originalPrice,
    required this.discount,
    required this.discountType,
    required this.total,
  });
}

extension _sales_pageCodExt on _DashboardScreenState {
  void _showAssignDeliveryDialog(_SaleRecord sale) {
    final eligibleUsers = _users.where((u) => u.active).toList()
      ..sort((a, b) {
        if (a.role.toUpperCase() == 'DELIVERY' && b.role.toUpperCase() != 'DELIVERY') return -1;
        if (b.role.toUpperCase() == 'DELIVERY' && a.role.toUpperCase() != 'DELIVERY') return 1;
        return a.name.compareTo(b.name);
      });

    String? selectedUserId = sale.deliveryPersonId ?? (eligibleUsers.isNotEmpty ? eligibleUsers.first.id : null);
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.local_shipping_outlined, color: AppTheme.brandIndigo),
                  SizedBox(width: 10),
                  Text('Assign Delivery Person'),
                ],
              ),
              content: SizedBox(
                width: ResponsiveLayout.adaptiveDialogWidth(context, 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.brandIndigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, size: 20, color: AppTheme.brandIndigo),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Invoice: ' + sale.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Customer: ' + (sale.customerName.isEmpty ? "Walk-in" : sale.customerName)),
                                Text('Cash to Collect: ' + _money(sale.total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Delivery Person / Driver *', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    if (eligibleUsers.isEmpty)
                      const Text('No active users found. Please create a user with DELIVERY role in User Management.', style: TextStyle(color: Colors.redAccent, fontSize: 13))
                    else
                      DropdownButtonFormField<String>(
                        value: selectedUserId,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: eligibleUsers.map((u) {
                          final isDriver = u.role.toUpperCase() == 'DELIVERY';
                          return DropdownMenuItem<String>(
                            value: u.id,
                            child: Row(
                              children: [
                                Text(u.name),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDriver ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    u.role.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDriver ? Colors.green[800] : Colors.grey[800]),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setLocalState(() => selectedUserId = val),
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Note for Driver (Optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedUserId == null ? null : () async {
                    Navigator.pop(dialogCtx);
                    final driver = eligibleUsers.firstWhere((u) => u.id == selectedUserId);
                    setState(() {
                      sale.deliveryPersonId = driver.id;
                      sale.deliveryPersonName = driver.name;
                      sale.deliveryStatus = 'ASSIGNED';
                      sale.status = 'OUT_FOR_DELIVERY';
                      if (notesCtrl.text.trim().isNotEmpty) {
                        sale.notes = sale.notes.isEmpty ? "Driver Note: " + notesCtrl.text.trim() : sale.notes + " | Driver Note: " + notesCtrl.text.trim();
                      }
                      final idx = _sales.indexWhere((s) => s.id == sale.id);
                      if (idx >= 0) {
                        _sales[idx].deliveryPersonId = driver.id;
                        _sales[idx].deliveryPersonName = driver.name;
                        _sales[idx].deliveryStatus = 'ASSIGNED';
                        _sales[idx].status = 'OUT_FOR_DELIVERY';
                        _sales[idx].notes = sale.notes;
                      }
                    });

                    _addNotification(
                      title: 'Order Assigned for Delivery',
                      message: 'Invoice ' + sale.id + ' assigned to driver ' + driver.name + '. Cash to collect: ' + _money(sale.total),
                      type: 'delivery',
                      targetLocation: sale.locationId,
                      referenceId: sale.id,
                    );

                    await _persistWorkspaceData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order ' + sale.id + ' assigned to ' + driver.name + ' (Out for Delivery)')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandIndigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Dispatch Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMarkDeliveredDialog(_SaleRecord sale) {
    String? pickedPath;
    final notesController = TextEditingController();
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final outlineColor = Theme.of(context).colorScheme.outline;

            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.deepOrange),
                  SizedBox(width: 10),
                  Text('Mark Delivered to Customer'),
                ],
              ),
              content: SizedBox(
                width: ResponsiveLayout.adaptiveDialogWidth(context, 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Invoice: ' + sale.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Driver: ' + (sale.deliveryPersonName ?? "Assigned Driver"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Customer: ' + (sale.customerName.isEmpty ? "Walk-in" : sale.customerName)),
                          if (sale.shippingAddress.isNotEmpty)
                            Text('Address: ' + sale.shippingAddress, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('Cash Collected from Customer: ' + _money(sale.total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Safe Accounting Notice: This marks that the driver has delivered goods and holds cash. Cash will NOT be credited into the register until handed over to counter cashier.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sale.deliveryOtp != null && sale.deliveryOtp!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Customer Delivery OTP *',
                          hintText: 'Enter 4-digit code sent to customer WhatsApp',
                          prefixIcon: Icon(Icons.pin_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Text('Proof of Delivery Photo (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
                        if (result != null && result.files.isNotEmpty) {
                          setLocalState(() => pickedPath = result.files.single.path);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: pickedPath != null ? Colors.transparent : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
                          border: Border.all(color: outlineColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: pickedPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(pickedPath!), fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 30, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('Click to attach photo / signature', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Feedback / Remarks',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (sale.deliveryOtp != null && sale.deliveryOtp!.isNotEmpty) {
                      final enteredOtp = otpController.text.trim();
                      if (enteredOtp != sale.deliveryOtp && !_isOwner && !_isAdmin) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid Delivery OTP! Please ask the customer for the code sent to their WhatsApp.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                    }
                    Navigator.pop(dialogCtx);
                    String updatedNotes = sale.notes.trim();
                    if (pickedPath != null) {
                      final docDir = await getApplicationDocumentsDirectory();
                      final codReceiptsDir = Directory(docDir.path + '/cod_receipts');
                      if (!await codReceiptsDir.exists()) {
                        await codReceiptsDir.create(recursive: true);
                      }
                      final ext = pickedPath!.split('.').last;
                      final destFile = File(codReceiptsDir.path + '/pod_' + sale.id + '_' + DateTime.now().millisecondsSinceEpoch.toString() + '.' + ext);
                      await File(pickedPath!).copy(destFile.path);
                      updatedNotes = updatedNotes.isEmpty ? '[POD_PHOTO:' + destFile.path + ']' : updatedNotes + ' | [POD_PHOTO:' + destFile.path + ']';
                    }
                    final remark = notesController.text.trim();
                    if (remark.isNotEmpty) {
                      updatedNotes = updatedNotes.isEmpty ? 'Delivery: ' + remark : updatedNotes + ' | Delivery: ' + remark;
                    }

                    setState(() {
                      sale.status = 'DELIVERED_TO_CUSTOMER';
                      sale.deliveryStatus = 'DELIVERED';
                      sale.deliveredAt = DateTime.now();
                      sale.amountPaid = 0.0; // Driver holds money, counter register unaffected
                      sale.balance = sale.total;
                      sale.notes = updatedNotes;
                      final idx = _sales.indexWhere((s) => s.id == sale.id);
                      if (idx >= 0) {
                        _sales[idx].status = 'DELIVERED_TO_CUSTOMER';
                        _sales[idx].deliveryStatus = 'DELIVERED';
                        _sales[idx].deliveredAt = sale.deliveredAt;
                        _sales[idx].amountPaid = 0.0;
                        _sales[idx].balance = sale.total;
                        _sales[idx].notes = updatedNotes;
                      }
                    });

                    _addNotification(
                      title: 'Order Delivered to Customer',
                      message: 'Invoice ' + sale.id + ' delivered by ' + (sale.deliveryPersonName ?? "driver") + '. ' + _money(sale.total) + ' is with driver awaiting counter handover.',
                      type: 'delivery',
                      targetLocation: sale.locationId,
                      referenceId: sale.id,
                    );

                    await _persistWorkspaceData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order ' + sale.id + ' marked as Delivered to Customer (Cash with Driver)')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Delivered'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCompleteCodDeliveryDialog(_SaleRecord sale) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.price_check_outlined, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Counter Cash Settle & Complete'),
                ],
              ),
              content: SizedBox(
                width: ResponsiveLayout.adaptiveDialogWidth(context, 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Invoice: ' + _formatDisplayInvoiceNumber(sale), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Driver: ' + (sale.deliveryPersonName ?? "Counter / Driver"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Customer: ' + (sale.customerName.isEmpty ? "Walk-in" : sale.customerName)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cash Handover Amount:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(_money(sale.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Confirming will officially mark invoice COMPLETED, zero out balance, and credit cash into the register.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Counter Settlement Remarks',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    String updatedNotes = sale.notes.trim();
                    final remark = notesController.text.trim();
                    if (remark.isNotEmpty) {
                      updatedNotes = updatedNotes.isEmpty ? 'Cashier Settlement: ' + remark : updatedNotes + ' | Cashier Settlement: ' + remark;
                    }

                    if (_saleRepository != null) {
                      await _saleRepository!.completeCodDelivery(
                        saleId: sale.id,
                        notes: updatedNotes,
                      );
                    } else {
                      await _enqueueSync('UPDATE', 'sales', sale.id);
                    }

                    setState(() {
                      final now = DateTime.now();
                      sale.status = 'COMPLETED';
                      sale.deliveryStatus = 'SETTLED';
                      sale.amountPaid = sale.total;
                      sale.balance = 0.0;
                      sale.notes = updatedNotes;
                      sale.settledAt = now;
                      sale.settledByEmployeeId = _currentUserId;
                      sale.settledByCashierName = _currentUserName;
                      final idx = _sales.indexWhere((s) => s.id == sale.id);
                      if (idx >= 0) {
                        _sales[idx].status = 'COMPLETED';
                        _sales[idx].deliveryStatus = 'SETTLED';
                        _sales[idx].amountPaid = sale.total;
                        _sales[idx].balance = 0.0;
                        _sales[idx].notes = updatedNotes;
                        _sales[idx].settledAt = now;
                        _sales[idx].settledByEmployeeId = _currentUserId;
                        _sales[idx].settledByCashierName = _currentUserName;
                      }
                    });

                    _addNotification(
                      title: 'COD Cash Settled & Verified',
                      message: 'Counter cashier verified receipt of ' + _money(sale.total) + ' for invoice ' + sale.id + ' from ' + (sale.deliveryPersonName ?? "driver") + '. Added to drawer register.',
                      type: 'sale',
                      targetLocation: sale.locationId,
                      referenceId: sale.id,
                    );

                    await _persistWorkspaceData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('COD delivery for invoice ' + sale.id + ' settled & officially completed.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Cash Received & Settle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailField(String label, String value, IconData icon, {bool isBold = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _printSaleBillFromRecord(_SaleRecord sale) async {
    final lines = sale.items.map((item) {
      final discountType = item.discountType.toUpperCase();
      final discountValue = item.discount;
      final originalPrice = discountType == 'PERCENT'
          ? (discountValue >= 100
                ? item.unitPrice
                : item.unitPrice / (1 - (discountValue / 100)))
          : item.unitPrice + discountValue;
      return _CartLine(
        product: _ProductItem(
          id: item.productId,
          name: item.productName,
          category: 'Item',
          price: originalPrice,
          stock: 0,
          minStock: 0,
        ),
        qty: item.quantity,
        discountValue: discountValue,
        discountType: discountType,
        discountLabel: '',
      );
    }).toList();
    await _printReceipt(sale: sale, lines: lines);
  }

  void _showOrderActionsModal(_SaleRecord sale) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        final isCodPending = sale.status == 'COD_PENDING';
        final isOutForDelivery = sale.status == 'OUT_FOR_DELIVERY';
        final isDeliveredToCustomer = sale.status == 'DELIVERED_TO_CUSTOMER';
        final isReturned = sale.status == 'RETURNED';
        final isPartiallyReturned = sale.status == 'PARTIALLY_RETURNED';
        final isCancelled = sale.status == 'CANCELLED';
        final isCompleted = sale.status == 'COMPLETED';

        final Color badgeColor = isCodPending
            ? Colors.orange
            : isOutForDelivery
                ? Colors.purple
                : isDeliveredToCustomer
                    ? Colors.deepOrange
                    : isReturned
                        ? const Color(0xFFEF4444)
                        : isPartiallyReturned
                            ? const Color(0xFFF59E0B)
                            : isCancelled
                                ? const Color(0xFF6B7280)
                                : isCompleted
                                    ? Colors.green
                                    : AppTheme.brandIndigo;

        final String badgeText = isCodPending
            ? 'COD • PENDING'
            : isOutForDelivery
                ? 'OUT FOR DELIVERY'
                : isDeliveredToCustomer
                    ? 'DELIVERED • CASH WITH DRIVER'
                    : isReturned
                        ? 'RETURNED'
                        : isPartiallyReturned
                            ? 'PARTIALLY RETURNED'
                            : isCancelled
                                ? 'CANCELLED'
                                : isCompleted
                                    ? 'COMPLETED'
                                    : sale.status.toUpperCase();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  sale.paymentMethod == 'COD' ? Icons.local_shipping_outlined : Icons.receipt_long,
                  color: badgeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDisplayInvoiceNumber(sale),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      '${sale.createdAt.month}/${sale.createdAt.day}/${sale.createdAt.year}, ${sale.createdAt.hour.toString().padLeft(2, '0')}:${sale.createdAt.minute.toString().padLeft(2, '0')} ${sale.createdAt.hour >= 12 ? 'PM' : 'AM'}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(dialogCtx),
                tooltip: 'Close',
              ),
            ],
          ),
          content: SizedBox(
            width: ResponsiveLayout.adaptiveDialogWidth(context, 680),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Highlights summary grid
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailField(
                                'Cashier / Staff',
                                sale.cashierName.trim().isEmpty ? 'Staff' : sale.cashierName.trim(),
                                Icons.person_outline,
                              ),
                            ),
                            Expanded(
                              child: _buildDetailField(
                                'Payment Method',
                                sale.paymentMethod,
                                Icons.payment_outlined,
                              ),
                            ),
                            Expanded(
                              child: _buildDetailField(
                                'Grand Total',
                                _money(sale.total),
                                Icons.payments_outlined,
                                isBold: true,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailField(
                                'Customer',
                                sale.customerName.isEmpty ? 'Walk-in Customer' : sale.customerName,
                                Icons.account_circle_outlined,
                              ),
                            ),
                            Expanded(
                              child: _buildDetailField(
                                'Contact Phone',
                                sale.customerPhone.isNotEmpty ? sale.customerPhone : 'N/A',
                                Icons.phone_outlined,
                              ),
                            ),
                            Expanded(
                              child: _buildDetailField(
                                'Amount Paid / Due',
                                '${_money(sale.amountPaid)} / ${_money(sale.balance)}',
                                Icons.account_balance_wallet_outlined,
                                color: sale.balance > 0 ? Colors.redAccent : Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // COD / Delivery details banner
                  if (sale.paymentMethod == 'COD' || sale.shippingAddress.isNotEmpty || (sale.deliveryPersonName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_shipping, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Delivery & Logistics Information',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                              ),
                              const Spacer(),
                              if (sale.deliveryOtp != null && sale.deliveryOtp!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.vpn_key_outlined, size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'OTP: ${sale.deliveryOtp}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Assigned Driver: ' + (sale.deliveryPersonName?.isNotEmpty == true ? sale.deliveryPersonName! : 'None Assigned'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (sale.settledByCashierName != null && sale.settledByCashierName!.isNotEmpty)
                                Expanded(
                                  child: Text('Settled By: ' + sale.settledByCashierName!,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                                  ),
                                ),
                            ],
                          ),
                          if (sale.shippingAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Delivery Address: ' + sale.shippingAddress, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                          if (sale.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Notes: ' + sale.notes, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Text('Purchased Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: sale.items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final it = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: idx.isEven ? Colors.transparent : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.02)),
                            border: idx < sale.items.length - 1
                                ? Border(bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    if (it.discount > 0)
                                      Text('Disc: ${it.discount}${it.discountType == 'PERCENT' ? '%' : ''}',
                                        style: const TextStyle(fontSize: 11, color: Colors.orange),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('x${_formatQty(it.quantity)}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(_money(it.unitPrice), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(_money(it.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // PRIMARY ACTION BUTTONS
                  const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // 1. Receive Cash from Driver & Settle (Green)
                      if (sale.paymentMethod == 'COD' &&
                          (sale.status == 'DELIVERED_TO_CUSTOMER' ||
                              sale.status == 'COD_PENDING' ||
                              sale.status == 'OUT_FOR_DELIVERY'))
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            _showCompleteCodDeliveryDialog(sale);
                          },
                          icon: const Icon(Icons.price_check_outlined, size: 20),
                          label: const Text('Receive Cash from Driver & Settle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 1,
                          ),
                        ),

                      // 2. Mark Delivered to Customer (Deep Orange)
                      if (sale.paymentMethod == 'COD' && sale.status == 'OUT_FOR_DELIVERY')
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            _showMarkDeliveredDialog(sale);
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                          label: const Text('Mark Delivered to Customer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 1,
                          ),
                        ),

                      // 3. Assign Delivery Driver (Indigo)
                      if (sale.paymentMethod == 'COD' && (sale.deliveryPersonId ?? '').isEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            _showAssignDeliveryDialog(sale);
                          },
                          icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
                          label: const Text('Assign Delivery Driver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 1,
                          ),
                        ),

                      // 4. Make Sales Return (Amber)
                      if (sale.status != 'CANCELLED')
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            _makeSalesReturnForSale(sale);
                          },
                          icon: const Icon(Icons.assignment_return_outlined, size: 20),
                          label: const Text('Make Sales Return'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 1,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // SECONDARY BUTTONS
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _showSaleDetails(sale);
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Bill Preview'),
                      ),
                      OutlinedButton.icon(
                        onPressed: (_allowReprintSalesBill || _isOwner || _isAdmin)
                            ? () {
                                Navigator.pop(dialogCtx);
                                _printSaleBillFromRecord(sale);
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Re-printing sales bills is disabled in settings. Only Admin/Owner can re-print.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                        icon: Icon(
                          Icons.print_outlined,
                          size: 18,
                          color: (_allowReprintSalesBill || _isOwner || _isAdmin) ? Colors.teal : Colors.grey,
                        ),
                        label: Text(
                          'Print Bill',
                          style: TextStyle(
                            color: (_allowReprintSalesBill || _isOwner || _isAdmin) ? Colors.teal : Colors.grey,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _printDeliveryNote(sale);
                        },
                        icon: const Icon(Icons.local_shipping_outlined, size: 18, color: Colors.blue),
                        label: const Text('Delivery Note'),
                      ),
                      if (_canEditBill)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            _showDirectEditBillDialog(sale);
                          },
                          icon: const Icon(Icons.edit_note_outlined, size: 18, color: Colors.blue),
                          label: const Text('Edit Bill'),
                        ),
                      if (_canCreateDuplicate)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            _loadSaleIntoPOS(sale, isEdit: false);
                          },
                          icon: const Icon(Icons.copy_all_outlined, size: 18, color: Colors.cyan),
                          label: const Text('Create Duplicate'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
