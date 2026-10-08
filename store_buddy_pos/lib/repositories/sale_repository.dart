import 'package:drift/drift.dart';

import '../database/database.dart' as db;
import '../models/models.dart' as models;
import '../services/commission_service.dart';
import '../services/sync_service.dart';

class SaleRepository {
  final db.AppDatabase _database;
  final SyncService? _syncService;
  final CommissionService _commissionService;

  SaleRepository(this._database, [this._syncService])
    : _commissionService = CommissionService(_database);

  Future<List<models.Sale>> getAllSales() async {
    final sales = await _database.getAllSales();
    final mapped = <models.Sale>[];

    for (final s in sales) {
      final items = await _database.getSaleItems(s.id);
      mapped.add(
        models.Sale(
          id: s.id,
          tenantId: s.tenantId,
          customerId: s.customerId,
          employeeId: s.employeeId,
          invoiceNumber: s.invoiceNumber,
          total: s.total,
          tax: s.tax,
          discount: s.discount,
          paymentMethod: s.paymentMethod,
          status: s.status,
          locationId: s.locationId,
          synced: s.synced,
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
          notes: s.notes ?? '',
          shippingAddress: s.shippingAddress,
          shippingCharges: s.shippingCharges,
          agentName: s.agentName,
          agentCommission: s.agentCommission,
          agentCommissionType: s.agentCommissionType,
          agentCommissionPaid: s.agentCommissionPaid,
          items: items
              .map(
                (i) => models.SaleItem(
                  id: i.id,
                  saleId: i.saleId,
                  productId: i.productId,
                  productName: i.productName,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  total: i.total,
                  tenantId: i.tenantId,
                ),
              )
              .toList(),
        ),
      );
    }

    return mapped;
  }

  Future<void> insertSale(models.Sale sale) async {
    final now = DateTime.now().toUtc();
    // Ensure the sale has accurate timestamps for LWW conflict resolution.
    final stamped = models.Sale(
      id: sale.id,
      tenantId: sale.tenantId,
      customerId: sale.customerId,
      employeeId: sale.employeeId,
      invoiceNumber: sale.invoiceNumber,
      total: sale.total,
      tax: sale.tax,
      discount: sale.discount,
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      locationId: sale.locationId,
      synced: false, // will flip to true after server ack
      createdAt: sale.createdAt ?? now,
      updatedAt: now,
      shippingCharges: sale.shippingCharges,
      agentName: sale.agentName,
      agentCommission: sale.agentCommission,
      agentCommissionType: sale.agentCommissionType,
      agentCommissionPaid: sale.agentCommissionPaid,
      items: sale.items,
      customer: sale.customer,
      notes: sale.notes,
      shippingAddress: sale.shippingAddress,
      installmentSchedules: sale.installmentSchedules,
    );

    await _database.insertSale(stamped.toCompanion());
    for (final item in stamped.items) {
      await _database.insertSaleItem(item.toCompanion());
    }
    await _commissionService.recordCommissionsForSale(stamped);

    if (_syncService != null) {
      final syncedItems = <Map<String, dynamic>>[];
      for (final i in stamped.items) {
        syncedItems.add({
          'id': i.id,
          'saleId': i.saleId,
          'productId': i.productId,
          'productName': i.productName,
          'quantity': i.quantity,
          'unitPrice': i.unitPrice,
          'total': i.total,
          'tenantId': i.tenantId,
          'productType': await _productTypeForSaleItemId(i.productId),
        });
      }
      try {
        await _syncService.queueOperation('INSERT', 'sales', stamped.id, {
          'id': stamped.id,
          'tenantId': stamped.tenantId,
          'customerId': stamped.customerId,
          'employeeId': stamped.employeeId,
          'invoiceNumber': stamped.invoiceNumber,
          'total': stamped.total,
          'tax': stamped.tax,
          'discount': stamped.discount,
          'paymentMethod': stamped.paymentMethod,
          'status': stamped.status,
          'locationId': stamped.locationId,
          'createdAt': stamped.createdAt?.toIso8601String(),
          'updatedAt': stamped.updatedAt?.toIso8601String(),
          'shippingAddress': stamped.shippingAddress,
          'shippingCharges': stamped.shippingCharges,
          'notes': stamped.notes,
          'agentName': stamped.agentName,
          'agentCommission': stamped.agentCommission,
          'agentCommissionType': stamped.agentCommissionType,
          'agentCommissionPaid': stamped.agentCommissionPaid,
          'installmentSchedules': stamped.installmentSchedules.map((s) => s.toJson()).toList(),
          'items': syncedItems,
        });
      } catch (_) {
        // The local row is already durable. SyncService repairs missing queue
        // entries from unsynced rows on the next sync cycle.
      }
    }
  }

