part of '../dashboard_screen.dart';

class BankRegistersPage extends StatefulWidget {
  final String currencySymbol;
  final List<_CashierSession> cashierSessions;
  final List<_BankTransaction> bankTransactions;
  final double bankAccountBalance;
  final Function(double, String, String) onAddManualTransaction;
  final Function(
    _CashierSession,
    double, {
    double? payoutAmount,
    String? payoutReason,
    double keptCash,
  })
  onCloseSession;
  final Map<String, double> Function(_CashierSession)
  onCalculateSessionBreakdown;
  final List<_UserItem> appUsers;

  const BankRegistersPage({
    super.key,
    required this.currencySymbol,
    required this.cashierSessions,
    required this.bankTransactions,
    required this.bankAccountBalance,
    required this.onAddManualTransaction,
    required this.onCloseSession,
    required this.onCalculateSessionBreakdown,
    required this.appUsers,
  });

  @override
  State<BankRegistersPage> createState() => _BankRegistersPageState();
}

class _BankRegistersPageState extends State<BankRegistersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _txType = 'MANUAL_DEPOSIT';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showAddTransactionDialog() {
    _amountCtrl.clear();
    _notesCtrl.clear();
    _txType = 'MANUAL_DEPOSIT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Bank Transaction',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _txType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'MANUAL_DEPOSIT',
                    child: Text('Manual Deposit (+)'),
                  ),
                  DropdownMenuItem(
                    value: 'MANUAL_WITHDRAW',
                    child: Text('Manual Withdrawal (-)'),
                  ),
                ],
                onChanged: (v) => setS(() => _txType = v ?? 'MANUAL_DEPOSIT'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (${widget.currencySymbol})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes / Reference',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amt = double.tryParse(_amountCtrl.text) ?? 0.0;
                if (amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive amount'),
                    ),
                  );
                  return;
                }
                widget.onAddManualTransaction(
                  amt,
                  _txType,
                  _notesCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 640;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bank & Register Management',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Track shift register drawer balances and bank account transactions',
                    maxLines: narrow ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              );
              final tabs = SizedBox(
                width: narrow ? double.infinity : 280,
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Bank Ledger'),
                    Tab(text: 'Cashier Shifts'),
                  ],
                ),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleBlock, const SizedBox(height: 12), tabs],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  tabs,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBankLedgerTab(isDark),
                _buildCashierShiftsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankLedgerTab(bool isDark) {
    final style = Theme.of(context).textTheme;

    return Column(
      children: [
        // Bank Balance Overview Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: UiGradients.brand,
            borderRadius: BorderRadius.circular(16),
            boxShadow: UiShadows.glow,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'BANK ACCOUNT BALANCE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.currencySymbol} ${widget.bankAccountBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _showAddTransactionDialog,
                icon: const Icon(Icons.add_card_rounded, color: Colors.indigo),
                label: const Text(
                  'Add Transaction',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Transactions List
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Transaction History',
            style: style.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2D45)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: UiShadows.card,
            ),
            child: widget.bankTransactions.isEmpty
                ? const Center(
                    child: Text('No bank transactions recorded yet.'),
                  )
                : ListView.separated(
                    itemCount: widget.bankTransactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final tx = widget.bankTransactions[idx];
                      final isDeposit =
                          tx.type == 'CLOSE_SHIFT_DEPOSIT' ||
                          tx.type == 'MANUAL_DEPOSIT';
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDeposit
                                ? const Color(0xFF10B981).withOpacity(0.12)
                                : const Color(0xFFEF4444).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDeposit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: isDeposit
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          _getTxTypeLabel(tx.type),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${tx.notes}  •  ${_formatDateTime(tx.createdAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${isDeposit ? "+" : "-"}${widget.currencySymbol} ${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDeposit
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashierShiftsTab(bool isDark) {
    final Widget content = widget.cashierSessions.isEmpty
        ? const Center(child: Text('No cashier shifts recorded yet.'))
        : ListView.separated(
            itemCount: widget.cashierSessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final s = widget.cashierSessions[idx];
              final isOpen = s.status == 'OPEN';
              final breakdown = widget.onCalculateSessionBreakdown(s);

              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: isOpen
                      ? const Color(0xFF10B981).withOpacity(0.12)
                      : Colors.grey.withOpacity(0.12),
                  child: Icon(
                    isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: isOpen ? const Color(0xFF10B981) : Colors.grey,
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOpen ? 'OPEN SHIFT' : 'CLOSED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? const Color(0xFF10B981) : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Opened: ${_formatDateTime(s.openingTime)}${s.closingTime != null ? "  •  Closed: ${_formatDateTime(s.closingTime!)}" : ""}\nExpected Drawer Cash: ${widget.currencySymbol} ${breakdown['expected']!.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11.5),
                ),
                trailing: isOpen
                    ? FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 14),
                        label: const Text(
                          'Close Shift',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _showCloseShiftDialog(s),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Closing: ${widget.currencySymbol} ${(s.closingCash ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (s.difference != null && s.difference != 0)
                            Text(
                              s.difference! > 0
                                  ? 'Over: +${widget.currencySymbol} ${s.difference!.toStringAsFixed(2)}'
                                  : 'Short: -${widget.currencySymbol} ${s.difference!.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: s.difference! > 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            )
                          else
                            const Text(
                              'Balanced',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Session Details & Breakdown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _dialogValueRow(
                                    'Opening Cash',
                                    '${widget.currencySymbol} ${breakdown['opening']!.toStringAsFixed(2)}',
                                  ),
                                  _dialogValueRow(
                                    'Cash Sales',
                                    '+ ${widget.currencySymbol} ${breakdown['cashSales']!.toStringAsFixed(2)}',
                                  ),
                                  if (breakdown['codSales']! > 0)
                                    _dialogValueRow(
                                      'COD Completed',
                                      '+ ${widget.currencySymbol} ${breakdown['codSales']!.toStringAsFixed(2)}',
                                    ),
                                  _dialogValueRow(
                                    'Credit Payments (Cash)',
                                    '+ ${widget.currencySymbol} ${breakdown['creditCollected']!.toStringAsFixed(2)}',
                                  ),
                                  _dialogValueRow(
                                    'Installments (Cash)',
                                    '+ ${widget.currencySymbol} ${breakdown['installmentsCollected']!.toStringAsFixed(2)}',
                                  ),
                                  if (breakdown['cashTransfers']! > 0)
                                    _dialogValueRow(
                                      'Transfers IN (Drawer)',
                                      '+ ${widget.currencySymbol} ${breakdown['cashTransfers']!.toStringAsFixed(2)}',
                                    ),
                                  if (breakdown['drawerExpenses']! > 0)
                                    _dialogValueRow(
                                      'Drawer Expenses',
                                      '- ${widget.currencySymbol} ${breakdown['drawerExpenses']!.toStringAsFixed(2)}',
                                      isNegative: true,
                                    ),
                                  if (breakdown['cashRefunds']! > 0)
                                    _dialogValueRow(
                                      'Refunds / Cash OUT',
                                      '- ${widget.currencySymbol} ${breakdown['cashRefunds']!.toStringAsFixed(2)}',
                                      isNegative: true,
                                    ),
                                  const Divider(),
                                  _dialogValueRow(
                                    'Expected Drawer Cash',
                                    '${widget.currencySymbol} ${breakdown['expected']!.toStringAsFixed(2)}',
                                    isNegative: false,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _dialogValueRow(
                                    'Card Sales',
                                    '${widget.currencySymbol} ${breakdown['cardSales']!.toStringAsFixed(2)}',
                                  ),
                                  _dialogValueRow(
                                    'Unpaid Credit Sales',
                                    '${widget.currencySymbol} ${breakdown['creditSales']!.toStringAsFixed(2)}',
                                  ),
                                  _dialogValueRow(
                                    'Unpaid Installment Sales',
                                    '${widget.currencySymbol} ${breakdown['installmentSales']!.toStringAsFixed(2)}',
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
              );
            },
          );

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Register Drawer Sessions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2D45)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: UiShadows.card,
            ),
            child: content,
          ),
        ),
      ],
    );
  }

  void _showCloseShiftDialog(_CashierSession session) {
    final breakdown = widget.onCalculateSessionBreakdown(session);
    final actualCtrl = TextEditingController();
    final keptCashCtrl = TextEditingController(text: '0.0');
    final payoutAmountCtrl = TextEditingController();
    final payoutReasonCtrl = TextEditingController();
    bool hasPayout = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final baseExpected = breakdown['expected'] ?? 0.0;
          double currentExpected = baseExpected;
          if (hasPayout) {
            final amt = double.tryParse(payoutAmountCtrl.text) ?? 0.0;
            currentExpected = baseExpected - amt;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Close Cashier Shift — ${session.userName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: ResponsiveLayout.adaptiveDialogWidth(context, 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Expected Cash Highlight Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Expected Cash in Drawer:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.currencySymbol} ${currentExpected.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cash Drawer Flow Card
                    const Text(
                      'Cash Drawer Flow (In Drawer)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _dialogValueRow(
                              'Opening Cash',
                              '${widget.currencySymbol} ${breakdown['opening']!.toStringAsFixed(2)}',
                            ),
                            _dialogValueRow(
                              'Cash Sales',
                              '+ ${widget.currencySymbol} ${breakdown['cashSales']!.toStringAsFixed(2)}',
                            ),
                            if (breakdown['codSales']! > 0)
                              _dialogValueRow(
                                'COD Completed',
                                '+ ${widget.currencySymbol} ${breakdown['codSales']!.toStringAsFixed(2)}',
                              ),
                            _dialogValueRow(
                              'Credit Payments',
                              '+ ${widget.currencySymbol} ${breakdown['creditCollected']!.toStringAsFixed(2)}',
                            ),
                            _dialogValueRow(
                              'Installments Collected',
                              '+ ${widget.currencySymbol} ${breakdown['installmentsCollected']!.toStringAsFixed(2)}',
                            ),
                            if (breakdown['cashTransfers']! > 0)
                              _dialogValueRow(
                                'Transfers IN',
                                '+ ${widget.currencySymbol} ${breakdown['cashTransfers']!.toStringAsFixed(2)}',
                              ),
                            if (breakdown['drawerExpenses']! > 0)
                              _dialogValueRow(
                                'Drawer Expenses',
                                '- ${widget.currencySymbol} ${breakdown['drawerExpenses']!.toStringAsFixed(2)}',
                                isNegative: true,
                              ),
                            if (breakdown['cashRefunds']! > 0)
                              _dialogValueRow(
                                'Refunds / Cash OUT',
                                '- ${widget.currencySymbol} ${breakdown['cashRefunds']!.toStringAsFixed(2)}',
                                isNegative: true,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Taken Money (Payout) Section
                    CheckboxListTile(
                      title: const Text(
                        'Took money from drawer during this shift?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Record drawer payout for expenses/misc usage',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: hasPayout,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          hasPayout = val ?? false;
                          if (!hasPayout) {
                            payoutAmountCtrl.clear();
                            payoutReasonCtrl.clear();
                          }
                        });
                      },
                    ),
                    if (hasPayout) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: payoutAmountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Taken Amount *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: payoutReasonCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Reason / Notes *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Non-Cash / Informational breakdown
                    const Text(
                      'Other Session Payments (Not in Drawer)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _dialogValueRow(
                              'Card Sales',
                              '${widget.currencySymbol} ${breakdown['cardSales']!.toStringAsFixed(2)}',
                            ),
                            _dialogValueRow(
                              'Unpaid Credit Sales',
                              '${widget.currencySymbol} ${breakdown['creditSales']!.toStringAsFixed(2)}',
                            ),
                            _dialogValueRow(
                              'Unpaid Installment Sales',
                              '${widget.currencySymbol} ${breakdown['installmentSales']!.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input Field for counting
                    TextFormField(
                      controller: actualCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Actual Drawer Cash Counted *',
                        border: const OutlineInputBorder(),
                        prefixText: '${widget.currencySymbol} ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Input Field for kept cash
                    TextFormField(
                      controller: keptCashCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) => setState(() {}),
                      decoration: InputDecoration(
                        labelText:
                            'Cash to Keep in Drawer (Next Session Change)',
                        border: const OutlineInputBorder(),
                        prefixText: '${widget.currencySymbol} ',
                        helperText:
                            'This amount will remain in the drawer for the next shift and will NOT be deposited into the bank.',
                      ),
                    ),

                    // Display dynamic Net Bank Deposit Portion
                    if (actualCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final actVal =
                              double.tryParse(actualCtrl.text) ?? 0.0;
                          final keptVal =
                              double.tryParse(keptCashCtrl.text) ?? 0.0;
                          final depositVal = (actVal - keptVal).clamp(
                            0.0,
                            double.infinity,
                          );
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Net Bank Deposit Portion:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${widget.currencySymbol} ${depositVal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
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
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                ),
                onPressed: () async {
                  final act = double.tryParse(actualCtrl.text);
                  if (act == null || act < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid cash amount counted',
                        ),
                      ),
                    );
                    return;
                  }

                  final kept = double.tryParse(keptCashCtrl.text) ?? 0.0;
                  if (kept < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kept cash cannot be negative'),
                      ),
                    );
                    return;
                  }
                  if (kept > act) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Kept cash cannot exceed total counted cash',
                        ),
                      ),
                    );
                    return;
                  }

                  double payoutAmt = 0.0;
                  String? payoutReason;
                  if (hasPayout) {
                    payoutAmt = double.tryParse(payoutAmountCtrl.text) ?? 0.0;
                    payoutReason = payoutReasonCtrl.text.trim();
                    if (payoutAmt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid taken amount'),
                        ),
                      );
                      return;
                    }
                    if (payoutReason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a reason for the drawer payout',
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  final expectedWithPayout = baseExpected - payoutAmt;
                  if (act < expectedWithPayout) {
                    final diff = expectedWithPayout - act;
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (wCtx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Drawer Shortage Warning',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        content: Text(
                          'Counted cash (${widget.currencySymbol} ${act.toStringAsFixed(2)}) is LESS than expected cash (${widget.currencySymbol} ${expectedWithPayout.toStringAsFixed(2)}).\n\nDrawer is SHORT by: ${widget.currencySymbol} ${diff.toStringAsFixed(2)}\n\nAre you sure you want to close this shift with a shortage?',
                          style: const TextStyle(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(wCtx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                            onPressed: () => Navigator.pop(wCtx, true),
                            child: const Text('Yes, Close Shift'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;
                  }

                  widget.onCloseSession(
                    session,
                    act,
                    payoutAmount: hasPayout ? payoutAmt : null,
                    payoutReason: hasPayout ? payoutReason : null,
                    keptCash: kept,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Confirm Close & Deposit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dialogValueRow(
    String label,
    String value, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isNegative ? const Color(0xFFEF4444) : null,
            ),
          ),
        ],
      ),
    );
  }

  String _getTxTypeLabel(String type) {
    switch (type) {
      case 'OPEN_SHIFT_WITHDRAW':
        return 'Shift Open Drawer Payout';
      case 'CLOSE_SHIFT_DEPOSIT':
        return 'Shift Close Drawer Deposit';
      case 'EXPENSE_PAYMENT':
        return 'General Expense Paid';
      case 'PO_PAYMENT':
        return 'Purchase Order Paid';
      case 'MANUAL_DEPOSIT':
        return 'Manual Bank Deposit';
      case 'MANUAL_WITHDRAW':
        return 'Manual Bank Withdrawal';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
