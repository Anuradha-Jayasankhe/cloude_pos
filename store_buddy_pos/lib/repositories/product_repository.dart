import '../database/database.dart' as db;
import '../models/models.dart' as models;
import '../services/sync_service.dart';

class ProductRepository {
  final db.AppDatabase _database;
  final SyncService? _syncService;

  ProductRepository(this._database, [this._syncService]);

  Future<List<models.Product>> getAllProducts() async {
    final products = await _database.getAllProducts();
    return products
        .map(
          (p) => models.Product(
            id: p.id,
            tenantId: p.tenantId,
            name: p.name,
            description: p.description,
            sku: p.sku,
            barcode: p.barcode,
            price: p.price,
            costPrice: p.costPrice,
            minPrice: p.minPrice,
            category: p.category,
            type: p.type,
            unitOfMeasure: p.unitOfMeasure,
            stock: p.stock,
            minStock: p.minStock,
            warrantyMonths: p.warrantyMonths,
            expiryDate: p.expiryDate,
            locationId: p.locationId,
            supplierId: p.supplierId,
            imeis: p.imeis,
            synced: p.synced,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
          ),
        )
        .toList();
  }

  Future<models.Product?> getProduct(String id) async {
    final product = await _database.getProduct(id);
    if (product != null) {
      return models.Product(
        id: product.id,
        tenantId: product.tenantId,
        name: product.name,
        description: product.description,
        sku: product.sku,
        barcode: product.barcode,
        price: product.price,
        costPrice: product.costPrice,
        minPrice: product.minPrice,
        category: product.category,
        type: product.type,
        unitOfMeasure: product.unitOfMeasure,
        stock: product.stock,
        minStock: product.minStock,
        warrantyMonths: product.warrantyMonths,
        expiryDate: product.expiryDate,
        locationId: product.locationId,
        supplierId: product.supplierId,
        imeis: product.imeis,
        synced: product.synced,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
    }
    return null;
  }

  Future<void> insertProduct(models.Product product) async {
    // Stamp createdAt/updatedAt so conflict resolution timestamps are accurate.
    final now = DateTime.now().toUtc();
    final stamped = models.Product(
      id: product.id,
      tenantId: product.tenantId,
      name: product.name,
      description: product.description,
      sku: product.sku,
      barcode: product.barcode,
      price: product.price,
      costPrice: product.costPrice,
      minPrice: product.minPrice,
      category: product.category,
      type: product.type,
      unitOfMeasure: product.unitOfMeasure,
      stock: product.stock,
      minStock: product.minStock,
      warrantyMonths: product.warrantyMonths,
      expiryDate: product.expiryDate,
      locationId: product.locationId,
      supplierId: product.supplierId,
      imeis: product.imeis,
      synced: false, // will be set to true after server ack
      createdAt: product.createdAt ?? now,
      updatedAt: now,
    );
    await _database.insertProduct(stamped.toCompanion());
    if (_syncService != null) {
      try {
        await _syncService.queueOperation(
          'INSERT',
          'products',
          stamped.id,
          stamped.toJson(),
        );
      } catch (_) {
        // The local row is already durable. SyncService repairs missing queue
        // entries from unsynced rows on the next sync cycle.
      }
    }
  }

  Future<void> updateProduct(models.Product product) async {
    final now = DateTime.now().toUtc();
    final stamped = models.Product(
      id: product.id,
      tenantId: product.tenantId,
      name: product.name,
      description: product.description,
      sku: product.sku,
      barcode: product.barcode,
      price: product.price,
      costPrice: product.costPrice,
      minPrice: product.minPrice,
      category: product.category,
      type: product.type,
      unitOfMeasure: product.unitOfMeasure,
      stock: product.stock,
      minStock: product.minStock,
      warrantyMonths: product.warrantyMonths,
      expiryDate: product.expiryDate,
      locationId: product.locationId,
      supplierId: product.supplierId,
      imeis: product.imeis,
      synced: false, // will be set to true after server ack
      createdAt: product.createdAt,
      updatedAt: now,
    );
    await _database.updateProduct(stamped.toCompanion());
    if (_syncService != null) {
      try {
        await _syncService.queueOperation(
          'UPDATE',
          'products',
          stamped.id,
          stamped.toJson(),
        );
      } catch (_) {
        // The local row is already durable. SyncService repairs missing queue
        // entries from unsynced rows on the next sync cycle.
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    await _database.deleteProduct(id);
    if (_syncService != null) {
      await _syncService.queueOperation('DELETE', 'products', id, {'id': id});
    }
  }
}