  Future<void> updateSale(models.Sale sale) async {
    final now = DateTime.now().toUtc();
    final stamped = models.Sale(
      id: sale.id,
      tenantId: sale.tenantId,
      customerId: sale.customerId,
      employeeId: sale.employeeId,
      invoiceNumber: sale.invoiceNumber,
      total: sale.total,
      tax: sale.tax,
      discount: sale.discount,
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      locationId: sale.locationId,
      synced: false,
      createdAt: sale.createdAt ?? now,
      updatedAt: now,
      shippingCharges: sale.shippingCharges,
      agentName: sale.agentName,
      agentCommission: sale.agentCommission,
      agentCommissionType: sale.agentCommissionType,
      agentCommissionPaid: sale.agentCommissionPaid,
      items: sale.items,
      customer: sale.customer,
      notes: sale.notes,
      shippingAddress: sale.shippingAddress,
      installmentSchedules: sale.installmentSchedules,
    );

    // Delete existing sale items first to prevent orphan items
    await _database.deleteSaleItemsBySaleId(stamped.id);

    await _database.insertSale(stamped.toCompanion());
    for (final item in stamped.items) {
      await _database.insertSaleItem(item.toCompanion());
    }
    await _commissionService.recordCommissionsForSale(stamped);

    if (_syncService != null) {
      final syncedItems = <Map<String, dynamic>>[];
      for (final i in stamped.items) {
        syncedItems.add({
          'id': i.id,
          'saleId': i.saleId,
          'productId': i.productId,
          'productName': i.productName,
          'quantity': i.quantity,
          'unitPrice': i.unitPrice,
          'total': i.total,
          'tenantId': i.tenantId,
          'productType': await _productTypeForSaleItemId(i.productId),
        });
      }
      try {
        await _syncService.queueOperation('UPDATE', 'sales', stamped.id, {
          'id': stamped.id,
          'tenantId': stamped.tenantId,
          'customerId': stamped.customerId,
          'employeeId': stamped.employeeId,
          'invoiceNumber': stamped.invoiceNumber,
          'total': stamped.total,
          'tax': stamped.tax,
          'discount': stamped.discount,
          'paymentMethod': stamped.paymentMethod,
          'status': stamped.status,
          'locationId': stamped.locationId,
          'createdAt': stamped.createdAt?.toIso8601String(),
          'updatedAt': stamped.updatedAt?.toIso8601String(),
          'shippingAddress': stamped.shippingAddress,
          'shippingCharges': stamped.shippingCharges,
          'notes': stamped.notes,
          'agentName': stamped.agentName,
          'agentCommission': stamped.agentCommission,
          'agentCommissionType': stamped.agentCommissionType,
          'agentCommissionPaid': stamped.agentCommissionPaid,
          'installmentSchedules': stamped.installmentSchedules.map((s) => s.toJson()).toList(),
          'items': syncedItems,
        });
      } catch (_) {
        // Safe to ignore, sync service will recover
      }
    }
  }

