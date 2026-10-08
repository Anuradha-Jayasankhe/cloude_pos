part of '../dashboard_screen.dart';

extension _barcode_printing_pageExt on _DashboardScreenState {
  Widget _buildBarcodePrintingPage() {
    final query = _barcodeSearchController.text.trim().toLowerCase();
    final visibleProducts = _scopedProducts.where((product) {
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(query) ||
          product.id.toLowerCase().contains(query) ||
          product.barcode.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();

    final selectedVisibleCount = visibleProducts
        .where((product) => _selectedBarcodeProductIds.contains(product.id))
        .length;
    final allVisibleSelected =
        visibleProducts.isNotEmpty &&
        selectedVisibleCount == visibleProducts.length;
    final selectedProductsCount = _selectedBarcodeProductIds.length;

    final totalLabelsCount = _selectedBarcodeProductIds.fold<int>(
      0,
      (sum, productId) {
        final matchIdx = _products.indexWhere((p) => p.id == productId);
        if (matchIdx != -1) {
          final prod = _products[matchIdx];
          if (_barcodePrintIndividualImei && prod.imeiList.isNotEmpty) {
            return sum + prod.imeiList.length;
          }
        }
        return sum + _barcodeQuantityForProduct(productId);
      },
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, headerConstraints) {
                final titleMaxWidth = (headerConstraints.maxWidth - 54).clamp(
                  120.0,
                  360.0,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const GradientIconBox(
                              icon: Icons.qr_code_2_rounded,
                              size: 42,
                              iconSize: 21,
                            ),
                            const SizedBox(width: 12),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: titleMaxWidth,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Barcode & Label Printing',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Presets for Zebra, Dymo, Brother, Thermal POS rolls, and A4/Letter sheets.',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: selectedProductsCount == 0
                              ? null
                              : _printSelectedProductBarcodes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: Text(
                            'Print $totalLabelsCount Labels ($selectedProductsCount Products)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Configuration Card
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Destination Printer Banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: _localLabelPrinterName != null &&
                                        _localLabelPrinterName!.isNotEmpty
                                    ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _localLabelPrinterName != null &&
                                          _localLabelPrinterName!.isNotEmpty
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.3)
                                      : Colors.blue.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _localLabelPrinterName != null &&
                                            _localLabelPrinterName!.isNotEmpty
                                        ? Icons.print_rounded
                                        : Icons.info_outline_rounded,
                                    size: 16,
                                    color: _localLabelPrinterName != null &&
                                            _localLabelPrinterName!.isNotEmpty
                                        ? const Color(0xFF10B981)
                                        : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _localLabelPrinterName != null &&
                                              _localLabelPrinterName!.isNotEmpty
                                          ? 'Direct Output Printer: "$_localLabelPrinterName" (Local Binding)'
                                          : 'Output Destination: System Print Dialog (Bind a dedicated label printer in Print Settings)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _localLabelPrinterName != null &&
                                                _localLabelPrinterName!.isNotEmpty
                                            ? const Color(0xFF10B981)
                                            : (isDark
                                                ? Colors.blue.shade300
                                                : Colors.blue.shade800),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Row 1: Presets & Symbology
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 260,
                                    maxWidth: 340,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: [
                                      'a4_3x10',
                                      'a4_2x7',
                                      'a4_4x13',
                                      'letter_3x10',
                                      'zebra_1col_50x30',
                                      'zebra_2col_38x25',
                                      'zebra_3col_32x19',
                                      'dymo_single_54x25',
                                      'dymo_large_89x36',
                                      'brother_ql_62x29',
                                      'generic_80mm_roll',
                                      'generic_58mm_roll',
                                      'custom',
                                    ].contains(_barcodePreset)
                                        ? _barcodePreset
                                        : 'a4_3x10',
                                    decoration: const InputDecoration(
                                      labelText: 'Label Size Preset',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(
                                        Icons.aspect_ratio_rounded,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'a4_3x10',
                                        child: Text(
                                          'A4: 3x10 (30 Labels, 64x25mm)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'a4_2x7',
                                        child: Text(
                                          'A4: 2x7 (14 Labels, 99x38mm)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'a4_4x13',
                                        child: Text(
                                          'A4: 4x13 (52 Labels, 48x21mm)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'letter_3x10',
                                        child: Text(
                                          'Letter: 3x10 (30 Labels, 66x25mm)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'zebra_1col_50x30',
                                        child: Text(
                                          'Zebra 1-Col (50x30mm Roll)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'zebra_2col_38x25',
                                        child: Text(
                                          'Zebra 2-Col (38x25mm Roll)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'zebra_3col_32x19',
                                        child: Text(
                                          'Zebra 3-Col (32x19mm Jewelry)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'dymo_single_54x25',
                                        child: Text(
                                          'Dymo Single (54x25mm Standard)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'dymo_large_89x36',
                                        child: Text('Dymo Large (89x36mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'brother_ql_62x29',
                                        child: Text(
                                          'Brother QL (62x29mm Die-cut)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'generic_80mm_roll',
                                        child: Text(
                                          'Thermal POS 80mm Roll (72x30mm)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'generic_58mm_roll',
                                        child: Text(
                                          'Thermal POS 58mm Roll (50x25mm)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'custom',
                                        child: Text('Custom (Manual Sliders)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) _applyBarcodePreset(val);
                                    },
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 180,
                                    maxWidth: 240,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: [
                                      'CODE128',
                                      'CODE39',
                                      'EAN13',
                                      'UPCA',
                                      'QR',
                                    ].contains(_barcodeFormat)
                                        ? _barcodeFormat
                                        : 'CODE128',
                                    decoration: const InputDecoration(
                                      labelText: 'Barcode Symbology',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.qr_code_rounded),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'CODE128',
                                        child: Text('Code 128 (Standard)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'CODE39',
                                        child: Text('Code 39 (Alphanumeric)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'EAN13',
                                        child: Text('EAN-13 (13-digit GTIN)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'UPCA',
                                        child: Text('UPC-A (12-digit US)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'QR',
                                        child: Text('QR Code (2D Matrix)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _barcodeFormat = val);
                                      }
                                    },
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 120,
                                    maxWidth: 160,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Width: ${_barcodeLabelWidthMm.toStringAsFixed(0)} mm',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Slider(
                                        min: 25,
                                        max: 105,
                                        divisions: 80,
                                        value: _barcodeLabelWidthMm.clamp(
                                          25.0,
                                          105.0,
                                        ),
                                        onChanged: (value) => setState(
                                          () => _barcodeLabelWidthMm = value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 120,
                                    maxWidth: 160,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Height: ${_barcodeLabelHeightMm.toStringAsFixed(0)} mm',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Slider(
                                        min: 15,
                                        max: 60,
                                        divisions: 45,
                                        value: _barcodeLabelHeightMm.clamp(
                                          15.0,
                                          60.0,
                                        ),
                                        onChanged: (value) => setState(
                                          () => _barcodeLabelHeightMm = value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 120,
                                    maxWidth: 150,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scale: ${_barcodeFontScale.toStringAsFixed(2)}x',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Slider(
                                        min: 0.7,
                                        max: 1.5,
                                        divisions: 16,
                                        value: _barcodeFontScale.clamp(
                                          0.7,
                                          1.5,
                                        ),
                                        onChanged: (value) => setState(
                                          () => _barcodeFontScale = value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Row 2: Toggles & Display Options
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FilterChip(
                                  avatar: const Icon(
                                    Icons.fingerprint_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Print Individual Labels per Serial / IMEI',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  selected: _barcodePrintIndividualImei,
                                  selectedColor: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.2),
                                  checkmarkColor: const Color(0xFF6366F1),
                                  onSelected: (val) => setState(
                                    () => _barcodePrintIndividualImei = val,
                                  ),
                                ),
                                FilterChip(
                                  label: const Text('Show Name'),
                                  selected: _barcodeShowName,
                                  onSelected: (value) =>
                                      setState(() => _barcodeShowName = value),
                                ),
                                FilterChip(
                                  label: const Text('Show Price'),
                                  selected: _barcodeShowPrice,
                                  onSelected: (value) =>
                                      setState(() => _barcodeShowPrice = value),
                                ),
                                FilterChip(
                                  label: const Text('Show SKU'),
                                  selected: _barcodeShowSku,
                                  onSelected: (value) =>
                                      setState(() => _barcodeShowSku = value),
                                ),
                                FilterChip(
                                  label: const Text('Show Barcode Text'),
                                  selected: _barcodeShowCodeText,
                                  onSelected: (value) => setState(
                                    () => _barcodeShowCodeText = value,
                                  ),
                                ),
                                FilterChip(
                                  label: const Text('Show Category'),
                                  selected: _barcodeShowCategory,
                                  onSelected: (value) => setState(
                                    () => _barcodeShowCategory = value,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search & Multi-select Bar
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 340,
                          child: TextField(
                            controller: _barcodeSearchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText:
                                  'Search by name, barcode, SKU or category...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon:
                                  _barcodeSearchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              size: 18),
                                          onPressed: () {
                                            _barcodeSearchController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: allVisibleSelected,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  for (final product in visibleProducts) {
                                    if (value) {
                                      _selectedBarcodeProductIds.add(product.id);
                                      _barcodeQuantityByProduct.putIfAbsent(
                                        product.id,
                                        () => 1,
                                      );
                                    } else {
                                      _selectedBarcodeProductIds
                                          .remove(product.id);
                                    }
                                  }
                                });
                              },
                            ),
                            Text(
                              'Select all visible (${visibleProducts.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedBarcodeProductIds.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedBarcodeProductIds.clear();
                              });
                            },
                            icon: const Icon(Icons.clear_all_rounded, size: 16),
                            label: const Text('Clear All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),

          // Products List
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            sliver: SliverToBoxAdapter(
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: visibleProducts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(36),
                        child: Center(
                          child: Text(
                            'No products found matching your search.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visibleProducts.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = visibleProducts[index];
                          final selected = _selectedBarcodeProductIds.contains(
                            product.id,
                          );
                          final hasImeis = product.imeiList.isNotEmpty;
                          final isAutoImei =
                              _barcodePrintIndividualImei && hasImeis;
                          final quantity = isAutoImei
                              ? product.imeiList.length
                              : _barcodeQuantityForProduct(product.id);

                          final checkboxWidget = Checkbox(
                            value: selected,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                if (value) {
                                  _selectedBarcodeProductIds.add(product.id);
                                  _barcodeQuantityByProduct.putIfAbsent(
                                    product.id,
                                    () => 1,
                                  );
                                } else {
                                  _selectedBarcodeProductIds.remove(product.id);
                                }
                              });
                            },
                          );

                          final infoWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SKU: ${product.id} | Barcode: ${product.barcode.isEmpty ? "(none)" : product.barcode} | ${product.category} | ${_money(product.price)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              if (hasImeis) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          Colors.blue.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.tag_rounded,
                                        size: 13,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${product.imeiList.length} Serial / IMEIs Tracked',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );

                          final quantityStepper = isAutoImei
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${product.imeiList.length} Labels (Auto S/N)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: selected
                                          ? () => _setBarcodeQuantityForProduct(
                                                product.id,
                                                quantity - 1,
                                              )
                                          : null,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '$quantity',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: selected
                                          ? () => _setBarcodeQuantityForProduct(
                                                product.id,
                                                quantity + 1,
                                              )
                                          : null,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                );

                          final singlePrintButton = OutlinedButton.icon(
                            onPressed: () => _printProductBarcode(product),
                            icon: const Icon(Icons.print_outlined, size: 16),
                            label: Text(
                              isAutoImei
                                  ? 'Print All ${product.imeiList.length} IMEIs'
                                  : 'Single Print',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          );

                          final isPhoneWidth =
                              MediaQuery.of(context).size.width <
                              UiBreakpoints.phone;

                          if (isPhoneWidth) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      checkboxWidget,
                                      Expanded(child: infoWidget),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      quantityStepper,
                                      singlePrintButton,
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                checkboxWidget,
                                Expanded(child: infoWidget),
                                const SizedBox(width: 12),
                                quantityStepper,
                                const SizedBox(width: 12),
                                singlePrintButton,
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
