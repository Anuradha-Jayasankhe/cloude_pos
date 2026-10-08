part of '../dashboard_screen.dart';

extension _suppliers_pageExt on _DashboardScreenState {
  Widget _supplierAvatar(_SupplierItem supplier) {
    final imagePath = supplier.imagePath.trim();
    if (imagePath.isEmpty) {
      final initial = supplier.name.trim().isEmpty
          ? '?'
          : supplier.name.trim().substring(0, 1).toUpperCase();
      return CircleAvatar(child: Text(initial));
    }
    if (imagePath.startsWith('http')) {
      return CircleAvatar(backgroundImage: NetworkImage(imagePath));
    }
    return CircleAvatar(backgroundImage: FileImage(File(imagePath)));
  }

  Widget _supplierImagePreview(String path) {
    if (path.trim().isEmpty) {
      return Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE1E5EE)),
        ),
        child: const Icon(Icons.image_outlined, color: Color(0xFF9AA3B2)),
      );
    }
    final imageWidget = path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(height: 80, width: 80, child: imageWidget),
    );
  }

  Future<void> _createProductForSupplier(_SupplierItem supplier) async {
    final result = await _showProductDialog(initialSupplierId: supplier.id);
    if (result == null || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _handleProductCreation(result);
  }

  Future<void> _showSupplierProductLinkDialog(_SupplierItem supplier) async {
    final searchController = TextEditingController();
    final selected = <String>{};

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          final query = searchController.text.trim().toLowerCase();
          final filtered = _products.where((p) {
            if (query.isEmpty) return true;
            return p.name.toLowerCase().contains(query) ||
                p.id.toLowerCase().contains(query);
          }).toList();

          final screenSize = MediaQuery.of(context).size;
          final dialogWidth = screenSize.width < 600
              ? screenSize.width * 0.94
              : 560.0;
          final dialogHeight = screenSize.height < 640
              ? screenSize.height * 0.88
              : 560.0;

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
              height: dialogHeight,
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.brandIndigo.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            Icons.link_rounded,
                            color: AppTheme.brandIndigo,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Link Products',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'to ${supplier.name}',
                                style: const TextStyle(
                                  color: Color(0xFF6D7383),
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Search + selection count ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: (_) => setLocal(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search products by name or SKU',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        if (selected.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.brandIndigo.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${selected.length} selected',
                              style: TextStyle(
                                color: AppTheme.brandIndigo,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Product list ─────────────────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No products found.'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              final isLinkedHere =
                                  product.supplierId == supplier.id;
                              final hasOtherSupplier =
                                  product.supplierId.isNotEmpty &&
                                  product.supplierId != supplier.id;
                              final currentSupplier = hasOtherSupplier
                                  ? _suppliers.firstWhere(
                                      (s) => s.id == product.supplierId,
                                      orElse: () => _SupplierItem(
                                        id: '',
                                        name: 'Unknown',
                                        contact: '',
                                        email: '',
                                      ),
                                    )
                                  : null;
                              final statusColor = isLinkedHere
                                  ? const Color(0xFF179C52)
                                  : hasOtherSupplier
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF9AA3B2);
                              final statusText = isLinkedHere
                                  ? 'Linked here'
                                  : hasOtherSupplier
                                  ? currentSupplier?.name ?? 'Unknown'
                                  : 'Unlinked';
                              final isSelected = selected.contains(product.id);
                              return Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.brandIndigo.withValues(
                                          alpha: 0.06,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CheckboxListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setLocal(() {
                                      if (checked == true) {
                                        selected.add(product.id);
                                      } else {
                                        selected.remove(product.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // ── Footer actions ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: selected.isEmpty
                                    ? null
                                    : () async {
                                        final targets = _products
                                            .where(
                                              (p) => selected.contains(p.id),
                                            )
                                            .toList();
                                        final unlinkTargets = targets
                                            .where(
                                              (p) =>
                                                  p.supplierId == supplier.id,
                                            )
                                            .toList();
                                        if (unlinkTargets.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No selected items are linked to this supplier.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        setState(() {
                                          for (final product in unlinkTargets) {
                                            product.supplierId = '';
                                          }
                                        });
                                        await _persistWorkspaceData();

                                        for (final product in unlinkTargets) {
                                          if (_productRepository != null) {
                                            await _productRepository!
                                                .updateProduct(
                                                  _toDomainProduct(product),
                                                );
                                            await _refreshPendingSyncQueue();
                                            await _triggerImmediateSync(
                                              action: 'UPDATE',
                                              module: 'products',
                                              reference: product.id,
                                            );
                                          } else {
                                            await _enqueueSync(
                                              'UPDATE',
                                              'products',
                                              product.id,
                                            );
                                          }
                                        }
                                        if (!context.mounted) return;
                                        Navigator.pop(context);
                                      },
                                icon: const Icon(Icons.link_off, size: 15),
                                label: const Text('Unlink'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(
                                    color: Color(0xFFEF4444),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: selected.isEmpty
                                ? null
                                : () async {
                                    final targets = _products
                                        .where((p) => selected.contains(p.id))
                                        .toList();
                                    final reassign = targets
                                        .where(
                                          (p) =>
                                              p.supplierId.isNotEmpty &&
                                              p.supplierId != supplier.id,
                                        )
                                        .toList();

                                    if (reassign.isNotEmpty) {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Reassign suppliers?',
                                          ),
                                          content: Text(
                                            'Some products are already linked to another supplier. Reassign them to ${supplier.name}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('No'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppTheme.brandIndigo,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Yes, reassign',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed != true) return;
                                    }

                                    setState(() {
                                      for (final product in targets) {
                                        product.supplierId = supplier.id;
                                      }
                                    });
                                    await _persistWorkspaceData();

                                    for (final product in targets) {
                                      if (_productRepository != null) {
                                        await _productRepository!.updateProduct(
                                          _toDomainProduct(product),
                                        );
                                        await _refreshPendingSyncQueue();
                                        await _triggerImmediateSync(
                                          action: 'UPDATE',
                                          module: 'products',
                                          reference: product.id,
                                        );
                                      } else {
                                        await _enqueueSync(
                                          'UPDATE',
                                          'products',
                                          product.id,
                                        );
                                      }
                                    }
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                  },
                            icon: const Icon(Icons.link, size: 15),
                            label: const Text('Link Selected'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandIndigo,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
    );
  }

  Future<void> _showSupplierDetailsDialog(_SupplierItem supplier) async {
    final linkedProducts = _scopedProducts
        .where((p) => p.supplierId == supplier.id)
        .toList();
    final supplierPOs =
        _scopedPurchaseOrders
            .where((po) => po.supplierId == supplier.id)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final softBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    await showDialog<void>(
      context: context,
      builder: (context) {
        final screen = MediaQuery.of(context).size;
        final dialogW = screen.width < 680 ? screen.width * 0.94 : 640.0;
        final dialogH = screen.height < 720 ? screen.height * 0.90 : 640.0;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: dialogW,
            height: dialogH,
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.brandIndigo.withValues(alpha: 0.12),
                          AppTheme.brandIndigo.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.brandIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.brandIndigo.withValues(alpha: 0.25),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: supplier.imagePath.trim().isNotEmpty
                              ? (supplier.imagePath.startsWith('http')
                                  ? Image.network(
                                      supplier.imagePath,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(supplier.imagePath),
                                      fit: BoxFit.cover,
                                    ))
                              : Center(
                                  child: Text(
                                    supplier.name.isNotEmpty
                                        ? supplier.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                      color: AppTheme.brandIndigo,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier.name.isEmpty
                                    ? 'Unnamed supplier'
                                    : supplier.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (supplier.companyName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  supplier.companyName,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _supplierStatPill(
                                    icon: Icons.inventory_2_outlined,
                                    label: '${linkedProducts.length} products',
                                    color: AppTheme.brandIndigo,
                                  ),
                                  _supplierStatPill(
                                    icon: Icons.receipt_long_outlined,
                                    label: '${supplierPOs.length} orders',
                                    color: const Color(0xFF0EA5E9),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: muted),
                          style: IconButton.styleFrom(
                            backgroundColor: softBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Tabs ───────────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    decoration: BoxDecoration(
                      color: softBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppTheme.brandIndigo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: muted,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(
                          height: 38,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline_rounded, size: 15),
                              SizedBox(width: 6),
                              Text('Info'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 38,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link_rounded, size: 15),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Products',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          height: 38,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 15),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Purchases',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Tab views ──────────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      children: [
                        // ── Tab 1: Info ──────────────────────────────────
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _supplierInfoSection(
                                title: 'Contact',
                                children: [
                                  _infoRow(
                                    Icons.phone_outlined,
                                    'Phone',
                                    supplier.contact,
                                  ),
                                  _infoRow(
                                    Icons.email_outlined,
                                    'Email',
                                    supplier.email,
                                  ),
                                  _infoRow(
                                    Icons.language_outlined,
                                    'Website',
                                    supplier.website,
                                  ),
                                  _infoRow(
                                    Icons.badge_outlined,
                                    'Tax ID',
                                    supplier.taxId,
                                  ),
                                ],
                              ),
                              if (supplier.address.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _supplierInfoSection(
                                  title: 'Address',
                                  children: [
                                    _infoRow(
                                      Icons.location_on_outlined,
                                      'Address',
                                      supplier.address,
                                    ),
                                  ],
                                ),
                              ],
                              if (supplier.notes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _supplierInfoSection(
                                  title: 'Notes',
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        4,
                                        12,
                                        12,
                                      ),
                                      child: Text(
                                        supplier.notes,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          height: 1.45,
                                          color: isDark
                                              ? const Color(0xFFE2E8F0)
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                'Images',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _supplierImagePreview(supplier.imagePath),
                                  _supplierImagePreview(supplier.idCardImage1),
                                  _supplierImagePreview(supplier.idCardImage2),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // ── Tab 2: Linked Products ───────────────────────
                        linkedProducts.isEmpty
                            ? _supplierEmptyState(
                                icon: Icons.inventory_2_outlined,
                                title: 'No linked products',
                                subtitle:
                                    'Link existing products or create a new one for this supplier.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  8,
                                ),
                                itemCount: linkedProducts.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final p = linkedProducts[i];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: softBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppTheme.brandIndigo
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.inventory_2_outlined,
                                            size: 20,
                                            color: AppTheme.brandIndigo,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Stock: ${p.stock}  ·  Cost: ${_money(p.costPrice ?? p.price)}  ·  Sell: ${_money(p.price)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          p.id,
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        // ── Tab 3: Purchase History ──────────────────────
                        supplierPOs.isEmpty
                            ? _supplierEmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: 'No purchase orders yet',
                                subtitle:
                                    'Create a new purchase order for this supplier to get started.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  8,
                                ),
                                itemCount: supplierPOs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final po = supplierPOs[i];
                                  final statusColor = _poStatusColor(po.status);
                                  final statusBg = _poStatusBg(po.status);
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showPODetailsDialog(po);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: softBg,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          po.id,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 13.5,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: statusBg,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          po.status,
                                                          style: TextStyle(
                                                            color: statusColor,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    '${po.itemsCount} items  ·  ${po.paymentMethod}'
                                                    '${po.amountDue > 0 ? "  ·  Due: ${_money(po.amountDue)}" : ""}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: muted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _money(po.amount),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (po.amountDue > 0)
                                                  Text(
                                                    'Due ${_money(po.amountDue)}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFFDC2626),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 20,
                                              color: muted,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                  // ── Action bar ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border(
                        top: BorderSide(color: borderColor),
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 520;
                        final actions = [
                          _supplierDetailAction(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            onPressed: () {
                              Navigator.pop(context);
                              _editSupplier(supplier);
                            },
                          ),
                          _supplierDetailAction(
                            icon: Icons.add_box_outlined,
                            label: 'New Product',
                            onPressed: () {
                              Navigator.pop(context);
                              _createProductForSupplier(supplier);
                            },
                          ),
                          _supplierDetailAction(
                            icon: Icons.link_rounded,
                            label: 'Link',
                            onPressed: () {
                              Navigator.pop(context);
                              _showSupplierProductLinkDialog(supplier);
                            },
                          ),
                          _supplierDetailAction(
                            icon: Icons.add_shopping_cart_rounded,
                            label: 'New PO',
                            primary: true,
                            onPressed: () async {
                              Navigator.pop(context);
                              final po =
                                  await _showCreatePurchaseOrderDialog();
                              if (po == null) return;
                              setState(() => _purchaseOrders.insert(0, po));
                              await _persistWorkspaceData();
                              await _enqueueSync(
                                'INSERT',
                                'purchase_orders',
                                po.id,
                              );
                            },
                          ),
                        ];

                        if (narrow) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: actions,
                          );
                        }
                        return Row(
                          children: [
                            for (var i = 0; i < actions.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              if (i == actions.length - 1) const Spacer(),
                              actions[i],
                            ],
                          ],
                        );
                      },
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

  Widget _supplierStatPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _supplierInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final softBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: muted,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.brandIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.brandIndigo),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _supplierEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.brandIndigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 30, color: AppTheme.brandIndigo),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supplierDetailAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _editSupplier(_SupplierItem supplier) async {
    final updated = await _showSupplierDialog(existing: supplier);
    if (updated == null) return;
    setState(() {
      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index >= 0) {
        _suppliers[index] = updated;
      }
    });
    await _persistWorkspaceData();
    await _enqueueSync('UPDATE', 'suppliers', updated.id);
  }

  Widget _infoChip(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4DCEF)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.black87, fontSize: 13),
      ),
    );
  }

  Widget _buildSuppliersPage() {
    return _moduleCard(
      title: 'Suppliers',
      action: ElevatedButton.icon(
        onPressed: () async {
          final supplier = await _showSupplierDialog();
          if (supplier == null) return;
          setState(() {
            _suppliers.add(supplier);
          });
          await _persistWorkspaceData();
          await _enqueueSync('INSERT', 'suppliers', supplier.id);
        },
        icon: const Icon(Icons.local_shipping_outlined, size: 18),
        label: const Text(
          'Add Supplier',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      child: SizedBox(
        height: 560,
        child: _suppliers.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 40,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No suppliers yet.',
                      style: TextStyle(color: Color(0xFF6D7383), fontSize: 14),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _suppliers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final s = _suppliers[index];
                  final linkedCount = _scopedProducts
                      .where((p) => p.supplierId == s.id)
                      .length;
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE4E7EF)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showSupplierDetailsDialog(s),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: _supplierAvatar(s),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name.isEmpty
                                            ? 'Unnamed supplier'
                                            : s.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (s.companyName.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            s.companyName,
                                            style: const TextStyle(
                                              color: Color(0xFF6D7383),
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          if (s.contact.isNotEmpty)
                                            _supplierChip(
                                              Icons.phone_outlined,
                                              s.contact,
                                            ),
                                          if (s.email.isNotEmpty)
                                            _supplierChip(
                                              Icons.email_outlined,
                                              s.email,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandIndigo.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '$linkedCount linked',
                                    style: TextStyle(
                                      color: AppTheme.brandIndigo,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _supplierActionButton(
                                  icon: Icons.edit_outlined,
                                  label: 'Edit',
                                  onPressed: () => _editSupplier(s),
                                ),
                                const SizedBox(width: 8),
                                _supplierActionButton(
                                  icon: Icons.add_box_outlined,
                                  label: 'New Product',
                                  onPressed: () => _createProductForSupplier(s),
                                ),
                                const SizedBox(width: 8),
                                _supplierActionButton(
                                  icon: Icons.link_outlined,
                                  label: 'Link',
                                  onPressed: () =>
                                      _showSupplierProductLinkDialog(s),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Delete supplier',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () async {
                                    setState(() {
                                      _suppliers.removeWhere(
                                        (x) => x.id == s.id,
                                      );
                                    });
                                    await _persistWorkspaceData();
                                    await _enqueueSync(
                                      'DELETE',
                                      'suppliers',
                                      s.id,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFD32F2F),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _supplierChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6D7383)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF3A3F4B)),
          ),
        ],
      ),
    );
  }

  Widget _supplierActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
