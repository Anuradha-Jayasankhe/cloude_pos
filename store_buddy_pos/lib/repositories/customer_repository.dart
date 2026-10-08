import '../database/database.dart' as db;
import '../models/models.dart' as models;
import '../services/sync_service.dart';

class CustomerRepository {
  final db.AppDatabase _database;
  final SyncService? _syncService;

  CustomerRepository(this._database, [this._syncService]);

  Future<List<models.Customer>> getAllCustomers() async {
    final customers = await _database.getAllCustomers();
    return customers
        .map(
          (c) => models.Customer(
            id: c.id,
            tenantId: c.tenantId,
            name: c.name,
            phone: c.phone,
            email: c.email,
            address: c.address,
            vehicleNumber: c.vehicleNumber,
            creditLimit: c.creditLimit,
            currentBalance: c.currentBalance,
            synced: c.synced,
            createdAt: c.createdAt,
            updatedAt: c.updatedAt,
            shippingAddress: c.shippingAddress,
          ),
        )
        .toList();
  }

  Future<void> insertCustomer(models.Customer customer) async {
    final now = DateTime.now().toUtc();
    final stamped = models.Customer(
      id: customer.id,
      tenantId: customer.tenantId,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      vehicleNumber: customer.vehicleNumber,
      creditLimit: customer.creditLimit,
      currentBalance: customer.currentBalance,
      synced: false,
      createdAt: customer.createdAt ?? now,
      updatedAt: now,
      shippingAddress: customer.shippingAddress,
    );
    await _database.insertCustomer(stamped.toCompanion());
    if (_syncService != null) {
      try {
        await _syncService.queueOperation('INSERT', 'customers', stamped.id, {
          'id': stamped.id,
          'tenantId': stamped.tenantId,
          'name': stamped.name,
          'phone': stamped.phone,
          'email': stamped.email,
          'address': stamped.address,
          'vehicleNumber': stamped.vehicleNumber,
          'creditLimit': stamped.creditLimit,
          'currentBalance': stamped.currentBalance,
          'createdAt': stamped.createdAt?.toIso8601String(),
          'updatedAt': stamped.updatedAt?.toIso8601String(),
          'shippingAddress': stamped.shippingAddress,
        });
      } catch (_) {
        // The local row is already durable. SyncService repairs missing queue
        // entries from unsynced rows on the next sync cycle.
      }
    }
  }

  Future<void> updateCustomer(models.Customer customer) async {
    final now = DateTime.now().toUtc();
    final stamped = models.Customer(
      id: customer.id,
      tenantId: customer.tenantId,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      vehicleNumber: customer.vehicleNumber,
      creditLimit: customer.creditLimit,
      currentBalance: customer.currentBalance,
      synced: false,
      createdAt: customer.createdAt,
      updatedAt: now,
      shippingAddress: customer.shippingAddress,
    );
    await _database.updateCustomer(stamped.toCompanion());
    if (_syncService != null) {
      try {
        await _syncService.queueOperation('UPDATE', 'customers', stamped.id, {
          'id': stamped.id,
          'tenantId': stamped.tenantId,
          'name': stamped.name,
          'phone': stamped.phone,
          'email': stamped.email,
          'address': stamped.address,
          'vehicleNumber': stamped.vehicleNumber,
          'creditLimit': stamped.creditLimit,
          'currentBalance': stamped.currentBalance,
          'createdAt': stamped.createdAt?.toIso8601String(),
          'updatedAt': stamped.updatedAt?.toIso8601String(),
          'shippingAddress': stamped.shippingAddress,
        });
      } catch (_) {
        // The local row is already durable. SyncService repairs missing queue
        // entries from unsynced rows on the next sync cycle.
      }
    }
  }

  Future<void> deleteCustomer(String id) async {
    await (_database.delete(
      _database.customers,
    )..where((c) => c.id.equals(id))).go();
    if (_syncService != null) {
      await _syncService.queueOperation('DELETE', 'customers', id, {'id': id});
    }
  }
}
