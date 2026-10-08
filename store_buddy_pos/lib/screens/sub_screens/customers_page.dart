part of '../dashboard_screen.dart';

extension _customers_pageExt on _DashboardScreenState {
  Widget _buildCustomersPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final query = _customerSearchController.text.trim().toLowerCase();
    final filtered = _scopedCustomers.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.vehicleNumber.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query);
    }).toList();
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
                    : (color ?? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(UiSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: UiSize.pageMaxContentWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
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
                          child: const Text(
                            'Customer Management',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage customer profiles, vehicle logs, and credit policies.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UiSpacing.md),
              // Search input
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(UiRadius.md),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
                  ),
                  boxShadow: UiShadows.card,
                ),
                child: TextField(
                  controller: _customerSearchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search customers by name, vehicle number, phone, email...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 13.5,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: UiSpacing.md),
              // Data Container Card
              Expanded(
                child: Container(
                  width: double.infinity,
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
                    child: Padding(
                      padding: const EdgeInsets.all(UiSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Profiles',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _canManageCatalog
                                    ? () async {
                                        final customer = await _showCustomerDialog();
                                        if (customer == null) return;
                                        customer.locationId = _activeLocationForWrites;
                                        setState(() => _customers.add(customer));
                                        await _persistWorkspaceData();

                                        if (_customerRepository != null) {
                                          await _customerRepository!.insertCustomer(
                                            _toDomainCustomer(customer),
                                          );
                                          await _refreshPendingSyncQueue();
                                          await _triggerImmediateSync(
                                            action: 'INSERT',
                                            module: 'customers',
                                            reference: customer.id,
                                          );
                                        } else {
                                          await _enqueueSync(
                                            'INSERT',
                                            'customers',
                                            customer.id,
                                          );
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brandIndigo,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(UiRadius.md),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: UiSpacing.sm),
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.groups_outlined,
                                          size: 48,
                                          color: colorScheme.onSurface.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: UiSpacing.sm),
                                        Text(
                                          'No customers found. Add your first customer to get started.',
                                          style: TextStyle(
                                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                                            fontSize: 13.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth,
                                          ),
                                          child: Theme(
                                            data: Theme.of(context).copyWith(
                                              dividerColor: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
                                            ),
                                            child: DataTable(
                                              showCheckboxColumn: false,
                                              horizontalMargin: UiSpacing.sm,
                                              columnSpacing: UiSpacing.md,
                                              headingRowColor: WidgetStateProperty.all(
                                                isDark
                                                    ? const Color(0xFF1F2937).withValues(alpha: 0.4)
                                                    : const Color(0xFFF1F5F9),
                                              ),
                                              columns: const [
                                                DataColumn(
                                                  label: Text('CUSTOMER'),
                                                ),
                                                DataColumn(
                                                  label: Text('VEHICLE NO'),
                                                ),
                                                DataColumn(label: Text('PHONE')),
                                                DataColumn(label: Text('EMAIL')),
                                                DataColumn(
                                                  label: Text('CREDIT LIMIT'),
                                                ),
                                                DataColumn(
                                                  label: Text('ACTIONS'),
                                                ),
                                              ],
                                              rows: filtered.map((c) {
                                                return DataRow(
                                                  onSelectChanged: (_) => _showCustomerDetails(c),
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        c.name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: c.vehicleNumber.isEmpty
                                                              ? Colors.transparent
                                                              : colorScheme.secondary.withValues(alpha: 0.08),
                                                          borderRadius: BorderRadius.circular(UiRadius.xs),
                                                          border: c.vehicleNumber.isEmpty
                                                              ? null
                                                              : Border.all(
                                                                  color: colorScheme.secondary.withValues(alpha: 0.2),
                                                                ),
                                                        ),
                                                        child: Text(
                                                          c.vehicleNumber.isEmpty
                                                              ? 'N/A'
                                                              : c.vehicleNumber,
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight: c.vehicleNumber.isEmpty
                                                                ? FontWeight.normal
                                                                : FontWeight.w600,
                                                            color: c.vehicleNumber.isEmpty
                                                                ? colorScheme.onSurface.withValues(alpha: 0.5)
                                                                : colorScheme.secondary,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        c.phone,
                                                        style: const TextStyle(
                                                          fontFamily: 'monospace',
                                                          fontSize: 12.5,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        c.email.isEmpty ? 'N/A' : c.email,
                                                        style: TextStyle(
                                                          color: c.email.isEmpty
                                                              ? colorScheme.onSurface.withValues(alpha: 0.4)
                                                              : colorScheme.onSurface,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _money(c.creditLimit),
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        children: [
                                                          customerActionButton(
                                                            tooltip: 'View Details',
                                                            onPressed: () => _showCustomerDetails(c),
                                                            icon: Icons.visibility_outlined,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          customerActionButton(
                                                            tooltip: 'Edit Profile',
                                                            onPressed: _canManageCatalog
                                                                ? () async {
                                                                    final edited =
                                                                        await _showCustomerDialog(
                                                                          existing: c,
                                                                        );
                                                                    if (edited == null) return;
                                                                    setState(() {
                                                                      final i = _customers
                                                                          .indexWhere(
                                                                            (x) => x.id == c.id,
                                                                          );
                                                                      _customers[i] = edited;
                                                                    });
                                                                    await _persistWorkspaceData();

                                                                    if (_customerRepository != null) {
                                                                      await _customerRepository!.updateCustomer(
                                                                        _toDomainCustomer(edited),
                                                                      );
                                                                      await _refreshPendingSyncQueue();
                                                                      await _triggerImmediateSync(
                                                                        action: 'UPDATE',
                                                                        module: 'customers',
                                                                        reference: edited.id,
                                                                      );
                                                                    } else {
                                                                      await _enqueueSync(
                                                                        'UPDATE',
                                                                        'customers',
                                                                        edited.id,
                                                                      );
                                                                    }
                                                                  }
                                                                : null,
                                                            icon: Icons.edit_outlined,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          customerActionButton(
                                                            tooltip: 'Delete Customer',
                                                            onPressed: _canManageCatalog
                                                                ? () async {
                                                                    setState(() {
                                                                      _customers.removeWhere(
                                                                        (x) => x.id == c.id,
                                                                      );
                                                                      _customerCreditPayments.remove(c.id);
                                                                    });
                                                                    await _persistWorkspaceData();

                                                                    if (_customerRepository != null) {
                                                                      await _customerRepository!.deleteCustomer(
                                                                        c.id,
                                                                      );
                                                                      await _refreshPendingSyncQueue();
                                                                      await _triggerImmediateSync(
                                                                        action: 'DELETE',
                                                                        module: 'customers',
                                                                        reference: c.id,
                                                                      );
                                                                    } else {
                                                                      await _enqueueSync(
                                                                        'DELETE',
                                                                        'customers',
                                                                        c.id,
                                                                      );
                                                                    }
                                                                  }
                                                                : null,
                                                            icon: Icons.delete_outline,
                                                            color: AppTheme.brandRose,
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomerDetails(_CustomerItem customer) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CustomerDetails',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        final colorScheme = Theme.of(context).colorScheme;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return _SideSheetContainer(
          title: customer.name,
          width: _adaptiveWidth(680, minWidth: 360, horizontalPadding: 0),
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              // Fetch customer specific data dynamically so updates reflect in real-time
              final customerSales = _sales
                  .where((s) => s.customerId == customer.id)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              final creditSales = _scopedCreditSales(customer.id);
              final plans = _scopedInstallmentPlans
                  .where((p) => p.customerId == customer.id)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              final totalOutstandingCredit = _customerOutstandingBalance(
                customer.id,
                fallback: customer.currentBalance,
              );
              final totalInstallmentsOwed = plans.fold<double>(
                0.0,
                (sum, p) => sum + p.remainingAmount,
              );

              return DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge in the content area
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 16, right: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          customer.customerType,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Contact / Details Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _customerDetailRow(Icons.phone_outlined, 'Phone', customer.phone),
                            const SizedBox(height: 10),
                            _customerDetailRow(
                              Icons.email_outlined,
                              'Email',
                              customer.email.isEmpty ? 'N/A' : customer.email,
                            ),
                            const SizedBox(height: 10),
                            _customerDetailRow(
                              Icons.directions_car_outlined,
                              'Vehicle No',
                              customer.vehicleNumber.isEmpty ? 'N/A' : customer.vehicleNumber,
                            ),
                            const SizedBox(height: 10),
                            _customerDetailRow(
                              Icons.location_on_outlined,
                              'Address',
                              customer.address.isEmpty ? 'N/A' : customer.address,
                            ),
                            if (customer.notes.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _customerDetailRow(Icons.note_alt_outlined, 'Notes', customer.notes),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Financial metrics summary cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _financialCard(
                              title: 'Credit Balance',
                              value: _money(totalOutstandingCredit),
                              subText: 'Limit: ${_money(customer.creditLimit)}',
                              color: totalOutstandingCredit > 0
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _financialCard(
                              title: 'Installments Owed',
                              value: _money(totalInstallmentsOwed),
                              subText: '${plans.where((p) => p.remainingAmount > 0).length} active plans',
                              color: totalInstallmentsOwed > 0
                                  ? const Color(0xFFED6C02)
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tabs
                    TabBar(
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                      indicatorColor: colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Sales History'),
                        Tab(text: 'Credit Log'),
                        Tab(text: 'Installments'),
                      ],
                    ),

                    // Tab Bar Views
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildCustomerSalesTab(customerSales),
                          _buildCustomerCreditTab(customer, creditSales, () {
                            setState(() {});
                            setLocalState(() {});
                          }),
                          _buildCustomerInstallmentsTab(plans, () {
                            setState(() {});
                            setLocalState(() {});
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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

  Widget _customerDetailRow(IconData icon, String label, String value) {
    final isDark = Theme.of(this.context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xDD000000),
            ),
          ),
        ),
      ],
    );
  }

  Widget _financialCard({
    required String title,
    required String value,
    required String subText,
    required Color color,
  }) {
    final isDark = Theme.of(this.context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF64748B) : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSalesTab(List<_SaleRecord> sales) {
    if (sales.isEmpty) {
      return const Center(child: Text('No sales found for this customer.'));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        final soldItemCount = sale.items.fold<double>(
          0,
          (sum, item) => sum + item.quantity,
        );
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiRadius.md),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text(
                  'Invoice: ${sale.id}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const Spacer(),
                Text(
                  _money(sale.total),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    '${_formatDate(sale.createdAt)}  •  $soldItemCount items',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _paymentMethodColor(sale.paymentMethod).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sale.paymentMethod,
                      style: TextStyle(
                        color: _paymentMethodColor(sale.paymentMethod),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...sale.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} x${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${_money(item.unitPrice)} ea  -  ${_money(item.lineTotal)}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showSaleDetails(sale),
                    icon: const Icon(Icons.receipt_outlined, size: 14),
                    label: const Text('View Full Invoice', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _paymentMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return Colors.green;
      case 'CARD':
        return Colors.blue;
      case 'CHEQUE':
        return Colors.amber.shade800;
      case 'CREDIT':
        return Colors.red;
      case 'INSTALLMENT':
        return Colors.orange.shade800;
      default:
        return Colors.purple;
    }
  }

  Widget _buildCustomerCreditTab(
    _CustomerItem customer,
    List<_CreditSaleEntry> entries,
    VoidCallback onPaymentRecorded,
  ) {
    final outstanding = _customerOutstandingBalance(
      customer.id,
      fallback: customer.currentBalance,
    );
    return Column(
      children: [
        if (outstanding > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await _recordCustomerCreditPayment(customer);
                onPaymentRecorded();
              },
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Record Credit Payment'),
            ),
          ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('No credit sales found.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          const Text('Sale: ', style: TextStyle(color: Colors.black54, fontSize: 14)),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                final sale = _sales.firstWhere(
                                  (s) => s.id == entry.saleId,
                                  orElse: () => _SaleRecord(
                                    id: entry.saleId,
                                    invoiceNumber: entry.invoiceNumber,
                                    locationId: entry.locationId,
                                    customerName: entry.customerName,
                                    paymentMethod: entry.paymentMethod,
                                    items: const [],
                                    subtotal: entry.subtotal,
                                    tax: entry.tax,
                                    total: entry.total,
                                    amountPaid: entry.amountPaidOnSale,
                                    balance: entry.outstandingAmount,
                                    chequeNumber: '',
                                    status: 'COMPLETED',
                                    createdAt: entry.createdAt,
                                  ),
                                );
                                _showSaleDetails(sale);
                              },
                              child: Text(
                                entry.invoiceNumber.isNotEmpty
                                    ? entry.invoiceNumber
                                    : entry.saleId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Owed: ${_money(entry.outstandingAmount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(
                              '${_formatDate(entry.createdAt)}  •  Total: ${_money(entry.total)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              entry.outstandingAmount <= 0 ? 'Fully Paid' : 'Pending',
                              style: TextStyle(
                                color: entry.outstandingAmount <= 0 ? Colors.green : Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomerInstallmentsTab(
    List<_InstallmentPlan> plans,
    VoidCallback onPaymentRecorded,
  ) {
    if (plans.isEmpty) {
      return const Center(child: Text('No installment plans found.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final plan = plans[index];
        final pendingAmount = plan.schedules
            .where((schedule) => !schedule.isPaid)
            .fold<double>(
              0,
              (sum, schedule) => sum + schedule.remainingAmount,
            );
        if ((plan.remainingAmount - pendingAmount).abs() > 0.009) {
          plan.remainingAmount = double.parse(pendingAmount.toStringAsFixed(2));
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            childrenPadding: const EdgeInsets.all(12),
            title: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final sale = _sales.firstWhere(
                        (s) => s.id == plan.saleId,
                        orElse: () => _SaleRecord(
                          id: plan.saleId,
                          invoiceNumber: plan.invoiceNumber,
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
                        ),
                      );
                      _showSaleDetails(sale);
                    },
                    child: Text(
                      plan.invoiceNumber.isNotEmpty
                          ? plan.invoiceNumber
                          : plan.saleId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Owed: ${_money(plan.remainingAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.orange),
                ),
              ],
            ),
            subtitle: Text(
              '${plan.numberOfInstallments} installments  •  Created: ${_formatDate(plan.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            children: [
              ...plan.schedules.map((schedule) {
                final scheduleIndex = schedule.installmentNo - 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '#${schedule.installmentNo}  •  Due: ${_formatDate(schedule.dueDate)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        _money(schedule.amount),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (schedule.isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          schedule.isPaid
                              ? 'Paid'
                              : schedule.paidAmount > 0
                                  ? 'Partial'
                                  : 'Pending',
                          style: TextStyle(
                            color: schedule.isPaid ? Colors.green : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!schedule.isPaid)
                        TextButton(
                          onPressed: () async {
                            final controller = TextEditingController(
                              text: schedule.remainingAmount.toStringAsFixed(2),
                            );
                            final amount = await showDialog<double>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Pay Installment #${schedule.installmentNo}'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Due: ${_money(schedule.remainingAmount)}'),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: controller,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Payment Amount',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final value = double.tryParse(controller.text.trim());
                                      if (value == null || value <= 0) return;
                                      Navigator.pop(context, value);
                                    },
                                    child: const Text('Pay'),
                                  ),
                                ],
                              ),
                            );
                            if (amount == null || amount <= 0) return;

                            setState(() {
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
                            onPaymentRecorded();
                          },
                          child: const Text('Pay'),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