  Future<void> updateSaleStatus({
    required String saleId,
    required String status,
  }) async {
    final sale = await _database.getSale(saleId);
    if (sale == null) return;

    final now = DateTime.now().toUtc();
    await _database.updateSale(
      db.SalesCompanion(
        id: Value(sale.id),
        tenantId: Value(sale.tenantId),
        customerId: Value(sale.customerId),
        employeeId: Value(sale.employeeId),
        total: Value(sale.total),
        tax: Value(sale.tax),
        discount: Value(sale.discount),
        paymentMethod: Value(sale.paymentMethod),
        status: Value(status),
        locationId: Value(sale.locationId),
        synced: const Value(false),
        createdAt: Value(sale.createdAt),
        updatedAt: Value(now), // stamp the actual mutation time
        shippingAddress: Value(sale.shippingAddress),
      ),
    );

    if (_syncService != null) {
      final saleItems = await _database.getSaleItems(saleId);
      final syncedItems = <Map<String, dynamic>>[];
      for (final i in saleItems) {
        syncedItems.add({
          'id': i.id,
          'saleId': i.saleId,
          'productId': i.productId,
          'productName': i.productName,
          'quantity': i.quantity,
          'unitPrice': i.unitPrice,
          'total': i.total,
          'tenantId': i.tenantId,
          'productType': await _productTypeForSaleItemId(i.productId),
        });
      }
      try {
        await _syncService.queueOperation('UPDATE', 'sales', saleId, {
          'id': sale.id,
          'tenantId': sale.tenantId,
          'customerId': sale.customerId,
          'employeeId': sale.employeeId,
          'invoiceNumber': sale.invoiceNumber,
          'total': sale.total,
          'tax': sale.tax,
          'discount': sale.discount,
          'paymentMethod': sale.paymentMethod,
          'status': status,
          'locationId': sale.locationId,
          'createdAt': sale.createdAt?.toIso8601String(),
          'updatedAt': now.toIso8601String(), // use the newly-stamped time
          'shippingAddress': sale.shippingAddress,
          'items': syncedItems,
        });
      } catch (_) {
        // The local row is already durable. SyncService repairs missing queue
        // entries from unsynced rows on the next sync cycle.
      }
    }
  }

  Future<void> completeCodDelivery({
    required String saleId,
    required String notes,
  }) async {
    final sale = await _database.getSale(saleId);
    if (sale == null) return;

    final now = DateTime.now().toUtc();
    await _database.updateSale(
      db.SalesCompanion(
        id: Value(sale.id),
        tenantId: Value(sale.tenantId),
        customerId: Value(sale.customerId),
        employeeId: Value(sale.employeeId),
        total: Value(sale.total),
        cashAmount: Value(sale.total),
        tax: Value(sale.tax),
        discount: Value(sale.discount),
        paymentMethod: Value(sale.paymentMethod),
        status: const Value('COMPLETED'),
        notes: Value(notes),
        locationId: Value(sale.locationId),
        invoiceNumber: Value(sale.invoiceNumber),
        synced: const Value(false),
        createdAt: Value(sale.createdAt),
        updatedAt: Value(now),
        shippingAddress: Value(sale.shippingAddress),
      ),
    );

    if (_syncService != null) {
      final saleItems = await _database.getSaleItems(saleId);
      final syncedItems = <Map<String, dynamic>>[];
      for (final i in saleItems) {
        syncedItems.add({
          'id': i.id,
          'saleId': i.saleId,
          'productId': i.productId,
          'productName': i.productName,
          'quantity': i.quantity,
          'unitPrice': i.unitPrice,
          'total': i.total,
          'tenantId': i.tenantId,
          'productType': await _productTypeForSaleItemId(i.productId),
        });
      }
      try {
        await _syncService.queueOperation('UPDATE', 'sales', saleId, {
          'id': sale.id,
          'tenantId': sale.tenantId,
          'customerId': sale.customerId,
          'employeeId': sale.employeeId,
          'invoiceNumber': sale.invoiceNumber,
          'total': sale.total,
          'amountPaid': sale.total,
          'balance': 0.0,
          'tax': sale.tax,
          'discount': sale.discount,
          'paymentMethod': sale.paymentMethod,
          'status': 'COMPLETED',
          'notes': notes,
          'locationId': sale.locationId,
          'createdAt': sale.createdAt?.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'shippingAddress': sale.shippingAddress,
          'items': syncedItems,
        });
      } catch (_) {}
    }
  }

  Future<String> _productTypeForSaleItemId(String productId) async {
    if (productId.startsWith('SV:')) {
      return 'SERVICE';
    }
    final product = await _database.getProduct(productId);
    if (product == null) {
      return 'PRODUCT';
    }
    final type = product.type.trim().toUpperCase();
    return type.isEmpty ? 'PRODUCT' : type;
  }

  Future<void> deleteSaleById(String saleId) async {
    await _database.deleteSaleItemsBySaleId(saleId);
    await _database.deleteSale(saleId);
    if (_syncService != null) {
      await _syncService.queueOperation('DELETE', 'sales', saleId, {
        'id': saleId,
      });
    }
  }

  Future<void> deleteSalesByIds(Iterable<String> saleIds) async {
    for (final saleId in saleIds) {
      await deleteSaleById(saleId);
    }
  }
}
