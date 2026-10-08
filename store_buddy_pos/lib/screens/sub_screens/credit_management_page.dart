part of '../dashboard_screen.dart';

extension _credit_management_pageExt on _DashboardScreenState {
  Widget _buildCreditManagementPage() {
    final isCompact = MediaQuery.of(context).size.width < 1100;
    final query = _customerSearchController.text.trim().toLowerCase();
    final cashierBySaleId = <String, String>{
      for (final sale in _sales) sale.id: sale.cashierName,
    };

    final creditCashiers = <String>{};
    for (final entries in _customerCreditSales.values) {
      for (final entry in entries) {
        final cashierName = cashierBySaleId[entry.saleId] ?? 'Cashier';
        if (cashierName.trim().isNotEmpty) {
          creditCashiers.add(cashierName.trim());
        }
      }
    }
    final cashierOptions = ['All Cashiers', ...creditCashiers];
    final selectedCashier = cashierOptions.contains(_creditCashierFilter)
        ? _creditCashierFilter
        : 'All Cashiers';

    final customersWithCredit = _scopedCustomers.where((c) {
      final outstanding = _customerOutstandingBalance(
        c.id,
        fallback: c.currentBalance,
      );
      final entries = _customerCreditSales[c.id] ?? [];
      final hasCreditHistory = entries.isNotEmpty;

      // Base check: must have ever had a credit sale
      if (outstanding <= 0 && !hasCreditHistory) return false;

      // Status filter
      if (_creditStatusFilter == 'ACTIVE' && outstanding <= 0) return false;
      if (_creditStatusFilter == 'SETTLED' &&
          (outstanding > 0 || !hasCreditHistory))
        return false;

      // Cashier filter
      if (selectedCashier != 'All Cashiers') {
        final matchesCashier = entries.any((entry) {
          final cashierName = cashierBySaleId[entry.saleId] ?? 'Cashier';
          return cashierName.trim().toLowerCase() ==
              selectedCashier.trim().toLowerCase();
        });
        if (!matchesCashier) return false;
      }

      // Time filter
      if (_creditTimeFilter != 'All Time') {
        if (entries.isEmpty) return false;
        final latestDate = entries.first.createdAt;
        final day = DateTime(latestDate.year, latestDate.month, latestDate.day);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (_creditTimeFilter == 'Today') {
          if (!day.isAtSameMomentAs(today)) return false;
        } else if (_creditTimeFilter == '1 Month') {
          if (today.difference(day).inDays > 30) return false;
        } else if (_creditTimeFilter == '6 Months') {
          if (today.difference(day).inDays > 180) return false;
        } else if (_creditTimeFilter == '1 Year') {
          if (today.difference(day).inDays > 365) return false;
        }
      }

      // Text query search
      if (query.isNotEmpty) {
        return c.name.toLowerCase().contains(query) ||
            c.phone.toLowerCase().contains(query) ||
            c.vehicleNumber.toLowerCase().contains(query) ||
            c.address.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    final totalOutstanding = customersWithCredit.fold<double>(
      0,
      (sum, c) =>
          sum + _customerOutstandingBalance(c.id, fallback: c.currentBalance),
    );
    final overdueCustomers = customersWithCredit
        .where((c) => _hasOverdueCreditForCustomer(c))
        .length;
    final overCreditLimit = customersWithCredit
        .where(
          (c) =>
              c.creditLimit > 0 &&
              _customerOutstandingBalance(c.id, fallback: c.currentBalance) >
                  c.creditLimit,
        )
        .length;

    Widget metricCard({
      required IconData icon,
      required Color iconColor,
      required Color iconBg,
      required String title,
      required String value,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pageSurfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _pageBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credit Management',
            style: TextStyle(
              fontSize: isCompact ? 30 : 40,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Manage customer credit and payment tracking',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 300,
                ),
                child: metricCard(
                  icon: Icons.credit_card,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  iconBg: Theme.of(
                    context,
                  ).colorScheme.tertiary.withOpacity(0.12),
                  title: 'Total Outstanding',
                  value: _money(totalOutstanding),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 300,
                ),
                child: metricCard(
                  icon: Icons.attach_money,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  iconBg: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.12),
                  title: 'Customers with Credit',
                  value: '${customersWithCredit.length}',
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 300,
                ),
                child: metricCard(
                  icon: Icons.schedule,
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  iconBg: Theme.of(
                    context,
                  ).colorScheme.tertiary.withOpacity(0.12),
                  title: 'Overdue Customers',
                  value: '$overdueCustomers',
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 300,
                ),
                child: metricCard(
                  icon: Icons.cancel_outlined,
                  iconColor: Theme.of(context).colorScheme.error,
                  iconBg: Theme.of(
                    context,
                  ).colorScheme.error.withOpacity(0.12),
                  title: 'Over Credit Limit',
                  value: '$overCreditLimit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _pageSurfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _pageBorderColor),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: _adaptiveWidth(
                    350,
                    minWidth: 200,
                    horizontalPadding: 40,
                  ),
                  child: TextField(
                    controller: _customerSearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: _adaptiveWidth(
                    200,
                    minWidth: 160,
                    horizontalPadding: 40,
                  ),
                  child: _salesFilterDropdown(
                    value: _creditStatusFilter,
                    items: const ['ALL', 'ACTIVE', 'SETTLED'],
                    onChanged: (v) =>
                        setState(() => _creditStatusFilter = v),
                    labelMapper: (v) {
                      if (v == 'ACTIVE') return 'Active (Owed)';
                      if (v == 'SETTLED') return 'Settled (Paid)';
                      return 'All Outstanding';
                    },
                  ),
                ),
                SizedBox(
                  width: _adaptiveWidth(
                    180,
                    minWidth: 150,
                    horizontalPadding: 40,
                  ),
                  child: _salesFilterDropdown(
                    value: _creditTimeFilter,
                    items: const [
                      'All Time',
                      'Today',
                      '1 Month',
                      '6 Months',
                      '1 Year',
                    ],
                    onChanged: (v) =>
                        setState(() => _creditTimeFilter = v),
                  ),
                ),
                SizedBox(
                  width: _adaptiveWidth(
                    220,
                    minWidth: 170,
                    horizontalPadding: 40,
                  ),
                  child: _salesFilterDropdown(
                    value: selectedCashier,
                    items: cashierOptions,
                    onChanged: (v) =>
                        setState(() => _creditCashierFilter = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: _pageBorderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Customers with Credit (${customersWithCredit.length})',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 22 : 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  customersWithCredit.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  size: 54,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No customers found',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 18,
                                  ),
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
                                child: DataTable(
                                  headingRowColor:
                                      WidgetStateProperty.all(
                                        _tableHeaderColor,
                                      ),
                                  columnSpacing: isCompact ? 16 : 24,
                                  columns: const [
                                    DataColumn(label: Text('CUSTOMER')),
                                    DataColumn(label: Text('PHONE')),
                                    DataColumn(label: Text('ADDRESS')),
                                    DataColumn(
                                      label: Text('OUTSTANDING'),
                                    ),
                                    DataColumn(label: Text('LIMIT')),
                                    DataColumn(label: Text('STATUS')),
                                    DataColumn(
                                      label: Text('LAST CREDIT SALE'),
                                    ),
                                    DataColumn(label: Text('ACTIONS')),
                                  ],
                                  rows: customersWithCredit.map((c) {
                                    final effectiveOutstanding =
                                        _customerOutstandingBalance(
                                          c.id,
                                          fallback: c.currentBalance,
                                        );
                                    final isOverdue =
                                        _hasOverdueCreditForCustomer(c);
                                    final latestCreditSale =
                                        _customerCreditSales[c.id]
                                                ?.isNotEmpty ==
                                            true
                                        ? _customerCreditSales[c.id]!
                                              .first
                                        : null;
                                    return DataRow(
                                      onSelectChanged: (_) =>
                                          _showCustomerCreditHistory(c),
                                      cells: [
                                        DataCell(Text(c.name)),
                                        DataCell(Text(c.phone)),
                                        DataCell(
                                          SizedBox(
                                            width: 180,
                                            child: Text(
                                              c.address.isEmpty
                                                  ? 'N/A'
                                                  : c.address,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            _money(effectiveOutstanding),
                                          ),
                                        ),
                                        DataCell(
                                          Text(_money(c.creditLimit)),
                                        ),
                                        DataCell(
                                          Text(
                                            isOverdue
                                                ? 'Overdue'
                                                : 'Active',
                                            style: TextStyle(
                                              color: isOverdue
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.error
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 200,
                                            child: Text(
                                              latestCreditSale == null
                                                  ? '-'
                                                  : '${latestCreditSale.saleId} (${_money(latestCreditSale.outstandingAmount)})',
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              OutlinedButton(
                                                onPressed: () =>
                                                    _recordCustomerCreditPayment(
                                                      c,
                                                    ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                  side: BorderSide(
                                                    color:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                    width: 1.2,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          UiRadius.md,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                ),
                                                child: const Text(
                                                  'Record Payment',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(
                                                onPressed: () =>
                                                    _showCustomerCreditSalesHistory(
                                                      c,
                                                    ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                  side: BorderSide(
                                                    color:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                    width: 1.2,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          UiRadius.md,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                ),
                                                child: const Text(
                                                  'Sales',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: () =>
                                                    _showCustomerCreditHistory(
                                                      c,
                                                    ),
                                                icon: const Icon(
                                                  Icons.history,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }
}
