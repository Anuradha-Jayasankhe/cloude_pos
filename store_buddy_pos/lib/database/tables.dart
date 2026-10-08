import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  RealColumn get price => real()();
  RealColumn get costPrice => real().nullable()();
  TextColumn get category => text()();
  TextColumn get type => text()(); // 'PRODUCT' | 'SERVICE' | 'REPAIR'
  TextColumn get unitOfMeasure =>
      text()(); // 'PIECE' | 'KG' | 'LITER' | 'METER'
  RealColumn get stock => real().withDefault(const Constant(0))();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  RealColumn get reorderLevel => real().withDefault(const Constant(0))();
  IntColumn get warrantyMonths => integer().withDefault(const Constant(0))();
  TextColumn get locationId => text().nullable()();
  TextColumn get supplierId => text().withDefault(const Constant(''))();
  TextColumn get batchNumber => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  // Commission fields
  BoolColumn get commissionEligible =>
      boolean().withDefault(const Constant(false))();
  RealColumn get agentCommissionPercent =>
      real().withDefault(const Constant(0))();
  RealColumn get bonusCommission => real().withDefault(const Constant(0))();
  // Calculated profit margin (stored for quick access)
  RealColumn get profitMargin => real().withDefault(const Constant(0))();
  // Minimum selling price
  RealColumn get minPrice => real().withDefault(const Constant(0.0))();
  // Image URL or local path
  TextColumn get imageUrl => text().nullable()();
  TextColumn get imeis => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get employeeId => text()();
  RealColumn get total => real()();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  // Invoice-level discount (separate from line-item discounts)
  RealColumn get invoiceDiscount => real().withDefault(const Constant(0))();
  TextColumn get discountType =>
      text().withDefault(const Constant('FIXED'))(); // 'FIXED' | 'PERCENT'
  // Loyalty points
  RealColumn get loyaltyPointsUsed => real().withDefault(const Constant(0))();
  RealColumn get loyaltyPointsEarned => real().withDefault(const Constant(0))();
  // Invoice metadata
  TextColumn get invoiceNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get paymentMethod =>
      text()(); // 'CASH' | 'CARD' | 'CHEQUE' | 'INSTALLMENT' | 'SPLIT'
  // Split payment amounts
  RealColumn get cashAmount => real().withDefault(const Constant(0))();
  RealColumn get cardAmount => real().withDefault(const Constant(0))();
  TextColumn get status =>
      text()(); // 'COMPLETED' | 'RETURNED' | 'CANCELLED' | 'HELD'
  TextColumn get locationId => text()();
  RealColumn get shippingCharges => real().withDefault(const Constant(0.0))();
  TextColumn get agentName => text().nullable()();
  RealColumn get agentCommission => real().withDefault(const Constant(0.0))();
  TextColumn get agentCommissionType =>
      text().withDefault(const Constant('PERCENT'))();
  BoolColumn get agentCommissionPaid =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get shippingAddress => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get originalPrice => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  TextColumn get discountType =>
      text().withDefault(const Constant('FIXED'))(); // 'FIXED' | 'PERCENT'
  RealColumn get total => real()();
  RealColumn get commissionAmount => real().withDefault(const Constant(0))();
  TextColumn get tenantId => text()();
  TextColumn get imei => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get vehicleNumber => text().nullable()();
  RealColumn get creditLimit => real().withDefault(const Constant(0))();
  RealColumn get currentBalance => real().withDefault(const Constant(0))();
  // Loyalty & Type
  RealColumn get loyaltyPoints => real().withDefault(const Constant(0))();
  RealColumn get totalPurchases => real().withDefault(const Constant(0))();
  TextColumn get customerType => text().withDefault(
    const Constant('RETAIL'),
  )(); // 'RETAIL' | 'WHOLESALE' | 'VIP'
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  DateTimeColumn get birthday => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get shippingAddress => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Employees extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get role =>
      text()(); // 'OWNER' | 'MANAGER' | 'CASHIER' | 'TECHNICIAN' | 'AGENT'
  TextColumn get locationId => text()();
  // Commission fields
  TextColumn get commissionType => text().withDefault(
    const Constant('NONE'),
  )(); // 'NONE' | 'FIXED' | 'PERCENT' | 'PRODUCT' | 'CATEGORY'
  RealColumn get commissionValue => real().withDefault(const Constant(0))();
  RealColumn get minSalesTarget => real().withDefault(const Constant(0))();
  BoolColumn get isAgent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get joiningDate => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks commission earned per sale/employee/product
