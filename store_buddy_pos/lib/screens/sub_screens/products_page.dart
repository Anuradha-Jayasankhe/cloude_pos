part of '../dashboard_screen.dart';

extension _products_pageExt on _DashboardScreenState {
  Widget _buildProductsPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final q = _productSearchController.text.trim().toLowerCase();
    final filtered = _scopedProducts.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q);
    }).toList();

    List<_ProductItem> displayedProducts;
    if (_selectedLocationScope == _DashboardScreenState._allLocationsLabel &&
        _combineProductsStockAllLocations) {
      final groupedMap = <String, _ProductItem>{};
      for (final p in filtered) {
        final key = p.barcode.trim().isNotEmpty
            ? 'barcode:${p.barcode.trim().toLowerCase()}_price:${p.price.toStringAsFixed(2)}'
            : 'name:${p.name.trim().toLowerCase()}_price:${p.price.toStringAsFixed(2)}';

        if (groupedMap.containsKey(key)) {
          final existing = groupedMap[key]!;
          existing.stock += p.stock;
        } else {
          groupedMap[key] = _ProductItem(
            id: p.id,
            name: p.name,
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
            locationId: p.locationId,
            imageUrl: p.imageUrl,
          );
        }
      }
      displayedProducts = groupedMap.values.toList();
    } else {
      displayedProducts = filtered;
    }

    final expiringSoon = _expiringProductsSoon();

    Widget productActionButton({
      required String tooltip,
      required VoidCallback? onPressed,
      required IconData icon,
      Color? color,
    }) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    : (color ??
                          (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569))),
              ),
            ),
          ),
        ),
      );
    }

    const stockReasonOptions = [
      'Damaged',
      'Expired',
      'Removed',
      'Returned to Supplier',
      'Missing / Lost',
      'Manual Count Correction',
      'Other',
    ];

    ({String condition, String status}) damagedMetaForReason(String reason) {
      final normalized = reason.trim().toLowerCase();
      if (normalized.contains('expired')) {
        return (condition: 'Expired', status: 'SCRAPPED');
      }
      if (normalized.contains('return')) {
        return (condition: 'Returned', status: 'RETURNED_TO_SUPPLIER');
      }
      if (normalized.contains('remove') ||
          normalized.contains('lost') ||
          normalized.contains('missing')) {
        return (condition: 'Removed', status: 'SCRAPPED');
      }
      if (normalized.contains('damage')) {
        return (condition: 'Damaged', status: 'QUARANTINE');
      }
      return (condition: reason, status: 'QUARANTINE');
    }

    bool shouldCreateDamagedRecord(String reason) {
      final normalized = reason.trim().toLowerCase();
      return normalized.contains('damaged') ||
          normalized.contains('expired') ||
          normalized.contains('removed') ||
          normalized.contains('lost') ||
          normalized.contains('missing') ||
          normalized.contains('returned');
    }

    Future<
      ({
        int delta,
        double costPrice,
        String reason,
        String? damagedCondition,
        String? damagedStatus,
      })?
    >
    askStockDelta(_ProductItem product) async {
      final qtyController = TextEditingController(text: '1');
      final costController = TextEditingController(
        text: (product.costPrice ?? product.price).toStringAsFixed(2),
      );
      final customReasonController = TextEditingController();
      String movementType = 'Increase';
      String selectedReason = 'Manual Count Correction';
      final result =
          await showDialog<
            ({
              int delta,
              double costPrice,
              String reason,
              String? damagedCondition,
              String? damagedStatus,
            })
          >(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Adjust Stock  -  ${product.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: movementType,
                      items: const [
                        DropdownMenuItem(
                          value: 'Increase',
                          child: Text('Increase'),
                        ),
                        DropdownMenuItem(
                          value: 'Decrease',
                          child: Text('Decrease'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        movementType = value;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Action',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      items: stockReasonOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        selectedReason = value;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (selectedReason == 'Other')
                      TextField(
                        controller: customReasonController,
                        decoration: const InputDecoration(
                          labelText: 'Custom reason',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (selectedReason == 'Other') const SizedBox(height: 10),
                    TextField(
                      controller: costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Current cost price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final parsedQty = int.tryParse(qtyController.text.trim());
                    final parsedCost = double.tryParse(
                      costController.text.trim(),
                    );
                    if (parsedQty == null || parsedQty <= 0) {
                      return;
                    }
                    if (parsedCost == null || parsedCost < 0) {
                      return;
                    }
                    final reasonText = selectedReason == 'Other'
                        ? customReasonController.text.trim()
                        : selectedReason;
                    if (reasonText.isEmpty) {
                      return;
                    }
                    final signedDelta = movementType == 'Decrease'
                        ? -parsedQty
                        : parsedQty;
                    final damagedMeta =
                        movementType == 'Decrease' &&
                            shouldCreateDamagedRecord(reasonText)
                        ? damagedMetaForReason(reasonText)
                        : null;
                    Navigator.pop(context, (
                      delta: signedDelta,
                      costPrice: parsedCost,
                      reason: reasonText,
                      damagedCondition: damagedMeta?.condition,
                      damagedStatus: damagedMeta?.status,
                    ));
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          );
      qtyController.dispose();
      costController.dispose();
      customReasonController.dispose();
      return result;
    }

    Future<void> showStockHistory(_ProductItem? product) async {
      String selectedPeriod = 'All Time';
      String selectedReason = 'All Reasons';
      String selectedUser = 'All Users';

      String classifyReason(_StockAdjustmentItem entry) {
        final reason = entry.reason.trim().toLowerCase();
        if (reason.startsWith('sale ')) return 'Sale';
        if (reason.contains('po received') || reason.contains('purchase'))
          return 'Purchase';
        if (reason.contains('increase')) return 'Increase';
        if (reason.contains('decrease')) return 'Decrease';
        if (reason.contains('damaged')) return 'Damaged';
        if (reason.contains('expired')) return 'Expired';
        if (reason.contains('returned')) return 'Returned';
        if (reason.contains('removed') ||
            reason.contains('missing') ||
            reason.contains('lost')) {
          return 'Removed';
        }
        if (reason.contains('manual')) return 'Manual';
        return 'Other';
      }

      bool inPeriod(DateTime ts, String period) {
        final now = DateTime.now();
        final day = DateTime(ts.year, ts.month, ts.day);
        final today = DateTime(now.year, now.month, now.day);
        switch (period) {
          case 'Today':
            return day == today;
          case 'This Week':
            final start = today.subtract(Duration(days: today.weekday - 1));
            return !day.isBefore(start);
          case 'This Month':
            return ts.year == now.year && ts.month == now.month;
          case 'All Time':
          default:
            return true;
        }
      }

      String buildCsv(List<_StockAdjustmentItem> rows) {
        String esc(String value) {
          final safe = value.replaceAll('"', '""');
          return '"$safe"';
        }

        final buffer = StringBuffer();
        buffer.writeln(
          'Date,Product,Change,Before,After,Reason,Performed By,Product ID',
        );
        for (final row in rows) {
          final dateValue =
              '${row.createdAt.year}-${row.createdAt.month.toString().padLeft(2, '0')}-${row.createdAt.day.toString().padLeft(2, '0')} ${row.createdAt.hour.toString().padLeft(2, '0')}:${row.createdAt.minute.toString().padLeft(2, '0')}';
          buffer.writeln(
            '${esc(dateValue)},${esc(row.productName)},${esc(row.delta > 0 ? '+${row.delta}' : '${row.delta}')},${row.beforeStock},${row.afterStock},${esc(row.reason)},${esc(row.performedBy.isEmpty ? 'System' : row.performedBy)},${esc(row.productId)}',
          );
        }
        return buffer.toString();
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setLocal) {
              final baseRows =
                  _stockAdjustments
                      .where(
                        (entry) =>
                            product == null || entry.productId == product.id,
                      )
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              final userOptions = {
                'All Users',
                ...baseRows.map(
                  (entry) => entry.performedBy.trim().isEmpty
                      ? 'System'
                      : entry.performedBy.trim(),
                ),
              }.toList();

              if (!userOptions.contains(selectedUser)) {
                selectedUser = 'All Users';
              }

              final filteredRows = baseRows.where((entry) {
                if (!inPeriod(entry.createdAt, selectedPeriod)) return false;
                if (selectedReason != 'All Reasons' &&
                    classifyReason(entry) != selectedReason) {
                  return false;
                }

                final userLabel = entry.performedBy.trim().isEmpty
                    ? 'System'
                    : entry.performedBy.trim();
                if (selectedUser != 'All Users' && userLabel != selectedUser) {
                  return false;
                }
                return true;
              }).toList();

              final screenSize = MediaQuery.of(context).size;
              final isNarrow = screenSize.width < 700;
              final dialogWidth = isNarrow ? screenSize.width * 0.94 : 900.0;
              final dialogMaxHeight = screenSize.height * 0.88;

              Widget periodDropdown() => DropdownButtonFormField<String>(
                initialValue: selectedPeriod,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                  DropdownMenuItem(value: 'Today', child: Text('Today')),
                  DropdownMenuItem(
                    value: 'This Week',
                    child: Text('This Week'),
                  ),
                  DropdownMenuItem(
                    value: 'This Month',
                    child: Text('This Month'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setLocal(() => selectedPeriod = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Period',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(),
                ),
              );

              Widget reasonDropdown() => DropdownButtonFormField<String>(
                initialValue: selectedReason,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'All Reasons',
                    child: Text('All Reasons'),
                  ),
                  DropdownMenuItem(value: 'Increase', child: Text('Increase')),
                  DropdownMenuItem(value: 'Decrease', child: Text('Decrease')),
                  DropdownMenuItem(value: 'Damaged', child: Text('Damaged')),
                  DropdownMenuItem(value: 'Expired', child: Text('Expired')),
                  DropdownMenuItem(value: 'Removed', child: Text('Removed')),
                  DropdownMenuItem(value: 'Returned', child: Text('Returned')),
                  DropdownMenuItem(value: 'Manual', child: Text('Manual')),
                  DropdownMenuItem(value: 'Sale', child: Text('Sale')),
                  DropdownMenuItem(value: 'Purchase', child: Text('Purchase')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setLocal(() => selectedReason = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(),
                ),
              );

              Widget userDropdown() => DropdownButtonFormField<String>(
                initialValue: selectedUser,
                isExpanded: true,
                items: userOptions
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setLocal(() => selectedUser = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Performed By',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(),
                ),
              );

              Widget filtersSection = isNarrow
                  ? Column(
                      children: [
                        periodDropdown(),
                        const SizedBox(height: 10),
                        reasonDropdown(),
                        const SizedBox(height: 10),
                        userDropdown(),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: periodDropdown()),
                        const SizedBox(width: 8),
                        Expanded(child: reasonDropdown()),
                        const SizedBox(width: 8),
                        Expanded(child: userDropdown()),
                      ],
                    );

              Widget entryStatusChip(_StockAdjustmentItem entry) {
                final positive = entry.delta > 0;
                final color = positive
                    ? const Color(0xFF179C52)
                    : const Color(0xFFD32F2F);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    positive ? '+${entry.delta}' : '${entry.delta}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              Widget listSection = filteredRows.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Text('No stock adjustments found.'),
                      ),
                    )
                  : isNarrow
                  ? ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = filteredRows[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE4E7EF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  entryStatusChip(entry),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(entry.createdAt)} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6D7383),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${entry.beforeStock} -> ${entry.afterStock}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.reason,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'By: ${entry.performedBy.isEmpty ? 'System' : entry.performedBy}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6D7383),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('DATE')),
                          DataColumn(label: Text('PRODUCT')),
                          DataColumn(label: Text('CHANGE')),
                          DataColumn(label: Text('BEFORE -> AFTER')),
                          DataColumn(label: Text('REASON')),
                          DataColumn(label: Text('BY')),
                        ],
                        rows: filteredRows
                            .map(
                              (entry) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '${_formatDate(entry.createdAt)} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                  DataCell(Text(entry.productName)),
                                  DataCell(entryStatusChip(entry)),
                                  DataCell(
                                    Text(
                                      '${entry.beforeStock} -> ${entry.afterStock}',
                                    ),
                                  ),
                                  DataCell(Text(entry.reason)),
                                  DataCell(
                                    Text(
                                      entry.performedBy.isEmpty
                                          ? 'System'
                                          : entry.performedBy,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    );

              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: dialogWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: dialogMaxHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Header ──────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.brandIndigo
                                    .withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.history_rounded,
                                  color: AppTheme.brandIndigo,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  product == null
                                      ? 'Stock Adjustment History'
                                      : 'Stock History  -  ${product.name}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                        // ── Filters + list (scrollable) ──────────────────
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                filtersSection,
                                const SizedBox(height: 14),
                                listSection,
                              ],
                            ),
                          ),
                        ),
                        // ── Footer actions ───────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                          child: isNarrow
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Close'),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: filteredRows.isEmpty
                                          ? null
                                          : () async {
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text: buildCsv(filteredRows),
                                                ),
                                              );
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Stock history CSV copied.',
                                                  ),
                                                ),
                                              );
                                            },
                                      icon: const Icon(
                                        Icons.download_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Export CSV'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: filteredRows.isEmpty
                                          ? null
                                          : () async {
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text: buildCsv(filteredRows),
                                                ),
                                              );
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Stock history CSV copied.',
                                                  ),
                                                ),
                                              );
                                            },
                                      icon: const Icon(Icons.download_outlined),
                                      label: const Text('Export CSV'),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    Future<void> applyStockDelta(
      _ProductItem product,
      int delta, {
      double? currentCostPrice,
      required String reason,
      String? damagedCondition,
      String? damagedStatus,
    }) async {
      if (delta == 0) return;
      final before = product.stock;
      final after = (product.stock + delta).clamp(0.0, 1000000000.0);
      final appliedDelta = after - before;
      if (appliedDelta == 0) return;
      final effectiveCostPrice = currentCostPrice ?? product.costPrice;
      final createdAt = DateTime.now();
      final auditReason = delta > 0
          ? 'Increase - $reason'
          : 'Decrease - $reason';

      final audit = _StockAdjustmentItem(
        id: 'SA${createdAt.microsecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        delta: appliedDelta,
        beforeStock: before,
        afterStock: after,
        reason: auditReason,
        performedBy: _currentUserName,
        unitCost: effectiveCostPrice,
        adjustedStockValue: effectiveCostPrice == null
            ? null
            : after * effectiveCostPrice,
        createdAt: createdAt,
      );

      setState(() {
        product.stock = after;
        if (currentCostPrice != null) {
          product.costPrice = currentCostPrice;
        }
        _stockAdjustments.insert(0, audit);
        if (delta < 0 &&
            damagedCondition != null &&
            damagedCondition.trim().isNotEmpty) {
          _damagedInventory.insert(
            0,
            _DamagedInventoryItem(
              id: 'DMG${createdAt.microsecondsSinceEpoch}',
              productId: product.id,
              productName: product.name,
              qty: appliedDelta.abs(),
              reason: reason,
              condition: damagedCondition,
              returnId: audit.id,
              status: damagedStatus ?? 'QUARANTINE',
              createdAt: createdAt.toIso8601String(),
            ),
          );
        }
      });
      await _persistWorkspaceData();

      if (_productRepository != null) {
        await _productRepository!.updateProduct(_toDomainProduct(product));
        await _refreshPendingSyncQueue();
        await _triggerImmediateSync(
          action: 'UPDATE',
          module: 'inventory',
          reference: product.id,
        );
      } else {
        await _enqueueSync('UPDATE', 'inventory', product.id);
      }
      await _enqueueSync('INSERT', 'stock_adjustments', audit.id);
      if (delta < 0 &&
          damagedCondition != null &&
          damagedCondition.trim().isNotEmpty) {
        await _enqueueSync(
          'INSERT',
          'damaged_inventory',
          'DMG${createdAt.microsecondsSinceEpoch}',
        );
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(UiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                        'Products',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your inventory and product catalog.',
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
          if (expiringSoon.isNotEmpty) ...[
            const SizedBox(height: UiSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(UiSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.brandAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(UiRadius.md),
                border: Border.all(
                  color: AppTheme.brandAmber.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.brandAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Expiry reminders active for ${expiringSoon.length} product(s): ${expiringSoon.take(3).map((product) => product.name).join(', ')}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: UiSpacing.md),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(UiRadius.md),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2D45)
                    : const Color(0xFFE8EAFF),
              ),
              boxShadow: UiShadows.card,
            ),
            child: TextField(
              controller: _productSearchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText:
                    'Search products by name, category, SKU or barcode...',
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
          const SizedBox(height: UiSpacing.sm),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(UiRadius.lg),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E2D45)
                      : const Color(0xFFE8EAFF),
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
                      Wrap(
                        spacing: UiSpacing.xs,
                        runSpacing: UiSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Products (${displayedProducts.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_selectedLocationScope ==
                              _DashboardScreenState._allLocationsLabel) ...[
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _combineProductsStockAllLocations,
                                  onChanged: (val) {
                                    setState(() {
                                      _combineProductsStockAllLocations =
                                          val ?? false;
                                    });
                                  },
                                ),
                                const Text(
                                  'Group by Product',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => showStockHistory(null),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1E2D45)
                                    : const Color(0xFFE8EAFF),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  UiRadius.md,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.history, size: 16),
                            label: const Text(
                              'Stock History',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _canManageCatalog
                                ? () => setState(
                                    () => _selectedNavKey = 'categories',
                                  )
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1E2D45)
                                    : const Color(0xFFE8EAFF),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  UiRadius.md,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.category_outlined, size: 16),
                            label: const Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: _canManageCatalog
                                ? () async {
                                    final result = await _showProductDialog();
                                    if (result == null || !mounted) return;
                                    await Future.delayed(
                                      const Duration(milliseconds: 300),
                                    );
                                    if (!mounted) return;
                                    await _handleProductCreation(result);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandIndigo,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  UiRadius.md,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              'Add Product',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UiSpacing.sm),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compactTable = constraints.maxWidth < 1200;
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
                                      dividerColor: isDark
                                          ? const Color(0xFF1E2D45)
                                          : const Color(0xFFE8EAFF),
                                    ),
                                    child: DataTable(
                                      dataRowMinHeight: 68,
                                      dataRowMaxHeight: 88,
                                      horizontalMargin: compactTable
                                          ? UiSpacing.xs
                                          : UiSpacing.sm,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark
                                            ? const Color(
                                                0xFFF1F5F9,
                                              ).withValues(alpha: 0.05)
                                            : const Color(0xFFF1F5F9),
                                      ),
                                      columnSpacing: compactTable ? 12 : 20,
                                      columns: const [
                                        DataColumn(label: Text('PRODUCT')),
                                        DataColumn(label: Text('SKU')),
                                        DataColumn(label: Text('TYPE')),
                                        DataColumn(label: Text('CATEGORY')),
                                        DataColumn(label: Text('SUPPLIER')),
                                        DataColumn(label: Text('PRICE')),
                                        DataColumn(label: Text('STOCK')),
                                        DataColumn(label: Text('MIN')),
                                        DataColumn(label: Text('EXPIRY')),
                                        DataColumn(label: Text('ACTIONS')),
                                      ],
                                      rows: displayedProducts.map((p) {
                                        String supplierLabel = 'Unlinked';
                                        if (p.supplierId.isNotEmpty) {
                                          try {
                                            final supplier = _suppliers
                                                .firstWhere(
                                                  (s) => s.id == p.supplierId,
                                                );
                                            final name =
                                                supplier.name.isNotEmpty
                                                ? supplier.name
                                                : supplier.companyName;
                                            supplierLabel =
                                                supplier.contact
                                                    .trim()
                                                    .isNotEmpty
                                                ? '$name - ${supplier.contact}'
                                                : name;
                                          } catch (_) {
                                            supplierLabel = 'Unknown';
                                          }
                                        }
                                        final hasImg = p.imageUrl != null &&
                                            p.imageUrl!.trim().isNotEmpty &&
                                            File(p.imageUrl!).existsSync();
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 6,
                                                    ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 38,
                                                      height: 38,
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? const Color(0xFF1F2937)
                                                            : const Color(0xFFF1F5F9),
                                                        borderRadius:
                                                            BorderRadius.circular(8),
                                                        border: Border.all(
                                                          color: isDark
                                                              ? const Color(0xFF374151)
                                                              : const Color(0xFFE2E8F0),
                                                        ),
                                                      ),
                                                      child: hasImg
                                                          ? ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(7),
                                                              child: Image.file(
                                                                File(p.imageUrl!),
                                                                width: 38,
                                                                height: 38,
                                                                fit: BoxFit.cover,
                                                                errorBuilder: (_, __, ___) =>
                                                                    Center(
                                                                  child: Text(
                                                                    p.name.isNotEmpty
                                                                        ? p.name[0].toUpperCase()
                                                                        : 'P',
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                      color: isDark
                                                                          ? Colors.white70
                                                                          : AppTheme.brandIndigo,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          : Center(
                                                              child: Text(
                                                                p.name.isNotEmpty
                                                                    ? p.name[0].toUpperCase()
                                                                    : 'P',
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  color: isDark
                                                                      ? Colors.white70
                                                                      : AppTheme.brandIndigo,
                                                                ),
                                                              ),
                                                            ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          p.name,
                                                          style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                    if (p
                                                        .barcode
                                                        .isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        p.barcode,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                          fontFamily:
                                                              'monospace',
                                                        ),
                                                      ),
                                                    ],
                                                    if (_selectedLocationScope ==
                                                        _DashboardScreenState
                                                            ._allLocationsLabel) ...[
                                                      const SizedBox(height: 2),
                                                      if (_combineProductsStockAllLocations)
                                                        Builder(
                                                          builder: (context) {
                                                            final matchingItems = filtered.where((
                                                              x,
                                                            ) {
                                                              final matchBarcode =
                                                                  p.barcode
                                                                      .trim()
                                                                      .isNotEmpty &&
                                                                  x.barcode
                                                                          .trim()
                                                                          .toLowerCase() ==
                                                                      p.barcode
                                                                          .trim()
                                                                          .toLowerCase();
                                                              final matchName =
                                                                  x.name
                                                                      .trim()
                                                                      .toLowerCase() ==
                                                                  p.name
                                                                      .trim()
                                                                      .toLowerCase();
                                                              return matchBarcode ||
                                                                  matchName;
                                                            }).toList();
                                                            final breakdown = matchingItems
                                                                .map((x) {
                                                                  final loc =
                                                                      x
                                                                          .locationId
                                                                          .isEmpty
                                                                      ? 'Main Branch'
                                                                      : x.locationId;
                                                                  return '$loc (${x.stock})';
                                                                })
                                                                .join(', ');
                                                            return Text(
                                                              'Locations: $breakdown',
                                                              style: TextStyle(
                                                                color:
                                                                    colorScheme
                                                                        .primary,
                                                                fontSize: 11.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      else
                                                        Text(
                                                          'Location: ${p.locationId.isEmpty ? 'Main Branch' : p.locationId}',
                                                          style: TextStyle(
                                                            color: colorScheme
                                                                .secondary,
                                                            fontSize: 11.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                              Text(
                                                p.id,
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      p.productType
                                                              .toUpperCase() ==
                                                          'SERVICE'
                                                      ? AppTheme.brandAmber
                                                            .withValues(
                                                              alpha: 0.12,
                                                            )
                                                      : colorScheme.secondary
                                                            .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        UiRadius.pill,
                                                      ),
                                                ),
                                                child: Text(
                                                  p.productType.toLowerCase(),
                                                  style: TextStyle(
                                                    color:
                                                        p.productType
                                                                .toUpperCase() ==
                                                            'SERVICE'
                                                        ? AppTheme.brandAmber
                                                        : colorScheme.secondary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(p.category)),
                                            DataCell(
                                              Text(
                                                supplierLabel,
                                                style: TextStyle(
                                                  color:
                                                      supplierLabel ==
                                                          'Unlinked'
                                                      ? colorScheme.onSurface
                                                            .withValues(
                                                              alpha: 0.4,
                                                            )
                                                      : colorScheme.onSurface,
                                                  fontStyle:
                                                      supplierLabel ==
                                                          'Unlinked'
                                                      ? FontStyle.italic
                                                      : FontStyle.normal,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                _money(p.price),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                p.allowLooseSales
                                                    ? _formatDualStock(
                                                        p.stock,
                                                        p.measureUnit,
                                                        p.secondaryUnit,
                                                        p.unitConversionRatio,
                                                      )
                                                    : '${p.stock.toStringAsFixed(p.stock.truncateToDouble() == p.stock ? 0 : 2)} ${p.measureUnit}',
                                                style: TextStyle(
                                                  color: p.stock <= p.minStock
                                                      ? AppTheme.brandRose
                                                      : colorScheme.onSurface,
                                                  fontWeight:
                                                      p.stock <= p.minStock
                                                      ? FontWeight.w700
                                                      : FontWeight.normal,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                '${p.minStock.toInt()} ${p.measureUnit}',
                                                style: TextStyle(
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                p.expiryDate == null
                                                    ? 'N/A'
                                                    : '${p.expiryDate!.year}-${p.expiryDate!.month.toString().padLeft(2, '0')}-${p.expiryDate!.day.toString().padLeft(2, '0')}',
                                                style: TextStyle(
                                                  color:
                                                      p.expiryDate != null &&
                                                          p.expiryDate!.isBefore(
                                                            DateTime.now().add(
                                                              Duration(
                                                                days: p
                                                                    .expiryReminderDays,
                                                              ),
                                                            ),
                                                          )
                                                      ? AppTheme.brandRose
                                                      : colorScheme.onSurface,
                                                  fontWeight:
                                                      p.expiryDate != null &&
                                                          p.expiryDate!.isBefore(
                                                            DateTime.now().add(
                                                              Duration(
                                                                days: p
                                                                    .expiryReminderDays,
                                                              ),
                                                            ),
                                                          )
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    productActionButton(
                                                      tooltip:
                                                          _selectedLocationScope ==
                                                                  _DashboardScreenState
                                                                      ._allLocationsLabel &&
                                                              _combineProductsStockAllLocations
                                                          ? 'Untoggle Group by Product to adjust stock'
                                                          : 'Adjust By Quantity',
                                                      onPressed:
                                                          _canManageCatalog &&
                                                              !(_selectedLocationScope ==
                                                                      _DashboardScreenState
                                                                          ._allLocationsLabel &&
                                                                  _combineProductsStockAllLocations)
                                                          ? () async {
                                                              final adjustment =
                                                                  await askStockDelta(
                                                                    p,
                                                                  );
                                                              if (adjustment ==
                                                                  null)
                                                                return;
                                                              await applyStockDelta(
                                                                p,
                                                                adjustment
                                                                    .delta,
                                                                currentCostPrice:
                                                                    adjustment
                                                                        .costPrice,
                                                                reason:
                                                                    adjustment
                                                                        .reason,
                                                                damagedCondition:
                                                                    adjustment
                                                                        .damagedCondition,
                                                                damagedStatus:
                                                                    adjustment
                                                                        .damagedStatus,
                                                              );
                                                            }
                                                          : null,
                                                      icon: Icons.tune_outlined,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    productActionButton(
                                                      tooltip:
                                                          'View Stock History',
                                                      onPressed: () =>
                                                          showStockHistory(p),
                                                      icon: Icons
                                                          .history_outlined,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    productActionButton(
                                                      tooltip:
                                                          _selectedLocationScope ==
                                                                  _DashboardScreenState
                                                                      ._allLocationsLabel &&
                                                              _combineProductsStockAllLocations
                                                          ? 'Untoggle Group by Product to edit'
                                                          : 'Edit Product',
                                                      onPressed:
                                                          _canManageCatalog &&
                                                              !(_selectedLocationScope ==
                                                                      _DashboardScreenState
                                                                          ._allLocationsLabel &&
                                                                  _combineProductsStockAllLocations)
                                                          ? () async {
                                                              final result =
                                                                  await _showProductDialog(
                                                                    existing: p,
                                                                  );
                                                              if (result ==
                                                                      null ||
                                                                  !mounted) {
                                                                return;
                                                              }
                                                              final edited =
                                                                  result
                                                                      .product;
                                                              var addedCategoryToCatalog =
                                                                  false;
                                                              edited.locationId =
                                                                  p.locationId
                                                                      .trim()
                                                                      .isEmpty
                                                                  ? _activeLocationForWrites
                                                                  : p.locationId;
                                                              await Future.delayed(
                                                                const Duration(
                                                                  milliseconds:
                                                                      300,
                                                                ),
                                                              );
                                                              if (!mounted) {
                                                                return;
                                                              }
                                                              setState(() {
                                                                final i = _products
                                                                    .indexWhere(
                                                                      (x) =>
                                                                          x.id ==
                                                                          p.id,
                                                                    );
                                                                if (i != -1) {
                                                                  _products[i] =
                                                                      edited;
                                                                }
                                                                if (!_productCategories.any(
                                                                  (c) =>
                                                                      c
                                                                          .toLowerCase() ==
                                                                      edited
                                                                          .category
                                                                          .toLowerCase(),
                                                                )) {
                                                                  _productCategories
                                                                      .add(
                                                                        edited
                                                                            .category,
                                                                      );
                                                                  addedCategoryToCatalog =
                                                                      true;
                                                                }
                                                              });
                                                              await _persistWorkspaceData();
                                                              _notifyExpiryReminders();

                                                              if (addedCategoryToCatalog) {
                                                                await _enqueueSync(
                                                                  'UPDATE',
                                                                  'categories',
                                                                  edited
                                                                      .category,
                                                                );
                                                              }

                                                              if (_productRepository !=
                                                                  null) {
                                                                await _productRepository!
                                                                    .updateProduct(
                                                                      _toDomainProduct(
                                                                        edited,
                                                                      ),
                                                                    );
                                                                await _refreshPendingSyncQueue();
                                                                await _triggerImmediateSync(
                                                                  action:
                                                                      'UPDATE',
                                                                  module:
                                                                      'products',
                                                                  reference:
                                                                      edited.id,
                                                                );
                                                              } else {
                                                                await _enqueueSync(
                                                                  'UPDATE',
                                                                  'products',
                                                                  edited.id,
                                                                );
                                                              }
                                                            }
                                                          : null,
                                                      icon: Icons.edit_outlined,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    productActionButton(
                                                      tooltip:
                                                          _selectedLocationScope ==
                                                                  _DashboardScreenState
                                                                      ._allLocationsLabel &&
                                                              _combineProductsStockAllLocations
                                                          ? 'Untoggle Group by Product to delete'
                                                          : 'Delete Product',
                                                      onPressed:
                                                          _canManageCatalog &&
                                                              !(_selectedLocationScope ==
                                                                      _DashboardScreenState
                                                                          ._allLocationsLabel &&
                                                                  _combineProductsStockAllLocations)
                                                          ? () async {
                                                              setState(() {
                                                                _products
                                                                    .removeWhere(
                                                                      (x) =>
                                                                          x.id ==
                                                                          p.id,
                                                                    );
                                                              });
                                                              await _persistWorkspaceData();
                                                              _notifyExpiryReminders();

                                                              if (_productRepository !=
                                                                  null) {
                                                                await _productRepository!
                                                                    .deleteProduct(
                                                                      p.id,
                                                                    );
                                                                await _refreshPendingSyncQueue();
                                                                await _triggerImmediateSync(
                                                                  action:
                                                                      'DELETE',
                                                                  module:
                                                                      'products',
                                                                  reference:
                                                                      p.id,
                                                                );
                                                              } else {
                                                                await _enqueueSync(
                                                                  'DELETE',
                                                                  'products',
                                                                  p.id,
                                                                );
                                                              }
                                                            }
                                                          : null,
                                                      icon:
                                                          Icons.delete_outline,
                                                      color: AppTheme.brandRose,
                                                    ),
                                                  ],
                                                ),
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
    );
  }
}
