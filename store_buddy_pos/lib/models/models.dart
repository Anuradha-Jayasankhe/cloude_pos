import 'dart:convert';
import 'package:drift/drift.dart';

import '../database/database.dart';

class Product {
  final String id;
  final String tenantId;
  final String name;
  final String description;
  final String? sku;
  final String? barcode;
  final double price;
  final double? costPrice;
  final double minPrice;
  final String category;
  final String type; // 'PRODUCT' | 'SERVICE' | 'REPAIR'
  final String unitOfMeasure; // 'PIECE' | 'KG' | 'LITER' | 'METER'
  final double stock;
  final double minStock;
  final int warrantyMonths;
  final DateTime? expiryDate;
  final String? locationId;
  final String supplierId;
  final String? imeis;
  final String? imageUrl;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description = '',
    this.sku,
    this.barcode,
    required this.price,
    this.costPrice,
    this.minPrice = 0.0,
    required this.category,
    required this.type,
    required this.unitOfMeasure,
    required this.stock,
    required this.minStock,
    this.warrantyMonths = 0,
    this.expiryDate,
    this.locationId,
    this.supplierId = '',
    this.imeis,
    this.imageUrl,
    required this.synced,
    this.createdAt,
    this.updatedAt,
  });

  List<String> get imeiList {
    if (imeis == null || imeis!.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(imeis!);
      if (decoded is List) {
        return List<String>.from(decoded);
      }
    } catch (_) {}
    return [];
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'],
      tenantId: json['tenantId'],
      name: json['name'],
      description: json['description']?.toString() ?? '',
      sku: json['sku'],
      barcode: json['barcode'],
      price: (json['price'] as num).toDouble(),
      costPrice: json['costPrice'] != null
          ? (json['costPrice'] as num).toDouble()
          : null,
      minPrice: json['minPrice'] != null ? (json['minPrice'] as num).toDouble() : 0.0,
      category: json['category'],
      type: json['type'],
      unitOfMeasure: json['unitOfMeasure'],
      stock: (json['stock'] as num).toDouble(),
      minStock: (json['minStock'] as num).toDouble(),
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt() ?? 0,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      locationId: json['locationId'],
      supplierId: (json['supplierId'] ?? '').toString(),
      imeis: json['imeis']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      synced: json['synced'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  ProductsCompanion toCompanion() {
    return ProductsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      description: Value(description),
      sku: Value(sku),
      barcode: Value(barcode),
      price: Value(price),
      costPrice: Value(costPrice),
      minPrice: Value(minPrice),
      category: Value(category),
      type: Value(type),
      unitOfMeasure: Value(unitOfMeasure),
      stock: Value(stock),
      minStock: Value(minStock),
      warrantyMonths: Value(warrantyMonths),
      expiryDate: Value(expiryDate),
      locationId: Value(locationId),
      supplierId: Value(supplierId),
      imeis: Value(imeis),
      imageUrl: Value(imageUrl),
      synced: Value(synced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tenantId': tenantId,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'costPrice': costPrice,
      'minPrice': minPrice,
      'category': category,
      'type': type,
      'unitOfMeasure': unitOfMeasure,
      'stock': stock,
      'minStock': minStock,
      'warrantyMonths': warrantyMonths,
      'expiryDate': expiryDate?.toIso8601String(),
      'locationId': locationId,
      'supplierId': supplierId,
      'imeis': imeis,
      'imageUrl': imageUrl,
      'synced': synced,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class Sale {
  final String id;
  final String tenantId;
  final String? customerId;
  final String employeeId;
  final String? invoiceNumber;
  final String? cashierName;
  final double? customerOutstandingBefore;
  final double? customerOutstandingAfter;
  final double total;
  final double tax;
  final double discount;
  final double? amountPaid;
  final double? balance;
  final String paymentMethod; // 'CASH' | 'CARD' | 'CHEQUE' | 'INSTALLMENT'
  final String status; // 'COMPLETED' | 'RETURNED' | 'CANCELLED'
  final String locationId;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double shippingCharges;
  final String? agentName;
  final double agentCommission;
  final String agentCommissionType; // 'PERCENT' | 'FIXED'
  final bool agentCommissionPaid;
  final List<SaleItem> items;
  final Customer? customer;
  final List<InstallmentPaymentLine> installmentSchedules;
  final String? notes;

  final String? shippingAddress;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final String? deliveryStatus;
  final DateTime? deliveredAt;
  final String? deliveryOtp;
  final DateTime? settledAt;
  final String? settledByEmployeeId;
  final String? settledByCashierName;

  Sale({
    required this.id,
    required this.tenantId,
    this.customerId,
    required this.employeeId,
    this.invoiceNumber,
    this.cashierName,
    this.customerOutstandingBefore,
    this.customerOutstandingAfter,
    required this.total,
    required this.tax,
    required this.discount,
    this.amountPaid,
    this.balance,
    required this.paymentMethod,
    required this.status,
    required this.locationId,
    required this.synced,
    this.createdAt,
    this.updatedAt,
    this.shippingCharges = 0.0,
    this.agentName,
    this.agentCommission = 0.0,
    this.agentCommissionType = 'PERCENT',
    this.agentCommissionPaid = false,
    required this.items,
    this.customer,
    this.installmentSchedules = const [],
    this.notes = '',
    this.shippingAddress,
    this.deliveryPersonId,
    this.deliveryPersonName,
    this.deliveryStatus,
    this.deliveredAt,
    this.deliveryOtp,
    this.settledAt,
    this.settledByEmployeeId,
    this.settledByCashierName,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      tenantId: (json['tenantId'] ?? '').toString(),
      customerId: json['customerId']?.toString(),
      employeeId: (json['employeeId'] ?? '').toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      cashierName: json['cashierName']?.toString(),
      customerOutstandingBefore: (json['customerOutstandingBefore'] as num?)
          ?.toDouble(),
      customerOutstandingAfter: (json['customerOutstandingAfter'] as num?)
          ?.toDouble(),
      total: (json['total'] as num? ?? 0).toDouble(),
      tax: (json['tax'] as num? ?? 0).toDouble(),
      discount: (json['discount'] as num? ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      balance: (json['balance'] as num?)?.toDouble(),
      paymentMethod: (json['paymentMethod'] ?? 'CASH').toString(),
      status: (json['status'] ?? 'COMPLETED').toString(),
      // locationId may be null on old server records – fall back to empty string
      // so _passesLocationScope treats it as "no restriction".
      locationId: (json['locationId'] ?? '').toString(),
      synced: json['synced'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      shippingCharges: (json['shippingCharges'] as num? ?? 0.0).toDouble(),
      agentName: json['agentName']?.toString(),
      agentCommission: (json['agentCommission'] as num? ?? 0.0).toDouble(),
      agentCommissionType: (json['agentCommissionType'] as String? ?? 'PERCENT'),
      agentCommissionPaid: json['agentCommissionPaid'] as bool? ?? false,
      notes: json['notes']?.toString() ?? '',
      shippingAddress: json['shippingAddress']?.toString(),
      deliveryPersonId: json['deliveryPersonId']?.toString(),
      deliveryPersonName: json['deliveryPersonName']?.toString(),
      deliveryStatus: json['deliveryStatus']?.toString(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
      deliveryOtp: json['deliveryOtp']?.toString(),
      settledAt: json['settledAt'] != null
          ? DateTime.tryParse(json['settledAt'].toString())
          : null,
      settledByEmployeeId: json['settledByEmployeeId']?.toString(),
      settledByCashierName: json['settledByCashierName']?.toString(),
      items:
          (json['items'] as List?)
              ?.map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      installmentSchedules:
          (json['installmentSchedules'] as List?)
              ?.map(
                (item) => InstallmentPaymentLine.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }

  SalesCompanion toCompanion() {
    return SalesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      customerId: Value(customerId),
      employeeId: Value(employeeId),
      invoiceNumber: Value(invoiceNumber),
      total: Value(total),
      subtotal: Value(total + discount - tax),
      tax: Value(tax),
      discount: Value(discount),
      paymentMethod: Value(paymentMethod),
      status: Value(status),
      locationId: Value(locationId),
      shippingCharges: Value(shippingCharges),
      agentName: Value(agentName),
      agentCommission: Value(agentCommission),
      agentCommissionType: Value(agentCommissionType),
      agentCommissionPaid: Value(agentCommissionPaid),
      synced: Value(synced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      notes: Value(notes),
      shippingAddress: Value(shippingAddress),
    );
  }

  /// Serialises this sale to a plain map for JSON encoding.
  /// Used when persisting synced sales to SharedPreferences workspace state.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'tenantId': tenantId,
      'customerId': customerId,
      'employeeId': employeeId,
      'invoiceNumber': invoiceNumber,
      'cashierName': cashierName,
      'customerOutstandingBefore': customerOutstandingBefore,
      'customerOutstandingAfter': customerOutstandingAfter,
      'total': total,
      'tax': tax,
      'discount': discount,
      'amountPaid': amountPaid,
      'balance': balance,
      'paymentMethod': paymentMethod,
      'status': status,
      'locationId': locationId,
      'synced': synced,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'shippingCharges': shippingCharges,
      'agentName': agentName,
      'agentCommission': agentCommission,
      'agentCommissionType': agentCommissionType,
      'agentCommissionPaid': agentCommissionPaid,
      'notes': notes ?? '',
      'shippingAddress': shippingAddress,
      'deliveryPersonId': deliveryPersonId,
      'deliveryPersonName': deliveryPersonName,
      'deliveryStatus': deliveryStatus,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'deliveryOtp': deliveryOtp,
      'settledAt': settledAt?.toIso8601String(),
      'settledByEmployeeId': settledByEmployeeId,
      'settledByCashierName': settledByCashierName,
      'installmentSchedules': installmentSchedules
          .map((item) => item.toJson())
          .toList(),
      'items': items
          .map(
            (i) => {
              'id': i.id,
              'saleId': i.saleId,
              'productId': i.productId,
              'productName': i.productName,
              'quantity': i.quantity,
              'unitPrice': i.unitPrice,
              'total': i.total,
              'tenantId': i.tenantId,
              'imei': i.imei,
            },
          )
          .toList(),
    };
  }
}

class InstallmentPaymentLine {
  final int installmentNo;
  final DateTime dueDate;
  final double scheduledAmount;
  final double paidAmount;
  final double remainingAmount;
  final bool isPaid;

  const InstallmentPaymentLine({
    required this.installmentNo,
    required this.dueDate,
    required this.scheduledAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.isPaid,
  });

  Map<String, dynamic> toJson() {
    return {
      'installmentNo': installmentNo,
      'dueDate': dueDate.toIso8601String(),
      'scheduledAmount': scheduledAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'isPaid': isPaid,
    };
  }

  factory InstallmentPaymentLine.fromJson(Map<String, dynamic> json) {
    return InstallmentPaymentLine(
      installmentNo: (json['installmentNo'] as num?)?.toInt() ?? 1,
      dueDate:
          DateTime.tryParse((json['dueDate'] ?? '').toString()) ??
          DateTime.now(),
      scheduledAmount: (json['scheduledAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }
}

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice; // After discount
  final double originalPrice;
  final double discount;
  final String discountType; // 'FIXED' | 'PERCENT'
  final double total;
  final String tenantId;
  final String? imei;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.originalPrice = 0.0,
    this.discount = 0.0,
    this.discountType = 'FIXED',
    required this.total,
    required this.tenantId,
    this.imei,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      saleId: (json['saleId'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? 'Unknown').toString(),
      quantity: (json['quantity'] as num? ?? 1).toDouble(),
      unitPrice: (json['unitPrice'] as num? ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discountType'] as String? ?? 'FIXED',
      total: (json['total'] as num? ?? 0).toDouble(),
      tenantId: (json['tenantId'] ?? '').toString(),
      imei: json['imei']?.toString(),
    );
  }

  SaleItemsCompanion toCompanion() {
    return SaleItemsCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      originalPrice: Value(originalPrice),
      discount: Value(discount),
      discountType: Value(discountType),
      total: Value(total),
      tenantId: Value(tenantId),
      imei: Value(imei),
    );
  }
}

class Customer {
  final String id;
  final String tenantId;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? vehicleNumber;
  final double creditLimit;
  final double currentBalance;
  final String customerType;
  final double discountPercent;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? shippingAddress;

  Customer({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.vehicleNumber,
    required this.creditLimit,
    required this.currentBalance,
    this.customerType = 'RETAIL',
    this.discountPercent = 0.0,
    required this.synced,
    this.createdAt,
    this.updatedAt,
    this.shippingAddress,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? json['id'],
      tenantId: json['tenantId'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      vehicleNumber: json['vehicleNumber']?.toString(),
      creditLimit: (json['creditLimit'] as num? ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] as num? ?? 0).toDouble(),
      customerType: json['customerType'] as String? ?? 'RETAIL',
      discountPercent: (json['discountPercent'] as num? ?? 0).toDouble(),
      synced: json['synced'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      shippingAddress: json['shippingAddress']?.toString(),
    );
  }

  CustomersCompanion toCompanion() {
    return CustomersCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      phone: Value(phone),
      email: Value(email),
      address: Value(address),
      vehicleNumber: Value(vehicleNumber),
      creditLimit: Value(creditLimit),
      currentBalance: Value(currentBalance),
      customerType: Value(customerType),
      discountPercent: Value(discountPercent),
      synced: Value(synced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      shippingAddress: Value(shippingAddress),
    );
  }
}

class Employee {
  final String id;
  final String tenantId;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'OWNER' | 'MANAGER' | 'CASHIER' | 'TECHNICIAN' | 'AGENT'
  final String locationId;
  final String
  commissionType; // 'NONE' | 'FIXED' | 'PERCENT' | 'PRODUCT' | 'CATEGORY'
  final double commissionValue;
  final double minSalesTarget;
  final bool isAgent;
  final DateTime? joiningDate;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Employee({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.locationId,
    this.commissionType = 'NONE',
    this.commissionValue = 0,
    this.minSalesTarget = 0,
    this.isAgent = false,
    this.joiningDate,
    required this.synced,
    this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] ?? json['id'],
      tenantId: json['tenantId'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      locationId: json['locationId'],
      commissionType: json['commissionType'] ?? 'NONE',
      commissionValue: (json['commissionValue'] as num? ?? 0).toDouble(),
      minSalesTarget: (json['minSalesTarget'] as num? ?? 0).toDouble(),
      isAgent: json['isAgent'] ?? false,
      joiningDate: json['joiningDate'] != null
          ? DateTime.tryParse(json['joiningDate'])
          : null,
      synced: json['synced'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  EmployeesCompanion toCompanion() {
    return EmployeesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      email: Value(email),
      phone: Value(phone),
      role: Value(role),
      locationId: Value(locationId),
      commissionType: Value(commissionType),
      commissionValue: Value(commissionValue),
      minSalesTarget: Value(minSalesTarget),
      isAgent: Value(isAgent),
      joiningDate: Value(joiningDate),
      synced: Value(synced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

// ---------------------------------------------------------------------------
// Commission Log Model
// ---------------------------------------------------------------------------
class CommissionLogModel {
  final String id;
  final String tenantId;
  final String saleId;
  final String employeeId;
  final String? productId;
  final double saleAmount;
  final double commissionAmount;
  final String commissionType;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime? createdAt;

  CommissionLogModel({
    required this.id,
    required this.tenantId,
    required this.saleId,
    required this.employeeId,
    this.productId,
    required this.saleAmount,
    required this.commissionAmount,
    required this.commissionType,
    this.isPaid = false,
    this.paidAt,
    this.createdAt,
  });

  factory CommissionLogModel.fromJson(Map<String, dynamic> json) {
    return CommissionLogModel(
      id: json['_id'] ?? json['id'],
      tenantId: json['tenantId'] ?? '',
      saleId: json['saleId'] ?? '',
      employeeId: json['employeeId'] ?? '',
      productId: json['productId'],
      saleAmount: (json['saleAmount'] as num? ?? 0).toDouble(),
      commissionAmount: (json['commissionAmount'] as num? ?? 0).toDouble(),
      commissionType: json['commissionType'] ?? 'PERCENT',
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  CommissionLogsCompanion toCompanion() {
    return CommissionLogsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      saleId: Value(saleId),
      employeeId: Value(employeeId),
      productId: Value(productId),
      saleAmount: Value(saleAmount),
      commissionAmount: Value(commissionAmount),
      commissionType: Value(commissionType),
      isPaid: Value(isPaid),
      paidAt: Value(paidAt),
      createdAt: Value(createdAt),
    );
  }
}

// ---------------------------------------------------------------------------
// Expense Model
// ---------------------------------------------------------------------------
class ExpenseModel {
  final String id;
  final String tenantId;
  final String category;
  final String description;
  final double amount;
  final String? employeeId;
  final String? locationId;
  final String? notes;
  final DateTime expenseDate;
  final bool synced;
  final DateTime? createdAt;

  const ExpenseModel({
    required this.id,
    required this.tenantId,
    required this.category,
    this.description = '',
    required this.amount,
    this.employeeId,
    this.locationId,
    this.notes,
    required this.expenseDate,
    this.synced = false,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'] ?? json['id'],
      tenantId: json['tenantId'] ?? '',
      category: json['category'] ?? 'OTHER',
      description: json['description'] ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      employeeId: json['employeeId'],
      locationId: json['locationId'],
      notes: json['notes'],
      expenseDate: json['expenseDate'] != null
          ? DateTime.parse(json['expenseDate'])
          : DateTime.now(),
      synced: json['synced'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  ExpensesCompanion toCompanion() {
    return ExpensesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      category: Value(category),
      description: Value(description),
      amount: Value(amount),
      employeeId: Value(employeeId),
      locationId: Value(locationId),
      notes: Value(notes),
      expenseDate: Value(expenseDate),
      synced: Value(synced),
      createdAt: Value(createdAt),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'tenantId': tenantId,
    'category': category,
    'description': description,
    'amount': amount,
    'employeeId': employeeId,
    'locationId': locationId,
    'notes': notes,
    'expenseDate': expenseDate.toIso8601String(),
    'synced': synced,
    'createdAt': createdAt?.toIso8601String(),
  };
}

// ---------------------------------------------------------------------------
// Print Settings Model
// ---------------------------------------------------------------------------
class PrintSettingsModel {
  final String id;
  final String tenantId;
  final String paperSize; // '58mm' | '80mm' | 'A4'
  final String? printerName;
  final String printerType; // 'THERMAL' | 'A4' | 'DEFAULT'
  final String invoiceTemplate; // 'COMPACT' | 'PROFESSIONAL' | 'MODERN'
  final bool autoPrint;
  final bool showLogo;
  final bool showBarcode;
  final bool showQr;
  final bool showTax;
  final bool showDiscount;
  final bool showCustomerAddress;
  final double marginTop;
  final double marginLeft;
  final double fontSize;
  final double lineSpacing;
  final String thankYouMessage;
  final String? returnPolicy;
  final String? socialLinks;

  // Layout & structure toggles
  final bool showShopHeader;
  final bool showInvoiceNumber;
  final bool showDateTime;
  final bool showCashierName;
  final bool showCustomerName;
  final bool showItemTable;
  final bool showItemNumbers;
  final bool showSubtotal;
  final bool showTotal;
  final bool showPaymentDetails;
  final bool showFooter;
  final bool showTerms;
  final bool showSlogan;
  final String? invoiceSlogan;
  final String? invoiceTerms;
  final double? paperWidthMm;
  final double? marginVerticalMm;
  final double? marginHorizontalMm;
  final String receiptLanguage;
  final String deliveryNoteFormat; // 'THERMAL_80MM' | 'THERMAL_58MM' | 'A4'
  final String? deliveryNotePrinterName;

  const PrintSettingsModel({
    required this.id,
    required this.tenantId,
    this.paperSize = '80mm',
    this.printerName,
    this.printerType = 'THERMAL',
    this.invoiceTemplate = 'PROFESSIONAL',
    this.autoPrint = false,
    this.showLogo = true,
    this.showBarcode = false,
    this.showQr = true,
    this.showTax = true,
    this.showDiscount = true,
    this.showCustomerAddress = false,
    this.marginTop = 10,
    this.marginLeft = 10,
    this.fontSize = 10,
    this.lineSpacing = 1.2,
    this.thankYouMessage = 'Thank you for your business!',
    this.returnPolicy,
    this.socialLinks,
    this.showShopHeader = true,
    this.showInvoiceNumber = true,
    this.showDateTime = true,
    this.showCashierName = true,
    this.showCustomerName = true,
    this.showItemTable = true,
    this.showItemNumbers = true,
    this.showSubtotal = true,
    this.showTotal = true,
    this.showPaymentDetails = true,
    this.showFooter = true,
    this.showTerms = true,
    this.showSlogan = false,
    this.invoiceSlogan,
    this.invoiceTerms,
    this.paperWidthMm,
    this.marginVerticalMm,
    this.marginHorizontalMm,
    this.receiptLanguage = 'en',
    this.deliveryNoteFormat = 'THERMAL_80MM',
    this.deliveryNotePrinterName,
  });

  PrintSettingsCompanion toCompanion() {
    return PrintSettingsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      paperSize: Value(paperSize),
      printerName: Value(printerName),
      printerType: Value(printerType),
      invoiceTemplate: Value(invoiceTemplate),
      autoPrint: Value(autoPrint),
      showLogo: Value(showLogo),
      showBarcode: Value(showBarcode),
      showQr: Value(showQr),
      showTax: Value(showTax),
      showDiscount: Value(showDiscount),
      showCustomerAddress: Value(showCustomerAddress),
      marginTop: Value(marginTop),
      marginLeft: Value(marginLeft),
      fontSize: Value(fontSize),
      lineSpacing: Value(lineSpacing),
      thankYouMessage: Value(thankYouMessage),
      returnPolicy: Value(returnPolicy),
      socialLinks: Value(socialLinks),
      updatedAt: Value(DateTime.now()),
    );
  }
}

// ---------------------------------------------------------------------------
// User model (unchanged)
// ---------------------------------------------------------------------------
class User {
  final String id;
  final String tenantId;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final List<String> locationIds;
  final int maxLocations;
  final String? token;
  final String? refreshToken;

  User({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.locationIds = const [],
    this.maxLocations = 100,
    this.token,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      tenantId: json['tenantId'] ?? '',
      name: json['name'],
      email: json['email'],
      role: json['role'],
      isActive: json['isActive'] ?? true,
      locationIds:
          (json['location_ids'] as List<dynamic>? ??
                  json['locationIds'] as List<dynamic>? ??
                  const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
      maxLocations:
          (json['max_locations'] as num?)?.toInt() ??
          (json['maxLocations'] as num?)?.toInt() ??
          100,
      token: json['token'],
      refreshToken: json['refreshToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tenantId': tenantId,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'locationIds': locationIds,
      'maxLocations': maxLocations,
      'token': token,
      'refreshToken': refreshToken,
    };
  }
}
