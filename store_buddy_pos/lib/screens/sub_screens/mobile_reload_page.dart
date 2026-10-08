// ignore_for_file: invalid_use_of_protected_member

part of '../dashboard_screen.dart';

extension _MobileReloadPageExt on _DashboardScreenState {
  Widget _buildMobileReloadPage() {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Mobile Reloads',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Process prepaid & postpaid mobile reloads, manage tiered commission rules, track settlements, and view history',
                      style: TextStyle(color: Color(0xFF6D7383), fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.65),
            indicatorColor: colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                icon: Icon(Icons.phone_android_rounded),
                text: 'New Reload',
              ),
              Tab(
                icon: Icon(Icons.history_rounded),
                text: 'Reload History',
              ),
              Tab(
                icon: Icon(Icons.account_balance_wallet_rounded),
                text: 'Operator Settlements',
              ),
              Tab(
                icon: Icon(Icons.settings_suggest_rounded),
                text: 'Commission Settings',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildNewReloadTab(),
                _buildReloadHistoryTab(),
                _buildOperatorSettlementsTab(),
                _buildCommissionSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewReloadTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final operators = [
      {'name': 'Dialog', 'color': const Color(0xFFE91E63), 'icon': Icons.cell_tower_rounded},
      {'name': 'Mobitel', 'color': const Color(0xFF4CAF50), 'icon': Icons.cell_tower_rounded},
      {'name': 'Hutch', 'color': const Color(0xFFFF9800), 'icon': Icons.cell_tower_rounded},
      {'name': 'Airtel', 'color': const Color(0xFFF44336), 'icon': Icons.cell_tower_rounded},
      {'name': 'SLT', 'color': const Color(0xFF2196F3), 'icon': Icons.cell_tower_rounded},
      {'name': 'eZ Cash', 'color': const Color(0xFF673AB7), 'icon': Icons.wallet_rounded},
    ];

    final formKey = GlobalKey<FormState>();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    String selectedOperator = 'Dialog';

    return StatefulBuilder(
      builder: (context, setSubState) {
        final localContext = context;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Process Mobile Reload / Wallet Pay-in',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Select Operator / Service',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D7383),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Operator Selection Cards
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: operators.map((op) {
                      final isSelected = selectedOperator == op['name'];
                      final opColor = op['color'] as Color;
                      return InkWell(
                        onTap: () {
                          setSubState(() {
                            selectedOperator = op['name'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? opColor.withValues(alpha: 0.15)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? opColor
                                  : colorScheme.outlineVariant,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                op['icon'] as IconData,
                                color: isSelected
                                    ? opColor
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.65,
                                      ),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                op['name'] as String,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? opColor
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Customer Phone Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D7383),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'e.g., 0771234567 or 771234567',
                      prefixIcon: Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a phone number';
                      }
                      final cleanVal = value.trim();
                      final phoneRegex = RegExp(r'^\+?[0-9]{9,12}$');
                      if (!phoneRegex.hasMatch(cleanVal)) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Reload Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D7383),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '$_currency ',
                      prefixIcon: const Icon(Icons.payments_rounded),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amt = double.tryParse(value.trim());
                      if (amt == null || amt <= 0) {
                        return 'Please enter a valid amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          final phone = phoneController.text.trim();
                          final amt = double.parse(amountController.text.trim());
                          final op = selectedOperator;

                          // Evaluate tiered commission rule
                          final tiers = _operatorCommissions[op] ?? [];
                          double comm = 0.0;
                          bool matched = false;
                          for (final tier in tiers) {
                            final minVal = (tier['min'] as num?)?.toDouble() ?? 0.0;
                            final maxVal = (tier['max'] as num?)?.toDouble() ?? 999999.0;
                            if (amt >= minVal && amt <= maxVal) {
                              final type = tier['type'] ?? 'percentage';
                              final val = (tier['value'] as num?)?.toDouble() ?? 0.0;
                              if (type == 'percentage') {
                                comm = amt * (val / 100.0);
                              } else {
                                comm = val;
                              }
                              matched = true;
                              break;
                            }
                          }
                          
                          // Fallback to 5.0% if no range rules configured or matched
                          if (!matched) {
                            comm = amt * 0.05;
                          }
                          comm = double.parse(comm.toStringAsFixed(2));

                          final before = _cashInHand;
                          final after = before + amt;
                          
                          final reloadId = 'RLD-${DateTime.now().millisecondsSinceEpoch}';
                          final txId = 'CTX-${DateTime.now().millisecondsSinceEpoch}';
                          
                          final tx = _CashTransactionItem(
                            id: txId,
                            type: 'IN',
                            referenceType: 'RELOAD',
                            referenceId: reloadId,
                            amount: amt,
                            balanceBefore: before,
                            balanceAfter: after,
                            note: 'Mobile reload payment for $op - $phone (Comm: $_currency $comm)',
                            createdAt: DateTime.now().toIso8601String(),
                          );

                          final record = _MobileReloadRecord(
                            id: reloadId,
                            operator: op,
                            phoneNumber: phone,
                            amount: amt,
                            commission: comm,
                            createdAt: DateTime.now(),
                          );

                          setState(() {
                            _cashTransactions.insert(0, tx);
                            _mobileReloads.insert(0, record);
                          });

                          await _persistWorkspaceData();
                          await _enqueueSync('INSERT', 'cash_transactions', tx.id);
                          await _enqueueSync('INSERT', 'mobile_reloads', record.id);

                          phoneController.clear();
                          amountController.clear();

                          if (!localContext.mounted) return;
                          ScaffoldMessenger.of(localContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reload of $_currency ${amt.toStringAsFixed(2)} processed for $phone. Commission: $_currency ${comm.toStringAsFixed(2)}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Submit Reload Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  Widget _buildReloadHistoryTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return StatefulBuilder(
      builder: (context, setSubState) {
        final reloads = _mobileReloads;

        if (reloads.isEmpty) {
          return const Center(
            child: Text(
              'No reload transactions processed yet.',
              style: TextStyle(color: Color(0xFF8780A0), fontSize: 16),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reload History (${reloads.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListView.separated(
                    itemCount: reloads.length,
                    separatorBuilder: (context, index) => Divider(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final item = reloads[index];
                      Color opColor = const Color(0xFF9E9E9E);
                      if (item.operator == 'Dialog') opColor = const Color(0xFFE91E63);
                      if (item.operator == 'Mobitel') opColor = const Color(0xFF4CAF50);
                      if (item.operator == 'Hutch') opColor = const Color(0xFFFF9800);
                      if (item.operator == 'Airtel') opColor = const Color(0xFFF44336);
                      if (item.operator == 'SLT') opColor = const Color(0xFF2196F3);
                      if (item.operator == 'eZ Cash') opColor = const Color(0xFF673AB7);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: opColor.withValues(alpha: 0.12),
                          child: Icon(
                            item.operator == 'eZ Cash' ? Icons.wallet_rounded : Icons.phone_iphone_rounded,
                            color: opColor,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              item.phoneNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: opColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.operator,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: opColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(item.createdAt),
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Commission: ${_money(item.commission)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          _money(item.amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOperatorSettlementsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final operators = ['Dialog', 'Mobitel', 'Hutch', 'Airtel', 'SLT', 'eZ Cash'];

    final formKey = GlobalKey<FormState>();
    final settleAmountController = TextEditingController();
    String selectedSettleOperator = 'Dialog';

    return StatefulBuilder(
      builder: (context, setSubState) {
        final localContext = context;

        final summary = operators.map((op) {
          double sales = 0.0;
          double commissions = 0.0;
          for (final r in _mobileReloads) {
            if (r.operator == op) {
              sales += r.amount;
              commissions += r.commission;
            }
          }
          final double owed = sales - commissions;

          double settled = 0.0;
          for (final tx in _cashTransactions) {
            if (tx.type == 'OUT' &&
                tx.referenceType == 'OPERATOR_SETTLEMENT' &&
                tx.referenceId == op.toUpperCase()) {
              settled += tx.amount;
            }
          }

          final outstanding = owed - settled;

          return {
            'operator': op,
            'sales': sales,
            'commissions': commissions,
            'owed': owed,
            'settled': settled,
            'outstanding': outstanding,
          };
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 950;

              final tablePanel = Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Operator')),
                        DataColumn(label: Text('Total Sales'), numeric: true),
                        DataColumn(label: Text('Earned Commission'), numeric: true),
                        DataColumn(label: Text('Net Owed'), numeric: true),
                        DataColumn(label: Text('Total Settled'), numeric: true),
                        DataColumn(label: Text('Outstanding Owed'), numeric: true),
                      ],
                      rows: summary.map((s) {
                        final outstanding = s['outstanding'] as double;
                        return DataRow(
                          cells: [
                            DataCell(Text(s['operator'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(_money(s['sales'] as double))),
                            DataCell(Text(_money(s['commissions'] as double), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600))),
                            DataCell(Text(_money(s['owed'] as double))),
                            DataCell(Text(_money(s['settled'] as double))),
                            DataCell(
                              Text(
                                _money(outstanding),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: outstanding > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );

              final formPanel = Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Record Operator Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedSettleOperator,
                        decoration: const InputDecoration(
                          labelText: 'Select Operator',
                          border: OutlineInputBorder(),
                        ),
                        items: operators.map((op) {
                          return DropdownMenuItem(
                            value: op,
                            child: Text(op),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setSubState(() {
                            selectedSettleOperator = v;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: settleAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Settlement Amount',
                          prefixText: '$_currency ',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final amt = double.tryParse(value.trim());
                          if (amt == null || amt <= 0) {
                            return 'Please enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final op = selectedSettleOperator;
                              final amt = double.parse(settleAmountController.text.trim());

                              final before = _cashInHand;
                              final after = before - amt;

                              final txId = 'CTX-${DateTime.now().millisecondsSinceEpoch}';

                              final tx = _CashTransactionItem(
                                id: txId,
                                type: 'OUT',
                                referenceType: 'OPERATOR_SETTLEMENT',
                                referenceId: op.toUpperCase(),
                                amount: amt,
                                balanceBefore: before,
                                balanceAfter: after,
                                note: 'Settlement payment to $op operator',
                                createdAt: DateTime.now().toIso8601String(),
                              );

                              setState(() {
                                _cashTransactions.insert(0, tx);
                              });

                              await _persistWorkspaceData();
                              await _enqueueSync('INSERT', 'cash_transactions', tx.id);

                              settleAmountController.clear();

                              if (!localContext.mounted) return;
                              ScaffoldMessenger.of(localContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Settled payment of $_currency ${amt.toStringAsFixed(2)} recorded for $op.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Record Payment'),
                        ),
                      )
                    ],
                  ),
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: tablePanel),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: formPanel),
                  ],
                );
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    tablePanel,
                    const SizedBox(height: 18),
                    formPanel,
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCommissionSettingsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final operators = ['Dialog', 'Mobitel', 'Hutch', 'Airtel', 'SLT', 'eZ Cash'];

    return StatefulBuilder(
      builder: (context, setSubState) {
        final localContext = context;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure Tiered Operator Commission Rules',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Define multiple range-based commission rules for each provider. The system matches transactions to ranges dynamically.',
                  style: TextStyle(color: Color(0xFF6D7383), fontSize: 13),
                ),
                const SizedBox(height: 24),
                // Build settings edit fields for each operator
                ...operators.map((op) {
                  final tiers = _operatorCommissions[op] ?? [];
                  Color opColor = const Color(0xFF9E9E9E);
                  if (op == 'Dialog') opColor = const Color(0xFFE91E63);
                  if (op == 'Mobitel') opColor = const Color(0xFF4CAF50);
                  if (op == 'Hutch') opColor = const Color(0xFFFF9800);
                  if (op == 'Airtel') opColor = const Color(0xFFF44336);
                  if (op == 'SLT') opColor = const Color(0xFF2196F3);
                  if (op == 'eZ Cash') opColor = const Color(0xFF673AB7);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: opColor.withValues(alpha: 0.3)),
                      color: opColor.withValues(alpha: 0.02),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              op,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: opColor,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setSubState(() {
                                  _operatorCommissions[op] ??= [];
                                  _operatorCommissions[op]!.add({
                                    'min': 0.0,
                                    'max': 999.0,
                                    'type': 'percentage',
                                    'value': 5.0,
                                  });
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              label: const Text('Add Range Tier'),
                              style: TextButton.styleFrom(foregroundColor: opColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (tiers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No ranges configured. Fallback default commission (5.0%) will apply.',
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tiers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, tIndex) {
                              final tier = tiers[tIndex];
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: tier['min'].toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Min Amount',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) {
                                        tier['min'] = double.tryParse(v) ?? 0.0;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: tier['max'].toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Max Amount',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) {
                                        tier['max'] = double.tryParse(v) ?? 999999.0;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: DropdownButtonFormField<String>(
                                      value: tier['type'] as String,
                                      decoration: const InputDecoration(
                                        labelText: 'Rule Type',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                                        DropdownMenuItem(value: 'fixed', child: Text('Fixed Rate')),
                                      ],
                                      onChanged: (v) {
                                        if (v == null) return;
                                        setSubState(() {
                                          tier['type'] = v;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: tier['value'].toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Rate',
                                        suffixText: tier['type'] == 'percentage' ? '%' : _currency,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (v) {
                                        tier['value'] = double.tryParse(v) ?? 0.0;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                    onPressed: () {
                                      setSubState(() {
                                        _operatorCommissions[op]!.removeAt(tIndex);
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _persistWorkspaceData();
                      if (!localContext.mounted) return;
                      ScaffoldMessenger.of(localContext).showSnackBar(
                        const SnackBar(
                          content: Text('Tiered commission rules saved successfully.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text(
                      'Save Multi-Tier Commission Rules',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
