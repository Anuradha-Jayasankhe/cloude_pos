part of '../dashboard_screen.dart';

extension _inventory_pageExt on _DashboardScreenState {
  Widget _buildInventoryPage() {
    return _moduleCard(
      title: 'Inventory Management',
      action: ElevatedButton.icon(
        onPressed: _canManageCatalog
            ? () async {
                final po = await _showCreatePurchaseOrderDialog();
                if (po == null) return;
                setState(() {
                  _purchaseOrders.insert(0, po);
                });
                await _enqueueSync('INSERT', 'purchase_orders', po.id);
              }
            : null,
        icon: const Icon(Icons.add_business),
        label: const Text('New Purchase Order'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: _scopedProducts.length,
              itemBuilder: (context, index) {
                final p = _scopedProducts[index];
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      'Current stock ${p.stock}  -  Minimum ${p.minStock}',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Recent Purchase Orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: _purchaseOrders.isEmpty
                ? const Center(child: Text('No purchase orders yet.'))
                : ListView.builder(
                    itemCount: _purchaseOrders.length,
                    itemBuilder: (context, index) {
                      final po = _purchaseOrders[index];
                      return ListTile(
                        title: Text('${po.id}  -  ${po.supplier}'),
                        subtitle: Text(
                          'Items ${po.itemsCount}  -  ${_money(po.amount)}',
                        ),
                        onTap: () => _showPODetailsDialog(po),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
