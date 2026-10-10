part of '../dashboard_screen.dart';

extension _barcode_printing_pageExt on _DashboardScreenState {
  Widget _buildBarcodePrintingPage() {
    if (_barcodeRollWidthController.text.isEmpty) {
      _syncBarcodeControllersWithValues();
    }
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
                                vertical: 10,
                              ),
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: _localLabelPrinterName != null &&
                                        _localLabelPrinterName!.isNotEmpty
                                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _localLabelPrinterName != null &&
                                          _localLabelPrinterName!.isNotEmpty
                                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
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
                                    size: 18,
                                    color: _localLabelPrinterName != null &&
                                            _localLabelPrinterName!.isNotEmpty
                                        ? const Color(0xFF10B981)
                                        : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _localLabelPrinterName != null &&
                                                  _localLabelPrinterName!.isNotEmpty
                                              ? 'Active Label Printer: "$_localLabelPrinterName"'
                                              : 'Printer: System Print Dialog (No Direct Binding)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _localLabelPrinterName != null &&
                                                    _localLabelPrinterName!.isNotEmpty
                                                ? const Color(0xFF10B981)
                                                : (isDark
                                                    ? Colors.blue.shade300
                                                    : Colors.blue.shade800),
                                          ),
                                        ),
                                        Text(
                                          _localLabelPrinterName != null &&
                                                  _localLabelPrinterName!.isNotEmpty
                                              ? 'Labels will send directly to this device without dialog prompts.'
                                              : 'Click "Connect Printer" to bind directly to Zebra, Xprinter, Dymo, or Brother.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: _showChangeLabelPrinterDialog,
                                    icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                                    label: Text(
                                      _localLabelPrinterName != null &&
                                              _localLabelPrinterName!.isNotEmpty
                                          ? 'Change'
                                          : 'Connect Printer',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                  if (Platform.isWindows &&
                                      _localLabelPrinterName != null &&
                                      _localLabelPrinterName!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        try {
                                          Process.run('rundll32.exe', [
                                            'printui.dll,PrintUIEntry',
                                            '/e',
                                            '/n',
                                            _localLabelPrinterName!,
                                          ]);
                                        } catch (e) {
                                          debugPrint('Failed to open printer preferences: $e');
                                        }
                                      },
                                      icon: const Icon(Icons.settings_outlined, size: 16),
                                      label: const Text('Zebra Preferences', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF4F46E5),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: () async {
                                      _applyBarcodePreset('zebra_zd230_3col_22mm');
                                      _saveBarcodeSettings();
                                      final printer = _localLabelPrinterName;
                                      if (printer != null && printer.trim().isNotEmpty) {
                                        const calCmd = '! U1 setvar "media.sense_mode" "gap"\r\n'
                                            '! U1 setvar "zpl.label_length_always" "yes"\r\n'
                                            '! U1 setvar "zpl.label_length" "192"\r\n'
                                            '^XA\r\n'
                                            '^PW813\r\n'
                                            '^LL192,Y\r\n'
                                            '^MNY\r\n'
                                            '^JUS\r\n'
                                            '^XZ\r\n'
                                            '~JC\r\n';
                                        await _printBarcodeEntriesViaZpl(printer, calCmd);
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Auto-Calibrated for Zebra ZD230 3-Col (31.8x22mm)! Hardware sensor calibrated to 22mm gaps.'),
                                            backgroundColor: Color(0xFF10B981),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.tune_rounded, size: 16),
                                    label: const Text('Auto-Calibrate 3-Col (31.8x22mm)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                      foregroundColor: const Color(0xFFD97706),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: _testPrintSampleBarcodeLabel,
                                    icon: const Icon(Icons.bolt_rounded, size: 16),
                                    label: const Text('Test 1 Label', style: TextStyle(fontSize: 12)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      await _saveBarcodeSettings();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Label printer & layout settings saved successfully!'),
                                            backgroundColor: Color(0xFF10B981),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                    label: const Text('Save Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Roll Width Mismatch Warning Banner (when span of columns exceeds roll width)
                            Builder(
                              builder: (context) {
                                final totalColSpanMm = (_barcodeColumns * _barcodeLabelWidthMm) +
                                    ((_barcodeColumns - 1) * _barcodeHorizontalGapMm) +
                                    _barcodeRightShiftMm;
                                final isRollWidthTooNarrow =
                                    _barcodePrinterType == 'thermal' &&
                                        _barcodeColumns > 1 &&
                                        totalColSpanMm > _barcodePaperWidthMm;

                                if (!isRollWidthTooNarrow) return const SizedBox.shrink();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.amber.shade700, width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 26),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Roll Width Warning: $_barcodeColumns columns span ${totalColSpanMm.toStringAsFixed(1)} mm, but Roll W is ${_barcodePaperWidthMm.toStringAsFixed(1)} mm!',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'This causes the rightmost barcode to be cut off. Standard 3-column Zebra rolls are 101.6 mm (4 inches) wide.',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      FilledButton.tonalIcon(
                                        onPressed: () {
                                          setState(() {
                                            _barcodePaperWidthMm = 101.6;
                                            _barcodeRightShiftMm = 0.0;
                                          });
                                          _saveBarcodeSettings();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Auto-Fixed: Roll W set to 101.6mm & Left Shift centered to 0.0mm!'),
                                                backgroundColor: Color(0xFF10B981),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                                        label: const Text('Auto-Fix Alignment & Width', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Row 1: Presets, Columns, Symbology & Rotation
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 260,
                                    maxWidth: 360,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: [
                                      'zebra_zd230_3col_22mm',
                                      'zebra_zd230_3col',
                                      'zebra_zd230_2col',
                                      'zebra_zd230_1col',
                                      'zebra_generic_3col',
                                      'dymo_lw_standard',
                                      'dymo_lw_large',
                                      'brother_ql_29mm',
                                      'brother_ql_62mm',
                                      'generic_thermal_1col',
                                      'generic_58mm_1col',
                                      'a4_3col',
                                      'a4_2col',
                                      'a4_4col',
                                      'letter_3col',
                                      'custom',
                                    ].contains(_barcodePreset)
                                        ? _barcodePreset
                                        : 'zebra_zd230_3col_22mm',
                                    decoration: const InputDecoration(
                                      labelText: 'Printer & Label Preset',
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
                                        value: 'zebra_zd230_3col_22mm',
                                        child: Text('Zebra ZD230 - 3 Col (31.8x22mm) [Current Roll]'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'zebra_zd230_3col',
                                        child: Text('Zebra ZD230 - 3 Col (31.75x25.4mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'zebra_zd230_2col',
                                        child: Text('Zebra ZD230 - 2 Col (48x25.4mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'zebra_zd230_1col',
                                        child: Text('Zebra ZD230 - 1 Col (98x50mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'zebra_generic_3col',
                                        child: Text('Zebra Generic - 3 Col (23x25.4mm, 3" roll)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'dymo_lw_standard',
                                        child: Text('Dymo LW Standard (89x28mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'dymo_lw_large',
                                        child: Text('Dymo LW Large (89x36mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'brother_ql_29mm',
                                        child: Text('Brother QL (29x30mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'brother_ql_62mm',
                                        child: Text('Brother QL (62x30mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'generic_thermal_1col',
                                        child: Text('Thermal POS 80mm Roll (76x40mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'generic_58mm_1col',
                                        child: Text('Thermal POS 58mm Roll (50x25mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'a4_3col',
                                        child: Text('A4: 3x10 (30 Labels, 64x25mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'a4_2col',
                                        child: Text('A4: 2x7 (14 Labels, 99x38mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'a4_4col',
                                        child: Text('A4: 4x13 (52 Labels, 48x21mm)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'letter_3col',
                                        child: Text('Letter: 3x10 (30 Labels, 66x25mm)'),
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
                                    minWidth: 140,
                                    maxWidth: 170,
                                  ),
                                  child: DropdownButtonFormField<int>(
                                    isExpanded: true,
                                    value: _barcodeColumns.clamp(1, 6),
                                    decoration: const InputDecoration(
                                      labelText: 'Columns / Row',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.view_column_rounded),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: List.generate(6, (i) => i + 1)
                                        .map((n) => DropdownMenuItem(
                                            value: n,
                                            child: Text('$n col${n > 1 ? 's' : ''}')))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _barcodeColumns = val);
                                        _saveBarcodeSettings();
                                      }
                                    },
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 170,
                                    maxWidth: 220,
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
                                        _saveBarcodeSettings();
                                      }
                                    },
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 170,
                                    maxWidth: 220,
                                  ),
                                  child: DropdownButtonFormField<int>(
                                    isExpanded: true,
                                    value: [0, 90, 180, 270].contains(_barcodeRotationDegrees)
                                        ? _barcodeRotationDegrees
                                        : 0,
                                    decoration: const InputDecoration(
                                      labelText: 'Orientation / Rotation',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.screen_rotation_rounded),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 0,
                                        child: Text('Normal (0°)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 180,
                                        child: Text('Invert 180° (අනිත් පැත්තට)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 90,
                                        child: Text('Rotate 90° (Clockwise)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 270,
                                        child: Text('Rotate 270° (Counter-CW)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _barcodeRotationDegrees = val);
                                        _saveBarcodeSettings();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Row 2: Direct Input Text Boxes & Quick Sliders - Dimensions & Fine Alignment
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Dimensions & Alignment (Type exact values or adjust with +/-)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () {
                                        _applyBarcodePreset(_barcodePreset);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Reset to preset defaults!'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.restart_alt_rounded, size: 15),
                                      label: const Text('Reset Defaults', style: TextStyle(fontSize: 11)),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _buildDimensionBox(
                                      context: context,
                                      label: 'Roll W',
                                      unit: 'mm',
                                      controller: _barcodeRollWidthController,
                                      value: _barcodePaperWidthMm,
                                      defaultValue: 101.6,
                                      min: 25.0,
                                      max: 115.0,
                                      step: 1.0,
                                      onChanged: (val) {
                                        setState(() => _barcodePaperWidthMm = val);
                                        _saveBarcodeSettings();
                                      },
                                    ),
                                    _buildDimensionBox(
                                      context: context,
                                      label: 'Label W',
                                      unit: 'mm',
                                      controller: _barcodeLabelWidthController,
                                      value: _barcodeLabelWidthMm,
                                      defaultValue: 31.8,
                                      min: 15.0,
                                      max: 105.0,
                                      step: 0.5,
                                      onChanged: (val) {
                                        setState(() => _barcodeLabelWidthMm = val);
                                        _saveBarcodeSettings();
                                      },
                                    ),
                                    _buildDimensionBox(
                                      context: context,
                                      label: 'Label H',
                                      unit: 'mm',
                                      controller: _barcodeLabelHeightController,
                                      value: _barcodeLabelHeightMm,
                                      defaultValue: 22.0,
                                      min: 12.0,
                                      max: 80.0,
                                      step: 0.5,
                                      onChanged: (val) {
                                        setState(() => _barcodeLabelHeightMm = val);
                                        _saveBarcodeSettings();
                                      },
                                    ),
                                    _buildDimensionBox(
                                      context: context,
                                      label: 'Barcode H',
                                      unit: 'mm',
                                      controller: _barcodeHeightController,
                                      value: _barcodeHeightMm,
                                      defaultValue: 6.5,
                                      min: 4.0,
                                      max: 25.0,
                                      step: 0.5,
                                      highlight: true,
                                      tooltip: 'Directly adjusts the vertical height of printed barcode lines (Default: 6.5 mm)',
                                      onChanged: (val) {
                                        setState(() => _barcodeHeightMm = val);
                                        _saveBarcodeSettings();
                                      },
                                    ),
                                    _buildDimensionBox(
                                      context: context,
                                      label: 'Col Gap',
                                      unit: 'mm',
                                      controller: _barcodeColGapController,
                                      value: _barcodeHorizontalGapMm,
                                      defaultValue: 2.0,
                                      min: 0.0,
                                      max: 10.0,
                                      step: 0.5,
                                      onChanged: (val) {
                                        setState(() => _barcodeHorizontalGapMm = val);
                                        _saveBarcodeSettings();
                                      },
                                    ),
                                    _buildDimensionBox(
                                      context: context,
                                      label: 'Row Gap',
                                      unit: 'mm',
                                      controller: _barcodeRowGapController,
                                      value: _barcodeVerticalGapMm,
                                      defaultValue: 2.0,
                                      min: 0.0,
                                      max: 10.0,
                                      step: 0.5,
                                      onChanged: (val) {
                                        setState(() => _barcodeVerticalGapMm = val);
                                        _saveBarcodeSettings();
                                      },
                                    ),
                                    _buildDimensionBox(
                                      context: context,
                                      label: 'Top Shift',
                                      unit: 'mm',
                                      controller: _barcodeTopShiftController,
                                      value: _barcodeTopShiftMm,
                                      defaultValue: 12.0,
                                      min: 0.0,
                                      max: 25.0,
                                      step: 0.5,
                                      tooltip: 'Physical sticker top shift (mm). Default 12.0 mm for Zebra 3-Col.',
                                      onChanged: (val) {
                                        setState(() => _barcodeTopShiftMm = val);
                                        _saveBarcodeSettings();
                                      },
                                    ),
                                    _buildDimensionBox(
                                      context: context,
                                      label: 'Left Shift',
                                      unit: 'mm',
                                      controller: _barcodeLeftShiftController,
                                      value: _barcodeRightShiftMm,
                                      defaultValue: 0.0,
                                      min: 0.0,
                                      max: 20.0,
                                      step: 0.5,
                                      onChanged: (val) {
                                        setState(() => _barcodeRightShiftMm = val);
                                        _saveBarcodeSettings();
                                      },
                                    ),
                                    _buildDimensionBox(
                                      context: context,
                                      label: 'Scale',
                                      unit: 'x',
                                      controller: _barcodeScaleController,
                                      value: _barcodeFontScale,
                                      defaultValue: 0.85,
                                      min: 0.6,
                                      max: 1.5,
                                      step: 0.05,
                                      onChanged: (val) {
                                        setState(() => _barcodeFontScale = val);
                                        _saveBarcodeSettings();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Row 3: Toggles & Display Options
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
                                  onSelected: (val) {
                                    setState(
                                      () => _barcodePrintIndividualImei = val,
                                    );
                                    _saveBarcodeSettings();
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Show Store Name'),
                                  selected: _barcodeShowStoreName,
                                  onSelected: (value) {
                                    setState(() => _barcodeShowStoreName = value);
                                    _saveBarcodeSettings();
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Show Name'),
                                  selected: _barcodeShowName,
                                  onSelected: (value) {
                                    setState(() => _barcodeShowName = value);
                                    _saveBarcodeSettings();
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Show Price'),
                                  selected: _barcodeShowPrice,
                                  onSelected: (value) {
                                    setState(() => _barcodeShowPrice = value);
                                    _saveBarcodeSettings();
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Show SKU'),
                                  selected: _barcodeShowSku,
                                  onSelected: (value) {
                                    setState(() => _barcodeShowSku = value);
                                    _saveBarcodeSettings();
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Show Barcode Text'),
                                  selected: _barcodeShowCodeText,
                                  onSelected: (value) {
                                    setState(
                                      () => _barcodeShowCodeText = value,
                                    );
                                    _saveBarcodeSettings();
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Show Category'),
                                  selected: _barcodeShowCategory,
                                  onSelected: (value) {
                                    setState(
                                      () => _barcodeShowCategory = value,
                                    );
                                    _saveBarcodeSettings();
                                  },
                                ),
                                ActionChip(
                                  avatar: Icon(
                                    _barcodeRotationDegrees == 180
                                        ? Icons.check_circle_rounded
                                        : Icons.flip_camera_android_rounded,
                                    size: 16,
                                    color: _barcodeRotationDegrees == 180
                                        ? Colors.white
                                        : const Color(0xFF6366F1),
                                  ),
                                  label: Text(
                                    _barcodeRotationDegrees == 180
                                        ? 'Inverted 180° (Flip Active)'
                                        : 'Flip 180° (අනිත් පැත්තට)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _barcodeRotationDegrees == 180
                                          ? Colors.white
                                          : null,
                                    ),
                                  ),
                                  backgroundColor: _barcodeRotationDegrees == 180
                                      ? const Color(0xFF6366F1)
                                      : null,
                                  onPressed: () {
                                    setState(() {
                                      _barcodeRotationDegrees =
                                          _barcodeRotationDegrees == 180 ? 0 : 180;
                                    });
                                    _saveBarcodeSettings();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _barcodeRotationDegrees == 180
                                                ? 'Label orientation set to Inverted 180°'
                                                : 'Label orientation set to Normal 0°',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Live Sticker & Roll Calibration Preview Card
                            Builder(
                              builder: (context) {
                                final isCompactPreview = _barcodeLabelHeightMm <= 26.0;
                                final estStoreH = (_barcodeShowStoreName && _companyName.trim().isNotEmpty) ? 2.5 : 0.0;
                                final estNameH = _barcodeShowName ? (isCompactPreview ? 2.5 : 5.0) : 0.0;
                                final estPriceH = _barcodeShowPrice ? 2.8 : 0.0;
                                final estBarcodeH = _barcodeHeightMm;
                                final estCodeTextH = _barcodeShowCodeText ? 2.0 : 0.0;
                                final estSkuH = _barcodeShowSku ? 1.8 : 0.0;
                                final estCategoryH = _barcodeShowCategory ? 1.8 : 0.0;
                                final estSpacingH = isCompactPreview ? 1.6 : 3.2;
                                final estTotalContentH = estStoreH + estNameH + estPriceH + estBarcodeH + estCodeTextH + estSkuH + estCategoryH + estSpacingH;
                                final fitsStickerHeight = estTotalContentH <= (_barcodeLabelHeightMm + 1.0);

                                final previewTotalSpan = (_barcodeColumns * _barcodeLabelWidthMm) +
                                    ((_barcodeColumns - 1) * _barcodeHorizontalGapMm) +
                                    _barcodeRightShiftMm;
                                final fitsRollWidth = _barcodeColumns <= 1 || (previewTotalSpan <= _barcodePaperWidthMm);

                                final previewProd = visibleProducts.isNotEmpty
                                    ? visibleProducts.first
                                    : (_products.isNotEmpty
                                        ? _products.first
                                        : _ProductItem(
                                            id: 'P18126',
                                            name: 'test',
                                            category: 'Retail',
                                            barcode: 'SB1428818126',
                                            price: 10.0,
                                            stock: 10,
                                            minStock: 2,
                                          ));

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E2232) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.remove_red_eye_rounded, size: 16, color: Color(0xFF6366F1)),
                                              SizedBox(width: 6),
                                              Text(
                                                'Live Calibration Preview',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Sticker Height Fit Indicator
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: fitsStickerHeight
                                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                                  : Colors.amber.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: fitsStickerHeight
                                                    ? const Color(0xFF10B981)
                                                    : Colors.amber.shade700,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  fitsStickerHeight
                                                      ? Icons.check_circle_rounded
                                                      : Icons.warning_amber_rounded,
                                                  size: 13,
                                                  color: fitsStickerHeight
                                                      ? const Color(0xFF10B981)
                                                      : Colors.amber.shade800,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  fitsStickerHeight
                                                      ? 'Sticker Height: Fits (${estTotalContentH.toStringAsFixed(1)}mm ≤ ${_barcodeLabelHeightMm.toStringAsFixed(1)}mm)'
                                                      : 'Overflows: ${estTotalContentH.toStringAsFixed(1)}mm > ${_barcodeLabelHeightMm.toStringAsFixed(1)}mm (Set Top Shift to 0mm or reduce Barcode H)',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: fitsStickerHeight
                                                        ? const Color(0xFF10B981)
                                                        : Colors.amber.shade900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Roll Width Fit Indicator
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: fitsRollWidth
                                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                                  : Colors.red.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: fitsRollWidth
                                                    ? const Color(0xFF10B981)
                                                    : Colors.red.shade400,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  fitsRollWidth
                                                      ? Icons.check_circle_rounded
                                                      : Icons.cancel_rounded,
                                                  size: 13,
                                                  color: fitsRollWidth
                                                      ? const Color(0xFF10B981)
                                                      : Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  fitsRollWidth
                                                      ? 'Roll Width: Fits ${previewTotalSpan.toStringAsFixed(1)}mm ≤ ${_barcodePaperWidthMm.toStringAsFixed(1)}mm'
                                                      : 'Right Edge Clipped: ${previewTotalSpan.toStringAsFixed(1)}mm > ${_barcodePaperWidthMm.toStringAsFixed(1)}mm',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: fitsRollWidth
                                                        ? const Color(0xFF10B981)
                                                        : Colors.red.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Visual Previews (Single Sticker Box + 3-Column Roll Strip)
                                      Wrap(
                                        spacing: 20,
                                        runSpacing: 12,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          // 1. Single Sticker Preview
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: (_barcodeLabelWidthMm * 3.4).clamp(90.0, 260.0),
                                                height: (_barcodeLabelHeightMm * 3.4).clamp(65.0, 160.0),
                                                padding: EdgeInsets.only(
                                                  left: 4,
                                                  right: 4,
                                                  top: (3.0 + (_barcodeTopShiftMm * 3.0)).clamp(3.0, 25.0),
                                                  bottom: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: Colors.grey.shade400, width: 1),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.08),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRect(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      if (_barcodeShowStoreName && _companyName.trim().isNotEmpty)
                                                        Text(
                                                          _companyName.trim(),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: (8 * _barcodeFontScale).clamp(6.0, 11.0),
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.grey.shade800,
                                                          ),
                                                        ),
                                                      if (_barcodeShowName)
                                                        Text(
                                                          previewProd.name,
                                                          maxLines: isCompactPreview ? 1 : 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: (9 * _barcodeFontScale).clamp(7.0, 12.0),
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      if (_barcodeShowPrice)
                                                        Text(
                                                          _money(previewProd.price),
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            fontSize: (9.5 * _barcodeFontScale).clamp(7.5, 13.0),
                                                            fontWeight: FontWeight.bold,
                                                            color: const Color(0xFF047857),
                                                          ),
                                                        ),
                                                      const SizedBox(height: 1),
                                                      // Simulated Barcode visual with height matching slider
                                                      Container(
                                                        height: (_barcodeHeightMm * 3.2).clamp(12.0, 75.0),
                                                        width: double.infinity,
                                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                                        alignment: Alignment.center,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: List.generate(
                                                            28,
                                                            (idx) => Container(
                                                              width: (idx % 3 == 0 || idx % 7 == 0) ? 2.2 : 1.2,
                                                              height: double.infinity,
                                                              margin: const EdgeInsets.symmetric(horizontal: 0.8),
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 1),
                                                      if (_barcodeShowCodeText)
                                                        Text(
                                                          previewProd.barcode.isNotEmpty ? previewProd.barcode : 'SB1428818126',
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            fontSize: (7.5 * _barcodeFontScale).clamp(6.0, 10.0),
                                                            letterSpacing: 0.5,
                                                            fontFamily: 'monospace',
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      if (_barcodeShowSku)
                                                        Text(
                                                          'SKU: ${previewProd.id}',
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            fontSize: (7.0 * _barcodeFontScale).clamp(5.5, 9.5),
                                                            color: Colors.grey.shade800,
                                                          ),
                                                        ),
                                                      if (_barcodeShowCategory)
                                                        Text(
                                                          previewProd.category,
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            fontSize: (6.5 * _barcodeFontScale).clamp(5.0, 9.0),
                                                            color: Colors.grey.shade700,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '1 Label: ${_barcodeLabelWidthMm.toStringAsFixed(1)} x ${_barcodeLabelHeightMm.toStringAsFixed(1)} mm (Barcode: ${_barcodeHeightMm.toStringAsFixed(1)} mm)',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // 2. Roll Strip Preview across Columns
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height: ((_barcodeLabelHeightMm + _barcodeVerticalGapMm) * 2.2).clamp(48.0, 95.0),
                                                width: (_barcodePaperWidthMm * 2.2).clamp(120.0, 320.0),
                                                padding: EdgeInsets.only(
                                                  left: (_barcodeRightShiftMm * 2.2).clamp(0.0, 30.0),
                                                  top: (_barcodeTopShiftMm > 0 ? _barcodeTopShiftMm * 1.5 : 0.0),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF2C3246) : const Color(0xFFE2E8F0),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: fitsRollWidth ? Colors.grey.shade500 : Colors.red,
                                                    width: fitsRollWidth ? 1.0 : 1.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    for (int c = 0; c < _barcodeColumns; c++) ...[
                                                      if (c > 0)
                                                        SizedBox(width: (_barcodeHorizontalGapMm * 2.2).clamp(0.0, 20.0)),
                                                      Container(
                                                        width: (_barcodeLabelWidthMm * 2.2).clamp(25.0, 80.0),
                                                        height: (_barcodeLabelHeightMm * 2.0).clamp(25.0, 75.0),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(3),
                                                          border: Border.all(color: Colors.grey.shade400, width: 0.8),
                                                        ),
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Text(
                                                              'Col ${c + 1}',
                                                              style: const TextStyle(
                                                                fontSize: 8,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                            Icon(
                                                              Icons.qr_code_rounded,
                                                              size: 12,
                                                              color: Colors.grey.shade700,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Roll Strip: ${_barcodePaperWidthMm.toStringAsFixed(1)} mm Roll | Total Span: ${previewTotalSpan.toStringAsFixed(1)} mm',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
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

  Future<void> _showChangeLabelPrinterDialog() async {
    List<Printer> discovered = [];
    bool isScanning = true;
    try {
      discovered = await Printing.listPrinters();
      isScanning = false;
    } catch (_) {
      isScanning = false;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.print_rounded, color: Color(0xFF6366F1)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Select Label / Barcode Printer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.desktop_windows_outlined),
                    title: const Text('System Print Dialog (Default)'),
                    subtitle: const Text('Opens the Windows standard print preview dialog'),
                    trailing: _localLabelPrinterName == null || _localLabelPrinterName!.isEmpty
                        ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                        : null,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('local_printer_label_name');
                      setState(() => _localLabelPrinterName = null);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  const Divider(),
                  if (isScanning)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )
                  else if (discovered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No printers discovered on this device. Ensure your USB/Network label printer is powered on and installed in Windows Settings.',
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: discovered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = discovered[index];
                          final isSelected = _localLabelPrinterName != null &&
                              _localLabelPrinterName!.toLowerCase() == p.name.toLowerCase();
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.qr_code_2_rounded,
                              color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(p.isDefault ? 'System Default Printer' : 'Connected Device'),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                                : null,
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('local_printer_label_name', p.name);
                              setState(() => _localLabelPrinterName = p.name);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Connected to label printer: ${p.name}'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
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
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDimensionBox({
    required BuildContext context,
    required String label,
    required String unit,
    required TextEditingController controller,
    required double value,
    required double defaultValue,
    required double min,
    required double max,
    required double step,
    required ValueChanged<double> onChanged,
    String? tooltip,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? (isDark
                ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                : const Color(0xFF6366F1).withValues(alpha: 0.06))
            : (isDark ? const Color(0xFF1E2235) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? const Color(0xFF6366F1).withValues(alpha: 0.5)
              : (isDark ? Colors.white12 : Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: highlight
                        ? const Color(0xFF6366F1)
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 2),
                Tooltip(
                  message: tooltip,
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          // Direct typeable Text Box with Default Hint
          SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffixText: unit,
                suffixStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                hintText: defaultValue.toStringAsFixed(unit == 'x' ? 2 : 1),
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
              ),
              onChanged: (text) {
                final parsed = double.tryParse(text.trim());
                if (parsed != null && parsed >= 0) {
                  final clamped = parsed.clamp(min, max);
                  onChanged(clamped);
                }
              },
            ),
          ),
          const SizedBox(height: 5),
          // Quick Steppers (- / mini slider / +)
          Row(
            children: [
              InkWell(
                onTap: () {
                  final next = ((value - step) * 100).round() / 100;
                  final clamped = next.clamp(min, max);
                  controller.text =
                      clamped.toStringAsFixed(unit == 'x' ? 2 : 1);
                  onChanged(clamped);
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.remove, size: 12),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                    trackHeight: 2.5,
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 8),
                  ),
                  child: Slider(
                    min: min,
                    max: max,
                    value: value.clamp(min, max),
                    activeColor: highlight ? const Color(0xFF6366F1) : null,
                    onChanged: (v) {
                      final rounded = unit == 'x'
                          ? (v * 100).round() / 100
                          : (v * 10).round() / 10;
                      controller.text =
                          rounded.toStringAsFixed(unit == 'x' ? 2 : 1);
                      onChanged(rounded);
                    },
                    onChangeEnd: (_) => _saveBarcodeSettings(),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  final next = ((value + step) * 100).round() / 100;
                  final clamped = next.clamp(min, max);
                  controller.text =
                      clamped.toStringAsFixed(unit == 'x' ? 2 : 1);
                  onChanged(clamped);
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
