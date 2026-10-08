part of '../dashboard_screen.dart';

class DiscountsPage extends StatefulWidget {
  final db.AppDatabase appDatabase;
  final String tenantId;
  final Future<void> Function()? onDiscountsChanged;

  const DiscountsPage({
    super.key,
    required this.appDatabase,
    required this.tenantId,
    this.onDiscountsChanged,
  });

  @override
  State<DiscountsPage> createState() => _DiscountsPageState();
}

class _DiscountsPageState extends State<DiscountsPage> {
  List<db.Discount> _discounts = [];
  List<db.Product> _products = [];
  bool _loading = true;

  String _productNameById(String id) {
    for (final product in _products) {
      if (product.id == id) return product.name;
    }
    return id;
  }

  List<String> _decodeDelimitedIds(String? encoded) {
    if (encoded == null || encoded.trim().isEmpty) return const [];
    return encoded
        .split(RegExp(r'[|,]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Future<void> _pickDiscountProducts(
    Set<String> selectedProductIds,
    String type,
    void Function(void Function()) setDialogState,
  ) async {
    final searchController = TextEditingController();
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        final localSelected = <String>{...selectedProductIds};
        return StatefulBuilder(
          builder: (context, setLocal) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = _products.where((product) {
              if (query.isEmpty) return true;
              return product.name.toLowerCase().contains(query) ||
                  (product.sku?.toLowerCase().contains(query) ?? false) ||
                  (product.barcode?.toLowerCase().contains(query) ?? false);
            }).toList();

            return AlertDialog(
              title: const Text('Select Discount Items'),
              content: SizedBox(
                width: ResponsiveLayout.adaptiveDialogWidth(context, 720),
                height: ResponsiveLayout.adaptiveDialogHeight(context, 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search products',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setLocal(() {}),
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const Expanded(
                        child: Center(child: Text('No products found.')),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            final selected = localSelected.contains(product.id);
                            return CheckboxListTile(
                              value: selected,
                              title: Text(product.name),
                              subtitle: Text(
                                [
                                  if (product.sku?.isNotEmpty == true)
                                    'SKU: ${product.sku}',
                                  if (product.barcode?.isNotEmpty == true)
                                    'Barcode: ${product.barcode}',
                                ].join(' • '),
                              ),
                              onChanged: (value) {
                                setLocal(() {
                                  if (value == true) {
                                    localSelected.add(product.id);
                                  } else {
                                    localSelected.remove(product.id);
                                  }
                                });
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (type == 'PROMO' && localSelected.isNotEmpty) {
                      setDialogState(() => type = 'PRODUCT');
                    }
                    Navigator.pop(dialogContext, localSelected);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(UiRadius.md),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
    searchController.dispose();
    if (result == null) return;
    setDialogState(() {
      selectedProductIds
        ..clear()
        ..addAll(result);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDiscounts();
  }

  Future<void> _loadDiscounts() async {
    setState(() => _loading = true);
    try {
      final all = await widget.appDatabase
          .select(widget.appDatabase.discounts)
          .get();
      final products = await widget.appDatabase.getAllProducts();
      setState(() {
        _discounts = all;
        _products = products;
      });
    } catch (e) {
      debugPrint('Failed to load discounts: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDiscountDialog([db.Discount? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final valueController = TextEditingController(
      text: (existing?.value ?? 0).toString(),
    );
    final conditionsController = TextEditingController(
      text: existing?.conditions ?? '',
    );
    String type = existing?.type ?? 'PROMO';
    String mode = existing?.discountMode ?? 'PERCENT';
    bool isActive = existing?.isActive ?? true;
    DateTime? expiresAt = existing?.expiresAt;
    final selectedProductIds = <String>{
      ...((existing?.productId ?? '')
          .split(RegExp(r'[|,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)),
    };
    final productLookup = {for (final p in _products) p.id: p.name};

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DiscountDialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return _SideSheetContainer(
              title: existing == null ? 'Create Discount' : 'Edit Discount',
              width: 560,
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty ||
                          valueController.text.isEmpty) {
                        return;
                      }
                      final encodedProductIds = selectedProductIds.toList().join(
                        '|',
                      );

                      final companion = db.DiscountsCompanion(
                        id: existing != null
                            ? Value(existing.id)
                            : Value('DSC${DateTime.now().millisecondsSinceEpoch}'),
                        tenantId: Value(widget.tenantId),
                        name: Value(nameController.text.trim()),
                        type: Value(type),
                        discountMode: Value(mode),
                        value: Value(
                          double.tryParse(valueController.text.trim()) ?? 0,
                        ),
                        productId: Value(
                          encodedProductIds.isEmpty ? null : encodedProductIds,
                        ),
                        conditions: Value(
                          conditionsController.text.trim().isEmpty
                              ? null
                              : conditionsController.text.trim(),
                        ),
                        isActive: Value(isActive),
                        expiresAt: Value(expiresAt),
                        createdAt: existing != null
                            ? Value(existing.createdAt)
                            : Value(DateTime.now()),
                      );

                      if (existing == null) {
                        await widget.appDatabase
                            .into(widget.appDatabase.discounts)
                            .insert(companion);
                      } else {
                        await (widget.appDatabase.update(
                          widget.appDatabase.discounts,
                        )..where((t) => t.id.equals(existing.id))).write(companion);
                      }

                      if (widget.onDiscountsChanged != null) {
                        await widget.onDiscountsChanged!();
                      }

                      if (mounted) Navigator.pop(context);
                      _loadDiscounts();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Weekend Sale',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'PROMO',
                          child: Text('Promotional'),
                        ),
                        DropdownMenuItem(
                          value: 'PRODUCT',
                          child: Text('Product-specific'),
                        ),
                        DropdownMenuItem(
                          value: 'INVOICE',
                          child: Text('Invoice-level'),
                        ),
                        DropdownMenuItem(
                          value: 'CUSTOMER',
                          child: Text('Customer Type'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: mode,
                      decoration: const InputDecoration(labelText: 'Mode'),
                      items: const [
                        DropdownMenuItem(
                          value: 'PERCENT',
                          child: Text('Percentage (%)'),
                        ),
                        DropdownMenuItem(
                          value: 'FIXED',
                          child: Text('Fixed Amount'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => mode = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Value'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Apply to Items',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _products.isEmpty
                              ? null
                              : () => _pickDiscountProducts(
                                  selectedProductIds,
                                  type,
                                  setDialogState,
                                ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Select Items'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_products.isEmpty)
                      const Text(
                        'No products available. Add inventory products first, then link this discount.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D7383),
                        ),
                      )
                    else if (selectedProductIds.isEmpty)
                      const Text(
                        'No items selected yet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D7383),
                        ),
                      )
                    else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedProductIds.map((id) {
                          final productName = productLookup[id] ?? id;
                          return InputChip(
                            label: Text(productName),
                            onDeleted: () => setDialogState(() {
                              selectedProductIds.remove(id);
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selected: ${selectedProductIds.map((id) => productLookup[id] ?? id).join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D7383),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: conditionsController,
                      decoration: const InputDecoration(
                        labelText: 'Conditions (Optional)',
                        hintText: 'e.g. {"buy": 2, "get": 1}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiresAt ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => expiresAt = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                        ),
                        child: Text(
                          expiresAt == null
                              ? 'No expiry date'
                              : '${expiresAt!.year}-${expiresAt!.month.toString().padLeft(2, '0')}-${expiresAt!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            );
          },
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

  Future<void> _deleteDiscount(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Discount'),
        content: const Text('Are you sure you want to delete this discount?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiRadius.md),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await (widget.appDatabase.delete(
        widget.appDatabase.discounts,
      )..where((t) => t.id.equals(id))).go();
      if (widget.onDiscountsChanged != null) {
        await widget.onDiscountsChanged!();
      }
      _loadDiscounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(UiSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final header = compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discounts & Promotions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showDiscountDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Discount'),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discounts & Promotions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showDiscountDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(UiRadius.md),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Discount'),
                    ),
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  child: ListView.separated(
                    itemCount: _discounts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final discount = _discounts[index];
                      final selectedIds = _decodeDelimitedIds(
                        discount.productId,
                      );
                      return ListTile(
                        title: Text(
                          discount.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            discount.type,
                            discount.discountMode == 'PERCENT'
                                ? '${discount.value}%'
                                : 'Rs. ${discount.value}',
                            if (selectedIds.isNotEmpty)
                              'Items: ${selectedIds.map(_productNameById).join(', ')}',
                          ].join(' • '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: discount.isActive,
                              onChanged: (val) async {
                                await (widget.appDatabase.update(
                                      widget.appDatabase.discounts,
                                    )..where((t) => t.id.equals(discount.id)))
                                    .write(
                                      db.DiscountsCompanion(
                                        isActive: Value(val),
                                      ),
                                    );
                                if (widget.onDiscountsChanged != null) {
                                  await widget.onDiscountsChanged!();
                                }
                                _loadDiscounts();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showDiscountDialog(discount),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteDiscount(discount.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
