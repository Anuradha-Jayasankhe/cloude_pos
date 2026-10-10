part of '../dashboard_screen.dart';

extension _point_of_saleExt on _DashboardScreenState {
  Future<void> _triggerOpenRegisterDialog() async {
    double previousKeptCash = 0.0;
    try {
      final locationId = _activeLocationForWrites;
      final prev = _cashierSessions.firstWhere(
        (s) => s.status == 'CLOSED' && s.locationId == locationId,
      );
      previousKeptCash = prev.keptCash;
    } catch (_) {}

    final openingCashStr = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final ctrl = TextEditingController(
          text: previousKeptCash.toStringAsFixed(2),
        );
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Open Register Session',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (previousKeptCash > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Last closed shift left ${_money(previousKeptCash)} kept in drawer change. Pre-populated starting cash.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'You must open a register session before checking out. Enter the starting cashier drawer cash amount.',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      'Opening Cash (${_currency == 'LKR' ? 'Rs.' : _currency})',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amt = double.tryParse(ctrl.text.trim());
                if (amt == null || amt < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid starting cash amount',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, ctrl.text.trim());
              },
              child: const Text('Open Register'),
            ),
          ],
        );
      },
    );

    if (openingCashStr == null) {
      return;
    }

    final openingCash = double.tryParse(openingCashStr) ?? 0.0;
    await _openSession(_currentUserId, _currentUserName, openingCash);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Register session opened for $_currentUserName with ${_currency == 'LKR' ? 'Rs.' : _currency} ${openingCash.toStringAsFixed(2)}',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _handleBarcodeOrSearchScan(String val) async {
    final trimmedVal = val.trim();
    if (trimmedVal.isEmpty) return;

    // 1. Check IMEI match first
    final imeiMatchedProduct = _findProductByImei(trimmedVal);
    if (imeiMatchedProduct != null) {
      final exactImei = imeiMatchedProduct.imeiList.firstWhere(
        (x) => x.toLowerCase() == trimmedVal.toLowerCase(),
        orElse: () => trimmedVal,
      );
      _addToCartWithImeiSelection(imeiMatchedProduct, exactImei);
      _productSearchController.clear();
      _posProductSearchFocusNode.requestFocus();
      return;
    }

    // 2. Check Barcode or ID / SKU match
    final matchedList = _scopedProducts
        .where(
          (p) =>
              (p.barcode.trim().isNotEmpty &&
                  p.barcode.trim().toLowerCase() == trimmedVal.toLowerCase()) ||
              p.id.trim().toLowerCase() == trimmedVal.toLowerCase(),
        )
        .toList();

    if (matchedList.isNotEmpty) {
      if (matchedList.length > 1) {
        _showProductSkuSelectionDialog(matchedList);
      } else {
        final p = matchedList.first;
        final sameNameProducts = _scopedProducts
            .where(
              (sp) =>
                  sp.name.trim().toLowerCase() == p.name.trim().toLowerCase(),
            )
            .toList();

        if (sameNameProducts.length > 1) {
          _showProductSkuSelectionDialog(sameNameProducts);
        } else {
          if (p.allowLooseSales) {
            _showDualUnitSelectionDialog(p);
          } else {
            _addToCartWithImeiSelection(p);
          }
          _productSearchController.clear();
          _posProductSearchFocusNode.requestFocus();
        }
      }
      return;
    }

    // 3. Fallback exact Name match
    final exactNameMatched = _scopedProducts
        .where((p) => p.name.trim().toLowerCase() == trimmedVal.toLowerCase())
        .toList();
    if (exactNameMatched.length == 1) {
      final p = exactNameMatched.first;
      if (p.allowLooseSales) {
        _showDualUnitSelectionDialog(p);
      } else {
        _addToCartWithImeiSelection(p);
      }
      _productSearchController.clear();
      _posProductSearchFocusNode.requestFocus();
      return;
    }

    // 4. Barcode not registered: Offer prompt to add new product with this barcode
    if (!mounted) return;
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Barcode Not Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trimmedVal,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This barcode is not registered in your product catalog. Would you like to create and add this new product to inventory now?',
              style: TextStyle(fontSize: 13, height: 1.4),
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
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Product & Add to Cart'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );

    if (shouldAdd == true && mounted) {
      final result = await _showProductDialog(barcode: trimmedVal);
      if (result != null && mounted) {
        await _handleProductCreation(result);
        if (!mounted) return;
        final createdProduct = _products.firstWhere(
          (p) => p.id == result.product.id || p.barcode == result.product.barcode,
          orElse: () => result.product,
        );
        if (createdProduct.allowLooseSales) {
          _showDualUnitSelectionDialog(createdProduct);
        } else {
          _addToCartWithImeiSelection(createdProduct);
        }
        _productSearchController.clear();
        _posProductSearchFocusNode.requestFocus();
      }
    } else {
      _productSearchController.clear();
      _posProductSearchFocusNode.requestFocus();
    }
  }

  Future<_ServiceJobItem?> _showPosServicePickerDialog() async {
    final activeServices = _serviceJobs
        .where((service) => service.active)
        .toList();
    if (activeServices.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active services available. Add services first.'),
        ),
      );
      return null;
    }

    return showDialog<_ServiceJobItem>(
      context: context,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final filtered = activeServices.where((service) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              return service.title.toLowerCase().contains(q) ||
                  service.sku.toLowerCase().contains(q) ||
                  service.description.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              title: const Text('Add Service to Bill'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) => setLocalState(() => query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search services',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No services found'),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final service = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(service.title),
                                  subtitle: Text(
                                    '${service.sku.isEmpty ? service.id : service.sku} • ${service.description.isEmpty ? 'Service item' : service.description}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    _money(service.defaultPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onTap: () =>
                                      Navigator.of(context).pop(service),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showExtendCreditLimitDialog(
    _CustomerItem customer,
    double currentOutstanding,
    double outstandingAmount,
  ) async {
    final nextBalance = currentOutstanding + outstandingAmount;
    final controller = TextEditingController(
      text: customer.creditLimit.toStringAsFixed(2),
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'Credit Limit Exceeded',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer: ${customer.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.6),
                    1: FlexColumnWidth(1.2),
                  },
                  children: [
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Credit Limit:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _money(customer.creditLimit),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Current Outstanding:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _money(currentOutstanding),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Current Sale Credit:'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _money(outstandingAmount),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'New Outstanding Balance:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _money(nextBalance),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'This sale exceeds the customer\'s credit limit. Would you like to extend their credit limit to proceed?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'New Credit Limit (LKR)',
                    prefixText: 'LKR ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel Sale'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), // Purple theme color
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newLimit = double.tryParse(controller.text.trim());
                if (newLimit == null || newLimit < nextBalance) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid credit limit of at least ${_money(nextBalance)}',
                      ),
                    ),
                  );
                  return;
                }

                // Update customer locally and in database
                setState(() {
                  customer.creditLimit = newLimit;
                });

                if (_customerRepository != null) {
                  await _customerRepository!.updateCustomer(
                    _toDomainCustomer(customer),
                  );
                }

                await _refreshPendingSyncQueue();
                await _triggerImmediateSync(
                  action: 'UPDATE',
                  module: 'customers',
                  reference: customer.id,
                );

                Navigator.of(ctx).pop(true);
              },
              child: const Text('Update & Proceed'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _buildPosPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = MediaQuery.of(context).size.width < 1100;
    final isAllLocations =
        _selectedLocationScope == _DashboardScreenState._allLocationsLabel;

    final activeSession = _activeSessionFor(_currentUserId);
    if (_isCashier &&
        activeSession == null &&
        !_hasPromptedOpenRegisterThisVisit) {
      _hasPromptedOpenRegisterThisVisit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerOpenRegisterDialog();
      });
    }

    final rawFilteredProducts = _scopedProducts.where((p) {
      final q = _productSearchController.text.trim().toLowerCase();
      final matchCategory =
          _posCategoryFilter == 'All Categories' ||
          p.category == _posCategoryFilter;
      if (!matchCategory) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q);
    }).toList();

    final List<_ProductItem> filteredProducts;
    final Map<String, List<String>> stockBreakdown = {};

    final groupedMap = <String, _ProductItem>{};
    for (final p in rawFilteredProducts) {
      final key = p.name.trim().toLowerCase();

      final locName = p.locationId.trim().isEmpty
          ? 'Main Branch'
          : p.locationId;
      stockBreakdown.putIfAbsent(key, () => []).add('$locName: ${p.stock}');

      if (groupedMap.containsKey(key)) {
        final existing = groupedMap[key]!;
        existing.stock += p.stock;
      } else {
        groupedMap[key] = _ProductItem(
          id: p.id,
          name: p.name,
          locationId: p.locationId,
          category: p.category,
          barcode: p.barcode,
          measureUnit: p.measureUnit,
          productType: p.productType,
          description: p.description,
          costPrice: p.costPrice,
          warrantyMonths: p.warrantyMonths,
          expiryDate: p.expiryDate,
          expiryReminderMode: p.expiryReminderMode,
          expiryReminderDays: p.expiryReminderDays,
          attributeValues: p.attributeValues,
          price: p.price,
          minPrice: p.minPrice,
          stock: p.stock,
          minStock: p.minStock,
          supplierId: p.supplierId,
        );
      }
    }
    filteredProducts = groupedMap.values.toList();

    final discountCustomer = _selectedCustomerId == null
        ? _CustomerItem(
            id: 'C001',
            name: 'Walk-in Customer',
            locationId: _activeLocationForWrites,
            phone: 'N/A',
            email: '',
          )
        : _scopedCustomers.firstWhere(
            (c) => c.id == _selectedCustomerId,
            orElse: () => _CustomerItem(
              id: 'C001',
              name: 'Walk-in Customer',
              locationId: _activeLocationForWrites,
              phone: 'N/A',
              email: '',
            ),
          );

    final cartItems = _cart.entries
        .map((e) {
          final product = _resolveCartItemProduct(e.key);
          if (product == null) return null;
          final discount =
              _posLineDiscounts[e.key] ?? _autoDiscountForProduct(product);
          return _CartLine(
            product: product,
            qty: e.value,
            discountValue: discount?.value ?? 0.0,
            discountType: discount?.type ?? 'FIXED',
            discountLabel: discount?.label ?? '',
          );
        })
        .whereType<_CartLine>()
        .toList();
    final rawSubtotal = cartItems.fold<double>(0, (s, c) => s + c.totalPrice);
    double invoiceDiscountAmount = 0.0;
    if (_posInvoiceDiscountType == 'PERCENT') {
      invoiceDiscountAmount = rawSubtotal * (_posInvoiceDiscountValue / 100);
    } else {
      invoiceDiscountAmount = _posInvoiceDiscountValue;
    }
    final subtotal = (rawSubtotal - invoiceDiscountAmount).clamp(
      0.0,
      double.infinity,
    );

    final taxRate = double.tryParse(_taxRate) ?? 0;
    final taxAmount = _posApplyTax ? subtotal * (taxRate / 100) : 0.0;
    final paymentMethod = _paymentMethodController.text.isEmpty
        ? 'CASH'
        : _paymentMethodController.text;
    final isCodPayment = paymentMethod == 'COD';
    final shippingCharges =
        (_enableShippingCharges || isCodPayment) ? _posShippingCharges : 0.0;
    final grandTotal = subtotal + taxAmount + shippingCharges;
    final isChequePayment = paymentMethod == 'CHEQUE';
    final isInstallmentPayment = paymentMethod == 'INSTALLMENT';
    final allowsManualPaidAmount = _allowsManualPaidAmount(paymentMethod);
    final rawPaidAmount =
        double.tryParse(_amountPaidController.text.trim()) ?? 0;
    final effectivePaidAmount = allowsManualPaidAmount
        ? rawPaidAmount
        : grandTotal;
    final balanceAmount = (grandTotal - effectivePaidAmount)
        .clamp(0, double.infinity)
        .toDouble();
    final changeAmount = (effectivePaidAmount - grandTotal)
        .clamp(0, double.infinity)
        .toDouble();

    if (!allowsManualPaidAmount) {
      final autoPaidText = grandTotal.toStringAsFixed(2);
      if (_amountPaidController.text != autoPaidText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _amountPaidController.text = autoPaidText;
        });
      }
    }

    final posCategories = ['All Categories', ..._productCategories];
    final scopedCustomers = _scopedCustomers;
    final selectedCustomer = discountCustomer;
    final selectedCustomerOutstanding = _customerOutstandingBalance(
      selectedCustomer.id,
      fallback: selectedCustomer.currentBalance,
    );
    final hasOverdueCredit = _hasOverdueCreditForCustomer(selectedCustomer);
    final oldestOverdueDate = _oldestOverdueDateForCustomer(selectedCustomer);
    if (_posCustomerSearchController.text.trim().isEmpty) {
      if (_selectedCustomerId != null &&
          selectedCustomer.name.toLowerCase() != 'walk-in customer') {
        _posCustomerSearchController.text = selectedCustomer.name;
      } else {
        _posCustomerSearchController.clear();
      }
    }

    final installmentCount = _posInstallmentCount.clamp(1, 60).toInt();
    final installmentIntervalDays = _posInstallmentIntervalDays
        .clamp(1, 365)
        .toInt();
    final installmentDueDates =
        _posInstallmentDueDates.length == installmentCount
        ? List<DateTime>.from(_posInstallmentDueDates)
        : _generateInstallmentDueDates(
            installments: installmentCount,
            intervalDays: installmentIntervalDays,
          );
    _syncPosInstallmentAmounts(balanceAmount);
    final installmentAmounts = List<double>.from(_posInstallmentAmounts);
    final installmentPlannedTotal = installmentAmounts.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final installmentDifference = (balanceAmount - installmentPlannedTotal)
        .toDouble();
    const toolbarControlHeight = 52.0;
    final toolbarBgColor = isDark
        ? const Color(0xFF111827)
        : const Color.fromARGB(255, 255, 255, 255);
    final toolbarBorderColor = isDark
        ? const Color(0xFF1E2D45)
        : const Color.fromARGB(255, 226, 226, 226);
    final controlBorderColor = isDark
        ? const Color(0xFF1E2D45)
        : const Color.fromARGB(255, 222, 222, 222);

    final colorScheme = Theme.of(context).colorScheme;

    // Whole page scrolls (like other screens). No nested box-only scroll.
    final mainContent = SingleChildScrollView(
      primary: false,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 20,
        isCompact ? 12 : 20,
        isCompact ? 12 : 20,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        UiGradients.brand.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    child: Text(
                      'Point of Sale',
                      style: TextStyle(
                        fontSize: isCompact ? 28 : 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Process sales transactions quickly and efficiently.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              if (_isCashier && activeSession != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'CASH IN HAND',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            _money(
                              _calculateSessionBreakdown(
                                    activeSession,
                                  )['expected'] ??
                                  activeSession.openingCash,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Avoid Flexible/Expanded inside scroll view (causes blank layout).
          // Build product + cart as normal children; page scrolls as a whole.
          Builder(
            builder: (context) {
              final productPanel = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: toolbarBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: toolbarBorderColor),
                    ),
                    child: isCompact
                        ? Column(
                            children: [
                              SizedBox(
                                height: toolbarControlHeight,
                                child: TextField(
                                  controller: _productSearchController,
                                  focusNode: _posProductSearchFocusNode,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: _handleBarcodeOrSearchScan,
                                  decoration: InputDecoration(
                                    hintText: 'Search products or scan',
                                    prefixIcon: const Icon(Icons.search),
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF2F2B48)
                                        : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: controlBorderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: controlBorderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: controlBorderColor,
                                        width: 1.4,
                                      ),
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: toolbarControlHeight,
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF2E9C64,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFBFE6CF),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.qr_code_scanner,
                                          size: 16,
                                        ),
                                        label: const Text('Scanner'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: toolbarControlHeight,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final service =
                                              await _showPosServicePickerDialog();
                                          if (service == null) return;
                                          final serviceCartId =
                                              'SV:${service.id}';
                                          setState(() {
                                            _cart[serviceCartId] =
                                                (_cart[serviceCartId] ?? 0) + 1;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.brandIndigo,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              UiRadius.md,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Add Service'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: toolbarControlHeight,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2F2B48)
                                      : Colors.white,
                                  border: Border.all(color: controlBorderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _posCategoryFilter,
                                    isExpanded: true,
                                    items: posCategories
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _posCategoryFilter = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: toolbarControlHeight,
                                  child: TextField(
                                    controller: _productSearchController,
                                    focusNode: _posProductSearchFocusNode,
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: _handleBarcodeOrSearchScan,
                                    decoration: InputDecoration(
                                      hintText: 'Search products or scan',
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF2F2B48)
                                          : Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: controlBorderColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: controlBorderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: controlBorderColor,
                                          width: 1.4,
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: toolbarControlHeight,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _posProductSearchFocusNode.requestFocus();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Barcode Scanner Ready - Scan product barcode or press Enter'),
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E9C64),
                                    side: const BorderSide(
                                      color: Color(0xFFBFE6CF),
                                    ),
                                    minimumSize: const Size(
                                      0,
                                      toolbarControlHeight,
                                    ),
                                    maximumSize: const Size(
                                      double.infinity,
                                      toolbarControlHeight,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.qr_code_scanner,
                                    size: 16,
                                  ),
                                  label: const Text('Scanner Active'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                height: toolbarControlHeight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2F2B48)
                                      : Colors.white,
                                  border: Border.all(color: controlBorderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _posCategoryFilter,
                                    items: posCategories
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _posCategoryFilter = v);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: toolbarControlHeight,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final service =
                                        await _showPosServicePickerDialog();
                                    if (service == null) return;
                                    final serviceCartId = 'SV:${service.id}';
                                    setState(() {
                                      _cart[serviceCartId] =
                                          (_cart[serviceCartId] ?? 0) + 1;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandIndigo,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: Size(0, toolbarControlHeight),
                                    maximumSize: Size(
                                      double.infinity,
                                      toolbarControlHeight,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        UiRadius.md,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Add Service'),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final int crossAxisCount;
                      final double childAspectRatio;

                      if (availableWidth < 320) {
                        crossAxisCount = 1;
                        childAspectRatio = 1.4;
                      } else if (availableWidth < 520) {
                        crossAxisCount = 2;
                        childAspectRatio = 0.72;
                      } else if (availableWidth < 800) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.74;
                      } else {
                        crossAxisCount = 4;
                        childAspectRatio = 0.75;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final p = filteredProducts[index];
                          final key = p.name.trim().toLowerCase();
                          final locStocksList = stockBreakdown[key] ?? [];
                          final locStocksSummary = locStocksList.join(' | ');
                          final locStocksTooltip = locStocksList.join('\n');

                          final matches = _scopedProducts
                              .where(
                                (sp) =>
                                    sp.name.trim().toLowerCase() ==
                                    p.name.trim().toLowerCase(),
                              )
                              .toList();

                          final activeMatches = matches
                              .where((m) => m.stock > 0)
                              .toList();
                          final displayMatches = activeMatches.isNotEmpty
                              ? activeMatches
                              : matches;

                          final displayPriceText = displayMatches
                              .map((m) => _money(m.price))
                              .join(' / ');
                          final displaySkus = displayMatches
                              .map(
                                (m) =>
                                    m.barcode.trim().isNotEmpty ? m.barcode : m.id,
                              )
                              .join(', ');
                          final displayStock = displayMatches.fold<double>(
                            0,
                            (sum, m) => sum + m.stock,
                          );
                          final isOutOfStock = displayStock <= 0;

                          Widget cardContent = GlassContainer(
                            padding: const EdgeInsets.all(10),
                            borderRadius: UiRadius.md,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final matchedWithImg = displayMatches.firstWhere(
                                          (m) =>
                                              m.imageUrl != null &&
                                              m.imageUrl!.trim().isNotEmpty &&
                                              File(m.imageUrl!).existsSync(),
                                          orElse: () => p,
                                        );
                                        final imgPath = (p.imageUrl != null &&
                                                p.imageUrl!.trim().isNotEmpty &&
                                                File(p.imageUrl!).existsSync())
                                            ? p.imageUrl
                                            : (matchedWithImg.imageUrl != null &&
                                                    matchedWithImg.imageUrl!.trim().isNotEmpty &&
                                                    File(matchedWithImg.imageUrl!).existsSync())
                                                ? matchedWithImg.imageUrl
                                                : null;

                                        if (imgPath != null) {
                                          return Container(
                                            height: 100,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                UiRadius.sm,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(
                                                    alpha: 0.08,
                                                  ),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(
                                                UiRadius.sm,
                                              ),
                                              child: Image.file(
                                                File(imgPath),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  decoration: BoxDecoration(
                                                    gradient: UiGradients.brand,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 28),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        p.name.isNotEmpty
                                                            ? p.name[0].toUpperCase()
                                                            : 'P',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return Container(
                                          height: 90,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: UiGradients.brand,
                                            borderRadius: BorderRadius.circular(
                                              UiRadius.sm,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF6366F1,
                                                ).withValues(alpha: 0.15),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 26),
                                              const SizedBox(height: 4),
                                              Text(
                                                p.name.isNotEmpty
                                                    ? p.name[0].toUpperCase()
                                                    : 'P',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      displayMatches.length > 1
                                          ? 'Variants: $displaySkus'
                                          : 'SKU: $displaySkus',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                    if (isAllLocations &&
                                        locStocksSummary.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        locStocksSummary,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withValues(
                                            alpha: 0.55,
                                          ),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayPriceText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppTheme.brandIndigo,
                                          fontWeight: FontWeight.w700,
                                          fontSize: displayMatches.length > 1
                                              ? 11.5
                                              : 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Tooltip(
                                      message: isAllLocations
                                          ? locStocksTooltip
                                          : 'Stock at current branch',
                                      child: StatusChip(
                                        label: p.allowLooseSales
                                            ? _formatDualStock(
                                                displayStock,
                                                p.measureUnit,
                                                p.secondaryUnit,
                                                p.unitConversionRatio,
                                              )
                                            : 'Stock: ${displayStock.toStringAsFixed(displayStock.truncateToDouble() == displayStock ? 0 : 2)}',
                                        color: isOutOfStock
                                            ? AppTheme.brandRose
                                            : AppTheme.brandEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );

                          if (isAllLocations && locStocksTooltip.isNotEmpty) {
                            cardContent = Tooltip(
                              message: locStocksTooltip,
                              child: cardContent,
                            );
                          }

                      return InkWell(
                        onTap: () {
                          if (isAllLocations) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select a specific branch from the top dropdown to start selling.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          final matches = _scopedProducts
                              .where(
                                (sp) =>
                                    sp.name.trim().toLowerCase() ==
                                    p.name.trim().toLowerCase(),
                              )
                              .toList();

                          if (matches.length > 1) {
                            _showProductSkuSelectionDialog(matches);
                          } else {
                            final target = matches.isNotEmpty
                                ? matches.first
                                : p;
                            if (target.stock <= 0) return;
                            if (target.allowLooseSales) {
                              _showDualUnitSelectionDialog(target);
                            } else {
                              _addToCartWithImeiSelection(target);
                            }
                          }
                        },
                        child: cardContent,
                      );
                    },
                  );
                },
              ),
            ],
              );

              final cartPanel = GlassContainer(
                borderRadius: UiRadius.lg,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _editingSaleId != null
                                ? 'Editing Bill: $_editingSaleId'
                                : 'Shopping Cart (${cartItems.length})',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _editingSaleId != null
                                  ? const Color(0xFFE35D5D)
                                  : null,
                            ),
                          ),
                        ),
                        if (_editingSaleId != null)
                          IconButton(
                            tooltip: 'Cancel Edit',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Color(0xFFE35D5D),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _editingSaleId = null;
                                _cart.clear();
                                _posLineDiscounts.clear();
                                _posLinePrices.clear();
                                _resetPosDiscountState();
                                _selectedCustomerId = null;
                                _posCustomerSearchController.clear();
                                _posShippingCharges = 0.0;
                                _posShippingController.clear();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invoice editing cancelled.'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    if (isAllLocations) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.amber.shade700.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please select a specific location from the top dropdown to perform sales.',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // ── QUICK ACTIONS TOOLBAR ──
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: cartItems.isEmpty
                                ? null
                                : () async {
                                    await _showCurrentCartBillPreview();
                                  },
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.receipt_long_outlined, size: 15),
                            label: const Text('Preview', style: TextStyle(fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: cartItems.isEmpty
                                ? null
                                : () async {
                                    await _holdCurrentCart();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Bill held successfully'),
                                      ),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.pause_circle_outline, size: 15),
                            label: const Text('Hold', style: TextStyle(fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _heldCarts.isEmpty
                                ? null
                                : () async {
                                    await _resumeHeldCart();
                                  },
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.play_circle_outline, size: 15),
                            label: Text('Resume (${_heldCarts.length})', style: const TextStyle(fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: cartItems.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _removeTemporaryCartProducts(
                                      cartItems.map((line) => line.product.id),
                                    );
                                    _cart.clear();
                                    _posLineDiscounts.clear();
                                    _posLinePrices.clear();
                                    _editingSaleId = null;
                                    _paymentMethodController.text = 'CASH';
                                    _amountPaidController.clear();
                                    _chequeNumberController.clear();
                                    _posInstallmentCount = 3;
                                    _posInstallmentIntervalDays = 30;
                                    _resetPosInstallmentSchedule();
                                    _resetPosDiscountState();
                                    _selectedCustomerId = null;
                                    _posCustomerSearchController.clear();
                                  });
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: BorderSide(
                              color: cartItems.isEmpty
                                  ? (isDark ? Colors.white10 : Colors.black12)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.4),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 15),
                          label: const Text('Clear', style: TextStyle(fontSize: 11.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ── CARD 1: ORDER ITEMS CONTAINER ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2433).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(UiRadius.md),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 15,
                                    color: AppTheme.brandIndigo,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ORDER ITEMS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(UiRadius.pill),
                                ),
                                child: Text(
                                  '${cartItems.length} lines',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.brandIndigo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (cartItems.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A344A) : const Color(0xFFEEF2F6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.remove_shopping_cart_outlined,
                                      size: 24,
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your cart is empty',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap items on the left or scan barcode to add',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: cartItems.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 12,
                                  color: isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (context, index) {
                                  final line = cartItems[index];
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Product initial avatar
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          line.product.name.isNotEmpty
                                              ? line.product.name[0].toUpperCase()
                                              : 'P',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.brandIndigo,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Product details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              line.product.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 1),
                                            Row(
                                              children: [
                                                Text(
                                                  _money(line.unitPriceAfterDiscount),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                                  ),
                                                ),
                                                if (line.discountValue > 0) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _money(line.product.price),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(3),
                                                    ),
                                                    child: Text(
                                                      line.discountType == 'PERCENT'
                                                          ? '-${line.discountValue}%'
                                                          : '-${_money(line.discountValue)}',
                                                      style: const TextStyle(
                                                        color: Color(0xFFEF4444),
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (_enableMobileShopFeatures &&
                                                line.product.imeis != null &&
                                                line.product.imeis!.trim().isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              ...List.generate(line.qty.toInt(), (i) {
                                                final selectedList = _selectedCartImeis[line.product.id] ?? [];
                                                while (selectedList.length <= i) {
                                                  selectedList.add('');
                                                }
                                                final currentVal = selectedList[i];
                                                final allImeis = line.product.imeiList;
                                                final availableForThisIndex = allImeis.where((imei) {
                                                  for (int otherIdx = 0; otherIdx < line.qty; otherIdx++) {
                                                    if (otherIdx != i &&
                                                        otherIdx < selectedList.length &&
                                                        selectedList[otherIdx] == imei) {
                                                      return false;
                                                    }
                                                  }
                                                  return true;
                                                }).toList();

                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 4),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Unit ${i + 1} IMEI: ',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      DropdownButtonHideUnderline(
                                                        child: DropdownButton<String>(
                                                          isDense: true,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.blue,
                                                          ),
                                                          value: currentVal.isEmpty ? null : currentVal,
                                                          hint: const Text('Select IMEI', style: TextStyle(fontSize: 11)),
                                                          items: availableForThisIndex.map((imei) => DropdownMenuItem(
                                                            value: imei,
                                                            child: Text(imei, style: const TextStyle(fontSize: 11)),
                                                          )).toList(),
                                                          onChanged: (newVal) {
                                                            if (newVal != null) {
                                                              setState(() {
                                                                selectedList[i] = newVal;
                                                                _selectedCartImeis[line.product.id] = selectedList;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Discount icon button
                                      IconButton(
                                        onPressed: () => _showLineDiscountDialog(line.product),
                                        icon: const Icon(Icons.local_offer_outlined, size: 15),
                                        color: AppTheme.brandIndigo,
                                        tooltip: 'Discount',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                      ),
                                      // Quantity controls
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF2A344A) : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF3B4863) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => _decrementCartImei(line.product),
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                child: Icon(Icons.remove, size: 13),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _showEditCartQuantityDialog(line),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                child: Text(
                                                  line.qty.toStringAsFixed(
                                                    line.qty.truncateToDouble() == line.qty ? 0 : 2,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11.5,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _addToCartWithImeiSelection(line.product),
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                                child: Icon(Icons.add, size: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Delete button
                                      IconButton(
                                        onPressed: () {
                                          _removeCartImei(line.product);
                                          setState(() {
                                            _posLineDiscounts.remove(line.product.id);
                                          });
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 16),
                                        color: const Color(0xFFEF4444),
                                        tooltip: 'Remove',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                      ),
                                      const SizedBox(width: 2),
                                      // Line Total
                                      SizedBox(
                                        width: 68,
                                        child: Text(
                                          _money(line.totalPrice),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                          ),
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
                    const SizedBox(height: 12),
                    // ── CARD 2: BILL SUMMARY & HERO TOTAL CONTAINER ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2433).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(UiRadius.md),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 15, color: AppTheme.brandIndigo),
                              const SizedBox(width: 6),
                              Text(
                                'BILL SUMMARY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Subtotal row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                _money(rawSubtotal),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Discount row with inline Add/Edit
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Discount',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  if (_posInvoiceDiscountValue > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _posInvoiceDiscountType == 'PERCENT'
                                            ? '${_posInvoiceDiscountValue}%'
                                            : _money(_posInvoiceDiscountValue),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Material(
                                    color: _posInvoiceDiscountValue > 0
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                        : AppTheme.brandIndigo.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    child: InkWell(
                                      onTap: _showInvoiceDiscountDialog,
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _posInvoiceDiscountValue > 0
                                                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                                : AppTheme.brandIndigo.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _posInvoiceDiscountValue > 0
                                                  ? Icons.edit_rounded
                                                  : Icons.add_rounded,
                                              size: 13,
                                              color: _posInvoiceDiscountValue > 0
                                                  ? const Color(0xFFEF4444)
                                                  : AppTheme.brandIndigo,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              _posInvoiceDiscountValue > 0 ? 'Edit' : 'Add',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: _posInvoiceDiscountValue > 0
                                                    ? const Color(0xFFEF4444)
                                                    : AppTheme.brandIndigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                invoiceDiscountAmount > 0 ? '-${_money(invoiceDiscountAmount)}' : _money(0),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: invoiceDiscountAmount > 0 ? const Color(0xFFEF4444) : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Tax row with inline checkbox
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Tax (${taxRate.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: Checkbox(
                                      value: _posApplyTax,
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) {
                                        if (val != null) setState(() => _posApplyTax = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _money(taxAmount),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          // Shipping Charges
                          if (shippingCharges > 0 || (paymentMethod == 'COD' && _posShippingCharges > 0)) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  paymentMethod == 'COD' ? _t('Delivery Fee:') : 'Shipping:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  _money(shippingCharges),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                    // Agent commission inputs (only when enabled in Settings)
                    if (_enableAgentCommission) ...[
                      const SizedBox(height: 4),
                      const Divider(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Agent Commission',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // ── Agent name: locked mode vs selectable mode ──
                      if (_agentCommissionLockToLogin) ...[
                        // LOCKED: show the logged-in user as a read-only chip
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_person_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentUserName.isEmpty
                                      ? 'Agent: (not set)'
                                      : _currentUserName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'LOCKED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // SELECTABLE: searchable autocomplete dropdown
                        Builder(
                          builder: (context) {
                            // Build combined agent list: employees + users from dashboard state
                            final agentOptions = <Map<String, String>>[];
                            final seen = <String>{};
                            for (final emp in _employees) {
                              if (!seen.contains(emp.id)) {
                                seen.add(emp.id);
                                agentOptions.add({
                                  'id': emp.id,
                                  'name': emp.name,
                                  'role': emp.role,
                                  'commissionType': 'PERCENT',
                                  'commissionValue': '0',
                                });
                              }
                            }
                            // Also add app users not already in the list
                            for (final u in _users) {
                              if (!seen.contains(u.id) &&
                                  !agentOptions.any(
                                    (e) =>
                                        e['name']?.toLowerCase() ==
                                        u.name.toLowerCase(),
                                  )) {
                                seen.add(u.id);
                                agentOptions.add({
                                  'id': u.id,
                                  'name': u.name,
                                  'role': u.role,
                                  'commissionType': 'PERCENT',
                                  'commissionValue': '0',
                                });
                              }
                            }

                            return Autocomplete<Map<String, String>>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                    final q = textEditingValue.text
                                        .trim()
                                        .toLowerCase();
                                    if (q.isEmpty) return agentOptions;
                                    return agentOptions.where(
                                      (opt) =>
                                          (opt['name'] ?? '')
                                              .toLowerCase()
                                              .contains(q) ||
                                          (opt['role'] ?? '')
                                              .toLowerCase()
                                              .contains(q),
                                    );
                                  },
                              displayStringForOption: (opt) =>
                                  opt['name'] ?? '',
                              initialValue: TextEditingValue(
                                text: _posAgentName,
                              ),
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onSubmitted,
                                  ) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                        labelText: 'Agent Name',
                                        hintText:
                                            'Search or type agent name...',
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          size: 16,
                                        ),
                                        suffixIcon: _posAgentName.isNotEmpty
                                            ? IconButton(
                                                iconSize: 14,
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  controller.clear();
                                                  setState(() {
                                                    _posAgentName = '';
                                                    _posAgentId = '';
                                                    _posAgentCommission = 0.0;
                                                    _posAgentCommissionController
                                                        .clear();
                                                  });
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (v) {
                                        setState(() {
                                          _posAgentName = v.trim();
                                          // Clear the stored ID if the user manually edits
                                          _posAgentId = '';
                                        });
                                      },
                                    );
                                  },
                              optionsViewBuilder: (context, onSelected, options) {
                                final optList = options.toList();
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 6,
                                    borderRadius: BorderRadius.circular(8),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 220,
                                        maxWidth: 320,
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: optList.length,
                                        itemBuilder: (context, index) {
                                          final opt = optList[index];
                                          final name = opt['name'] ?? '';
                                          final role = opt['role'] ?? '';
                                          return InkWell(
                                            onTap: () => onSelected(opt),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.12,
                                                            ),
                                                    child: Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                                .toUpperCase()
                                                          : '?',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          name,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                        if (role.isNotEmpty)
                                                          Text(
                                                            role,
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              onSelected: (Map<String, String> selection) {
                                final name = selection['name'] ?? '';
                                final id = selection['id'] ?? '';
                                setState(() {
                                  _posAgentName = name;
                                  _posAgentId = id;
                                  _posAgentNameController.text = name;
                                });
                                // Try to auto-fill commission rate from employee DB record
                                _appDatabase
                                    ?.getAllEmployees()
                                    .then((emps) {
                                      final emp = emps.firstWhere(
                                        (e) =>
                                            e.id == id ||
                                            e.name.toLowerCase() ==
                                                name.toLowerCase(),
                                        orElse: () =>
                                            throw StateError('not found'),
                                      );
                                      final commType =
                                          emp.commissionType.toUpperCase() ==
                                              'FIXED'
                                          ? 'FIXED'
                                          : 'PERCENT';
                                      final commValue = emp.commissionValue;
                                      if (commValue > 0 && mounted) {
                                        setState(() {
                                          _posAgentCommissionType = commType;
                                          _posAgentCommission = commValue;
                                          _posAgentCommissionController.text =
                                              commValue.toStringAsFixed(
                                                commType == 'FIXED' ? 2 : 1,
                                              );
                                        });
                                      }
                                    })
                                    .catchError((_) {
                                      // Agent is a system user without an employee record —
                                      // commission type/value fields stay at their current values.
                                    });
                              },
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Commission Type toggle + amount input
                      Row(
                        children: [
                          // Type selector (PERCENT / FIXED)
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _posAgentCommissionType,
                              isDense: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                labelText: 'Type',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'PERCENT',
                                  child: Text('% Percent'),
                                ),
                                DropdownMenuItem(
                                  value: 'FIXED',
                                  child: Text('Fixed'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _posAgentCommissionType = v;
                                    _posAgentCommission = 0.0;
                                    _posAgentCommissionController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Commission amount / percent input
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _posAgentCommissionController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: const OutlineInputBorder(),
                                labelText: _posAgentCommissionType == 'PERCENT'
                                    ? 'Commission (%)'
                                    : 'Fixed Amount',
                                hintText: '0',
                                suffixText: _posAgentCommissionType == 'PERCENT'
                                    ? '%'
                                    : _currency,
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _posAgentCommission =
                                      double.tryParse(v) ?? 0.0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Pay Now / Pay Later
                      DropdownButtonFormField<bool>(
                        value: _posAgentCommissionPaid,
                        isDense: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          labelText: 'Commission Payment',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: false,
                            child: Text('Pay Later (Record as Unpaid)'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Pay Now (Mark as Paid)'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _posAgentCommissionPaid = v);
                          }
                        },
                      ),
                      // Commission preview row
                      if (_posAgentName.isNotEmpty && _posAgentCommission > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _overviewRow(
                            _posAgentCommissionType == 'PERCENT'
                                ? 'Commission (${_posAgentCommission.toStringAsFixed(1)}%):'
                                : 'Commission (Fixed):',
                            _money(
                              _posAgentCommissionType == 'PERCENT'
                                  ? grandTotal * (_posAgentCommission / 100)
                                  : _posAgentCommission,
                            ),
                          ),
                        ),
                    ],
                          // ── HERO GRAND TOTAL & STATUS BANNER ──
                          Container(
                            margin: const EdgeInsets.only(top: 14),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF1E1B4B),
                                        const Color(0xFF2E2466),
                                      ]
                                    : [
                                        const Color(0xFFEEF2FF),
                                        const Color(0xFFE0E7FF),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(UiRadius.md),
                              border: Border.all(
                                color: AppTheme.brandIndigo.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.brandIndigo.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'GRAND TOTAL',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                            color: AppTheme.brandIndigo,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _money(grandTotal),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E1B4B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Dynamic status badge
                                    if (changeAmount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(UiRadius.pill),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.currency_exchange_rounded,
                                              size: 16,
                                              color: Color(0xFF059669),
                                            ),
                                            const SizedBox(width: 6),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'CHANGE',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                                Text(
                                                  _money(changeAmount),
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (balanceAmount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(UiRadius.pill),
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.schedule_rounded,
                                              size: 16,
                                              color: Color(0xFFD97706),
                                            ),
                                            const SizedBox(width: 6),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'BALANCE DUE',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                    color: Color(0xFFD97706),
                                                  ),
                                                ),
                                                Text(
                                                  _money(balanceAmount),
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFFD97706),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(UiRadius.pill),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 15,
                                              color: Color(0xFF059669),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'PAID IN FULL',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (effectivePaidAmount > 0) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Paid Amount:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                          ),
                                        ),
                                        Text(
                                          _money(effectivePaidAmount),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Collapsible / Compact Coupon & Gift Card Section
                          if (_coupons.any((c) => c.active)) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _posCouponController,
                                      style: const TextStyle(fontSize: 12.5),
                                      decoration: InputDecoration(
                                        hintText: 'Enter coupon code',
                                        prefixIcon: const Icon(
                                          Icons.confirmation_number_outlined,
                                          size: 16,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final code = _posCouponController.text.trim().toLowerCase();
                                      if (code.isEmpty) return;
                                      final match = _coupons.firstWhere(
                                        (c) => c.active && c.code.trim().toLowerCase() == code,
                                        orElse: () => _CouponItem(
                                          code: '',
                                          description: '',
                                          discountPercent: 0,
                                          active: false,
                                        ),
                                      );
                                      if (match.code.isNotEmpty && match.discountPercent > 0) {
                                        setState(() {
                                          _posInvoiceDiscountType = 'PERCENT';
                                          _posInvoiceDiscountValue = match.discountPercent;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Coupon applied: ${match.discountPercent}% discount (${match.code})',
                                            ),
                                            backgroundColor: AppTheme.brandEmerald,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Invalid or inactive coupon code'),
                                            backgroundColor: AppTheme.brandRose,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                    ),
                                    child: const Text('Apply'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: TextField(
                                    controller: _posGiftCardController,
                                    style: const TextStyle(fontSize: 12.5),
                                    decoration: InputDecoration(
                                      hintText: 'Enter gift card code',
                                      prefixIcon: const Icon(
                                        Icons.card_giftcard_outlined,
                                        size: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 38,
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── CARD 3: PAYMENT METHOD & CUSTOMER ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131D2E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E2D45)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payment_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PAYMENT METHOD',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : const Color(0xFF475569),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandIndigo.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  paymentMethod,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.brandIndigo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _posPaymentCompactButton(
                          'CASH',
                          'Cash',
                          paymentMethod,
                          grandTotal,
                        ),
                        _posPaymentCompactButton(
                          'CARD',
                          'Card',
                          paymentMethod,
                          grandTotal,
                        ),
                        _posPaymentCompactButton(
                          'CHEQUE',
                          'Cheque',
                          paymentMethod,
                          grandTotal,
                        ),
                        _posPaymentCompactButton(
                          'CREDIT',
                          'Credit',
                          paymentMethod,
                          grandTotal,
                        ),
                        _posPaymentCompactButton(
                          'INSTALLMENT',
                          'Installment',
                          paymentMethod,
                          grandTotal,
                        ),
                        if (_enableCod)
                          _posPaymentCompactButton(
                            'COD',
                            'COD',
                            paymentMethod,
                            grandTotal,
                          ),
                      ],
                    ),
                    if (paymentMethod == 'COD') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _t('Delivery Fee (COD):'),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                  const Text(
                                    'Added to customer cash to collect',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: TextField(
                                controller: _posShippingController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                  hintText: '0.00',
                                  prefixText: '${_currency == 'USD' ? '\$' : (_currency == 'LKR' ? 'Rs.' : _currency)} ',
                                  prefixStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    _posShippingCharges =
                                        double.tryParse(v) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (paymentMethod != 'CASH' && paymentMethod != 'CARD') ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Customer',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              _posCustomerSearchController.clear();
                              final customer = await _showCustomerDialog();
                              if (customer == null) return;
                              customer.locationId = _activeLocationForWrites;

                              try {
                                setState(() {
                                  _customers.removeWhere(
                                    (item) => item.id == customer.id,
                                  );
                                  _customers.add(customer);
                                  _selectedCustomerId = customer.id;
                                  _posCustomerSearchController.text =
                                      '${customer.name} (${customer.phone.isEmpty ? 'N/A' : customer.phone})';
                                  if (customer.discountPercent > 0) {
                                    _posInvoiceDiscountType = 'PERCENT';
                                    _posInvoiceDiscountValue =
                                        customer.discountPercent;
                                  }
                                });
                                await _persistWorkspaceData();

                                if (_customerRepository != null) {
                                  try {
                                    await _customerRepository!.insertCustomer(
                                      _toDomainCustomer(customer),
                                    );
                                  } catch (_) {
                                    // Fall back to update for ID collisions from legacy short IDs.
                                    await _customerRepository!.updateCustomer(
                                      _toDomainCustomer(customer),
                                    );
                                  }
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
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Unable to add customer: $e'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Add Customer'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RawAutocomplete<_CustomerItem>(
                        textEditingController: _posCustomerSearchController,
                        focusNode: _posCustomerSearchFocusNode,
                        displayStringForOption: (customer) =>
                            '${customer.name} (${customer.phone.isEmpty ? 'N/A' : customer.phone})',
                        optionsBuilder: (textEditingValue) {
                          final query = textEditingValue.text
                              .trim()
                              .toLowerCase();
                          return _scopedCustomers.where((customer) {
                            if (query.isEmpty) return true;
                            return customer.name.toLowerCase().contains(query) ||
                                customer.phone.toLowerCase().contains(query) ||
                                customer.id.toLowerCase().contains(query);
                          });
                        },
                        onSelected: (customer) {
                          setState(() {
                            _selectedCustomerId = customer.id;
                            _posCustomerSearchController.text =
                                '${customer.name} (${customer.phone.isEmpty ? 'N/A' : customer.phone})';
                            if (customer.discountPercent > 0) {
                              _posInvoiceDiscountType = 'PERCENT';
                              _posInvoiceDiscountValue = customer.discountPercent;
                            } else {
                              _posInvoiceDiscountType = 'FIXED';
                              _posInvoiceDiscountValue = 0.0;
                            }
                          });
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search customer by name, phone, or ID',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  if (val.trim().isEmpty) {
                                    setState(() {
                                      _selectedCustomerId = null;
                                    });
                                  }
                                },
                                onSubmitted: (_) => onFieldSubmitted(),
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          final optionList = options.toList();
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                  maxHeight: 220,
                                ),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: optionList.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final customer = optionList[index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(customer.name),
                                      subtitle: Text(
                                        '${customer.id} • ${customer.phone.isEmpty ? 'N/A' : customer.phone}',
                                      ),
                                      onTap: () => onSelected(customer),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_selectedCustomerId != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 14, color: AppTheme.brandIndigo),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      selectedCustomer.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedCustomerId = null;
                                        _posCustomerSearchController.clear();
                                        _posInvoiceDiscountType = 'FIXED';
                                        _posInvoiceDiscountValue = 0.0;
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Address: ${selectedCustomer.address.isEmpty ? 'N/A' : selectedCustomer.address}',
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Credit: ',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  Text(
                                    _money(selectedCustomerOutstanding),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selectedCustomerOutstanding > 0 ? const Color(0xFFE11D48) : null,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  Text(
                                    ' / Limit: ${selectedCustomer.creditLimit <= 0 ? 'No limit' : _money(selectedCustomer.creditLimit)}',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasOverdueCredit) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEFEF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFF2B6B6)),
                                  ),
                                  child: Text(
                                    oldestOverdueDate == null
                                        ? 'Overdue credit detected. Clear overdue balance before creating new credit sale.'
                                        : 'Overdue credit since ${_formatDate(oldestOverdueDate)}. Clear overdue balance before creating new credit sale.',
                                    style: const TextStyle(
                                      color: Color(0xFFB43E3E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── CARD 4: TENDER & PAYMENT ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131D2E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E2D45)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.point_of_sale_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'TENDER & PAYMENT',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Amount Paid',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountPaidController,
                            readOnly: !allowsManualPaidAmount,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: allowsManualPaidAmount
                                ? () {
                                    setState(() {
                                      _amountPaidController.text = grandTotal
                                          .toStringAsFixed(2);
                                    });
                                  }
                                : null,
                            child: const Text('Exact'),
                          ),
                        ),
                      ],
                    ),
                    if (allowsManualPaidAmount) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...[100, 500, 1000, 5000].map((amt) {
                            final label = _currency == 'LKR' ? 'Rs. $amt' : '$amt';
                            return ActionChip(
                              label: Text(label),
                              labelStyle: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onPressed: () {
                                setState(() {
                                  _amountPaidController.text =
                                      amt.toDouble().toStringAsFixed(2);
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ],
                    if (isChequePayment) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Cheque Number',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _chequeNumberController,
                        decoration: const InputDecoration(
                          hintText: 'Enter cheque number',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                    if (isInstallmentPayment) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F2FB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE6D9F3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Installment Plan',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7A1EA4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE6D9F3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remaining Balance: ${_money(balanceAmount)}',
                                  ),
                                  Text(
                                    'Planned Installments: ${_money(installmentPlannedTotal)}',
                                  ),
                                  Text(
                                    'Difference: ${_money(installmentDifference)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: installmentDifference.abs() <= 0.01
                                          ? const Color(0xFF2E9C64)
                                          : const Color(0xFFB42318),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey(
                                      'pos-installment-count-$installmentCount',
                                    ),
                                    initialValue: installmentCount.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Number of Installments',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      final parsed = int.tryParse(value.trim());
                                      if (parsed == null) {
                                        return;
                                      }
                                      final safe = parsed.clamp(1, 60);
                                      if (_posInstallmentCount == safe) {
                                        return;
                                      }
                                      setState(() {
                                        _posInstallmentCount = safe.toInt();
                                        _resetPosInstallmentSchedule();
                                        _syncPosInstallmentAmounts(
                                          balanceAmount,
                                        );
                                      });
                                    },
                                    onFieldSubmitted: (value) {
                                      final parsed =
                                          int.tryParse(value.trim()) ??
                                          installmentCount;
                                      final safe = parsed.clamp(1, 60);
                                      setState(() {
                                        _posInstallmentCount = safe.toInt();
                                        _resetPosInstallmentSchedule();
                                        _syncPosInstallmentAmounts(
                                          balanceAmount,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey(
                                      'pos-installment-interval-$installmentIntervalDays',
                                    ),
                                    initialValue: installmentIntervalDays
                                        .toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Payable Every (Days)',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      final parsed = int.tryParse(value.trim());
                                      if (parsed == null) {
                                        return;
                                      }
                                      final safe = parsed.clamp(1, 365);
                                      if (_posInstallmentIntervalDays == safe) {
                                        return;
                                      }
                                      setState(() {
                                        _posInstallmentIntervalDays = safe
                                            .toInt();
                                        _resetPosInstallmentSchedule();
                                        _syncPosInstallmentAmounts(
                                          balanceAmount,
                                        );
                                      });
                                    },
                                    onFieldSubmitted: (value) {
                                      final parsed =
                                          int.tryParse(value.trim()) ??
                                          installmentIntervalDays;
                                      final safe = parsed.clamp(1, 365);
                                      setState(() {
                                        _posInstallmentIntervalDays = safe
                                            .toInt();
                                        _resetPosInstallmentSchedule();
                                        _syncPosInstallmentAmounts(
                                          balanceAmount,
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(installmentCount, (index) {
                              final dueDate = installmentDueDates[index];
                              final amount = installmentAmounts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            '#${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              key: ValueKey(
                                                'pos-installment-amount-$index-${amount.toStringAsFixed(2)}',
                                              ),
                                              initialValue: amount
                                                  .toStringAsFixed(2),
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              decoration: const InputDecoration(
                                                labelText: 'Amount',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                              onChanged: (value) {
                                                final parsed = double.tryParse(
                                                  value.trim(),
                                                );
                                                if (parsed == null) {
                                                  return;
                                                }
                                                setState(() {
                                                  _updatePosInstallmentAmount(
                                                    installmentIndex: index,
                                                    newAmount: parsed,
                                                    totalAmount: balanceAmount,
                                                  );
                                                });
                                              },
                                              onFieldSubmitted: (value) {
                                                final parsed = double.tryParse(
                                                  value.trim(),
                                                );
                                                if (parsed == null) {
                                                  return;
                                                }
                                                setState(() {
                                                  _updatePosInstallmentAmount(
                                                    installmentIndex: index,
                                                    newAmount: parsed,
                                                    totalAmount: balanceAmount,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: dueDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked == null) return;
                                        setState(() {
                                          if (_posInstallmentDueDates.length !=
                                              installmentCount) {
                                            _resetPosInstallmentSchedule(
                                              startFrom: DateTime.now(),
                                            );
                                          }
                                          _posInstallmentDueDates[index] =
                                              DateTime(
                                                picked.year,
                                                picked.month,
                                                picked.day,
                                              );
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.edit_calendar_rounded,
                                        size: 16,
                                      ),
                                      label: Text(_formatDate(dueDate)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    if (paymentMethod == 'COD') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _posCodPaymentCollectedUpfront
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _posCodPaymentCollectedUpfront
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _posCodPaymentCollectedUpfront
                                      ? Icons.check_circle_outline
                                      : Icons.local_shipping_outlined,
                                  color: _posCodPaymentCollectedUpfront
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'COD Payment Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _posCodPaymentCollectedUpfront
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text(
                                'Payment already received (Prepaid COD)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _posCodPaymentCollectedUpfront
                                    ? 'Money is collected now. Added to cash drawer & recognized revenue immediately.'
                                    : 'Payment will be collected upon delivery. Excluded from drawer/revenue until delivery collection.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              value: _posCodPaymentCollectedUpfront,
                              onChanged: (val) {
                                setState(() {
                                  _posCodPaymentCollectedUpfront = val ?? false;
                                });
                              },
                            ),
                            () {
                              final availableDrivers = _scopedUsers
                                  .where((u) => u.role.toUpperCase() == 'DELIVERY' && u.active)
                                  .toList();
                              if (availableDrivers.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: DropdownButtonFormField<String?>(
                                  value: _posSelectedDeliveryDriverId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Assign Delivery Driver (Optional)',
                                    prefixIcon: const Icon(Icons.delivery_dining_rounded, color: Colors.blue),
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Unassigned (Assign Later in Sales)'),
                                    ),
                                    ...availableDrivers.map(
                                      (d) => DropdownMenuItem<String?>(
                                        value: d.id,
                                        child: Text('${d.name} (${d.email.isNotEmpty ? d.email : d.role.toUpperCase()})'),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _posSelectedDeliveryDriverId = val;
                                    });
                                  },
                                ),
                              );
                            }(),
                          ],
                        ),
                      ),
                    ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── CHECKOUT ACTION BUTTON ──
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: (cartItems.isEmpty || isAllLocations)
                            ? null
                            : UiGradients.brand,
                        color: (cartItems.isEmpty || isAllLocations)
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05))
                            : null,
                        borderRadius: BorderRadius.circular(UiRadius.md),
                        boxShadow: (cartItems.isEmpty || isAllLocations)
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: (cartItems.isEmpty || isAllLocations)
                            ? null
                            : () async {
                                // Enforce an active cashier session exists only for Cashiers
                                if (_isCashier) {
                                  final activeSession = _activeSessionFor(
                                    _currentUserId,
                                  );
                                  if (activeSession == null) {
                                    await _triggerOpenRegisterDialog();
                                    if (_activeSessionFor(_currentUserId) ==
                                        null) {
                                      return;
                                    }
                                  }
                                }

                                final linkedReturnIds = <String>{
                                  for (final line in cartItems)
                                    if (_isReturnStoreCreditCartItemId(
                                      line.product.id,
                                    ))
                                      _returnIdFromStoreCreditCartItemId(
                                            line.product.id,
                                          ) ??
                                          '',
                                }..remove('');
                                final hasReturnStoreCredit =
                                    linkedReturnIds.isNotEmpty;
                                final replacementItemsTotal = cartItems
                                    .where(
                                      (line) => !_isReturnStoreCreditCartItemId(
                                        line.product.id,
                                      ),
                                    )
                                    .fold<double>(
                                      0,
                                      (sum, line) =>
                                          sum + (line.product.price * line.qty),
                                    );
                                final isCreditSale = _isCreditPaymentMethod(
                                  paymentMethod,
                                );
                                final chequeNumber = _chequeNumberController
                                    .text
                                    .trim();
                                final paidAmount =
                                    double.tryParse(
                                      _amountPaidController.text.trim(),
                                    ) ??
                                    0;
                                final sanitizedPaidAmount =
                                    paymentMethod == 'COD'
                                        ? (_posCodPaymentCollectedUpfront
                                              ? grandTotal
                                              : 0.0)
                                        : (_allowsManualPaidAmount(paymentMethod)
                                                  ? paidAmount
                                                  : grandTotal)
                                              .clamp(0, double.infinity)
                                              .toDouble();
                                final outstandingAmount =
                                    paymentMethod == 'COD'
                                        ? (_posCodPaymentCollectedUpfront
                                              ? 0.0
                                              : grandTotal)
                                        : (grandTotal - sanitizedPaidAmount)
                                              .clamp(0, double.infinity)
                                              .toDouble();
                                final balanceAmount =
                                    (grandTotal - sanitizedPaidAmount)
                                        .clamp(0, double.infinity)
                                        .toDouble();

                                if (hasReturnStoreCredit &&
                                    replacementItemsTotal <= 0) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Store-credit returns need at least one replacement item before checkout.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (hasReturnStoreCredit && grandTotal < 0) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Replacement sale total cannot be below zero after store credit is applied.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                for (final line in cartItems) {
                                  if (!line.product.id.startsWith('SV:')) {
                                    final bool isLoose = line.product.id
                                        .startsWith('LOOSE:');
                                    final String baseProductId = isLoose
                                        ? line.product.id.substring(6)
                                        : line.product.id;

                                    _ProductItem? baseProduct;
                                    for (final p in _products) {
                                      if (p.id == baseProductId) {
                                        baseProduct = p;
                                        break;
                                      }
                                    }
                                    final targetProduct =
                                        baseProduct ?? line.product;
                                    final ratio = isLoose &&
                                            targetProduct
                                                    .unitConversionRatio >
                                                0
                                        ? targetProduct.unitConversionRatio
                                        : 1.0;
                                    final deductQtyInBaseUnit = isLoose
                                        ? (line.qty / ratio)
                                        : line.qty;

                                    if (deductQtyInBaseUnit >
                                        targetProduct.stock) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Cannot complete sale: Insufficient stock for ${line.product.name}. Requested ${_formatQty(line.qty)} ${line.product.measureUnit}, available ${_formatQty(targetProduct.stock)} ${targetProduct.measureUnit}.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                }

                                if (paymentMethod == 'CASH' &&
                                    sanitizedPaidAmount + 0.0001 < grandTotal) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cash sale cannot be completed with partial payment. Use Exact or enter full amount.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (paymentMethod == 'CREDIT' &&
                                    outstandingAmount <= 0) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Credit sale must have an outstanding balance. Reduce Amount Paid.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (paymentMethod == 'INSTALLMENT' &&
                                    outstandingAmount <= 0) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Installment sale must have an outstanding balance. Reduce Amount Paid.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (_enableMobileShopFeatures) {
                                  for (final line in cartItems) {
                                    if (line.product.imeis != null &&
                                        line.product.imeis!.trim().isNotEmpty) {
                                      final selectedList =
                                          _selectedCartImeis[line.product.id] ??
                                          [];
                                      bool missing = false;
                                      for (int i = 0; i < line.qty; i++) {
                                        if (i >= selectedList.length ||
                                            selectedList[i].trim().isEmpty) {
                                          missing = true;
                                          break;
                                        }
                                      }
                                      if (missing) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please select an IMEI for all units of ${line.product.name}.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }
                                  }
                                }

                                if (isChequePayment && chequeNumber.isEmpty) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Enter cheque number for cheque payment.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (paymentMethod == 'COD') {
                                  final isWalkIn =
                                      selectedCustomer.id == 'C001' ||
                                      selectedCustomer.name.trim().isEmpty ||
                                      selectedCustomer.name
                                              .trim()
                                              .toLowerCase() ==
                                          'walk-in customer';
                                  if (isWalkIn) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Customer name and address/phone are required for Cash on Delivery (COD) orders.',
                                        ),
                                        backgroundColor: Colors.deepOrange,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                if (isCreditSale &&
                                    selectedCustomer.id == 'C001') {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Select a registered customer for credit sales.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (isCreditSale &&
                                    _hasOverdueCreditForCustomer(
                                      selectedCustomer,
                                    )) {
                                  final overdueDate =
                                      _oldestOverdueDateForCustomer(
                                        selectedCustomer,
                                      );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        overdueDate == null
                                            ? 'Customer has overdue credit. New credit sale is blocked.'
                                            : 'Customer has overdue credit since ${_formatDate(overdueDate)}. New credit sale is blocked.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (isCreditSale &&
                                    selectedCustomer.creditLimit > 0) {
                                  final currentOutstanding =
                                      _customerOutstandingBalance(
                                        selectedCustomer.id,
                                        fallback:
                                            selectedCustomer.currentBalance,
                                      );
                                  final nextBalance =
                                      currentOutstanding + outstandingAmount;
                                  if (nextBalance >
                                      selectedCustomer.creditLimit) {
                                    if (!mounted) return;
                                    final proceed =
                                        await _showExtendCreditLimitDialog(
                                          selectedCustomer,
                                          currentOutstanding,
                                          outstandingAmount,
                                        );
                                    if (!proceed) return;
                                  }
                                }

                                final saleCreatedAt = DateTime.now().toUtc();

                                final shouldCreateInstallmentPlan =
                                    paymentMethod == 'INSTALLMENT' &&
                                    outstandingAmount > 0;
                                final planDueDates =
                                    _posInstallmentDueDates.length ==
                                        installmentCount
                                    ? List<DateTime>.from(
                                        _posInstallmentDueDates,
                                      )
                                    : _generateInstallmentDueDates(
                                        installments: installmentCount,
                                        intervalDays: installmentIntervalDays,
                                        startFrom: saleCreatedAt,
                                      );
                                final planInstallmentAmounts =
                                    (paymentMethod == 'INSTALLMENT' &&
                                        _posInstallmentAmounts.length ==
                                            installmentCount)
                                    ? List<double>.from(_posInstallmentAmounts)
                                    : _splitInstallmentAmounts(
                                        outstandingAmount,
                                        installmentCount,
                                      );
                                final planSchedules =
                                    List<_InstallmentScheduleItem>.generate(
                                      installmentCount,
                                      (index) => _InstallmentScheduleItem(
                                        installmentNo: index + 1,
                                        amount: planInstallmentAmounts[index],
                                        dueDate: planDueDates[index],
                                      ),
                                    );

                                final customerName = selectedCustomer.name;
                                final customerOutstandingBefore =
                                    selectedCustomerOutstanding;
                                final customerOutstandingAfter =
                                    (selectedCustomerOutstanding +
                                            outstandingAmount)
                                        .clamp(0, double.infinity)
                                        .toDouble();
                                final selectedAgentId = _posAgentId.trim();
                                final generatedInvoiceNo =
                                    await _buildInvoiceNumber(saleCreatedAt);
                                _UserItem? assignedDriver;
                                if (paymentMethod == 'COD' && _posSelectedDeliveryDriverId != null) {
                                  for (final u in _scopedUsers) {
                                    if (u.id == _posSelectedDeliveryDriverId) {
                                      assignedDriver = u;
                                      break;
                                    }
                                  }
                                }
                                final hasAssignedDriver = assignedDriver != null;
                                final codDeliveryOtp = paymentMethod == 'COD'
                                    ? (1000 + math.Random().nextInt(9000)).toString()
                                    : null;

                                final sale = _SaleRecord(
                                  id: _buildLocalSaleId(saleCreatedAt),
                                  invoiceNumber: generatedInvoiceNo,
                                  locationId: _activeLocationForWrites,
                                  customerName: customerName,
                                  customerId: selectedCustomer.id,
                                  customerPhone: selectedCustomer.phone,
                                  customerAddress: selectedCustomer.address,
                                  shippingAddress: paymentMethod == 'COD'
                                      ? (selectedCustomer.shippingAddress ?? '')
                                      : '',
                                  customerOutstandingBefore:
                                      customerOutstandingBefore,
                                  customerOutstandingAfter:
                                      isCreditSale ||
                                          paymentMethod == 'INSTALLMENT'
                                      ? customerOutstandingAfter
                                      : customerOutstandingBefore,
                                  employeeId: _currentUserId,
                                  cashierName: _currentUserName,
                                  paymentMethod: paymentMethod,
                                  items: cartItems
                                      .map(
                                        (line) => _SaleItemSnapshot(
                                          productId: line.product.id,
                                          productName: line.product.name,
                                          quantity: line.qty,
                                          unitPrice:
                                              line.unitPriceAfterDiscount,
                                          discount: line.discountValue,
                                          discountType: line.discountType,
                                          lineTotal: line.totalPrice,
                                          productType: line.product.productType,
                                        ),
                                      )
                                      .toList(),
                                  subtotal: subtotal,
                                  tax: taxAmount,
                                  discount: invoiceDiscountAmount,
                                  total: grandTotal,
                                  amountPaid: sanitizedPaidAmount,
                                  balance: grandTotal - sanitizedPaidAmount,
                                  chequeNumber: chequeNumber,
                                  shippingCharges: shippingCharges,
                                  agentName: _posAgentName,
                                  agentCommission: _posAgentCommission,
                                  agentCommissionType: _posAgentCommissionType,
                                  agentCommissionPaid: _posAgentCommissionPaid,
                                  deliveryPersonId: hasAssignedDriver ? assignedDriver.id : null,
                                  deliveryPersonName: hasAssignedDriver ? assignedDriver.name : null,
                                  deliveryStatus: hasAssignedDriver
                                      ? 'ASSIGNED'
                                      : (paymentMethod == 'COD' ? 'PENDING' : null),
                                  deliveryOtp: codDeliveryOtp,
                                  status: paymentMethod == 'COD'
                                      ? (_posCodPaymentCollectedUpfront
                                            ? 'COMPLETED'
                                            : (hasAssignedDriver ? 'OUT_FOR_DELIVERY' : 'COD_PENDING'))
                                      : 'COMPLETED',
                                  notes: () {
                                    final customNotes = _posNotesController.text
                                        .trim();
                                    if (!_enableMobileShopFeatures) {
                                      return customNotes;
                                    }
                                    final soldMap = <String, List<String>>{};
                                    for (final line in cartItems) {
                                      if (line.product.imeis != null &&
                                          line.product.imeis!
                                              .trim()
                                              .isNotEmpty) {
                                        final selected =
                                            _selectedCartImeis[line
                                                .product
                                                .id] ??
                                            [];
                                        final soldImeis = selected
                                            .take(line.qty.toInt())
                                            .toList();
                                        if (soldImeis.isNotEmpty) {
                                          soldMap[line.product.id] = soldImeis;
                                        }
                                      }
                                    }
                                    if (soldMap.isEmpty) {
                                      return customNotes;
                                    }
                                    return jsonEncode({
                                      'custom': customNotes,
                                      'imeis': soldMap,
                                    });
                                  }(),
                                  createdAt: saleCreatedAt,
                                  installmentSchedules:
                                      paymentMethod == 'INSTALLMENT'
                                      ? planSchedules
                                      : <_InstallmentScheduleItem>[],
                                );
                                final domainSale = _toDomainSale(
                                  sale,
                                  cartItems,
                                );
                                final installmentPlan =
                                    shouldCreateInstallmentPlan
                                    ? _InstallmentPlan(
                                        id: 'IP${DateTime.now().microsecondsSinceEpoch}',
                                        saleId: sale.id,
                                        invoiceNumber: sale.invoiceNumber ?? '',
                                        customerId: selectedCustomer.id,
                                        locationId: _activeLocationForWrites,
                                        customerName: selectedCustomer.name,
                                        customerPhone: selectedCustomer.phone,
                                        customerAddress:
                                            selectedCustomer.address,
                                        totalAmount: grandTotal,
                                        subtotal: subtotal,
                                        taxAmount: taxAmount,
                                        downPayment: sanitizedPaidAmount,
                                        remainingAmount: outstandingAmount,
                                        paymentMethod: paymentMethod,
                                        chequeNumber: chequeNumber,
                                        numberOfInstallments: installmentCount,
                                        intervalDays: installmentIntervalDays,
                                        createdAt: saleCreatedAt,
                                        items: sale.items,
                                        schedules: planSchedules,
                                      )
                                    : null;
                                final creditSaleSyncId =
                                    isCreditSale && outstandingAmount > 0
                                    ? 'CS${DateTime.now().microsecondsSinceEpoch}'
                                    : null;
                                final stockAuditEntries =
                                    <_StockAdjustmentItem>[];

                                var saleSavedLocally = false;
                                String? syncWarning;

                                Future<void>
                                persistSaleAndQueueSideEffects() async {
                                  if (_editingSaleId != null) {
                                    if (_saleRepository != null) {
                                      await _saleRepository!.updateSale(
                                        domainSale,
                                      );
                                    } else {
                                      await _enqueueSync(
                                        'UPDATE',
                                        'sales',
                                        sale.id,
                                      );
                                    }
                                  } else {
                                    if (_saleRepository != null) {
                                      await _saleRepository!.insertSale(
                                        domainSale,
                                      );
                                    } else {
                                      await _enqueueSync(
                                        'INSERT',
                                        'sales',
                                        sale.id,
                                      );
                                    }
                                  }
                                  saleSavedLocally = true;

                                  setState(() {
                                    final currentOutstanding =
                                        _customerOutstandingBalance(
                                          selectedCustomer.id,
                                          fallback:
                                              selectedCustomer.currentBalance,
                                        );
                                    selectedCustomer.loyaltyPoints +=
                                        _loyaltyPointsForAmount(grandTotal);
                                    if (isCreditSale && outstandingAmount > 0) {
                                      selectedCustomer.currentBalance =
                                          currentOutstanding +
                                          outstandingAmount;
                                    }

                                    if (isCreditSale && outstandingAmount > 0) {
                                      final creditEntry = _CreditSaleEntry(
                                        id: creditSaleSyncId!,
                                        saleId: sale.id,
                                        invoiceNumber: sale.invoiceNumber ?? '',
                                        locationId: _activeLocationForWrites,
                                        customerId: selectedCustomer.id,
                                        customerName: selectedCustomer.name,
                                        customerPhone: selectedCustomer.phone,
                                        customerAddress:
                                            selectedCustomer.address,
                                        customerOutstandingBefore:
                                            currentOutstanding,
                                        customerOutstandingAfter:
                                            currentOutstanding +
                                            outstandingAmount,
                                        subtotal: subtotal,
                                        tax: taxAmount,
                                        total: grandTotal,
                                        amountPaidOnSale: sanitizedPaidAmount,
                                        outstandingAmount: outstandingAmount,
                                        paymentMethod: paymentMethod,
                                        items: cartItems
                                            .map(
                                              (line) =>
                                                  '${line.product.name} x${line.qty} @ ${_money(line.product.price)} = ${_money(line.product.price * line.qty)}',
                                            )
                                            .toList(),
                                        createdAt: sale.createdAt,
                                      );

                                      _customerCreditSales
                                          .putIfAbsent(
                                            selectedCustomer.id,
                                            () => [],
                                          )
                                          .insert(0, creditEntry);
                                    }
                                    if (installmentPlan != null) {
                                      _installmentPlans.insert(
                                        0,
                                        installmentPlan,
                                      );
                                    }

                                    if (_editingSaleId != null) {
                                      final idx = _sales.indexWhere(
                                        (s) => s.id == _editingSaleId,
                                      );
                                      if (idx >= 0) {
                                        _sales[idx] = sale;
                                      } else {
                                        _sales.insert(0, sale);
                                      }
                                    } else {
                                      _sales.insert(0, sale);
                                    }
                                    for (final line in cartItems) {
                                      if (!line.product.id.startsWith('SV:')) {
                                        final bool isLoose = line.product.id
                                            .startsWith('LOOSE:');
                                        final String baseProductId = isLoose
                                            ? line.product.id.substring(6)
                                            : line.product.id;

                                        _ProductItem? baseProduct;
                                        for (final p in _products) {
                                          if (p.id == baseProductId) {
                                            baseProduct = p;
                                            break;
                                          }
                                        }
                                        final targetProduct =
                                            baseProduct ?? line.product;
                                        final ratio = isLoose &&
                                                targetProduct
                                                        .unitConversionRatio >
                                                    0
                                            ? targetProduct.unitConversionRatio
                                            : 1.0;
                                        final deductQtyInBaseUnit = isLoose
                                            ? (line.qty / ratio)
                                            : line.qty;

                                        final beforeStock =
                                            targetProduct.stock;
                                        final afterStock =
                                            (beforeStock - deductQtyInBaseUnit)
                                                .clamp(0.0, 1000000000.0);
                                        targetProduct.stock = afterStock;
                                        if (baseProduct != null &&
                                            line.product != baseProduct) {
                                          line.product.stock = afterStock;
                                        }

                                        if (_enableMobileShopFeatures &&
                                            line.product.imeis != null &&
                                            line.product.imeis!
                                                .trim()
                                                .isNotEmpty) {
                                          final currentImeis =
                                              line.product.imeiList;
                                          final sold =
                                              _selectedCartImeis[line
                                                  .product
                                                  .id] ??
                                              [];
                                          final remaining = currentImeis
                                              .where((x) => !sold.contains(x))
                                              .toList();
                                          line.product.imeis = jsonEncode(
                                            remaining,
                                          );
                                        }

                                        final appliedDelta =
                                            afterStock - beforeStock;
                                        if (appliedDelta != 0) {
                                          final unitCost =
                                              targetProduct.costPrice;
                                          stockAuditEntries.add(
                                            _StockAdjustmentItem(
                                              id: 'SA${DateTime.now().microsecondsSinceEpoch}-${targetProduct.id}',
                                              productId: targetProduct.id,
                                              productName: isLoose
                                                  ? '${targetProduct.name} (${line.qty.toStringAsFixed(line.qty.truncateToDouble() == line.qty ? 0 : 2)} ${targetProduct.secondaryUnit} loose)'
                                                  : targetProduct.name,
                                              delta: appliedDelta,
                                              beforeStock: beforeStock,
                                              afterStock: afterStock,
                                              reason: isLoose
                                                  ? 'Sale ${sale.id} (${line.qty} ${targetProduct.secondaryUnit} sold = ${deductQtyInBaseUnit.toStringAsFixed(3)} ${targetProduct.measureUnit})'
                                                  : 'Sale ${sale.id} completed',
                                              performedBy: _currentUserName,
                                              unitCost: unitCost,
                                              adjustedStockValue:
                                                  unitCost == null
                                                  ? null
                                                  : afterStock * unitCost,
                                              createdAt: DateTime.now(),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    _stockAdjustments.insertAll(
                                      0,
                                      stockAuditEntries,
                                    );
                                    for (final returnId in linkedReturnIds) {
                                      for (final item in _returns) {
                                        if (item.id != returnId) {
                                          continue;
                                        }
                                        item.status = 'Refunded';
                                        item.exchangeSaleId = sale.id;
                                        item.updatedAt = DateTime.now()
                                            .toUtc()
                                            .toIso8601String();
                                        break;
                                      }
                                    }
                                    _removeTemporaryCartProducts(
                                      cartItems.map((line) => line.product.id),
                                    );
                                    _cart.clear();
                                    _selectedCartImeis.clear();
                                    _posLineDiscounts.clear();
                                    _posLinePrices.clear();
                                    _editingSaleId = null;
                                    _paymentMethodController.text = 'CASH';
                                    _amountPaidController.clear();
                                    _chequeNumberController.clear();
                                    _posNotesController.clear();
                                    _posInstallmentCount = 3;
                                    _posInstallmentIntervalDays = 30;
                                    _resetPosInstallmentSchedule();
                                    _resetPosDiscountState();
                                    _selectedCustomerId = null;
                                    _posCustomerSearchController.clear();
                                    // Reset shipping & agent commission for next sale
                                    _posShippingCharges = 0.0;
                                    _posShippingController.clear();
                                    // Re-fill agent name based on mode
                                    if (_agentCommissionLockToLogin ||
                                        _isAgent) {
                                      // Locked mode OR user is an agent role → always use login user
                                      _posAgentName = _currentUserName;
                                      _posAgentId = _currentUserId;
                                      _posAgentNameController.text =
                                          _currentUserName;
                                    } else {
                                      _posAgentName = '';
                                      _posAgentId = '';
                                      _posAgentNameController.clear();
                                    }
                                    _posAgentCommission = 0.0;
                                    _posAgentCommissionController.clear();
                                    _posAgentCommissionType = 'PERCENT';
                                    _posAgentCommissionPaid = false;
                                    _posCodPaymentCollectedUpfront = false;
                                    _posSelectedDeliveryDriverId = null;
                                  });
                                  await _persistWorkspaceData();

                                  if (installmentPlan != null) {
                                    await _enqueueSync(
                                      'INSERT',
                                      'installments',
                                      installmentPlan.id,
                                    );
                                  }
                                  if (creditSaleSyncId != null) {
                                    await _enqueueSync(
                                      'INSERT',
                                      'credit_sales',
                                      creditSaleSyncId,
                                    );
                                  }
                                  if (isCreditSale && outstandingAmount > 0) {
                                    if (_customerRepository != null) {
                                      await _customerRepository!.updateCustomer(
                                        _toDomainCustomer(selectedCustomer),
                                      );
                                    } else {
                                      await _enqueueSync(
                                        'UPDATE',
                                        'customers',
                                        selectedCustomer.id,
                                      );
                                    }
                                  }

                                  final soldProductIds = <String>{
                                    for (final line in cartItems)
                                      if (!line.product.id.startsWith('SV:'))
                                        line.product.id.startsWith('LOOSE:')
                                            ? line.product.id.substring(6)
                                            : line.product.id,
                                  };
                                  if (_productRepository != null) {
                                    for (final productId in soldProductIds) {
                                      _ProductItem? product;
                                      for (final item in _products) {
                                        if (item.id == productId) {
                                          product = item;
                                          break;
                                        }
                                      }
                                      if (product == null) continue;
                                      await _productRepository!.updateProduct(
                                        _toDomainProduct(product),
                                      );
                                    }
                                  } else {
                                    for (final productId in soldProductIds) {
                                      await _enqueueSync(
                                        'UPDATE',
                                        'inventory',
                                        productId,
                                      );
                                    }
                                  }
                                  for (final audit in stockAuditEntries) {
                                    await _enqueueSync(
                                      'INSERT',
                                      'stock_adjustments',
                                      audit.id,
                                    );
                                  }
                                  for (final returnId in linkedReturnIds) {
                                    await _enqueueSync(
                                      'UPDATE',
                                      'returns',
                                      returnId,
                                    );
                                  }
                                }

                                try {
                                  if (_syncService != null) {
                                    await _syncService!.runWithoutAutoSync(
                                      persistSaleAndQueueSideEffects,
                                    );
                                  } else {
                                    await persistSaleAndQueueSideEffects();
                                  }
                                } catch (e) {
                                  if (!saleSavedLocally) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to save sale locally: $e',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  syncWarning =
                                      'Sale saved locally, but some follow-up sync actions failed: $e';
                                }

                                // ── Agent commission log ──────────────────
                                if (_enableAgentCommission &&
                                    sale.agentName.isNotEmpty &&
                                    sale.agentCommission > 0 &&
                                    _appDatabase != null) {
                                  try {
                                    // Always load the full employees list once
                                    final dbEmps = await _appDatabase!
                                        .getAllEmployees();

                                    // Start with the stored ID from the dropdown (captured before state resets)
                                    String agentEmployeeId = selectedAgentId;

                                    // Validate/Lookup employee ID
                                    if (agentEmployeeId.isNotEmpty) {
                                      final existsInDb = dbEmps.any(
                                        (e) => e.id == agentEmployeeId,
                                      );
                                      if (!existsInDb) {
                                        // Check if they exist in in-memory _users list to get their details
                                        final userRecord = _users.firstWhere(
                                          (u) => u.id == agentEmployeeId,
                                          orElse: () => _UserItem(
                                            id: '',
                                            name: '',
                                            email: '',
                                            role: '',
                                            active: false,
                                          ),
                                        );
                                        final userName =
                                            userRecord.id.isNotEmpty
                                            ? userRecord.name
                                            : sale.agentName;

                                        // Auto-create employee record using their user ID so it's consistent
                                        await _appDatabase!.insertEmployee(
                                          db.EmployeesCompanion(
                                            id: Value(agentEmployeeId),
                                            tenantId: Value(
                                              _activeTenantId ?? 'local',
                                            ),
                                            name: Value(userName),
                                            email: Value(
                                              userRecord.id.isNotEmpty
                                                  ? userRecord.email
                                                  : '',
                                            ),
                                            locationId: Value(
                                              _activeLocationForWrites,
                                            ),
                                            role: Value(
                                              userRecord.id.isNotEmpty
                                                  ? userRecord.role
                                                  : 'AGENT',
                                            ),
                                            isAgent: const Value(true),
                                            synced: const Value(false),
                                            createdAt: Value(
                                              DateTime.now().toUtc(),
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      // If no ID is stored (typed manually), look up by name in employee DB
                                      for (final emp in dbEmps) {
                                        if (emp.name.trim().toLowerCase() ==
                                            sale.agentName.toLowerCase()) {
                                          agentEmployeeId = emp.id;
                                          break;
                                        }
                                      }

                                      // If not in employee DB, look up by name in _users list
                                      if (agentEmployeeId.isEmpty) {
                                        final userRecord = _users.firstWhere(
                                          (u) =>
                                              u.name.trim().toLowerCase() ==
                                              sale.agentName.toLowerCase(),
                                          orElse: () => _UserItem(
                                            id: '',
                                            name: '',
                                            email: '',
                                            role: '',
                                            active: false,
                                          ),
                                        );
                                        if (userRecord.id.isNotEmpty) {
                                          agentEmployeeId = userRecord.id;
                                          // Auto-create employee record using their user ID
                                          await _appDatabase!.insertEmployee(
                                            db.EmployeesCompanion(
                                              id: Value(agentEmployeeId),
                                              tenantId: Value(
                                                _activeTenantId ?? 'local',
                                              ),
                                              name: Value(userRecord.name),
                                              email: Value(userRecord.email),
                                              locationId: Value(
                                                _activeLocationForWrites,
                                              ),
                                              role: Value(userRecord.role),
                                              isAgent: const Value(true),
                                              synced: const Value(false),
                                              createdAt: Value(
                                                DateTime.now().toUtc(),
                                              ),
                                            ),
                                          );
                                        }
                                      }

                                      // If still empty (neither employee nor user exists), auto-create with a deterministic ID
                                      if (agentEmployeeId.isEmpty) {
                                        agentEmployeeId =
                                            'AGT-${sale.agentName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
                                        await _appDatabase!.insertEmployee(
                                          db.EmployeesCompanion(
                                            id: Value(agentEmployeeId),
                                            tenantId: Value(
                                              _activeTenantId ?? 'local',
                                            ),
                                            name: Value(sale.agentName),
                                            email: const Value(''),
                                            locationId: Value(
                                              _activeLocationForWrites,
                                            ),
                                            role: const Value('AGENT'),
                                            isAgent: const Value(true),
                                            synced: const Value(false),
                                            createdAt: Value(
                                              DateTime.now().toUtc(),
                                            ),
                                          ),
                                        );
                                      }
                                    }

                                    // Use the type stored IN the sale record — NOT the
                                    // mutable state variable — so the calculation is
                                    // always consistent with what was captured at
                                    // checkout time (prevents Pay Now vs Pay Later drift).
                                    final agentType = sale.agentCommissionType
                                        .trim()
                                        .toUpperCase();
                                    final commissionAmount =
                                        agentType == 'FIXED'
                                        ? sale.agentCommission
                                        : double.parse(
                                            (grandTotal *
                                                    (sale.agentCommission /
                                                        100))
                                                .toStringAsFixed(2),
                                          );
                                    final logId =
                                        'CL-AGENT-${sale.id}-$agentEmployeeId';
                                    await _appDatabase!.insertCommissionLog(
                                      db.CommissionLogsCompanion(
                                        id: Value(logId),
                                        tenantId: Value(
                                          _activeTenantId ?? 'local',
                                        ),
                                        saleId: Value(sale.id),
                                        employeeId: Value(agentEmployeeId),
                                        saleAmount: Value(grandTotal),
                                        commissionAmount: Value(
                                          commissionAmount,
                                        ),
                                        commissionType: Value(
                                          sale.agentCommissionType,
                                        ),
                                        isPaid: Value(sale.agentCommissionPaid),
                                        paidAt: Value(
                                          sale.agentCommissionPaid
                                              ? DateTime.now().toUtc()
                                              : null,
                                        ),
                                        createdAt: Value(
                                          DateTime.now().toUtc(),
                                        ),
                                      ),
                                    );
                                  } catch (commErr) {
                                    // Surface the error — non-critical but useful
                                    if (mounted) {
                                      ScaffoldMessenger.maybeOf(
                                        context,
                                      )?.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Commission note: could not record commission log. $commErr',
                                          ),
                                          duration: const Duration(seconds: 6),
                                          backgroundColor: Colors.orange,
                                          action: SnackBarAction(
                                            label: 'OK',
                                            textColor: Colors.white,
                                            onPressed: () {},
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                                // ──────────────────────────────────────────

                                 // Trigger Cash Drawer kick immediately if enabled
                                 unawaited(_maybeOpenCashDrawer(paymentMethod: paymentMethod));

                                 // Print receipt immediately with zero delay
                                 String? printWarning;
                                 try {
                                   await _printReceipt(
                                     sale: sale,
                                     lines: cartItems,
                                   );
                                 } catch (e) {
                                   printWarning =
                                       'Sale saved, but receipt printing failed: $e';
                                 }

                                 // Sync queue update runs asynchronously in background so
                                 // receipt printing and checkout UI are never blocked by cloud HTTP latency
                                 unawaited(() async {
                                   try {
                                     await _refreshPendingSyncQueue();
                                     await _triggerImmediateSync(
                                       action: 'INSERT',
                                       module: 'sales',
                                       reference: sale.id,
                                     );
                                   } catch (syncErr) {
                                     debugPrint('Background sync after sale complete error: $syncErr');
                                   }
                                 }());

                                if (paymentMethod == 'COD' ||
                                    sale.shippingAddress.isNotEmpty ||
                                    _localPromptDeliveryLabel) {
                                  try {
                                    await _printDeliveryNote(sale);
                                  } catch (_) {}
                                }

                                if (paymentMethod == 'COD' && _enableWhatsappCodNotifications) {
                                  final customerPhone = sale.customerPhone.isNotEmpty
                                      ? sale.customerPhone
                                      : selectedCustomer.phone;
                                  if (customerPhone.isNotEmpty) {
                                    try {
                                      final ws = WhatsAppService(context.read<ApiClient>());
                                      ws.sendDeliveryNote(
                                        customerPhone: customerPhone,
                                        customerName: sale.customerName,
                                        invoiceNumber: sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : sale.id,
                                        deliveryOtp: codDeliveryOtp,
                                        totalAmount: sale.total,
                                        shippingAddress: sale.shippingAddress,
                                        assignedDriverName: sale.deliveryPersonName,
                                        storeName: _companyName.isNotEmpty ? _companyName : 'StoreBuddy Store',
                                      ).then((res) {
                                        if (res['success'] == true) {
                                          _addNotification(
                                            title: 'WhatsApp Delivery Note Sent',
                                            message: 'WhatsApp delivery note & OTP sent to customer ($customerPhone) for invoice ${sale.id}',
                                            type: 'delivery',
                                            targetLocation: sale.locationId,
                                            referenceId: sale.id,
                                          );
                                        }
                                      }).catchError((_) {});
                                    } catch (_) {}
                                  }
                                }

                                if (!mounted || !context.mounted) return;
                                try {
                                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        printWarning ??
                                            syncWarning ??
                                            (installmentPlan != null
                                                ? 'Installment plan created for ${sale.id}'
                                                : isCreditSale
                                                ? 'Credit sale recorded: ${sale.id}'
                                                : 'Sale completed: ${sale.id}'),
                                      ),
                                    ),
                                  );
                                } catch (_) {}
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(UiRadius.md),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _editingSaleId != null
                                  ? Icons.save_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _editingSaleId != null
                                  ? 'Update Bill • ${_money(grandTotal)}'
                                  : 'Complete Sale • ${_money(grandTotal)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    productPanel,
                    const SizedBox(height: 12),
                    cartPanel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: productPanel),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: cartPanel),
                ],
              );
            },
          ),
        ],
      ),
    );

    if (_isCashier && activeSession == null) {
      return Stack(
        children: [
          AbsorbPointer(
            absorbing: true,
            child: Opacity(opacity: 0.35, child: mainContent),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Center(
                  child: Container(
                    width: ResponsiveLayout.adaptiveDialogWidth(context, 450),
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1B29).withOpacity(0.85)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.purple,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Register Session Closed',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You must open a cashier register session with a starting cash-in-hand balance to perform sales transactions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: UiGradients.brand,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _triggerOpenRegisterDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Open Cash Register',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return mainContent;
  }

  Widget _posPaymentButton(
    String key,
    String label,
    String selected,
    double grandTotal,
  ) {
    final isSelected = key == selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData getIcon(String k) {
      switch (k.toUpperCase()) {
        case 'CASH':
          return Icons.payments_outlined;
        case 'CARD':
          return Icons.credit_card_outlined;
        case 'CHEQUE':
          return Icons.sticky_note_2_outlined;
        case 'CREDIT':
          return Icons.badge_outlined;
        case 'INSTALLMENT':
          return Icons.calendar_month_outlined;
        case 'COD':
          return Icons.local_shipping_outlined;
        default:
          return Icons.payment_outlined;
      }
    }

    return Expanded(
      child: Material(
        color: isSelected
            ? (isDark
                  ? AppTheme.brandIndigo.withValues(alpha: 0.15)
                  : AppTheme.brandIndigo.withValues(alpha: 0.08))
            : (isDark ? const Color(0xFF111827) : Colors.white),
        borderRadius: BorderRadius.circular(UiRadius.md),
        child: InkWell(
          onTap: () => _applyPosPaymentMethod(key, grandTotal),
          borderRadius: BorderRadius.circular(UiRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiRadius.md),
              border: Border.all(
                color: isSelected
                    ? AppTheme.brandIndigo
                    : (isDark
                          ? const Color(0xFF1E2D45)
                          : const Color(0xFFE8EAFF)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getIcon(key),
                  size: 18,
                  color: isSelected
                      ? AppTheme.brandIndigo
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.brandIndigo
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155)),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _posPaymentCompactButton(
    String key,
    String label,
    String selected,
    double grandTotal,
  ) {
    final isSelected = key == selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData getIcon(String k) {
      switch (k.toUpperCase()) {
        case 'CASH':
          return Icons.payments_outlined;
        case 'CARD':
          return Icons.credit_card_outlined;
        case 'CHEQUE':
          return Icons.sticky_note_2_outlined;
        case 'CREDIT':
          return Icons.badge_outlined;
        case 'INSTALLMENT':
          return Icons.calendar_month_outlined;
        case 'COD':
          return Icons.local_shipping_outlined;
        default:
          return Icons.payment_outlined;
      }
    }

    return SizedBox(
      width: 104,
      child: Material(
        color: isSelected
            ? (isDark
                  ? AppTheme.brandIndigo.withValues(alpha: 0.15)
                  : AppTheme.brandIndigo.withValues(alpha: 0.08))
            : (isDark ? const Color(0xFF111827) : Colors.white),
        borderRadius: BorderRadius.circular(UiRadius.md),
        child: InkWell(
          onTap: () => _applyPosPaymentMethod(key, grandTotal),
          borderRadius: BorderRadius.circular(UiRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiRadius.md),
              border: Border.all(
                color: isSelected
                    ? AppTheme.brandIndigo
                    : (isDark
                          ? const Color(0xFF1E2D45)
                          : const Color(0xFFE8EAFF)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getIcon(key),
                  size: 16,
                  color: isSelected
                      ? AppTheme.brandIndigo
                      : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.brandIndigo
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155)),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLineDiscountDialog(_ProductItem product) {
    final TextEditingController valueController = TextEditingController(
      text: _posLineDiscounts[product.id]?.value.toString() ?? '',
    );
    String type = _posLineDiscounts[product.id]?.type ?? 'FIXED';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Discount for ${product.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Fixed Amount'),
                          value: 'FIXED',
                          groupValue: type,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Percentage (%)'),
                          value: 'PERCENT',
                          groupValue: type,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'PERCENT'
                          ? 'Discount %'
                          : 'Discount Amount',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _posLineDiscounts.remove(product.id);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(valueController.text) ?? 0.0;
                    if (value > 0) {
                      setState(() {
                        _posLineDiscounts[product.id] = _DiscountData(
                          value: type == 'PERCENT'
                              ? value.clamp(0, 100)
                              : value,
                          type: type,
                        );
                      });
                    } else {
                      setState(() {
                        _posLineDiscounts.remove(product.id);
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInvoiceDiscountDialog() {
    final TextEditingController valueController = TextEditingController(
      text: _posInvoiceDiscountValue > 0
          ? _posInvoiceDiscountValue.toString()
          : '',
    );
    String type = _posInvoiceDiscountType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Invoice Discount'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Fixed Amount'),
                          value: 'FIXED',
                          groupValue: type,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Percentage (%)'),
                          value: 'PERCENT',
                          groupValue: type,
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'PERCENT'
                          ? 'Discount %'
                          : 'Discount Amount',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _posInvoiceDiscountValue = 0.0;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(valueController.text) ?? 0.0;
                    setState(() {
                      _posInvoiceDiscountValue = type == 'PERCENT'
                          ? value.clamp(0, 100)
                          : value;
                      _posInvoiceDiscountType = type;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showProductSkuSelectionDialog(
    List<_ProductItem> options,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiRadius.lg),
          ),
          title: const Text(
            'Select Variant / Batch',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: ResponsiveLayout.adaptiveDialogWidth(context, 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multiple products share this barcode or name. Please select the correct batch / price variant:',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = options[index];
                      final expText = item.expiryDate != null
                          ? ' • Exp: ${item.expiryDate!.toLocal().toString().split(' ').first}'
                          : '';
                      final branchText = item.locationId.isNotEmpty && item.locationId != 'LOC_MAIN'
                          ? ' • Loc: ${item.locationId}'
                          : '';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandIndigo.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.brandIndigo.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      'Batch #${index + 1}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.brandIndigo,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _money(item.price),
                              style: TextStyle(
                                color: AppTheme.brandIndigo,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'SKU/Bar: ${item.barcode.trim().isNotEmpty ? item.barcode : item.id} • Cost: ${_money(item.costPrice ?? 0.0)}$expText$branchText',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Stock: ${item.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.stock <= item.minStock
                                      ? AppTheme.brandRose
                                      : AppTheme.brandEmerald,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          Icons.add_shopping_cart_rounded,
                          color: colorScheme.primary,
                        ),
                        onTap: () {
                          if (item.stock <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This batch is out of stock!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            return;
                          }
                          if (item.allowLooseSales) {
                            Navigator.pop(ctx);
                            _showDualUnitSelectionDialog(item);
                            _productSearchController.clear();
                            return;
                          }
                          _addToCartWithImeiSelection(item);
                          _productSearchController.clear();
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  _ProductItem? _findProductByImei(String query) {
    if (!_enableMobileShopFeatures) return null;
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    for (final p in _scopedProducts) {
      if (p.imeis != null && p.imeis!.isNotEmpty) {
        final imeisList = p.imeiList;
        for (final imei in imeisList) {
          if (imei.toLowerCase() == trimmed) {
            return p;
          }
        }
      }
    }
    return null;
  }

  void _addToCartWithImeiSelection(_ProductItem item, [String? imei]) {
    final currentQty = _cart[item.id] ?? 0;
    if (currentQty >= item.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot exceed available stock of ${item.stock}!'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _cart[item.id] = currentQty + 1;

      if (_enableMobileShopFeatures &&
          item.imeis != null &&
          item.imeis!.trim().isNotEmpty) {
        final availableImeis = item.imeiList;
        if (availableImeis.isNotEmpty) {
          final currentSelected = _selectedCartImeis[item.id] ?? [];
          final nextSelected = List<String>.from(currentSelected);

          if (imei != null &&
              availableImeis.contains(imei) &&
              !nextSelected.contains(imei)) {
            nextSelected.add(imei);
          } else {
            final unselected = availableImeis.firstWhere(
              (x) => !nextSelected.contains(x),
              orElse: () => '',
            );
            nextSelected.add(unselected);
          }
          _selectedCartImeis[item.id] = nextSelected;
        }
      }
    });
  }

  void _decrementCartImei(_ProductItem item) {
    setState(() {
      final currentQty = _cart[item.id] ?? 0;
      final next = currentQty - 1;
      if (next <= 0) {
        _removeTemporaryCartProducts([item.id]);
        _cart.remove(item.id);
        _selectedCartImeis.remove(item.id);
      } else {
        _cart[item.id] = next;
        if (_enableMobileShopFeatures &&
            _selectedCartImeis.containsKey(item.id)) {
          final list = _selectedCartImeis[item.id]!;
          if (list.isNotEmpty) {
            list.removeLast();
          }
        }
      }
    });
  }

  void _removeCartImei(_ProductItem item) {
    setState(() {
      _removeTemporaryCartProducts([item.id]);
      _cart.remove(item.id);
      _selectedCartImeis.remove(item.id);
    });
  }

  Future<void> _showEditCartQuantityDialog(_CartLine line) async {
    final controller = TextEditingController(
      text: line.qty.truncateToDouble() == line.qty
          ? line.qty.toInt().toString()
          : line.qty.toString(),
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit Quantity - ${line.product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity (${line.product.measureUnit})',
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
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text.trim());
                if (val == null) return;
                setState(() {
                  if (val <= 0) {
                    _removeCartImei(line.product);
                  } else {
                    _cart[line.product.id] = (val * 100).round() / 100.0;
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDualUnitSelectionDialog(_ProductItem product) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryUnit = product.measureUnit;
    final secondaryUnit = product.secondaryUnit;
    final ratio = product.unitConversionRatio > 0
        ? product.unitConversionRatio
        : 1.0;
    final loosePrice = product.secondaryPrice ??
        (ratio > 0 ? (product.price / ratio) : product.price);

    bool isLooseSelected = false;
    double chosenQty = 1.0;
    final qtyController = TextEditingController(text: '1');

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final activeUnit = isLooseSelected ? secondaryUnit : primaryUnit;
            final activeUnitPrice =
                isLooseSelected ? loosePrice : product.price;
            final lineTotal = activeUnitPrice * chosenQty;

            final totalLooseStock =
                ratio > 0 ? (product.stock * ratio) : product.stock;
            final maxStock = isLooseSelected ? totalLooseStock : product.stock;
            final stockWarning = chosenQty > maxStock;

            void updateQty(double newQty) {
              if (newQty < 0.01) newQty = 0.01;
              setLocal(() {
                chosenQty = (newQty * 100).round() / 100.0;
                qtyController.text = chosenQty.truncateToDouble() == chosenQty
                    ? chosenQty.toInt().toString()
                    : chosenQty.toString();
              });
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.scale_rounded,
                      color: Color(0xFF0EA5E9),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stock: ${_formatDualStock(product.stock, primaryUnit, secondaryUnit, ratio)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: product.stock <= product.minStock
                                ? AppTheme.brandRose
                                : AppTheme.brandEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Select Selling Unit:'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setLocal(() {
                                  isLooseSelected = false;
                                  updateQty(1.0);
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: !isLooseSelected
                                      ? const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.12)
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                            : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !isLooseSelected
                                        ? const Color(0xFF6366F1)
                                        : (isDark
                                              ? Colors.white12
                                              : Colors.grey.shade300),
                                    width: !isLooseSelected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 24,
                                      color: !isLooseSelected
                                          ? const Color(0xFF6366F1)
                                          : (isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Full $primaryUnit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: !isLooseSelected
                                            ? const Color(0xFF6366F1)
                                            : (isDark
                                                  ? Colors.white
                                                  : Colors.grey.shade800),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _money(product.price),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: !isLooseSelected
                                            ? const Color(0xFF6366F1)
                                            : (isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setLocal(() {
                                  isLooseSelected = true;
                                  updateQty(1.0);
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isLooseSelected
                                      ? const Color(
                                          0xFF0EA5E9,
                                        ).withValues(alpha: 0.12)
                                      : (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                            : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isLooseSelected
                                        ? const Color(0xFF0EA5E9)
                                        : (isDark
                                              ? Colors.white12
                                              : Colors.grey.shade300),
                                    width: isLooseSelected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.scale_rounded,
                                      size: 24,
                                      color: isLooseSelected
                                          ? const Color(0xFF0EA5E9)
                                          : (isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Loose $secondaryUnit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: isLooseSelected
                                            ? const Color(0xFF0EA5E9)
                                            : (isDark
                                                  ? Colors.white
                                                  : Colors.grey.shade800),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_money(loosePrice)} / $secondaryUnit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isLooseSelected
                                            ? const Color(0xFF0EA5E9)
                                            : (isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isLooseSelected) ...[
                        Text(
                          _t('Quick Quantity:'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [0.5, 1.0, 2.0, 5.0, 10.0, 25.0]
                              .where((q) => q <= ratio)
                              .map((chipQty) {
                                final isSel = chosenQty == chipQty;
                                return InkWell(
                                  onTap: () => updateQty(chipQty),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? const Color(0xFF0EA5E9)
                                          : (isDark
                                                ? Colors.white10
                                                : Colors.grey.shade200),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '+${chipQty.truncateToDouble() == chipQty ? chipQty.toInt() : chipQty} $secondaryUnit',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSel
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade800),
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              final step = 1.0;
                              updateQty(
                                (chosenQty - step).clamp(0.1, 999999.0),
                              );
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppTheme.brandRose,
                          ),
                          Expanded(
                            child: TextField(
                              controller: qtyController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                suffixText: activeUnit,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (val) {
                                final v = double.tryParse(val.trim());
                                if (v != null && v > 0) {
                                  setLocal(() {
                                    chosenQty = v;
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              final step = 1.0;
                              updateQty(chosenQty + step);
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppTheme.brandEmerald,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: stockWarning
                                ? Colors.redAccent
                                : (isDark
                                      ? Colors.white10
                                      : Colors.grey.shade300),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total for this line:',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  _money(lineTotal),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                            if (isLooseSelected) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Stock Deduction:',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${(chosenQty / ratio).toStringAsFixed(3)} $primaryUnit',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (stockWarning) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 14,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Exceeds available stock ($maxStock $activeUnit)!',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final targetCartId = isLooseSelected
                        ? 'LOOSE:${product.id}'
                        : product.id;
                    final currentQty = _cart[targetCartId] ?? 0;
                    final newQty = currentQty + chosenQty;

                    if (newQty > maxStock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Cannot exceed available stock of $maxStock $activeUnit!',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _cart[targetCartId] = (newQty * 100).round() / 100.0;
                    });
                    _productSearchController.clear();
                    Navigator.pop(dialogCtx);
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Add to Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLooseSelected
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
