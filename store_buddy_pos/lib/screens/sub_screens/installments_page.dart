part of '../dashboard_screen.dart';

extension _installments_pageExt on _DashboardScreenState {
  Widget _buildInstallmentsPage() {
    final query = _installmentSearchController.text.trim().toLowerCase();
    final plans = List<_InstallmentPlan>.from(_scopedInstallmentPlans).where((
      plan,
    ) {
      if (query.isEmpty) return true;
      return plan.customerName.toLowerCase().contains(query) ||
          plan.customerPhone.toLowerCase().contains(query) ||
          plan.customerAddress.toLowerCase().contains(query) ||
          plan.saleId.toLowerCase().contains(query) ||
          plan.id.toLowerCase().contains(query) ||
          plan.paymentMethod.toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Installment Management',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text(
            'Track installment plans, due dates, and payable amounts.',
            style: TextStyle(color: Color(0xFF6D7383), fontSize: 16),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: TextField(
              controller: _installmentSearchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search customer, sale, phone, address, or method...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: plans.isEmpty
                ? Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: const Center(
                      child: Text('No installment plans created yet.'),
                    ),
                  )
                : ListView.separated(
                    itemCount: plans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final pendingAmount = plan.schedules
                          .where((schedule) => !schedule.isPaid)
                          .fold<double>(
                            0,
                            (sum, schedule) => sum + schedule.remainingAmount,
                          );
                      if ((plan.remainingAmount - pendingAmount).abs() >
                          0.009) {
                        plan.remainingAmount = double.parse(
                          pendingAmount.toStringAsFixed(2),
                        );
                      }
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Theme.of(context).colorScheme.outline),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            14,
                            0,
                            14,
                            14,
                          ),
                          title: Text(
                            '${plan.customerName} - ${plan.invoiceNumber.isNotEmpty ? plan.invoiceNumber : plan.saleId}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Remaining ${_money(plan.remainingAmount)} | ${plan.numberOfInstallments} installments',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: plan.remainingAmount <= 0
                                  ? const Color(0xFFE8F7EC)
                                  : const Color(0xFFFFF4E5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              plan.remainingAmount <= 0
                                  ? 'Completed'
                                  : 'Active',
                              style: TextStyle(
                                color: plan.remainingAmount <= 0
                                    ? const Color(0xFF2E9C64)
                                    : const Color(0xFFAA6A00),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Total: ${_money(plan.totalAmount)} | Down Payment: ${_money(plan.downPayment)} | Balance: ${_money(plan.remainingAmount)}',
                                  ),
                                ),
                                Text(
                                  'Created: ${_formatDate(plan.createdAt)}',
                                  style: const TextStyle(
                                    color: Color(0xFF7E8495),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final sale = _scopedSales.where(
                                      (item) => item.id == plan.saleId,
                                    );
                                    final resolvedSale = sale.isNotEmpty
                                        ? sale.first
                                        : _SaleRecord(
                                            id: plan.saleId,
                                            locationId: plan.locationId,
                                            customerName: plan.customerName,
                                            paymentMethod: plan.paymentMethod,
                                            items: plan.items,
                                            subtotal: plan.subtotal,
                                            tax: plan.taxAmount,
                                            total: plan.totalAmount,
                                            amountPaid: plan.downPayment,
                                            balance: plan.remainingAmount,
                                            chequeNumber: plan.chequeNumber,
                                            status: 'COMPLETED',
                                            createdAt: plan.createdAt,
                                          );
                                    final updatedSaleRecord = _SaleRecord(
                                      id: resolvedSale.id,
                                      invoiceNumber: resolvedSale.invoiceNumber,
                                      locationId: resolvedSale.locationId,
                                      customerName: resolvedSale.customerName,
                                      customerId: resolvedSale.customerId,
                                      customerPhone: resolvedSale.customerPhone,
                                      customerAddress: resolvedSale.customerAddress,
                                      customerOutstandingBefore: resolvedSale.customerOutstandingBefore,
                                      customerOutstandingAfter: resolvedSale.customerOutstandingAfter,
                                      employeeId: resolvedSale.employeeId,
                                      cashierName: resolvedSale.cashierName,
                                      paymentMethod: resolvedSale.paymentMethod,
                                      items: resolvedSale.items,
                                      installmentSchedules: plan.schedules,
                                      subtotal: resolvedSale.subtotal,
                                      tax: resolvedSale.tax,
                                      discount: resolvedSale.discount,
                                      total: resolvedSale.total,
                                      amountPaid: resolvedSale.amountPaid,
                                      balance: resolvedSale.balance,
                                      chequeNumber: resolvedSale.chequeNumber,
                                      shippingCharges: resolvedSale.shippingCharges,
                                      agentName: resolvedSale.agentName,
                                      agentCommission: resolvedSale.agentCommission,
                                      agentCommissionType: resolvedSale.agentCommissionType,
                                      agentCommissionPaid: resolvedSale.agentCommissionPaid,
                                      status: resolvedSale.status,
                                      returnReason: resolvedSale.returnReason,
                                      createdAt: resolvedSale.createdAt,
                                      notes: resolvedSale.notes,
                                      shippingAddress: resolvedSale.shippingAddress,
                                    );
                                    final lines = plan.items
                                        .map(
                                          (item) => _CartLine(
                                            product: _ProductItem(
                                              id: item.productId,
                                              name: item.productName,
                                              category: 'Item',
                                              price: item.unitPrice,
                                              stock: 0,
                                              minStock: 0,
                                            ),
                                            qty: item.quantity,
                                          ),
                                        )
                                        .toList();
                                    await _printReceipt(
                                      sale: updatedSaleRecord,
                                      lines: lines,
                                    );
                                  },
                                  icon: const Icon(Icons.print_outlined),
                                  label: const Text('Print Bill'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F6FC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFEAE4F4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer: ${plan.customerName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Phone: ${plan.customerPhone.isEmpty ? 'N/A' : plan.customerPhone}',
                                  ),
                                  Text(
                                    'Address: ${plan.customerAddress.isEmpty ? 'N/A' : plan.customerAddress}',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Payment Method: ${plan.paymentMethod}${plan.chequeNumber.isEmpty ? '' : ' (Cheque: ${plan.chequeNumber})'}',
                                  ),
                                  Text(
                                    'Bill: Subtotal ${_money(plan.subtotal)} | Tax ${_money(plan.taxAmount)} | Total ${_money(plan.totalAmount)}',
                                  ),
                                ],
                              ),
                            ),
                            if (plan.items.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEAE4F4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Purchased Items',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...plan.items.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          '${item.productName} x${item.quantity} @ ${_money(item.unitPrice)} = ${_money(item.lineTotal)}',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF7F4FC),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(10),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Expanded(child: Text('Installment')),
                                        Expanded(child: Text('Amount')),
                                        Expanded(child: Text('Due Date')),
                                        Expanded(child: Text('Status')),
                                        Expanded(child: Text('Actions')),
                                      ],
                                    ),
                                  ),
                                  ...plan.schedules.map((schedule) {
                                    final scheduleIndex =
                                        schedule.installmentNo - 1;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Color(0xFFF0EDF8),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '#${schedule.installmentNo}',
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              _money(schedule.amount),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              _formatDate(schedule.dueDate),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              schedule.isPaid
                                                  ? 'Paid'
                                                  : schedule.paidAmount > 0
                                                  ? 'Partial'
                                                  : 'Pending',
                                              style: TextStyle(
                                                color: schedule.isPaid
                                                    ? const Color(0xFF2E9C64)
                                                    : schedule.paidAmount > 0
                                                    ? const Color(0xFF1976D2)
                                                    : const Color(0xFFAA6A00),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Wrap(
                                              spacing: 2,
                                              runSpacing: 0,
                                              children: [
                                                TextButton(
                                                  onPressed:
                                                      schedule.isPaid ||
                                                          schedule.paidAmount >
                                                              0
                                                      ? null
                                                      : () async {
                                                          final controller =
                                                              TextEditingController(
                                                                text: schedule
                                                                    .amount
                                                                    .toStringAsFixed(
                                                                      2,
                                                                    ),
                                                              );
                                                          final result = await showDialog<double>(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                title: Text(
                                                                  'Edit Installment #${schedule.installmentNo}',
                                                                ),
                                                                content: TextField(
                                                                  controller:
                                                                      controller,
                                                                  keyboardType:
                                                                      const TextInputType.numberWithOptions(
                                                                        decimal:
                                                                            true,
                                                                      ),
                                                                  decoration: const InputDecoration(
                                                                    labelText:
                                                                        'Amount',
                                                                    border:
                                                                        OutlineInputBorder(),
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                          context,
                                                                        ),
                                                                    child: const Text(
                                                                      'Cancel',
                                                                    ),
                                                                  ),
                                                                  ElevatedButton(
                                                                    onPressed: () {
                                                                      final value = double.tryParse(
                                                                        controller
                                                                            .text
                                                                            .trim(),
                                                                      );
                                                                      if (value ==
                                                                          null) {
                                                                        return;
                                                                      }
                                                                      Navigator.pop(
                                                                        context,
                                                                        value,
                                                                      );
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                          'Save',
                                                                        ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                          if (result == null)
                                                            return;

                                                          setState(() {
                                                            _updateInstallmentScheduleAmount(
                                                              plan: plan,
                                                              scheduleIndex:
                                                                  scheduleIndex,
                                                              newAmount: result,
                                                            );
                                                            final nextBalance = plan
                                                                .schedules
                                                                .where(
                                                                  (
                                                                    item,
                                                                  ) => !item
                                                                      .isPaid,
                                                                )
                                                                .fold<double>(
                                                                  0,
                                                                  (sum, item) =>
                                                                      sum +
                                                                      item.amount,
                                                                );
                                                            plan.remainingAmount =
                                                                double.parse(
                                                                  nextBalance
                                                                      .toStringAsFixed(
                                                                        2,
                                                                      ),
                                                                );
                                                          });
                                                          await _persistWorkspaceData();
                                                          await _enqueueSync(
                                                            'UPDATE',
                                                            'installments',
                                                            plan.id,
                                                          );
                                                        },
                                                  child: const Text('Amount'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    final picked =
                                                        await showDatePicker(
                                                          context: context,
                                                          initialDate:
                                                              schedule.dueDate,
                                                          firstDate: DateTime(
                                                            2020,
                                                          ),
                                                          lastDate: DateTime(
                                                            2100,
                                                          ),
                                                        );
                                                    if (picked == null) {
                                                      return;
                                                    }

                                                    setState(() {
                                                      schedule.dueDate =
                                                          DateTime(
                                                            picked.year,
                                                            picked.month,
                                                            picked.day,
                                                          );
                                                    });
                                                    await _persistWorkspaceData();
                                                    await _enqueueSync(
                                                      'UPDATE',
                                                      'installments',
                                                      plan.id,
                                                    );
                                                  },
                                                  child: const Text('Date'),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      schedule.remainingAmount <=
                                                          0.009
                                                      ? null
                                                      : () async {
                                                          final controller =
                                                              TextEditingController(
                                                                text: schedule
                                                                    .remainingAmount
                                                                    .toStringAsFixed(
                                                                      2,
                                                                    ),
                                                              );
                                                          final amount = await showDialog<double>(
                                                            context: context,
                                                            builder: (context) => AlertDialog(
                                                              title: Text(
                                                                'Pay Installment #${schedule.installmentNo}',
                                                              ),
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    'Due: ${_money(schedule.remainingAmount)}',
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  TextField(
                                                                    controller:
                                                                        controller,
                                                                    keyboardType:
                                                                        const TextInputType.numberWithOptions(
                                                                          decimal:
                                                                              true,
                                                                        ),
                                                                    decoration: const InputDecoration(
                                                                      labelText:
                                                                          'Payment Amount',
                                                                      border:
                                                                          OutlineInputBorder(),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                      ),
                                                                  child:
                                                                      const Text(
                                                                        'Cancel',
                                                                      ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () {
                                                                    final value = double.tryParse(
                                                                      controller
                                                                          .text
                                                                          .trim(),
                                                                    );
                                                                    if (value ==
                                                                            null ||
                                                                        value <=
                                                                            0) {
                                                                      return;
                                                                    }
                                                                    Navigator.pop(
                                                                      context,
                                                                      value,
                                                                    );
                                                                  },
                                                                  child:
                                                                      const Text(
                                                                        'Pay',
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                          if (amount == null ||
                                                              amount <= 0) {
                                                            return;
                                                          }

                                                          final balanceBefore =
                                                              plan.remainingAmount;
                                                          late List<
                                                            domain.InstallmentPaymentLine
                                                          >
                                                          allocations;
                                                          setState(() {
                                                            allocations =
                                                                _applyInstallmentPayment(
                                                                  plan,
                                                                  scheduleIndex,
                                                                  amount,
                                                                );
                                                          });
                                                          await _persistWorkspaceData();
                                                          await _enqueueSync(
                                                            'UPDATE',
                                                            'installments',
                                                            plan.id,
                                                          );

                                                          await _showInstallmentReceiptPreviewDialog(
                                                            customerName: plan
                                                                .customerName,
                                                            customerPhone: plan
                                                                .customerPhone,
                                                            customerAddress: plan
                                                                .customerAddress,
                                                            planId: plan.id,
                                                            saleId: plan.saleId,
                                                            paymentMethod: plan
                                                                .paymentMethod,
                                                            paymentAmount:
                                                                amount,
                                                            balanceBefore:
                                                                balanceBefore,
                                                            balanceAfter: plan
                                                                .remainingAmount,
                                                            note: '',
                                                            items: plan.items,
                                                            schedules:
                                                                plan.schedules,
                                                            allocations:
                                                                allocations,
                                                          );
                                                        },
                                                  child: const Text('Pay'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
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
    );
  }

  Future<void> _showInstallmentReceiptPreviewDialog({
    required String customerName,
    required String customerPhone,
    required String? customerAddress,
    required String planId,
    required String saleId,
    required String paymentMethod,
    required double paymentAmount,
    required double balanceBefore,
    required double balanceAfter,
    required String note,
    required List<dynamic> items,
    required List<dynamic> schedules,
    required List<domain.InstallmentPaymentLine> allocations,
  }) async {
    final settings = await _currentPrintSettings();
    if (!mounted) return;
    final currencySymbol = _currency == 'LKR'
        ? 'Rs.'
        : _currency == 'USD'
        ? '\$'
        : _currency;
    final storeName = _companyName;
    final storeAddress = _companyAddress.trim().isEmpty
        ? _storeLocation
        : _companyAddress;
    final storePhone = _companyPhone;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'InstallmentReceiptPreview',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth < 600 ? screenWidth : 550.0;
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF111827)
                : Colors.white,
            child: SizedBox(
              width: dialogWidth,
              height: double.infinity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE6E2EF),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Installment Receipt Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        primaryColor: const Color(0xFF1E88E5),
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: const Color(0xFF1E88E5),
                          secondary: const Color(0xFF1E88E5),
                        ),
                      ),
                      child: PdfPreview(
                        build: (format) =>
                            PrintService.generateInstallmentPaymentReceiptPdf(
                              customerName: customerName,
                              customerPhone: customerPhone,
                              customerAddress: customerAddress,
                              planId: planId,
                              saleId: saleId,
                              paymentMethod: paymentMethod,
                              paymentAmount: paymentAmount,
                              balanceBefore: balanceBefore,
                              balanceAfter: balanceAfter,
                              note: note,
                              items: items,
                              schedules: schedules,
                              allocations: allocations,
                              settings: settings,
                              currencySymbol: currencySymbol,
                              storeName: storeName,
                              storeAddress: storeAddress,
                              storePhone: storePhone,
                            ),
                        allowPrinting: true,
                        allowSharing: true,
                        canChangePageFormat: false,
                        canDebug: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );
  }
}
