part of '../dashboard_screen.dart';

extension _categories_pageExt on _DashboardScreenState {
  Widget _buildCategoriesPage() {
    final compact = MediaQuery.of(context).size.width < UiBreakpoints.tablet;
    final categories = _productCategories.where((c) {
      final q = _categoriesSearchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return c.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontSize: compact ? 30 : 40,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Organize products using categories.',
            style: TextStyle(color: Color(0xFF6F7A8A), fontSize: 16),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: compact
                    ? double.infinity
                    : _adaptiveWidth(460, minWidth: 260, horizontalPadding: 40),
                child: TextField(
                  controller: _categoriesSearchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _canManageCatalog ? _manageCategories : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiRadius.md),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add New Category'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final count = _products
                      .where(
                        (p) => p.category.toLowerCase() == cat.toLowerCase(),
                      )
                      .length;
                  return ListTile(
                    title: Text(cat),
                    subtitle: Text('$count products'),
                    trailing: _canManageCatalog
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editCategory(cat),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit category',
                              ),
                              IconButton(
                                onPressed: () => _deleteCategory(cat),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete category',
                              ),
                            ],
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _canManageCatalog ? () => _editCategory(cat) : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCategory(String oldCategory) async {
    final controller = TextEditingController(text: oldCategory);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
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
    );

    if (updated == null || updated.isEmpty || updated == oldCategory) return;
    final duplicate = _productCategories.any(
      (c) => c.toLowerCase() == updated.toLowerCase(),
    );
    if (duplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category already exists')));
      return;
    }

    setState(() {
      _productCategories = _productCategories
          .map((c) => c == oldCategory ? updated : c)
          .toList();
      if (_categoryAttributes.containsKey(oldCategory)) {
        _categoryAttributes[updated] =
            _categoryAttributes.remove(oldCategory) ?? [];
      }
      for (final product in _products) {
        if (product.category == oldCategory) {
          product.category = updated;
        }
      }
      if (_posCategoryFilter == oldCategory) {
        _posCategoryFilter = updated;
      }
    });
    await _persistWorkspaceData();
    await _enqueueSync('UPDATE', 'categories', updated);
  }

  Future<void> _deleteCategory(String category) async {
    final affectedCount = _products
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          affectedCount > 0
              ? 'Delete "$category"? $affectedCount products will be moved to General.'
              : 'Delete "$category"?',
        ),
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

    if (confirmed != true) return;

    setState(() {
      _productCategories.removeWhere((c) => c == category);
      _categoryAttributes.remove(category);
      if (_productCategories.isEmpty) {
        _productCategories.add('General');
      }
      if (affectedCount > 0) {
        if (!_productCategories.any((c) => c.toLowerCase() == 'general')) {
          _productCategories.add('General');
        }
        for (final product in _products) {
          if (product.category.toLowerCase() == category.toLowerCase()) {
            product.category = 'General';
          }
        }
      }
      if (_posCategoryFilter == category) {
        _posCategoryFilter = 'All Categories';
      }
    });
    await _persistWorkspaceData();
    await _enqueueSync('DELETE', 'categories', category);
  }
}
