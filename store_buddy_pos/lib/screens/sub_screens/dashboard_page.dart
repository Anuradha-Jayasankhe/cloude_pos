part of '../dashboard_screen.dart';

extension _dashboard_pageExt on _DashboardScreenState {
  Widget _dashboardPage() {
    if (_isCashier || _isAgent) {
      return _cashierDashboardPage();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scopedSales = _scopedSales;
    final scopedProducts = _scopedProducts;
    final scopedEmployees = _scopedEmployees;
    final scopedUsers = _scopedUsers;
    final periodSales = _salesForPeriod(_dashboardPeriod, scopedSales);
    final validPeriodSales = periodSales.where((s) {
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
    final totalRefundedReturns = _returns.where((r) {
      if (r.status == 'Rejected') return false;
      if (r.refundMethod == 'NO_PAYOUT' || r.amount <= 0) return false;
      final rDate = DateTime.tryParse(r.createdAt) ?? DateTime.now();
      if (!_matchesTimeFilter(rDate, _dashboardPeriod)) return false;
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
      return true;
    }).fold<double>(0.0, (sum, r) => sum + r.amount);
    final totalRevenue = (validPeriodSales.fold<double>(0, (sum, s) => sum + s.total) - totalRefundedReturns).clamp(0.0, double.infinity);
    final avgOrder = validPeriodSales.isEmpty
        ? 0.0
        : totalRevenue / validPeriodSales.length;
    final lowStock = scopedProducts.where((p) => p.stock <= p.minStock).length;
    final now = DateTime.now();
    final expiredProducts = scopedProducts
        .where((p) => p.expiryDate != null && p.expiryDate!.isBefore(now))
        .toList();
    final expiringSoonProducts = scopedProducts.where((p) {
      if (p.expiryDate == null || p.expiryDate!.isBefore(now)) return false;
      final reminderDays = p.expiryReminderDays > 0 ? p.expiryReminderDays : 7;
      final reminderThreshold = now.add(Duration(days: reminderDays));
      return p.expiryDate!.isBefore(reminderThreshold) ||
          p.expiryDate!.isAtSameMomentAs(reminderThreshold);
    }).toList();
    final expiringIn30Days = scopedProducts.where((p) {
      if (p.expiryDate == null || p.expiryDate!.isBefore(now)) return false;
      final reminderDays = p.expiryReminderDays > 0 ? p.expiryReminderDays : 7;
      final reminderThreshold = now.add(Duration(days: reminderDays));
      if (p.expiryDate!.isBefore(reminderThreshold)) return false;
      return p.expiryDate!.isBefore(now.add(const Duration(days: 30)));
    }).toList();
    final totalAlertCount = (lowStock > 0 ? 1 : 0) +
        (expiredProducts.isNotEmpty ? 1 : 0) +
        (expiringSoonProducts.isNotEmpty ? 1 : 0) +
        (expiringIn30Days.isNotEmpty ? 1 : 0);
    final activeEmployees = scopedEmployees.where((e) => e.active).length;
    double totalEmployeeCost = scopedEmployees.where((e) => e.active).fold<double>(
      0.0,
      (sum, e) => sum + e.baseSalary,
    );
    if (totalEmployeeCost == 0.0 && _payrollRecords.isNotEmpty) {
      totalEmployeeCost = _payrollRecords.fold<double>(
        0.0,
        (sum, r) => sum + (r.grossPay > 0 ? r.grossPay : r.baseSalary),
      );
    }
    if (totalEmployeeCost == 0.0) {
      totalEmployeeCost = _scopedExpenses
          .where((x) =>
              x.category.toLowerCase().contains('salary') ||
              x.category.toLowerCase().contains('payroll') ||
              (x.notes ?? '').toLowerCase().contains('salary') ||
              (x.notes ?? '').toLowerCase().contains('payroll'))
          .fold<double>(0.0, (sum, x) => sum + x.amount);
    }
    final inventoryValue = _inventoryValue();
    final productRevenue = validPeriodSales.fold<double>(
      0,
      (sum, s) => sum + _saleProductRevenue(s),
    );
    final serviceRevenue = validPeriodSales.fold<double>(
      0,
      (sum, s) => sum + _saleServiceRevenue(s),
    );
    double _periodTotalCost = 0.0;
    for (final sale in validPeriodSales) {
      for (final item in sale.items) {
        final prodIdx = _products.indexWhere((p) => p.id == item.productId);
        final unitCost = prodIdx >= 0
            ? _unitInventoryCost(_products[prodIdx])
            : 0.0;
        _periodTotalCost += unitCost * item.quantity;
      }
    }
    final _periodTotalProfit = (totalRevenue - _periodTotalCost).clamp(
      0.0,
      double.infinity,
    );
    final profitMargin = totalRevenue == 0
        ? 0.0
        : (_periodTotalProfit / totalRevenue) * 100;
    final customersWithOutstandingCredit = _scopedCustomers.where((c) {
      final outstanding = _customerOutstandingBalance(
        c.id,
        fallback: c.currentBalance,
      );
      return outstanding > 0;
    }).toList();
    final pendingPaymentsCount = customersWithOutstandingCredit.length;
    final overduePaymentsCount = customersWithOutstandingCredit
        .where((c) => _hasOverdueCreditForCustomer(c))
        .length;
    final pendingPaymentsAmount = customersWithOutstandingCredit.fold<double>(
      0,
      (sum, c) =>
          sum + _customerOutstandingBalance(c.id, fallback: c.currentBalance),
    );
    final categorySummary =
        scopedProducts
            .fold<Map<String, int>>({}, (map, p) {
              map[p.category] = (map[p.category] ?? 0) + 1;
              return map;
            })
            .entries
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final topSeller = periodSales.isEmpty
        ? null
        : (periodSales.toList()..sort((a, b) => b.total.compareTo(a.total)))
              .first;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < UiBreakpoints.tablet;
    final isPhone = screenWidth < UiBreakpoints.phone;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 14 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Page Header ───────────────────────────────────────────
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
                      child: Text(
                        _companyName.trim().isEmpty
                            ? 'Business Overview'
                            : _companyName.trim(),
                        style: TextStyle(
                          fontSize: isCompact ? 24 : 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete business overview and management tools.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Premium period selector
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: UiGradients.brand,
                  borderRadius: BorderRadius.circular(UiRadius.pill),
                  boxShadow: UiShadows.glow,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _dashboardPeriod,
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Today', child: Text('Today')),
                      DropdownMenuItem(
                        value: 'This Month',
                        child: Text('This Month'),
                      ),
                      DropdownMenuItem(
                        value: 'This Year',
                        child: Text('This Year'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _dashboardPeriod = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (isCompact)
            Column(
              children: [
                _MetricCard(
                  width: double.infinity,
                  title: 'Total Revenue',
                  numericValue: totalRevenue,
                  formatValue: _money,
                  icon: Icons.payments_rounded,
                  subtitle: '$_dashboardPeriod sales',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  width: double.infinity,
                  title: 'Product Revenue',
                  numericValue: productRevenue,
                  formatValue: _money,
                  icon: Icons.shopping_bag_outlined,
                  subtitle: 'From products',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  width: double.infinity,
                  title: 'Service Revenue',
                  numericValue: serviceRevenue,
                  formatValue: _money,
                  icon: Icons.settings_suggest_outlined,
                  subtitle: 'From services',
                  deltaText: serviceRevenue.isNaN ? '+NaN%' : '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  width: double.infinity,
                  title: 'Profit Margin',
                  numericValue: profitMargin,
                  formatValue: (val) => '${val.toStringAsFixed(1)}%',
                  icon: Icons.bar_chart_rounded,
                  subtitle: 'After product costs',
                  deltaText: profitMargin >= 25
                      ? '+Excellent'
                      : 'Needs attention',
                  deltaHint: 'vs last period',
                  deltaColor: profitMargin >= 25
                      ? const Color(0xFF1FA35B)
                      : const Color(0xFFE35D5D),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  width: double.infinity,
                  title: 'Employee Cost',
                  numericValue: totalEmployeeCost,
                  formatValue: _money,
                  icon: Icons.groups_2_outlined,
                  subtitle: '$activeEmployees active employees',
                  deltaText: '+${_money(totalEmployeeCost)}',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showEmployeeCostDetailsDialog,
                ),
              ],
            )
          else
            Wrap(
              spacing: 0,
              runSpacing: 0,
              children: [
                _MetricCard(
                  title: 'Total Revenue',
                  numericValue: totalRevenue,
                  formatValue: _money,
                  icon: Icons.payments_rounded,
                  subtitle: '$_dashboardPeriod sales',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  title: 'Product Revenue',
                  numericValue: productRevenue,
                  formatValue: _money,
                  icon: Icons.shopping_bag_outlined,
                  subtitle: 'From products',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  title: 'Service Revenue',
                  numericValue: serviceRevenue,
                  formatValue: _money,
                  icon: Icons.settings_suggest_outlined,
                  subtitle: 'From services',
                  deltaText: serviceRevenue.isNaN ? '+NaN%' : '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  title: 'Profit Margin',
                  value: '${profitMargin.toStringAsFixed(1)}%',
                  icon: Icons.bar_chart_rounded,
                  subtitle: 'After product costs',
                  deltaText: profitMargin >= 25
                      ? '+Excellent'
                      : 'Needs attention',
                  deltaHint: 'vs last period',
                  deltaColor: profitMargin >= 25
                      ? const Color(0xFF1FA35B)
                      : const Color(0xFFE35D5D),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  title: 'Employee Cost',
                  value: _money(totalEmployeeCost),
                  icon: Icons.groups_2_outlined,
                  subtitle: '$activeEmployees active employees',
                  deltaText: '+${_money(totalEmployeeCost)}',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showEmployeeCostDetailsDialog,
                ),
              ],
            ),
          // ─── Financial Health Summary ──────────────────────────────
          const SizedBox(height: 22),
          Text(
            'Financial Health Summary',
            style: TextStyle(
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 0,
                runSpacing: 0,
                children: [
                  _FinancialMetricCard(
                    title: 'Cash in Hand',
                    value: _money(
                      _calculatedCashInHandForPeriod(_dashboardPeriod),
                    ),
                    icon: Icons.account_balance_wallet_rounded,
                    themeColor: const Color(0xFF10B981),
                    subtitle: 'Register & Drawer cash',
                    onViewDetails: _showCashInHandDetailsDialog,
                  ),
                  _FinancialMetricCard(
                    title: 'Credit to Collect',
                    value: _money(
                      _calculatedCreditToCollectForPeriod(_dashboardPeriod),
                    ),
                    icon: Icons.assignment_returned_rounded,
                    themeColor: const Color(0xFF3B82F6),
                    subtitle: 'Accounts Receivable',
                    onViewDetails: _showCreditToCollectDetailsDialog,
                  ),
                  _FinancialMetricCard(
                    title: 'Credit to Pay',
                    value: _money(
                      _calculatedCreditToPayForPeriod(_dashboardPeriod),
                    ),
                    icon: Icons.assignment_late_rounded,
                    themeColor: const Color(0xFFEF4444),
                    subtitle: 'Accounts Payable',
                    onViewDetails: _showCreditToPayDetailsDialog,
                  ),
                  _FinancialMetricCard(
                    title: 'Cheques (Issued/Received)',
                    value: _calculatedChequesForPeriod(_dashboardPeriod),
                    icon: Icons.payments_rounded,
                    themeColor: const Color(0xFFF59E0B),
                    subtitle: 'Cheque payments history',
                    onViewDetails: _showChequesDetailsDialog,
                  ),
                  _FinancialMetricCard(
                    title: 'Active Installments',
                    value: _calculatedActiveInstallmentsValueForPeriod(
                      _dashboardPeriod,
                    ),
                    icon: Icons.credit_card_rounded,
                    themeColor: const Color(0xFF8B5CF6),
                    subtitle:
                        'Remaining: ' +
                        _money(
                          _calculatedActiveInstallmentsRemainingForPeriod(
                            _dashboardPeriod,
                          ),
                        ),
                    onViewDetails: _showInstallmentDetailsDialog,
                  ),
                  _FinancialMetricCard(
                    title: 'COD Orders',
                    value: _money(
                      _calculatedCodOrdersForPeriod(_dashboardPeriod),
                    ),
                    icon: Icons.local_shipping_rounded,
                    themeColor: const Color(0xFF06B6D4),
                    subtitle:
                        '${_scopedSales.where((s) => s.paymentMethod.toUpperCase() == 'COD' && _matchesTimeFilter(s.createdAt, _dashboardPeriod)).length} total COD orders',
                    onViewDetails: _showCodDetailsDialog,
                  ),
                ],
              );
            },
          ),
          // ─── Business Alerts ─────────────────────────────────────
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF111827)
                  : Colors.white,
              borderRadius: BorderRadius.circular(UiRadius.lg),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E2D45)
                    : const Color(0xFFE8EAFF),
              ),
              boxShadow: UiShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(UiRadius.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amber accent header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: AppTheme.brandAmber.withValues(alpha: 0.08),
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.brandAmber.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          color: AppTheme.brandAmber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Business Alerts ($totalAlertCount)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brandAmber.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(UiRadius.md),
                        border: Border.all(
                          color: AppTheme.brandAmber.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: AppTheme.brandAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Low Stock Alert',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$lowStock products are running low on stock',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.68,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () =>
                                setState(() => _selectedNavKey = 'products'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.brandAmber,
                              side: BorderSide(
                                color: AppTheme.brandAmber.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: const Text('Manage'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Expired Products Alert ──────────────────────────
                  if (expiredProducts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE35D5D).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(UiRadius.md),
                          border: Border.all(
                            color: const Color(0xFFE35D5D).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.dangerous_outlined,
                              color: Color(0xFFE35D5D),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Expired Products',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFFE35D5D),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${expiredProducts.length} product${expiredProducts.length == 1 ? '' : 's'} '
                                    'ha${expiredProducts.length == 1 ? 's' : 've'} passed their expiry date',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  setState(() => _selectedNavKey = 'products'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE35D5D),
                                side: BorderSide(
                                  color: const Color(0xFFE35D5D).withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text('Review'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // ── Expiring Soon Alert (within reminder window) ────
                  if (expiringSoonProducts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(UiRadius.md),
                          border: Border.all(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Color(0xFFFF6B35),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Expiring Soon',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFFFF6B35),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${expiringSoonProducts.length} product${expiringSoonProducts.length == 1 ? '' : 's'} '
                                    'expiring within the set reminder window',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  setState(() => _selectedNavKey = 'products'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFF6B35),
                                side: BorderSide(
                                  color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text('Manage'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // ── Expiring within 30 days (informational) ─────────
                  if (expiringIn30Days.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brandAmber.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(UiRadius.md),
                          border: Border.all(
                            color: AppTheme.brandAmber.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_outlined,
                              color: AppTheme.brandAmber,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Upcoming Expiry',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${expiringIn30Days.length} product${expiringIn30Days.length == 1 ? '' : 's'} '
                                    'expiring within 30 days',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  setState(() => _selectedNavKey = 'products'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.brandAmber,
                                side: BorderSide(
                                  color: AppTheme.brandAmber.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text('View'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isCompact)
            Column(
              children: [
                _buildDashboardSummaryCard(
                  title: 'Sales Overview',
                  children: [
                    _overviewRow(
                      _dashboardPeriod,
                      _money(totalRevenue),
                      valueColor: colorScheme.primary,
                    ),
                    _overviewRow('Transactions', '${periodSales.length}'),
                    _overviewRow('Avg Order', _money(avgOrder)),
                    const Divider(height: 22),
                    _overviewRow('Product Sales', _money(productRevenue)),
                    _overviewRow('Service Sales', _money(serviceRevenue)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDashboardSummaryCard(
                  title: 'Payment Status',
                  children: [
                    _overviewRow('Total Invoices', '${_invoices.length}'),
                    _overviewRow('Pending Payments', '$pendingPaymentsCount'),
                    _overviewRow(
                      'Overdue Payments',
                      '$overduePaymentsCount',
                      valueColor: overduePaymentsCount > 0
                          ? const Color(0xFFE35D5D)
                          : const Color(0xFF1FA35B),
                    ),
                    const Divider(height: 22),
                    _overviewRow(
                      'Pending Amount',
                      _money(pendingPaymentsAmount),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDashboardSummaryCard(
                  title: 'Inventory Overview',
                  children: [
                    _overviewRow('Total Products', '${scopedProducts.length}'),
                    _overviewRow(
                      'Low Stock',
                      '$lowStock',
                      valueColor: lowStock > 0
                          ? const Color(0xFFE35D5D)
                          : const Color(0xFF1FA35B),
                    ),
                    _overviewRow('Inventory Value', _money(inventoryValue)),
                    const Divider(height: 22),
                    _overviewRow(
                      'Categories',
                      categorySummary.isEmpty ? '-' : categorySummary.first.key,
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDashboardSummaryCard(
                    title: 'Sales Overview',
                    children: [
                      _overviewRow(
                        _dashboardPeriod,
                        _money(totalRevenue),
                        valueColor: colorScheme.primary,
                      ),
                      _overviewRow('Transactions', '${periodSales.length}'),
                      _overviewRow('Avg Order', _money(avgOrder)),
                      const Divider(height: 22),
                      _overviewRow('Product Sales', _money(productRevenue)),
                      _overviewRow('Service Sales', _money(serviceRevenue)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDashboardSummaryCard(
                    title: 'Payment Status',
                    children: [
                      _overviewRow('Total Invoices', '${_invoices.length}'),
                      _overviewRow('Pending Payments', '$pendingPaymentsCount'),
                      _overviewRow(
                        'Overdue Payments',
                        '$overduePaymentsCount',
                        valueColor: overduePaymentsCount > 0
                            ? const Color(0xFFE35D5D)
                            : const Color(0xFF1FA35B),
                      ),
                      const Divider(height: 22),
                      _overviewRow(
                        'Pending Amount',
                        _money(pendingPaymentsAmount),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDashboardSummaryCard(
                    title: 'Inventory Overview',
                    children: [
                      _overviewRow(
                        'Total Products',
                        '${scopedProducts.length}',
                      ),
                      _overviewRow(
                        'Low Stock',
                        '$lowStock',
                        valueColor: lowStock > 0
                            ? const Color(0xFFE35D5D)
                            : const Color(0xFF1FA35B),
                      ),
                      _overviewRow('Inventory Value', _money(inventoryValue)),
                      const Divider(height: 22),
                      _overviewRow(
                        'Categories',
                        categorySummary.isEmpty
                            ? '-'
                            : categorySummary.first.key,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          _buildDashboardSummaryCard(
            title: 'Team Performance',
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topSeller?.customerName ??
                              (scopedUsers.isNotEmpty
                                  ? scopedUsers.first.name
                                  : 'Team Member'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${periodSales.length} sales',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _money(topSeller?.total ?? totalRevenue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ─── Quick Management Actions ─────────────────────────────
          const SizedBox(height: 20),
          Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                          : const Color(0xFFF8FAFC),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF1E2D45)
                              : const Color(0xFFE8EAFF),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: UiGradients.brand,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Management Actions',
                                style: TextStyle(
                                  fontSize: isCompact ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Fast access to key administration tools and operational modules.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Grid Body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final columns = width < 450
                            ? 2
                            : (width < 800 ? 3 : 6);
                        final itemWidth =
                            (width - (12 * (columns - 1))) / columns;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _quickActionTile(
                                icon: Icons.insights_rounded,
                                label: 'Sales Report',
                                subtitle: 'Analytics & Financials',
                                customGradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                onTap: () => setState(() => _selectedNavKey = 'reports'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _quickActionTile(
                                icon: Icons.people_alt_rounded,
                                label: 'Employees',
                                subtitle: '$activeEmployees Active Staff',
                                badgeText: '$activeEmployees',
                                badgeColor: const Color(0xFF3B82F6),
                                customGradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                onTap: () => setState(() => _selectedNavKey = 'employees'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _quickActionTile(
                                icon: Icons.inventory_2_rounded,
                                label: 'Products',
                                subtitle: '${scopedProducts.length} Items Listed',
                                badgeText: scopedProducts.length.toString(),
                                badgeColor: const Color(0xFFF59E0B),
                                customGradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                onTap: () => setState(() => _selectedNavKey = 'products'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _quickActionTile(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Payroll',
                                subtitle: 'Salary & Slips',
                                customGradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                onTap: () => setState(() => _selectedNavKey = 'payroll'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _quickActionTile(
                                icon: Icons.admin_panel_settings_rounded,
                                label: 'Users',
                                subtitle: '${scopedUsers.length} System Users',
                                badgeText: scopedUsers.length.toString(),
                                badgeColor: const Color(0xFF8B5CF6),
                                customGradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                onTap: () => setState(() => _selectedNavKey = 'users'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _quickActionTile(
                                icon: Icons.sync_rounded,
                                label: 'Refresh',
                                subtitle: 'Reload Dashboard',
                                customGradient: const LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Dashboard refreshed successfully!'),
                                      duration: Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  setState(() {});
                                },
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
          ),
        ],
      ),
    );
  }

  Widget _cashierDashboardPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < UiBreakpoints.tablet;
    final isPhone = screenWidth < UiBreakpoints.phone;
    // Filter to this cashier's/agent's own sales using the user ID or name matching.
    final cashierSales = _scopedSales.where((s) {
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
      } else {
        if (s.employeeId.isNotEmpty && _currentUserId.isNotEmpty) {
          return s.employeeId == _currentUserId;
        }
        return s.cashierName == _currentUserName;
      }
    }).toList();
    final periodSales = _salesForPeriod(_dashboardPeriod, cashierSales);
    final totalRevenue = periodSales.fold<double>(0, (sum, s) => sum + s.total);
    final avgOrder = periodSales.isEmpty
        ? 0.0
        : totalRevenue / periodSales.length;
    final productRevenue = periodSales.fold<double>(
      0,
      (sum, s) => sum + _saleProductRevenue(s),
    );
    final serviceRevenue = periodSales.fold<double>(
      0,
      (sum, s) => sum + _saleServiceRevenue(s),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isAgent ? 'Agent Dashboard' : 'Cashier Dashboard',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _dashboardPeriod,
                    items: const [
                      DropdownMenuItem(value: 'Today', child: Text('Today')),
                      DropdownMenuItem(
                        value: 'This Month',
                        child: Text('This Month'),
                      ),
                      DropdownMenuItem(
                        value: 'This Year',
                        child: Text('This Year'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _dashboardPeriod = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Your sales performance and transaction overview.',
            style: textTheme.titleMedium?.copyWith(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 18),
          if (isCompact)
            Column(
              children: [
                _MetricCard(
                  width: double.infinity,
                  title: 'Your Revenue',
                  value: _money(totalRevenue),
                  icon: Icons.payments_rounded,
                  subtitle: '$_dashboardPeriod sales',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  width: double.infinity,
                  title: 'Product Sales',
                  value: _money(productRevenue),
                  icon: Icons.shopping_bag_outlined,
                  subtitle: 'From products',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  width: double.infinity,
                  title: 'Service Sales',
                  value: _money(serviceRevenue),
                  icon: Icons.settings_suggest_outlined,
                  subtitle: 'From services',
                  deltaText: serviceRevenue.isNaN ? '+NaN%' : '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  width: double.infinity,
                  title: 'Avg Transaction',
                  value: _money(avgOrder),
                  icon: Icons.receipt_long_rounded,
                  subtitle: 'Per sale',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
              ],
            )
          else
            Wrap(
              spacing: 0,
              runSpacing: 0,
              children: [
                _MetricCard(
                  title: 'Your Revenue',
                  value: _money(totalRevenue),
                  icon: Icons.payments_rounded,
                  subtitle: '$_dashboardPeriod sales',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  title: 'Product Sales',
                  value: _money(productRevenue),
                  icon: Icons.shopping_bag_outlined,
                  subtitle: 'From products',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  title: 'Service Sales',
                  value: _money(serviceRevenue),
                  icon: Icons.settings_suggest_outlined,
                  subtitle: 'From services',
                  deltaText: serviceRevenue.isNaN ? '+NaN%' : '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
                _MetricCard(
                  title: 'Avg Transaction',
                  value: _money(avgOrder),
                  icon: Icons.receipt_long_rounded,
                  subtitle: 'Per sale',
                  deltaText: '+0.0%',
                  deltaHint: 'vs last period',
                  deltaColor: const Color(0xFF1FA35B),
                  onViewMore: _showRevenueAndProfitDetailsDialog,
                ),
              ],
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _overviewRow(
                    _dashboardPeriod,
                    _money(totalRevenue),
                    valueColor: colorScheme.primary,
                  ),
                  _overviewRow('Transactions', '${periodSales.length}'),
                  _overviewRow('Avg Order', _money(avgOrder)),
                  const Divider(height: 22),
                  _overviewRow('Product Sales', _money(productRevenue)),
                  _overviewRow('Service Sales', _money(serviceRevenue)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final columns = isPhone ? 2.0 : 4.0;
                      final rawTileWidth =
                          (maxWidth - (12 * (columns - 1))) / columns;
                      final tileWidth = rawTileWidth
                          .clamp(120.0, maxWidth)
                          .toDouble();

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: tileWidth,
                            child: _quickActionTile(
                              icon: Icons.point_of_sale_rounded,
                              label: 'Point of Sale',
                              onTap: () =>
                                  setState(() => _selectedNavKey = 'pos'),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: _quickActionTile(
                              icon: Icons.receipt_long_rounded,
                              label: 'Sales',
                              onTap: () =>
                                  setState(() => _selectedNavKey = 'sales'),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: _quickActionTile(
                              icon: Icons.bar_chart_rounded,
                              label: 'Reports',
                              onTap: () =>
                                  setState(() => _selectedNavKey = 'reports'),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: _quickActionTile(
                              icon: Icons.refresh_rounded,
                              label: 'Refresh',
                              onTap: () => setState(() {}),
                            ),
                          ),
                        ],
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

  Widget _overviewRow(String label, String value, {Color? valueColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
                fontSize: 16,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? subtitle,
    LinearGradient? customGradient,
    String? badgeText,
    Color? badgeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = customGradient ?? UiGradients.brand;

    return Material(
      color: isDark ? const Color(0xFF111827) : Colors.white,
      borderRadius: BorderRadius.circular(UiRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UiRadius.md),
            border: Border.all(
              color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : const Color(0xFF6366F1).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  if (badgeText != null && badgeText.isNotEmpty)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF111827) : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSummaryCard({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(UiRadius.lg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
        ),
        boxShadow: UiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header stripe
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(UiRadius.lg),
              topRight: Radius.circular(UiRadius.lg),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.brandIndigo.withValues(alpha: 0.10),
                    AppTheme.brandViolet.withValues(alpha: 0.06),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E2D45)
                        : const Color(0xFFE8EAFF),
                  ),
                ),
              ),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => UiGradients.brand.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Financial health detail dialogs ───────────────────────────────

  void _showCashInHandDetailsDialog() {
    final movements = _getCashMovementsLog()
        .where(
          (m) => _matchesTimeFilter(m['date'] as DateTime, _dashboardPeriod),
        )
        .toList();

    // Calculate totals
    final cashSalesTotal = _scopedSales
        .where(
          (s) {
            final st = s.status.toUpperCase();
            return (st == 'COMPLETED' ||
                    st == 'RETURNED' ||
                    st == 'PARTIALLY_RETURNED') &&
                s.paymentMethod.toUpperCase() == 'CASH' &&
                _matchesTimeFilter(s.createdAt, _dashboardPeriod);
          },
        )
        .fold<double>(
          0.0,
          (sum, s) => sum + (s.amountPaid > 0 ? s.amountPaid : s.total),
        );
    final codCompletedTotal = _scopedSales
        .where(
          (s) {
            final st = s.status.toUpperCase();
            return (st == 'COMPLETED' ||
                    st == 'RETURNED' ||
                    st == 'PARTIALLY_RETURNED') &&
                s.paymentMethod.toUpperCase() == 'COD' &&
                s.amountPaid > 0 &&
                _matchesTimeFilter(s.settledAt ?? s.createdAt, _dashboardPeriod);
          },
        )
        .fold<double>(0.0, (sum, s) => sum + s.amountPaid);

    double creditSettlementsTotal = 0.0;
    for (final customer in _scopedCustomers) {
      final payments =
          _customerCreditPayments[customer.id] ?? const <_CreditPaymentItem>[];
      for (final p in payments) {
        if (_matchesTimeFilter(p.createdAt, _dashboardPeriod)) {
          creditSettlementsTotal += p.amount;
        }
      }
    }

    double installmentDownTotal = 0.0;
    double installmentScheduleTotal = 0.0;
    for (final plan in _scopedInstallmentPlans) {
      if (plan.paymentMethod.toUpperCase() == 'CASH') {
        if (_matchesTimeFilter(plan.createdAt, _dashboardPeriod)) {
          installmentDownTotal += plan.downPayment;
        }
        for (final schedule in plan.schedules) {
          if (schedule.isPaid &&
              schedule.paidAt != null &&
              _matchesTimeFilter(schedule.paidAt!, _dashboardPeriod)) {
            installmentScheduleTotal += schedule.paidAmount;
          }
        }
      }
    }

    double poCashTotal = 0.0;
    for (final exp in _scopedExpenses) {
      if (exp.category == 'STOCK_PURCHASE' &&
          _matchesTimeFilter(exp.expenseDate, _dashboardPeriod)) {
        if (_getExpensePaymentMethod(exp.notes) == 'CASH') {
          poCashTotal += exp.amount;
        }
      }
    }

    double generalExpensesTotal = 0.0;
    for (final exp in _scopedExpenses) {
      if (exp.category != 'STOCK_PURCHASE' &&
          _matchesTimeFilter(exp.expenseDate, _dashboardPeriod)) {
        if (_getExpensePaymentMethod(exp.notes) == 'CASH') {
          generalExpensesTotal += exp.amount;
        }
      }
    }

    double cashRefundsTotal = _scopedCashTransactions
        .where(
          (t) =>
              t.type == 'OUT' &&
              _matchesTimeFilter(
                DateTime.tryParse(t.createdAt) ?? DateTime.now(),
                _dashboardPeriod,
              ),
        )
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    double manualCashInTotal = _scopedCashTransactions
        .where(
          (t) =>
              t.type == 'IN' &&
              _matchesTimeFilter(
                DateTime.tryParse(t.createdAt) ?? DateTime.now(),
                _dashboardPeriod,
              ),
        )
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final totalInflow =
        cashSalesTotal +
        codCompletedTotal +
        creditSettlementsTotal +
        installmentDownTotal +
        installmentScheduleTotal +
        manualCashInTotal;
    final totalOutflow = poCashTotal + generalExpensesTotal + cashRefundsTotal;

    showDialog(
      context: context,
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width < 768;

        Widget buildInflowCard() {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CASH INFLOW (+)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      fontSize: 12,
                    ),
                  ),
                  const Divider(),
                  _dialogValueRow('Cash Sales', _money(cashSalesTotal)),
                  _dialogValueRow('COD Completed', _money(codCompletedTotal)),
                  _dialogValueRow('Credit Payments', _money(creditSettlementsTotal)),
                  _dialogValueRow('Installments Down', _money(installmentDownTotal)),
                  _dialogValueRow('Installment Schedules', _money(installmentScheduleTotal)),
                  if (manualCashInTotal > 0)
                    _dialogValueRow('Manual Cash In', _money(manualCashInTotal)),
                  const Divider(),
                  _dialogValueRow('Total Inflow', _money(totalInflow), isBold: true),
                ],
              ),
            ),
          );
        }

        Widget buildOutflowCard() {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CASH OUTFLOW (-)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                    ),
                  ),
                  const Divider(),
                  _dialogValueRow('PO Cash Restocks', _money(poCashTotal)),
                  _dialogValueRow('General Expenses', _money(generalExpensesTotal)),
                  _dialogValueRow('Cash Refunds', _money(cashRefundsTotal)),
                  const Divider(),
                  if (!isMobile && manualCashInTotal == 0)
                    const SizedBox(height: 38), // spacer align
                  _dialogValueRow('Total Outflow', _money(totalOutflow), isBold: true),
                ],
              ),
            ),
          );
        }

        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 10),
              const Text('Cash in Hand Breakdown'),
            ],
          ),
          content: SizedBox(
            width: isMobile
                ? MediaQuery.of(context).size.width * 0.95
                : MediaQuery.of(context).size.width * 0.7,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Calculated Cash In Hand ($_dashboardPeriod):',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Inflow: ${_money(totalInflow)}  •  Outflow: ${_money(totalOutflow)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _money(
                              _calculatedCashInHandForPeriod(_dashboardPeriod),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildInflowCard(),
                        const SizedBox(height: 12),
                        buildOutflowCard(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: buildInflowCard()),
                        const SizedBox(width: 12),
                        Expanded(child: buildOutflowCard()),
                      ],
                    ),
                const SizedBox(height: 14),
                const Text(
                  'Recent Cash movements',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: movements.isEmpty
                      ? const Center(
                          child: Text('No cash transactions recorded.'),
                        )
                      : ListView.builder(
                          itemCount: movements.take(15).length,
                          itemBuilder: (context, idx) {
                            final item = movements[idx];
                            final isIn = item['type'] == 'IN';
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isIn
                                    ? Icons.add_circle_outline_rounded
                                    : Icons.remove_circle_outline_rounded,
                                color: isIn
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                              title: Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${item['subtitle']}  •  ${_formatDate(item['date'] as DateTime)}',
                              ),
                              trailing: Text(
                                '${isIn ? "+" : "-"}${_money(item['amount'] as double)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isIn
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

  void _showCreditToCollectDetailsDialog() {
    final debtors =
        _scopedCustomers.where((c) {
          final periodOutstanding =
              _customerCreditSales[c.id]
                  ?.where(
                    (s) => _matchesTimeFilter(s.createdAt, _dashboardPeriod),
                  )
                  .fold<double>(0.0, (sum, s) => sum + s.outstandingAmount) ??
              0.0;
          return periodOutstanding > 0;
        }).toList()..sort((a, b) {
          final balA =
              _customerCreditSales[a.id]
                  ?.where(
                    (s) => _matchesTimeFilter(s.createdAt, _dashboardPeriod),
                  )
                  .fold<double>(0.0, (sum, s) => sum + s.outstandingAmount) ??
              0.0;
          final balB =
              _customerCreditSales[b.id]
                  ?.where(
                    (s) => _matchesTimeFilter(s.createdAt, _dashboardPeriod),
                  )
                  .fold<double>(0.0, (sum, s) => sum + s.outstandingAmount) ??
              0.0;
          return balB.compareTo(balA);
        });
    final totalOutstanding = _calculatedCreditToCollectForPeriod(
      _dashboardPeriod,
    );

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_returned_rounded,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Credit to Collect',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${debtors.length} Debtors with Outstanding Balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: ResponsiveLayout.adaptiveDialogWidth(context, 620.0),
            height: ResponsiveLayout.adaptiveDialogHeight(context, 580.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Color(0xFF3B82F6),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total Accounts Receivable (Outstanding)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _money(totalOutstanding),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Top Debtors List',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Sorted by highest balance',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: debtors.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 48,
                                  color: Colors.green.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No customers with outstanding credit.',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: debtors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final c = debtors[idx];
                            final balance =
                                _customerCreditSales[c.id]
                                    ?.where(
                                      (s) => _matchesTimeFilter(
                                        s.createdAt,
                                        _dashboardPeriod,
                                      ),
                                    )
                                    .fold<double>(
                                      0.0,
                                      (sum, s) => sum + s.outstandingAmount,
                                    ) ??
                                0.0;
                            final isOverdue = _hasOverdueCreditForCustomer(c);
                            
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, itemConstraints) {
                                  final isItemNarrow = itemConstraints.maxWidth < 360;
                                  
                                  final badgeWidget = Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOverdue
                                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                          : const Color(0xFF10B981).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isOverdue
                                              ? Icons.warning_amber_rounded
                                              : Icons.check_circle_outline,
                                          size: 12,
                                          color: isOverdue
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOverdue ? 'Overdue' : 'Active',
                                          style: TextStyle(
                                            color: isOverdue
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                            child: Text(
                                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                color: Color(0xFF3B82F6),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  c.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                if (c.phone.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 2),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.phone_outlined,
                                                          size: 12,
                                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            c.phone,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (c.address.isNotEmpty)
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.location_on_outlined,
                                                        size: 12,
                                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          c.address,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (!isItemNarrow) ...[
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _money(balance),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF3B82F6),
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                badgeWidget,
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (isItemNarrow) ...[
                                        const SizedBox(height: 8),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            badgeWidget,
                                            Text(
                                              _money(balance),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF3B82F6),
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _selectedNavKey = 'creditManagement');
                  },
                  icon: const Icon(Icons.credit_card_rounded, size: 18),
                  label: const Text('Go to Credit Management'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showCreditToPayDetailsDialog() {
    final payables =
        _scopedPurchaseOrders
            .where(
              (po) =>
                  po.status == 'RECEIVED' &&
                  po.amountDue > 0 &&
                  _matchesTimeFilter(
                    po.receivedAt ??
                        DateTime.tryParse(po.createdAt) ??
                        DateTime.now(),
                    _dashboardPeriod,
                  ),
            )
            .toList()
          ..sort((a, b) => b.amountDue.compareTo(a.amountDue));
    final totalPayable = _calculatedCreditToPayForPeriod(_dashboardPeriod);
    final totalOrderValue = payables.fold<double>(0.0, (sum, po) => sum + po.amount);

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_late_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Credit to Pay (Accounts Payable)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${payables.length} Outstanding Purchase Orders Owed',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: ResponsiveLayout.adaptiveDialogWidth(context, 640.0),
            height: ResponsiveLayout.adaptiveDialogHeight(context, 580.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Financial Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.account_balance_outlined,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total Accounts Payable (Owed)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _money(totalPayable),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Total PO Value: ${_money(totalOrderValue)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Pending POs: ${payables.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: const Text(
                        'Outstanding Supplier Payments List',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sorted by highest due',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: payables.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 48,
                                  color: Colors.green.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No purchase orders with outstanding due.',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: payables.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final po = payables[idx];
                            bool isPoOverdue = false;
                            if (po.paymentDueDate != null && po.paymentDueDate!.isNotEmpty) {
                              final dueDate = DateTime.tryParse(po.paymentDueDate!);
                              if (dueDate != null && dueDate.isBefore(DateTime.now())) {
                                isPoOverdue = true;
                              }
                            }

                            final double progress = po.amount > 0
                                ? (po.amountPaid / po.amount).clamp(0.0, 1.0)
                                : 0.0;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, itemConstraints) {
                                  final isItemNarrow = itemConstraints.maxWidth < 440;

                                  final badgeWidget = Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPoOverdue
                                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                          : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPoOverdue
                                              ? Icons.warning_amber_rounded
                                              : Icons.access_time_rounded,
                                          size: 12,
                                          color: isPoOverdue
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFF59E0B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isPoOverdue ? 'Overdue' : 'Pending',
                                          style: TextStyle(
                                            color: isPoOverdue
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFFF59E0B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                            child: Text(
                                              po.supplier.isNotEmpty ? po.supplier[0].toUpperCase() : 'S',
                                              style: const TextStyle(
                                                color: Color(0xFFEF4444),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        po.supplier,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: isDark
                                                              ? Colors.white.withValues(alpha: 0.08)
                                                              : Colors.grey.shade200,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          'PO #${po.id}',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Date: ${po.expectedDate.isEmpty ? "N/A" : po.expectedDate} • ${po.itemsCount} Items',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isItemNarrow) ...[
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _money(po.amountDue),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFEF4444),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                badgeWidget,
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (isItemNarrow) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            badgeWidget,
                                            Text(
                                              'Due: ${_money(po.amountDue)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFEF4444),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      // Progress bar & payment detail
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 4,
                                          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Paid: ${_money(po.amountPaid)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Total PO: ${_money(po.amount)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _selectedNavKey = 'purchaseOrders');
                  },
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Go to Purchase Orders'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showChequesDetailsDialog() {
    final issued =
        _scopedPurchaseOrders
            .where(
              (po) =>
                  po.paymentMethod.toUpperCase() == 'CHEQUE' &&
                  _matchesTimeFilter(
                    po.receivedAt ??
                        DateTime.tryParse(po.createdAt) ??
                        DateTime.now(),
                    _dashboardPeriod,
                  ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final received =
        _scopedSales
            .where(
              (s) =>
                  s.paymentMethod.toUpperCase() == 'CHEQUE' &&
                  _matchesTimeFilter(s.createdAt, _dashboardPeriod),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalIssued = issued.fold<double>(0.0, (sum, po) => sum + po.amount);
    final totalReceived = received.fold<double>(0.0, (sum, s) => sum + s.total);

    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.payments_rounded, color: Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              const Text('Cheque Registry Details'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: math.min(480.0, MediaQuery.of(context).size.height * 0.6),
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Received Cheques (Sales)'),
                    Tab(text: 'Issued Cheques (POs)'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Cheques Received:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _money(totalReceived),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: received.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No cheques received from customers.',
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: received.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(),
                                    itemBuilder: (context, idx) {
                                      final s = received[idx];
                                      return ListTile(
                                        title: Text(
                                          'Cheque #${s.chequeNumber.isEmpty ? "N/A" : s.chequeNumber}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Customer: ${s.customerName.isEmpty ? "Walk-in" : s.customerName}  •  Invoice: ${s.id}',
                                        ),
                                        trailing: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _money(s.total),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFF59E0B),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatDate(s.createdAt),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Cheques Issued:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _money(totalIssued),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: issued.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No cheques issued to suppliers.',
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: issued.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(),
                                    itemBuilder: (context, idx) {
                                      final po = issued[idx];
                                      // Extract cheque number from notes if possible
                                      String chNum = 'N/A';
                                      final notesLower = po.notes.toLowerCase();
                                      if (notesLower.contains('cheque #')) {
                                        final idx = notesLower.indexOf(
                                          'cheque #',
                                        );
                                        chNum = po.notes
                                            .substring(idx + 8)
                                            .split(' ')
                                            .first;
                                      } else if (po.notes.isNotEmpty) {
                                        chNum = po.notes;
                                      }
                                      return ListTile(
                                        title: Text(
                                          'Cheque / Ref: $chNum',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Supplier: ${po.supplier}  •  PO Ref: ${po.id}',
                                        ),
                                        trailing: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _money(po.amount),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFF59E0B),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              po.createdAt,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstallmentDetailsDialog() {
    final activePlans =
        _scopedInstallmentPlans
            .where(
              (p) =>
                  p.remainingAmount > 0 &&
                  _matchesTimeFilter(p.createdAt, _dashboardPeriod),
            )
            .toList()
          ..sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    final totalRemaining = _calculatedActiveInstallmentsRemainingForPeriod(
      _dashboardPeriod,
    );

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Active Installment Plans',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${activePlans.length} Active Plans Registered',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: ResponsiveLayout.adaptiveDialogWidth(context, 640.0),
            height: ResponsiveLayout.adaptiveDialogHeight(context, 580.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Summary Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Color(0xFF8B5CF6),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total Remaining Installment Capital',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _money(totalRemaining),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Plans Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Sorted by highest balance',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: activePlans.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 48,
                                  color: Colors.green.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No active installment plans.',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: activePlans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final plan = activePlans[idx];
                            // Find next unpaid installment due date
                            DateTime? nextDue;
                            final unpaidSchedules =
                                plan.schedules.where((s) => !s.isPaid).toList()
                                  ..sort(
                                    (a, b) => a.dueDate.compareTo(b.dueDate),
                                  );
                            if (unpaidSchedules.isNotEmpty) {
                              nextDue = unpaidSchedules.first.dueDate;
                            }

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, itemConstraints) {
                                  final isItemNarrow = itemConstraints.maxWidth < 380;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                            child: Text(
                                              plan.customerName.isNotEmpty
                                                  ? plan.customerName[0].toUpperCase()
                                                  : 'C',
                                              style: const TextStyle(
                                                color: Color(0xFF8B5CF6),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        plan.customerName.isEmpty
                                                            ? "Walk-in Customer"
                                                            : plan.customerName,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.white.withValues(alpha: 0.08)
                                                            : Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'Inv #${plan.saleId}',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${plan.numberOfInstallments} payments • Next Due: ${nextDue == null ? "N/A" : _formatDate(nextDue)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isItemNarrow) ...[
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _money(plan.remainingAmount),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF8B5CF6),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Total: ${_money(plan.totalAmount)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (isItemNarrow) ...[
                                        const SizedBox(height: 8),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          spacing: 8,
                                          runSpacing: 2,
                                          children: [
                                            Text(
                                              'Remaining: ${_money(plan.remainingAmount)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF8B5CF6),
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'Total Financed: ${_money(plan.totalAmount)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _selectedNavKey = 'installments');
                  },
                  icon: const Icon(Icons.install_desktop_rounded, size: 18),
                  label: const Text('Go to Installments Screen'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showCodDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          // Re-query/re-filter for real-time dialog updates
          final currentCodSales =
              _scopedSales
                  .where(
                    (s) =>
                        s.paymentMethod.toUpperCase() == 'COD' &&
                        _matchesTimeFilter(s.createdAt, _dashboardPeriod),
                  )
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final currentPending = currentCodSales
              .where((s) => s.status != 'COMPLETED')
              .toList();
          final currentCompleted = currentCodSales
              .where((s) => s.status == 'COMPLETED')
              .toList();
          final currentTotalPending = currentPending.fold<double>(
            0.0,
            (sum, s) => sum + s.total,
          );
          final currentTotalCompleted = currentCompleted.fold<double>(
            0.0,
            (sum, s) => sum + s.total,
          );

          Future<void> confirmDelivery(dynamic s) async {
            final saleRecord = s is _SaleRecord ? s : null;
            final invoiceLabel = saleRecord != null
                ? _formatDisplayInvoiceNumber(saleRecord)
                : 'Invoice #${s.id}';
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.point_of_sale_rounded, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text('Settle COD Cash into Register'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receive ${_money(s.total)} cash for $invoiceLabel?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'This officially records receipt of payment, marks the order COMPLETED, and credits cash into today\'s drawer Cash in Hand.',
                        style: TextStyle(fontSize: 12),
                      ),
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
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Confirm Cash Received'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              if (_saleRepository != null) {
                await _saleRepository!.completeCodDelivery(
                  saleId: s.id,
                  notes: 'Completed & settled via COD Dashboard Registry',
                );
                setState(() {
                  s.status = 'COMPLETED';
                  s.deliveryStatus = 'SETTLED';
                  s.amountPaid = s.total;
                  s.balance = 0.0;
                  final idx = _sales.indexWhere((x) => x.id == s.id);
                  if (idx >= 0) {
                    _sales[idx].status = 'COMPLETED';
                    _sales[idx].deliveryStatus = 'SETTLED';
                    _sales[idx].amountPaid = s.total;
                    _sales[idx].balance = 0.0;
                  }
                });
                await _loadCoreDataFromRepositories();
                setDialogState(() {});
                setState(() {});
              }
            }
          }

          return DefaultTabController(
            length: 2,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Color(0xFF06B6D4),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'COD Orders Registry',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${currentCodSales.length} Total Cash on Delivery Orders',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: ResponsiveLayout.adaptiveDialogWidth(context, 640.0),
                height: ResponsiveLayout.adaptiveDialogHeight(context, 580.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      labelColor: const Color(0xFF06B6D4),
                      unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                      indicatorColor: const Color(0xFF06B6D4),
                      tabs: [
                        Tab(text: 'Pending (${currentPending.length})'),
                        Tab(text: 'Completed (${currentCompleted.length})'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Pending Deliveries
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.local_shipping_outlined,
                                          color: Color(0xFF06B6D4),
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Total COD Outstanding (In Transit)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _money(currentTotalPending),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                          color: Color(0xFF06B6D4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: currentPending.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline_rounded,
                                                size: 48,
                                                color: Colors.green.withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'No pending COD deliveries.',
                                                style: TextStyle(
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: currentPending.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, idx) {
                                          final s = currentPending[idx];
                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.04)
                                                  : Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white10
                                                    : Colors.grey.shade200,
                                              ),
                                            ),
                                            child: LayoutBuilder(
                                              builder: (context, itemConstraints) {
                                                final isItemNarrow = itemConstraints.maxWidth < 380;

                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 18,
                                                          backgroundColor: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                                                          child: const Icon(
                                                            Icons.local_shipping_rounded,
                                                            color: Color(0xFF06B6D4),
                                                            size: 18,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      s.customerName.isEmpty ? "Walk-in Customer" : s.customerName,
                                                                      style: const TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 14,
                                                                      ),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 6),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal: 6,
                                                                      vertical: 2,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: isDark
                                                                          ? Colors.white.withValues(alpha: 0.08)
                                                                          : Colors.grey.shade200,
                                                                      borderRadius: BorderRadius.circular(4),
                                                                    ),
                                                                    child: Text(
                                                                      _formatDisplayInvoiceNumber(s),
                                                                      style: TextStyle(
                                                                        fontSize: 10,
                                                                        fontWeight: FontWeight.w700,
                                                                        color: isDark ? const Color(0xFF67E8F9) : const Color(0xFF0E7490),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 4),
                                                              if (s.shippingAddress.isNotEmpty)
                                                                Padding(
                                                                  padding: const EdgeInsets.only(bottom: 2),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons.location_on_outlined,
                                                                        size: 12,
                                                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                      Expanded(
                                                                        child: Text(
                                                                          s.shippingAddress,
                                                                          style: TextStyle(
                                                                            fontSize: 12,
                                                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                                          ),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              if (s.notes.isNotEmpty)
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons.notes_rounded,
                                                                      size: 12,
                                                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                                    ),
                                                                    const SizedBox(width: 4),
                                                                    Expanded(
                                                                      child: Text(
                                                                        s.notes,
                                                                        style: TextStyle(
                                                                          fontSize: 11,
                                                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                                        ),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (!isItemNarrow) ...[
                                                          const SizedBox(width: 10),
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              Text(
                                                                _money(s.total),
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Color(0xFF06B6D4),
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 4),
                                                              FilledButton.icon(
                                                                onPressed: () => confirmDelivery(s),
                                                                icon: const Icon(Icons.price_check_rounded, size: 14),
                                                                label: const Text('Settle Cash'),
                                                                style: FilledButton.styleFrom(
                                                                  backgroundColor: const Color(0xFF10B981),
                                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    if (isItemNarrow) ...[
                                                      const SizedBox(height: 8),
                                                      const Divider(height: 1),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            _money(s.total),
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFF06B6D4),
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          FilledButton.icon(
                                                            onPressed: () => confirmDelivery(s),
                                                            icon: const Icon(Icons.price_check_rounded, size: 14),
                                                            label: const Text('Settle Cash & Complete'),
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor: const Color(0xFF10B981),
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                          // Tab 2: Completed COD Deliveries
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: Color(0xFF10B981),
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Total COD Cash Collected',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _money(currentTotalCompleted),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: currentCompleted.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline_rounded,
                                                size: 48,
                                                color: Colors.green.withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'No completed COD transactions.',
                                                style: TextStyle(
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: currentCompleted.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, idx) {
                                          final s = currentCompleted[idx];
                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.04)
                                                  : Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white10
                                                    : Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                  child: const Icon(
                                                    Icons.check_circle_rounded,
                                                    color: Color(0xFF10B981),
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              s.customerName.isEmpty ? "Walk-in Customer" : s.customerName,
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: isDark
                                                                  ? Colors.white.withValues(alpha: 0.08)
                                                                  : Colors.grey.shade200,
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              _formatDisplayInvoiceNumber(s),
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w700,
                                                                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Delivered: ${_formatDate(s.createdAt)}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  _money(s.total),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF10B981),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getCashMovementsLog() {
    final movements = <Map<String, dynamic>>[];

    // 1. Cash Sales & COD completed sales
    for (final sale in _scopedSales) {
      if (sale.status == 'COMPLETED') {
        if (sale.paymentMethod.toUpperCase() == 'CASH' ||
            sale.paymentMethod.toUpperCase() == 'COD') {
          movements.add({
            'type': 'IN',
            'title': 'Completed Sale ${sale.id}',
            'subtitle':
                'Customer: ${sale.customerName.isEmpty ? "Walk-in" : sale.customerName} (${sale.paymentMethod})',
            'date': (sale.paymentMethod.toUpperCase() == 'COD' && sale.settledAt != null)
                ? sale.settledAt!
                : sale.createdAt,
            'amount': sale.total,
          });
        }
      }
    }

    // 2. Customer Credit payments (settlements)
    for (final customer in _scopedCustomers) {
      final payments = _customerCreditPayments[customer.id] ?? [];
      for (final p in payments) {
        movements.add({
          'type': 'IN',
          'title': 'Credit Settlement',
          'subtitle': 'Customer: ${customer.name}',
          'date': p.createdAt,
          'amount': p.amount,
        });
      }
    }

    // 3. Installments in Cash
    for (final plan in _scopedInstallmentPlans) {
      if (plan.paymentMethod.toUpperCase() == 'CASH') {
        movements.add({
          'type': 'IN',
          'title': 'Installment Down Payment',
          'subtitle': 'Plan ID: ${plan.id} (Customer: ${plan.customerName})',
          'date': plan.createdAt,
          'amount': plan.downPayment,
        });
        for (final schedule in plan.schedules) {
          if (schedule.isPaid && schedule.paidAt != null) {
            movements.add({
              'type': 'IN',
              'title': 'Installment Paid #${schedule.installmentNo}',
              'subtitle':
                  'Plan ID: ${plan.id} (Customer: ${plan.customerName})',
              'date': schedule.paidAt!,
              'amount': schedule.paidAmount,
            });
          }
        }
      }
    }

    // 4. Expenses & PO cash purchases
    for (final exp in _scopedExpenses) {
      final isPO = exp.category == 'STOCK_PURCHASE';
      if (_getExpensePaymentMethod(exp.notes) == 'CASH') {
        if (!isPO) {
          movements.add({
            'type': 'OUT',
            'title': 'Expense: ${exp.category}',
            'subtitle': _getExpenseNotes(exp.notes).isEmpty
                ? 'General expense'
                : _getExpenseNotes(exp.notes),
            'date': exp.expenseDate,
            'amount': exp.amount,
          });
        } else {
          movements.add({
            'type': 'OUT',
            'title': 'PO Cash Restock',
            'subtitle': exp.description.isNotEmpty
                ? exp.description
                : (_getExpenseNotes(exp.notes).isEmpty
                    ? 'Stock purchase'
                    : _getExpenseNotes(exp.notes)),
            'date': exp.expenseDate,
            'amount': exp.amount,
          });
        }
      }
    }

    // 5. Cash Refunds / Transactions (from returns page)
    for (final tx in _scopedCashTransactions) {
      final isIn = tx.type == 'IN';
      movements.add({
        'type': isIn ? 'IN' : 'OUT',
        'title': tx.note.isEmpty
            ? (isIn ? 'Cash Deposit' : 'Cash Withdrawal')
            : tx.note,
        'subtitle': isIn ? 'Manual Cash In' : 'Manual Cash Out / Refund',
        'date': DateTime.tryParse(tx.createdAt) ?? DateTime.now(),
        'amount': tx.amount,
      });
    }

    // Sort by date descending
    movements.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    return movements;
  }

  Widget _dialogValueRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            val,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showRevenueAndProfitDetailsDialog() {
    final List<_SaleRecord> salesScope = (_isCashier || _isAgent)
        ? _scopedSales.where((s) {
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
            } else {
              if (s.employeeId.isNotEmpty && _currentUserId.isNotEmpty) {
                return s.employeeId == _currentUserId;
              }
              return s.cashierName == _currentUserName;
            }
          }).toList()
        : _scopedSales;

    final periodSales = _salesForPeriod(_dashboardPeriod, salesScope);
    final validPeriodSales = periodSales.where((s) {
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

    final totalRefundedReturns = _returns.where((r) {
      if (r.status == 'Rejected') return false;
      if (r.refundMethod == 'NO_PAYOUT' || r.amount <= 0) return false;
      final rDate = DateTime.tryParse(r.createdAt) ?? DateTime.now();
      if (!_matchesTimeFilter(rDate, _dashboardPeriod)) return false;
      return true;
    }).fold<double>(0.0, (sum, r) => sum + r.amount);

    final totalRevenue = (validPeriodSales.fold<double>(
      0.0,
      (sum, s) => sum + s.total,
    ) - totalRefundedReturns).clamp(0.0, double.infinity);

    final productRevenue = validPeriodSales.fold<double>(
      0.0,
      (sum, s) => sum + _saleProductRevenue(s),
    );
    final serviceRevenue = validPeriodSales.fold<double>(
      0.0,
      (sum, s) => sum + _saleServiceRevenue(s),
    );

    // Calculate cost and profit
    double totalCost = 0.0;
    for (final sale in validPeriodSales) {
      for (final item in sale.items) {
        final prodIdx = _products.indexWhere((p) => p.id == item.productId);
        final unitCost = prodIdx >= 0
            ? _unitInventoryCost(_products[prodIdx])
            : 0.0;
        totalCost += unitCost * item.quantity;
      }
    }
    final totalProfit = (totalRevenue - totalCost).clamp(0.0, double.infinity);
    final profitMarginVal = totalRevenue == 0
        ? 0.0
        : (totalProfit / totalRevenue) * 100;

    // Payment breakdown
    final paymentBreakdown = <String, double>{};
    final paymentCounts = <String, int>{};
    for (final s in validPeriodSales) {
      final method = s.paymentMethod.trim().isEmpty
          ? 'Unknown'
          : s.paymentMethod;
      paymentBreakdown[method] = (paymentBreakdown[method] ?? 0.0) + s.total;
      paymentCounts[method] = (paymentCounts[method] ?? 0) + 1;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    Widget breakdownCard({
      required String title,
      required List<Widget> children,
    }) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E2D45)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      );
    }

    final paymentMethodCard = breakdownCard(
      title: 'REVENUE BY PAYMENT METHOD',
      children: [
        if (paymentBreakdown.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No sales recorded in this period.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ...paymentBreakdown.entries.map((entry) {
            final method = entry.key;
            final amount = entry.value;
            final count = paymentCounts[method] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    method.toUpperCase() == 'CASH'
                        ? Icons.money_rounded
                        : method.toUpperCase() == 'CARD'
                        ? Icons.credit_card_rounded
                        : method.toUpperCase() == 'COD'
                        ? Icons.local_shipping_rounded
                        : Icons.payment_rounded,
                    size: 15,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$method ($count)',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _money(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        const Divider(),
        _dialogValueRow('Total Inflow', _money(totalRevenue), isBold: true),
      ],
    );

    final profitabilityCard = breakdownCard(
      title: 'PROFITABILITY BREAKDOWN',
      children: [
        _dialogValueRow('Product Revenue', _money(productRevenue)),
        _dialogValueRow('Service Revenue', _money(serviceRevenue)),
        const Divider(),
        _dialogValueRow(
          'Total Revenue (A)',
          _money(totalRevenue),
          isBold: true,
        ),
        _dialogValueRow('Estimated Item Cost (B)', _money(totalCost)),
        const Divider(),
        _dialogValueRow(
          'Est. Net Profit (A - B)',
          _money(totalProfit),
          isBold: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profit Margin %',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: profitMarginVal >= 20
                      ? const Color(0xFF10B981).withOpacity(0.12)
                      : const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${profitMarginVal.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: profitMarginVal >= 20
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final isNarrow = screenSize.width < 700;
        final dialogWidth = isNarrow ? screenSize.width * 0.94 : 720.0;
        final dialogMaxHeight = screenSize.height * 0.86;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: dialogMaxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                    child: Row(
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
                          child: const Icon(Icons.analytics_rounded, size: 26),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Sales & Revenue Analysis',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  // ── Scrollable body ───────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Summary Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: UiGradients.brand,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: UiShadows.glow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL REVENUE',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _money(totalRevenue),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$_dashboardPeriod Sales Period • ${periodSales.length} Total Invoices',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Breakdown cards: side-by-side on wide screens,
                          // stacked on narrow (phone) screens.
                          if (isNarrow)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                paymentMethodCard,
                                const SizedBox(height: 14),
                                profitabilityCard,
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: paymentMethodCard),
                                const SizedBox(width: 14),
                                Expanded(child: profitabilityCard),
                              ],
                            ),
                          const SizedBox(height: 14),
                          // Explanatory note
                          Text(
                            '* Product costs are dynamically calculated based on the purchase cost prices registered for each product in your inventory at checkout. Service revenue carries no default product costs.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Footer actions ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: colorScheme.outline),
                      ),
                    ),
                    child: isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Close'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() => _selectedNavKey = 'reports');
                                },
                                icon: const Icon(
                                  Icons.insert_chart_outlined,
                                  size: 18,
                                ),
                                label: const Text('Go to Reports Page'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() => _selectedNavKey = 'reports');
                                },
                                icon: const Icon(
                                  Icons.insert_chart_outlined,
                                  size: 18,
                                ),
                                label: const Text('Go to Reports Page'),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Close'),
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
  }

  void _showEmployeeCostDetailsDialog() {
    final activeList = _scopedEmployees.where((e) => e.active).toList()
      ..sort((a, b) => b.baseSalary.compareTo(a.baseSalary));
    double totalBaseSalary = activeList.fold<double>(
      0.0,
      (sum, e) => sum + e.baseSalary,
    );
    if (totalBaseSalary == 0.0 && _payrollRecords.isNotEmpty) {
      totalBaseSalary = _payrollRecords.fold<double>(
        0.0,
        (sum, r) => sum + (r.grossPay > 0 ? r.grossPay : r.baseSalary),
      );
    }
    if (totalBaseSalary == 0.0) {
      totalBaseSalary = _scopedExpenses
          .where((x) =>
              x.category.toLowerCase().contains('salary') ||
              x.category.toLowerCase().contains('payroll') ||
              (x.notes ?? '').toLowerCase().contains('salary') ||
              (x.notes ?? '').toLowerCase().contains('payroll'))
          .fold<double>(0.0, (sum, x) => sum + x.amount);
    }

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: Color(0xFF6366F1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Employee Cost Directory',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${activeList.length} Active Staff Members Registered',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: ResponsiveLayout.adaptiveDialogWidth(context, 640.0),
            height: ResponsiveLayout.adaptiveDialogHeight(context, 580.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cost Summary Header Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.payments_outlined,
                            color: Color(0xFF6366F1),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total Base Salary Expenditure (Monthly)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _money(totalBaseSalary),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Staff Directory',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Sorted by base salary',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: activeList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 48,
                                  color: Colors.indigo.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No active employees registered.',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: activeList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final e = activeList[idx];

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, itemConstraints) {
                                  final isItemNarrow = itemConstraints.maxWidth < 380;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                            child: Text(
                                              e.name.isNotEmpty
                                                  ? e.name[0].toUpperCase()
                                                  : 'E',
                                              style: const TextStyle(
                                                color: Color(0xFF6366F1),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        e.name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.white.withValues(alpha: 0.08)
                                                            : Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        e.role.isEmpty ? 'Staff' : e.role,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Position: ${e.position.isEmpty ? "N/A" : e.position}  •  Dept: ${e.department.isEmpty ? "N/A" : e.department}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (e.phone.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.phone_outlined,
                                                        size: 11,
                                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        e.phone,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (!isItemNarrow) ...[
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _money(e.baseSalary),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF6366F1),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Base Monthly',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (isItemNarrow) ...[
                                        const SizedBox(height: 8),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Base Monthly Salary:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              _money(e.baseSalary),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF6366F1),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _selectedNavKey = 'employees');
                  },
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: const Text('Go to Employees page'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial Metric Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _FinancialMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onViewDetails;
  final Color themeColor;
  final String subtitle;

  const _FinancialMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onViewDetails,
    required this.themeColor,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? themeColor.withOpacity(0.25)
              : themeColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top color accent bar
              Container(height: 4, color: themeColor),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: themeColor, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: onViewDetails,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: themeColor,
                            ),
                          ],
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
}
