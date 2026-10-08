import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/database.dart' as db;
import '../models/models.dart' as models;

class CommissionRule {
  final String id;
  final String name;
  final String commissionType;
  final double value;
  final bool active;
  final List<String> productIds;
  final List<String> employeeIds;
  final String? category;

  const CommissionRule({
    required this.id,
    required this.name,
    required this.commissionType,
    required this.value,
    required this.active,
    this.productIds = const [],
    this.employeeIds = const [],
    this.category,
  });

  bool appliesToProduct(models.SaleItem item, db.Product? product) {
    if (!active) return false;
    final normalizedProductIds = productIds.map((e) => e.trim()).toSet();

    if (normalizedProductIds.isNotEmpty) {
      if (!normalizedProductIds.contains(item.productId.trim())) {
        return false;
      }
    } else if ((category ?? '').trim().isNotEmpty) {
      final productCategory = (product?.category ?? '').trim().toLowerCase();
      if (productCategory != category!.trim().toLowerCase()) {
        return false;
      }
    }

    final normalizedType = commissionType.trim().toUpperCase();
    return normalizedType == 'PERCENT' || normalizedType == 'FIXED';
  }

  double commissionFor(models.SaleItem item) {
    final normalizedType = commissionType.trim().toUpperCase();
    if (normalizedType == 'PERCENT') {
      return (item.total * value) / 100.0;
    }
    return value * item.quantity;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'commissionType': commissionType,
    'value': value,
    'active': active,
    'productIds': productIds,
    'employeeIds': employeeIds,
    'category': category,
  };

  factory CommissionRule.fromJson(Map<String, dynamic> json) {
    return CommissionRule(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      commissionType: (json['commissionType'] ?? 'PERCENT').toString(),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ?? true,
      productIds: (json['productIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      employeeIds: (json['employeeIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      category: json['category']?.toString(),
    );
  }
}

class CommissionService {
  CommissionService(this._database);

  final db.AppDatabase _database;

  Future<List<CommissionRule>> getRules(String tenantId) async {
    final rows = await _database.getAllCommissionRules(tenantId);
    return rows
        .map(
          (r) => CommissionRule(
            id: r.id,
            name: r.name,
            commissionType: r.ruleType,
            value: r.value,
            active: r.active,
            productIds: _splitIds(r.productId),
            employeeIds: _splitIds(r.employeeId),
            category: r.category,
          ),
        )
        .toList();
  }

  Future<void> upsertRule(String tenantId, CommissionRule rule) async {
    final existing = await _database.getCommissionRule(rule.id);
    final companion = db.CommissionRulesCompanion(
      id: Value(rule.id),
      tenantId: Value(tenantId),
      name: Value(rule.name),
      ruleType: Value(rule.commissionType.toUpperCase()),
      value: Value(rule.value),
      productId: Value(_joinIds(rule.productIds)),
      category: Value(rule.category),
      employeeId: Value(_joinIds(rule.employeeIds)),
      active: Value(rule.active),
      synced: const Value(false),
      createdAt: Value(DateTime.now().toUtc()),
      updatedAt: Value(DateTime.now().toUtc()),
    );
    await _database.insertCommissionRule(companion);
    // Enqueue sync operation for the rule (INSERT or UPDATE)
    final action = existing == null ? 'INSERT' : 'UPDATE';
    final payload = {...rule.toJson(), 'tenantId': tenantId};
    final syncComp = db.SyncQueueCompanion(
      operation: Value(action),
      entityTable: Value('commission_rules'),
      recordId: Value(rule.id),
      clientOpId: const Value(null),
      data: Value(jsonEncode(payload)),
      createdAt: Value(DateTime.now().toUtc()),
    );
    try {
      await _database.enqueueSyncItem(syncComp);
    } catch (_) {}
  }

  Future<void> deleteRule(String tenantId, String ruleId) async {
    await _database.deleteCommissionRule(ruleId);
    final syncComp = db.SyncQueueCompanion(
      operation: Value('DELETE'),
      entityTable: Value('commission_rules'),
      recordId: Value(ruleId),
      clientOpId: const Value(null),
      data: Value(jsonEncode({'id': ruleId, 'tenantId': tenantId})),
      createdAt: Value(DateTime.now().toUtc()),
    );
    try {
      await _database.enqueueSyncItem(syncComp);
    } catch (_) {}
  }

  Future<void> recordCommissionsForSale(models.Sale sale) async {
    final rules = await getRules(sale.tenantId);
    if (rules.isEmpty) return;

    final employeeId = sale.employeeId.trim();
    if (employeeId.isEmpty) return;

    final eligibleRules = rules.where((rule) {
      if (!rule.active) return false;
      final employeeIds = rule.employeeIds.map((e) => e.trim()).toSet();
      return employeeIds.isEmpty || employeeIds.contains(employeeId);
    }).toList();

    if (eligibleRules.isEmpty) return;

    final productsById = <String, db.Product>{};
    for (final item in sale.items) {
      if (item.productId.startsWith('SV:')) continue;
      final product = await _database.getProduct(item.productId);
      if (product != null) {
        productsById[item.productId] = product;
      }
    }

    for (final item in sale.items) {
      final product = productsById[item.productId];
      for (final rule in eligibleRules) {
        if (!rule.appliesToProduct(item, product)) continue;

        final commissionAmount = double.parse(
          rule.commissionFor(item).toStringAsFixed(2),
        );
        if (commissionAmount <= 0) continue;

        final logId = 'CL-${sale.id}-$employeeId-${item.productId}-${rule.id}';
        await _database.insertCommissionLog(
          db.CommissionLogsCompanion(
            id: Value(logId),
            tenantId: Value(sale.tenantId),
            saleId: Value(sale.id),
            employeeId: Value(employeeId),
            productId: Value(item.productId),
            saleAmount: Value(item.total),
            commissionAmount: Value(commissionAmount),
            commissionType: Value(rule.commissionType.toUpperCase()),
            isPaid: const Value(false),
            createdAt: Value(DateTime.now().toUtc()),
          ),
        );
        // Enqueue sync for the commission log
        final payload = {
          'id': logId,
          'tenantId': sale.tenantId,
          'saleId': sale.id,
          'employeeId': employeeId,
          'productId': item.productId,
          'saleAmount': item.total,
          'commissionAmount': commissionAmount,
          'commissionType': rule.commissionType.toUpperCase(),
          'isPaid': false,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        };
        final syncComp = db.SyncQueueCompanion(
          operation: Value('INSERT'),
          entityTable: Value('commission_logs'),
          recordId: Value(logId),
          clientOpId: const Value(null),
          data: Value(jsonEncode(payload)),
          createdAt: Value(DateTime.now().toUtc()),
        );
        try {
          await _database.enqueueSyncItem(syncComp);
        } catch (_) {}
      }
    }
  }

  static List<String> _splitIds(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return const [];
    return value
        .split(RegExp(r'[|,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String? _joinIds(List<String> ids) {
    final filtered = ids
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (filtered.isEmpty) return null;
    return filtered.join('|');
  }
}
