part of '../dashboard_screen.dart';

extension _payroll_pageExt on _DashboardScreenState {
  Widget _buildPayrollPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalRecords = _payrollRecords.length;
    final pendingRecords = _payrollRecords
        .where((r) => r.status == 'Pending')
        .length;
    final paidRecords = _payrollRecords.where((r) => r.status == 'Paid').length;
    final pendingAmount = _payrollRecords
        .where((r) => r.status == 'Pending')
        .fold<double>(0, (sum, r) => sum + r.netPay);
    final totalPaid = _payrollRecords
        .where((r) => r.status == 'Paid')
        .fold<double>(0, (sum, r) => sum + r.netPay);

    final softBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE8EAF2);
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final pageBg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF7F8FC);

    Future<void> markPaid(_PayrollRecordItem r) async {
      setState(() => r.status = 'Paid');
      await _persistWorkspaceData();
      await _enqueueSync('UPDATE', 'payroll', r.id);
    }

    Future<void> editRecord(_PayrollRecordItem r) async {
      final edited = await _showPayrollDialog(existing: r);
      if (edited == null || !mounted) return;
      setState(() {
        final idx = _payrollRecords.indexWhere((x) => x.id == r.id);
        if (idx >= 0) _payrollRecords[idx] = edited;
      });
      await _persistWorkspaceData();
      await _enqueueSync('UPDATE', 'payroll', edited.id);
    }

    Future<void> deleteRecord(_PayrollRecordItem r) async {
      setState(() {
        _payrollRecords.removeWhere((x) => x.id == r.id);
      });
      await _persistWorkspaceData();
      await _enqueueSync('DELETE', 'payroll', r.id);
    }

    Future<void> addRecord() async {
      final payroll = await _showPayrollDialog();
      if (payroll == null || !mounted) return;
      setState(() => _payrollRecords.insert(0, payroll));
      await _persistWorkspaceData();
      await _enqueueSync('INSERT', 'payroll', payroll.id);
    }

    Widget metricCard({
      required String label,
      required String value,
      required IconData icon,
      required Color accent,
    }) {
      return Container(
        constraints: const BoxConstraints(minWidth: 140, minHeight: 96),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(UiRadius.lg),
          border: Border.all(color: softBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    Widget actionChip({
      required String tooltip,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: color.withValues(alpha: isDark ? 0.16 : 0.1),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 16, color: color),
            ),
          ),
        ),
      );
    }

    Widget payrollRecordCard(_PayrollRecordItem r) {
      final isPaid = r.status == 'Paid';
      final statusColor = isPaid
          ? const Color(0xFF10B981)
          : const Color(0xFFF59E0B);
      final initials = r.employeeName
          .trim()
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .take(2)
          .map((p) => p[0].toUpperCase())
          .join();

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(UiRadius.lg),
          border: Border.all(color: softBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF6366F1,
                    ).withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFC7D2FE)
                          : const Color(0xFF4F46E5),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.employeeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StatusChip(
                            label: r.status.toUpperCase(),
                            color: statusColor,
                            icon: isPaid
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${r.paymentType}  ·  ${r.payPeriodStart} → ${r.payPeriodEnd}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: pageBg,
                borderRadius: BorderRadius.circular(UiRadius.md),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _payrollMeta(
                    'Days',
                    '${r.daysWorked}',
                    Icons.calendar_today_outlined,
                    colorScheme,
                  ),
                  _payrollMeta(
                    'Hours',
                    r.hoursWorked.toStringAsFixed(1),
                    Icons.schedule_outlined,
                    colorScheme,
                  ),
                  _payrollMeta(
                    'Gross',
                    _money(r.grossPay),
                    Icons.trending_up_rounded,
                    colorScheme,
                  ),
                  _payrollMeta(
                    'Net Pay',
                    _money(r.netPay),
                    Icons.payments_outlined,
                    colorScheme,
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (r.payDate.isNotEmpty)
                  Flexible(
                    child: Text(
                      'Pay date: ${r.payDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                const Spacer(),
                if (!isPaid) ...[
                  actionChip(
                    tooltip: 'Mark as Paid',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                    onPressed: () => markPaid(r),
                  ),
                  const SizedBox(width: 8),
                ],
                actionChip(
                  tooltip: 'Edit',
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF6366F1),
                  onPressed: () => editRecord(r),
                ),
                const SizedBox(width: 8),
                actionChip(
                  tooltip: 'Delete',
                  icon: Icons.delete_outline,
                  color: colorScheme.error,
                  onPressed: () => deleteRecord(r),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Full page scrolls as one view — no Expanded nested layout that
    // overflows and paints yellow/black debug stripes at the bottom.
    return ColoredBox(
      color: pageBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final cols = maxW >= 1100
              ? 4
              : maxW >= 700
              ? 2
              : 1;
          final gap = 12.0;
          final cardW = cols == 1
              ? maxW - 40
              : ((maxW - 40) - gap * (cols - 1)) / cols;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 720;
                      final titleBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: narrow ? 40 : 44,
                                height: narrow ? 40 : 44,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: isDark ? 0.25 : 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: narrow ? 20 : 22,
                                  color: isDark
                                      ? const Color(0xFFC7D2FE)
                                      : const Color(0xFF4F46E5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Payroll Management',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: narrow ? 22 : 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage employee payroll, compensation and pay cycles.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      );

                      final actions = Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Monthly payroll generated'),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  UiRadius.md,
                                ),
                              ),
                              side: BorderSide(color: softBorder),
                            ),
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text(
                              'Generate Monthly',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: addRecord,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  UiRadius.md,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                            ),
                            label: const Text(
                              'Add Payroll',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      );

                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleBlock,
                            const SizedBox(height: 14),
                            actions,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: titleBlock),
                          actions,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: cardW,
                        child: metricCard(
                          label: 'Total Records',
                          value: '$totalRecords',
                          icon: Icons.receipt_long_rounded,
                          accent: const Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(
                        width: cardW,
                        child: metricCard(
                          label: 'Pending Records',
                          value: '$pendingRecords',
                          icon: Icons.hourglass_top_rounded,
                          accent: const Color(0xFFF59E0B),
                        ),
                      ),
                      SizedBox(
                        width: cardW,
                        child: metricCard(
                          label: 'Pending Amount',
                          value: _money(pendingAmount),
                          icon: Icons.pending_actions_rounded,
                          accent: const Color(0xFFEF4444),
                        ),
                      ),
                      SizedBox(
                        width: cardW,
                        child: metricCard(
                          label: 'Total Paid',
                          value: _money(totalPaid),
                          icon: Icons.verified_rounded,
                          accent: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Text(
                        'Employee Payroll',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(UiRadius.pill),
                        ),
                        child: Text(
                          '$totalRecords',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (paidRecords > 0)
                        Text(
                          '$paidRecords paid',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_payrollRecords.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: isDark
                                  ? const Color(0xFFC7D2FE)
                                  : const Color(0xFF4F46E5),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No payroll records yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add a payroll entry or generate monthly cycle.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: addRecord,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  UiRadius.md,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                            ),
                            label: const Text(
                              'Add Payroll',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._payrollRecords.map(payrollRecordCard),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
      ),
    );
  }

  Widget _payrollMeta(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme, {
    bool emphasize = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: emphasize
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: emphasize ? 14 : 13,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: emphasize ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
