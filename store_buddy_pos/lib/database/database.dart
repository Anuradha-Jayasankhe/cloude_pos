import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    Sales,
    SaleItems,
    Customers,
    Employees,
    CommissionRules,
    SyncQueue,
    SyncJournal,
    CommissionLogs,
    Expenses,
    Discounts,
    LoyaltyLedger,
    PrintSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  final String tenantId;

  AppDatabase._internal(super.e, this.tenantId);

  static final Map<String, AppDatabase> _instances = {};

  factory AppDatabase(String tenantId) {
    if (_instances.containsKey(tenantId)) {
      return _instances[tenantId]!;
    }
    final db = AppDatabase._internal(_openConnection(tenantId), tenantId);
    _instances[tenantId] = db;
    return db;
  }

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => await m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(products, products.description);
        await m.addColumn(products, products.warrantyMonths);
      }
      if (from < 3) {
        // Add lastRetryAt to SyncQueue to correctly track exponential back-off
        // from the actual last attempt time rather than the queue insertion time.
        await m.addColumn(syncQueue, syncQueue.lastRetryAt);
      }
      if (from < 4) {
        await m.addColumn(syncQueue, syncQueue.clientOpId);
        await customStatement(
          "UPDATE sync_queue SET client_op_id = 'legacy-' || id WHERE client_op_id IS NULL",
        );
      }
      if (from < 5) {
        await m.createTable(syncJournal);
      }
      if (from < 6) {
        await m.addColumn(products, products.supplierId);
      }
      if (from < 7) {
        // New tables
        await m.createTable(commissionLogs);
        await m.createTable(expenses);
        await m.createTable(discounts);
        await m.createTable(loyaltyLedger);
        await m.createTable(printSettings);
        // Extended columns on existing tables
        await m.addColumn(products, products.reorderLevel);
        await m.addColumn(products, products.batchNumber);
        await m.addColumn(products, products.expiryDate);
        await m.addColumn(products, products.commissionEligible);
        await m.addColumn(products, products.agentCommissionPercent);
        await m.addColumn(products, products.bonusCommission);
        await m.addColumn(products, products.profitMargin);
        await m.addColumn(products, products.imageUrl);
        await m.addColumn(sales, sales.subtotal);
        await m.addColumn(sales, sales.invoiceDiscount);
        await m.addColumn(sales, sales.discountType);
        await m.addColumn(sales, sales.loyaltyPointsUsed);
        await m.addColumn(sales, sales.loyaltyPointsEarned);
        await m.addColumn(sales, sales.invoiceNumber);
        await m.addColumn(sales, sales.notes);
        await m.addColumn(sales, sales.cashAmount);
        await m.addColumn(sales, sales.cardAmount);
        await m.addColumn(saleItems, saleItems.originalPrice);
        await m.addColumn(saleItems, saleItems.discount);
        await m.addColumn(saleItems, saleItems.discountType);
        await m.addColumn(saleItems, saleItems.commissionAmount);
        await m.addColumn(customers, customers.loyaltyPoints);
        await m.addColumn(customers, customers.totalPurchases);
        await m.addColumn(customers, customers.customerType);
        await m.addColumn(customers, customers.discountPercent);
        await m.addColumn(customers, customers.birthday);
        await m.addColumn(customers, customers.notes);
        await m.addColumn(employees, employees.phone);
        await m.addColumn(employees, employees.commissionType);
        await m.addColumn(employees, employees.commissionValue);
        await m.addColumn(employees, employees.minSalesTarget);
        await m.addColumn(employees, employees.isAgent);
        await m.addColumn(employees, employees.joiningDate);
      }
      if (from < 8) {
        await m.createTable(commissionRules);
      }
      if (from < 9) {
        await m.addColumn(products, products.minPrice);
      }
      if (from < 10) {
        await m.addColumn(sales, sales.shippingCharges);
        await m.addColumn(sales, sales.agentName);
        await m.addColumn(sales, sales.agentCommission);
      }
      if (from < 11) {
        await m.addColumn(sales, sales.agentCommissionType);
        await m.addColumn(sales, sales.agentCommissionPaid);
      }
      if (from < 12) {
        await m.addColumn(customers, customers.shippingAddress);
        await m.addColumn(sales, sales.shippingAddress);
      }
      if (from < 13) {
        await m.addColumn(products, products.imeis);
        await m.addColumn(saleItems, saleItems.imei);
      }
      if (from < 14) {
        await m.addColumn(customers, customers.vehicleNumber);
      }
    },
  );

  static LazyDatabase _openConnection(String tenantId) {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'tenant_$tenantId.db'));
      return NativeDatabase(file);
    });
  }

  // Close database for a tenant
  static void closeDatabase(String tenantId) {
    final db = _instances.remove(tenantId);
    db?.close();
  }

  // Product operations
  Future<List<Product>> getAllProducts() => select(products).get();
  Future<Product?> getProduct(String id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Inserts a product, replacing any existing row with the same primary key
  /// to prevent UniqueConstraintException during concurrent WS + HTTP pull.
  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product, mode: InsertMode.insertOrReplace);

  Future<bool> updateProduct(ProductsCompanion product) =>
      update(products).replace(product);
  Future<int> deleteProduct(String id) =>
      (delete(products)..where((p) => p.id.equals(id))).go();
  Future<int> markProductSynced(String id) =>
      (update(products)..where((p) => p.id.equals(id))).write(
        const ProductsCompanion(synced: Value(true)),
      );
  Future<List<Product>> getUnsyncedProducts() =>
      (select(products)..where((p) => p.synced.equals(false))).get();

  // Sale operations
  Future<List<Sale>> getAllSales() => select(sales).get();
  Future<Sale?> getSale(String id) =>
      (select(sales)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Inserts a sale, replacing any existing row with the same primary key.
  /// This prevents a UniqueConstraintException when overlapping HTTP sync
  /// cycles attempt to apply the same sale more than once.
  Future<int> insertSale(SalesCompanion sale) =>
      into(sales).insert(sale, mode: InsertMode.insertOrReplace);

  Future<bool> updateSale(SalesCompanion sale) => update(sales).replace(sale);
  Future<int> deleteSale(String id) =>
      (delete(sales)..where((s) => s.id.equals(id))).go();
  Future<int> markSaleSynced(String id) =>
      (update(sales)..where((s) => s.id.equals(id))).write(
        const SalesCompanion(synced: Value(true)),
      );
  Future<List<Sale>> getUnsyncedSales() =>
      (select(sales)..where((s) => s.synced.equals(false))).get();

  Future<int> getSalesCountForToday(
    String locationId,
    String employeeId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = select(sales)
      ..where((s) {
        Expression<bool> filter = s.createdAt.isBiggerOrEqualValue(startOfDay) &
            s.createdAt.isSmallerThanValue(endOfDay);
        if (locationId.isNotEmpty) {
          filter = filter & s.locationId.equals(locationId);
        }
        if (employeeId.isNotEmpty) {
          filter = filter & s.employeeId.equals(employeeId);
        }
        return filter;
      });

    final results = await query.get();
    return results.length;
  }

  // Sale items operations
  Future<List<SaleItem>> getSaleItems(String saleId) =>
      (select(saleItems)..where((si) => si.saleId.equals(saleId))).get();

  /// Inserts a sale item, replacing any existing row with the same primary key
  /// (same dedup protection as insertSale above).
  Future<int> insertSaleItem(SaleItemsCompanion item) =>
      into(saleItems).insert(item, mode: InsertMode.insertOrReplace);

  Future<int> deleteSaleItemsBySaleId(String saleId) =>
      (delete(saleItems)..where((si) => si.saleId.equals(saleId))).go();

  // Customer operations
  Future<List<Customer>> getAllCustomers() => select(customers).get();
  Future<Customer?> getCustomer(String id) =>
      (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Inserts a customer, replacing any existing row with the same primary key.
  Future<int> insertCustomer(CustomersCompanion customer) =>
      into(customers).insert(customer, mode: InsertMode.insertOrReplace);

  Future<bool> updateCustomer(CustomersCompanion customer) =>
      update(customers).replace(customer);
  Future<int> markCustomerSynced(String id) =>
      (update(customers)..where((c) => c.id.equals(id))).write(
        const CustomersCompanion(synced: Value(true)),
      );
  Future<List<Customer>> getUnsyncedCustomers() =>
      (select(customers)..where((c) => c.synced.equals(false))).get();

  // Employee operations
  Future<List<Employee>> getAllEmployees() => select(employees).get();
  Future<Employee?> getEmployee(String id) =>
      (select(employees)..where((e) => e.id.equals(id))).getSingleOrNull();

  /// Inserts an employee, replacing any existing row with the same primary key.
  Future<int> insertEmployee(EmployeesCompanion employee) =>
      into(employees).insert(employee, mode: InsertMode.insertOrReplace);

  Future<bool> updateEmployee(EmployeesCompanion employee) =>
      update(employees).replace(employee);
  Future<int> deleteEmployee(String id) =>
      (delete(employees)..where((e) => e.id.equals(id))).go();
  Future<int> markEmployeeSynced(String id) =>
      (update(employees)..where((e) => e.id.equals(id))).write(
        const EmployeesCompanion(synced: Value(true)),
      );
  Future<List<Employee>> getUnsyncedEmployees() =>
      (select(employees)..where((e) => e.synced.equals(false))).get();

  // ---------------------------------------------------------------------------
  // Sync queue operations
  // ---------------------------------------------------------------------------

  /// Returns all pending sync items that haven't yet exceeded the max retry
  /// count, ordered by creation time (oldest first so the push preserves
  /// causal ordering). Items that already exhausted retries are excluded at
  /// the DB level to avoid loading them into memory on every sync cycle.
  Future<List<SyncQueueData>> getPendingSyncItems({int maxRetries = 6}) =>
      (select(syncQueue)
            ..where((s) => s.retryCount.isSmallerThanValue(maxRetries))
            ..orderBy([
              (s) => OrderingTerm(expression: s.createdAt),
              (s) => OrderingTerm(expression: s.id),
            ]))
          .get();

  /// Appends a sync-queue entry so every local action is preserved.
  ///
  Future<SyncQueueData> enqueueSyncItem(SyncQueueCompanion item) async {
    final insertedId = await into(syncQueue).insert(item);
    return (select(
      syncQueue,
    )..where((s) => s.id.equals(insertedId))).getSingle();
  }

  Future<int> insertSyncItem(SyncQueueCompanion item) =>
      into(syncQueue).insert(item);

  Future<bool> hasQueuedSyncItemForRecord(
    String entityTable,
    String recordId,
  ) async {
    final existing =
        await (select(syncQueue)
              ..where(
                (s) =>
                    s.entityTable.equals(entityTable) &
                    s.recordId.equals(recordId),
              )
              ..limit(1))
            .getSingleOrNull();
    return existing != null;
  }

  Future<SyncQueueData?> getSyncItemByClientOpId(String clientOpId) => (select(
    syncQueue,
  )..where((s) => s.clientOpId.equals(clientOpId))).getSingleOrNull();

  Future<int> deleteSyncItem(int id) =>
      (delete(syncQueue)..where((s) => s.id.equals(id))).go();

  Future<int> incrementRetryCount(int id) async {
    final current = await (select(
      syncQueue,
    )..where((s) => s.id.equals(id))).getSingle();
    return (update(syncQueue)..where((s) => s.id.equals(id))).write(
      SyncQueueCompanion(retryCount: Value(current.retryCount + 1)),
    );
  }

  /// Stamps the current time as [lastRetryAt] and increments [retryCount].
  /// Call this instead of [incrementRetryCount] during actual push attempts
  /// so that exponential back-off windows are measured from the most-recent
  /// send attempt, not from when the item was first queued.
  Future<int> updateSyncItemRetry(int id) async {
    final current = await (select(
      syncQueue,
    )..where((s) => s.id.equals(id))).getSingle();
    return (update(syncQueue)..where((s) => s.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(current.retryCount + 1),
        lastRetryAt: Value(DateTime.now()),
      ),
    );
  }

  /// Resets the retry counter for a single queued item back to 0.
  /// Called after a transient network failure is resolved so the item
  /// is eligible for push again immediately.
  Future<int> resetRetryCount(int id) =>
      (update(syncQueue)..where((s) => s.id.equals(id))).write(
        const SyncQueueCompanion(
          retryCount: Value(0),
          lastRetryAt: Value(null),
        ),
      );

  /// Resets retry counters for ALL queued items back to 0.
  /// Called when the device comes back online after an offline period so that
  /// items which previously exhausted their retry budget are sent on the next
  /// sync cycle rather than being silently abandoned.
  Future<int> resetAllRetryCounts() => update(syncQueue).write(
    const SyncQueueCompanion(retryCount: Value(0), lastRetryAt: Value(null)),
  );

  Future<void> upsertSyncJournalEntry(SyncJournalCompanion entry) async {
    final directionValue = entry.direction.value;
    final clientOpIdValue = entry.clientOpId.present
        ? entry.clientOpId.value
        : null;
    final serverSeqValue = entry.serverSeq.present
        ? entry.serverSeq.value
        : null;

    SyncJournalData? existing;
    if (clientOpIdValue != null && clientOpIdValue.isNotEmpty) {
      existing =
          await (select(syncJournal)
                ..where(
                  (j) =>
                      j.direction.equals(directionValue) &
                      j.clientOpId.equals(clientOpIdValue),
                )
                ..limit(1))
              .getSingleOrNull();
    } else if (serverSeqValue != null) {
      existing =
          await (select(syncJournal)
                ..where(
                  (j) =>
                      j.direction.equals(directionValue) &
                      j.serverSeq.equals(serverSeqValue),
                )
                ..limit(1))
              .getSingleOrNull();
    }

    if (existing != null) {
      final existingEntry = existing;
      await (update(
        syncJournal,
      )..where((j) => j.id.equals(existingEntry.id))).write(
        entry.copyWith(
          createdAt: Value(existingEntry.createdAt),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }

    await into(
      syncJournal,
    ).insert(entry.copyWith(updatedAt: Value(DateTime.now())));
  }

  Future<bool> hasJournalEntryForRecord(
    String entityTable,
    String recordId,
  ) async {
    final entry = await (select(syncJournal)
          ..where(
            (j) =>
                j.entityTable.equals(entityTable) &
                j.recordId.equals(recordId),
          )
          ..limit(1))
        .getSingleOrNull();
    return entry != null;
  }

  Future<List<SyncJournalData>> getSyncJournalEntries({
    String? direction,
    String? status,
    int limit = 200,
  }) {
    final query = select(syncJournal)
      ..orderBy([(j) => OrderingTerm.desc(j.updatedAt)])
      ..limit(limit);

    if (direction != null && direction.isNotEmpty) {
      query.where((j) => j.direction.equals(direction));
    }
    if (status != null && status.isNotEmpty) {
      query.where((j) => j.status.equals(status));
    }

    return query.get();
  }

  // ---------------------------------------------------------------------------
  // Commission log operations
  // ---------------------------------------------------------------------------

  Future<List<CommissionLog>> getCommissionLogs({String? employeeId}) {
    final query = select(commissionLogs)
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]);
    if (employeeId != null) {
      query.where((c) => c.employeeId.equals(employeeId));
    }
    return query.get();
  }

  Future<int> insertCommissionLog(CommissionLogsCompanion log) =>
      into(commissionLogs).insert(log, mode: InsertMode.insertOrReplace);

  // -------------------------------------------------------------------------
  // Commission rule operations
  // -------------------------------------------------------------------------

  Future<List<CommissionRule>> getAllCommissionRules(String tenantId) =>
      (select(
        commissionRules,
      )..where((r) => r.tenantId.equals(tenantId))).get();

  Future<CommissionRule?> getCommissionRule(String id) => (select(
    commissionRules,
  )..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> insertCommissionRule(CommissionRulesCompanion rule) =>
      into(commissionRules).insert(rule, mode: InsertMode.insertOrReplace);

  Future<bool> updateCommissionRule(CommissionRulesCompanion rule) =>
      update(commissionRules).replace(rule);

  Future<int> deleteCommissionRule(String id) =>
      (delete(commissionRules)..where((r) => r.id.equals(id))).go();

  Future<List<CommissionRule>> getActiveRulesForEmployee(
    String tenantId,
    String? employeeId,
  ) {
    final query = select(commissionRules)
      ..where((r) => r.tenantId.equals(tenantId) & r.active.equals(true));
    if (employeeId != null && employeeId.isNotEmpty) {
      query.where(
        (r) => r.employeeId.isNull() | r.employeeId.equals(employeeId),
      );
    }
    return query.get();
  }

  Future<int> markCommissionPaid(String id) =>
      (update(commissionLogs)..where((c) => c.id.equals(id))).write(
        CommissionLogsCompanion(
          isPaid: const Value(true),
          paidAt: Value(DateTime.now()),
        ),
      );

  Future<double> getTotalCommissionByEmployee(String employeeId) async {
    final logs = await (select(
      commissionLogs,
    )..where((c) => c.employeeId.equals(employeeId))).get();
    return logs.fold<double>(0.0, (sum, log) => sum + log.commissionAmount);
  }

  Future<double> getPendingCommissionByEmployee(String employeeId) async {
    final logs =
        await (select(commissionLogs)..where(
              (c) => c.employeeId.equals(employeeId) & c.isPaid.equals(false),
            ))
            .get();
    return logs.fold<double>(0.0, (sum, log) => sum + log.commissionAmount);
  }

  // ---------------------------------------------------------------------------
  // Expense operations
  // ---------------------------------------------------------------------------

  Future<List<Expense>> getAllExpenses() => (select(
    expenses,
  )..orderBy([(e) => OrderingTerm.desc(e.expenseDate)])).get();

  Future<List<Expense>> getExpensesByDateRange(DateTime from, DateTime to) =>
      (select(expenses)
            ..where(
              (e) =>
                  e.expenseDate.isBiggerOrEqualValue(from) &
                  e.expenseDate.isSmallerOrEqualValue(to),
            )
            ..orderBy([(e) => OrderingTerm.desc(e.expenseDate)]))
          .get();

  Future<Expense?> getExpense(String id) =>
      (select(expenses)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense, mode: InsertMode.insertOrReplace);

  Future<bool> updateExpense(ExpensesCompanion expense) =>
      update(expenses).replace(expense);

  Future<int> deleteExpense(String id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();

  Future<List<Expense>> getUnsyncedExpenses() =>
      (select(expenses)..where((e) => e.synced.equals(false))).get();

  Future<int> markExpenseSynced(String id) =>
      (update(expenses)..where((e) => e.id.equals(id)))
          .write(const ExpensesCompanion(synced: Value(true)));

  Future<double> getTotalExpensesForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final list = await getExpensesByDateRange(start, end);
    return list.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  // ---------------------------------------------------------------------------
  // Discount operations
  // ---------------------------------------------------------------------------

  Future<List<Discount>> getAllDiscounts() =>
      (select(discounts)..where((d) => d.isActive.equals(true))).get();

  Future<int> insertDiscount(DiscountsCompanion discount) =>
      into(discounts).insert(discount, mode: InsertMode.insertOrReplace);

  Future<bool> updateDiscount(DiscountsCompanion discount) =>
      update(discounts).replace(discount);

  Future<int> deleteDiscount(String id) =>
      (delete(discounts)..where((d) => d.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Loyalty ledger operations
  // ---------------------------------------------------------------------------

  Future<List<LoyaltyLedgerData>> getLoyaltyHistory(String customerId) =>
      (select(loyaltyLedger)
            ..where((l) => l.customerId.equals(customerId))
            ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
          .get();

  Future<int> insertLoyaltyEntry(LoyaltyLedgerCompanion entry) =>
      into(loyaltyLedger).insert(entry, mode: InsertMode.insertOrReplace);

  Future<double> getTotalLoyaltyPoints(String customerId) async {
    final entries = await getLoyaltyHistory(customerId);
    double total = 0;
    for (final e in entries) {
      if (e.type == 'EARN' || e.type == 'ADJUST') {
        total += e.points;
      } else if (e.type == 'REDEEM') {
        total -= e.points;
      }
    }
    return total < 0 ? 0 : total;
  }

  // ---------------------------------------------------------------------------
  // Print settings operations
  // ---------------------------------------------------------------------------

  Future<PrintSetting?> getPrintSettings(String tenantId) => (select(
    printSettings,
  )..where((p) => p.tenantId.equals(tenantId))).getSingleOrNull();

  Future<int> upsertPrintSettings(PrintSettingsCompanion settings) =>
      into(printSettings).insert(settings, mode: InsertMode.insertOrReplace);
}
