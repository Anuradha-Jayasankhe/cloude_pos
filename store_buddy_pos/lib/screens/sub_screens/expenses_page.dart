part of '../dashboard_screen.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Expenses Page
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ExpensesPage extends StatefulWidget {
  final db.AppDatabase appDatabase;
  final String tenantId;
  final String locationId;
  final String currencySymbol;
  final VoidCallback? onExpensesChanged;
  final Function(double, String, String, String)? onAddBankTransaction;
  final Future<void> Function(String action, String module, String reference)? onEnqueueSync;

  const ExpensesPage({
    super.key,
    required this.appDatabase,
    required this.tenantId,
    required this.locationId,
    required this.currencySymbol,
    this.onExpensesChanged,
    this.onAddBankTransaction,
    this.onEnqueueSync,
  });

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<db.Expense> _expenses = [];
  List<db.Employee> _employees = [];
  bool _loading = true;
  String _filterCategory = 'ALL';
  DateTime _selectedMonth = DateTime.now();
  double _totalInventoryValue = 0.0;

  static const _categories = [
    'ALL',
    'SALARY',
    'ELECTRICITY',
    'RENT',
    'TRANSPORT',
    'INTERNET',
    'MAINTENANCE',
    'STOCK_PURCHASE',
    'OTHER',
  ];

  static const _categoryColors = {
    'SALARY': Color(0xFF6366F1),
    'ELECTRICITY': Color(0xFFF59E0B),
    'RENT': Color(0xFF10B981),
    'TRANSPORT': Color(0xFF3B82F6),
    'INTERNET': Color(0xFF8B5CF6),
    'MAINTENANCE': Color(0xFFEF4444),
    'STOCK_PURCHASE': Color(0xFF059669),
    'OTHER': Color(0xFF6B7280),
  };

  static const _categoryIcons = {
    'SALARY': Icons.people_outline,
    'ELECTRICITY': Icons.bolt_outlined,
    'RENT': Icons.home_outlined,
    'TRANSPORT': Icons.directions_car_outlined,
    'INTERNET': Icons.wifi_outlined,
    'MAINTENANCE': Icons.build_outlined,
    'STOCK_PURCHASE': Icons.shopping_bag_outlined,
    'OTHER': Icons.receipt_long_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _loading = true);
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );
    final all = await widget.appDatabase.getExpensesByDateRange(start, end);
    final emps = await widget.appDatabase.getAllEmployees();

    // Filter expenses by location scope
    final filteredExpenses = all.where((e) {
      if (widget.locationId == 'All Locations') return true;
      final loc = (e.locationId ?? '').trim();
      if (loc.isEmpty) return true;
      return loc == widget.locationId;
    }).toList();

    // Calculate dynamic inventory cost valuation
    final prods = await widget.appDatabase.getAllProducts();
    double invCostSum = 0.0;
    for (final p in prods) {
      if (widget.locationId != 'All Locations') {
        final loc = (p.locationId ?? '').trim();
        if (loc.isNotEmpty && loc != widget.locationId) {
          continue;
        }
      }
      final stockVal = p.stock;
      final costVal = p.costPrice ?? 0.0;
      invCostSum += stockVal * costVal;
    }

    setState(() {
      _expenses = filteredExpenses;
      _employees = emps;
      _totalInventoryValue = invCostSum;
      _loading = false;
    });
  }

  List<db.Expense> get _filtered => _filterCategory == 'ALL'
      ? _expenses
      : _expenses.where((e) => e.category == _filterCategory).toList();

  double get _totalFiltered => _filtered.fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (final e in _expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Future<void> _showAddEditDialog([db.Expense? existing]) async {
    final formKey = GlobalKey<FormState>();
    String category = existing?.category ?? 'OTHER';
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    String paymentMethod = 'CASH';
    String initialNotes = '';
    if (existing != null) {
      paymentMethod = _getExpensePaymentMethod(existing.notes);
      initialNotes = _getExpenseNotes(existing.notes);
    }
    final notesCtrl = TextEditingController(text: initialNotes);
    DateTime selectedDate = existing?.expenseDate ?? DateTime.now();
    String? selectedEmployeeId = existing?.employeeId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existing == null ? 'Add Expense' : 'Edit Expense',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: math.min(MediaQuery.of(ctx).size.width * 0.9, 480.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: _inputDec('Category'),
                    items: _categories
                        .where((c) => c != 'ALL')
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcons[c] ?? Icons.receipt_outlined,
                                  size: 18,
                                  color: _categoryColors[c],
                                ),
                                const SizedBox(width: 8),
                                Text(c),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setS(() => category = v ?? 'OTHER'),
                  ),
                  const SizedBox(height: 12),
                  if (category == 'SALARY') ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedEmployeeId,
                      decoration: _inputDec('Employee'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No Employee Linked'),
                        ),
                        ..._employees.map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text('${e.name} (${e.role})'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setS(() => selectedEmployeeId = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: descCtrl,
                    decoration: _inputDec('Description'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: _inputDec('Amount (${widget.currencySymbol})'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setS(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: _inputDec('Payment Method'),
                    items: const [
                      DropdownMenuItem(value: 'CASH', child: Text('CASH')),
                      DropdownMenuItem(value: 'CARD', child: Text('CARD')),
                      DropdownMenuItem(value: 'CHEQUE', child: Text('CHEQUE')),
                    ],
                    onChanged: (v) => setS(() => paymentMethod = v ?? 'CASH'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: _inputDec('Notes (optional)'),
                    maxLines: 2,
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final id = existing?.id ?? _uuid();
                final amt = double.parse(amountCtrl.text);
                final companion = db.ExpensesCompanion(
                  id: Value(id),
                  tenantId: Value(widget.tenantId),
                  category: Value(category),
                  description: Value(descCtrl.text.trim()),
                  amount: Value(amt),
                  locationId: Value(widget.locationId),
                  employeeId: Value(selectedEmployeeId),
                  notes: Value(
                    '${paymentMethod}|${notesCtrl.text.trim()}',
                  ),
                  expenseDate: Value(selectedDate),
                  synced: const Value(false),
                  createdAt: Value(existing?.createdAt ?? DateTime.now()),
                  updatedAt: Value(DateTime.now()),
                );
                await widget.appDatabase.insertExpense(companion);
                widget.onEnqueueSync?.call(
                  existing == null ? 'INSERT' : 'UPDATE',
                  'expenses',
                  id,
                );

                // Deduct from bank ledger if payment method is not CASH
                if (paymentMethod != 'CASH') {
                  widget.onAddBankTransaction?.call(
                    amt,
                    'EXPENSE_PAYMENT',
                    id,
                    'General Expense: ${descCtrl.text.trim()}',
                  );
                }

                if (ctx.mounted) Navigator.pop(ctx);
                _loadExpenses();
                widget.onExpensesChanged?.call();
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(db.Expense e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Delete "${e.description}" (${widget.currencySymbol}${e.amount.toStringAsFixed(2)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.appDatabase.deleteExpense(e.id);
      widget.onEnqueueSync?.call('DELETE', 'expenses', e.id);
      _loadExpenses();
      widget.onExpensesChanged?.call();
    }
  }

  InputDecoration _inputDec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  String _uuid() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + (DateTime.now().microsecond % 9000)).toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _expenses.fold(0.0, (s, e) => s + e.amount);
    final sym = widget.currencySymbol;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;
        final header = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Management',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Track and manage business expenses',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.chevron_left, size: 18),
                        label: const SizedBox.shrink(),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month - 1,
                            );
                          });
                          _loadExpenses();
                        },
                      ),
                      Text(
                        '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: const SizedBox.shrink(),
                        onPressed:
                            _selectedMonth.month == DateTime.now().month &&
                                _selectedMonth.year == DateTime.now().year
                            ? null
                            : () {
                                setState(() {
                                  _selectedMonth = DateTime(
                                    _selectedMonth.year,
                                    _selectedMonth.month + 1,
                                  );
                                });
                                _loadExpenses();
                              },
                      ),
                      FilledButton.icon(
                        onPressed: () => _showAddEditDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Expense'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Management',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Track and manage business expenses',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const SizedBox.shrink(),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                      _loadExpenses();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: const SizedBox.shrink(),
                    onPressed:
                        _selectedMonth.month == DateTime.now().month &&
                            _selectedMonth.year == DateTime.now().year
                        ? null
                        : () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                            _loadExpenses();
                          },
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Expense'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              );

        return Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              header,
              const SizedBox(height: 20),
          
              // â”€â”€ Summary Cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Total + category breakdown
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: compact ? double.infinity : 280,
                              child: _summaryCard(
                                'Total Expenses',
                                '$sym ${total.toStringAsFixed(2)}',
                                Icons.account_balance_wallet_outlined,
                                const Color(0xFF4F46E5),
                              ),
                            ),
                            SizedBox(
                              width: compact ? double.infinity : 240,
                              child: _summaryCard(
                                'Inventory Asset Value',
                                '$sym ${_totalInventoryValue.toStringAsFixed(2)}',
                                Icons.inventory_2_outlined,
                                const Color(0xFF0EA5E9),
                              ),
                            ),
                            ..._categoryTotals.entries
                                .take(3)
                                .map(
                                  (e) => SizedBox(
                                    width: compact ? double.infinity : 240,
                                    child: _summaryCard(
                                      e.key,
                                      '$sym ${e.value.toStringAsFixed(2)}',
                                      _categoryIcons[e.key] ??
                                          Icons.receipt_outlined,
                                      _categoryColors[e.key] ?? Colors.grey,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                        const SizedBox(height: 16),
          
                        // â”€â”€ Category filter chips & Pie Chart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        Flex(
                          direction: compact ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: compact
                                  ? double.infinity
                                  : constraints.maxWidth * 0.6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Filter by Category',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _categories.map((cat) {
                                      final selected = _filterCategory == cat;
                                      return FilterChip(
                                        selected: selected,
                                        label: Text(cat),
                                        labelStyle: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                                          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                        avatar: cat != 'ALL'
                                            ? Icon(
                                                _categoryIcons[cat],
                                                size: 15,
                                                color: selected
                                                    ? Colors.white
                                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                              )
                                            : null,
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : Colors.black.withValues(alpha: 0.04),
                                        selectedColor: const Color(0xFF4F46E5),
                                        checkmarkColor: Colors.white,
                                        showCheckmark: false,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        side: BorderSide(
                                          color: selected
                                              ? const Color(0xFF4F46E5)
                                              : (Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white.withValues(alpha: 0.12)
                                                  : Colors.grey.shade300),
                                          width: 1,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        onSelected: (_) =>
                                            setState(() => _filterCategory = cat),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            if (total > 0)
                              SizedBox(
                                width: compact ? double.infinity : 260,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Expense Breakdown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 120,
                                      child: CustomPaint(
                                        size: const Size.square(120),
                                        painter: _PieChartPainter(
                                          _categoryTotals,
                                          _categoryColors,
                                          total,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
          
                        // â”€â”€ Table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        Builder(
                          builder: (context) {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _filtered.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No expenses found',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth - 30,
                                      ),
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.resolveWith(
                                          (states) => isDark
                                              ? Theme.of(context).colorScheme.surfaceContainerHighest
                                              : const Color(0xFFF8FAFC),
                                        ),
                                        columnSpacing: 20,
                                        columns: const [
                                          DataColumn(label: Text('Category')),
                                          DataColumn(label: Text('Description')),
                                          DataColumn(label: Text('Date')),
                                          DataColumn(label: Text('Method')),
                                          DataColumn(
                                            label: Text('Amount'),
                                            numeric: true,
                                          ),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: _filtered.map((e) {
                                          final cat = e.category;
                                          final color =
                                              _categoryColors[cat] ?? Theme.of(context).colorScheme.outline;
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(
                                                        6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: color.withValues(
                                                          alpha: 0.12,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(
                                                        _categoryIcons[cat] ??
                                                            Icons.receipt_outlined,
                                                        size: 16,
                                                        color: color,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      cat,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      e.description,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (e.category == 'SALARY' &&
                                                        e.employeeId != null)
                                                      Text(
                                                        _employees
                                                            .firstWhere(
                                                              (emp) =>
                                                                  emp.id ==
                                                                  e.employeeId,
                                                              orElse: () =>
                                                                  db.Employee(
                                                                    id: '',
                                                                    tenantId: '',
                                                                    name: 'Unknown',
                                                                    email: '',
                                                                    role: 'CASHIER',
                                                                    locationId: '',
                                                                    commissionType:
                                                                        'NONE',
                                                                    commissionValue:
                                                                        0,
                                                                    minSalesTarget: 0,
                                                                    isAgent: false,
                                                                    synced: true,
                                                                  ),
                                                            )
                                                            .name,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Theme.of(context).colorScheme.outline,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  '${e.expenseDate.year}-${e.expenseDate.month.toString().padLeft(2, '0')}-${e.expenseDate.day.toString().padLeft(2, '0')}',
                                                ),
                                              ),
                                              DataCell(
                                                (() {
                                                  final pm = _getExpensePaymentMethod(e.notes);
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: pm == 'CASH'
                                                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                                          : pm == 'CARD'
                                                              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                                                              : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      pm,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: pm == 'CASH'
                                                            ? const Color(0xFF10B981)
                                                            : pm == 'CARD'
                                                                ? const Color(0xFF3B82F6)
                                                                : const Color(0xFFF59E0B),
                                                      ),
                                                    ),
                                                  );
                                                })(),
                                              ),
                                              DataCell(
                                                Text(
                                                  '$sym ${e.amount.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit_outlined,
                                                        size: 18,
                                                      ),
                                                      color: const Color(0xFF4F46E5),
                                                      onPressed: () =>
                                                          _showAddEditDialog(e),
                                                      tooltip: 'Edit',
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        size: 18,
                                                      ),
                                                      color: const Color(0xFFEF4444),
                                                      onPressed: () =>
                                                          _deleteExpense(e),
                                                      tooltip: 'Delete',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                           );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                              ),
                            );
                          },
                        ),

          
                        // â”€â”€ Filtered total â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        if (_filterCategory != 'ALL')
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12, right: 4),
                              child: Text(
                                '$_filterCategory Total: $sym ${_totalFiltered.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ],
          ),
         ),
        );
      },
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      '',
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
    return names[month];
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;
  final Map<String, Color> categoryColors;
  final double total;

  _PieChartPainter(this.categoryTotals, this.categoryColors, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    double startRadian = -math.pi / 2;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    // Sort categories by total to draw larger slices first (optional but looks nice)
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries) {
      if (entry.value <= 0) continue;
      final sweepRadian = (entry.value / total) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = categoryColors[entry.key] ?? Colors.grey;
      canvas.drawArc(rect, startRadian, sweepRadian, true, paint);
      startRadian += sweepRadian;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.categoryTotals != categoryTotals;
  }
}

String _getExpensePaymentMethod(String? notesVal) {
  final notes = notesVal ?? '';
  if (notes.startsWith('CASH|')) return 'CASH';
  if (notes.startsWith('CARD|')) return 'CARD';
  if (notes.startsWith('CHEQUE|')) return 'CHEQUE';
  if (notes.toLowerCase().contains('cash')) return 'CASH';
  if (notes.toLowerCase().contains('card')) return 'CARD';
  if (notes.toLowerCase().contains('cheque')) return 'CHEQUE';
  return 'CASH';
}

String _getExpenseNotes(String? notesVal) {
  final notes = notesVal ?? '';
  if (notes.startsWith('CASH|')) return notes.substring(5);
  if (notes.startsWith('CARD|')) return notes.substring(5);
  if (notes.startsWith('CHEQUE|')) return notes.substring(7);
  return notes;
}
