part of '../dashboard_screen.dart';

class BankRegistersPage extends StatefulWidget {
  final String currencySymbol;
  final List<_CashierSession> cashierSessions;
  final List<_BankTransaction> bankTransactions;
  final double bankAccountBalance;
  final double cashInHand;
  final bool isAdminOrOwner;
  final Function(double, String, String) onAddManualTransaction;
  final Function(
    _CashierSession,
    double, {
    double? payoutAmount,
    String? payoutReason,
    double keptCash,
    String? notes,
  })
  onCloseSession;
  final Function(_CashierSession) onApproveCloseSession;
  final Function(_CashierSession, {String? reason}) onRejectCloseSession;
  final Function(String, String, double) onOpenSession;
  final Map<String, double> Function(_CashierSession)
  onCalculateSessionBreakdown;
  final List<_UserItem> appUsers;
  final String storeName;
  final List<db.Expense> scopedExpenses;

  const BankRegistersPage({
    super.key,
    required this.currencySymbol,
    required this.cashierSessions,
    required this.bankTransactions,
    required this.bankAccountBalance,
    required this.cashInHand,
    required this.isAdminOrOwner,
    required this.onAddManualTransaction,
    required this.onCloseSession,
    required this.onApproveCloseSession,
    required this.onRejectCloseSession,
    required this.onOpenSession,
    required this.onCalculateSessionBreakdown,
    required this.appUsers,
    this.storeName = 'Main Branch',
    this.scopedExpenses = const [],
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
  String _reportPeriod = 'TODAY'; // 'TODAY', 'THIS_MONTH', 'THIS_YEAR', 'CUSTOM'
  DateTime _reportCustomStart = DateTime.now();
  DateTime _reportCustomEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                width: narrow ? double.infinity : 420,
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Bank Ledger'),
                    Tab(text: 'Cashier Shifts'),
                    Tab(text: 'Register Report'),
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
                _buildRegisterReportTab(isDark),
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
        // Bank & Till Balance Overview Card
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
            runSpacing: 14,
            children: [
              Wrap(
                spacing: 28,
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.currencySymbol} ${widget.bankAccountBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 46,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'DRAWER CASH IN HAND (TILLS)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.currencySymbol} ${widget.cashInHand.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
    final pendingSessions = widget.cashierSessions
        .where((s) => s.status == 'PENDING_APPROVAL')
        .toList();

    final Widget listContent = widget.cashierSessions.isEmpty
        ? const Center(child: Text('No cashier shifts recorded yet.'))
        : ListView.separated(
            itemCount: widget.cashierSessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final s = widget.cashierSessions[idx];
              final isOpen = s.status == 'OPEN';
              final isPending = s.status == 'PENDING_APPROVAL';
              final breakdown = widget.onCalculateSessionBreakdown(s);

              final Color statusColor = isOpen
                  ? const Color(0xFF10B981)
                  : isPending
                      ? Colors.amber.shade700
                      : Colors.grey;

              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Icon(
                    isOpen
                        ? Icons.lock_open_rounded
                        : isPending
                            ? Icons.hourglass_top_rounded
                            : Icons.lock_rounded,
                    color: statusColor,
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
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOpen
                            ? 'OPEN SHIFT'
                            : isPending
                                ? 'PENDING APPROVAL'
                                : 'CLOSED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  isOpen
                      ? 'Opened: ${_formatDateTime(s.openingTime)}\nExpected Drawer Cash: ${widget.currencySymbol} ${breakdown['expected']!.toStringAsFixed(2)}'
                      : isPending
                          ? 'Close Requested by ${s.closeRequestedBy ?? s.userName}\nCounted: ${widget.currencySymbol} ${(s.actualCash ?? 0).toStringAsFixed(2)}  •  Expected: ${widget.currencySymbol} ${s.expectedCash.toStringAsFixed(2)}'
                          : 'Opened: ${_formatDateTime(s.openingTime)}${s.closingTime != null ? "  •  Closed: ${_formatDateTime(s.closingTime!)}" : ""}\nExpected: ${widget.currencySymbol} ${s.expectedCash.toStringAsFixed(2)}  •  Counted: ${widget.currencySymbol} ${(s.actualCash ?? s.closingCash ?? 0).toStringAsFixed(2)}',
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
                    : isPending
                        ? (widget.isAdminOrOwner
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Approve',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () async {
                                      await widget.onApproveCloseSession(s);
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Recount',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    onPressed: () async {
                                      await widget.onRejectCloseSession(s);
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Awaiting Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ))
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
                        if (s.closingNotes != null &&
                            s.closingNotes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Notes: ${s.closingNotes}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _dialogValueRow(
                                    'Opening Float',
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
                                  const Divider(),
                                  _dialogValueRow(
                                    'Total Turnover (All)',
                                    '${widget.currencySymbol} ${(breakdown['totalSales'] ?? (breakdown['cashSales']! + breakdown['cardSales']!)).toStringAsFixed(2)}',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Register Drawer Sessions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text(
                'Open New Shift',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: _showOpenShiftDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pendingSessions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pendingSessions.length} cashier shift(s) awaiting Admin close approval.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            child: listContent,
          ),
        ),
      ],
    );
  }

  void _showOpenShiftDialog() {
    String selectedUserId = widget.appUsers.isNotEmpty
        ? widget.appUsers.first.id
        : 'CASHIER-1';
    String selectedUserName = widget.appUsers.isNotEmpty
        ? widget.appUsers.first.name
        : 'Cashier';
    final ctrl = TextEditingController(text: '5000.00');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Open New Shift Session',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedUserId,
                  decoration: const InputDecoration(
                    labelText: 'Cashier / Staff Member',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.appUsers
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.name} (${u.role})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDlgState(() {
                        selectedUserId = val;
                        selectedUserName = widget.appUsers
                            .firstWhere((u) => u.id == val)
                            .name;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        'Starting Cash Float (${widget.currencySymbol})*',
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
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                onPressed: () {
                  final amt = double.tryParse(ctrl.text.trim()) ?? 0.0;
                  widget.onOpenSession(selectedUserId, selectedUserName, amt);
                  Navigator.pop(ctx);
                },
                child: const Text('Open Shift'),
              ),
            ],
          );
        },
      ),
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
                child: Text(
                  widget.isAdminOrOwner
                      ? 'Confirm Close & Deposit'
                      : 'Submit Shift Close Request',
                ),
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
        return 'General Expense Paid (Bank)';
      case 'DRAWER_EXPENSE':
        return 'Cash Drawer Expense Paid';
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

  (DateTime, DateTime) _getReportDateRange() {
    final now = DateTime.now();
    switch (_reportPeriod) {
      case 'TODAY':
        return (
          DateTime(now.year, now.month, now.day, 0, 0, 0),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'THIS_MONTH':
        return (
          DateTime(now.year, now.month, 1, 0, 0, 0),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case 'THIS_YEAR':
        return (
          DateTime(now.year, 1, 1, 0, 0, 0),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case 'CUSTOM':
      default:
        return (
          DateTime(_reportCustomStart.year, _reportCustomStart.month, _reportCustomStart.day, 0, 0, 0),
          DateTime(_reportCustomEnd.year, _reportCustomEnd.month, _reportCustomEnd.day, 23, 59, 59),
        );
    }
  }

  Widget _periodChip(String label, String value) {
    final selected = _reportPeriod == value;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
        fontSize: 12,
      ),
      selectedColor: const Color(0xFF4F46E5),
      onSelected: (_) => setState(() => _reportPeriod = value),
    );
  }

  Widget _reportKpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark, {
    String? subtitle,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
        ),
        boxShadow: UiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterReportTab(bool isDark) {
    final (startDate, endDate) = _getReportDateRange();

    // 1. Filter sessions
    final sessions = widget.cashierSessions.where((s) {
      return s.openingTime.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
             s.openingTime.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    // 2. Filter transactions
    final transactions = widget.bankTransactions.where((t) {
      return t.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
             t.createdAt.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    // 3. Filter scoped expenses
    final expenses = widget.scopedExpenses.where((e) {
      return e.expenseDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
             e.expenseDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    double totalCashSales = 0.0;
    double totalOpeningFloats = 0.0;
    double totalDrawerExpenses = 0.0;
    double totalExpectedCash = 0.0;
    double totalActualCash = 0.0;
    double totalDiscrepancy = 0.0;
    int completedShifts = 0;

    for (final s in sessions) {
      final bd = widget.onCalculateSessionBreakdown(s);
      totalOpeningFloats += s.openingCash;
      totalCashSales += bd['cashSales'] ?? 0.0;
      totalDrawerExpenses += bd['drawerExpenses'] ?? 0.0;
      totalExpectedCash += bd['expected'] ?? s.openingCash;
      if (s.status == 'CLOSED' || s.status == 'PENDING_APPROVAL') {
        completedShifts++;
        final act = s.actualCash ?? 0.0;
        totalActualCash += act;
        totalDiscrepancy += (act - (bd['expected'] ?? s.openingCash));
      }
    }

    // Include standalone cash drawer expenses if no sessions recorded
    final cashExpensesList = expenses.where((e) => _getExpensePaymentMethod(e.notes) == 'CASH').toList();
    if (sessions.isEmpty) {
      for (final exp in cashExpensesList) {
        totalDrawerExpenses += exp.amount;
      }
    }

    double totalBankDeposits = 0.0;
    double totalBankWithdrawals = 0.0;
    for (final tx in transactions) {
      if (tx.type == 'CLOSE_SHIFT_DEPOSIT' || tx.type == 'MANUAL_DEPOSIT') {
        totalBankDeposits += tx.amount;
      } else if (tx.type == 'OPEN_SHIFT_WITHDRAW' || tx.type == 'MANUAL_WITHDRAW' || tx.type == 'EXPENSE_PAYMENT') {
        totalBankWithdrawals += tx.amount;
      }
    }

    final netDrawerCashFlow = totalCashSales - totalDrawerExpenses;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Controls & Print Button Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
              ),
              boxShadow: UiShadows.card,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _periodChip('Today (අද)', 'TODAY'),
                    _periodChip('This Month (මේ මාසය)', 'THIS_MONTH'),
                    _periodChip('This Year (මේ වසර)', 'THIS_YEAR'),
                    _periodChip('Custom Range', 'CUSTOM'),
                    if (_reportPeriod == 'CUSTOM') ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month_outlined, size: 16),
                        label: Text(
                          '${_reportCustomStart.year}-${_reportCustomStart.month.toString().padLeft(2, '0')}-${_reportCustomStart.day.toString().padLeft(2, '0')}',
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _reportCustomStart,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _reportCustomStart = picked);
                          }
                        },
                      ),
                      const Text('to', style: TextStyle(fontWeight: FontWeight.bold)),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month_outlined, size: 16),
                        label: Text(
                          '${_reportCustomEnd.year}-${_reportCustomEnd.month.toString().padLeft(2, '0')}-${_reportCustomEnd.day.toString().padLeft(2, '0')}',
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _reportCustomEnd,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _reportCustomEnd = picked);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showReportSlipDialog(
                    startDate: startDate,
                    endDate: endDate,
                    sessions: sessions,
                    transactions: transactions,
                    cashExpenses: cashExpensesList,
                    totalCashSales: totalCashSales,
                    totalDrawerExpenses: totalDrawerExpenses,
                    totalOpeningFloats: totalOpeningFloats,
                    totalExpectedCash: totalExpectedCash,
                    totalActualCash: totalActualCash,
                    totalDiscrepancy: totalDiscrepancy,
                    totalBankDeposits: totalBankDeposits,
                    totalBankWithdrawals: totalBankWithdrawals,
                    netDrawerCashFlow: netDrawerCashFlow,
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Print / Slip View (මුද්‍රණය කරන්න)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overview KPI Cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _reportKpiCard(
                'Total Cash Sales (+)',
                '${widget.currencySymbol} ${totalCashSales.toStringAsFixed(2)}',
                Icons.trending_up_rounded,
                const Color(0xFF10B981),
                isDark,
              ),
              _reportKpiCard(
                'Drawer Expenses (-)',
                '${widget.currencySymbol} ${totalDrawerExpenses.toStringAsFixed(2)}',
                Icons.trending_down_rounded,
                const Color(0xFFEF4444),
                isDark,
              ),
              _reportKpiCard(
                'Net Drawer Movement',
                '${widget.currencySymbol} ${netDrawerCashFlow.toStringAsFixed(2)}',
                Icons.account_balance_wallet_rounded,
                const Color(0xFF6366F1),
                isDark,
              ),
              _reportKpiCard(
                'Reconciliation (Over/Short)',
                '${totalDiscrepancy >= 0 ? "+" : ""}${widget.currencySymbol} ${totalDiscrepancy.toStringAsFixed(2)}',
                totalDiscrepancy == 0
                    ? Icons.check_circle_rounded
                    : (totalDiscrepancy > 0 ? Icons.add_circle_rounded : Icons.warning_rounded),
                totalDiscrepancy == 0
                    ? const Color(0xFF10B981)
                    : (totalDiscrepancy > 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444)),
                isDark,
                subtitle: totalDiscrepancy == 0
                    ? 'BALANCED'
                    : (totalDiscrepancy > 0 ? 'EXCESS (වැඩි මුදල්)' : 'SHORTAGE (හිඟ මුදල්)'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cashier Shifts Table
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
              ),
              boxShadow: UiShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cashier Shifts in Period (${sessions.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '$completedShifts Completed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                sessions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No cashier shifts recorded for this period.')),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.resolveWith(
                            (_) => isDark ? const Color(0xFF1E2D45) : const Color(0xFFF8FAFC),
                          ),
                          columnSpacing: 18,
                          columns: const [
                            DataColumn(label: Text('Cashier')),
                            DataColumn(label: Text('Opening Time')),
                            DataColumn(label: Text('Float')),
                            DataColumn(label: Text('Cash Sales')),
                            DataColumn(label: Text('Expenses')),
                            DataColumn(label: Text('Expected')),
                            DataColumn(label: Text('Counted')),
                            DataColumn(label: Text('Variance')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: sessions.map((s) {
                            final bd = widget.onCalculateSessionBreakdown(s);
                            final expected = bd['expected'] ?? s.openingCash;
                            final actual = s.actualCash ?? 0.0;
                            final variance = s.status == 'OPEN' ? 0.0 : (actual - expected);
                            return DataRow(
                              cells: [
                                DataCell(Text(s.userName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(_formatDateTime(s.openingTime))),
                                DataCell(Text('${widget.currencySymbol} ${s.openingCash.toStringAsFixed(2)}')),
                                DataCell(Text('+ ${widget.currencySymbol} ${(bd['cashSales'] ?? 0.0).toStringAsFixed(2)}')),
                                DataCell(Text('- ${widget.currencySymbol} ${(bd['drawerExpenses'] ?? 0.0).toStringAsFixed(2)}')),
                                DataCell(Text('${widget.currencySymbol} ${expected.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(s.status == 'OPEN' ? '-' : '${widget.currencySymbol} ${actual.toStringAsFixed(2)}')),
                                DataCell(
                                  Text(
                                    s.status == 'OPEN'
                                        ? '-'
                                        : '${variance >= 0 ? "+" : ""}${widget.currencySymbol} ${variance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: s.status == 'OPEN'
                                          ? null
                                          : (variance == 0
                                              ? const Color(0xFF10B981)
                                              : (variance > 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444))),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: s.status == 'OPEN'
                                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                          : (s.status == 'PENDING_APPROVAL'
                                              ? Colors.amber.withValues(alpha: 0.15)
                                              : Colors.grey.withValues(alpha: 0.12)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      s.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: s.status == 'OPEN'
                                            ? const Color(0xFF10B981)
                                            : (s.status == 'PENDING_APPROVAL'
                                                ? Colors.amber.shade800
                                                : Colors.grey.shade700),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Drawer Expenses & Transactions List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
              ),
              boxShadow: UiShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash & Bank Ledger Transactions (${transactions.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                transactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No transactions recorded for this period.')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final tx = transactions[idx];
                          final isDeposit = tx.type == 'CLOSE_SHIFT_DEPOSIT' || tx.type == 'MANUAL_DEPOSIT';
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDeposit
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isDeposit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                size: 18,
                              ),
                            ),
                            title: Text(_getTxTypeLabel(tx.type), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${tx.notes} • ${_formatDateTime(tx.createdAt)}', style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              '${isDeposit ? "+" : "-"}${widget.currencySymbol} ${tx.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDeposit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showReportSlipDialog({
    required DateTime startDate,
    required DateTime endDate,
    required List<_CashierSession> sessions,
    required List<_BankTransaction> transactions,
    required List<db.Expense> cashExpenses,
    required double totalCashSales,
    required double totalDrawerExpenses,
    required double totalOpeningFloats,
    required double totalExpectedCash,
    required double totalActualCash,
    required double totalDiscrepancy,
    required double totalBankDeposits,
    required double totalBankWithdrawals,
    required double netDrawerCashFlow,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Register Reconciliation Slip'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.storeName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'REGISTER & SHIFT AUDIT REPORT',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Period: ${_formatDateTime(startDate)} to ${_formatDateTime(endDate)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const Divider(height: 24, thickness: 1),
                  _posBreakdownRowSlip('Shifts Conducted:', '${sessions.length} shifts'),
                  _posBreakdownRowSlip('Total Opening Floats:', '${widget.currencySymbol} ${totalOpeningFloats.toStringAsFixed(2)}'),
                  _posBreakdownRowSlip('Cash Sales (Drawer In):', '+ ${widget.currencySymbol} ${totalCashSales.toStringAsFixed(2)}'),
                  _posBreakdownRowSlip('Cash Expenses (Drawer Out):', '- ${widget.currencySymbol} ${totalDrawerExpenses.toStringAsFixed(2)}', isNegative: true),
                  const Divider(height: 16),
                  _posBreakdownRowSlip('Net Drawer Movement:', '${widget.currencySymbol} ${netDrawerCashFlow.toStringAsFixed(2)}', isBold: true),
                  _posBreakdownRowSlip('Expected Drawer Cash:', '${widget.currencySymbol} ${totalExpectedCash.toStringAsFixed(2)}', isBold: true),
                  _posBreakdownRowSlip('Actual Cash Counted:', '${widget.currencySymbol} ${totalActualCash.toStringAsFixed(2)}', isBold: true),
                  const Divider(height: 16),
                  _posBreakdownRowSlip(
                    'Discrepancy (Over/Short):',
                    '${totalDiscrepancy >= 0 ? "+" : ""}${widget.currencySymbol} ${totalDiscrepancy.toStringAsFixed(2)}',
                    isBold: true,
                    isNegative: totalDiscrepancy < 0,
                  ),
                  const Divider(height: 24, thickness: 1),
                  const Text('BANK LEDGER SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  _posBreakdownRowSlip('Shift Close Deposits:', '+ ${widget.currencySymbol} ${totalBankDeposits.toStringAsFixed(2)}'),
                  _posBreakdownRowSlip('Shift Open & Bank Payouts:', '- ${widget.currencySymbol} ${totalBankWithdrawals.toStringAsFixed(2)}', isNegative: true),
                  const SizedBox(height: 12),
                  Text(
                    'Generated on ${_formatDateTime(DateTime.now())}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report generated successfully!')),
              );
            },
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _posBreakdownRowSlip(String label, String value, {bool isNegative = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isNegative ? const Color(0xFFEF4444) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