class CommissionLogs extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get saleId => text()();
  TextColumn get employeeId => text()();
  TextColumn get productId => text().nullable()();
  RealColumn get saleAmount => real().withDefault(const Constant(0))();
  RealColumn get commissionAmount => real()();
  TextColumn get commissionType =>
      text()(); // 'FIXED' | 'PERCENT' | 'PRODUCT' | 'CATEGORY'
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get paidAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Flexible commission rule definitions stored per-tenant.
class CommissionRules extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  TextColumn get ruleType =>
      text()(); // 'PERCENT' | 'FIXED' | 'PRODUCT' | 'CATEGORY'
  RealColumn get value => real().withDefault(const Constant(0))();
  TextColumn get productId => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get employeeId =>
      text().nullable()(); // limits rule to a specific employee if present
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Expense tracking
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get category =>
      text()(); // 'SALARY' | 'ELECTRICITY' | 'RENT' | 'TRANSPORT' | 'INTERNET' | 'MAINTENANCE' | 'OTHER'
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get amount => real()();
  TextColumn get employeeId => text().nullable()();
  TextColumn get locationId => text().nullable()();
  TextColumn get receiptUrl => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get expenseDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Discount definitions (promotional, customer-type, etc.)
class Discounts extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  TextColumn get type =>
      text()(); // 'PRODUCT' | 'INVOICE' | 'CUSTOMER' | 'PROMO'
  TextColumn get discountMode => text()(); // 'FIXED' | 'PERCENT'
  RealColumn get value => real()();
  // Optional: apply only to this product or category
  TextColumn get productId => text().nullable()();
  TextColumn get category => text().nullable()();
  // Optional: apply only to this customer type
  TextColumn get customerType => text().nullable()();
  // Conditions as JSON (for complex promos like Buy2Get1)
  TextColumn get conditions => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Loyalty points ledger per customer
class LoyaltyLedger extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get customerId => text()();
  TextColumn get saleId => text().nullable()();
  RealColumn get points => real()();
  TextColumn get type => text()(); // 'EARN' | 'REDEEM' | 'ADJUST'
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Print settings per tenant
class PrintSettings extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get paperSize =>
      text().withDefault(const Constant('80mm'))(); // '58mm' | '80mm' | 'A4'
  TextColumn get printerName => text().nullable()();
  TextColumn get printerType => text().withDefault(
    const Constant('THERMAL'),
  )(); // 'THERMAL' | 'A4' | 'DEFAULT'
  TextColumn get invoiceTemplate => text().withDefault(
    const Constant('PROFESSIONAL'),
  )(); // 'COMPACT' | 'PROFESSIONAL' | 'MODERN'
  BoolColumn get autoPrint => boolean().withDefault(const Constant(false))();
  BoolColumn get showLogo => boolean().withDefault(const Constant(true))();
  BoolColumn get showBarcode => boolean().withDefault(const Constant(false))();
  BoolColumn get showQr => boolean().withDefault(const Constant(true))();
  BoolColumn get showTax => boolean().withDefault(const Constant(true))();
  BoolColumn get showDiscount => boolean().withDefault(const Constant(true))();
  BoolColumn get showCustomerAddress =>
      boolean().withDefault(const Constant(false))();
  // Alignment
  RealColumn get marginTop => real().withDefault(const Constant(10))();
  RealColumn get marginLeft => real().withDefault(const Constant(10))();
  RealColumn get fontSize => real().withDefault(const Constant(10))();
  RealColumn get lineSpacing => real().withDefault(const Constant(1.2))();
  // Footer
  TextColumn get thankYouMessage =>
      text().withDefault(const Constant('Thank you for your business!'))();
  TextColumn get returnPolicy => text().nullable()();
  TextColumn get socialLinks => text().nullable()(); // JSON array
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()(); // 'INSERT', 'UPDATE', 'DELETE'
  TextColumn get entityTable => text()();
  TextColumn get recordId => text()();
  TextColumn get clientOpId => text().nullable()();
  TextColumn get data => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  // Tracks the actual last attempt time so exponential back-off is measured
  // from the most-recent send attempt, not from the queue insertion time.
  DateTimeColumn get lastRetryAt => dateTime().nullable()();
}

class SyncJournal extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientOpId => text().nullable()();
  IntColumn get serverSeq => integer().nullable()();
  TextColumn get direction => text()(); // 'outbound' | 'inbound'
  TextColumn get status => text()();
  TextColumn get operation => text()();
  TextColumn get entityTable => text()();
  TextColumn get recordId => text()();
  TextColumn get payload => text().nullable()();
  TextColumn get errorReason => text().nullable()();
  TextColumn get sourceDeviceId => text().nullable()();
  TextColumn get sourceUserId => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
