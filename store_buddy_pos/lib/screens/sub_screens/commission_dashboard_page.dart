part of '../dashboard_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Commission Dashboard Page
// ─────────────────────────────────────────────────────────────────────────────
class CommissionDashboardPage extends StatefulWidget {
  final db.AppDatabase appDatabase;
  final String tenantId;
  final String currencySymbol;
  final List<Map<String, String>> appUsers; // {id, name, role} from _users

  const CommissionDashboardPage({
    super.key,
    required this.appDatabase,
    required this.tenantId,
    required this.currencySymbol,
    this.appUsers = const [],
  });

  @override
  State<CommissionDashboardPage> createState() =>
      _CommissionDashboardPageState();
}

class _CommissionDashboardPageState extends State<CommissionDashboardPage> {
  List<db.Employee> _employees = [];
  List<db.CommissionLog> _logs = [];
  List<db.Sale> _sales = [];
  List<db.Product> _products = [];
  List<commission.CommissionRule> _rules = [];
  bool _loading = true;
  String _period = 'MONTH'; // 'TODAY' | 'MONTH' | 'YEAR'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final emps = await widget.appDatabase.getAllEmployees();
    final logs = await widget.appDatabase.getCommissionLogs();
    final sales = await widget.appDatabase.getAllSales();
    final products = await widget.appDatabase.getAllProducts();
    final svc = commission.CommissionService(widget.appDatabase);
    final rules = await svc.getRules(widget.tenantId);

    // Synthesize virtual employee entries for any log employeeId
    // not already covered by a real DB employee record.
    final empIds = {for (final e in emps) e.id};
    final synthetic = <db.Employee>[];
    final seenSynth = <String>{};
    for (final log in logs) {
      final eid = log.employeeId;
      if (!empIds.contains(eid) && !seenSynth.contains(eid)) {
        seenSynth.add(eid);
        // Try to get a human-readable name from the ID (e.g. AGT-as-... -> as)
        final displayName = _agentDisplayName(eid);
        synthetic.add(
          db.Employee(
            id: eid,
            tenantId: log.tenantId,
            name: displayName,
            email: '',
            locationId: '',
            role: 'AGENT',
            commissionType: 'NONE',
            commissionValue: 0,
            minSalesTarget: 0,
            isAgent: true,
            synced: false,
            createdAt: log.createdAt,
          ),
        );
      }
    }

    setState(() {
      _employees = [...emps, ...synthetic];
      _logs = logs;
      _sales = sales;
      _products = products;
      _rules = rules;
      _loading = false;
    });
  }

  /// Derives a human-readable name from an agent employee ID.
  /// e.g. "AGT-as-1234567890" -> "as"
  ///      "user_abc123"       -> "user_abc123"
  static String _agentDisplayName(String id) {
    final agtMatch = RegExp(r'^AGT-(.+?)-\d+$').firstMatch(id);
    if (agtMatch != null) {
      return agtMatch.group(1)!.replaceAll('_', ' ').trim();
    }
    return id;
  }

  String _productLabel(String productId) {
    for (final product in _products) {
      if (product.id == productId) return product.name;
    }
    return productId;
  }

  Future<void> _saveRule(commission.CommissionRule rule) async {
    final svc = commission.CommissionService(widget.appDatabase);
    await svc.upsertRule(widget.tenantId, rule);
    await _load();
  }

  Future<void> _deleteRule(String id) async {
    final svc = commission.CommissionService(widget.appDatabase);
    await svc.deleteRule(widget.tenantId, id);
    await _load();
  }

  Future<commission.CommissionRule?> _showCommissionRuleDialog({
    commission.CommissionRule? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final valueController = TextEditingController(
      text: existing?.value.toStringAsFixed(2) ?? '',
    );
    final categoryController = TextEditingController(
      text: existing?.category ?? '',
    );
    String commissionType = existing?.commissionType.toUpperCase() == 'FIXED'
        ? 'FIXED'
        : 'PERCENT';
    bool active = existing?.active ?? true;
    final selectedProducts = <String>{...(existing?.productIds ?? const [])};
    final selectedEmployees = <String>{...(existing?.employeeIds ?? const [])};
    final employeeChoices = <Map<String, String>>[];
    // Add DB employees
    for (final employee in _employees) {
      employeeChoices.add({
        'id': employee.id,
        'name': employee.name,
        'role': employee.role,
      });
    }
    // Add app users that are not already in the employee list
    for (final user in widget.appUsers) {
      final userId = user['id'] ?? '';
      final userName = user['name'] ?? '';
      if (userId.isNotEmpty &&
          !employeeChoices.any(
            (e) =>
                e['id'] == userId ||
                e['name']?.toLowerCase() == userName.toLowerCase(),
          )) {
        employeeChoices.add({
          'id': userId,
          'name': userName,
          'role': user['role'] ?? 'USER',
        });
      }
    }

    final rule = await showDialog<commission.CommissionRule>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final narrow = MediaQuery.of(context).size.width < 700;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            // Explicit chip colors: black text on a light grey chip in light
            // mode, white text on a dark grey chip in dark mode. Selected
            // chips use the app's indigo brand color with white text.
            final chipUnselectedBg = isDark
                ? const Color(0xFF334155) // slate grey for dark mode
                : const Color(0xFFE5E7EB); // light grey for light mode
            final chipUnselectedText = isDark ? Colors.white : Colors.black;
            final chipSelectedBg = const Color(0xFF4F46E5); // brand indigo
            const chipSelectedText = Colors.white;
            final chipBorder = isDark
                ? const Color(0xFF475569)
                : const Color(0xFFCBD5E1);
            final typeField = DropdownButtonFormField<String>(
              initialValue: commissionType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'PERCENT', child: Text('Percentage')),
                DropdownMenuItem(value: 'FIXED', child: Text('Fixed Amount')),
              ],
              onChanged: (value) => setLocal(() {
                commissionType = value ?? commissionType;
              }),
            );
            final valueField = TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: commissionType == 'PERCENT'
                    ? 'Percent Value'
                    : 'Fixed Amount',
                border: const OutlineInputBorder(),
              ),
            );

            return AlertDialog(
              title: Text(
                existing == null
                    ? 'Add Commission Rule'
                    : 'Edit Commission Rule',
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  minWidth: 320,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Rule Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      narrow
                          ? Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: typeField,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: valueField,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: typeField),
                                const SizedBox(width: 12),
                                Expanded(child: valueField),
                              ],
                            ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Optional Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Products',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _products.isEmpty
                            ? const Center(
                                child: Text(
                                  'No products available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(8),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: _products.map((product) {
                                    final selected = selectedProducts.contains(
                                      product.id,
                                    );
                                    return FilterChip(
                                      label: Text(
                                        product.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? chipSelectedText
                                              : chipUnselectedText,
                                        ),
                                      ),
                                      selected: selected,
                                      showCheckmark: false,
                                      backgroundColor: chipUnselectedBg,
                                      selectedColor: chipSelectedBg,
                                      side: BorderSide(
                                        color: selected
                                            ? chipSelectedBg
                                            : chipBorder,
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      onSelected: (value) => setLocal(() {
                                        if (value) {
                                          selectedProducts.add(product.id);
                                        } else {
                                          selectedProducts.remove(product.id);
                                        }
                                      }),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Employees / Users',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: employeeChoices.isEmpty
                            ? const Center(
                                child: Text(
                                  'No employees/users found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(8),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: employeeChoices.map((choice) {
                                    final employeeId = choice['id'] ?? '';
                                    final employeeName =
                                        choice['name'] ?? employeeId;
                                    final role = choice['role'] ?? '';
                                    final selected = selectedEmployees.contains(
                                      employeeId,
                                    );
                                    return FilterChip(
                                      avatar: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.blue
                                            .withOpacity(0.2),
                                        child: Text(
                                          employeeName.isNotEmpty
                                              ? employeeName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      label: Text(
                                        '$employeeName${role.isNotEmpty ? ' ($role)' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? chipSelectedText
                                              : chipUnselectedText,
                                        ),
                                      ),
                                      selected: selected,
                                      showCheckmark: false,
                                      backgroundColor: chipUnselectedBg,
                                      selectedColor: chipSelectedBg,
                                      side: BorderSide(
                                        color: selected
                                            ? chipSelectedBg
                                            : chipBorder,
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      onSelected: (value) => setLocal(() {
                                        if (value) {
                                          selectedEmployees.add(employeeId);
                                        } else {
                                          selectedEmployees.remove(employeeId);
                                        }
                                      }),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value =
                        double.tryParse(valueController.text.trim()) ?? 0;
                    Navigator.pop(
                      context,
                      commission.CommissionRule(
                        id:
                            existing?.id ??
                            'CR${DateTime.now().microsecondsSinceEpoch}',
                        name: nameController.text.trim().isEmpty
                            ? 'Commission Rule'
                            : nameController.text.trim(),
                        commissionType: commissionType,
                        value: value,
                        active: active,
                        productIds: selectedProducts.toList(),
                        employeeIds: selectedEmployees.toList(),
                        category: categoryController.text.trim().isEmpty
                            ? null
                            : categoryController.text.trim(),
                      ),
                    );
                  },
                  child: Text(existing == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    valueController.dispose();
    categoryController.dispose();
    return rule;
  }

  List<db.CommissionLog> get _filteredLogs {
    final now = DateTime.now();
    return _logs.where((log) {
      final date = log.createdAt ?? now;
      if (_period == 'TODAY') {
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      } else if (_period == 'MONTH') {
        return date.year == now.year && date.month == now.month;
      }
      return date.year == now.year;
    }).toList();
  }

  List<db.Sale> get _filteredSales {
    final now = DateTime.now();
    return _sales.where((s) {
      final date = s.createdAt ?? now;
      if (_period == 'TODAY') {
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      } else if (_period == 'MONTH') {
        return date.year == now.year && date.month == now.month;
      }
      return date.year == now.year;
    }).toList();
  }

  // Employee summary map: { employeeId -> {salesCount, revenue, total, pending, paid} }
  // Revenue is computed from the sales referenced in commission logs for that agent.
  Map<String, Map<String, double>> get _employeeSummaries {
    final Map<String, Map<String, double>> map = {};
    // Build saleId -> sale lookup
    final saleMap = <String, db.Sale>{};
    for (final sale in _filteredSales) {
      saleMap[sale.id] = sale;
    }

    for (final emp in _employees) {
      final empLogs = _filteredLogs
          .where((l) => l.employeeId == emp.id)
          .toList();

      // Unique sale IDs referenced in commission logs for this employee
      final linkedSaleIds = empLogs.map((l) => l.saleId).toSet();
      final linkedSales = linkedSaleIds
          .map((id) => saleMap[id])
          .whereType<db.Sale>()
          .toList();

      final total = empLogs.fold(0.0, (s, l) => s + l.commissionAmount);
      final pending = empLogs
          .where((l) => !l.isPaid)
          .fold(0.0, (s, l) => s + l.commissionAmount);
      final paid = empLogs
          .where((l) => l.isPaid)
          .fold(0.0, (s, l) => s + l.commissionAmount);

      map[emp.id] = {
        'salesCount': linkedSales.length.toDouble(),
        'revenue': linkedSales.fold(0.0, (s, sale) => s + sale.total),
        'total': total,
        'pending': pending,
        'paid': paid,
      };
    }
    return map;
  }

  /// Only return employees who have at least one commission log in the current period.
  List<db.Employee> get _rankedEmployees {
    final sums = _employeeSummaries;
    final withLogs = _employees
        .where((e) => (sums[e.id]?['total'] ?? 0) > 0)
        .toList();
    withLogs.sort(
      (a, b) =>
          (sums[b.id]?['total'] ?? 0).compareTo(sums[a.id]?['total'] ?? 0),
    );
    return withLogs;
  }

  Future<void> _markAllPaid(String employeeId) async {
    final pending = _filteredLogs
        .where((l) => l.employeeId == employeeId && !l.isPaid)
        .toList();
    for (final log in pending) {
      await widget.appDatabase.markCommissionPaid(log.id);
    }
    _load();
  }

  void _showEmployeeHistory(db.Employee emp) {
    final logs = _filteredLogs.where((l) => l.employeeId == emp.id).toList();
    logs.sort(
      (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
        a.createdAt ?? DateTime.now(),
      ),
    );

    // Build a sale lookup map
    final saleMap = <String, db.Sale>{};
    for (final sale in _sales) {
      saleMap[sale.id] = sale;
    }

    final sym = widget.currencySymbol;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.15),
              child: Text(
                emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${emp.name} — Commission History')),
          ],
        ),
        content: SizedBox(
          width: ResponsiveLayout.adaptiveDialogWidth(context, 860),
          height: ResponsiveLayout.adaptiveDialogHeight(context, 520),
          child: logs.isEmpty
              ? const Center(
                  child: Text('No commission records for this period.'),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary row
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          _summaryChip(
                            'Total',
                            '$sym ${logs.fold(0.0, (s, l) => s + l.commissionAmount).toStringAsFixed(2)}',
                            Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          _summaryChip(
                            'Paid',
                            '$sym ${logs.where((l) => l.isPaid).fold(0.0, (s, l) => s + l.commissionAmount).toStringAsFixed(2)}',
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _summaryChip(
                            'Pending',
                            '$sym ${logs.where((l) => !l.isPaid).fold(0.0, (s, l) => s + l.commissionAmount).toStringAsFixed(2)}',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 16,
                          headingRowHeight: 36,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 64,
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Sale / Invoice')),
                            DataColumn(label: Text('Type')),
                            DataColumn(
                              label: Text('Sale Total'),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text('Commission'),
                              numeric: true,
                            ),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: logs.map((log) {
                            final date = log.createdAt ?? DateTime.now();
                            final sale = saleMap[log.saleId];
                            final dateStr =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            final sid = log.saleId;
                            final invoiceStr =
                                sale?.invoiceNumber ??
                                (sid.length > 12 ? sid.substring(0, 12) : sid);
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        invoiceStr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (sale != null)
                                        Text(
                                          '$sym ${sale.total.toStringAsFixed(2)} | ${sale.paymentMethod}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: log.commissionType == 'FIXED'
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log.commissionType,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: log.commissionType == 'FIXED'
                                            ? Colors.blue
                                            : Colors.purple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '$sym ${log.saleAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '$sym ${log.commissionAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  log.isPaid
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _statusChip(
                                              'PAID',
                                              const Color(0xFF22C55E),
                                            ),
                                            if (log.paidAt != null)
                                              Text(
                                                '${log.paidAt!.year}-${log.paidAt!.month.toString().padLeft(2, '0')}-${log.paidAt!.day.toString().padLeft(2, '0')}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          ],
                                        )
                                      : _statusChip(
                                          'PENDING',
                                          const Color(0xFFF59E0B),
                                        ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
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
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sym = widget.currencySymbol;
    final sums = _employeeSummaries;
    final totalCommission = _filteredLogs.fold(
      0.0,
      (s, l) => s + l.commissionAmount,
    );
    final pendingCommission = _filteredLogs
        .where((l) => !l.isPaid)
        .fold(0.0, (s, l) => s + l.commissionAmount);
    final paidCommission = _filteredLogs
        .where((l) => l.isPaid)
        .fold(0.0, (s, l) => s + l.commissionAmount);
    final totalRevenue = _filteredSales.fold(0.0, (s, sale) => s + sale.total);

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // ── Header ────────────────────────────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    final periodToggle = Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['TODAY', 'MONTH', 'YEAR'].map((p) {
                          final active = _period == p;
                          return GestureDetector(
                            onTap: () => setState(() => _period = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: active
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commission Dashboard',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track employee commissions and sales performance',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          periodToggle,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commission Dashboard',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Track employee commissions and sales performance',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        periodToggle,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── KPI Cards ─────────────────────────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 36) / 4;
                    final useGrid = cardWidth < 155;

                    if (useGrid) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              _kpiCard(
                                'Total Revenue',
                                '$sym ${totalRevenue.toStringAsFixed(2)}',
                                Icons.trending_up,
                                theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 12),
                              _kpiCard(
                                'Total Commission',
                                '$sym ${totalCommission.toStringAsFixed(2)}',
                                Icons.stars_outlined,
                                theme.colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _kpiCard(
                                'Pending',
                                '$sym ${pendingCommission.toStringAsFixed(2)}',
                                Icons.pending_outlined,
                                theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 12),
                              _kpiCard(
                                'Paid Out',
                                '$sym ${paidCommission.toStringAsFixed(2)}',
                                Icons.check_circle_outline,
                                theme.colorScheme.secondary,
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        _kpiCard(
                          'Total Revenue',
                          '$sym ${totalRevenue.toStringAsFixed(2)}',
                          Icons.trending_up,
                          theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        _kpiCard(
                          'Total Commission',
                          '$sym ${totalCommission.toStringAsFixed(2)}',
                          Icons.stars_outlined,
                          theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        _kpiCard(
                          'Pending',
                          '$sym ${pendingCommission.toStringAsFixed(2)}',
                          Icons.pending_outlined,
                          theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 12),
                        _kpiCard(
                          'Paid Out',
                          '$sym ${paidCommission.toStringAsFixed(2)}',
                          Icons.check_circle_outline,
                          theme.colorScheme.secondary,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Commission Rules',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final created = await _showCommissionRuleDialog();
                        if (created == null) return;
                        await _saveRule(created);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Rule'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _rules.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('No commission rules yet.'),
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
                                  headingRowColor: WidgetStateProperty.all(
                                    Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.04),
                                  ),
                                  columnSpacing: 20,
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 56,
                                  columns: const [
                                    DataColumn(label: Text('Rule')),
                                    DataColumn(label: Text('Type')),
                                    DataColumn(label: Text('Scope')),
                                    DataColumn(
                                      label: Text('Value'),
                                      numeric: true,
                                    ),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: _rules.map((rule) {
                                    final scopeBits = <String>[];
                                    if (rule.productIds.isNotEmpty) {
                                      scopeBits.add(
                                        rule.productIds
                                            .map(_productLabel)
                                            .join(', '),
                                      );
                                    }
                                    if ((rule.category ?? '')
                                        .trim()
                                        .isNotEmpty) {
                                      scopeBits.add(
                                        'Category: ${rule.category}',
                                      );
                                    }
                                    if (rule.employeeIds.isNotEmpty) {
                                      scopeBits.add(
                                        'Employees: ${rule.employeeIds.join(', ')}',
                                      );
                                    }
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(rule.name)),
                                        DataCell(
                                          Text(
                                            rule.commissionType.toUpperCase(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            scopeBits.isEmpty
                                                ? 'All sales'
                                                : scopeBits.join(' | '),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            rule.commissionType.toUpperCase() ==
                                                    'PERCENT'
                                                ? '${rule.value.toStringAsFixed(2)}%'
                                                : '${widget.currencySymbol} ${rule.value.toStringAsFixed(2)}',
                                          ),
                                        ),
                                        DataCell(
                                          _statusChip(
                                            rule.active ? 'Active' : 'Inactive',
                                            rule.active
                                                ? const Color(0xFF22C55E)
                                                : Colors.grey,
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Edit',
                                                onPressed: () async {
                                                  final edited =
                                                      await _showCommissionRuleDialog(
                                                        existing: rule,
                                                      );
                                                  if (edited == null) return;
                                                  await _saveRule(edited);
                                                },
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Delete',
                                                onPressed: () async {
                                                  await _deleteRule(rule.id);
                                                },
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color:
                                                      theme.colorScheme.error,
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
                ),
                const SizedBox(height: 24),

                // ── Employee Rankings ─────────────────────────────────────────
                Text(
                  'Employee Performance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _rankedEmployees.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No commission data for this period',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
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
                                  headingRowColor: WidgetStateProperty.all(
                                    Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.04),
                                  ),
                                  columnSpacing: 20,
                                  dataRowMinHeight: 52,
                                  dataRowMaxHeight: 60,
                                  columns: const [
                                    DataColumn(label: Text('Rank')),
                                    DataColumn(label: Text('Employee')),
                                    DataColumn(label: Text('Role')),
                                    DataColumn(
                                      label: Text('Sales'),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text('Revenue'),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text('Commission'),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text('Pending'),
                                      numeric: true,
                                    ),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Action')),
                                  ],
                                  rows: _rankedEmployees.asMap().entries.map((
                                    entry,
                                  ) {
                                    final idx = entry.key;
                                    final emp = entry.value;
                                    final s = sums[emp.id] ?? {};
                                    final hasPending = (s['pending'] ?? 0) > 0;
                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith((
                                        states,
                                      ) {
                                        if (states.contains(
                                          WidgetState.hovered,
                                        )) {
                                          return Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.04);
                                        }
                                        return null;
                                      }),
                                      cells: [
                                        DataCell(_rankBadge(idx + 1)),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: theme
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.15),
                                                child: Text(
                                                  emp.name.isNotEmpty
                                                      ? emp.name[0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                emp.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(_roleBadge(emp.role)),
                                        DataCell(
                                          Text(
                                            '${(s['salesCount'] ?? 0).toInt()}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '$sym ${(s['revenue'] ?? 0).toStringAsFixed(2)}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '$sym ${(s['total'] ?? 0).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '$sym ${(s['pending'] ?? 0).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: hasPending
                                                  ? const Color(0xFFF59E0B)
                                                  : Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          hasPending
                                              ? _statusChip(
                                                  'Pending',
                                                  const Color(0xFFF59E0B),
                                                )
                                              : _statusChip(
                                                  'All Paid',
                                                  const Color(0xFF22C55E),
                                                ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (hasPending)
                                                TextButton(
                                                  onPressed: () =>
                                                      _markAllPaid(emp.id),
                                                  child: const Text(
                                                    'Mark Paid',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              TextButton(
                                                onPressed: () =>
                                                    _showEmployeeHistory(emp),
                                                child: const Text(
                                                  'History',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
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
                ),
              ],
            ),
          ),
        );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rankBadge(int rank) {
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.tertiary, // Gold-ish
      theme.colorScheme.onSurface.withValues(alpha: 0.6), // Silver neutral
      theme.colorScheme.secondary, // Bronze-ish
    ];
    final color = rank <= 3
        ? colors[rank - 1]
        : theme.colorScheme.onSurface.withValues(alpha: 0.4);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    final theme = Theme.of(context);
    final colors = {
      'OWNER': theme.colorScheme.primary,
      'MANAGER': theme.colorScheme.secondary,
      'CASHIER': theme.colorScheme.secondary,
      'AGENT': theme.colorScheme.primary,
      'TECHNICIAN': theme.colorScheme.tertiary,
    };
    final color = colors[role] ?? theme.colorScheme.onSurface.withOpacity(0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
