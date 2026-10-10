import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:drift/drift.dart' hide Column, Table;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../blocs/auth/auth_bloc.dart';
import '../database/database.dart' as db;
import '../models/models.dart' as domain;
import '../repositories/customer_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/commission_service.dart' as commission;
import '../services/print_service.dart';
import '../services/sync_service.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../theme/ui_system.dart';
import 'login_screen.dart';

part 'sub_screens/attendance_page.dart';
part 'sub_screens/bank_registers_page.dart';
part 'sub_screens/barcode_printing_page.dart';
part 'sub_screens/categories_page.dart';
part 'sub_screens/commission_dashboard_page.dart';
part 'sub_screens/credit_management_page.dart';
part 'sub_screens/customers_page.dart';
part 'sub_screens/dashboard_page.dart';
part 'sub_screens/discounts_page.dart';
part 'sub_screens/employees_page.dart';
part 'sub_screens/expenses_page.dart';
part 'sub_screens/installments_page.dart';
part 'sub_screens/inventory_page.dart';
part 'sub_screens/job_cards_page.dart';
part 'sub_screens/locations_page.dart';
part 'sub_screens/marketing_page.dart';
part 'sub_screens/mobile_reload_page.dart';
part 'sub_screens/payroll_page.dart';
part 'sub_screens/point_of_sale.dart';
part 'sub_screens/print_settings_tab.dart';
part 'sub_screens/products_page.dart';
part 'sub_screens/purchase_orders_page.dart';
part 'sub_screens/reports_page.dart';
part 'sub_screens/returns_refunds_page.dart';
part 'sub_screens/sales_page.dart';
part 'sub_screens/services_page.dart';
part 'sub_screens/settings_page.dart';
part 'sub_screens/settings_tab_content.dart';
part 'sub_screens/stock_transfers_page.dart';
part 'sub_screens/store_page_content.dart';
part 'sub_screens/suppliers_page.dart';
part 'sub_screens/sync_page.dart';
part 'sub_screens/users_page.dart';
part 'sub_screens/whatsapp_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.user});

  final domain.User user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const List<_UserPermissionOption> _userPermissionOptions = [
    _UserPermissionOption('POS', {'pos'}),
    _UserPermissionOption('Products', {'products'}),
    _UserPermissionOption('Categories', {'categories'}),
    _UserPermissionOption('Locations', {'locations'}),
    _UserPermissionOption('Stock Transfers', {'stockTransfers'}),
    _UserPermissionOption('Services', {'services'}),
    _UserPermissionOption('Barcode Printing', {'barcodes'}),
    _UserPermissionOption('Sales', {'sales'}),
    _UserPermissionOption('Installments', {'installments'}),
    _UserPermissionOption('Customers', {'customers'}),
    _UserPermissionOption('Credit Management', {'creditManagement'}),
    _UserPermissionOption('Employees', {'employees'}),
    _UserPermissionOption('Attendance', {'attendance'}),
    _UserPermissionOption('Payroll', {'payroll'}),
    _UserPermissionOption('Users', {'users'}),
    _UserPermissionOption('Reports', {'reports'}),
    _UserPermissionOption('Settings', {'settings'}),
    _UserPermissionOption('Marketing', {'marketing'}),
    _UserPermissionOption('Expenses', {'expenses'}),
    _UserPermissionOption('Discounts', {'discounts'}),
    _UserPermissionOption('Commissions', {'commissions'}),
    _UserPermissionOption('Job Cards', {'jobCards'}),
    _UserPermissionOption('Returns & Refunds', {'warranties'}),
    _UserPermissionOption('Suppliers', {'suppliers'}),
    _UserPermissionOption('Purchase Orders', {'purchaseOrders'}),
    _UserPermissionOption('Mobile Reload', {'mobileReload'}),
    _UserPermissionOption('Sync Manager', {'sync'}),
    _UserPermissionOption('WhatsApp Connect', {'whatsapp'}),
  ];

  static const List<_NavItem> _defaultStoreNavItems = [
    _NavItem(
      key: 'dashboard',
      label: 'Owner Dashboard',
      icon: Icons.dashboard_rounded,
    ),
    _NavItem(key: 'pos', label: 'Point of Sale', icon: Icons.storefront),
    _NavItem(key: 'products', label: 'Products', icon: Icons.inventory_2),
    _NavItem(key: 'categories', label: 'Categories', icon: Icons.category),
    _NavItem(
      key: 'stockTransfers',
      label: 'Stock Transfers',
      icon: Icons.swap_horiz_rounded,
    ),
    _NavItem(key: 'services', label: 'Services', icon: Icons.build_rounded),
    _NavItem(
      key: 'barcodes',
      label: 'Barcode Printing',
      icon: Icons.qr_code_2_rounded,
    ),
    _NavItem(key: 'sales', label: 'Sales', icon: Icons.receipt_long_rounded),
    _NavItem(
      key: 'installments',
      label: 'Installments',
      icon: Icons.event_note_rounded,
    ),
    _NavItem(key: 'customers', label: 'Customers', icon: Icons.groups_rounded),
    _NavItem(
      key: 'creditManagement',
      label: 'Credit Management',
      icon: Icons.credit_card_rounded,
    ),
    _NavItem(key: 'employees', label: 'Employees', icon: Icons.badge_rounded),
    _NavItem(
      key: 'attendance',
      label: 'Attendance',
      icon: Icons.schedule_rounded,
    ),
    _NavItem(
      key: 'payroll',
      label: 'Payroll',
      icon: Icons.account_balance_wallet_rounded,
    ),
    _NavItem(key: 'users', label: 'Users', icon: Icons.manage_accounts_rounded),
    _NavItem(key: 'reports', label: 'Reports', icon: Icons.bar_chart_rounded),
    _NavItem(
      key: 'marketing',
      label: 'Marketing',
      icon: Icons.campaign_rounded,
    ),
    _NavItem(
      key: 'expenses',
      label: 'Expenses',
      icon: Icons.receipt_long_outlined,
    ),
    _NavItem(
      key: 'discounts',
      label: 'Discounts',
      icon: Icons.local_offer_rounded,
    ),
    _NavItem(
      key: 'commissions',
      label: 'Commission Dashboard',
      icon: Icons.stars_outlined,
    ),
    _NavItem(
      key: 'jobCards',
      label: 'Job Cards',
      icon: Icons.assignment_rounded,
    ),
    _NavItem(
      key: 'warranties',
      label: 'Returns & Refunds',
      icon: Icons.sync_alt_rounded,
    ),
    _NavItem(
      key: 'suppliers',
      label: 'Suppliers',
      icon: Icons.local_shipping_rounded,
    ),
    _NavItem(
      key: 'purchaseOrders',
      label: 'Purchase Orders',
      icon: Icons.assignment_outlined,
    ),
    _NavItem(
      key: 'bankRegisters',
      label: 'Bank & Registers',
      icon: Icons.account_balance_rounded,
    ),
    _NavItem(
      key: 'mobileReload',
      label: 'Mobile Reload',
      icon: Icons.phone_android_rounded,
    ),
    _NavItem(key: 'locations', label: 'Locations', icon: Icons.place_rounded),
    _NavItem(key: 'settings', label: 'Settings', icon: Icons.settings_rounded),
    _NavItem(key: 'sync', label: 'Sync Manager', icon: Icons.sync_rounded),
    _NavItem(
      key: 'whatsapp',
      label: 'WhatsApp Connect',
      icon: Icons.qr_code_scanner_rounded,
    ),
  ];

  static const List<String> _defaultSidebarNavOrder = [
    'dashboard',
    'pos',
    'bankRegisters',
    'products',
    'categories',
    'stockTransfers',
    'services',
    'barcodes',
    'sales',
    'installments',
    'customers',
    'creditManagement',
    'employees',
    'attendance',
    'payroll',
    'users',
    'reports',
    'marketing',
    'expenses',
    'discounts',
    'commissions',
    'jobCards',
    'warranties',
    'suppliers',
    'purchaseOrders',
    'mobileReload',
    'locations',
    'settings',
    'sync',
    'whatsapp',
  ];

  static const List<_PlatformNavItem> _platformNavItems = [
    _PlatformNavItem('dashboard', 'Dashboard', Icons.dashboard_rounded),
    _PlatformNavItem('restaurants', 'Shops', Icons.storefront_rounded),
    _PlatformNavItem('plans', 'Plans', Icons.dashboard_customize_rounded),
    _PlatformNavItem('users', 'Users', Icons.people_alt_rounded),
    _PlatformNavItem('qrPayments', 'QR Payments', Icons.qr_code_2_rounded),
    _PlatformNavItem('activity', 'Activity', Icons.receipt_long_rounded),
    _PlatformNavItem('releases', 'Releases', Icons.rocket_launch_rounded),
    _PlatformNavItem('documentation', 'Documentation', Icons.menu_book_rounded),
    _PlatformNavItem(
      'tutorials',
      'Tutorials',
      Icons.play_circle_outline_rounded,
    ),
    _PlatformNavItem('support', 'Support', Icons.support_agent_rounded),
    _PlatformNavItem('about', 'About', Icons.info_outline_rounded),
    _PlatformNavItem('contact', 'Contact', Icons.contact_mail_rounded),
  ];

  static const List<_PlatformPlanSpec> _platformPlanSpecs = [
    _PlatformPlanSpec(
      name: 'Free',
      badge: 'FREE',
      description: 'Trial-safe default plan for new stores.',
      monthlyPrice: 0,
      yearlyPrice: 0,
      trialDays: 7,
      accentColor: Color(0xFF6B7280),
    ),
    _PlatformPlanSpec(
      name: 'Starter',
      badge: 'STARTER',
      description: 'Small teams that need core shop operations.',
      monthlyPrice: 29,
      yearlyPrice: 290,
      trialDays: 14,
      accentColor: Color(0xFF2563EB),
    ),
    _PlatformPlanSpec(
      name: 'Growth',
      badge: 'GROWTH',
      description: 'Busy shops that want more admin control.',
      monthlyPrice: 59,
      yearlyPrice: 590,
      trialDays: 30,
      accentColor: Color(0xFF7C3AED),
    ),
    _PlatformPlanSpec(
      name: 'Enterprise',
      badge: 'ENTERPRISE',
      description: 'Multi-branch shops with premium support.',
      monthlyPrice: 99,
      yearlyPrice: 990,
      trialDays: 45,
      accentColor: Color(0xFFB45309),
    ),
  ];

  List<Map<String, dynamic>> _storeLogins = [];
  bool _isCreatingStore = false;
  final Set<String> _trialUpdatingTenants = <String>{};
  String _selectedNavKey = 'dashboard';
  void _selectNavByKey(String key) => setState(() => _selectedNavKey = key);
  bool _hasPromptedOpenRegisterThisVisit = false;
  List<String> _sidebarNavOrder = List<String>.from(_defaultSidebarNavOrder);
  final GlobalKey<ScaffoldState> _mobileShellScaffoldKey =
      GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _platformShellScaffoldKey =
      GlobalKey<ScaffoldState>();
  final TextEditingController _platformSearchController =
      TextEditingController();
  final Map<String, _PlatformPlanAssignment> _platformPlanAssignments = {};
  final List<_PlatformActivityEntry> _platformActivity = [];
  String _selectedPlatformNavKey = 'dashboard';

  List<Map<String, dynamic>> _adminPlans = [];
  Map<String, dynamic> _adminStats = {};
  List<Map<String, dynamic>> _adminUsers = [];
  List<Map<String, dynamic>> _adminActivityLogs = [];
  List<Map<String, dynamic>> _adminReleases = [];
  Map<String, dynamic> _adminQrPaymentsData = {};
  List<Map<String, dynamic>> _adminDocs = [];
  List<Map<String, dynamic>> _adminTutorials = [];
  String _selectedQrStatus = 'ALL';
  String _selectedTutAudience = 'ALL';
  String _selectedDocSection = 'ALL';
  Map<String, dynamic>? _selectedDoc;
  bool _isLoadingPlatformData = false;

  final List<_ProductItem> _products = [
    _ProductItem(
      id: 'P001',
      name: 'Chicken Burger',
      category: 'Food',
      price: 1200,
      stock: 30,
      minStock: 8,
      barcode: 'P001',
    ),
    _ProductItem(
      id: 'P002',
      name: 'Coke 500ml',
      category: 'Beverage',
      price: 350,
      stock: 55,
      minStock: 12,
      barcode: 'P002',
    ),
    _ProductItem(
      id: 'P003',
      name: 'French Fries',
      category: 'Food',
      price: 700,
      stock: 18,
      minStock: 10,
      barcode: 'P003',
    ),
  ];
  List<String> _productCategories = ['Food', 'Beverage', 'General'];
  final List<_CustomerItem> _customers = [
    _CustomerItem(
      id: 'C001',
      name: 'Walk-in Customer',
      phone: 'N/A',
      email: '',
    ),
  ];
  final List<_EmployeeItem> _employees = [];
  final List<_UserItem> _users = [];
  final List<commission.CommissionRule> _commissionRules = [];
  final List<_SupplierItem> _suppliers = [];
  final List<_LocationItem> _locations = [
    _LocationItem(
      id: 'LOC_MAIN',
      name: 'Main Branch',
      code: 'MAIN',
      isActive: true,
      isHeadquarters: true,
      openingTime: '09:00 AM',
      closingTime: '06:00 PM',
    ),
  ];
  final List<_StockTransferItem> _stockTransfers = [];
  final List<_StockRequestItem> _stockRequests = [];
  int _stockTransfersTabIndex = 0;
  String _stockRequestsSearchQuery = '';
  String _stockRequestStatusFilter = 'ALL';
  final List<_NotificationItem> _notifications = [];
  final List<_CouponItem> _coupons = [];
  final List<_ServiceJobItem> _serviceJobs = [];
  final List<_ReturnItem> _returns = [];
  final List<_DamagedInventoryItem> _damagedInventory = [];
  final List<_CashTransactionItem> _cashTransactions = [];
  final List<db.Expense> _expensesList = [];
  List<_CashierSession> _cashierSessions = [];
  List<_BankTransaction> _bankTransactions = [];
  double _bankAccountBalance = 0.0;
  bool _posCodPaymentCollectedUpfront = false;
  String? _posSelectedDeliveryDriverId;
  double get _cashInHand => _calculatedCashInHand;

  double get _calculatedCashInHand {
    final openSessions = _cashierSessions
        .where((s) => s.status == 'OPEN')
        .toList();
    if (openSessions.isNotEmpty) {
      return openSessions.fold<double>(0.0, (sum, s) => sum + s.expectedCash);
    }

    double cash = 0.0;

    // 1. Cash Sales & COD completed sales (including returned sales where cash was collected)
    for (final sale in _scopedSales) {
      final st = sale.status.toUpperCase();
      if (st == 'COMPLETED' || st == 'RETURNED' || st == 'PARTIALLY_RETURNED') {
        if (sale.paymentMethod.toUpperCase() == 'CASH') {
          cash += sale.amountPaid > 0 ? sale.amountPaid : sale.total;
        } else if (sale.paymentMethod.toUpperCase() == 'COD' &&
            sale.amountPaid > 0) {
          cash += sale.amountPaid;
        }
      }
    }

    // 2. Customer Credit payments (settlements)
    for (final customer in _scopedCustomers) {
      final payments =
          _customerCreditPayments[customer.id] ?? const <_CreditPaymentItem>[];
      for (final p in payments) {
        cash += p.amount;
      }
    }

    // 3. Installments in Cash
    for (final plan in _scopedInstallmentPlans) {
      if (plan.paymentMethod.toUpperCase() == 'CASH') {
        cash += plan.downPayment;
        for (final schedule in plan.schedules) {
          cash += schedule.paidAmount;
        }
      }
    }

    // 4. Expenses & PO cash purchases
    for (final exp in _scopedExpenses) {
      if (_getExpensePaymentMethod(exp.notes) == 'CASH') {
        cash -= exp.amount;
      }
    }

    // 5. Cash Refunds / Transactions (from returns page)
    for (final tx in _scopedCashTransactions) {
      if (tx.type == 'OUT') {
        cash -= tx.amount;
      } else if (tx.type == 'IN') {
        cash += tx.amount;
      }
    }

    return cash;
  }

  final List<_SaleRecord> _sales = [];
  final List<_HeldCart> _heldCarts = [];
  final List<_InvoiceItem> _invoices = [];
  final List<_PurchaseOrderItem> _purchaseOrders = [];
  final List<_AttendanceRecordItem> _attendanceRecords = [];
  final List<_PayrollRecordItem> _payrollRecords = [];
  final List<_StockAdjustmentItem> _stockAdjustments = [];
  final List<_SyncItem> _syncQueue = [];
  final Map<String, List<_CreditPaymentItem>> _customerCreditPayments = {};
  final Map<String, List<_CreditSaleEntry>> _customerCreditSales = {};
  final List<_InstallmentPlan> _installmentPlans = [];

  final Map<String, double> _cart = {};
  final Map<String, List<String>> _selectedCartImeis = {};
  String? _editingSaleId;
  final Map<String, _DiscountData> _posLineDiscounts = {};
  final Map<String, double> _posLinePrices = {};
  final List<db.Discount> _discountDefinitions = [];
  double _posInvoiceDiscountValue = 0.0;
  String _posInvoiceDiscountType = 'FIXED';
  final Map<String, _ProductItem> _temporaryCartProducts = {};
  String? _selectedCustomerId;
  int _posInstallmentCount = 3;
  int _posInstallmentIntervalDays = 30;
  final List<DateTime> _posInstallmentDueDates = [];
  final List<double> _posInstallmentAmounts = [];
  double _posInstallmentAmountsTotal = 0;
  // Shipping & Agent Commission — per-transaction POS session state
  double _posShippingCharges = 0.0;
  String _posAgentName = '';
  String _posAgentId = ''; // actual employee/user ID for the selected agent
  double _posAgentCommission = 0.0;
  String _posAgentCommissionType = 'PERCENT'; // 'PERCENT' | 'FIXED'
  bool _posAgentCommissionPaid = false; // true = Pay Now, false = Pay Later

  String _companyName = 'Store Buddy Shop';
  String _taxRate = '8';
  String _currency = 'LKR';
  String _storeLocation = 'Main Branch';
  String _receiptHeader = 'Store Buddy POS';
  String _receiptFooter = 'Thank you, come again!';
  bool _receiptShowTax = true;
  bool _posApplyTax = true;
  bool _receiptShowLogo = false;
  bool _receiptShowCompanyName = true;
  bool _receiptShowShopAddress = true;
  bool _receiptShowShopPhone = true;
  bool _receiptShowReceiptTitle = true;
  bool _receiptShowReceiptNumber = true;
  bool _receiptShowDate = true;
  bool _receiptShowTime = true;
  bool _receiptShowCashier = true;
  bool _receiptShowCustomer = true;
  bool _receiptShowPaymentMethod = true;
  bool _receiptShowBalance = true;
  bool _receiptShowReturnPolicy = true;
  bool _allowReprintSalesBill = true;
  bool _enableWhatsappCodNotifications = true;
  String _receiptNote = 'No refunds without invoice';
  String _openFrom = '08:00';
  String _openTo = '22:00';
  bool _acceptCash = true;
  bool _acceptCard = true;
  bool _acceptCheque = false;
  bool _acceptInstallment = false;
  String _integrationMode = 'Cloud Sync';
  String _integrationWebhook = '';
  bool _notifyLowStock = true;
  bool _notifyDailySummary = true;
  bool _notifyReturns = true;
  bool _cashDrawerEnabled = true;
  bool _cashDrawerRequirePin = false;
  String _cashDrawerPin = '';
  String _receiptPaper = '80mm';
  String _receiptMargin = '8';
  String _receiptFontScale = '1.0';
  String _profileName = '';
  String _profileEmail = '';
  String _profilePhone = '';
  String _profileCurrentPassword = '';
  String _profileNewPassword = '';
  String _profileConfirmPassword = '';
  String _companyEmail = '';
  String _companyPhone = '';
  String _companyAddress = '';
  String _companyRegNo = '';
  String _companyLogoPath = '';
  String _invoicePattern = '{PREFIX}-{SEQ}';
  int _invoicePatternResetCounter = 0;
  String _invoicePrefix = 'INV';
  bool _invoiceIncludeLocation = true;
  String _invoiceLocationLength = '2';
  bool _invoiceIncludeUser = true;
  String _invoiceUserLength = '2';
  bool _invoiceIncludeDate = true;
  String _uiTheme = 'Light';
  String _uiLanguage = 'English';
  bool _prefSound = true;
  bool _prefAutoPrint = false;
  bool _prefCompact = false;
  // Optional POS features — controlled via Settings
  bool _enableShippingCharges = false;
  bool _enableCod = false;
  double _defaultDeliveryFee = 350.0;
  bool _enableAgentCommission = false;
  bool _mobileReloadEnabled = false;
  bool _enableMobileShopFeatures = false;

  // Device-Local Hardware Printer Configuration (Terminal-specific, NOT synced across branches)
  String? _localReceiptPrinterName;
  String _localReceiptPaperSize = 'thermal_80'; // thermal_80 | thermal_58 | a4 | a5 | custom
  double _localPaperWidthMm = 72.0;
  double _localMarginHMm = 2.0;
  double _localMarginVMm = 3.0;
  bool _localAutoPrintOnSaleComplete = false;
  bool _localPromptDeliveryLabel = false;
  bool _localCashDrawerEnabled = true;
  String? _localCashDrawerPrinterName;
  String _localCashDrawerMethod = 'print_job'; // 'print_job' | 'network' | 'hybrid'
  int _localCashDrawerPulsePin = 0; // 0 for Pin 2, 1 for Pin 5
  int _localCashDrawerPulseOnMs = 120;
  int _localCashDrawerPulseOffMs = 240;
  String _localCashDrawerNetworkIp = '';
  int _localCashDrawerNetworkPort = 9100;
  String? _localLabelPrinterName;
  String _localDeliveryNoteFormat = 'THERMAL_80MM';
  String? _localDeliveryNotePrinterName;
  String _productScanBuffer = '';
  DateTime _lastProductScanTime = DateTime.now();
  bool _isProductDialogOpen = false;

  final List<_MobileReloadRecord> _mobileReloads = [];
  Map<String, List<Map<String, dynamic>>> _operatorCommissions = {
    'Dialog': [
      {'min': 0.0, 'max': 199.0, 'type': 'percentage', 'value': 2.0},
      {'min': 200.0, 'max': 999.0, 'type': 'percentage', 'value': 3.5},
      {'min': 1000.0, 'max': 999999.0, 'type': 'percentage', 'value': 5.0},
    ],
    'Mobitel': [
      {'min': 0.0, 'max': 199.0, 'type': 'percentage', 'value': 2.0},
      {'min': 200.0, 'max': 999.0, 'type': 'percentage', 'value': 3.5},
      {'min': 1000.0, 'max': 999999.0, 'type': 'percentage', 'value': 5.0},
    ],
    'Hutch': [
      {'min': 0.0, 'max': 199.0, 'type': 'percentage', 'value': 2.0},
      {'min': 200.0, 'max': 999.0, 'type': 'percentage', 'value': 3.5},
      {'min': 1000.0, 'max': 999999.0, 'type': 'percentage', 'value': 5.0},
    ],
    'Airtel': [
      {'min': 0.0, 'max': 199.0, 'type': 'percentage', 'value': 2.0},
      {'min': 200.0, 'max': 999.0, 'type': 'percentage', 'value': 3.5},
      {'min': 1000.0, 'max': 999999.0, 'type': 'percentage', 'value': 5.0},
    ],
    'SLT': [
      {'min': 0.0, 'max': 999999.0, 'type': 'percentage', 'value': 3.0},
    ],
    'eZ Cash': [
      {'min': 0.0, 'max': 199.0, 'type': 'percentage', 'value': 2.0},
      {'min': 200.0, 'max': 999.0, 'type': 'percentage', 'value': 3.5},
      {'min': 1000.0, 'max': 999999.0, 'type': 'percentage', 'value': 5.0},
    ],
  };
  // When true: agent name is locked to the logged-in user; no dropdown shown
  bool _agentCommissionLockToLogin = false;
  bool _prefRequireSaleConfirmation = true;
  bool _notifyEmail = true;
  bool _notifySms = false;
  bool _notifyPayroll = true;
  String _payrollCycle = 'Monthly';
  String _payrollWorkingDays = '26';
  String _payrollOtRate = '1.5';
  String _payrollLatePenalty = '500';
  bool _payrollAutoGenerate = false;
  bool _payrollEnableEpf = true;
  String _selectedReportType = 'sales';
  String _settingsTab = 'general';
  final String _salesFilterStatus = 'ALL';
  String _salesFilterPayment = 'ALL';
  String _salesCashierFilter = 'All Cashiers';
  String _salesAgentFilter = 'All Agents';
  String _salesCategoryFilter = 'All Categories';
  String _reportsInventoryCategoryFilter = 'All Categories';
  String _reportsInventorySupplierFilter = 'All Suppliers';
  String _salesCustomerFilter = 'All Customers';
  String _salesItemsFilter = 'All Items';
  String _salesTimeFilter = 'All Time';
  String _reportsTimeFilter = 'This Month';
  String _reportsPaymentFilter = 'ALL';
  String _reportsStatusFilter = 'ALL';
  String _reportsCashierFilter = 'ALL';
  String _creditStatusFilter = 'ALL';
  String _creditTimeFilter = 'All Time';
  String _creditCashierFilter = 'All Cashiers';
  String _dashboardPeriod = 'This Month';
  String _posCategoryFilter = 'All Categories';
  String _purchaseOrderStatusFilter = 'All Statuses';
  String _barcodePreset = 'zebra_zd230_2col';
  String _barcodePaperFormat = 'custom_roll';
  String _barcodeFormat = 'CODE128';
  String _barcodePrinterType = 'thermal';
  double _barcodePaperWidthMm = 101.6;
  double _barcodeLabelWidthMm = 48.0;
  double _barcodeLabelHeightMm = 25.4;
  double _barcodeHorizontalGapMm = 2.0;
  double _barcodeVerticalGapMm = 2.0;
  double _barcodeMarginMm = 1.1;
  double _barcodeRightShiftMm = 0.0;
  double _barcodeTopShiftMm = 3.5;
  double _barcodeFontScale = 1.0;
  double _barcodeHeightMm = 7.0;
  bool _barcodeShowStoreName = false;
  bool _barcodeShowName = true;
  bool _barcodeShowPrice = true;
  bool _barcodeShowSku = true;
  bool _barcodeShowCodeText = true;
  bool _barcodeShowCategory = false;
  bool _barcodePrintIndividualImei = true;
  int _barcodeRotationDegrees = 0; // 0, 90, 180, 270
  int _barcodeColumns = 2; // 1, 2, 3, 4
  final Set<String> _selectedBarcodeProductIds = <String>{};
  final Map<String, int> _barcodeQuantityByProduct = <String, int>{};
  DateTime? _lastSyncAt;
  String? _lastSyncError;
  String? _lastExpiryReminderDigest;

  SyncService? _syncService;
  db.AppDatabase? _appDatabase;
  ProductRepository? _productRepository;
  CustomerRepository? _customerRepository;
  SaleRepository? _saleRepository;
  String? _activeTenantId;
  String _currentUserRole = 'manager';
  String _currentUserId = '';
  String _currentUserName = 'Cashier';
  String _currentUserEmail = '';
  bool _coreDataLoaded = false;
  bool _syncInProgress = false;
  bool _syncQueueLoaded = false;
  bool _combineProductsStockAllLocations = true;
  bool _isSubscriptionExpired = false;
  bool _isCheckingSubscription = false;
  Map<String, dynamic>? _subscriptionStatusData;
  final TextEditingController _offlineLicenseInputController =
      TextEditingController();

  final TextEditingController _salesSearchController = TextEditingController();
  final TextEditingController _installmentSearchController =
      TextEditingController();
  final TextEditingController _reportsSearchController =
      TextEditingController();
  final TextEditingController _customerSearchController =
      TextEditingController();
  final TextEditingController _attendanceSearchController =
      TextEditingController();
  final TextEditingController _employeeSearchController =
      TextEditingController();
  final TextEditingController _usersSearchController = TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();
  final FocusNode _posProductSearchFocusNode = FocusNode();
  final TextEditingController _categoriesSearchController =
      TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _tenantIdController = TextEditingController();
  final TextEditingController _storeEmailController = TextEditingController();
  final TextEditingController _storePasswordController =
      TextEditingController();
  final TextEditingController _posCouponController = TextEditingController();
  final TextEditingController _posGiftCardController = TextEditingController();
  final TextEditingController _posCustomerSearchController =
      TextEditingController();
  final FocusNode _posCustomerSearchFocusNode = FocusNode();
  final TextEditingController _posCustomerNameController =
      TextEditingController();
  final TextEditingController _posCustomerPhoneController =
      TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _posNotesController = TextEditingController();
  final TextEditingController _chequeNumberController = TextEditingController();
  final TextEditingController _posShippingController = TextEditingController();
  final TextEditingController _posAgentNameController = TextEditingController();
  final TextEditingController _posAgentCommissionController =
      TextEditingController();
  final TextEditingController _purchaseOrderSearchController =
      TextEditingController();
  final TextEditingController _serviceSearchController =
      TextEditingController();
  final TextEditingController _warrantySearchController =
      TextEditingController();
  final TextEditingController _returnsSearchController =
      TextEditingController();
  final TextEditingController _barcodeSearchController =
      TextEditingController();
  final TextEditingController _barcodeRollWidthController =
      TextEditingController(text: '101.6');
  final TextEditingController _barcodeLabelWidthController =
      TextEditingController(text: '31.8');
  final TextEditingController _barcodeLabelHeightController =
      TextEditingController(text: '22.0');
  final TextEditingController _barcodeHeightController =
      TextEditingController(text: '6.5');
  final TextEditingController _barcodeColGapController =
      TextEditingController(text: '2.0');
  final TextEditingController _barcodeRowGapController =
      TextEditingController(text: '2.0');
  final TextEditingController _barcodeTopShiftController =
      TextEditingController(text: '3.5');
  final TextEditingController _barcodeLeftShiftController =
      TextEditingController(text: '0.0');
  final TextEditingController _barcodeScaleController =
      TextEditingController(text: '0.85');
  String _jobCardStatusFilter = 'ALL';
  String _jobCardPriorityFilter = 'ALL';
  String _returnsStatusFilter = 'All Statuses';
  String _returnsReasonFilter = 'All Reasons';
  String _damagedFilter = 'All';
  Map<String, List<_CategoryAttributeDef>> _categoryAttributes = {};
  final String _warrantyTabKey = 'warranties';
  DateTime _attendanceMonth = DateTime.now();
  String _usersRoleFilter = 'All Roles';
  String _usersStatusFilter = 'All Statuses';
  String _usersLocationFilter = 'All Locations';
  String _selectedLocationScope = 'All Locations';
  static const String _allLocationsLabel = 'All Locations';

  static const String _workspaceStateKeyBase = 'workspace_state';

  late final String _workspaceStateKey;

  late final String _tenantWorkspaceStateKey;

  bool get _isCompactViewport =>
      MediaQuery.of(context).size.width < UiBreakpoints.tablet;

  double _adaptiveWidth(
    double desktopWidth, {
    double minWidth = 240,
    double horizontalPadding = 24,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (!_isCompactViewport) {
      return desktopWidth;
    }
    final available = screenWidth - horizontalPadding;
    return available.clamp(minWidth, desktopWidth).toDouble();
  }

  double _adaptiveHeight(
    double desktopHeight, {
    double minHeight = 220,
    double screenFraction = 0.9,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (!_isCompactViewport) {
      return desktopHeight;
    }
    final available = screenHeight * screenFraction;
    return available.clamp(minHeight, desktopHeight).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _tenantWorkspaceStateKey = 'workspace_state_${widget.user.tenantId}';
    _profileName = widget.user.name.trim().isNotEmpty ? widget.user.name.trim() : 'Owner';
    _profileEmail = widget.user.email.trim();
    _companyEmail = widget.user.email.trim();
    if (_companyName == 'Store Buddy Shop' || _companyName.isEmpty) {
      _companyName = widget.user.name.trim().isNotEmpty ? "${widget.user.name.trim()}'s Store" : 'Store Buddy Shop';
    }
    _paymentMethodController.text = 'CASH';
    _resetPosInstallmentSchedule();
    _loadPersistedWorkspaceData();
    _loadDeviceLocalPrinterSettings();
    _loadStoreLogins();
    _checkSubscriptionAndEnforceExpiry();
    HardwareKeyboard.instance.addHandler(_handleGlobalHardwareKey);
  }

  Future<void> _checkSubscriptionAndEnforceExpiry() async {
    if (widget.user.role.toLowerCase() == 'platform_admin') return;
    setState(() => _isCheckingSubscription = true);
    try {
      final authService = context.read<AuthService>();
      final status = await authService.getSubscriptionStatus();
      final isExpired = status['is_expired'] == true ||
          status['status'] == 'EXPIRED' ||
          status['status'] == 'SUSPENDED';
      if (mounted) {
        setState(() {
          _subscriptionStatusData = status;
          _isSubscriptionExpired = isExpired;
        });
      }
    } catch (e) {
      debugPrint('Could not check subscription status: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingSubscription = false);
      }
    }
  }

  Future<void> _loadDeviceLocalPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localReceiptPrinterName = prefs.getString('local_printer_receipt_name');
      _localReceiptPaperSize = prefs.getString('local_printer_paper_size') ?? 'thermal_80';
      _localPaperWidthMm = prefs.getDouble('local_printer_paper_width_mm') ?? 72.0;
      _localMarginHMm = prefs.getDouble('local_printer_margin_h_mm') ?? 2.0;
      _localMarginVMm = prefs.getDouble('local_printer_margin_v_mm') ?? 3.0;
      _localAutoPrintOnSaleComplete = prefs.getBool('local_printer_auto_print') ?? false;
      _localPromptDeliveryLabel = prefs.getBool('local_printer_prompt_delivery_label') ?? false;
      _localCashDrawerEnabled = prefs.getBool('local_cash_drawer_enabled') ?? true;
      _localCashDrawerPrinterName = prefs.getString('local_cash_drawer_printer_name');
      _localCashDrawerMethod = prefs.getString('local_cash_drawer_method') ?? 'print_job';
      _localCashDrawerPulsePin = prefs.getInt('local_cash_drawer_pulse_pin') ?? 0;
      _localCashDrawerPulseOnMs = prefs.getInt('local_cash_drawer_pulse_on_ms') ?? 120;
      _localCashDrawerPulseOffMs = prefs.getInt('local_cash_drawer_pulse_off_ms') ?? 240;
      _localCashDrawerNetworkIp = prefs.getString('local_cash_drawer_network_ip') ?? '';
      _localCashDrawerNetworkPort = prefs.getInt('local_cash_drawer_network_port') ?? 9100;
      _localLabelPrinterName = prefs.getString('local_printer_label_name');
      _localDeliveryNoteFormat = prefs.getString('local_printer_delivery_note_format') ?? 'THERMAL_80MM';
      _localDeliveryNotePrinterName = prefs.getString('local_printer_delivery_note_printer_name');

      _barcodePreset = prefs.getString('barcode_preset') ?? 'zebra_zd230_2col';
      _barcodePaperFormat = prefs.getString('barcode_paper_format') ?? 'custom_roll';
      _barcodeFormat = prefs.getString('barcode_format') ?? 'CODE128';
      _barcodePrinterType = prefs.getString('barcode_printer_type') ?? 'thermal';
      _barcodePaperWidthMm = prefs.getDouble('barcode_paper_width_mm') ?? 101.6;
      _barcodeLabelWidthMm = prefs.getDouble('barcode_label_width_mm') ?? 48.0;
      _barcodeLabelHeightMm = prefs.getDouble('barcode_label_height_mm') ?? 25.4;
      _barcodeHorizontalGapMm = prefs.getDouble('barcode_horizontal_gap_mm') ?? 2.0;
      _barcodeVerticalGapMm = prefs.getDouble('barcode_vertical_gap_mm') ?? 2.0;
      _barcodeMarginMm = prefs.getDouble('barcode_margin_mm') ?? 1.1;
      _barcodeRightShiftMm = prefs.getDouble('barcode_right_shift_mm') ?? 0.0;
      _barcodeTopShiftMm = prefs.getDouble('barcode_top_shift_mm') ?? 12.0;
      if (_barcodeTopShiftMm > 25.0) {
        _barcodeTopShiftMm = 12.0;
      }
      _barcodeFontScale = prefs.getDouble('barcode_font_scale') ?? 1.0;
      _barcodeHeightMm = prefs.getDouble('barcode_height_mm') ?? 7.0;
      _barcodeShowStoreName = prefs.getBool('barcode_show_store_name') ?? false;
      _barcodeShowName = prefs.getBool('barcode_show_name') ?? true;
      _barcodeShowPrice = prefs.getBool('barcode_show_price') ?? true;
      _barcodeShowSku = prefs.getBool('barcode_show_sku') ?? true;
      _barcodeShowCodeText = prefs.getBool('barcode_show_code_text') ?? true;
      _barcodeShowCategory = prefs.getBool('barcode_show_category') ?? false;
      _barcodePrintIndividualImei = prefs.getBool('barcode_print_individual_imei') ?? true;
      _barcodeRotationDegrees = prefs.getInt('barcode_rotation_degrees') ?? 0;
      _barcodeColumns = prefs.getInt('barcode_columns') ?? 2;
    });
    _syncBarcodeControllersWithValues();
  }

  void _syncBarcodeControllersWithValues() {
    _barcodeRollWidthController.text = _barcodePaperWidthMm.toStringAsFixed(1);
    _barcodeLabelWidthController.text = _barcodeLabelWidthMm.toStringAsFixed(1);
    _barcodeLabelHeightController.text = _barcodeLabelHeightMm.toStringAsFixed(1);
    _barcodeHeightController.text = _barcodeHeightMm.toStringAsFixed(1);
    _barcodeColGapController.text = _barcodeHorizontalGapMm.toStringAsFixed(1);
    _barcodeRowGapController.text = _barcodeVerticalGapMm.toStringAsFixed(1);
    _barcodeTopShiftController.text = _barcodeTopShiftMm.toStringAsFixed(1);
    _barcodeLeftShiftController.text = _barcodeRightShiftMm.toStringAsFixed(1);
    _barcodeScaleController.text = _barcodeFontScale.toStringAsFixed(2);
  }

  Future<void> _saveDeviceLocalPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_localReceiptPrinterName != null) {
      await prefs.setString('local_printer_receipt_name', _localReceiptPrinterName!);
    } else {
      await prefs.remove('local_printer_receipt_name');
    }
    await prefs.setString('local_printer_paper_size', _localReceiptPaperSize);
    await prefs.setDouble('local_printer_paper_width_mm', _localPaperWidthMm);
    await prefs.setDouble('local_printer_margin_h_mm', _localMarginHMm);
    await prefs.setDouble('local_printer_margin_v_mm', _localMarginVMm);
    await prefs.setBool('local_printer_auto_print', _localAutoPrintOnSaleComplete);
    await prefs.setBool('local_printer_prompt_delivery_label', _localPromptDeliveryLabel);
    await prefs.setBool('local_cash_drawer_enabled', _localCashDrawerEnabled);
    if (_localCashDrawerPrinterName != null) {
      await prefs.setString('local_cash_drawer_printer_name', _localCashDrawerPrinterName!);
    } else {
      await prefs.remove('local_cash_drawer_printer_name');
    }
    await prefs.setString('local_cash_drawer_method', _localCashDrawerMethod);
    await prefs.setInt('local_cash_drawer_pulse_pin', _localCashDrawerPulsePin);
    await prefs.setInt('local_cash_drawer_pulse_on_ms', _localCashDrawerPulseOnMs);
    await prefs.setInt('local_cash_drawer_pulse_off_ms', _localCashDrawerPulseOffMs);
    await prefs.setString('local_cash_drawer_network_ip', _localCashDrawerNetworkIp);
    await prefs.setInt('local_cash_drawer_network_port', _localCashDrawerNetworkPort);
    if (_localLabelPrinterName != null) {
      await prefs.setString('local_printer_label_name', _localLabelPrinterName!);
    } else {
      await prefs.remove('local_printer_label_name');
    }
    await prefs.setString('local_printer_delivery_note_format', _localDeliveryNoteFormat);
    if (_localDeliveryNotePrinterName != null) {
      await prefs.setString('local_printer_delivery_note_printer_name', _localDeliveryNotePrinterName!);
    } else {
      await prefs.remove('local_printer_delivery_note_printer_name');
    }
    await _saveBarcodeSettings();
  }

  Future<void> _saveBarcodeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('barcode_preset', _barcodePreset);
    await prefs.setString('barcode_paper_format', _barcodePaperFormat);
    await prefs.setString('barcode_format', _barcodeFormat);
    await prefs.setString('barcode_printer_type', _barcodePrinterType);
    await prefs.setDouble('barcode_paper_width_mm', _barcodePaperWidthMm);
    await prefs.setDouble('barcode_label_width_mm', _barcodeLabelWidthMm);
    await prefs.setDouble('barcode_label_height_mm', _barcodeLabelHeightMm);
    await prefs.setDouble('barcode_horizontal_gap_mm', _barcodeHorizontalGapMm);
    await prefs.setDouble('barcode_vertical_gap_mm', _barcodeVerticalGapMm);
    await prefs.setDouble('barcode_margin_mm', _barcodeMarginMm);
    await prefs.setDouble('barcode_right_shift_mm', _barcodeRightShiftMm);
    await prefs.setDouble('barcode_top_shift_mm', _barcodeTopShiftMm);
    await prefs.setDouble('barcode_font_scale', _barcodeFontScale);
    await prefs.setDouble('barcode_height_mm', _barcodeHeightMm);
    await prefs.setBool('barcode_show_store_name', _barcodeShowStoreName);
    await prefs.setBool('barcode_show_name', _barcodeShowName);
    await prefs.setBool('barcode_show_price', _barcodeShowPrice);
    await prefs.setBool('barcode_show_sku', _barcodeShowSku);
    await prefs.setBool('barcode_show_code_text', _barcodeShowCodeText);
    await prefs.setBool('barcode_show_category', _barcodeShowCategory);
    await prefs.setBool('barcode_print_individual_imei', _barcodePrintIndividualImei);
    await prefs.setInt('barcode_rotation_degrees', _barcodeRotationDegrees);
    await prefs.setInt('barcode_columns', _barcodeColumns);
    if (_localLabelPrinterName != null) {
      await prefs.setString('local_printer_label_name', _localLabelPrinterName!);
    }
  }

  Future<void> _applyUiTheme(String themeName, {bool persist = true}) async {
    await context.read<ThemeController>().setThemeByName(
      themeName,
      persist: persist,
    );
  }

  List<_NavItem> get _storeNavItems => _orderedStoreNavItems;

  List<_NavItem> get _orderedStoreNavItems {
    final itemsByKey = {
      for (final item in _defaultStoreNavItems) item.key: item,
    };
    final seen = <String>{};
    final ordered = <_NavItem>[];
    for (final key in _sidebarNavOrder) {
      final item = itemsByKey[key];
      if (item != null && seen.add(item.key)) {
        if (item.key == 'mobileReload' && !_mobileReloadEnabled) continue;
        ordered.add(item);
      }
    }
    for (final item in _defaultStoreNavItems) {
      if (seen.add(item.key)) {
        if (item.key == 'mobileReload' && !_mobileReloadEnabled) continue;
        ordered.add(item);
      }
    }
    return ordered;
  }

  List<String> get _sidebarNavKeys =>
      _orderedStoreNavItems.map((item) => item.key).toList();

  void _resetSidebarNavOrder() {
    setState(() {
      _sidebarNavOrder = List<String>.from(_defaultSidebarNavOrder);
    });
  }

  @override
  void dispose() {
    _disposeTenantScopedResources();
    _salesSearchController.dispose();
    _installmentSearchController.dispose();
    _reportsSearchController.dispose();
    _customerSearchController.dispose();
    _attendanceSearchController.dispose();
    _employeeSearchController.dispose();
    _usersSearchController.dispose();
    _productSearchController.dispose();
    _posProductSearchFocusNode.dispose();
    _categoriesSearchController.dispose();
    _paymentMethodController.dispose();
    _storeNameController.dispose();
    _tenantIdController.dispose();
    _storeEmailController.dispose();
    _storePasswordController.dispose();
    _posCouponController.dispose();
    _posGiftCardController.dispose();
    _posCustomerSearchController.dispose();
    _posCustomerSearchFocusNode.dispose();
    _posCustomerNameController.dispose();
    _posCustomerPhoneController.dispose();
    _amountPaidController.dispose();
    _posNotesController.dispose();
    _chequeNumberController.dispose();
    _posShippingController.dispose();
    _posAgentNameController.dispose();
    _posAgentCommissionController.dispose();
    _purchaseOrderSearchController.dispose();
    _serviceSearchController.dispose();
    _warrantySearchController.dispose();
    _returnsSearchController.dispose();
    _barcodeSearchController.dispose();
    _barcodeRollWidthController.dispose();
    _barcodeLabelWidthController.dispose();
    _barcodeLabelHeightController.dispose();
    _barcodeHeightController.dispose();
    _barcodeColGapController.dispose();
    _barcodeRowGapController.dispose();
    _barcodeTopShiftController.dispose();
    _barcodeLeftShiftController.dispose();
    _barcodeScaleController.dispose();
    _platformSearchController.dispose();
    HardwareKeyboard.instance.removeHandler(_handleGlobalHardwareKey);
    super.dispose();
  }

  bool _handleGlobalHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // Only process hardware scans when on products or POS pages
    if (_selectedNavKey != 'products' && _selectedNavKey != 'pos') {
      return false;
    }

    // Never intercept if an add/edit product dialog or any modal is already active
    if (_isProductDialogOpen) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;

    final now = DateTime.now();
    // Barcode scanners deliver key strokes at < 150ms intervals
    if (now.difference(_lastProductScanTime).inMilliseconds > 200) {
      _productScanBuffer = '';
    }
    _lastProductScanTime = now;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final scanned = _productScanBuffer.trim();
      _productScanBuffer = '';
      if (scanned.length >= 2) {
        if (_selectedNavKey == 'products') {
          _handleProductPageBarcodeScan(scanned);
          return true;
        } else if (_selectedNavKey == 'pos') {
          _handleBarcodeOrSearchScan(scanned);
          return true;
        }
      }
    } else if (event.character != null &&
        event.character!.isNotEmpty &&
        event.character!.codeUnitAt(0) >= 32) {
      _productScanBuffer += event.character!;
    }

    return false;
  }

  Future<void> _enqueueSync(
    String action,
    String module,
    String reference,
  ) async {
    await _addToSyncQueue(action: action, module: module, reference: reference);
  }

  Future<void> _addToSyncQueue({
    required String action,
    required String module,
    required String reference,
  }) async {
    _syncQueue.add(
      _SyncItem(
        timestamp: DateTime.now(),
        action: action,
        module: module,
        reference: reference,
      ),
    );

    if (_syncService != null) {
      final payload = _buildSyncPayload(module, reference);
      await _syncService!.queueOperation(action, module, reference, payload);
    }

    await _refreshPendingSyncQueue();
    await _persistWorkspaceData();

    if (_syncService == null || !_syncService!.isAutoSyncSuppressed) {
      await _triggerImmediateSync(
        action: action,
        module: module,
        reference: reference,
      );
    }
  }

  Future<void> _refreshPendingSyncQueue() async {
    if (_syncService == null) return;

    final pending = await _syncService!.getPendingQueue();
    if (!mounted) return;

    setState(() {
      _syncQueue
        ..clear()
        ..addAll(
          pending
              .map(
                (item) => _SyncItem(
                  timestamp: item.createdAt,
                  action: item.operation,
                  module: item.entityTable,
                  reference: item.recordId,
                ),
              )
              .toList(),
        );
    });
  }

  void _ensureSyncService(String tenantId) {
    if (_syncService != null) return;
    final apiClient = context.read<ApiClient>();
    _syncService = SyncService(apiClient, tenantId);
    _productRepository?.updateSyncService(_syncService);
    _customerRepository?.updateSyncService(_syncService);
    _saleRepository?.updateSyncService(_syncService);

    // Called after the HTTP sync loop applies remote events to prefs.
    // We reload prefs into memory so the UI reflects the latest data
    // (locations, users, products, etc.) from other devices.
    _syncService!.startChangeListener(() async {
      await _loadPersistedWorkspaceData(); // pull synced data from prefs → memory
      await _loadCoreDataFromRepositories();
      await _refreshPendingSyncQueue();
      if (!mounted) return;
      setState(() {
        _lastSyncAt = DateTime.now();
        _lastSyncError = null;
      });
      // Re-persist so products/sales from the DB layer are also saved.
      await _persistWorkspaceData();
    });

    // Run an initial full sync on login so the new device gets all server data.
    Future<void>(() async {
      final synced = await _syncService!.syncAllData();
      if (!mounted) return;
      if (synced) {
        // IMPORTANT: load prefs into memory BEFORE re-persisting.
        // _pullChanges() writes synced entities (locations, users, etc.) to prefs.
        // If we call _persistWorkspaceData() first it overwrites those changes
        // with the stale in-memory state, making newly synced data invisible.
        await _loadPersistedWorkspaceData();
        await _loadCoreDataFromRepositories();
        await _refreshPendingSyncQueue();
        if (!mounted) return;
        setState(() {
          _lastSyncAt = DateTime.now();
          _lastSyncError = null;
        });
        await _persistWorkspaceData();
      }
    });
  }

  Map<String, dynamic> _buildSyncPayload(String module, String reference) {
    Map<String, dynamic>? findById<T>(
      List<T> items,
      String Function(T item) idOf,
      Map<String, dynamic> Function(T item) toJson,
    ) {
      for (final item in items) {
        if (idOf(item) == reference) {
          return toJson(item);
        }
      }
      return null;
    }

    switch (module) {
      case 'products':
      case 'inventory':
        final productPayload = findById<_ProductItem>(
          _products,
          (item) => item.id,
          (item) => item.toJson(),
        );
        if (productPayload == null) {
          return {'id': reference, '_id': reference};
        }

        return {
          ...productPayload,
          'id': reference,
          '_id': reference,
          'tenantId': _activeTenantId ?? 'local',
          'sku': (productPayload['id'] ?? reference).toString(),
          'type':
              (productPayload['productType'] ??
                      productPayload['type'] ??
                      'PRODUCT')
                  .toString()
                  .toUpperCase(),
          'unitOfMeasure':
              (productPayload['measureUnit'] ??
                      productPayload['unitOfMeasure'] ??
                      'PIECE')
                  .toString()
                  .toUpperCase(),
          'stock': (productPayload['stock'] as num?)?.toDouble() ?? 0,
          'minStock': (productPayload['minStock'] as num?)?.toDouble() ?? 0,
          'price': (productPayload['price'] as num?)?.toDouble() ?? 0,
          'costPrice': (productPayload['costPrice'] as num?)?.toDouble(),
          'locationId':
              (productPayload['locationId'] ?? _activeLocationForWrites)
                  .toString(),
        };
      case 'customers':
        return findById<_CustomerItem>(
              _customers,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'employees':
        final employeePayload = findById<_EmployeeItem>(
          _employees,
          (item) => item.id,
          (item) => item.toJson(),
        );
        if (employeePayload == null) {
          return {'id': reference};
        }
        final employeeLocations =
            (employeePayload['assignedLocations'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .toList();
        employeePayload['tenantId'] = _activeTenantId ?? 'local';
        employeePayload['locationId'] = employeeLocations.isEmpty
            ? _storeLocation
            : employeeLocations.first;
        employeePayload['role'] = (employeePayload['role'] ?? 'STAFF')
            .toString()
            .toUpperCase();
        employeePayload['email'] = (employeePayload['email'] ?? '')
            .toString()
            .trim();
        employeePayload['name'] = (employeePayload['name'] ?? 'Employee')
            .toString();
        return employeePayload;
      case 'users':
        final userPayload = findById<_UserItem>(
          _users,
          (item) => item.id,
          (item) => item.toJson(),
        );
        if (userPayload == null) {
          return {'id': reference};
        }
        userPayload['tenantId'] = _activeTenantId ?? 'local';
        userPayload['role'] = (userPayload['role'] ?? 'CASHIER')
            .toString()
            .toUpperCase();
        userPayload['permissions'] =
            (userPayload['permissions'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList();
        userPayload['locations'] =
            (userPayload['locations'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList();
        return userPayload;
      case 'locations':
        return findById<_LocationItem>(
              _locations,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'stock_transfers':
        return findById<_StockTransferItem>(
              _stockTransfers,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'suppliers':
        return findById<_SupplierItem>(
              _suppliers,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'coupons':
        for (final item in _coupons) {
          if (item.code == reference) {
            return item.toJson();
          }
        }
        return {'code': reference};
      case 'services':
      case 'job_cards':
        return findById<_ServiceJobItem>(
              _serviceJobs,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'returns':
        return findById<_ReturnItem>(
              _returns,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'sales':
        return findById<_SaleRecord>(
              _sales,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'installments':
        return findById<_InstallmentPlan>(
              _installmentPlans,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'credit_payments':
        for (final entry in _customerCreditPayments.entries) {
          for (final payment in entry.value) {
            if (payment.id == reference) {
              return {...payment.toJson(), 'customerId': entry.key};
            }
          }
        }
        return {'id': reference};
      case 'credit_sales':
        for (final entry in _customerCreditSales.entries) {
          for (final sale in entry.value) {
            if (sale.id == reference) {
              return sale.toJson();
            }
          }
        }
        return {'id': reference};
      case 'purchase_orders':
        return findById<_PurchaseOrderItem>(
              _purchaseOrders,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'attendance':
        return findById<_AttendanceRecordItem>(
              _attendanceRecords,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'payroll':
        return findById<_PayrollRecordItem>(
              _payrollRecords,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'stock_adjustments':
        return findById<_StockAdjustmentItem>(
              _stockAdjustments,
              (item) => item.id,
              (item) => item.toJson(),
            ) ??
            {'id': reference};
      case 'categories':
        return {
          'category': reference,
          'attributes': (_categoryAttributes[reference] ?? [])
              .map((e) => e.toJson())
              .toList(),
        };
      case 'settings':
        return {
          'companyName': _companyName,
          'invoicePattern': _invoicePattern,
          'invoicePrefix': _invoicePrefix,
          'invoiceIncludeLocation': _invoiceIncludeLocation,
          'invoiceLocationLength': _invoiceLocationLength,
          'invoiceIncludeUser': _invoiceIncludeUser,
          'invoiceUserLength': _invoiceUserLength,
          'invoiceIncludeDate': _invoiceIncludeDate,
          'taxRate': _taxRate,
          'currency': _currency,
          'storeLocation': _storeLocation,
          'receiptHeader': _receiptHeader,
          'receiptFooter': _receiptFooter,
          'receiptShowTax': _receiptShowTax,
          'receiptShowLogo': _receiptShowLogo,
          'receiptShowCompanyName': _receiptShowCompanyName,
          'receiptShowShopAddress': _receiptShowShopAddress,
          'receiptShowShopPhone': _receiptShowShopPhone,
          'receiptShowReceiptTitle': _receiptShowReceiptTitle,
          'receiptShowReceiptNumber': _receiptShowReceiptNumber,
          'receiptShowDate': _receiptShowDate,
          'receiptShowTime': _receiptShowTime,
          'receiptShowCashier': _receiptShowCashier,
          'receiptShowCustomer': _receiptShowCustomer,
          'receiptShowPaymentMethod': _receiptShowPaymentMethod,
          'receiptShowBalance': _receiptShowBalance,
          'receiptShowReturnPolicy': _receiptShowReturnPolicy,
          'allowReprintSalesBill': _allowReprintSalesBill,
          'enableWhatsappCodNotifications': _enableWhatsappCodNotifications,
          'receiptNote': _receiptNote,
          'openFrom': _openFrom,
          'openTo': _openTo,
          'acceptCash': _acceptCash,
          'acceptCard': _acceptCard,
          'acceptCheque': _acceptCheque,
          'acceptInstallment': _acceptInstallment,
          'integrationMode': _integrationMode,
          'integrationWebhook': _integrationWebhook,
          'notifyLowStock': _notifyLowStock,
          'notifyDailySummary': _notifyDailySummary,
          'notifyReturns': _notifyReturns,
          'cashDrawerEnabled': _cashDrawerEnabled,
          'cashDrawerRequirePin': _cashDrawerRequirePin,
          'cashDrawerPin': _cashDrawerPin,
          'receiptPaper': _receiptPaper,
          'receiptMargin': _receiptMargin,
          'receiptFontScale': _receiptFontScale,
          'profileName': _profileName,
          'profileEmail': _profileEmail,
          'profilePhone': _profilePhone,
          'companyEmail': _companyEmail,
          'companyPhone': _companyPhone,
          'companyAddress': _companyAddress,
          'companyRegNo': _companyRegNo,
          'companyLogoPath': _companyLogoPath,
          'uiTheme': _uiTheme,
          'uiLanguage': _uiLanguage,
          'prefSound': _prefSound,
          'prefAutoPrint': _prefAutoPrint,
          'prefCompact': _prefCompact,
          'prefRequireSaleConfirmation': _prefRequireSaleConfirmation,
          'notifyEmail': _notifyEmail,
          'notifySms': _notifySms,
          'notifyPayroll': _notifyPayroll,
          'payrollCycle': _payrollCycle,
          'payrollWorkingDays': _payrollWorkingDays,
          'payrollOtRate': _payrollOtRate,
          'payrollLatePenalty': _payrollLatePenalty,
          'payrollAutoGenerate': _payrollAutoGenerate,
          'payrollEnableEpf': _payrollEnableEpf,
          'lastSyncAt': _lastSyncAt?.toIso8601String(),
        };
      case 'expenses':
        final exp = _expensesList.cast<db.Expense?>().firstWhere(
              (item) => item?.id == reference,
              orElse: () => null,
            );
        if (exp != null) {
          return {
            'id': exp.id,
            '_id': exp.id,
            'tenantId': exp.tenantId.isNotEmpty
                ? exp.tenantId
                : (_activeTenantId ?? 'local'),
            'category': exp.category,
            'description': exp.description,
            'amount': exp.amount,
            'locationId': exp.locationId,
            'employeeId': exp.employeeId,
            'notes': exp.notes,
            'expenseDate': exp.expenseDate.toIso8601String(),
            'createdAt': exp.createdAt?.toIso8601String() ?? exp.expenseDate.toIso8601String(),
            'updatedAt': (exp.updatedAt ?? exp.createdAt ?? exp.expenseDate).toIso8601String(),
          };
        }
        return {'id': reference};
      case 'bank_transactions':
        final btx = _bankTransactions.cast<_BankTransaction?>().firstWhere(
              (item) => item?.id == reference,
              orElse: () => null,
            );
        if (btx != null) {
          return {
            ...btx.toJson(),
            'tenantId': _activeTenantId ?? 'local',
            'updatedAt': btx.createdAt.toIso8601String(),
          };
        }
        return {'id': reference};
      case 'cashier_sessions':
        final sess = _cashierSessions.cast<_CashierSession?>().firstWhere(
              (item) => item?.id == reference,
              orElse: () => null,
            );
        if (sess != null) {
          return {
            ...sess.toJson(),
            'tenantId': _activeTenantId ?? 'local',
            'updatedAt': (sess.closingTime ?? sess.openingTime).toIso8601String(),
          };
        }
        return {'id': reference};
      case 'mobile_reloads':
        final rld = _mobileReloads.cast<_MobileReloadRecord?>().firstWhere(
              (item) => item?.id == reference,
              orElse: () => null,
            );
        if (rld != null) {
          return {
            ...rld.toJson(),
            'tenantId': _activeTenantId ?? 'local',
            'updatedAt': rld.createdAt.toIso8601String(),
          };
        }
        return {'id': reference};
      default:
        return {'id': reference};
    }
  }

  double _unitInventoryCost(_ProductItem product) {
    final cost = product.costPrice;
    if (cost != null && cost > 0) {
      return cost;
    }
    return product.price;
  }

  double _inventoryValue() {
    return _products.fold<double>(
      0,
      (sum, product) => sum + (_unitInventoryCost(product) * product.stock),
    );
  }

  void _disposeTenantScopedResources() {
    _syncService?.dispose();
    _syncService = null;

    _appDatabase = null;
    _productRepository = null;
    _customerRepository = null;
    _saleRepository = null;
    _activeTenantId = null;
    _coreDataLoaded = false;
    _syncQueueLoaded = false;
    _syncQueue.clear();
  }

  String? _resolveLinkedEmployeeIdForUser({
    required String userId,
    required String email,
  }) {
    final normalizedId = userId.trim();
    if (normalizedId.isEmpty) return null;

    for (final employee in _employees) {
      if (employee.linkedUserId.trim() == normalizedId) {
        return employee.id;
      }
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;
    for (final user in _users) {
      if (user.id == normalizedId ||
          user.email.trim().toLowerCase() != normalizedEmail) {
        continue;
      }
      if (user.linkedEmployeeId.trim().isNotEmpty) {
        return user.linkedEmployeeId.trim();
      }
      for (final employee in _employees) {
        if (employee.email.trim().toLowerCase() == normalizedEmail) {
          return employee.id;
        }
      }
    }

    return null;
  }

  String get _currentEmployeeIdForSales =>
      _resolveLinkedEmployeeIdForUser(
        userId: _currentUserId,
        email: _currentUserEmail,
      ) ??
      _currentUserId;

  _EmployeeItem _employeeFromUser(_UserItem user, {String? linkedUserId}) {
    return _EmployeeItem(
      id: linkedUserId ?? user.id,
      name: user.name,
      role: user.role,
      active: user.active,
      firstName: user.name.trim().split(RegExp(r'\s+')).first,
      lastName: user.name.trim().split(RegExp(r'\s+')).length > 1
          ? user.name.trim().split(RegExp(r'\s+')).sublist(1).join(' ')
          : '',
      email: user.email,
      phone: '',
      position: user.role,
      department: '',
      paymentType: 'Monthly',
      baseSalary: 0,
      hireDate: '',
      bankAccount: '',
      address: '',
      emergencyContact: '',
      emergencyPhone: '',
      notes: '',
      assignedLocations: List<String>.from(user.locations),
      linkedUserId: user.id,
      permissions: List<String>.from(user.permissions),
    );
  }

  _UserItem _userFromEmployee(
    _EmployeeItem employee, {
    required String userId,
    required List<String> permissions,
    required List<String> locations,
  }) {
    return _UserItem(
      id: userId,
      name: employee.name,
      email: employee.email,
      role: employee.role,
      active: employee.active,
      permissions: permissions,
      locations: locations,
      linkedEmployeeId: employee.id,
    );
  }

  void _ensureTenantScope(String tenantId) {
    if (_activeTenantId == null || _activeTenantId == tenantId) {
      return;
    }

    _disposeTenantScopedResources();
  }

  void _ensureRepositories(String tenantId) {
    _appDatabase ??= db.AppDatabase(tenantId);
    _activeTenantId = tenantId;
    if (_productRepository == null) {
      _productRepository = ProductRepository(_appDatabase!, _syncService);
    } else {
      _productRepository!.updateSyncService(_syncService);
    }
    if (_customerRepository == null) {
      _customerRepository = CustomerRepository(_appDatabase!, _syncService);
    } else {
      _customerRepository!.updateSyncService(_syncService);
    }
    if (_saleRepository == null) {
      _saleRepository = SaleRepository(_appDatabase!, _syncService);
    } else {
      _saleRepository!.updateSyncService(_syncService);
    }

    if (!_coreDataLoaded) {
      _coreDataLoaded = true;
      _loadCoreDataFromRepositories();
    }
  }

  Future<void> _loadCoreDataFromRepositories() async {
    if (_productRepository == null ||
        _customerRepository == null ||
        _saleRepository == null) {
      return;
    }

    final repoExpenses = await _appDatabase!.getAllExpenses();
    final repoProducts = await _productRepository!.getAllProducts();
    final repoCustomers = await _customerRepository!.getAllCustomers();
    final repoSales = await _saleRepository!.getAllSales();
    final repoDiscounts = await _appDatabase!.getAllDiscounts();
    final existingProductsById = <String, _ProductItem>{
      for (final product in _products) product.id: product,
    };

    if (!mounted) return;
    setState(() {
      final hydratedProducts = repoProducts.map((repoProduct) {
        final mapped = _fromDomainProduct(repoProduct);
        final existing = existingProductsById[mapped.id];
        if (existing != null && existing.attributeValues.isNotEmpty) {
          mapped.attributeValues = Map<String, dynamic>.from(
            existing.attributeValues,
          );
        }
        return mapped;
      }).toList();

      final hydratedMap = {for (final p in hydratedProducts) p.id: p};
      final mergedProducts = <_ProductItem>[...hydratedProducts];
      for (final p in _products) {
        if (!hydratedMap.containsKey(p.id) && p.id.isNotEmpty) {
          mergedProducts.add(p);
        }
      }

      _products
        ..clear()
        ..addAll(mergedProducts);

      final hydratedCustomers = repoCustomers.map(_fromDomainCustomer).toList();
      final custMap = {for (final c in hydratedCustomers) c.id: c};
      final mergedCustomers = <_CustomerItem>[...hydratedCustomers];
      for (final c in _customers) {
        if (!custMap.containsKey(c.id) && c.id.isNotEmpty) {
          mergedCustomers.add(c);
        }
      }

      _customers
        ..clear()
        ..addAll(mergedCustomers);
      _selectedCustomerId = null;

      _sales
        ..clear()
        ..addAll(repoSales.map(_fromDomainSale))
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _discountDefinitions
        ..clear()
        ..addAll(repoDiscounts);

      _expensesList
        ..clear()
        ..addAll(repoExpenses);
    });
  }

  Future<void> _handleProductCreation(_ProductDialogResult result) async {
    final item = result.product;
    final locationStocks = result.locationStocks;
    final locationImeis = result.locationImeis;

    final itemsToCreate = <_ProductItem>[];

    if (locationStocks != null && locationStocks.isNotEmpty) {
      var isFirst = true;
      for (final entry in locationStocks.entries) {
        final locName = entry.key;
        final stockVal = entry.value;
        final locImeis = locationImeis?[locName];

        final newItem = _ProductItem(
          id: isFirst
              ? item.id
              : '${item.id}_${locName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${DateTime.now().microsecondsSinceEpoch}',
          name: item.name,
          category: item.category,
          barcode: item.barcode,
          measureUnit: item.measureUnit,
          productType: item.productType,
          description: item.description,
          costPrice: item.costPrice,
          warrantyMonths: item.warrantyMonths,
          expiryDate: item.expiryDate,
          expiryReminderMode: item.expiryReminderMode,
          expiryReminderDays: item.expiryReminderDays,
          attributeValues: Map<String, dynamic>.from(item.attributeValues),
          price: item.price,
          minPrice: item.minPrice,
          stock: stockVal,
          minStock: item.minStock,
          supplierId: item.supplierId,
          locationId: locName,
          imeis: locImeis != null && locImeis.isNotEmpty
              ? jsonEncode(locImeis)
              : null,
          imageUrl: item.imageUrl,
        );
        itemsToCreate.add(newItem);
        isFirst = false;
      }
    } else {
      if (item.locationId.isEmpty) {
        item.locationId = _activeLocationForWrites;
      }
      itemsToCreate.add(item);
    }

    for (final targetItem in itemsToCreate) {
      var addedCategoryToCatalog = false;
      if (!mounted) return;
      setState(() {
        _products.add(targetItem);
        if (!_productCategories.any(
          (c) => c.toLowerCase() == targetItem.category.toLowerCase(),
        )) {
          _productCategories.add(targetItem.category);
          addedCategoryToCatalog = true;
        }
      });
      await _persistWorkspaceData();

      if (addedCategoryToCatalog) {
        await _enqueueSync('UPDATE', 'categories', targetItem.category);
      }

      if (_productRepository != null) {
        _productRepository!.updateSyncService(_syncService);
        await _productRepository!.insertProduct(_toDomainProduct(targetItem));
        await _refreshPendingSyncQueue();
        await _triggerImmediateSync(
          action: 'INSERT',
          module: 'products',
          reference: targetItem.id,
        );
      } else {
        await _enqueueSync('INSERT', 'products', targetItem.id);
      }
    }

    _notifyExpiryReminders();
  }

  domain.Product _toDomainProduct(_ProductItem item) {
    final tenantId = _activeTenantId ?? 'local';
    final normalizedUnit = item.measureUnit.trim().toUpperCase();
    final normalizedType = item.productType.trim().toUpperCase();

    String finalDescription = item.description
        .replaceAll(RegExp(r'<!--DUAL_UNIT:.*?-->'), '')
        .trim();
    if (item.allowLooseSales) {
      final meta = jsonEncode({
        'allowLooseSales': true,
        'secondaryUnit': item.secondaryUnit,
        'unitConversionRatio': item.unitConversionRatio,
        'secondaryPrice': item.secondaryPrice,
      });
      finalDescription = '$finalDescription<!--DUAL_UNIT:$meta-->'.trim();
    }

    return domain.Product(
      id: item.id,
      tenantId: tenantId,
      name: item.name,
      description: finalDescription,
      sku: item.id,
      barcode: item.barcode.isEmpty ? null : item.barcode,
      price: item.price,
      costPrice: item.costPrice,
      category: item.category,
      type: normalizedType.isEmpty ? 'PRODUCT' : normalizedType,
      unitOfMeasure: normalizedUnit.isEmpty ? 'PIECE' : normalizedUnit,
      stock: item.stock.toDouble(),
      minStock: item.minStock.toDouble(),
      minPrice: item.minPrice,
      warrantyMonths: item.warrantyMonths,
      expiryDate: item.expiryDate,
      locationId: item.locationId,
      supplierId: item.supplierId,
      imeis: item.imeis,
      imageUrl: item.imageUrl,
      synced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  _ProductItem _fromDomainProduct(domain.Product p) {
    final attrs = <String, dynamic>{};
    final match = RegExp(r'<!--DUAL_UNIT:(.*?)-->').firstMatch(p.description);
    if (match != null) {
      try {
        final decoded = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        attrs.addAll(decoded);
      } catch (_) {}
    }
    final cleanDescription = p.description
        .replaceAll(RegExp(r'<!--DUAL_UNIT:.*?-->'), '')
        .trim();

    return _ProductItem(
      id: p.id,
      name: p.name,
      category: p.category,
      description: cleanDescription,
      price: p.price,
      costPrice: p.costPrice,
      minPrice: p.minPrice,
      stock: p.stock,
      minStock: p.minStock,
      barcode: p.barcode ?? p.id,
      measureUnit: p.unitOfMeasure,
      productType: p.type,
      warrantyMonths: p.warrantyMonths,
      expiryDate: p.expiryDate,
      locationId: p.locationId ?? _storeLocation,
      supplierId: p.supplierId,
      imeis: p.imeis,
      imageUrl: p.imageUrl,
      attributeValues: attrs,
    );
  }

  domain.Customer _toDomainCustomer(_CustomerItem item) {
    final tenantId = _activeTenantId ?? 'local';
    return domain.Customer(
      id: item.id,
      tenantId: tenantId,
      name: item.name,
      phone: item.phone,
      email: item.email.isEmpty ? null : item.email,
      address: item.address.isEmpty ? null : item.address,
      vehicleNumber: item.vehicleNumber.isEmpty ? null : item.vehicleNumber,
      creditLimit: item.creditLimit,
      currentBalance: item.currentBalance,
      customerType: item.customerType,
      discountPercent: item.discountPercent,
      synced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      shippingAddress: item.shippingAddress,
    );
  }

  _CustomerItem _fromDomainCustomer(domain.Customer c) {
    return _CustomerItem(
      id: c.id,
      name: c.name,
      locationId: _activeLocationForWrites,
      phone: c.phone,
      email: c.email ?? '',
      address: c.address ?? '',
      vehicleNumber: c.vehicleNumber ?? '',
      creditLimit: c.creditLimit,
      currentBalance: c.currentBalance,
      loyaltyPoints: 0,
      customerType: c.customerType,
      discountPercent: c.discountPercent,
      shippingAddress: c.shippingAddress ?? '',
    );
  }

  db.EmployeesCompanion _employeeItemToCompanion(_EmployeeItem employee) {
    return db.EmployeesCompanion(
      id: Value(employee.id),
      tenantId: Value(_activeTenantId ?? 'local'),
      name: Value(employee.name),
      email: Value(employee.email),
      phone: Value(employee.phone.isEmpty ? null : employee.phone),
      role: Value(employee.role),
      locationId: Value(
        employee.assignedLocations.isNotEmpty
            ? employee.assignedLocations.first
            : _activeLocationForWrites,
      ),
      commissionType: const Value('NONE'),
      commissionValue: const Value(0.0),
      minSalesTarget: const Value(0.0),
      isAgent: Value(employee.role.toUpperCase() == 'AGENT'),
      synced: const Value(false),
      createdAt: Value(DateTime.now().toUtc()),
    );
  }

  domain.Sale _toDomainSale(_SaleRecord sale, List<_CartLine> lines) {
    final tenantId = _activeTenantId ?? 'local';
    final items = lines
        .map(
          (line) => domain.SaleItem(
            id: '${sale.id}-${line.product.id}',
            saleId: sale.id,
            productId: line.product.id,
            productName: line.product.name,
            quantity: line.qty.toDouble(),
            unitPrice: line.unitPriceAfterDiscount,
            originalPrice: line.unitPriceBeforeDiscount,
            discount: line.discountValue,
            discountType: line.discountType,
            total: line.totalPrice,
            tenantId: tenantId,
          ),
        )
        .toList();

    return domain.Sale(
      id: sale.id,
      tenantId: tenantId,
      customerId: sale.customerId.isEmpty ? null : sale.customerId,
      employeeId: sale.employeeId.isEmpty
          ? _currentEmployeeIdForSales
          : sale.employeeId,
      invoiceNumber: sale.invoiceNumber.isEmpty ? sale.id : sale.invoiceNumber,
      cashierName: sale.cashierName,
      customerOutstandingBefore: sale.customerOutstandingBefore,
      customerOutstandingAfter: sale.customerOutstandingAfter,
      total: sale.total,
      tax: sale.tax,
      discount: sale.discount,
      amountPaid: sale.amountPaid,
      balance: sale.balance,
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      locationId: sale.locationId,
      synced: false,
      createdAt: sale.createdAt,
      updatedAt: DateTime.now(),
      shippingCharges: sale.shippingCharges,
      agentName: sale.agentName,
      agentCommission: sale.agentCommission,
      agentCommissionType: sale.agentCommissionType,
      agentCommissionPaid: sale.agentCommissionPaid,
      items: items,
      notes: sale.notes,
      shippingAddress: sale.shippingAddress,
      deliveryPersonId: sale.deliveryPersonId,
      deliveryPersonName: sale.deliveryPersonName,
      deliveryStatus: sale.deliveryStatus,
      deliveredAt: sale.deliveredAt,
      deliveryOtp: sale.deliveryOtp,
      settledAt: sale.settledAt,
      settledByEmployeeId: sale.settledByEmployeeId,
      settledByCashierName: sale.settledByCashierName,
      customer: sale.customerId.isNotEmpty && sale.customerId != 'C001'
          ? () {
              final matched = _customers.where((c) => c.id == sale.customerId);
              if (matched.isNotEmpty) {
                return _toDomainCustomer(matched.first);
              }
              if (sale.customerName != 'Walk-in Customer') {
                return domain.Customer(
                  id: sale.customerId,
                  tenantId: tenantId,
                  name: sale.customerName,
                  phone: sale.customerPhone,
                  address: sale.customerAddress,
                  creditLimit: 0,
                  currentBalance: sale.customerOutstandingAfter ?? 0.0,
                  synced: true,
                );
              }
              return null;
            }()
          : null,
      installmentSchedules: sale.installmentSchedules
          .map(
            (line) => domain.InstallmentPaymentLine(
              installmentNo: line.installmentNo,
              dueDate: line.dueDate,
              scheduledAmount: line.amount,
              paidAmount: line.paidAmount,
              remainingAmount: line.remainingAmount,
              isPaid: line.isPaid,
            ),
          )
          .toList(),
    );
  }

  String _buildLocalSaleId(DateTime createdAt) {
    final normalizedLocation = _activeLocationForWrites.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    final normalizedUser = _currentUserId.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );

    return 'S${createdAt.toUtc().microsecondsSinceEpoch}-${normalizedLocation.isEmpty ? 'LOC' : normalizedLocation}-${normalizedUser.isEmpty ? 'USER' : normalizedUser}';
  }

  Future<String> _buildInvoiceNumber(DateTime createdAt) async {
    final prefix = _invoicePrefix
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    // 1. Get Location Code
    final normalizedLocation = _activeLocationForWrites
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final int locLen = int.tryParse(_invoiceLocationLength) ?? 2;
    final locCode = normalizedLocation.isEmpty
        ? 'LOC'.substring(0, locLen.clamp(1, 3)).padRight(locLen, 'X')
        : (normalizedLocation.length > locLen
              ? normalizedLocation.substring(0, locLen)
              : normalizedLocation.padRight(locLen, 'X'));

    // 2. Get User / Cashier Code
    final cleanUserName = _currentUserName
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final cashierCode = cleanUserName.isNotEmpty ? cleanUserName : 'CASHIER1';

    final normalizedUser = _currentUserId
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final int userLen = int.tryParse(_invoiceUserLength) ?? 2;
    final userCode = normalizedUser.isEmpty
        ? 'USR'.substring(0, userLen.clamp(1, 3)).padRight(userLen, 'X')
        : (normalizedUser.length > userLen
              ? normalizedUser.substring(0, userLen)
              : normalizedUser.padRight(userLen, 'X'));

    // 3. Get Date Code
    final dateLocal = createdAt.toLocal();
    final year = dateLocal.year.toString().substring(2);
    final month = dateLocal.month.toString().padLeft(2, '0');
    final day = dateLocal.day.toString().padLeft(2, '0');
    final dateStr = '$year$month$day';

    // 4. Get Sequence
    int totalCount = _sales.length;
    if (_appDatabase != null) {
      try {
        final dbCount = await _appDatabase!.getSalesCountForToday(
          _activeLocationForWrites,
          _currentUserId,
          dateLocal,
        );
        if (dbCount > totalCount) totalCount = dbCount;
      } catch (_) {}
    }
    final nextNumber = totalCount + 1;
    final seqStr = nextNumber.toString();
    final seqPadded = nextNumber.toString().padLeft(4, '0');

    // 5. Parse Pattern
    String pattern = _invoicePattern.trim();
    final pfx = prefix.isEmpty ? 'INV' : prefix;
    if (pattern.isEmpty ||
        pattern == '{PREFIX}-{LOC}-{USR}-{DATE}-{SEQ}{RAND}' ||
        pattern == '{PREFIX}-{SEQ}' ||
        pattern.startsWith('#') ||
        pattern.length < 5 ||
        !pattern.contains('{SEQ}')) {
      return '$pfx-$cashierCode-$dateStr-#$seqPadded';
    }

    final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final randChar =
        alphabet[(createdAt.microsecondsSinceEpoch % alphabet.length)];

    String result = pattern
        .replaceAll('{PREFIX}', pfx)
        .replaceAll('{CASHIER}', cashierCode)
        .replaceAll('{LOC}', locCode)
        .replaceAll('{USR}', userCode)
        .replaceAll('{DATE}', dateStr)
        .replaceAll('{SEQ4}', seqPadded)
        .replaceAll('{SEQ}', seqPadded)
        .replaceAll('{RAND}', randChar);

    // Clean up double and trailing/leading separators
    result = result
        .replaceAll(RegExp(r'[-/_]{2,}'), '-')
        .replaceAll(RegExp(r'^[-/_]+|[-/_]+$'), '');
    if (result.isEmpty || result.length < 5 || result.startsWith('#')) {
      return '$pfx-$cashierCode-$dateStr-#$seqPadded';
    }
    return result.toUpperCase();
  }

  String _formatDisplayInvoiceNumber(_SaleRecord sale) {
    final inv = sale.invoiceNumber.trim();
    if (inv.isNotEmpty &&
        inv != '#' &&
        !RegExp(r'^#[0-9A-Z]{1,2}$').hasMatch(inv) &&
        !inv.startsWith('S17') &&
        !inv.contains('Branch-')) {
      return inv;
    }

    final d = sale.createdAt.toLocal();
    final year = d.year.toString().substring(2);
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final dateStr = '$year$month$day';
    final cleanCashier = sale.cashierName
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final cashierPart = cleanCashier.isNotEmpty ? cleanCashier : 'POS';

    String shortId = sale.id;
    if (shortId.contains('-')) {
      final parts = shortId.split('-');
      if (parts.isNotEmpty) {
        final lastPart = parts.last;
        shortId = lastPart.length > 5
            ? lastPart.substring(lastPart.length - 4)
            : lastPart;
      }
    } else if (shortId.length > 4) {
      shortId = shortId.substring(shortId.length - 4);
    }
    return 'INV-$cashierPart-$dateStr-#${shortId.toUpperCase()}';
  }

  _SaleRecord _fromDomainSale(domain.Sale s) {
    String customerName = 'Walk-in Customer';
    String customerPhone = s.customer?.phone ?? '';
    String customerAddress = s.customer?.address ?? '';
    if (s.customer?.name.trim().isNotEmpty == true) {
      customerName = s.customer!.name;
    } else if ((s.customerId ?? '').trim().isNotEmpty) {
      for (final customer in _customers) {
        if (customer.id == s.customerId) {
          customerName = customer.name;
          if (customerPhone.isEmpty) customerPhone = customer.phone;
          if (customerAddress.isEmpty) customerAddress = customer.address ?? '';
          break;
        }
      }
    }

    final employeeId = s.employeeId.trim();
    String cashierName = 'Cashier';
    if (s.cashierName?.trim().isNotEmpty == true) {
      cashierName = s.cashierName!;
    } else {
      if (employeeId.isNotEmpty) {
        if (employeeId == _currentUserId) {
          cashierName = _currentUserName;
        } else {
          for (final user in _users) {
            if (user.id == employeeId) {
              cashierName = user.name;
              break;
            }
          }
          if (cashierName == 'Cashier') {
            for (final employee in _employees) {
              if (employee.id == employeeId) {
                cashierName = employee.name;
                break;
              }
            }
          }
        }
      }
    }

    double outstandingBefore = s.customerOutstandingBefore ?? 0.0;
    double outstandingAfter = s.customerOutstandingAfter ?? 0.0;
    if (s.customerOutstandingBefore == null ||
        s.customerOutstandingAfter == null) {
      if (s.customerId != null && s.customerId!.isNotEmpty) {
        final entries = _customerCreditSales[s.customerId];
        if (entries != null) {
          for (final entry in entries) {
            if (entry.saleId == s.id) {
              outstandingBefore = entry.customerOutstandingBefore;
              outstandingAfter = entry.customerOutstandingAfter;
              break;
            }
          }
        }
      }
    }

    double resolvedAmountPaid = s.amountPaid ?? s.total;
    double resolvedBalance = s.balance ?? 0.0;
    final isCod = s.paymentMethod.toUpperCase() == 'COD';
    final isCodCompleted = isCod && s.status.toUpperCase() == 'COMPLETED';

    if (isCod) {
      if (isCodCompleted) {
        resolvedAmountPaid = s.total;
        resolvedBalance = 0.0;
      } else {
        resolvedAmountPaid = s.amountPaid ?? 0.0;
        resolvedBalance = s.total - resolvedAmountPaid;
      }
    } else if (s.amountPaid == null || s.balance == null) {
      if (s.paymentMethod == 'CREDIT') {
        bool foundEntry = false;
        if (s.customerId != null && s.customerId!.isNotEmpty) {
          final entries = _customerCreditSales[s.customerId];
          if (entries != null) {
            for (final entry in entries) {
              if (entry.saleId == s.id) {
                resolvedAmountPaid = entry.amountPaidOnSale;
                resolvedBalance = entry.outstandingAmount;
                foundEntry = true;
                break;
              }
            }
          }
        }
        if (!foundEntry) {
          resolvedAmountPaid = 0.0;
          resolvedBalance = s.total;
        }
      } else if (s.paymentMethod == 'INSTALLMENT') {
        bool foundPlan = false;
        for (final plan in _installmentPlans) {
          if (plan.saleId == s.id) {
            resolvedAmountPaid = plan.downPayment;
            resolvedBalance = plan.totalAmount - plan.downPayment;
            foundPlan = true;
            break;
          }
        }
        if (!foundPlan) {
          resolvedAmountPaid = 0.0;
          resolvedBalance = s.total;
        }
      } else {
        resolvedAmountPaid = s.total;
        resolvedBalance = 0.0;
      }
    }

    List<_InstallmentScheduleItem> resolvedInstallments = [];
    if (s.installmentSchedules.isNotEmpty) {
      resolvedInstallments = s.installmentSchedules
          .map(
            (line) => _InstallmentScheduleItem(
              installmentNo: line.installmentNo,
              amount: line.scheduledAmount,
              paidAmount: line.paidAmount,
              dueDate: line.dueDate,
              isPaid: line.isPaid,
            ),
          )
          .toList();
    } else if (s.paymentMethod == 'INSTALLMENT') {
      for (final plan in _installmentPlans) {
        if (plan.saleId == s.id) {
          resolvedInstallments = plan.schedules;
          break;
        }
      }
    }

    return _SaleRecord(
      id: s.id,
      invoiceNumber: s.invoiceNumber ?? '',
      customerName: customerName,
      customerId: s.customerId ?? '',
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerOutstandingBefore: outstandingBefore,
      customerOutstandingAfter: outstandingAfter,
      employeeId: employeeId,
      cashierName: cashierName,
      paymentMethod: s.paymentMethod,
      items: s.items.map((item) {
        var resolvedType = 'PRODUCT';
        if (item.productId.startsWith('SV:')) {
          resolvedType = 'SERVICE';
        } else {
          for (final product in _products) {
            if (product.id != item.productId) continue;
            resolvedType = product.productType.toUpperCase();
            break;
          }
        }

        return _SaleItemSnapshot(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          lineTotal: item.total,
          productType: resolvedType,
        );
      }).toList(),
      subtotal: s.total - s.tax,
      tax: s.tax,
      total: s.total,
      amountPaid: resolvedAmountPaid,
      balance: resolvedBalance,
      chequeNumber: '',
      shippingCharges: s.shippingCharges,
      agentName: s.agentName ?? '',
      agentCommission: s.agentCommission,
      agentCommissionType: s.agentCommissionType,
      agentCommissionPaid: s.agentCommissionPaid,
      status: s.status,
      locationId: s.locationId,
      createdAt: s.createdAt ?? DateTime.now(),
      notes: s.notes ?? '',
      shippingAddress: s.shippingAddress ?? '',
      installmentSchedules: resolvedInstallments,
      deliveryPersonId: s.deliveryPersonId,
      deliveryPersonName: s.deliveryPersonName,
      deliveryStatus: s.deliveryStatus,
      deliveredAt: s.deliveredAt,
      deliveryOtp: s.deliveryOtp,
      settledAt: s.settledAt,
      settledByEmployeeId: s.settledByEmployeeId,
      settledByCashierName: s.settledByCashierName,
    );
  }

  void _addNotification({
    required String title,
    required String message,
    required String type,
    String? targetLocation,
    String? referenceId,
  }) {
    final item = _NotificationItem(
      id: 'NOTIF-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      targetLocation: targetLocation,
      referenceId: referenceId,
      createdAt: DateTime.now(),
      isRead: false,
    );
    _notifications.insert(0, item);
    if (_notifications.length > 200) {
      _notifications.removeRange(200, _notifications.length);
    }
    if (mounted) {
      setState(() {});
    }
    _persistWorkspaceData();
  }

  Future<void> _triggerImmediateSync({
    required String action,
    required String module,
    required String reference,
  }) async {
    if (_syncService == null || _syncInProgress) return;
    _syncInProgress = true;

    try {
      final synced = await _syncService!.syncAllData();
      if (!synced) {
        final reason =
            _syncService!.lastFailureReason ??
            'Immediate sync failed. Will retry on the next poll.';
        if (!mounted) return;
        setState(() {
          _lastSyncError = reason;
        });
        await _refreshPendingSyncQueue();
        await _persistWorkspaceData();
        return;
      }

      // Load freshly-pulled workspace data (locations, users, etc.) from prefs
      // into memory BEFORE re-persisting. If we skip this step, _persistWorkspaceData()
      // overwrites the newly-synced data with the stale in-memory state.
      await _loadPersistedWorkspaceData();
      await _loadCoreDataFromRepositories();
      await _refreshPendingSyncQueue();
      if (!mounted) return;
      setState(() {
        _lastSyncAt = DateTime.now();
        _lastSyncError = null;
      });
      await _persistWorkspaceData();
    } catch (_) {
      // keep pending items in local queue if sync failed
      if (!mounted) return;
      setState(() {
        _lastSyncError = 'Sync error occurred. Pending items kept locally.';
      });
      await _refreshPendingSyncQueue();
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _runManualSync() async {
    if (_syncService == null || _syncInProgress) return;

    setState(() => _syncInProgress = true);
    try {
      final synced = await _syncService!.syncAllData();
      if (!mounted) return;

      if (synced) {
        // Load synced data from prefs into memory before re-persisting.
        // This ensures locations/users pulled from the server are visible in the
        // UI and are not overwritten back to the stale pre-sync state.
        await _loadPersistedWorkspaceData();
        await _loadCoreDataFromRepositories();
        await _refreshPendingSyncQueue();
        if (!mounted) return;
        setState(() {
          _lastSyncAt = DateTime.now();
          _lastSyncError = null;
        });
        await _persistWorkspaceData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manual sync completed successfully')),
        );
      } else {
        final reason =
            _syncService!.lastFailureReason ??
            'Manual sync failed (offline/server issue).';
        setState(() {
          _lastSyncError = reason;
        });
        await _refreshPendingSyncQueue();
        await _persistWorkspaceData();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(reason)));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lastSyncError = 'Unexpected sync error during manual sync.';
      });
      await _refreshPendingSyncQueue();
      await _persistWorkspaceData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manual sync failed unexpectedly')),
      );
    } finally {
      if (mounted) {
        setState(() => _syncInProgress = false);
      }
    }
  }

  String _syncStatusLabel() {
    if (_syncInProgress) return 'Syncing...';
    if (_lastSyncError != null) return 'Sync failed';
    if (_lastSyncAt != null) return 'Synced';
    return 'Not synced';
  }

  Color _syncStatusColor() {
    if (_syncInProgress) return const Color(0xFF1463FF);
    if (_lastSyncError != null) return const Color(0xFFE35D5D);
    if (_lastSyncAt != null) return const Color(0xFF0B9F69);
    return const Color(0xFF8A90A2);
  }

  bool get _isOwner => _currentUserRole.toLowerCase() == 'owner';
  bool get _isAdmin => _currentUserRole.toLowerCase() == 'admin';
  bool get _isManager => _currentUserRole.toLowerCase() == 'manager';
  bool get _isCashier => _currentUserRole.toLowerCase() == 'cashier';
  bool get _isAgent => _currentUserRole.toLowerCase() == 'agent';
  bool get _isDelivery => _currentUserRole.toLowerCase() == 'delivery';

  List<String> get _currentUserAssignedLocations {
    for (final user in _users) {
      if (user.id == _currentUserId ||
          (_currentUserEmail.isNotEmpty &&
              user.email.trim().toLowerCase() ==
                  _currentUserEmail.trim().toLowerCase())) {
        return user.locations
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  bool get _isBranchAdmin {
    if (_isOwner) return false;
    final role = _currentUserRole.trim().toLowerCase();
    if (role == 'branch admin' || role == 'branch_admin') return true;
    if (role == 'admin' || role == 'manager') {
      final assigned = _currentUserAssignedLocations;
      if (assigned.isNotEmpty &&
          !assigned.any((l) =>
              l.toLowerCase() == 'all' || l.toLowerCase() == 'all locations')) {
        return true;
      }
    }
    return false;
  }
  bool get _canManageCatalog =>
      _isOwner ||
      _isManager ||
      _hasAnyPermission(const {
        'PRODUCTS:EDIT',
        'CATEGORIES:EDIT',
        'CUSTOMERS:EDIT',
        'SERVICES:EDIT',
        'BARCODE PRINTING:EDIT',
        'SUPPLIERS:EDIT',
        'PURCHASE ORDERS:EDIT',
        'CREDIT MANAGEMENT:EDIT',
      });
  bool get _canManageEmployees =>
      _isOwner ||
      _isManager ||
      _hasAnyPermission(const {
        'EMPLOYEES:EDIT',
        'ATTENDANCE:EDIT',
        'PAYROLL:EDIT',
      });
  bool get _canManageSettings =>
      _isOwner ||
      _isManager ||
      _hasAnyPermission(const {'SETTINGS:EDIT', 'LOCATIONS:EDIT'});
  bool get _canChangeSalesStatus =>
      _isOwner ||
      _isManager ||
      _hasAnyPermission(const {'SALES:EDIT', 'INSTALLMENTS:EDIT'});
  bool get _canRunSync =>
      !_isCashier ||
      _hasAnyPermission(const {'SYNC MANAGER', 'SYNC MANAGER:EDIT'});
  bool get _canCreateUsers =>
      _isOwner ||
      _isAdmin ||
      _isManager ||
      _hasAnyPermission(const {'USERS:EDIT'});
  bool get _canEditUsers =>
      _isOwner ||
      _isAdmin ||
      _isManager ||
      _hasAnyPermission(const {'USERS:EDIT'});
  bool get _canDeleteUsers =>
      _isOwner ||
      _isAdmin ||
      _isManager ||
      _hasAnyPermission(const {'USERS:DELETE'});

  // Sales invoice action permissions
  bool get _canEditBill =>
      _isOwner ||
      _isAdmin ||
      _isManager ||
      _hasAnyPermission(const {'SALES:EDIT_BILL'});
  bool get _canCreateDuplicate =>
      _isOwner ||
      _isAdmin ||
      _isManager ||
      _hasAnyPermission(const {'SALES:CREATE_DUPLICATE'});
  bool get _canCancelInvoice =>
      _isOwner ||
      _isAdmin ||
      _isManager ||
      _hasAnyPermission(const {'SALES:CANCEL_INVOICE'});

  Set<String> get _currentUserPermissions {
    for (final user in _users) {
      if (user.id == _currentUserId) {
        return user.permissions
            .map((item) => item.trim().toUpperCase())
            .toSet();
      }
      if (_currentUserEmail.isNotEmpty &&
          user.email.trim().toLowerCase() == _currentUserEmail.toLowerCase()) {
        return user.permissions
            .map((item) => item.trim().toUpperCase())
            .toSet();
      }
    }
    return <String>{};
  }

  bool _hasAnyPermission(Set<String> permissions) {
    if (_isOwner) return true;
    final current = _currentUserPermissions;
    for (final permission in permissions) {
      if (current.contains(permission.toUpperCase())) {
        return true;
      }
    }
    return false;
  }

  Set<String> _allowedNavKeysForPermissions(Set<String> permissions) {
    if (_isOwner) {
      return _defaultStoreNavItems.map((item) => item.key).toSet();
    }
    final allowed = <String>{'dashboard'};
    for (final option in _userPermissionOptions) {
      if (permissions.contains(option.viewPermission)) {
        allowed.addAll(option.navKeys);
      }
    }

    // Backward compatibility for older permission keys saved before matrix-style access.
    const legacyPermissionToNav = <String, Set<String>>{
      'PRODUCTS': {'products', 'categories'},
      'BARCODE': {'barcodes'},
      'INVENTORY': {'products', 'categories'},
    };
    for (final permission in permissions) {
      allowed.addAll(legacyPermissionToNav[permission] ?? const <String>{});
    }
    return allowed;
  }

  static const Map<String, String> _sinhalaTranslations = {
    'Owner Dashboard': 'හිමිකරු උපකරණ පුවරුව',
    'Agent Dashboard': 'නියෝජිත පුවරුව',
    'Cashier Dashboard': 'කැෂියර් පුවරුව',
    'Point of Sale': 'විකුණුම් ස්ථානය (POS)',
    'Bank & Registers': 'බැංකු සහ ලේඛන',
    'Products': 'භාණ්ඩ / නිෂ්පාදන',
    'Categories': 'ප්‍රවර්ග',
    'Stock Transfers': 'තොග මාරු කිරීම්',
    'Services': 'සේවා',
    'Barcode Printing': 'තීරු කේත මුද්‍රණය',
    'Sales': 'විකුණුම්',
    'Installments': 'වාරික',
    'Customers': 'ගනුදෙනුකරුවන්',
    'Credit Management': 'ණය කළමනාකරණය',
    'Employees': 'සේවකයින්',
    'Attendance': 'පැමිණීම',
    'Payroll': 'වැටුප් ලේඛනය',
    'Users': 'පරිශීලකයින්',
    'Reports': 'වාර්තා',
    'Marketing': 'අලෙවිකරණය',
    'Expenses': 'වියදම්',
    'Discounts': 'වට්ටම්',
    'Commission Dashboard': 'කොමිස් පුවරුව',
    'Job Cards': 'කාර්ය පත්‍රිකා',
    'Returns & Refunds': 'ආපසු හැරවීම් සහ මුදල් ආපසු දීම්',
    'Suppliers': 'සැපයුම්කරුවන්',
    'Purchase Orders': 'මිලදී ගැනීමේ ඇණවුම්',
    'Mobile Reload': 'ජංගම රීලෝඩ්',
    'Locations': 'ස්ථාන',
    'Settings': 'සැකසුම්',
    'WhatsApp Connect': 'WhatsApp සම්බන්ධතාවය',
    'Sync Manager': 'සමමුහුර්ත කළමනාකරු',
    'Profile': 'පැතිකඩ',
    'General': 'පොදු සැකසුම්',
    'Navigation': 'සංචාලනය',
    'Company': 'සමාගම',
    'Receipt Settings': 'රසීදු සැකසුම්',
    'Print Settings': 'මුද්‍රණ සැකසුම්',
    'User Preferences': 'පරිශීලක මනාප',
    'Notifications': 'දැනුම්දීම්',
    'Save Settings': 'සැකසුම් සුරකින්න',
    'Theme': 'තේමාව',
    'Language': 'භාෂාව',
    'Dashboard': 'උපකරණ පුවරුව',
    'Shops': 'සාප්පු / ශාඛා',
    'Plans': 'සැලසුම්',
    'QR Payments': 'QR ගෙවීම්',
    'Activity': 'ක්‍රියාකාරකම්',
    'Releases': 'නිකුත් කිරීම්',
    'Documentation': 'ලේඛනගත කිරීම',
    'Tutorials': 'උපකාරක වීඩියෝ',
    'Select Selling Unit:': 'විකිණීමේ ඒකකය තෝරන්න:',
    'Quick Quantity:': 'ඉක්මන් ප්‍රමාණයන්:',
    'Full': 'සම්පූර්ණ',
    'Loose': 'සිල්ලර',
    'Total for this line:': 'මෙම අයිතමයේ එකතුව:',
    'Add to Bill': 'බිල්පතට එකතු කරන්න',
    'Cancel': 'අවලංගු කරන්න',
    'Apply': 'යොදන්න',
    'Shopping Cart': 'මිලදී ගැනීමේ කරත්තය',
    'View Bill': 'බිල්පත බලන්න',
    'Hold Bill': 'බිල රඳවා ගන්න',
    'Resume': 'නැවත ආරම්භ',
    'Clear Cart': 'කරත්තය හිස් කරන්න',
    'Subtotal:': 'උප එකතුව:',
    'Tax': 'බදු',
    'Add Discount': 'වට්ටම් එකතු කරන්න',
    'Apply Tax to Bill': 'බදු එකතු කරන්න',
    'Total:': 'මුළු එකතුව:',
    'Total::': 'මුළු එකතුව:',
    'Paid Amount:': 'ගෙවූ මුදල:',
    'Balance Due:': 'හිඟ මුදල:',
    'Change:': 'ඉතිරි මුදල:',
    'Delivery Fee:': 'බෙදාහැරීමේ ගාස්තුව:',
    'Shipping Charges': 'බෙදාහැරීමේ ගාස්තු',
    'Payment Method': 'ගෙවීම් ක්‍රමය',
    'Customer': 'ගනුදෙනුකරු',
    'Enter gift card code': 'තෑගි කාඩ්පත් කේතය ඇතුළත් කරන්න',
    'Enter coupon code': 'කූපන් කේතය ඇතුළත් කරන්න',
    'Cash': 'මුදල්',
    'Card': 'කාඩ්පත්',
    'Cheque': 'චෙක්පත්',
    'Credit': 'ණය',
    'Installment': 'වාරික',
    'COD': 'භාණ්ඩ ලැබුණු පසු මුදල් (COD)',
  };

  static const Map<String, String> _tamilTranslations = {
    'Owner Dashboard': 'உரிமையாளர் டாஷ்போர்டு',
    'Agent Dashboard': 'முகவர் டாஷ்போர்டு',
    'Cashier Dashboard': 'காசாளர் டாஷ்போர்டு',
    'Point of Sale': 'விற்பனை புள்ளி (POS)',
    'Bank & Registers': 'வங்கி & பதிவேடுகள்',
    'Products': 'தயாரிப்புகள்',
    'Categories': 'வகைகள்',
    'Stock Transfers': 'பங்கு இடமாற்றங்கள்',
    'Services': 'சேவைகள்',
    'Barcode Printing': 'பார்ர்கோட் அச்சிடுதல்',
    'Sales': 'விற்பனை',
    'Installments': 'தவணைகள்',
    'Customers': 'வாடிக்கையாளர்கள்',
    'Credit Management': 'கடன் மேலாண்மை',
    'Employees': 'ஊழியர்கள்',
    'Attendance': 'வருகை',
    'Payroll': 'ஊதியம்',
    'Users': 'பயனர்கள்',
    'Reports': 'அறிக்கைகள்',
    'Marketing': 'சந்தைப்படுத்தல்',
    'Expenses': 'செலவுகள்',
    'Discounts': 'தள்ளுபடிகள்',
    'Commission Dashboard': 'கமிஷன் டாஷ்போர்டு',
    'Job Cards': 'வேலை அட்டைகள்',
    'Returns & Refunds': 'வருமானம் & திருப்பிச் செலுத்துதல்',
    'Suppliers': 'சப்ளையர்கள்',
    'Purchase Orders': 'கொள்முதல் ஆணைகள்',
    'Mobile Reload': 'மொபைல் ரீலோட்',
    'Locations': 'இடங்கள்',
    'Settings': 'அமைப்புகள்',
    'Sync Manager': 'ஒத்திசைவு மேலாளர்',
    'Profile': 'சுயவிவரம்',
    'General': 'பொதுவானது',
    'Navigation': 'வழிசெலுத்தல்',
    'Company': 'நிறுவனம்',
    'Receipt Settings': 'ரசீது அமைப்புகள்',
    'Print Settings': 'அச்சு அமைப்புகள்',
    'User Preferences': 'பயனர் விருப்பங்கள்',
    'Notifications': 'அறிவிப்புகள்',
    'Save Settings': 'அமைப்புகளை சேமி',
    'Theme': 'தீம்',
    'Language': 'மொழி',
    'Dashboard': 'கட்டுப்பாட்டுப் பலகை',
    'Shops': 'கடைகள்',
    'Plans': 'திட்டங்கள்',
    'QR Payments': 'QR கொடுப்பனவுகள்',
    'Activity': 'செயல்பாடு',
    'Releases': 'வெளியீடுகள்',
    'Documentation': 'ஆவணங்கள்',
    'Tutorials': 'பயிற்சிகள்',
    'Select Selling Unit:': 'விற்பனை அலகைத் தேர்ந்தெடுக்கவும்:',
    'Quick Quantity:': 'விரைவு அளவு:',
    'Full': 'முழு',
    'Loose': 'சில்லறை',
    'Total for this line:': 'இந்த வரிக்கான மொத்தம்:',
    'Add to Bill': 'பட்டியலில் சேர்க்க',
    'Cancel': 'ரத்து செய்',
    'Apply': 'பயன்படுத்து',
    'Shopping Cart': 'ஷாப்பிங் கார்ட்',
    'View Bill': 'பட்டியலைக் காண்க',
    'Hold Bill': 'பட்டியலை நிறுத்து',
    'Resume': 'மீண்டும் தொடங்கு',
    'Clear Cart': 'வண்டியை அழிக்க',
    'Subtotal:': 'கூட்டுத்தொகை:',
    'Tax': 'வரி',
    'Add Discount': 'தள்ளுபடி சேர்க்க',
    'Apply Tax to Bill': 'வரி சேர்க்க',
    'Total:': 'மொத்தம்:',
    'Total::': 'மொத்தம்:',
    'Paid Amount:': 'செலுத்திய தொகை:',
    'Balance Due:': 'மீதி நிலுவை:',
    'Change:': 'மீதித்தொகை:',
    'Delivery Fee:': 'டெலிவரி கட்டணம்:',
    'Shipping Charges': 'டெலிவரி கட்டணம்',
    'Payment Method': 'பணம் செலுத்தும் முறை',
    'Customer': 'வாடிக்கையாளர்',
    'Enter gift card code': 'பரிசு அட்டை குறியீட்டை உள்ளிடவும்',
    'Enter coupon code': 'கூப்பன் குறியீட்டை உள்ளிடவும்',
    'Cash': 'ரொக்கம்',
    'Card': 'அட்டை',
    'Cheque': 'காசோலை',
    'Credit': 'கடன்',
    'Installment': 'தவணை முறை',
    'COD': 'டெலிவரியின் போது பணம் (COD)',
  };

  String _t(String text) {
    if (_uiLanguage == 'Sinhala') {
      return _sinhalaTranslations[text] ?? text;
    } else if (_uiLanguage == 'Tamil') {
      return _tamilTranslations[text] ?? text;
    }
    return text;
  }

  String _navItemLabel(_NavItem item) {
    String originalLabel = item.label;
    if (item.key == 'dashboard') {
      if (_isAgent)
        originalLabel = 'Agent Dashboard';
      else if (_isCashier)
        originalLabel = 'Cashier Dashboard';
      else
        originalLabel = 'Owner Dashboard';
    }
    return _t(originalLabel);
  }

  List<_NavItem> _visibleNavItems() {
    List<_NavItem> items;
    if (_isDelivery) {
      items = _storeNavItems
          .where((item) => item.key == 'sales' || item.key == 'dashboard')
          .toList();
    } else if (_isOwner || _isAdmin || _isBranchAdmin) {
      items = _storeNavItems;
    } else {
      final permissions = _currentUserPermissions;
      if (permissions.isNotEmpty) {
        final allowedByPermission = _allowedNavKeysForPermissions(permissions);
        items = _storeNavItems
            .where((item) => allowedByPermission.contains(item.key))
            .toList();
      } else if (_isManager) {
        items = _storeNavItems;
      } else {
        const cashierAllowed = {
          'dashboard',
          'pos',
          'sales',
          'installments',
          'customers',
          'reports',
          'settings',
          'mobileReload',
          'whatsapp',
        };
        items = _storeNavItems
            .where((item) => cashierAllowed.contains(item.key))
            .toList();
      }
    }

    final isOffline = _subscriptionStatusData?['status'] == 'OFFLINE' ||
        _subscriptionStatusData?['sync_enabled'] == false;
    if (isOffline) {
      // Offline mode is single location; multi-branch stock transfers is an online feature
      return items.where((item) => item.key != 'stockTransfers').toList();
    }

    return items;
  }

  List<String> get _availableLocationNames {
    final namesByKey = <String, String>{};
    for (final location in _locations) {
      final normalizedName = location.name.trim();
      if (location.isActive && normalizedName.isNotEmpty) {
        namesByKey.putIfAbsent(
          normalizedName.toLowerCase(),
          () => normalizedName,
        );
      }
    }
    final primaryName = _storeLocation.trim().isEmpty
        ? 'Main Branch'
        : _storeLocation.trim();
    namesByKey.putIfAbsent(primaryName.toLowerCase(), () => primaryName);
    final sorted = namesByKey.values.toList()..sort();
    return sorted;
  }

  List<String> _accessibleLocationNames(AuthAuthenticated state) {
    if (_isBranchAdmin) {
      final assigned = _currentUserAssignedLocations;
      if (assigned.isNotEmpty) {
        return assigned;
      }
    }
    if (_isOwner || (_isAdmin && !_isBranchAdmin) || (_isManager && !_isBranchAdmin)) {
      return _availableLocationNames;
    }

    final claimedLocations = state.user.locationIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (claimedLocations.isNotEmpty) {
      return claimedLocations;
    }

    final userEmail = state.user.email.trim().toLowerCase();
    for (final user in _users) {
      if (user.email.trim().toLowerCase() != userEmail) continue;
      final assigned = user.locations
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      if (assigned.isNotEmpty) {
        return assigned;
      }
    }

    return _availableLocationNames;
  }

  bool _passesLocationScope(String? location) {
    if (_isBranchAdmin) {
      final assigned = _currentUserAssignedLocations
          .map((l) => l.trim().toLowerCase())
          .toSet();
      if (assigned.isEmpty) return false;
      final normalized = (location ?? '').trim().toLowerCase();
      if (normalized.isEmpty) return false;
      return assigned.contains(normalized);
    }
    // When "All Locations" is selected, always show every record.
    // The location picker already restricts non-owners to their accessible
    // locations, so if they somehow have "All Locations" selected they can
    // see everything in their accessible scope.
    if (_selectedLocationScope == _allLocationsLabel) {
      return true;
    }
    final normalized = (location ?? '').trim();
    // A record with no location is not restricted to any branch — show it in
    // all scopes so old records without a locationId are never silently hidden.
    if (normalized.isEmpty) {
      return true;
    }
    return normalized.toLowerCase() ==
        _selectedLocationScope.trim().toLowerCase();
  }

  String get _activeLocationForWrites {
    if (_isBranchAdmin) {
      final assigned = _currentUserAssignedLocations;
      if (assigned.isNotEmpty) return assigned.first;
    }
    if (_selectedLocationScope != _allLocationsLabel) {
      return _selectedLocationScope;
    }
    return _storeLocation.trim().isEmpty ? 'Main Branch' : _storeLocation;
  }

  List<_ProductItem> get _scopedProducts =>
      _products.where((item) => _passesLocationScope(item.locationId)).toList();

  List<_CustomerItem> get _scopedCustomers => _customers
      .where((item) => _passesLocationScope(item.locationId))
      .toList();

  List<_SaleRecord> get _scopedSales {
    var list = _sales.where((item) => _passesLocationScope(item.locationId)).toList();
    if (_isDelivery) {
      list = list
          .where((item) =>
              item.paymentMethod == 'COD' &&
              (item.deliveryPersonId == _currentUserId ||
                  item.deliveryPersonId == null ||
                  item.deliveryPersonId!.isEmpty))
          .toList();
    }
    return list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<_EmployeeItem> get _scopedEmployees => _employees.where((item) {
    if (_isBranchAdmin) {
      final assigned = _currentUserAssignedLocations
          .map((l) => l.trim().toLowerCase())
          .toSet();
      return item.assignedLocations
          .any((loc) => assigned.contains(loc.trim().toLowerCase()));
    }
    if (_selectedLocationScope == _allLocationsLabel) {
      return true;
    }
    if (item.assignedLocations.isEmpty) {
      return true;
    }
    final scope = _selectedLocationScope.trim().toLowerCase();
    return item.assignedLocations.any(
      (loc) => loc.trim().toLowerCase() == scope,
    );
  }).toList();

  List<_UserItem> get _scopedUsers => _users.where((item) {
    if (_isBranchAdmin) {
      final assigned = _currentUserAssignedLocations
          .map((l) => l.trim().toLowerCase())
          .toSet();
      return item.locations
          .any((loc) => assigned.contains(loc.trim().toLowerCase()));
    }
    if (_selectedLocationScope == _allLocationsLabel) {
      return true;
    }
    if (item.locations.isEmpty) {
      return true;
    }
    final scope = _selectedLocationScope.trim().toLowerCase();
    return item.locations.any((loc) => loc.trim().toLowerCase() == scope);
  }).toList();

  List<db.Expense> get _scopedExpenses => _expensesList
      .where((item) => _passesLocationScope(item.locationId))
      .toList();

  List<_PurchaseOrderItem> get _scopedPurchaseOrders => _purchaseOrders
      .where((item) => _passesLocationScope(item.locationId))
      .toList();

  bool _passesCashTransactionLocationScope(_CashTransactionItem tx) {
    if (_selectedLocationScope == _allLocationsLabel) {
      return true;
    }
    String? locationId;
    final refType = tx.referenceType.toUpperCase();
    if (refType == 'SALE') {
      for (final sale in _sales) {
        if (sale.id == tx.referenceId) {
          locationId = sale.locationId;
          break;
        }
      }
    } else if (refType == 'RETURN') {
      for (final ret in _returns) {
        if (ret.id == tx.referenceId) {
          for (final sale in _sales) {
            if (sale.id == ret.saleId) {
              locationId = sale.locationId;
              break;
            }
          }
          break;
        }
      }
      if (locationId == null) {
        for (final sale in _sales) {
          if (sale.id == tx.referenceId) {
            locationId = sale.locationId;
            break;
          }
        }
      }
    } else if (refType == 'EXPENSE') {
      for (final exp in _expensesList) {
        if (exp.id == tx.referenceId) {
          locationId = exp.locationId;
          break;
        }
      }
    }
    return _passesLocationScope(locationId);
  }

  List<_CashTransactionItem> get _scopedCashTransactions => _cashTransactions
      .where((item) => _passesCashTransactionLocationScope(item))
      .toList();

  bool _passesReturnLocationScope(_ReturnItem item) {
    if (_selectedLocationScope == _allLocationsLabel) {
      return true;
    }
    String? locationId;
    for (final sale in _sales) {
      if (sale.id == item.saleId) {
        locationId = sale.locationId;
        break;
      }
    }
    return _passesLocationScope(locationId);
  }

  List<_ReturnItem> get _scopedReturns =>
      _returns.where((item) => _passesReturnLocationScope(item)).toList();

  bool _passesDamagedLocationScope(_DamagedInventoryItem item) {
    if (_selectedLocationScope == _allLocationsLabel) {
      return true;
    }
    String? locationId;
    for (final p in _products) {
      if (p.id == item.productId) {
        locationId = p.locationId;
        break;
      }
    }
    return _passesLocationScope(locationId);
  }

  List<_DamagedInventoryItem> get _scopedDamagedInventory => _damagedInventory
      .where((item) => _passesDamagedLocationScope(item))
      .toList();

  List<String> _splitDelimitedIds(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return const [];
    return value
        .split(RegExp(r'[|,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool _discountAppliesToProduct(db.Discount discount, _ProductItem product) {
    if (!discount.isActive) return false;
    final productIds = _splitDelimitedIds(discount.productId);
    if (productIds.isNotEmpty) {
      return productIds.contains(product.id);
    }
    final category = (discount.category ?? '').trim().toLowerCase();
    if (category.isNotEmpty) {
      return product.category.trim().toLowerCase() == category;
    }
    return false;
  }

  _DiscountData? _autoDiscountForProduct(_ProductItem product) {
    final matching = _discountDefinitions
        .where((discount) => _discountAppliesToProduct(discount, product))
        .toList();
    if (matching.isEmpty) return null;

    matching.sort((a, b) {
      final aAmount = _discountAmountForProduct(product, a);
      final bAmount = _discountAmountForProduct(product, b);
      return bAmount.compareTo(aAmount);
    });

    final best = matching.first;
    return _DiscountData(
      value: best.discountMode.toUpperCase() == 'PERCENT'
          ? best.value
          : best.value,
      type: best.discountMode.toUpperCase(),
      label: best.name,
    );
  }

  double _discountAmountForProduct(_ProductItem product, db.Discount discount) {
    if (discount.discountMode.toUpperCase() == 'PERCENT') {
      return product.price * (discount.value / 100);
    }
    return discount.value.clamp(0.0, product.price);
  }

  List<_StockTransferItem> get _scopedStockTransfers =>
      _stockTransfers.where((item) {
        if (_selectedLocationScope == _allLocationsLabel) {
          return _isOwner || _isAdmin;
        }
        return item.fromLocation == _selectedLocationScope ||
            item.toLocation == _selectedLocationScope;
      }).toList();

  List<_StockRequestItem> get _scopedStockRequests =>
      _stockRequests.where((item) {
        if (_selectedLocationScope == _allLocationsLabel) {
          return _isOwner || _isAdmin;
        }
        return item.fromLocation == _selectedLocationScope ||
            item.toLocation == _selectedLocationScope;
      }).toList();

  List<_CreditSaleEntry> _scopedCreditSales(String customerId) {
    final sales =
        _customerCreditSales[customerId] ?? const <_CreditSaleEntry>[];
    return sales.where((sale) {
      if (sale.locationId.trim().isNotEmpty) {
        return _passesLocationScope(sale.locationId);
      }
      if (sale.saleId.trim().isNotEmpty) {
        for (final item in _sales) {
          if (item.id == sale.saleId) {
            return _passesLocationScope(item.locationId);
          }
        }
      }
      return _selectedLocationScope == _allLocationsLabel
          ? _isOwner || _isAdmin
          : true;
    }).toList();
  }

  List<_InstallmentPlan> get _scopedInstallmentPlans =>
      _installmentPlans.where((plan) {
        if (plan.locationId.trim().isNotEmpty) {
          return _passesLocationScope(plan.locationId);
        }
        if (plan.saleId.trim().isNotEmpty) {
          for (final sale in _sales) {
            if (sale.id == plan.saleId) {
              return _passesLocationScope(sale.locationId);
            }
          }
        }
        return _selectedLocationScope == _allLocationsLabel
            ? _isOwner || _isAdmin
            : true;
      }).toList();

  String _money(double amount) => '$_currency ${amount.toStringAsFixed(2)}';

  String _formatDualStock(
    double stock,
    String primaryUnit,
    String secondaryUnit,
    double ratio,
  ) {
    final cleanPrimary = primaryUnit.trim().isEmpty
        ? 'UNIT'
        : primaryUnit.trim().toUpperCase();
    final cleanSecondary = secondaryUnit.trim().isEmpty
        ? 'KG'
        : secondaryUnit.trim().toUpperCase();

    if (ratio <= 1.0) {
      final s = stock.toStringAsFixed(
        stock.truncateToDouble() == stock ? 0 : 2,
      );
      return '$s $cleanPrimary';
    }

    if (stock <= 0) {
      return '0 $cleanPrimary';
    }

    final fullUnits = (stock + 1e-9).floor();
    final remainderFraction = (stock - fullUnits).clamp(0.0, 1.0);
    final looseUnits = remainderFraction * ratio;
    final roundedLoose = (looseUnits * 100).round() / 100.0;

    if (roundedLoose >= ratio - 1e-4) {
      return '${fullUnits + 1} $cleanPrimary';
    }

    final looseStr = roundedLoose.toStringAsFixed(
      roundedLoose.truncateToDouble() == roundedLoose ? 0 : 2,
    );

    if (fullUnits == 0 && roundedLoose > 0) {
      return '$looseStr $cleanSecondary';
    }

    if (roundedLoose == 0) {
      return '$fullUnits $cleanPrimary';
    }

    return '$fullUnits $cleanPrimary + $looseStr $cleanSecondary';
  }

  bool get _isDarkSurfaceMode =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _pageSurfaceColor =>
      _isDarkSurfaceMode ? const Color(0xFF111827) : const Color(0xFFFFFCF8);

  Color get _pageBorderColor =>
      _isDarkSurfaceMode ? const Color(0xFF283244) : const Color(0xFFE7D9CA);

  Color get _tableHeaderColor =>
      _isDarkSurfaceMode ? const Color(0xFF162033) : const Color(0xFFF5EEE5);

  String _returnStoreCreditCartItemId(String returnId) =>
      'SV:RETURN_CREDIT:$returnId';

  bool _isReturnStoreCreditCartItemId(String cartItemId) =>
      cartItemId.startsWith('SV:RETURN_CREDIT:');

  String? _returnIdFromStoreCreditCartItemId(String cartItemId) {
    if (!_isReturnStoreCreditCartItemId(cartItemId)) {
      return null;
    }
    final returnId = cartItemId.substring('SV:RETURN_CREDIT:'.length).trim();
    return returnId.isEmpty ? null : returnId;
  }

  String? _findCustomerIdByName(String customerName) {
    final normalized = customerName.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'walk-in customer') {
      return null;
    }

    for (final customer in _customers) {
      if (customer.name.trim().toLowerCase() == normalized) {
        return customer.id;
      }
    }
    return null;
  }

  void _removeTemporaryCartProducts(Iterable<String> cartItemIds) {
    for (final cartItemId in cartItemIds) {
      _temporaryCartProducts.remove(cartItemId);
    }
  }

  _ProductItem? _resolveCartItemProduct(String cartItemId) {
    final temporaryProduct = _temporaryCartProducts[cartItemId];
    if (temporaryProduct != null) {
      return temporaryProduct;
    }

    if (cartItemId.startsWith('LOOSE:')) {
      final baseProductId = cartItemId.substring(6);
      _ProductItem? baseProduct;
      for (final p in _products) {
        if (p.id == baseProductId) {
          baseProduct = p;
          break;
        }
      }
      if (baseProduct == null) return null;

      final ratio = baseProduct.unitConversionRatio > 0
          ? baseProduct.unitConversionRatio
          : 1.0;
      final loosePrice = baseProduct.secondaryPrice ??
          (ratio > 0 ? (baseProduct.price / ratio) : baseProduct.price);
      final looseStock = ratio > 0
          ? (baseProduct.stock * ratio)
          : baseProduct.stock;
      final looseMinStock = ratio > 0
          ? (baseProduct.minStock * ratio)
          : baseProduct.minStock;

      return _ProductItem(
        id: cartItemId,
        name: '${baseProduct.name} (${baseProduct.secondaryUnit})',
        category: baseProduct.category,
        productType: baseProduct.productType,
        measureUnit: baseProduct.secondaryUnit,
        price: loosePrice,
        minPrice: baseProduct.minPrice > 0 && ratio > 0
            ? (baseProduct.minPrice / ratio)
            : 0.0,
        stock: looseStock,
        minStock: looseMinStock,
        barcode: baseProduct.barcode,
        costPrice: baseProduct.costPrice != null && ratio > 0
            ? (baseProduct.costPrice! / ratio)
            : null,
        imageUrl: baseProduct.imageUrl,
        supplierId: baseProduct.supplierId,
        locationId: baseProduct.locationId,
        attributeValues: Map<String, dynamic>.from(baseProduct.attributeValues),
      );
    }

    if (cartItemId.startsWith('SV:')) {
      final serviceId = cartItemId.substring(3);
      _ServiceJobItem? service;
      for (final item in _serviceJobs) {
        if (item.id == serviceId) {
          service = item;
          break;
        }
      }
      if (service == null) return null;

      return _ProductItem(
        id: cartItemId,
        name: service.title,
        category: 'Service',
        productType: 'SERVICE',
        price: service.defaultPrice,
        stock: 999999,
        minStock: 0,
        barcode: service.sku.isEmpty ? service.id : service.sku,
      );
    }

    for (final product in _products) {
      if (product.id == cartItemId) return product;
    }
    return null;
  }

  bool _isCreditPaymentMethod(String paymentMethod) {
    return paymentMethod == 'CREDIT' || paymentMethod == 'INSTALLMENT';
  }

  bool _isCashPaymentMethod(String paymentMethod) {
    return paymentMethod == 'CASH';
  }

  bool _allowsManualPaidAmount(String paymentMethod) {
    return paymentMethod == 'CASH' ||
        paymentMethod == 'CREDIT' ||
        paymentMethod == 'INSTALLMENT';
  }

  bool _isServiceSaleItem(_SaleItemSnapshot item) {
    final explicitType = item.productType.trim().toUpperCase();
    if (explicitType == 'SERVICE') {
      return true;
    }
    if (item.productId.startsWith('SV:')) {
      return true;
    }
    for (final product in _products) {
      if (product.id != item.productId) continue;
      if (product.productType.trim().toUpperCase() == 'SERVICE') {
        return true;
      }
      if (product.category.trim().toLowerCase() == 'service') {
        return true;
      }
      return false;
    }
    return false;
  }

  bool _saleHasServiceItems(_SaleRecord sale) {
    if (sale.items.isEmpty) {
      return sale.paymentMethod.toUpperCase() == 'SERVICE';
    }
    return sale.items.any(_isServiceSaleItem);
  }

  double _saleServiceRevenue(_SaleRecord sale) {
    if (sale.items.isEmpty) {
      return sale.paymentMethod.toUpperCase() == 'SERVICE' ? sale.total : 0;
    }
    return sale.items
        .where(_isServiceSaleItem)
        .fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  double _saleProductRevenue(_SaleRecord sale) {
    if (sale.items.isEmpty) {
      return sale.paymentMethod.toUpperCase() == 'SERVICE' ? 0 : sale.total;
    }
    return sale.items
        .where((item) => !_isServiceSaleItem(item))
        .fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  List<DateTime> _generateInstallmentDueDates({
    required int installments,
    required int intervalDays,
    DateTime? startFrom,
  }) {
    final count = installments.clamp(1, 60).toInt();
    final safeInterval = intervalDays.clamp(1, 365).toInt();
    final start = DateTime(
      (startFrom ?? DateTime.now()).year,
      (startFrom ?? DateTime.now()).month,
      (startFrom ?? DateTime.now()).day,
    );

    return List<DateTime>.generate(
      count,
      (index) => start.add(Duration(days: safeInterval * (index + 1))),
    );
  }

  List<double> _splitInstallmentAmounts(double total, int installments) {
    final count = installments.clamp(1, 60).toInt();
    final safeTotal = total.clamp(0, double.infinity).toDouble();
    if (count == 1) return [safeTotal];

    final perInstallment = double.parse((safeTotal / count).toStringAsFixed(2));
    final amounts = List<double>.filled(count, perInstallment);
    final allocated = perInstallment * count;
    final adjustment = double.parse((safeTotal - allocated).toStringAsFixed(2));
    amounts[count - 1] = double.parse(
      (amounts[count - 1] + adjustment).toStringAsFixed(2),
    );
    return amounts;
  }

  void _resetPosInstallmentSchedule({DateTime? startFrom}) {
    _posInstallmentDueDates
      ..clear()
      ..addAll(
        _generateInstallmentDueDates(
          installments: _posInstallmentCount,
          intervalDays: _posInstallmentIntervalDays,
          startFrom: startFrom,
        ),
      );
    _posInstallmentAmounts.clear();
    _posInstallmentAmountsTotal = 0;
  }

  void _syncPosInstallmentAmounts(double totalAmount) {
    final safeTotal = totalAmount.clamp(0, double.infinity).toDouble();
    final expectedCount = _posInstallmentCount.clamp(1, 60).toInt();
    final requiresReset =
        _posInstallmentAmounts.length != expectedCount ||
        (_posInstallmentAmountsTotal - safeTotal).abs() > 0.009;

    if (!requiresReset) return;

    _posInstallmentAmounts
      ..clear()
      ..addAll(_splitInstallmentAmounts(safeTotal, expectedCount));
    _posInstallmentAmountsTotal = safeTotal;
  }

  void _updatePosInstallmentAmount({
    required int installmentIndex,
    required double newAmount,
    required double totalAmount,
  }) {
    _syncPosInstallmentAmounts(totalAmount);
    if (_posInstallmentAmounts.isEmpty) return;

    final index = installmentIndex.clamp(0, _posInstallmentAmounts.length - 1);
    final total = totalAmount.clamp(0, double.infinity).toDouble();

    var paidBefore = 0.0;
    for (var i = 0; i < index; i++) {
      paidBefore += _posInstallmentAmounts[i];
    }

    final futureCount = _posInstallmentAmounts.length - index - 1;
    final maxCurrent = (total - paidBefore)
        .clamp(0, double.infinity)
        .toDouble();
    final adjustedCurrent = futureCount == 0
        ? maxCurrent
        : newAmount.clamp(0, maxCurrent).toDouble();

    _posInstallmentAmounts[index] = double.parse(
      adjustedCurrent.toStringAsFixed(2),
    );

    if (futureCount > 0) {
      final remaining = (total - paidBefore - adjustedCurrent)
          .clamp(0, double.infinity)
          .toDouble();
      final redistributed = _splitInstallmentAmounts(remaining, futureCount);
      for (var i = 0; i < futureCount; i++) {
        _posInstallmentAmounts[index + 1 + i] = redistributed[i];
      }
    }

    _posInstallmentAmountsTotal = total;
  }

  void _updateInstallmentScheduleAmount({
    required _InstallmentPlan plan,
    required int scheduleIndex,
    required double newAmount,
  }) {
    if (plan.schedules.isEmpty) return;

    final index = scheduleIndex.clamp(0, plan.schedules.length - 1);
    final total = plan.remainingAmount.clamp(0, double.infinity).toDouble();
    var prefixTotal = 0.0;
    for (var i = 0; i < index; i++) {
      prefixTotal += plan.schedules[i].amount;
    }

    final futureCount = plan.schedules.length - index - 1;
    final maxCurrent = (total - prefixTotal)
        .clamp(0, double.infinity)
        .toDouble();
    final safeCurrent = futureCount == 0
        ? maxCurrent
        : newAmount.clamp(0, maxCurrent).toDouble();
    plan.schedules[index].amount = double.parse(safeCurrent.toStringAsFixed(2));

    if (futureCount <= 0) return;

    final remainingForFuture = (total - prefixTotal - safeCurrent)
        .clamp(0, double.infinity)
        .toDouble();
    final redistributed = _splitInstallmentAmounts(
      remainingForFuture,
      futureCount,
    );
    for (var i = 0; i < futureCount; i++) {
      plan.schedules[index + 1 + i].amount = redistributed[i];
    }
  }

  List<domain.InstallmentPaymentLine> _applyInstallmentPayment(
    _InstallmentPlan plan,
    int scheduleIndex,
    double paymentAmount,
  ) {
    if (plan.schedules.isEmpty || paymentAmount <= 0) {
      return const [];
    }

    final allocations = <domain.InstallmentPaymentLine>[];
    var remainingPayment = paymentAmount.clamp(0.0, double.infinity).toDouble();
    final startIndex = scheduleIndex.clamp(0, plan.schedules.length - 1);
    final paymentAt = DateTime.now();

    for (
      var i = startIndex;
      i < plan.schedules.length && remainingPayment > 0;
      i++
    ) {
      final schedule = plan.schedules[i];
      if (schedule.isPaid) {
        continue;
      }

      final needed = double.parse(schedule.remainingAmount.toStringAsFixed(2));
      if (needed <= 0.009) {
        schedule.isPaid = true;
        schedule.paidAt ??= paymentAt;
        continue;
      }

      if (remainingPayment >= needed) {
        final applied = needed;
        schedule.paidAmount = double.parse(
          (schedule.paidAmount + applied).toStringAsFixed(2),
        );
        remainingPayment = double.parse(
          (remainingPayment - applied).toStringAsFixed(2),
        );
        schedule.isPaid = true;
        schedule.paidAt = paymentAt;

        allocations.add(
          domain.InstallmentPaymentLine(
            installmentNo: schedule.installmentNo,
            dueDate: schedule.dueDate,
            scheduledAmount: schedule.amount,
            paidAmount: schedule.paidAmount,
            remainingAmount: schedule.remainingAmount,
            isPaid: schedule.isPaid,
          ),
        );
      } else {
        final applied = remainingPayment;
        schedule.paidAmount = double.parse(
          (schedule.paidAmount + applied).toStringAsFixed(2),
        );
        remainingPayment = 0.0;

        allocations.add(
          domain.InstallmentPaymentLine(
            installmentNo: schedule.installmentNo,
            dueDate: schedule.dueDate,
            scheduledAmount: schedule.amount,
            paidAmount: schedule.paidAmount,
            remainingAmount: schedule.remainingAmount,
            isPaid: schedule.isPaid,
          ),
        );
        break;
      }
    }

    plan.remainingAmount = double.parse(
      plan.schedules
          .fold<double>(0, (sum, item) => sum + item.remainingAmount)
          .toStringAsFixed(2),
    );

    return allocations;
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _applyPosPaymentMethod(String method, double grandTotal) {
    final normalizedMethod = method.trim().toUpperCase();
    final isCash = _isCashPaymentMethod(normalizedMethod);
    final isCredit = normalizedMethod == 'CREDIT';
    final allowsManual = _allowsManualPaidAmount(normalizedMethod);

    setState(() {
      _paymentMethodController.text = normalizedMethod;
      if (normalizedMethod == 'COD') {
        _amountPaidController.text = '0.00';
        if (_posShippingCharges == 0.0 &&
            (_posShippingController.text.trim().isEmpty ||
                _posShippingController.text.trim() == '0' ||
                _posShippingController.text.trim() == '0.00')) {
          _posShippingCharges = _defaultDeliveryFee;
          _posShippingController.text = _defaultDeliveryFee > 0
              ? _defaultDeliveryFee.toStringAsFixed(2)
              : '';
        }
      } else if (isCash) {
        _amountPaidController.clear();
      } else if (isCredit) {
        _amountPaidController.text = '0';
      } else if (allowsManual) {
        _amountPaidController.text = '0';
        _resetPosInstallmentSchedule();
      } else {
        _amountPaidController.text = grandTotal.toStringAsFixed(2);
      }
      if (normalizedMethod != 'CHEQUE') {
        _chequeNumberController.clear();
      }
    });
  }

  void _applyCreditPaymentToSales(String customerId, double amount) {
    final sales = _scopedCreditSales(customerId);
    if (sales.isEmpty || amount <= 0) {
      return;
    }

    var remaining = amount;
    for (final sale in sales) {
      if (remaining <= 0) break;
      if (sale.outstandingAmount <= 0) continue;

      final applied = remaining >= sale.outstandingAmount
          ? sale.outstandingAmount
          : remaining;
      sale.outstandingAmount = (sale.outstandingAmount - applied).clamp(
        0,
        double.infinity,
      );
      remaining -= applied;
    }
  }

  double _salesOutstandingBalance(String customerId) {
    final sales = _scopedCreditSales(customerId);
    return sales.fold<double>(
      0,
      (sum, sale) => sum + sale.outstandingAmount.clamp(0, double.infinity),
    );
  }

  double _customerOutstandingBalance(String customerId, {double fallback = 0}) {
    final fromSales = _salesOutstandingBalance(customerId);
    if (fromSales > 0) {
      return fromSales;
    }
    return fallback.clamp(0, double.infinity).toDouble();
  }

  bool _hasOverdueCreditForCustomer(_CustomerItem customer) {
    final sales = _scopedCreditSales(customer.id);
    if (sales.isEmpty) return false;

    final dueDays = customer.creditDueDays.clamp(1, 3650);
    final now = DateTime.now();
    for (final sale in sales) {
      if (sale.outstandingAmount <= 0) continue;
      final dueDate = sale.createdAt.add(Duration(days: dueDays));
      if (now.isAfter(dueDate)) {
        return true;
      }
    }
    return false;
  }

  DateTime? _oldestOverdueDateForCustomer(_CustomerItem customer) {
    final sales = _scopedCreditSales(customer.id);
    if (sales.isEmpty) return null;

    final dueDays = customer.creditDueDays.clamp(1, 3650);
    final now = DateTime.now();
    DateTime? oldest;
    for (final sale in sales) {
      if (sale.outstandingAmount <= 0) continue;
      final dueDate = sale.createdAt.add(Duration(days: dueDays));
      if (!now.isAfter(dueDate)) continue;
      if (oldest == null || dueDate.isBefore(oldest)) {
        oldest = dueDate;
      }
    }
    return oldest;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfWeek(DateTime value) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    return dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
  }

  bool _matchesTimeFilter(DateTime value, String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        return _isSameDay(value, now);
      case 'This Week':
        final weekStart = _startOfWeek(now);
        final weekEnd = weekStart.add(const Duration(days: 7));
        return !value.isBefore(weekStart) && value.isBefore(weekEnd);
      case 'This Month':
        return value.year == now.year && value.month == now.month;
      case 'This Year':
        return value.year == now.year;
      case 'All Time':
      default:
        return true;
    }
  }

  List<_SaleRecord> _salesForPeriod(String period, List<_SaleRecord> source) {
    return source
        .where((sale) => _matchesTimeFilter(sale.createdAt, period))
        .toList();
  }

  double _calculatedCashInHandForPeriod(String period) {
    double cash = 0.0;

    // 0. Register Drawer Opening Float for active/period sessions
    for (final session in _cashierSessions) {
      if (_matchesTimeFilter(session.openingTime, period)) {
        cash += session.openingCash;
      }
    }

    // 1. Cash Sales & COD completed sales (where cash was collected)
    for (final sale in _scopedSales) {
      final st = sale.status.toUpperCase();
      if (st == 'COMPLETED' || st == 'RETURNED' || st == 'PARTIALLY_RETURNED') {
        if (sale.paymentMethod.toUpperCase() == 'CASH') {
          if (_matchesTimeFilter(sale.createdAt, period)) {
            cash += sale.amountPaid > 0 ? sale.amountPaid : sale.total;
          }
        } else if (sale.paymentMethod.toUpperCase() == 'COD' &&
            st == 'COMPLETED') {
          final effectiveDate = sale.deliveredAt ?? sale.createdAt;
          if (_matchesTimeFilter(effectiveDate, period)) {
            cash += sale.amountPaid > 0 ? sale.amountPaid : sale.total;
          }
        }
      }
    }

    // 2. Customer Credit payments (settlements)
    for (final customer in _scopedCustomers) {
      final payments =
          _customerCreditPayments[customer.id] ?? const <_CreditPaymentItem>[];
      for (final p in payments) {
        if (_matchesTimeFilter(p.createdAt, period)) {
          cash += p.amount;
        }
      }
    }

    // 3. Installments in Cash
    for (final plan in _scopedInstallmentPlans) {
      if (plan.paymentMethod.toUpperCase() == 'CASH') {
        if (_matchesTimeFilter(plan.createdAt, period)) {
          cash += plan.downPayment;
        }
        for (final schedule in plan.schedules) {
          if (schedule.isPaid &&
              schedule.paidAt != null &&
              _matchesTimeFilter(schedule.paidAt!, period)) {
            cash += schedule.paidAmount;
          }
        }
      }
    }

    // 4. Expenses & PO cash purchases
    for (final exp in _scopedExpenses) {
      if (_matchesTimeFilter(exp.expenseDate, period)) {
        final pm = _getExpensePaymentMethod(exp.notes);
        if (pm == 'CASH') {
          cash -= exp.amount;
        }
      }
    }

    // 5. Cash Refunds / Transactions (from returns page)
    for (final tx in _scopedCashTransactions) {
      final txDate = DateTime.tryParse(tx.createdAt) ?? DateTime.now();
      if (_matchesTimeFilter(txDate, period)) {
        if (tx.type == 'OUT') {
          cash -= tx.amount;
        } else if (tx.type == 'IN') {
          cash += tx.amount;
        }
      }
    }

    return cash;
  }

  double _calculatedCreditToCollectForPeriod(String period) {
    double total = 0.0;
    for (final customer in _scopedCustomers) {
      final creditSales =
          _customerCreditSales[customer.id] ?? const <_CreditSaleEntry>[];
      for (final s in creditSales) {
        if (_matchesTimeFilter(s.createdAt, period)) {
          total += s.outstandingAmount;
        }
      }
    }
    return total;
  }

  double _calculatedCreditToPayForPeriod(String period) {
    return _scopedPurchaseOrders
        .where(
          (po) =>
              po.status == 'RECEIVED' &&
              _matchesTimeFilter(
                po.receivedAt ??
                    DateTime.tryParse(po.createdAt) ??
                    DateTime.now(),
                period,
              ),
        )
        .fold<double>(0.0, (sum, po) => sum + po.amountDue);
  }

  String _calculatedChequesForPeriod(String period) {
    final issued = _scopedPurchaseOrders
        .where(
          (po) =>
              po.paymentMethod.toUpperCase() == 'CHEQUE' &&
              _matchesTimeFilter(
                po.receivedAt ??
                    DateTime.tryParse(po.createdAt) ??
                    DateTime.now(),
                period,
              ),
        )
        .length;
    final recv = _scopedSales
        .where(
          (s) =>
              s.paymentMethod.toUpperCase() == 'CHEQUE' &&
              _matchesTimeFilter(s.createdAt, period),
        )
        .length;
    return 'Issued: $issued | Recv: $recv';
  }

  String _calculatedActiveInstallmentsValueForPeriod(String period) {
    final plans = _scopedInstallmentPlans
        .where(
          (p) =>
              p.remainingAmount > 0 && _matchesTimeFilter(p.createdAt, period),
        )
        .toList();
    return '${plans.length} plans';
  }

  double _calculatedActiveInstallmentsRemainingForPeriod(String period) {
    return _scopedInstallmentPlans
        .where(
          (p) =>
              p.remainingAmount > 0 && _matchesTimeFilter(p.createdAt, period),
        )
        .fold<double>(0.0, (sum, p) => sum + p.remainingAmount);
  }

  double _calculatedCodOrdersForPeriod(String period) {
    return _scopedSales
        .where(
          (s) =>
              s.paymentMethod.toUpperCase() == 'COD' &&
              _matchesTimeFilter(s.createdAt, period),
        )
        .fold<double>(0.0, (sum, s) => sum + s.total);
  }

  double _periodRevenue(String period, {List<_SaleRecord>? sales}) {
    final periodSales = _salesForPeriod(period, sales ?? _sales);
    return periodSales.fold<double>(0, (sum, sale) => sum + sale.total);
  }

  _CashierSession? _activeSessionFor(String userId) {
    for (final s in _cashierSessions) {
      if (s.userId == userId && s.status == 'OPEN') {
        return s;
      }
    }
    return null;
  }

  Map<String, double> _calculateSessionBreakdown(_CashierSession session) {
    double opening = session.openingCash;
    double cashSales = 0.0;
    double cardSales = 0.0;
    double creditSales = 0.0;
    double installmentSales = 0.0;
    double codSales = 0.0;

    double creditCollected = 0.0;
    double installmentsCollected = 0.0;
    double drawerExpenses = 0.0;
    double cashRefunds = 0.0;
    double cashTransfers = 0.0;

    // 1. Sales processed by this user during the session
    for (final sale in _scopedSales) {
      if (sale.status == 'COMPLETED' && sale.employeeId == session.userId) {
        if (sale.createdAt.isAfter(session.openingTime) &&
            (session.closingTime == null ||
                sale.createdAt.isBefore(session.closingTime!))) {
          final pm = sale.paymentMethod.toUpperCase();
          if (pm == 'CASH') {
            cashSales += sale.total;
          } else if (pm == 'CARD') {
            cardSales += sale.total;
          } else if (pm == 'CREDIT') {
            creditSales += sale.total;
          } else if (pm == 'INSTALLMENT') {
            installmentSales += sale.total;
          } else if (pm == 'COD') {
            codSales += sale.total;
          }
        }
      }
    }

    // 2. Customer Credit payments collected in CASH during the session
    for (final customer in _scopedCustomers) {
      final payments =
          _customerCreditPayments[customer.id] ?? const <_CreditPaymentItem>[];
      for (final p in payments) {
        if (p.createdAt.isAfter(session.openingTime) &&
            (session.closingTime == null ||
                p.createdAt.isBefore(session.closingTime!))) {
          creditCollected += p.amount;
        }
      }
    }

    // 3. Installments in Cash during the session
    for (final plan in _scopedInstallmentPlans) {
      if (plan.paymentMethod.toUpperCase() == 'CASH') {
        if (plan.createdAt.isAfter(session.openingTime) &&
            (session.closingTime == null ||
                plan.createdAt.isBefore(session.closingTime!))) {
          installmentsCollected += plan.downPayment;
        }
        for (final schedule in plan.schedules) {
          if (schedule.paidAt != null &&
              schedule.paidAt!.isAfter(session.openingTime) &&
              (session.closingTime == null ||
                  schedule.paidAt!.isBefore(session.closingTime!))) {
            installmentsCollected += schedule.paidAmount;
          }
        }
      }
    }

    // 4. Cash Drawer Expenses during the session
    for (final exp in _scopedExpenses) {
      final expenseDate = exp.expenseDate;
      if (expenseDate.isAfter(session.openingTime) &&
          (session.closingTime == null ||
              expenseDate.isBefore(session.closingTime!))) {
        final pm = _getExpensePaymentMethod(exp.notes);
        final notes = exp.notes?.toLowerCase() ?? '';
        final isDrawer = notes.contains('drawer') || notes.contains('cashier');
        if (pm == 'CASH' && isDrawer) {
          drawerExpenses += exp.amount;
        }
      }
    }

    // 5. Cash Refunds / Transactions processed during the session
    for (final tx in _scopedCashTransactions) {
      final txDate = DateTime.tryParse(tx.createdAt) ?? DateTime.now();
      if (txDate.isAfter(session.openingTime) &&
          (session.closingTime == null ||
              txDate.isBefore(session.closingTime!))) {
        if (tx.type == 'OUT') {
          cashRefunds += tx.amount;
        } else if (tx.type == 'IN') {
          cashTransfers += tx.amount;
        }
      }
    }

    final expected =
        opening +
        cashSales +
        codSales +
        creditCollected +
        installmentsCollected +
        cashTransfers -
        drawerExpenses -
        cashRefunds;

    return {
      'opening': opening,
      'cashSales': cashSales,
      'cardSales': cardSales,
      'creditSales': creditSales,
      'installmentSales': installmentSales,
      'codSales': codSales,
      'creditCollected': creditCollected,
      'installmentsCollected': installmentsCollected,
      'drawerExpenses': drawerExpenses,
      'cashRefunds': cashRefunds,
      'cashTransfers': cashTransfers,
      'expected': expected,
    };
  }

  double _calculateExpectedCashForSession(_CashierSession session) {
    return _calculateSessionBreakdown(session)['expected'] ??
        session.openingCash;
  }

  Future<void> _openSession(
    String userId,
    String userName,
    double openingCash,
  ) async {
    final sessionId = 'SESS-${DateTime.now().millisecondsSinceEpoch}';
    final locationId = _activeLocationForWrites;
    final session = _CashierSession(
      id: sessionId,
      userId: userId,
      userName: userName,
      openingTime: DateTime.now(),
      openingCash: openingCash,
      expectedCash: openingCash,
      status: 'OPEN',
      locationId: locationId,
    );

    // Find previous closed session at this location to check keptCash
    double previousKeptCash = 0.0;
    try {
      final prev = _cashierSessions.firstWhere(
        (s) => s.status == 'CLOSED' && s.locationId == locationId,
      );
      previousKeptCash = prev.keptCash;
    } catch (_) {}

    setState(() {
      _cashierSessions.insert(0, session);
      final diff = openingCash - previousKeptCash;
      if (diff > 0) {
        _bankAccountBalance -= diff;
        _bankTransactions.insert(
          0,
          _BankTransaction(
            id: 'TX-BANK-${DateTime.now().millisecondsSinceEpoch}',
            type: 'OPEN_SHIFT_WITHDRAW',
            amount: diff,
            referenceId: sessionId,
            notes:
                'Drawer open cash withdrawal for cashier $userName (net adjustment: opening ${_money(openingCash)} - prev kept ${_money(previousKeptCash)})',
            createdAt: DateTime.now(),
          ),
        );
      } else if (diff < 0) {
        final depositAmt = -diff;
        _bankAccountBalance += depositAmt;
        _bankTransactions.insert(
          0,
          _BankTransaction(
            id: 'TX-BANK-${DateTime.now().millisecondsSinceEpoch}',
            type: 'CLOSE_SHIFT_DEPOSIT',
            amount: depositAmt,
            referenceId: sessionId,
            notes:
                'Drawer open deposit for cashier $userName (net adjustment: opening ${_money(openingCash)} - prev kept ${_money(previousKeptCash)})',
            createdAt: DateTime.now(),
          ),
        );
      }
    });

    await _persistWorkspaceData();
    await _enqueueSync('INSERT', 'cashier_sessions', session.id);
    if (_bankTransactions.isNotEmpty && _bankTransactions.first.referenceId == sessionId) {
      await _enqueueSync('INSERT', 'bank_transactions', _bankTransactions.first.id);
    }
  }

  Future<void> _closeSession(
    _CashierSession session,
    double actualCash, {
    double? payoutAmount,
    String? payoutReason,
    double keptCash = 0.0,
  }) async {
    if (payoutAmount != null && payoutAmount > 0) {
      final expenseId = 'EXP-${DateTime.now().millisecondsSinceEpoch}';
      final companion = db.ExpensesCompanion(
        id: Value(expenseId),
        tenantId: Value(_activeTenantId ?? 'local'),
        category: const Value('OTHER'),
        description: Value(payoutReason ?? 'Cashier Drawer Withdrawal'),
        amount: Value(payoutAmount),
        locationId: Value(session.locationId),
        employeeId: Value(session.userId),
        notes: const Value('CASH|drawer'),
        expenseDate: Value(DateTime.now()),
        synced: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      await _appDatabase!.insertExpense(companion);
      await _loadCoreDataFromRepositories();
      await _enqueueSync('INSERT', 'expenses', expenseId);
    }

    final expected = _calculateExpectedCashForSession(session);
    final difference = actualCash - expected;

    setState(() {
      session.closingTime = DateTime.now();
      session.closingCash = actualCash;
      session.expectedCash = expected;
      session.actualCash = actualCash;
      session.difference = difference;
      session.keptCash = keptCash;
      session.status = 'CLOSED';

      // Deposit the actual closing cash back into the bank minus kept cash
      final depositAmount = actualCash - keptCash;
      if (depositAmount > 0) {
        _bankAccountBalance += depositAmount;
        _bankTransactions.insert(
          0,
          _BankTransaction(
            id: 'TX-BANK-${DateTime.now().millisecondsSinceEpoch}',
            type: 'CLOSE_SHIFT_DEPOSIT',
            amount: depositAmount,
            referenceId: session.id,
            notes:
                'Drawer close deposit for cashier ${session.userName} (kept ${_money(keptCash)} in drawer)',
            createdAt: DateTime.now(),
          ),
        );
      }
    });

    await _persistWorkspaceData();
    await _enqueueSync('UPDATE', 'cashier_sessions', session.id);
    if (actualCash - keptCash > 0 &&
        _bankTransactions.isNotEmpty &&
        _bankTransactions.first.referenceId == session.id) {
      await _enqueueSync('INSERT', 'bank_transactions', _bankTransactions.first.id);
    }
  }

  void _applyBarcodePreset(String presetKey) {
    setState(() {
      _barcodePreset = presetKey;
      switch (presetKey) {
        case 'zebra_zd230_3col_22mm':
          _barcodePreset = 'zebra_zd230_3col_22mm';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 101.6;
          _barcodeLabelWidthMm = 31.8;
          _barcodeLabelHeightMm = 22.0;
          _barcodeColumns = 3;
          _barcodeHorizontalGapMm = 2.0;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 1.1;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 3.5;
          _barcodeHeightMm = 5.0;
          _barcodeFontScale = 0.85;
          break;
        case 'zebra_zd230_3col':
        case 'zebra_3col_32x19':
          _barcodePreset = 'zebra_zd230_3col';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 101.6;
          _barcodeLabelWidthMm = 31.75;
          _barcodeLabelHeightMm = 25.4;
          _barcodeColumns = 3;
          _barcodeHorizontalGapMm = 2.0;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 1.15;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          _barcodeHeightMm = 7.5;
          _barcodeFontScale = 0.90;
          break;
        case 'zebra_zd230_2col':
        case 'zebra_2col_38x25':
          _barcodePreset = 'zebra_zd230_2col';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 101.6;
          _barcodeLabelWidthMm = 48.0;
          _barcodeLabelHeightMm = 25.4;
          _barcodeColumns = 2;
          _barcodeHorizontalGapMm = 2.0;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 1.5;
          _barcodeRightShiftMm = 4.0;
          _barcodeTopShiftMm = 1.0;
          _barcodeHeightMm = 8.5;
          _barcodeFontScale = 0.95;
          break;
        case 'zebra_zd230_1col':
        case 'zebra_1col_50x30':
          _barcodePreset = 'zebra_zd230_1col';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 101.6;
          _barcodeLabelWidthMm = 98.0;
          _barcodeLabelHeightMm = 50.0;
          _barcodeColumns = 1;
          _barcodeHorizontalGapMm = 0.0;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 1.5;
          _barcodeRightShiftMm = 5.0;
          _barcodeTopShiftMm = 2.0;
          break;
        case 'zebra_generic_3col':
          _barcodePreset = 'zebra_generic_3col';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 76.2;
          _barcodeLabelWidthMm = 23.0;
          _barcodeLabelHeightMm = 25.4;
          _barcodeColumns = 3;
          _barcodeHorizontalGapMm = 2.0;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 1.5;
          _barcodeRightShiftMm = 5.0;
          _barcodeTopShiftMm = 2.0;
          break;
        case 'dymo_lw_standard':
        case 'dymo_single_54x25':
          _barcodePreset = 'dymo_lw_standard';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 89.0;
          _barcodeLabelWidthMm = 89.0;
          _barcodeLabelHeightMm = 28.0;
          _barcodeColumns = 1;
          _barcodeHorizontalGapMm = 0.0;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 2.0;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'dymo_lw_large':
        case 'dymo_large_89x36':
          _barcodePreset = 'dymo_lw_large';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 89.0;
          _barcodeLabelWidthMm = 89.0;
          _barcodeLabelHeightMm = 36.0;
          _barcodeColumns = 1;
          _barcodeHorizontalGapMm = 0.0;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 2.0;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'brother_ql_29mm':
          _barcodePreset = 'brother_ql_29mm';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 29.0;
          _barcodeLabelWidthMm = 29.0;
          _barcodeLabelHeightMm = 30.0;
          _barcodeColumns = 1;
          _barcodeHorizontalGapMm = 0.0;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 1.0;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'brother_ql_62mm':
        case 'brother_ql_62x29':
          _barcodePreset = 'brother_ql_62mm';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 62.0;
          _barcodeLabelWidthMm = 62.0;
          _barcodeLabelHeightMm = 30.0;
          _barcodeColumns = 1;
          _barcodeHorizontalGapMm = 0.0;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 1.0;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'generic_thermal_1col':
        case 'generic_80mm_roll':
          _barcodePreset = 'generic_thermal_1col';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 80.0;
          _barcodeLabelWidthMm = 76.0;
          _barcodeLabelHeightMm = 40.0;
          _barcodeColumns = 1;
          _barcodeHorizontalGapMm = 0.0;
          _barcodeVerticalGapMm = 3.0;
          _barcodeMarginMm = 2.0;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'generic_58mm_1col':
        case 'generic_58mm_roll':
          _barcodePreset = 'generic_58mm_1col';
          _barcodePrinterType = 'thermal';
          _barcodePaperFormat = 'custom_roll';
          _barcodePaperWidthMm = 58.0;
          _barcodeLabelWidthMm = 50.0;
          _barcodeLabelHeightMm = 25.0;
          _barcodeColumns = 1;
          _barcodeHorizontalGapMm = 0.0;
          _barcodeVerticalGapMm = 3.0;
          _barcodeMarginMm = 2.0;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'a4_3col':
        case 'a4_3x10':
          _barcodePreset = 'a4_3col';
          _barcodePrinterType = 'regular';
          _barcodePaperFormat = 'A4';
          _barcodePaperWidthMm = 210.0;
          _barcodeLabelWidthMm = 63.5;
          _barcodeLabelHeightMm = 29.6;
          _barcodeColumns = 3;
          _barcodeHorizontalGapMm = 2.5;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 7.0;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'a4_2col':
        case 'a4_2x7':
          _barcodePreset = 'a4_2col';
          _barcodePrinterType = 'regular';
          _barcodePaperFormat = 'A4';
          _barcodePaperWidthMm = 210.0;
          _barcodeLabelWidthMm = 99.1;
          _barcodeLabelHeightMm = 38.1;
          _barcodeColumns = 2;
          _barcodeHorizontalGapMm = 2.5;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 4.7;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'a4_4col':
        case 'a4_4x13':
          _barcodePreset = 'a4_4col';
          _barcodePrinterType = 'regular';
          _barcodePaperFormat = 'A4';
          _barcodePaperWidthMm = 210.0;
          _barcodeLabelWidthMm = 48.5;
          _barcodeLabelHeightMm = 21.2;
          _barcodeColumns = 4;
          _barcodeHorizontalGapMm = 2.0;
          _barcodeVerticalGapMm = 1.5;
          _barcodeMarginMm = 4.7;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'letter_3col':
        case 'letter_3x10':
          _barcodePreset = 'letter_3col';
          _barcodePrinterType = 'regular';
          _barcodePaperFormat = 'Letter';
          _barcodePaperWidthMm = 215.9;
          _barcodeLabelWidthMm = 66.7;
          _barcodeLabelHeightMm = 25.4;
          _barcodeColumns = 3;
          _barcodeHorizontalGapMm = 3.2;
          _barcodeVerticalGapMm = 2.0;
          _barcodeMarginMm = 4.8;
          _barcodeRightShiftMm = 0.0;
          _barcodeTopShiftMm = 0.0;
          break;
        case 'custom':
        default:
          break;
      }
      _saveBarcodeSettings();
      _syncBarcodeControllersWithValues();
    });
  }

  PdfPageFormat _barcodePageFormat() {
    switch (_barcodePaperFormat) {
      case '58mm':
        return PdfPageFormat(58 * PdfPageFormat.mm, 240 * PdfPageFormat.mm);
      case '80mm':
        return PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm);
      case 'Letter':
        return PdfPageFormat.letter;
      case 'custom_roll':
        return PdfPageFormat(
          (_barcodeLabelWidthMm + 2) * PdfPageFormat.mm,
          (_barcodeLabelHeightMm + 2) * PdfPageFormat.mm,
          marginAll: 1 * PdfPageFormat.mm,
        );
      case 'A4':
      default:
        return PdfPageFormat.a4;
    }
  }

  int _barcodeQuantityForProduct(String productId) {
    return _barcodeQuantityByProduct[productId] ?? 1;
  }

  void _setBarcodeQuantityForProduct(String productId, int quantity) {
    final safeQuantity = quantity.clamp(1, 999);
    setState(() {
      _barcodeQuantityByProduct[productId] = safeQuantity;
    });
  }

  pw.Widget _buildBarcodeLabel(_BarcodeLabelEntry entry, {double? maxAllowedHeightMm}) {
    final product = entry.product;
    final width = _barcodeLabelWidthMm * PdfPageFormat.mm;
    final targetHeightMm = maxAllowedHeightMm ?? _barcodeLabelHeightMm;
    final height = targetHeightMm * PdfPageFormat.mm;

    String rawBarcode;
    if (entry.imei != null && entry.imei!.trim().isNotEmpty) {
      rawBarcode = entry.imei!.trim();
    } else {
      rawBarcode = product.barcode.trim().isEmpty
          ? product.id.trim()
          : product.barcode.trim();
    }

    String barcodeValue = rawBarcode.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    if (barcodeValue.isEmpty) {
      barcodeValue = '12345678';
    }

    pw.Barcode barcodeWidgetType;
    switch (_barcodeFormat) {
      case 'CODE39':
        final clean = barcodeValue.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-\.\ \$\/\+\%]'), '');
        if (clean.isNotEmpty) {
          barcodeWidgetType = pw.Barcode.code39();
          barcodeValue = clean;
        } else {
          barcodeWidgetType = pw.Barcode.code128();
        }
        break;
      case 'EAN13':
        final digits = barcodeValue.replaceAll(RegExp(r'\D'), '');
        if (digits.length == 12) {
          barcodeWidgetType = pw.Barcode.ean13();
          barcodeValue = digits;
        } else if (digits.length == 13) {
          try {
            pw.Barcode.ean13().verify(digits);
            barcodeWidgetType = pw.Barcode.ean13();
            barcodeValue = digits;
          } catch (_) {
            barcodeWidgetType = pw.Barcode.ean13();
            barcodeValue = digits.substring(0, 12);
          }
        } else {
          barcodeWidgetType = pw.Barcode.code128();
        }
        break;
      case 'UPCA':
        final digits = barcodeValue.replaceAll(RegExp(r'\D'), '');
        if (digits.length == 11 || digits.length == 12) {
          barcodeWidgetType = pw.Barcode.upcA();
          barcodeValue = digits;
        } else {
          barcodeWidgetType = pw.Barcode.code128();
        }
        break;
      case 'QR':
        barcodeWidgetType = pw.Barcode.qrCode();
        break;
      case 'CODE128':
      default:
        barcodeWidgetType = pw.Barcode.code128();
        break;
    }

    final isCompact = targetHeightMm <= 26.0;
    final fontScale = _barcodeFontScale.clamp(0.5, 1.8);
    final baseFontSize = ((isCompact ? 4.5 : 6.0) * fontScale).clamp(3.2, 9.0);
    final titleFontSize = ((isCompact ? 5.5 : 8.0) * fontScale).clamp(3.8, 11.0);
    final priceFontSize = ((isCompact ? 6.5 : 9.0) * fontScale).clamp(4.2, 12.0);
    final itemSpacing = (isCompact ? 0.3 : 0.8) * PdfPageFormat.mm;

    // Barcode Height: driven directly by user settings, safely clamped to fit sticker
    final barcodeHeightMm = _barcodeFormat == 'QR'
        ? _barcodeHeightMm.clamp(4.0, (targetHeightMm * 0.50).clamp(4.0, 30.0))
        : _barcodeHeightMm.clamp(3.5, (targetHeightMm - 7.5).clamp(3.5, 30.0));

    final textWidgets = <pw.Widget>[];

    // Store Name
    if (_barcodeShowStoreName && _companyName.trim().isNotEmpty) {
      textWidgets.add(
        pw.Text(
          _companyName.trim(),
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: baseFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
      textWidgets.add(pw.SizedBox(height: itemSpacing * 0.5));
    }

    // Item Name
    if (_barcodeShowName) {
      textWidgets.add(
        pw.Text(
          product.name,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: titleFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
      textWidgets.add(pw.SizedBox(height: itemSpacing * 0.6));
    }

    // Price
    if (_barcodeShowPrice) {
      textWidgets.add(
        pw.Text(
          _money(product.price),
          maxLines: 1,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: priceFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
      textWidgets.add(pw.SizedBox(height: itemSpacing * 0.6));
    }

    // Barcode Visual
    pw.Widget barcodeVisual;
    try {
      barcodeVisual = pw.BarcodeWidget(
        barcode: barcodeWidgetType,
        data: barcodeValue,
        drawText: false,
        color: PdfColors.black,
      );
    } catch (_) {
      barcodeVisual = pw.BarcodeWidget(
        barcode: pw.Barcode.code128(),
        data: '12345678',
        drawText: false,
        color: PdfColors.black,
      );
    }

    if (_barcodeFormat == 'QR') {
      textWidgets.add(
        pw.SizedBox(
          width: barcodeHeightMm * PdfPageFormat.mm,
          height: barcodeHeightMm * PdfPageFormat.mm,
          child: barcodeVisual,
        ),
      );
    } else {
      textWidgets.add(
        pw.SizedBox(
          width: (width - 2.0 * PdfPageFormat.mm).clamp(15.0, width),
          height: barcodeHeightMm * PdfPageFormat.mm,
          child: barcodeVisual,
        ),
      );
    }

    // IMEI or Barcode Text (Human-readable)
    if (entry.imei != null && entry.imei!.trim().isNotEmpty) {
      textWidgets.add(pw.SizedBox(height: itemSpacing * 0.4));
      textWidgets.add(
        pw.Text(
          'S/N: ${entry.imei}',
          maxLines: 1,
          style: pw.TextStyle(
            fontSize: (baseFontSize - 0.2).clamp(3.2, 8.5),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    } else if (_barcodeShowCodeText) {
      textWidgets.add(pw.SizedBox(height: itemSpacing * 0.4));
      textWidgets.add(
        pw.Text(
          barcodeValue,
          maxLines: 1,
          style: pw.TextStyle(
            fontSize: (baseFontSize - 0.2).clamp(3.2, 8.5),
          ),
        ),
      );
    }

    // SKU
    if (_barcodeShowSku) {
      final skuStr = product.id.trim();
      if (skuStr.isNotEmpty) {
        textWidgets.add(pw.SizedBox(height: itemSpacing * 0.3));
        textWidgets.add(
          pw.Text(
            'SKU: $skuStr',
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: (baseFontSize - 0.5).clamp(3.0, 7.5),
            ),
          ),
        );
      }
    }

    // Category
    if (_barcodeShowCategory) {
      textWidgets.add(pw.SizedBox(height: itemSpacing * 0.3));
      textWidgets.add(
        pw.Text(
          product.category,
          maxLines: 1,
          style: pw.TextStyle(
            fontSize: (baseFontSize - 0.8).clamp(3.0, 7.5),
          ),
        ),
      );
    }

    final labelBox = pw.Container(
      width: width,
      height: height,
      alignment: pw.Alignment.center,
      padding: pw.EdgeInsets.symmetric(
        horizontal: 0.5 * PdfPageFormat.mm,
        vertical: 0.2 * PdfPageFormat.mm,
      ),
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: pw.Alignment.center,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          mainAxisSize: pw.MainAxisSize.min,
          children: textWidgets,
        ),
      ),
    );

    if (_barcodeRotationDegrees == 180) {
      return pw.Transform.rotateBox(
        angle: math.pi,
        child: labelBox,
      );
    } else if (_barcodeRotationDegrees == 90) {
      return pw.Transform.rotateBox(
        angle: math.pi / 2,
        child: labelBox,
      );
    } else if (_barcodeRotationDegrees == 270) {
      return pw.Transform.rotateBox(
        angle: 3 * math.pi / 2,
        child: labelBox,
      );
    }

    return labelBox;
  }

  bool _isZebraPrinter(String printerName) {
    final lower = printerName.toLowerCase();
    return lower.contains('zebra') ||
        lower.contains('zdesigner') ||
        lower.contains('zd230') ||
        lower.contains('zpl');
  }

  String _cleanZplText(String s) {
    return s
        .replaceAll('^', ' ')
        .replaceAll('~', ' ')
        .replaceAll('\\', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('රු.', 'Rs.')
        .replaceAll('රු', 'Rs.')
        .trim();
  }

  String _buildZplForEntries(List<_BarcodeLabelEntry> entries) {
    final buffer = StringBuffer();
    final cols = _barcodeColumns.clamp(1, 10);
    const dotsPerMm = 8.0; // 203 DPI = 8.0 dots per mm
    final rollWidthDots = (_barcodePaperWidthMm * dotsPerMm).round();
    final labelWidthDots = (_barcodeLabelWidthMm * dotsPerMm).round();
    final labelHeightDots = (_barcodeLabelHeightMm * dotsPerMm).round();
    final colGapDots = (_barcodeHorizontalGapMm * dotsPerMm).round();
    final rowGapDots = (_barcodeVerticalGapMm * dotsPerMm).round();
    final labelPitchDots = labelHeightDots + rowGapDots;
    final leftShiftDots = (_barcodeRightShiftMm * dotsPerMm).round();
    final topShiftDots = (_barcodeTopShiftMm * dotsPerMm).round();
    final scale = _barcodeFontScale.clamp(0.6, 1.5);

    // Total width of all columns including horizontal gaps
    final totalSpanDots = (cols * labelWidthDots) + ((cols - 1) * colGapDots);
    final autoMarginDots = totalSpanDots < rollWidthDots
        ? ((rollWidthDots - totalSpanDots) / 2.0).round()
        : (_barcodeMarginMm * dotsPerMm).round();
    final effectiveLeftDots = (autoMarginDots + leftShiftDots).clamp(0, rollWidthDots - labelWidthDots);

    // Calculate vertical content height so everything is centered and never overruns the label
    final storeH = (_barcodeShowStoreName && _companyName.trim().isNotEmpty) ? (18 * scale).round() : 0;
    final nameH = _barcodeShowName ? (22 * scale).round() : 0;
    final priceH = _barcodeShowPrice ? (20 * scale).round() : 0;
    final barcodeH = (_barcodeHeightMm * dotsPerMm).round().clamp(24, 60);
    final codeTextH = _barcodeShowCodeText ? (18 * scale).round() : 0;
    final skuH = _barcodeShowSku ? (18 * scale).round() : 0;
    final categoryH = _barcodeShowCategory ? (16 * scale).round() : 0;

    int totalContentH = 0;
    if (storeH > 0) totalContentH += storeH + (2 * scale).round();
    if (nameH > 0) totalContentH += nameH + (2 * scale).round();
    if (priceH > 0) totalContentH += priceH + (2 * scale).round();
    totalContentH += barcodeH + 4;
    if (codeTextH > 0) totalContentH += codeTextH + (2 * scale).round();
    if (skuH > 0) totalContentH += skuH + (2 * scale).round();
    if (categoryH > 0) totalContentH += categoryH + (2 * scale).round();

    // Auto-center content vertically within labelHeightDots
    final idealTopPad = ((labelHeightDots - totalContentH) / 2.0).round().clamp(4, labelHeightDots);
    final maxAllowedStart = (labelHeightDots - totalContentH - 2).clamp(2, labelHeightDots);
    // When user adjusts topShift, apply it directly in layout coordinates (safely clamped)
    final contentStartY = topShiftDots > 0
        ? (topShiftDots).clamp(2, maxAllowedStart)
        : idealTopPad;

    // Ensure printer uses gap tracking and exact label pitch
    buffer.writeln('! U1 setvar "media.sense_mode" "gap"');
    buffer.writeln('! U1 setvar "zpl.label_length_always" "yes"');
    buffer.writeln('! U1 setvar "zpl.label_length" "$labelPitchDots"');

    for (int i = 0; i < entries.length; i += cols) {
      final rowEntries = entries.skip(i).take(cols).toList();
      buffer.writeln('^XA');
      buffer.writeln('^PW$rollWidthDots');
      buffer.writeln('^LL$labelPitchDots,Y');
      buffer.writeln('^LT0'); // Reset hardware label top so format strictly stays on current label
      buffer.writeln('^MNY'); // Media Sense: Gap / Web
      buffer.writeln('^LH0,0');

      for (int c = 0; c < rowEntries.length; c++) {
        final entry = rowEntries[c];
        final colX = effectiveLeftDots + (c * (labelWidthDots + colGapDots));
        int currY = contentStartY;

        // Store Name
        if (storeH > 0) {
          final w = (16 * scale).round();
          buffer.writeln('^FO$colX,$currY^FB$labelWidthDots,1,0,C^A0N,$storeH,$w^FD${_cleanZplText(_companyName.trim())}^FS');
          currY += storeH + (2 * scale).round();
        }

        // Product Name
        if (nameH > 0) {
          final w = (20 * scale).round();
          buffer.writeln('^FO$colX,$currY^FB$labelWidthDots,1,0,C^A0N,$nameH,$w^FD${_cleanZplText(entry.product.name)}^FS');
          currY += nameH + (2 * scale).round();
        }

        // Price
        if (priceH > 0) {
          final w = (18 * scale).round();
          buffer.writeln('^FO$colX,$currY^FB$labelWidthDots,1,0,C^A0N,$priceH,$w^FD${_cleanZplText(_money(entry.product.price))}^FS');
          currY += priceH + (2 * scale).round();
        }

        // Barcode
        final rawBarcode = entry.imei != null && entry.imei!.trim().isNotEmpty
            ? entry.imei!.trim()
            : (entry.product.barcode.trim().isEmpty ? entry.product.id.trim() : entry.product.barcode.trim());
        final narrowBar = labelWidthDots > 280 ? 2 : 1;
        final estBarcodeDots = (rawBarcode.length + 3) * 11 * narrowBar + 35;
        final barcodeOffsetX = ((labelWidthDots - estBarcodeDots) / 2).round().clamp(5, labelWidthDots - 20);
        final barcodeX = colX + barcodeOffsetX;
        buffer.writeln('^FO$barcodeX,$currY^BY$narrowBar,2.5,$barcodeH^BCN,$barcodeH,N,N,N^FD$rawBarcode^FS');
        currY += barcodeH + 4;

        // Human-readable Barcode Text / IMEI
        if (entry.imei != null && entry.imei!.trim().isNotEmpty) {
          final h = (18 * scale).round();
          final w = (16 * scale).round();
          buffer.writeln('^FO$colX,$currY^FB$labelWidthDots,1,0,C^A0N,$h,$w^FDS/N: ${_cleanZplText(entry.imei!.trim())}^FS');
          currY += h + (2 * scale).round();
        } else if (codeTextH > 0) {
          final w = (16 * scale).round();
          buffer.writeln('^FO$colX,$currY^FB$labelWidthDots,1,0,C^A0N,$codeTextH,$w^FD${_cleanZplText(rawBarcode)}^FS');
          currY += codeTextH + (2 * scale).round();
        }

        // SKU
        if (skuH > 0 && entry.product.id.trim().isNotEmpty) {
          final w = (16 * scale).round();
          buffer.writeln('^FO$colX,$currY^FB$labelWidthDots,1,0,C^A0N,$skuH,$w^FDSKU: ${_cleanZplText(entry.product.id.trim())}^FS');
          currY += skuH + (2 * scale).round();
        }

        // Category
        if (categoryH > 0 && entry.product.category.trim().isNotEmpty) {
          final w = (14 * scale).round();
          buffer.writeln('^FO$colX,$currY^FB$labelWidthDots,1,0,C^A0N,$categoryH,$w^FD${_cleanZplText(entry.product.category.trim())}^FS');
        }
      }
      buffer.writeln('^XZ');
    }

    return buffer.toString();
  }

  Future<bool> _printBarcodeEntriesViaZpl(String printerName, String zplContent) async {
    if (!Platform.isWindows) return false;

    final possibleExePaths = [
      'windows\\rawprint.exe',
      '${File(Platform.resolvedExecutable).parent.path}\\rawprint.exe',
      r'd:\bizpark\cloude_pos\store_buddy_pos\windows\rawprint.exe',
      r'D:\bizpark\cloude_pos\store_buddy_pos\build\windows\x64\runner\Debug\rawprint.exe',
    ];

    String? exePath;
    for (final p in possibleExePaths) {
      if (File(p).existsSync()) {
        exePath = p;
        break;
      }
    }

    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}\\sb_label_${DateTime.now().millisecondsSinceEpoch}.zpl');
    await tempFile.writeAsString(zplContent, encoding: utf8);

    if (exePath != null) {
      try {
        final res = await Process.run(exePath, [printerName, tempFile.path]);
        if (res.exitCode == 0) {
          try { await tempFile.delete(); } catch (_) {}
          return true;
        }
      } catch (e) {
        debugPrint('rawprint.exe failed: $e');
      }
    }

    try {
      final psScript = File('${tempDir.path}\\sb_raw_${DateTime.now().millisecondsSinceEpoch}.ps1');
      await psScript.writeAsString('''
      [System.IO.File]::ReadAllBytes("${tempFile.path.replaceAll(r'\', r'\\')}") | Out-Printer -Name "$printerName"
      ''');
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        psScript.path,
      ]);
      try { await psScript.delete(); } catch (_) {}
      try { await tempFile.delete(); } catch (_) {}
      return res.exitCode == 0;
    } catch (_) {}

    try { await tempFile.delete(); } catch (_) {}
    return false;
  }

  Future<void> _printBarcodeEntries(List<_BarcodeLabelEntry> entries) async {
    if (entries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products selected for barcode print')),
      );
      return;
    }

    // Direct native ZPL printing for Zebra thermal label printers
    if (Platform.isWindows && _localLabelPrinterName != null && _localLabelPrinterName!.trim().isNotEmpty) {
      final targetName = _localLabelPrinterName!.trim();
      if (_isZebraPrinter(targetName)) {
        try {
          final zpl = _buildZplForEntries(entries);
          final zplSuccess = await _printBarcodeEntriesViaZpl(targetName, zpl);
          if (zplSuccess) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Labels printed directly via ZPL to $targetName!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
            return;
          }
        } catch (zplErr) {
          debugPrint('ZPL printing error, falling back to PDF: $zplErr');
        }
      }
    }

    try {
      final doc = pw.Document();
      final isThermal = _barcodePrinterType == 'thermal' ||
          _barcodePaperFormat == 'custom_roll' ||
          _barcodePaperFormat == '58mm' ||
          _barcodePaperFormat == '80mm';

      PdfPageFormat targetPageFormat;

      if (isThermal) {
        // Multi-column or 1-column thermal roll (e.g. Zebra ZD230, Dymo, Brother)
        final cols = _barcodeColumns.clamp(1, 10);
        final gap = _barcodeHorizontalGapMm;
        final margin = _barcodeMarginMm;
        final leftShiftMm = _barcodeRightShiftMm;
        final topShiftMm = _barcodeTopShiftMm;

        final pageWidth = _barcodePaperWidthMm;
        // On die-cut thermal label rolls (Zebra ZD230), targetPageFormat height MUST BE the sticker height (_barcodeLabelHeightMm)
        // Never add vertical gap to page format height, because the physical sensor stops at the sticker edge.
        // Adding gap makes Zebra advance into the next label row, missing a row completely!
        final pageHeight = _barcodeLabelHeightMm;

        // Auto-center horizontal margin if base span fits within roll width
        final baseColumnsWidth = (cols * _barcodeLabelWidthMm) + ((cols - 1) * gap);
        final computedMargin = baseColumnsWidth < pageWidth
            ? ((pageWidth - baseColumnsWidth) / 2.0).clamp(0.0, 20.0)
            : margin;
        final effectiveLeft = (computedMargin + leftShiftMm).clamp(0.0, (pageWidth - _barcodeLabelWidthMm).clamp(0.0, pageWidth));

        // CRITICAL FOR THERMAL ROLL LABELS (e.g. Zebra ZD230 22mm die-cut rolls):
        // Top shift must be strictly clamped to <= 1.5mm so it never pushes content past the 22mm page boundary.
        // Overrunning the page boundary causes the Zebra driver to feed past the gap sensor into the next row,
        // which skips a label row completely!
        final safeTopShift = topShiftMm.clamp(0.0, 8.0);
        final effectiveTop = safeTopShift;
        final effectiveLabelHeight = (pageHeight - effectiveTop).clamp(8.0, pageHeight);

        targetPageFormat = PdfPageFormat(
          pageWidth * PdfPageFormat.mm,
          pageHeight * PdfPageFormat.mm,
        );

        for (int i = 0; i < entries.length; i += cols) {
          final rowEntries = entries.skip(i).take(cols).toList();

          doc.addPage(
            pw.Page(
              pageFormat: targetPageFormat,
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) {
                return pw.Container(
                  width: pageWidth * PdfPageFormat.mm,
                  height: pageHeight * PdfPageFormat.mm,
                  child: pw.Padding(
                    padding: pw.EdgeInsets.only(
                      left: effectiveLeft * PdfPageFormat.mm,
                      top: effectiveTop * PdfPageFormat.mm,
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        for (int j = 0; j < cols; j++) ...[
                          if (j > 0) pw.SizedBox(width: gap * PdfPageFormat.mm),
                          if (j < rowEntries.length)
                            pw.Container(
                              width: _barcodeLabelWidthMm * PdfPageFormat.mm,
                              height: effectiveLabelHeight * PdfPageFormat.mm,
                              alignment: pw.Alignment.center,
                              child: _buildBarcodeLabel(
                                rowEntries[j],
                                maxAllowedHeightMm: effectiveLabelHeight,
                              ),
                            )
                          else
                            pw.SizedBox(
                              width: _barcodeLabelWidthMm * PdfPageFormat.mm,
                              height: effectiveLabelHeight * PdfPageFormat.mm,
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
      } else {
        // Sheet printer (A4 / Letter)
        targetPageFormat = _barcodePageFormat();
        doc.addPage(
          pw.MultiPage(
            pageFormat: targetPageFormat,
            margin: pw.EdgeInsets.all(_barcodeMarginMm * PdfPageFormat.mm),
            build: (_) => [
              pw.Wrap(
                spacing: _barcodeHorizontalGapMm * PdfPageFormat.mm,
                runSpacing: _barcodeVerticalGapMm * PdfPageFormat.mm,
                children: entries.map(_buildBarcodeLabel).toList(),
              ),
            ],
          ),
        );
      }

      final pdfBytes = await doc.save();

      // Check if dedicated label printer is configured locally
      if (_localLabelPrinterName != null && _localLabelPrinterName!.trim().isNotEmpty) {
        final targetName = _localLabelPrinterName!.trim().toLowerCase();
        final printers = await Printing.listPrinters();
        Printer? match;
        for (final p in printers) {
          if (p.name.toLowerCase() == targetName) {
            match = p;
            break;
          }
        }
        if (match == null) {
          for (final p in printers) {
            if (p.name.toLowerCase().contains(targetName)) {
              match = p;
              break;
            }
          }
        }

        if (match != null) {
          try {
            final result = await Printing.directPrintPdf(
              printer: match,
              onLayout: (_) async => pdfBytes,
              name: 'Product Labels',
              format: targetPageFormat,
              usePrinterSettings: true,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result
                        ? 'Labels printed directly to ${match.name}!'
                        : 'Print job queued for ${match.name}',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
            return;
          } catch (directErr) {
            debugPrint('Direct printing failed: $directErr. Opening standard print dialog.');
          }
        }
      }

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Product Labels',
        format: targetPageFormat,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode Printing Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testPrintSampleBarcodeLabel() async {
    final sampleProd = _products.isNotEmpty
        ? _products.first
        : _ProductItem(
            id: 'PROD-001',
            name: 'Sample Retail Product',
            category: 'Retail',
            barcode: '123456789012',
            price: 1500.0,
            stock: 25,
            minStock: 5,
          );
    final count = (_barcodePrinterType == 'thermal' && _barcodeColumns > 1) ? _barcodeColumns : 1;
    final entries = List.generate(count, (_) => _BarcodeLabelEntry(product: sampleProd));
    await _printBarcodeEntries(entries);
  }

  Future<void> _printBarcodeLabels(List<_ProductItem> labels) async {
    final entries = labels.map((p) => _BarcodeLabelEntry(product: p)).toList();
    await _printBarcodeEntries(entries);
  }

  int _loyaltyPointsForAmount(double amount) => (amount ~/ 100).toInt();

  String _formatQty(double qty) {
    if (qty % 1 == 0) {
      return qty.toInt().toString();
    }
    final s = qty.toStringAsFixed(3);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  final List<_SettingsTabItem> _settingsTabs = const [
    _SettingsTabItem(key: 'profile', label: 'Profile', icon: Icons.person_rounded),
    _SettingsTabItem(key: 'company', label: 'Company & Store', icon: Icons.business_rounded),
    _SettingsTabItem(key: 'general', label: 'Store Operations', icon: Icons.tune_rounded),
    _SettingsTabItem(key: 'print_settings', label: 'Receipt & Printing', icon: Icons.print_rounded),
    _SettingsTabItem(key: 'navigation', label: 'Navigation & Menu', icon: Icons.menu_open_rounded),
    _SettingsTabItem(key: 'preferences', label: 'Display & Preferences', icon: Icons.palette_rounded),
    _SettingsTabItem(key: 'notifications', label: 'Notifications', icon: Icons.notifications_rounded),
    _SettingsTabItem(key: 'payroll', label: 'Payroll & HR', icon: Icons.request_page_rounded),
  ];

  Future<void> _exportReportsPdf() async {
    final totalRevenue = _sales.fold<double>(0, (sum, s) => sum + s.total);
    final completed = _sales.where((s) => s.status == 'COMPLETED').length;
    final cancelled = _sales.where((s) => s.status == 'CANCELLED').length;
    final returned = _sales.where((s) => s.status == 'RETURNED').length;
    final lowStock = _products.where((p) => p.stock <= p.minStock).length;
    final inventoryValue = _inventoryValue();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => [
          pw.Text(
            'Reports Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              _pdfRow('Metric', 'Value', header: true),
              _pdfRow('Total Revenue', _money(totalRevenue)),
              _pdfRow('Completed Sales', '$completed'),
              _pdfRow('Cancelled Sales', '$cancelled'),
              _pdfRow('Returned Sales', '$returned'),
              _pdfRow('Customers', '${_customers.length}'),
              _pdfRow('Low Stock Products', '$lowStock'),
              _pdfRow('Inventory Value', _money(inventoryValue)),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<void> _exportSalesPdf(List<_SaleRecord> sales) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => [
          pw.Text(
            'Sales Export',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _pdfRow(
                'Receipt',
                'Customer',
                c3: 'Payment',
                c4: 'Total',
                header: true,
              ),
              ...sales.map(
                (sale) => _pdfRow(
                  sale.id,
                  sale.customerName,
                  c3: sale.paymentMethod,
                  c4: _money(sale.total),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.TableRow _pdfRow(
    String c1,
    String c2, {
    String? c3,
    String? c4,
    bool header = false,
  }) {
    final cells = <String>[c1, c2, c3 ?? '', c4 ?? ''];
    return pw.TableRow(
      decoration: header
          ? const pw.BoxDecoration(color: PdfColors.grey200)
          : null,
      children: cells
          .map(
            (text) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                text,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: header
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _generateBarcodeValue() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'SB${now.toString().substring(now.toString().length - 10)}';
  }

  Future<void> _printProductBarcode(_ProductItem product) async {
    final entries = <_BarcodeLabelEntry>[];
    final imeis = product.imeiList;
    if (_barcodePrintIndividualImei && imeis.isNotEmpty) {
      for (final imei in imeis) {
        entries.add(_BarcodeLabelEntry(product: product, imei: imei));
      }
    } else {
      final quantity = _barcodeQuantityForProduct(product.id);
      for (var i = 0; i < quantity; i++) {
        entries.add(_BarcodeLabelEntry(product: product));
      }
    }
    await _printBarcodeEntries(entries);
  }

  Future<void> _printSelectedProductBarcodes() async {
    final entries = <_BarcodeLabelEntry>[];
    for (final product in _products) {
      if (!_selectedBarcodeProductIds.contains(product.id)) {
        continue;
      }

      final imeis = product.imeiList;
      if (_barcodePrintIndividualImei && imeis.isNotEmpty) {
        for (final imei in imeis) {
          entries.add(_BarcodeLabelEntry(product: product, imei: imei));
        }
      } else {
        final quantity = _barcodeQuantityForProduct(product.id);
        for (var i = 0; i < quantity; i++) {
          entries.add(_BarcodeLabelEntry(product: product));
        }
      }
    }

    await _printBarcodeEntries(entries);
  }

  List<_ProductItem> _expiringProductsSoon() {
    final now = DateTime.now();
    return _products.where((product) {
      final expiryDate = product.expiryDate;
      if (expiryDate == null) return false;
      final daysBefore = product.expiryReminderDays > 0
          ? product.expiryReminderDays
          : (product.expiryReminderMode == 'MONTH'
                ? 30
                : product.expiryReminderMode == 'CUSTOM'
                ? 7
                : 7);
      final reminderStart = expiryDate.subtract(Duration(days: daysBefore));
      return !now.isBefore(reminderStart);
    }).toList();
  }

  void _notifyExpiryReminders() {
    if (!mounted) return;
    final alerts = _expiringProductsSoon();
    if (alerts.isEmpty) return;

    final digest = alerts
        .map(
          (product) =>
              '${product.id}:${product.expiryDate?.toIso8601String()}:${product.expiryReminderMode}:${product.expiryReminderDays}',
        )
        .join('|');
    if (digest == _lastExpiryReminderDigest) return;
    _lastExpiryReminderDigest = digest;

    final preview = alerts.take(3).map((product) => product.name).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Expiry reminders due for ${alerts.length} product(s): $preview',
        ),
      ),
    );
  }

  Future<void> _recordCustomerCreditPayment(_CustomerItem customer) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Credit Payment  -  ${customer.name}'),
        content: SizedBox(
          width: _adaptiveWidth(380, minWidth: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Outstanding Balance: ${_money(customer.currentBalance)}'),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                return;
              }
              Navigator.pop(context, amount);
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );

    if (result == null || result <= 0) return;
    final paymentAmount = result > customer.currentBalance
        ? customer.currentBalance
        : result;
    if (paymentAmount <= 0) return;

    final payment = _CreditPaymentItem(
      id: 'CP${DateTime.now().millisecondsSinceEpoch}',
      amount: paymentAmount,
      balanceBefore: customer.currentBalance,
      balanceAfter: (customer.currentBalance - paymentAmount)
          .clamp(0, double.infinity)
          .toDouble(),
      note: noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() {
      customer.currentBalance = payment.balanceAfter;
      _customerCreditPayments
          .putIfAbsent(customer.id, () => [])
          .insert(0, payment);
      _applyCreditPaymentToSales(customer.id, paymentAmount);
    });
    await _persistWorkspaceData();

    if (_customerRepository != null) {
      await _customerRepository!.updateCustomer(_toDomainCustomer(customer));
      await _refreshPendingSyncQueue();
      await _triggerImmediateSync(
        action: 'UPDATE',
        module: 'customers',
        reference: customer.id,
      );
    } else {
      await _enqueueSync('UPDATE', 'customers', customer.id);
    }

    await _enqueueSync('INSERT', 'credit_payments', payment.id);
    final updatedCreditSales = _customerCreditSales[customer.id] ?? const [];
    for (final creditSale in updatedCreditSales) {
      await _enqueueSync('UPDATE', 'credit_sales', creditSale.id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment recorded: ${_money(paymentAmount)}')),
    );

    await PrintService.printCreditPaymentReceipt(
      customerName: customer.name,
      customerPhone: customer.phone,
      customerAddress: customer.address,
      paymentAmount: payment.amount,
      balanceBefore: payment.balanceBefore,
      balanceAfter: payment.balanceAfter,
      note: payment.note,
      settings: await _currentPrintSettings(),
      currencySymbol: _currency == 'LKR'
          ? 'Rs.'
          : _currency == 'USD'
          ? '\$'
          : _currency,
      storeName: _companyName,
      storeAddress: _companyAddress.trim().isEmpty
          ? _storeLocation
          : _companyAddress,
      storePhone: _companyPhone,
    );
  }

  Future<void> _showCustomerCreditHistory(_CustomerItem customer) async {
    final paymentItems = _customerCreditPayments[customer.id] ?? const [];
    final salesItems = _scopedCreditSales(customer.id);
    await showDialog<void>(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          title: Text('Credit History  -  ${customer.name}'),
          content: SizedBox(
            width: _adaptiveWidth(840, minWidth: 320),
            height: _adaptiveHeight(480, minHeight: 260),
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Payments'),
                    Tab(text: 'Sales'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      paymentItems.isEmpty
                          ? const Center(
                              child: Text('No credit payments recorded yet.'),
                            )
                          : ListView.separated(
                              itemCount: paymentItems.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = paymentItems[index];
                                return ListTile(
                                  title: Text(_money(item.amount)),
                                  subtitle: Text(
                                    '${item.createdAt.toLocal()}${item.note.isEmpty ? '' : '  -  ${item.note}'}',
                                  ),
                                  trailing: OutlinedButton(
                                    onPressed: () async {
                                      await PrintService.printCreditPaymentReceipt(
                                        customerName: customer.name,
                                        customerPhone: customer.phone,
                                        customerAddress: customer.address,
                                        paymentAmount: item.amount,
                                        balanceBefore: item.balanceBefore,
                                        balanceAfter: item.balanceAfter,
                                        note: item.note,
                                        settings: await _currentPrintSettings(),
                                        currencySymbol: _currency == 'LKR'
                                            ? 'Rs.'
                                            : _currency == 'USD'
                                            ? '\$'
                                            : _currency,
                                        storeName: _companyName,
                                        storeAddress:
                                            _companyAddress.trim().isEmpty
                                            ? _storeLocation
                                            : _companyAddress,
                                        storePhone: _companyPhone,
                                      );
                                    },
                                    child: const Text('Print Receipt'),
                                  ),
                                );
                              },
                            ),
                      salesItems.isEmpty
                          ? const Center(
                              child: Text('No credit sales recorded yet.'),
                            )
                          : ListView.separated(
                              itemCount: salesItems.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = salesItems[index];
                                return ExpansionTile(
                                  title: Text(
                                    '${item.invoiceNumber.isNotEmpty ? item.invoiceNumber : item.saleId}  -  Outstanding ${_money(item.outstandingAmount)}',
                                  ),
                                  subtitle: Text(
                                    '${item.createdAt.toLocal()}  -  Total ${_money(item.total)}  -  Paid ${_money(item.amountPaidOnSale)}',
                                  ),
                                  trailing: OutlinedButton(
                                    onPressed: () async {
                                      await _reprintCreditSaleInvoice(item);
                                    },
                                    child: const Text('Print Invoice'),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Phone: ${item.customerPhone}'),
                                          Text(
                                            'Address: ${item.customerAddress.isEmpty ? 'N/A' : item.customerAddress}',
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Purchased Items',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ...item.items.map(
                                            (line) => Text(' -  $line'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomerCreditSalesHistory(_CustomerItem customer) async {
    final items = _scopedCreditSales(customer.id);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Credit Sales  -  ${customer.name}'),
        content: SizedBox(
          width: _adaptiveWidth(680, minWidth: 300),
          height: _adaptiveHeight(420, minHeight: 260),
          child: items.isEmpty
              ? const Center(child: Text('No credit sales recorded yet.'))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ExpansionTile(
                      title: Text(
                        '${item.invoiceNumber.isNotEmpty ? item.invoiceNumber : item.saleId}  -  Outstanding ${_money(item.outstandingAmount)}',
                      ),
                      subtitle: Text(
                        '${item.createdAt.toLocal()}  -  Total ${_money(item.total)}  -  Paid ${_money(item.amountPaidOnSale)}',
                      ),
                      trailing: OutlinedButton(
                        onPressed: () async {
                          await _reprintCreditSaleInvoice(item);
                        },
                        child: const Text('Print Invoice'),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone: ${item.customerPhone}'),
                              Text(
                                'Address: ${item.customerAddress.isEmpty ? 'N/A' : item.customerAddress}',
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Purchased Items',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              ...item.items.map((line) => Text(' -  $line')),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  domain.Sale _saleRecordToDomainSale(
    _SaleRecord sale, {
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    double? customerOutstandingBefore,
    double? customerOutstandingAfter,
  }) {
    final tenantId = _activeTenantId ?? 'local';
    return domain.Sale(
      id: sale.id,
      tenantId: tenantId,
      customerId: sale.customerId.isEmpty ? null : sale.customerId,
      employeeId: sale.employeeId.isEmpty
          ? _currentEmployeeIdForSales
          : sale.employeeId,
      invoiceNumber: sale.invoiceNumber.isEmpty ? sale.id : sale.invoiceNumber,
      cashierName: sale.cashierName,
      customerOutstandingBefore:
          customerOutstandingBefore ?? sale.customerOutstandingBefore,
      customerOutstandingAfter:
          customerOutstandingAfter ?? sale.customerOutstandingAfter,
      total: sale.total,
      tax: sale.tax,
      discount: sale.discount,
      amountPaid: sale.amountPaid,
      balance: sale.balance,
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      locationId: sale.locationId,
      synced: false,
      createdAt: sale.createdAt,
      updatedAt: DateTime.now(),
      shippingAddress: sale.shippingAddress,
      shippingCharges: sale.shippingCharges,
      agentName: sale.agentName,
      agentCommission: sale.agentCommission,
      agentCommissionType: sale.agentCommissionType,
      agentCommissionPaid: sale.agentCommissionPaid,
      notes: sale.notes,
      deliveryPersonId: sale.deliveryPersonId,
      deliveryPersonName: sale.deliveryPersonName,
      deliveryStatus: sale.deliveryStatus,
      deliveredAt: sale.deliveredAt,
      items: sale.items
          .map(
            (line) => domain.SaleItem(
              id: '${sale.id}-${line.productId}',
              saleId: sale.id,
              productId: line.productId,
              productName: line.productName,
              quantity: line.quantity.toDouble(),
              unitPrice: line.unitPrice,
              originalPrice: line.quantity <= 0
                  ? line.unitPrice
                  : line.unitPrice + (line.discount / line.quantity),
              discount: line.discount,
              discountType: line.discountType,
              total: line.lineTotal,
              tenantId: tenantId,
            ),
          )
          .toList(),
      installmentSchedules: sale.installmentSchedules
          .map(
            (line) => domain.InstallmentPaymentLine(
              installmentNo: line.installmentNo,
              dueDate: line.dueDate,
              scheduledAmount: line.amount,
              paidAmount: line.paidAmount,
              remainingAmount: line.remainingAmount,
              isPaid: line.isPaid,
            ),
          )
          .toList(),
      customer: domain.Customer(
        id: sale.customerId,
        tenantId: tenantId,
        name: customerName,
        phone: customerPhone,
        address: customerAddress,
        creditLimit: 0,
        currentBalance: customerOutstandingAfter ?? 0.0,
        synced: true,
      ),
    );
  }

  Future<void> _reprintCreditSaleInvoice(_CreditSaleEntry creditSale) async {
    _SaleRecord? saleRecord;
    for (final sale in _sales) {
      if (sale.id == creditSale.saleId) {
        saleRecord = sale;
        break;
      }
    }

    if (saleRecord == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Original invoice was not found.')),
      );
      return;
    }

    await PrintService.printReceipt(
      sale: _saleRecordToDomainSale(
        saleRecord,
        customerName: creditSale.customerName,
        customerPhone: creditSale.customerPhone,
        customerAddress: creditSale.customerAddress,
        customerOutstandingBefore: creditSale.customerOutstandingBefore,
        customerOutstandingAfter: creditSale.customerOutstandingAfter,
      ),
      settings: await _currentPrintSettings(),
      currencySymbol: _currency == 'LKR'
          ? 'Rs.'
          : _currency == 'USD'
          ? '\$'
          : _currency,
      storeName: _companyName,
      storeAddress: _companyAddress.trim().isEmpty
          ? _storeLocation
          : _companyAddress,
      storePhone: _companyPhone,
    );
  }

  Future<void> _holdCurrentCart() async {
    if (_cart.isEmpty) return;

    final held = _HeldCart(
      id: 'HC${DateTime.now().millisecondsSinceEpoch}',
      customerId: _selectedCustomerId,
      paymentMethod: _paymentMethodController.text,
      amountPaidText: _amountPaidController.text,
      chequeNumber: _chequeNumberController.text,
      installmentCount: _posInstallmentCount,
      installmentIntervalDays: _posInstallmentIntervalDays,
      installmentDueDates: List<DateTime>.from(_posInstallmentDueDates),
      installmentAmounts: List<double>.from(_posInstallmentAmounts),
      applyTax: _posApplyTax,
      items: Map<String, double>.from(_cart),
      createdAt: DateTime.now(),
    );

    setState(() {
      _heldCarts.insert(0, held);
      _cart.clear();
      _paymentMethodController.text = 'CASH';
      _amountPaidController.clear();
      _chequeNumberController.clear();
      _posInstallmentCount = 3;
      _posInstallmentIntervalDays = 30;
      _resetPosInstallmentSchedule();
      _selectedCustomerId = null;
      _posCustomerSearchController.clear();
    });
    await _persistWorkspaceData();
  }

  Future<void> _resumeHeldCart() async {
    if (_heldCarts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No held carts available')));
      return;
    }

    final selected = await showDialog<_HeldCart>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Held Cart'),
        content: SizedBox(
          width: _adaptiveWidth(420, minWidth: 260),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _heldCarts.length,
            itemBuilder: (context, index) {
              final held = _heldCarts[index];
              final itemsCount = held.items.values.fold<double>(
                0,
                (s, q) => s + q,
              );
              return ListTile(
                title: Text('Cart ${held.id}'),
                subtitle: Text(
                  'Items: $itemsCount  -  ${held.createdAt.toLocal()}',
                ),
                onTap: () => Navigator.pop(context, held),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected == null) return;

    setState(() {
      _cart
        ..clear()
        ..addAll(selected.items);
      _selectedCustomerId = selected.customerId;
      if (_selectedCustomerId == null) {
        _posCustomerSearchController.clear();
      } else {
        final cust = _scopedCustomers.firstWhere(
          (c) => c.id == _selectedCustomerId,
          orElse: () => _CustomerItem(
            id: _selectedCustomerId!,
            name: 'Unknown Customer',
            locationId: _activeLocationForWrites,
            phone: '',
            email: '',
          ),
        );
        _posCustomerSearchController.text =
            '${cust.name} (${cust.phone.isEmpty ? 'N/A' : cust.phone})';
      }
      if (selected.paymentMethod != null &&
          selected.paymentMethod!.isNotEmpty) {
        _paymentMethodController.text = selected.paymentMethod!;
      }
      _amountPaidController.text = selected.amountPaidText ?? '';
      _chequeNumberController.text = selected.chequeNumber ?? '';
      _posInstallmentCount = selected.installmentCount ?? 3;
      _posInstallmentIntervalDays = selected.installmentIntervalDays ?? 30;
      _posInstallmentDueDates
        ..clear()
        ..addAll(selected.installmentDueDates ?? const <DateTime>[]);
      _posInstallmentAmounts
        ..clear()
        ..addAll(selected.installmentAmounts ?? const <double>[]);
      _posApplyTax = selected.applyTax ?? _posApplyTax;
      _heldCarts.removeWhere((x) => x.id == selected.id);
    });
    await _persistWorkspaceData();
  }

  Future<String?> _showReturnReasonDialog() async {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Reason'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageCategories() async {
    final created = await showGeneralDialog<_CategoryCreateResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddCategory',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        final nameController = TextEditingController();
        final attributes = <_CategoryAttributeDraft>[_CategoryAttributeDraft()];

        return StatefulBuilder(
          builder: (context, setLocal) {
            final dialogCompact =
                MediaQuery.of(context).size.width < UiBreakpoints.tablet;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final borderColor = isDark
                ? const Color(0xFF1E2D45)
                : const Color(0xFFE6E2EF);

            return _SideSheetContainer(
              title: 'Add New Category',
              width: 760,
              footer: Row(
                children: [
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final attributeDefs = <_CategoryAttributeDef>[];
                      for (final draft in attributes) {
                        final attributeName = draft.nameController.text.trim();
                        if (attributeName.isEmpty) continue;
                        final options = draft.type == 'select'
                            ? draft.optionsController.text
                                  .split(',')
                                  .map((option) => option.trim())
                                  .where((option) => option.isNotEmpty)
                                  .toList()
                            : <String>[];
                        attributeDefs.add(
                          _CategoryAttributeDef(
                            name: attributeName,
                            type: draft.type,
                            required: draft.required,
                            options: options,
                          ),
                        );
                      }
                      Navigator.pop(
                        context,
                        _CategoryCreateResult(
                          name: name,
                          attributes: attributeDefs,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                      ),
                    ),
                    child: const Text('Create Category'),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category Name *'),
                              const SizedBox(height: 6),
                              TextField(controller: nameController),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Category Attributes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setLocal(
                              () => attributes.add(_CategoryAttributeDraft()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandIndigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Attribute'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < attributes.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == attributes.length - 1 ? 0 : 14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (dialogCompact)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Attribute Name'),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller:
                                              attributes[i].nameController,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text('Attribute Type'),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          initialValue: attributes[i].type,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'text',
                                              child: Text('Text'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'num',
                                              child: Text('Number'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'boolean',
                                              child: Text('Boolean'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'select',
                                              child: Text('Select'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setLocal(
                                              () => attributes[i].type = value,
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: attributes[i].required,
                                              onChanged: (value) {
                                                setLocal(
                                                  () => attributes[i].required =
                                                      value ?? false,
                                                );
                                              },
                                            ),
                                            const Text('Required'),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: attributes.length == 1
                                                  ? null
                                                  : () {
                                                      setLocal(
                                                        () => attributes
                                                            .removeAt(i),
                                                      );
                                                    },
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Color(0xFFD14E4E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Attribute Name'),
                                              const SizedBox(height: 6),
                                              TextField(
                                                controller: attributes[i]
                                                    .nameController,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Attribute Type'),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<String>(
                                                initialValue:
                                                    attributes[i].type,
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'text',
                                                    child: Text('Text'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'num',
                                                    child: Text('Number'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'boolean',
                                                    child: Text('Boolean'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'select',
                                                    child: Text('Select'),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  setLocal(
                                                    () => attributes[i].type =
                                                        value,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 130,
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: attributes[i].required,
                                                onChanged: (value) {
                                                  setLocal(
                                                    () =>
                                                        attributes[i].required =
                                                            value ?? false,
                                                  );
                                                },
                                              ),
                                              const Text('Required'),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: attributes.length == 1
                                              ? null
                                              : () {
                                                  setLocal(
                                                    () =>
                                                        attributes.removeAt(i),
                                                  );
                                                },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Color(0xFFD14E4E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (attributes[i].type == 'select') ...[
                                    const SizedBox(height: 10),
                                    const Text('Options (comma-separated)'),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller:
                                          attributes[i].optionsController,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Option 1, Option 2, Option 3',
                                      ),
                                    ),
                                  ],
                                ],
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
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );

    if (created == null) return;
    final exists = _productCategories.any(
      (c) => c.toLowerCase() == created.name.toLowerCase(),
    );
    if (exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category already exists')));
      return;
    }

    setState(() {
      _productCategories = {..._productCategories, created.name}.toList();
      _categoryAttributes[created.name] = created.attributes;
      _posCategoryFilter = created.name;
    });
    await _persistWorkspaceData();
    await _enqueueSync('UPDATE', 'categories', created.name);
  }

  Future<int?> _showAdjustStockDialog(_ProductItem product) async {
    final controller = TextEditingController(text: product.stock.toString());
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock  -  ${product.name}'),
        content: SizedBox(
          width: _adaptiveWidth(360, minWidth: 260),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'New Stock Quantity',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 0) return;
              Navigator.pop(context, value);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaleDetails(_SaleRecord sale) async {
    final settings = await _currentPrintSettings();
    final domainSale = domain.Sale(
      id: sale.id,
      tenantId: _activeTenantId ?? 'local',
      customerId: sale.customerId.isEmpty ? null : sale.customerId,
      employeeId: sale.employeeId.isNotEmpty
          ? sale.employeeId
          : _currentEmployeeIdForSales,
      cashierName: sale.cashierName,
      customerOutstandingBefore: sale.customerOutstandingBefore,
      customerOutstandingAfter: sale.customerOutstandingAfter,
      total: sale.total,
      tax: sale.tax,
      discount: sale.discount,
      amountPaid: sale.amountPaid,
      balance: sale.balance,
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      locationId: sale.locationId,
      synced: true,
      createdAt: sale.createdAt,
      shippingCharges: sale.shippingCharges,
      agentName: sale.agentName,
      agentCommission: sale.agentCommission,
      agentCommissionType: sale.agentCommissionType,
      agentCommissionPaid: sale.agentCommissionPaid,
      installmentSchedules: sale.installmentSchedules
          .map(
            (line) => domain.InstallmentPaymentLine(
              installmentNo: line.installmentNo,
              dueDate: line.dueDate,
              scheduledAmount: line.amount,
              paidAmount: line.paidAmount,
              remainingAmount: line.remainingAmount,
              isPaid: line.isPaid,
            ),
          )
          .toList(),
      items: sale.items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;
        return domain.SaleItem(
          id: '${sale.id}-$index',
          saleId: sale.id,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          originalPrice: item.unitPrice + item.discount,
          discount: item.discount,
          discountType: item.discountType,
          total: item.lineTotal,
          tenantId: _activeTenantId ?? 'local',
        );
      }).toList(),
      customer: sale.customerName != 'Walk-in Customer'
          ? domain.Customer(
              id: sale.customerId,
              tenantId: _activeTenantId ?? 'local',
              name: sale.customerName,
              phone: sale.customerPhone,
              address: sale.customerAddress,
              creditLimit: 0,
              currentBalance: sale.customerOutstandingAfter,
              synced: true,
            )
          : null,
    );

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SaleDetails',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF111827)
                : Colors.white,
            child: SizedBox(
              width: _adaptiveWidth(600, minWidth: 400, horizontalPadding: 0),
              height: double.infinity,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE6E2EF),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Bill Preview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        primaryColor: const Color(0xFF1E88E5),
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: const Color(0xFF1E88E5),
                          secondary: const Color(0xFF1E88E5),
                        ),
                      ),
                      child: PdfPreview(
                        build: (format) => PrintService.generateReceiptPdf(
                          sale: domainSale,
                          settings: settings,
                          currencySymbol: _currency == 'LKR'
                              ? 'Rs.'
                              : _currency == 'USD'
                              ? '\$'
                              : _currency,
                          storeName: _companyName,
                          storeAddress: _companyAddress.trim().isEmpty
                              ? _storeLocation
                              : _companyAddress,
                          storePhone: _companyPhone,
                        ),
                        allowPrinting: true,
                        allowSharing: true,
                        canChangePageFormat: false,
                        canDebug: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  Future<void> _persistWorkspaceData() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'products': _products.map((e) => e.toJson()).toList(),
      'productCategories': _productCategories,
      'customers': _customers.map((e) => e.toJson()).toList(),
      'employees': _employees.map((e) => e.toJson()).toList(),
      'users': _users.map((e) => e.toJson()).toList(),
      'commissionRules': _commissionRules.map((e) => e.toJson()).toList(),
      'locations': _locations.map((e) => e.toJson()).toList(),
      'stockTransfers': _stockTransfers.map((e) => e.toJson()).toList(),
      'stockRequests': _stockRequests.map((e) => e.toJson()).toList(),
      'notifications': _notifications.map((e) => e.toJson()).toList(),
      'suppliers': _suppliers.map((e) => e.toJson()).toList(),
      'coupons': _coupons.map((e) => e.toJson()).toList(),
      'serviceJobs': _serviceJobs.map((e) => e.toJson()).toList(),
      'returns': _returns.map((e) => e.toJson()).toList(),
      'damagedInventory': _damagedInventory.map((e) => e.toJson()).toList(),
      'cashTransactions': _cashTransactions.map((e) => e.toJson()).toList(),
      'mobileReloads': _mobileReloads.map((e) => e.toJson()).toList(),
      'cashierSessions': _cashierSessions.map((e) => e.toJson()).toList(),
      'bankTransactions': _bankTransactions.map((e) => e.toJson()).toList(),
      'bankAccountBalance': _bankAccountBalance,
      'cashInHand': _cashInHand,
      'sales': _sales.map((e) => e.toJson()).toList(),
      'heldCarts': _heldCarts.map((e) => e.toJson()).toList(),
      'invoices': _invoices.map((e) => e.toJson()).toList(),
      'purchaseOrders': _purchaseOrders.map((e) => e.toJson()).toList(),
      'attendanceRecords': _attendanceRecords.map((e) => e.toJson()).toList(),
      'payrollRecords': _payrollRecords.map((e) => e.toJson()).toList(),
      'stockAdjustments': _stockAdjustments.map((e) => e.toJson()).toList(),
      'syncQueue': _syncQueue.map((e) => e.toJson()).toList(),
      'installmentPlans': _installmentPlans.map((e) => e.toJson()).toList(),
      'customerCreditPayments': _customerCreditPayments.map(
        (key, value) =>
            MapEntry(key, value.map((item) => item.toJson()).toList()),
      ),
      'customerCreditSales': _customerCreditSales.map(
        (key, value) =>
            MapEntry(key, value.map((item) => item.toJson()).toList()),
      ),
      'categoryAttributes': _categoryAttributes.map(
        (key, value) => MapEntry(
          key,
          value.map((attribute) => attribute.toJson()).toList(),
        ),
      ),
      'sidebarNavOrder': _sidebarNavOrder,
      'settings': {
        'companyName': _companyName,
        'invoicePattern': _invoicePattern,
        'invoicePrefix': _invoicePrefix,
        'invoiceIncludeLocation': _invoiceIncludeLocation,
        'invoiceLocationLength': _invoiceLocationLength,
        'invoiceIncludeUser': _invoiceIncludeUser,
        'invoiceUserLength': _invoiceUserLength,
        'invoiceIncludeDate': _invoiceIncludeDate,
        'taxRate': _taxRate,
        'currency': _currency,
        'storeLocation': _storeLocation,
        'selectedLocationScope': _selectedLocationScope,
        'receiptHeader': _receiptHeader,
        'receiptFooter': _receiptFooter,
        'receiptShowTax': _receiptShowTax,
        'receiptShowLogo': _receiptShowLogo,
        'receiptShowCompanyName': _receiptShowCompanyName,
        'receiptShowShopAddress': _receiptShowShopAddress,
        'receiptShowShopPhone': _receiptShowShopPhone,
        'receiptShowReceiptTitle': _receiptShowReceiptTitle,
        'receiptShowReceiptNumber': _receiptShowReceiptNumber,
        'receiptShowDate': _receiptShowDate,
        'receiptShowTime': _receiptShowTime,
        'receiptShowCashier': _receiptShowCashier,
        'receiptShowCustomer': _receiptShowCustomer,
        'receiptShowPaymentMethod': _receiptShowPaymentMethod,
        'receiptShowBalance': _receiptShowBalance,
        'receiptShowReturnPolicy': _receiptShowReturnPolicy,
        'allowReprintSalesBill': _allowReprintSalesBill,
        'enableWhatsappCodNotifications': _enableWhatsappCodNotifications,
        'receiptNote': _receiptNote,
        'openFrom': _openFrom,
        'openTo': _openTo,
        'acceptCash': _acceptCash,
        'acceptCard': _acceptCard,
        'acceptCheque': _acceptCheque,
        'acceptInstallment': _acceptInstallment,
        'integrationMode': _integrationMode,
        'integrationWebhook': _integrationWebhook,
        'notifyLowStock': _notifyLowStock,
        'notifyDailySummary': _notifyDailySummary,
        'notifyReturns': _notifyReturns,
        'cashDrawerEnabled': _cashDrawerEnabled,
        'cashDrawerRequirePin': _cashDrawerRequirePin,
        'cashDrawerPin': _cashDrawerPin,
        'receiptPaper': _receiptPaper,
        'receiptMargin': _receiptMargin,
        'receiptFontScale': _receiptFontScale,
        'profileName': _profileName,
        'profileEmail': _profileEmail,
        'profilePhone': _profilePhone,
        'companyEmail': _companyEmail,
        'companyPhone': _companyPhone,
        'companyAddress': _companyAddress,
        'companyRegNo': _companyRegNo,
        'companyLogoPath': _companyLogoPath,
        'uiTheme': _uiTheme,
        'uiLanguage': _uiLanguage,
        'prefSound': _prefSound,
        'prefAutoPrint': _prefAutoPrint,
        'prefCompact': _prefCompact,
        'prefRequireSaleConfirmation': _prefRequireSaleConfirmation,
        'enableShippingCharges': _enableShippingCharges,
        'enableCod': _enableCod,
        'defaultDeliveryFee': _defaultDeliveryFee,
        'enableAgentCommission': _enableAgentCommission,
        'mobileReloadEnabled': _mobileReloadEnabled,
        'enableMobileShopFeatures': _enableMobileShopFeatures,
        'operatorCommissions': _operatorCommissions,
        'agentCommissionLockToLogin': _agentCommissionLockToLogin,
        'notifyEmail': _notifyEmail,
        'notifySms': _notifySms,
        'notifyPayroll': _notifyPayroll,
        'payrollCycle': _payrollCycle,
        'payrollWorkingDays': _payrollWorkingDays,
        'payrollOtRate': _payrollOtRate,
        'payrollLatePenalty': _payrollLatePenalty,
        'payrollAutoGenerate': _payrollAutoGenerate,
        'payrollEnableEpf': _payrollEnableEpf,
        'lastSyncAt': _lastSyncAt?.toIso8601String(),
      },
    };

    await prefs.setString(_tenantWorkspaceStateKey, jsonEncode(payload));
  }

  Future<void> _loadPersistedWorkspaceData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tenantWorkspaceStateKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final productList = (decoded['products'] as List<dynamic>? ?? [])
          .map((e) => _ProductItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final categoryList =
          (decoded['productCategories'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList();
      final customerList = (decoded['customers'] as List<dynamic>? ?? [])
          .map((e) => _CustomerItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final employeeList = (decoded['employees'] as List<dynamic>? ?? [])
          .map((e) => _EmployeeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final userList = (decoded['users'] as List<dynamic>? ?? [])
          .map((e) => _UserItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final commissionRuleList =
          (decoded['commissionRules'] as List<dynamic>? ?? [])
              .map(
                (e) => commission.CommissionRule.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
      final locationList = (decoded['locations'] as List<dynamic>? ?? [])
          .map((e) => _LocationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final transferList = (decoded['stockTransfers'] as List<dynamic>? ?? [])
          .map((e) => _StockTransferItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final stockRequestList = (decoded['stockRequests'] as List<dynamic>? ?? [])
          .map((e) => _StockRequestItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final notificationList = (decoded['notifications'] as List<dynamic>? ?? [])
          .map((e) => _NotificationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final supplierList = (decoded['suppliers'] as List<dynamic>? ?? [])
          .map((e) => _SupplierItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final couponList = (decoded['coupons'] as List<dynamic>? ?? [])
          .map((e) => _CouponItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final serviceList = (decoded['serviceJobs'] as List<dynamic>? ?? [])
          .map((e) => _ServiceJobItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final returnsList = (decoded['returns'] as List<dynamic>? ?? [])
          .map((e) => _ReturnItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final damagedInventoryList =
          (decoded['damagedInventory'] as List<dynamic>? ?? [])
              .map(
                (e) => _DamagedInventoryItem.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
      final cashTransactionsList =
          (decoded['cashTransactions'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    _CashTransactionItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
      final cashierSessionsList =
          (decoded['cashierSessions'] as List<dynamic>? ?? [])
              .map(
                (e) => _CashierSession.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
      final bankTransactionsList =
          (decoded['bankTransactions'] as List<dynamic>? ?? [])
              .map(
                (e) => _BankTransaction.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
      double bankAccountBalanceVal =
          (decoded['bankAccountBalance'] as num?)?.toDouble() ?? 0.0;
      final totalBankDeposits = bankTransactionsList
          .where((t) => t.type.contains('DEPOSIT'))
          .fold<double>(0.0, (sum, t) => sum + t.amount);
      final totalBankWithdrawals = bankTransactionsList
          .where((t) => !t.type.contains('DEPOSIT'))
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      // If balance contains legacy 100,000 phantom default without matching deposits, remove the phantom baseline
      if (bankAccountBalanceVal >= 80000.0 && totalBankDeposits < 40000.0) {
        bankAccountBalanceVal = totalBankDeposits - totalBankWithdrawals;
      }
      final mobileReloadsList =
          (decoded['mobileReloads'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    _MobileReloadRecord.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
      final cashInHand = (decoded['cashInHand'] as num?)?.toDouble() ?? 0.0;
      final salesList = (decoded['sales'] as List<dynamic>? ?? [])
          .map((e) => _SaleRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final heldCartList = (decoded['heldCarts'] as List<dynamic>? ?? [])
          .map((e) => _HeldCart.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final invoiceList = (decoded['invoices'] as List<dynamic>? ?? [])
          .map((e) => _InvoiceItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final poList = (decoded['purchaseOrders'] as List<dynamic>? ?? [])
          .map((e) => _PurchaseOrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final attendanceList =
          (decoded['attendanceRecords'] as List<dynamic>? ?? [])
              .map(
                (e) => _AttendanceRecordItem.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
      final payrollList = (decoded['payrollRecords'] as List<dynamic>? ?? [])
          .map((e) => _PayrollRecordItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final stockAdjustmentList =
          (decoded['stockAdjustments'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    _StockAdjustmentItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
      final syncList = (decoded['syncQueue'] as List<dynamic>? ?? [])
          .map((e) => _SyncItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final installmentPlanList =
          (decoded['installmentPlans'] as List<dynamic>? ?? [])
              .map(
                (e) => _InstallmentPlan.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
      final creditPaymentsMap =
          (decoded['customerCreditPayments'] as Map<String, dynamic>? ?? {})
              .map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>)
                      .map(
                        (e) => _CreditPaymentItem.fromJson(
                          Map<String, dynamic>.from(e),
                        ),
                      )
                      .toList(),
                ),
              );
      final creditSalesMap =
          (decoded['customerCreditSales'] as Map<String, dynamic>? ?? {}).map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>)
                  .map(
                    (e) =>
                        _CreditSaleEntry.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList(),
            ),
          );
      final categoryAttributesMap =
          (decoded['categoryAttributes'] as Map<String, dynamic>? ?? {}).map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>)
                  .map(
                    (e) => _CategoryAttributeDef.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList(),
            ),
          );

      final settings = Map<String, dynamic>.from(decoded['settings'] ?? {});

      if (!mounted) return;
      setState(() {
        _products
          ..clear()
          ..addAll(productList);
        _productCategories = categoryList.isEmpty
            ? (_products.map((p) => p.category).toSet().toList()
                ..add('General'))
            : categoryList.toSet().toList();
        _customers
          ..clear()
          ..addAll(
            customerList.isEmpty
                ? [
                    _CustomerItem(
                      id: 'C001',
                      name: 'Walk-in Customer',
                      phone: 'N/A',
                      email: '',
                    ),
                  ]
                : customerList,
          );
        if (!_customers.any((c) => c.id == 'C001')) {
          _customers.add(
            _CustomerItem(
              id: 'C001',
              name: 'Walk-in Customer',
              phone: 'N/A',
              email: '',
            ),
          );
        }
        // Filter out legacy dummy accounts: 'Admin Owner', 'Owner User', 'owner@store.local', 'E001'
        final cleanedEmployees = employeeList.where((e) {
          final isDummy = e.id == 'E001' ||
              e.name.toLowerCase() == 'admin owner' ||
              e.name.toLowerCase() == 'owner user' ||
              e.email.toLowerCase() == 'owner@store.local';
          return !isDummy;
        }).toList();

        final cleanedUsers = userList.where((u) {
          final isDummy = u.id == 'U001' ||
              u.name.toLowerCase() == 'admin owner' ||
              u.name.toLowerCase() == 'owner user' ||
              u.email.toLowerCase() == 'owner@store.local';
          return !isDummy;
        }).toList();

        // Synchronize the single real Owner account using registration details
        if (widget.user.role.toUpperCase() == 'OWNER') {
          final ownerName = widget.user.name.trim().isNotEmpty
              ? widget.user.name.trim()
              : 'Owner';
          final ownerEmail = widget.user.email.trim();
          final ownerId = widget.user.id.isNotEmpty ? widget.user.id : 'USER_OWNER';

          // Ensure exactly one owner in _users
          cleanedUsers.removeWhere((u) => u.role.toUpperCase() == 'OWNER');
          cleanedUsers.insert(
            0,
            _UserItem(
              id: ownerId,
              name: ownerName,
              email: ownerEmail,
              role: 'OWNER',
              active: true,
              permissions:
                  _userPermissionOptions.map((o) => o.viewPermission).toList(),
            ),
          );

          // Ensure exactly one owner in _employees
          cleanedEmployees.removeWhere((e) => e.role.toUpperCase() == 'OWNER');
          cleanedEmployees.insert(
            0,
            _EmployeeItem(
              id: 'EMP_$ownerId',
              name: ownerName,
              email: ownerEmail,
              role: 'OWNER',
              position: 'OWNER',
              active: true,
            ),
          );

          _profileName = ownerName;
          if (ownerEmail.isNotEmpty) {
            _profileEmail = ownerEmail;
          }
        }

        _employees
          ..clear()
          ..addAll(cleanedEmployees);
        _users
          ..clear()
          ..addAll(cleanedUsers);
        _commissionRules
          ..clear()
          ..addAll(commissionRuleList);
        _locations
          ..clear()
          ..addAll(
            locationList.isEmpty
                ? [
                    _LocationItem(
                      id: 'LOC_MAIN',
                      name: 'Main Branch',
                      code: 'MAIN',
                      isActive: true,
                      isHeadquarters: true,
                      openingTime: '09:00 AM',
                      closingTime: '06:00 PM',
                    ),
                  ]
                : locationList,
          );
        _stockTransfers
          ..clear()
          ..addAll(transferList);
        _stockRequests
          ..clear()
          ..addAll(stockRequestList);
        _notifications
          ..clear()
          ..addAll(notificationList);
        _suppliers
          ..clear()
          ..addAll(supplierList);
        _coupons
          ..clear()
          ..addAll(couponList);
        _serviceJobs
          ..clear()
          ..addAll(serviceList);
        _returns
          ..clear()
          ..addAll(returnsList);
        _damagedInventory
          ..clear()
          ..addAll(damagedInventoryList);
        _cashTransactions
          ..clear()
          ..addAll(cashTransactionsList);
        _mobileReloads
          ..clear()
          ..addAll(mobileReloadsList);
        _cashierSessions
          ..clear()
          ..addAll(cashierSessionsList);
        _bankTransactions
          ..clear()
          ..addAll(bankTransactionsList);
        _bankAccountBalance = bankAccountBalanceVal;
        _sales
          ..clear()
          ..addAll(salesList)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _heldCarts
          ..clear()
          ..addAll(heldCartList);
        _invoices
          ..clear()
          ..addAll(invoiceList);
        _purchaseOrders
          ..clear()
          ..addAll(poList);
        _attendanceRecords
          ..clear()
          ..addAll(attendanceList);
        _payrollRecords
          ..clear()
          ..addAll(payrollList);
        _stockAdjustments
          ..clear()
          ..addAll(stockAdjustmentList);
        _syncQueue
          ..clear()
          ..addAll(syncList);
        _installmentPlans
          ..clear()
          ..addAll(installmentPlanList);
        _customerCreditPayments
          ..clear()
          ..addAll(creditPaymentsMap);
        _customerCreditSales
          ..clear()
          ..addAll(creditSalesMap);
        _categoryAttributes = Map<String, List<_CategoryAttributeDef>>.from(
          categoryAttributesMap,
        );

        _companyName = settings['companyName'] ?? _companyName;
        _invoicePattern = settings['invoicePattern'] ?? _invoicePattern;
        _invoicePrefix = settings['invoicePrefix'] ?? _invoicePrefix;
        _invoiceIncludeLocation =
            settings['invoiceIncludeLocation'] ?? _invoiceIncludeLocation;
        _invoiceLocationLength =
            settings['invoiceLocationLength'] ?? _invoiceLocationLength;
        _invoiceIncludeUser =
            settings['invoiceIncludeUser'] ?? _invoiceIncludeUser;
        _invoiceUserLength =
            settings['invoiceUserLength'] ?? _invoiceUserLength;
        _invoiceIncludeDate =
            settings['invoiceIncludeDate'] ?? _invoiceIncludeDate;
        _taxRate = settings['taxRate'] ?? _taxRate;
        _currency = settings['currency'] ?? _currency;
        _storeLocation = settings['storeLocation'] ?? _storeLocation;
        _selectedLocationScope =
            settings['selectedLocationScope'] ?? _selectedLocationScope;
        // Always ensure the primary store location exists in _locations list.
        // It may be absent on a fresh device that received only added locations via sync.
        final primaryName = _storeLocation.trim().isEmpty
            ? 'Main Branch'
            : _storeLocation.trim();
        if (!_locations.any((loc) => loc.name.trim() == primaryName)) {
          _locations.insert(
            0,
            _LocationItem(
              id: 'LOC_MAIN',
              name: primaryName,
              code: 'MAIN',
              isActive: true,
              isHeadquarters: true,
              openingTime: '09:00 AM',
              closingTime: '06:00 PM',
            ),
          );
        }
        final knownLocationNames = _locations
            .map((item) => item.name.trim())
            .where((item) => item.isNotEmpty)
            .toSet();
        if (_selectedLocationScope != _allLocationsLabel &&
            !knownLocationNames.contains(_selectedLocationScope)) {
          _selectedLocationScope = _storeLocation;
        }
        _receiptHeader = settings['receiptHeader'] ?? _receiptHeader;
        _receiptFooter = settings['receiptFooter'] ?? _receiptFooter;
        _receiptShowTax = settings['receiptShowTax'] ?? _receiptShowTax;
        _receiptShowLogo = settings['receiptShowLogo'] ?? _receiptShowLogo;
        _receiptShowCompanyName =
            settings['receiptShowCompanyName'] ?? _receiptShowCompanyName;
        _receiptShowShopAddress =
            settings['receiptShowShopAddress'] ?? _receiptShowShopAddress;
        _receiptShowShopPhone =
            settings['receiptShowShopPhone'] ?? _receiptShowShopPhone;
        _receiptShowReceiptTitle =
            settings['receiptShowReceiptTitle'] ?? _receiptShowReceiptTitle;
        _receiptShowReceiptNumber =
            settings['receiptShowReceiptNumber'] ?? _receiptShowReceiptNumber;
        _receiptShowDate = settings['receiptShowDate'] ?? _receiptShowDate;
        _receiptShowTime = settings['receiptShowTime'] ?? _receiptShowTime;
        _receiptShowCashier =
            settings['receiptShowCashier'] ?? _receiptShowCashier;
        _receiptShowCustomer =
            settings['receiptShowCustomer'] ?? _receiptShowCustomer;
        _receiptShowPaymentMethod =
            settings['receiptShowPaymentMethod'] ?? _receiptShowPaymentMethod;
        _receiptShowBalance =
            settings['receiptShowBalance'] ?? _receiptShowBalance;
        _receiptShowReturnPolicy =
            settings['receiptShowReturnPolicy'] ?? _receiptShowReturnPolicy;
        _allowReprintSalesBill =
            settings['allowReprintSalesBill'] ?? _allowReprintSalesBill;
        _enableWhatsappCodNotifications =
            settings['enableWhatsappCodNotifications'] ?? _enableWhatsappCodNotifications;
        _receiptNote = settings['receiptNote'] ?? _receiptNote;
        _openFrom = settings['openFrom'] ?? _openFrom;
        _openTo = settings['openTo'] ?? _openTo;
        _acceptCash = settings['acceptCash'] ?? _acceptCash;
        _acceptCard = settings['acceptCard'] ?? _acceptCard;
        _acceptCheque = settings['acceptCheque'] ?? _acceptCheque;
        _acceptInstallment =
            settings['acceptInstallment'] ?? _acceptInstallment;
        _integrationMode = settings['integrationMode'] ?? _integrationMode;
        _integrationWebhook =
            settings['integrationWebhook'] ?? _integrationWebhook;
        _notifyLowStock = settings['notifyLowStock'] ?? _notifyLowStock;
        _notifyDailySummary =
            settings['notifyDailySummary'] ?? _notifyDailySummary;
        _notifyReturns = settings['notifyReturns'] ?? _notifyReturns;
        _cashDrawerEnabled =
            settings['cashDrawerEnabled'] ?? _cashDrawerEnabled;
        _cashDrawerRequirePin =
            settings['cashDrawerRequirePin'] ?? _cashDrawerRequirePin;
        _cashDrawerPin = settings['cashDrawerPin'] ?? _cashDrawerPin;
        _receiptPaper = settings['receiptPaper'] ?? _receiptPaper;
        _receiptMargin = settings['receiptMargin'] ?? _receiptMargin;
        _receiptFontScale = settings['receiptFontScale'] ?? _receiptFontScale;
        final loadedProfName = (settings['profileName'] ?? '').toString().trim();
        if (loadedProfName.isNotEmpty &&
            loadedProfName.toLowerCase() != 'admin owner' &&
            loadedProfName.toLowerCase() != 'owner') {
          _profileName = loadedProfName;
        } else {
          _profileName = widget.user.name.trim().isNotEmpty ? widget.user.name.trim() : 'Owner';
        }

        final loadedProfEmail = (settings['profileEmail'] ?? '').toString().trim();
        if (loadedProfEmail.isNotEmpty &&
            loadedProfEmail.toLowerCase() != 'owner@store.local') {
          _profileEmail = loadedProfEmail;
        } else {
          _profileEmail = widget.user.email.trim();
        }

        final loadedProfPhone = (settings['profilePhone'] ?? '').toString().trim();
        if (loadedProfPhone.isNotEmpty && loadedProfPhone != '+94 77 123 4567') {
          _profilePhone = loadedProfPhone;
        } else {
          _profilePhone = '';
        }

        final loadedCompEmail = (settings['companyEmail'] ?? '').toString().trim();
        if (loadedCompEmail.isNotEmpty && loadedCompEmail.toLowerCase() != 'hello@storebuddy.local') {
          _companyEmail = loadedCompEmail;
        } else {
          _companyEmail = widget.user.email.trim();
        }

        final loadedCompPhone = (settings['companyPhone'] ?? '').toString().trim();
        if (loadedCompPhone.isNotEmpty && loadedCompPhone != '+94 11 555 0101') {
          _companyPhone = loadedCompPhone;
        } else {
          _companyPhone = '';
        }

        final loadedCompAddress = (settings['companyAddress'] ?? '').toString().trim();
        if (loadedCompAddress.isNotEmpty && loadedCompAddress.toLowerCase() != 'no. 12, main street, colombo') {
          _companyAddress = loadedCompAddress;
        } else {
          _companyAddress = '';
        }

        final loadedCompReg = (settings['companyRegNo'] ?? '').toString().trim();
        if (loadedCompReg.isNotEmpty && loadedCompReg.toUpperCase() != 'BR-54820') {
          _companyRegNo = loadedCompReg;
        } else {
          _companyRegNo = '';
        }

        final trialProfileJson = prefs.getString('trial_claim_profile');
        if (trialProfileJson != null && trialProfileJson.isNotEmpty) {
          try {
            final tMap = jsonDecode(trialProfileJson) as Map<String, dynamic>;
            if (_profilePhone.isEmpty && tMap['business_phone'] != null) {
              _profilePhone = tMap['business_phone'].toString();
            }
            if (_companyAddress.isEmpty && tMap['street_address'] != null) {
              _companyAddress = tMap['street_address'].toString();
            }
            if ((_companyName.isEmpty || _companyName == 'Store Buddy Shop') && tMap['store_name'] != null) {
              _companyName = tMap['store_name'].toString();
            }
            if (_companyPhone.isEmpty && tMap['business_phone'] != null) {
              _companyPhone = tMap['business_phone'].toString();
            }
          } catch (_) {}
        }

        _companyLogoPath = settings['companyLogoPath'] ?? _companyLogoPath;
        _uiTheme = settings['uiTheme'] ?? _uiTheme;
        _uiLanguage = settings['uiLanguage'] ?? _uiLanguage;
        _prefSound = settings['prefSound'] ?? _prefSound;
        _prefAutoPrint = settings['prefAutoPrint'] ?? _prefAutoPrint;
        _prefCompact = settings['prefCompact'] ?? _prefCompact;
        _prefRequireSaleConfirmation =
            settings['prefRequireSaleConfirmation'] ??
            _prefRequireSaleConfirmation;
        _enableShippingCharges =
            settings['enableShippingCharges'] ?? _enableShippingCharges;
        _enableCod = settings['enableCod'] ?? _enableCod;
        _defaultDeliveryFee =
            (settings['defaultDeliveryFee'] as num?)?.toDouble() ??
            _defaultDeliveryFee;
        _enableAgentCommission =
            settings['enableAgentCommission'] ?? _enableAgentCommission;
        _mobileReloadEnabled =
            settings['mobileReloadEnabled'] ?? _mobileReloadEnabled;
        _enableMobileShopFeatures =
            settings['enableMobileShopFeatures'] ?? _enableMobileShopFeatures;
        if (settings['operatorCommissions'] != null) {
          final rawCommissions = Map<String, dynamic>.from(
            settings['operatorCommissions'],
          );
          _operatorCommissions = rawCommissions.map((key, val) {
            final list = List<dynamic>.from(val);
            return MapEntry(
              key,
              list.map((item) => Map<String, dynamic>.from(item)).toList(),
            );
          });
        }
        _agentCommissionLockToLogin =
            settings['agentCommissionLockToLogin'] ??
            _agentCommissionLockToLogin;
        _notifyEmail = settings['notifyEmail'] ?? _notifyEmail;
        _notifySms = settings['notifySms'] ?? _notifySms;
        _notifyPayroll = settings['notifyPayroll'] ?? _notifyPayroll;
        _payrollCycle = settings['payrollCycle'] ?? _payrollCycle;
        _payrollWorkingDays =
            settings['payrollWorkingDays'] ?? _payrollWorkingDays;
        _payrollOtRate = settings['payrollOtRate'] ?? _payrollOtRate;
        _payrollLatePenalty =
            settings['payrollLatePenalty'] ?? _payrollLatePenalty;
        _payrollAutoGenerate =
            settings['payrollAutoGenerate'] ?? _payrollAutoGenerate;
        _payrollEnableEpf = settings['payrollEnableEpf'] ?? _payrollEnableEpf;
        final sidebarOrder =
            (decoded['sidebarNavOrder'] as List<dynamic>? ?? [])
                .map((value) => value.toString())
                .where((value) => value.trim().isNotEmpty)
                .toList();
        if (sidebarOrder.isNotEmpty) {
          final allowedKeys = _defaultSidebarNavOrder.toSet();
          _sidebarNavOrder = sidebarOrder.where(allowedKeys.contains).toList();
        } else {
          _sidebarNavOrder = List<String>.from(_defaultSidebarNavOrder);
        }
        _lastSyncAt = settings['lastSyncAt'] != null
            ? DateTime.tryParse(settings['lastSyncAt'])
            : null;
        if (!_settingsTabs.any((tab) => tab.key == _settingsTab)) {
          _settingsTab = 'general';
        }
        _selectedCustomerId = null;
        _posInstallmentIntervalDays = 30;
        _resetPosInstallmentSchedule();
        _posNotesController.clear();
      });
      await _applyUiTheme(_uiTheme, persist: false);
      _notifyExpiryReminders();
    } catch (_) {
      return;
    }
  }

  Future<void> _printReceipt({
    required _SaleRecord sale,
    required List<_CartLine> lines,
  }) async {
    final settings = await _currentPrintSettings();

    final domainSale = domain.Sale(
      id: sale.id,
      tenantId: _activeTenantId ?? 'local',
      customerId: sale.customerId.isEmpty ? null : sale.customerId,
      employeeId: sale.employeeId.isNotEmpty
          ? sale.employeeId
          : _currentEmployeeIdForSales,
      invoiceNumber: sale.invoiceNumber.isEmpty ? sale.id : sale.invoiceNumber,
      cashierName: sale.cashierName,
      customerOutstandingBefore: sale.customerOutstandingBefore,
      customerOutstandingAfter: sale.customerOutstandingAfter,
      total: sale.total,
      tax: sale.tax,
      discount: sale.discount,
      amountPaid: sale.amountPaid,
      balance: sale.balance,
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      locationId: sale.locationId,
      synced: true,
      createdAt: sale.createdAt,
      shippingCharges: sale.shippingCharges,
      agentName: sale.agentName,
      agentCommission: sale.agentCommission,
      agentCommissionType: sale.agentCommissionType,
      agentCommissionPaid: sale.agentCommissionPaid,
      notes: sale.notes,
      shippingAddress: sale.shippingAddress,
      installmentSchedules: sale.installmentSchedules
          .map(
            (line) => domain.InstallmentPaymentLine(
              installmentNo: line.installmentNo,
              dueDate: line.dueDate,
              scheduledAmount: line.amount,
              paidAmount: line.paidAmount,
              remainingAmount: line.remainingAmount,
              isPaid: line.isPaid,
            ),
          )
          .toList(),
      items: lines.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final line = entry.value;
        return domain.SaleItem(
          id: '${sale.id}-$index',
          saleId: sale.id,
          productId: line.product.id,
          productName: line.product.name,
          quantity: line.qty.toDouble(),
          unitPrice: line.unitPriceAfterDiscount,
          originalPrice: line.product.price,
          discount: line.discountLineTotal,
          discountType: line.discountType,
          total: line.totalPrice,
          tenantId: _activeTenantId ?? 'local',
        );
      }).toList(),
      customer: sale.customerName != 'Walk-in Customer'
          ? domain.Customer(
              id: '',
              tenantId: _activeTenantId ?? 'local',
              name: sale.customerName,
              phone: sale.customerPhone,
              address: sale.customerAddress,
              creditLimit: 0,
              currentBalance: sale.customerOutstandingAfter,
              synced: true,
            )
          : null,
    );

    await PrintService.printReceipt(
      sale: domainSale,
      settings: settings,
      currencySymbol: _currency == 'LKR'
          ? 'Rs.'
          : _currency == 'USD'
          ? '\$'
          : _currency,
      storeName: _companyName,
      storeAddress: _companyAddress.trim().isEmpty
          ? _storeLocation
          : _companyAddress,
      storePhone: _companyPhone,
    );
  }

  Future<void> _maybeOpenCashDrawer({required String paymentMethod}) async {
    if (!_localCashDrawerEnabled) return;
    final isCash = paymentMethod.toUpperCase().contains('CASH');
    if (!isCash && paymentMethod != 'COD') {
      return;
    }
    try {
      await PrintService.kickCashDrawer(
        printerName: _localCashDrawerPrinterName ?? _localReceiptPrinterName,
        method: _localCashDrawerMethod,
        pin: _localCashDrawerPulsePin,
        onMs: _localCashDrawerPulseOnMs,
        offMs: _localCashDrawerPulseOffMs,
        networkIp: _localCashDrawerNetworkIp,
        networkPort: _localCashDrawerNetworkPort,
      );
    } catch (_) {}
  }

  Future<void> _printDeliveryNote(_SaleRecord sale) async {
    final settings = await _currentPrintSettings();
    final domainSale = domain.Sale(
      id: sale.id,
      tenantId: _activeTenantId ?? 'local',
      customerId: sale.customerId.isEmpty ? null : sale.customerId,
      employeeId: sale.employeeId.isNotEmpty
          ? sale.employeeId
          : _currentEmployeeIdForSales,
      invoiceNumber: sale.invoiceNumber.isEmpty ? sale.id : sale.invoiceNumber,
      cashierName: sale.cashierName,
      customerOutstandingBefore: sale.customerOutstandingBefore,
      customerOutstandingAfter: sale.customerOutstandingAfter,
      total: sale.total,
      tax: sale.tax,
      discount: sale.discount,
      amountPaid: sale.amountPaid,
      balance: sale.balance,
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      locationId: sale.locationId,
      synced: true,
      createdAt: sale.createdAt,
      shippingCharges: sale.shippingCharges,
      agentName: sale.agentName,
      agentCommission: sale.agentCommission,
      agentCommissionType: sale.agentCommissionType,
      agentCommissionPaid: sale.agentCommissionPaid,
      notes: sale.notes,
      shippingAddress: sale.shippingAddress,
      deliveryPersonId: sale.deliveryPersonId,
      deliveryPersonName: sale.deliveryPersonName,
      deliveryStatus: sale.deliveryStatus,
      installmentSchedules: sale.installmentSchedules
          .map(
            (line) => domain.InstallmentPaymentLine(
              installmentNo: line.installmentNo,
              dueDate: line.dueDate,
              scheduledAmount: line.amount,
              paidAmount: line.paidAmount,
              remainingAmount: line.remainingAmount,
              isPaid: line.isPaid,
            ),
          )
          .toList(),
      items: sale.items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;
        return domain.SaleItem(
          id: '${sale.id}-$index',
          saleId: sale.id,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          originalPrice: item.unitPrice + item.discount,
          discount: item.discount,
          discountType: item.discountType,
          total: item.lineTotal,
          tenantId: _activeTenantId ?? 'local',
        );
      }).toList(),
      customer: domain.Customer(
        id: sale.customerId.isNotEmpty ? sale.customerId : 'C001',
        tenantId: _activeTenantId ?? 'local',
        name: sale.customerName.isNotEmpty ? sale.customerName : 'Walk-in Customer',
        phone: sale.customerPhone,
        address: sale.shippingAddress.isNotEmpty ? sale.shippingAddress : sale.customerAddress,
        creditLimit: 0,
        currentBalance: sale.customerOutstandingAfter,
        synced: true,
      ),
    );

    final currencySymbol = _currency == 'LKR'
        ? 'Rs.'
        : _currency == 'USD'
        ? '\$'
        : _currency;
    final storeAddress = _companyAddress.trim().isEmpty
        ? _storeLocation
        : _companyAddress;

    if (!mounted) return;

    final configuredPrinter = settings.deliveryNotePrinterName?.isNotEmpty == true
        ? settings.deliveryNotePrinterName!
        : (settings.printerName?.isNotEmpty == true ? settings.printerName! : 'Counter Receipt Printer');
    String selectedFormat = settings.deliveryNoteFormat;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryColor = Theme.of(context).primaryColor;

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text('Delivery Note (COD)'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoice: ${sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : sale.id}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'COD ORDER',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Deliver To: ${sale.customerName.isNotEmpty ? sale.customerName : "Walk-in Customer"}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Collect: $currencySymbol ${sale.total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.print_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Printer: $configuredPrinter (Set in Settings)',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Paper Format:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => selectedFormat = 'THERMAL_80MM'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedFormat == 'THERMAL_80MM'
                                  ? primaryColor.withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedFormat == 'THERMAL_80MM' ? primaryColor : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long, size: 22, color: selectedFormat == 'THERMAL_80MM' ? primaryColor : Colors.grey),
                                const SizedBox(height: 4),
                                const Text('Thermal 80mm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                const Text('(Roll)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => selectedFormat = 'THERMAL_58MM'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedFormat == 'THERMAL_58MM'
                                  ? primaryColor.withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedFormat == 'THERMAL_58MM' ? primaryColor : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.receipt, size: 22, color: selectedFormat == 'THERMAL_58MM' ? primaryColor : Colors.grey),
                                const SizedBox(height: 4),
                                const Text('Thermal 58mm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                const Text('(Narrow)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => selectedFormat = 'A4'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: selectedFormat == 'A4'
                                  ? primaryColor.withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedFormat == 'A4' ? primaryColor : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.description_outlined, size: 22, color: selectedFormat == 'A4' ? primaryColor : Colors.grey),
                                const SizedBox(height: 4),
                                const Text('A4 Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                const Text('(Sheet)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    final pdfBytes = await PrintService.generateDeliveryNotePdf(
                      sale: domainSale,
                      settings: settings,
                      currencySymbol: currencySymbol,
                      storeName: _companyName,
                      storeAddress: storeAddress,
                      storePhone: _companyPhone,
                      formatOverride: selectedFormat,
                    );
                    final tempDir = Directory.systemTemp;
                    final tempFile = File(
                      '${tempDir.path}/DeliveryNote_${sale.id}.pdf',
                    );
                    await tempFile.writeAsBytes(pdfBytes);

                    final escapedPath = tempFile.path.replaceAll("'", "''");
                    await Process.run('powershell.exe', [
                      '-Command',
                      'Set-Clipboard -Path \'$escapedPath\'',
                    ]);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Delivery Note PDF copied to clipboard! Paste (Ctrl+V) directly into WhatsApp.',
                        ),
                      ),
                    );

                    await Process.run('cmd.exe', [
                      '/c',
                      'start',
                      '',
                      'https://api.whatsapp.com/send',
                    ]);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to share Delivery Note PDF: $e'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.share_outlined, color: Colors.green),
                label: const Text('WhatsApp Share'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final pdfBytes = await PrintService.generateDeliveryNotePdf(
                    sale: domainSale,
                    settings: settings,
                    currencySymbol: currencySymbol,
                    storeName: _companyName,
                    storeAddress: storeAddress,
                    storePhone: _companyPhone,
                    formatOverride: selectedFormat,
                  );
                  await Printing.layoutPdf(
                    onLayout: (fmt) async => pdfBytes,
                    name: 'DeliveryNote_${sale.id}',
                  );
                },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Preview / OS Dialog'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  await PrintService.printDeliveryNote(
                    sale: domainSale,
                    settings: settings,
                    currencySymbol: currencySymbol,
                    storeName: _companyName,
                    storeAddress: storeAddress,
                    storePhone: _companyPhone,
                    formatOverride: selectedFormat,
                  );
                },
                icon: const Icon(Icons.print_rounded),
                label: const Text('Print Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cancelSaleInvoice(_SaleRecord sale) async {
    if (sale.status == 'CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This sale is already cancelled.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: Text(
          'Are you sure you want to cancel invoice ${sale.id}? This will revert product stock levels and outstanding customer balances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final stockAuditEntries = <_StockAdjustmentItem>[];
    for (final item in sale.items) {
      if (!item.productId.startsWith('SV:')) {
        final productIndex = _products.indexWhere(
          (p) => p.id == item.productId,
        );
        if (productIndex >= 0) {
          final product = _products[productIndex];
          final beforeStock = product.stock;
          final afterStock = beforeStock + item.quantity;
          product.stock = afterStock;

          final audit = _StockAdjustmentItem(
            id: 'SA${DateTime.now().microsecondsSinceEpoch}-${product.id}',
            productId: product.id,
            productName: product.name,
            delta: item.quantity,
            beforeStock: beforeStock,
            afterStock: afterStock,
            reason: 'Sale ${sale.id} cancelled',
            performedBy: _currentUserName,
            unitCost: product.costPrice,
            adjustedStockValue: product.costPrice == null
                ? null
                : afterStock * product.costPrice!,
            createdAt: DateTime.now(),
          );
          stockAuditEntries.add(audit);

          // Update database for product
          if (_productRepository != null) {
            await _productRepository!.updateProduct(_toDomainProduct(product));
          }
          await _enqueueSync('UPDATE', 'products', product.id);
        }
      }
    }

    // Adjust customer outstanding balance if payment method was credit or installment
    if ((sale.paymentMethod == 'CREDIT' ||
            sale.paymentMethod == 'INSTALLMENT') &&
        sale.customerId.isNotEmpty) {
      final custIndex = _customers.indexWhere((c) => c.id == sale.customerId);
      if (custIndex >= 0) {
        final customer = _customers[custIndex];
        final outstandingAmount = sale.total - sale.amountPaid;
        if (outstandingAmount > 0) {
          customer.currentBalance =
              (customer.currentBalance - outstandingAmount).clamp(
                0.0,
                double.infinity,
              );
          if (_customerRepository != null) {
            await _customerRepository!.updateCustomer(
              _toDomainCustomer(customer),
            );
          }
          await _enqueueSync('UPDATE', 'customers', customer.id);
        }
      }
    }

    // Cancel linked installment plans
    final plansToCancel = _installmentPlans
        .where((plan) => plan.saleId == sale.id)
        .toList();
    for (final plan in plansToCancel) {
      await _enqueueSync('DELETE', 'installments', plan.id);
    }
    _installmentPlans.removeWhere((plan) => plan.saleId == sale.id);

    // Cancel linked credit entries
    final creditSales = _customerCreditSales[sale.customerId];
    if (creditSales != null) {
      final entriesToCancel = creditSales
          .where((entry) => entry.saleId == sale.id)
          .toList();
      for (final entry in entriesToCancel) {
        await _enqueueSync('DELETE', 'credit_sales', entry.id);
      }
      creditSales.removeWhere((entry) => entry.saleId == sale.id);
    }

    setState(() {
      sale.status = 'CANCELLED';
      _stockAdjustments.insertAll(0, stockAuditEntries);
    });

    if (_saleRepository != null) {
      await _saleRepository!.updateSaleStatus(
        saleId: sale.id,
        status: 'CANCELLED',
      );
    } else {
      await _enqueueSync('UPDATE', 'sales', sale.id);
    }

    for (final audit in stockAuditEntries) {
      await _enqueueSync('INSERT', 'stock_adjustments', audit.id);
    }

    await _persistWorkspaceData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice ${sale.id} cancelled successfully.')),
      );
    }
  }

  domain.Sale _saleRecordToPreviewDomainSale(
    _SaleRecord sale,
    List<_CartLine> lines, {
    required _CustomerItem customer,
  }) {
    final tenantId = _activeTenantId ?? 'local';
    return domain.Sale(
      id: sale.id,
      tenantId: tenantId,
      customerId: customer.id == 'C001' ? null : customer.id,
      employeeId: sale.employeeId.isNotEmpty
          ? sale.employeeId
          : _currentEmployeeIdForSales,
      invoiceNumber: sale.invoiceNumber.isEmpty ? sale.id : sale.invoiceNumber,
      cashierName: sale.cashierName,
      customerOutstandingBefore: sale.customerOutstandingBefore,
      customerOutstandingAfter: sale.customerOutstandingAfter,
      total: sale.total,
      tax: sale.tax,
      discount: sale.discount,
      amountPaid: sale.amountPaid,
      balance: sale.balance,
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      locationId: sale.locationId,
      synced: true,
      createdAt: sale.createdAt,
      shippingCharges: sale.shippingCharges,
      agentName: sale.agentName,
      agentCommission: sale.agentCommission,
      agentCommissionType: sale.agentCommissionType,
      agentCommissionPaid: sale.agentCommissionPaid,
      notes: sale.notes,
      shippingAddress: sale.shippingAddress,
      installmentSchedules: sale.installmentSchedules
          .map(
            (line) => domain.InstallmentPaymentLine(
              installmentNo: line.installmentNo,
              dueDate: line.dueDate,
              scheduledAmount: line.amount,
              paidAmount: line.paidAmount,
              remainingAmount: line.remainingAmount,
              isPaid: line.isPaid,
            ),
          )
          .toList(),
      items: lines.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final line = entry.value;
        return domain.SaleItem(
          id: '${sale.id}-$index',
          saleId: sale.id,
          productId: line.product.id,
          productName: line.product.name,
          quantity: line.qty.toDouble(),
          unitPrice: line.unitPriceAfterDiscount,
          originalPrice: line.product.price,
          discount: line.discountLineTotal,
          discountType: line.discountType,
          total: line.totalPrice,
          tenantId: tenantId,
        );
      }).toList(),
      customer: customer.id == 'C001'
          ? null
          : domain.Customer(
              id: customer.id,
              tenantId: tenantId,
              name: customer.name,
              phone: customer.phone,
              address: customer.address,
              creditLimit: customer.creditLimit,
              currentBalance: customer.currentBalance,
              synced: true,
            ),
    );
  }

  Future<void> _showCurrentCartBillPreview() async {
    if (_cart.isEmpty) return;

    final cartLines = _cart.entries
        .map((entry) {
          final product = _resolveCartItemProduct(entry.key);
          if (product == null) return null;
          final discount =
              _posLineDiscounts[entry.key] ?? _autoDiscountForProduct(product);
          return _CartLine(
            product: product,
            qty: entry.value,
            discountValue: discount?.value ?? 0.0,
            discountType: discount?.type ?? 'FIXED',
            discountLabel: discount?.label ?? '',
          );
        })
        .whereType<_CartLine>()
        .toList();

    if (cartLines.isEmpty) return;

    final previewCustomer = _selectedCustomerId == null
        ? _CustomerItem(
            id: 'C001',
            name: 'Walk-in Customer',
            locationId: _activeLocationForWrites,
            phone: 'N/A',
            email: '',
          )
        : _scopedCustomers.firstWhere(
            (customer) => customer.id == _selectedCustomerId,
            orElse: () => _CustomerItem(
              id: 'C001',
              name: 'Walk-in Customer',
              locationId: _activeLocationForWrites,
              phone: 'N/A',
              email: '',
            ),
          );
    final subtotal = cartLines.fold<double>(
      0,
      (sum, line) => sum + line.totalPrice,
    );
    final invoiceDiscountAmount = _posInvoiceDiscountType == 'PERCENT'
        ? subtotal * (_posInvoiceDiscountValue / 100)
        : _posInvoiceDiscountValue;
    final previewSubtotal = (subtotal - invoiceDiscountAmount).clamp(
      0.0,
      double.infinity,
    );
    final taxRate = double.tryParse(_taxRate) ?? 0;
    final previewTax = _posApplyTax ? previewSubtotal * (taxRate / 100) : 0.0;
    final previewTotal = previewSubtotal + previewTax;
    final previewPaid =
        double.tryParse(_amountPaidController.text.trim()) ?? previewTotal;
    final previewBalance = previewTotal - previewPaid;
    final previewInvoiceNo = await _buildInvoiceNumber(DateTime.now());
    final previewSale = _SaleRecord(
      id: 'PREVIEW-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: previewInvoiceNo,
      locationId: _activeLocationForWrites,
      customerName: previewCustomer.name,
      employeeId: _currentUserId,
      cashierName: _currentUserName,
      paymentMethod: _paymentMethodController.text.isEmpty
          ? 'CASH'
          : _paymentMethodController.text,
      items: cartLines
          .map(
            (line) => _SaleItemSnapshot(
              productId: line.product.id,
              productName: line.product.name,
              quantity: line.qty,
              unitPrice: line.unitPriceAfterDiscount,
              discount: line.discountLineTotal,
              discountType: line.discountType,
              lineTotal: line.totalPrice,
              productType: line.product.productType,
            ),
          )
          .toList(),
      subtotal: previewSubtotal,
      tax: previewTax,
      discount: invoiceDiscountAmount,
      total: previewTotal,
      amountPaid: previewPaid,
      balance: previewBalance,
      chequeNumber: _chequeNumberController.text.trim(),
      status: 'DRAFT',
      createdAt: DateTime.now(),
    );

    final settings = await _currentPrintSettings();
    final previewSaleDomain = _saleRecordToPreviewDomainSale(
      previewSale,
      cartLines,
      customer: previewCustomer,
    );
    final isA4Printer = settings.printerType.trim().toUpperCase() == 'A4';
    final paperFormat = isA4Printer
        ? PdfPageFormat.a4
        : PrintService.getThermalPaperFormat(settings.paperSize);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bill Preview'),
        content: SizedBox(
          width: 800,
          height: 600,
          child: PdfPreview(
            build: (format) async {
              final pdf = pw.Document();
              if (isA4Printer) {
                pdf.addPage(
                  pw.MultiPage(
                    pageFormat: PdfPageFormat.a4,
                    margin: pw.EdgeInsets.all(settings.marginTop),
                    build: (context) => PrintService.buildA4Invoice(
                      sale: previewSaleDomain,
                      settings: settings,
                      currencySymbol: _currency == 'LKR'
                          ? 'Rs.'
                          : _currency == 'USD'
                          ? '\$'
                          : _currency,
                      storeName: _companyName,
                      storeAddress: _companyAddress.trim().isEmpty
                          ? _storeLocation
                          : _companyAddress,
                      storePhone: _companyPhone,
                    ),
                  ),
                );
              } else {
                pdf.addPage(
                  pw.Page(
                    pageFormat: paperFormat,
                    margin: pw.EdgeInsets.only(
                      top: settings.marginTop,
                      left: settings.marginLeft,
                      right: settings.marginLeft,
                      bottom: 10,
                    ),
                    build: (context) => PrintService.buildThermalReceipt(
                      sale: previewSaleDomain,
                      settings: settings,
                      currencySymbol: _currency == 'LKR'
                          ? 'Rs.'
                          : _currency == 'USD'
                          ? '\$'
                          : _currency,
                      storeName: _companyName,
                      storeAddress: _companyAddress.trim().isEmpty
                          ? _storeLocation
                          : _companyAddress,
                      storePhone: _companyPhone,
                    ),
                  ),
                );
              }
              return pdf.save();
            },
            allowSharing: false,
            allowPrinting: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _resetPosDiscountState() {
    _posLineDiscounts.clear();
    _posLinePrices.clear();
    _posInvoiceDiscountValue = 0.0;
    _posInvoiceDiscountType = 'FIXED';
    _posCouponController.clear();
    _posGiftCardController.clear();
  }

  Future<domain.PrintSettingsModel> _currentPrintSettings() async {
    db.PrintSetting? rawSettings;
    try {
      if (_appDatabase != null) {
        rawSettings = await _appDatabase!.getPrintSettings(
          _activeTenantId ?? 'local',
        );
      }
    } catch (e) {
      debugPrint('Failed to load raw print settings: $e');
    }
    final effectivePaper = _localReceiptPaperSize.isNotEmpty
        ? _localReceiptPaperSize
        : (rawSettings?.paperSize ?? '80mm');
    final isA4 = effectivePaper.toLowerCase().contains('a4');
    return domain.PrintSettingsModel(
      id: rawSettings?.id ?? 'default',
      tenantId: rawSettings?.tenantId ?? (_activeTenantId ?? 'local'),
      paperSize: effectivePaper,
      printerName: _localReceiptPrinterName ?? rawSettings?.printerName,
      printerType: isA4 ? 'A4' : (rawSettings?.printerType ?? 'THERMAL'),
      invoiceTemplate: rawSettings?.invoiceTemplate ?? 'PROFESSIONAL',
      autoPrint: _localAutoPrintOnSaleComplete,
      showLogo: _receiptShowLogo && (rawSettings?.showLogo ?? true),
      showBarcode: _receiptShowReceiptNumber && (rawSettings?.showBarcode ?? false),
      showQr: rawSettings?.showQr ?? true,
      showTax: _receiptShowTax && (rawSettings?.showTax ?? true),
      showDiscount: rawSettings?.showDiscount ?? true,
      showCustomerAddress: _receiptShowShopAddress && (rawSettings?.showCustomerAddress ?? false),
      marginTop: _localMarginVMm,
      marginLeft: _localMarginHMm,
      fontSize: rawSettings?.fontSize ?? 10,
      lineSpacing: rawSettings?.lineSpacing ?? 1.2,
      thankYouMessage: rawSettings?.thankYouMessage ?? 'Thank you for shopping with us!',
      returnPolicy: rawSettings?.returnPolicy ?? (_receiptShowReturnPolicy ? _receiptNote : null),
      socialLinks: rawSettings?.socialLinks,
      showShopHeader: _receiptShowCompanyName,
      showInvoiceNumber: _receiptShowReceiptNumber,
      showDateTime: _receiptShowDate || _receiptShowTime,
      showCashierName: _receiptShowCashier,
      showCustomerName: _receiptShowCustomer,
      showItemTable: true,
      showItemNumbers: true,
      showSubtotal: true,
      showTotal: true,
      showPaymentDetails: _receiptShowPaymentMethod,
      showFooter: _receiptFooter.trim().isNotEmpty,
      showTerms: _receiptShowReturnPolicy,
      invoiceTerms: _receiptNote,
      paperWidthMm: _localPaperWidthMm,
      marginVerticalMm: _localMarginVMm,
      marginHorizontalMm: _localMarginHMm,
      receiptLanguage: _uiLanguage == 'Sinhala'
          ? 'si'
          : _uiLanguage == 'Tamil'
              ? 'ta'
              : 'en',
      deliveryNoteFormat: _localDeliveryNoteFormat,
      deliveryNotePrinterName: _localDeliveryNotePrinterName,
    );
  }

  PdfPageFormat _receiptPageFormat() {
    if (_receiptPaper == '58mm') {
      return PdfPageFormat(58 * PdfPageFormat.mm, 240 * PdfPageFormat.mm);
    } else if (_receiptPaper == 'A4') {
      return PdfPageFormat.a4;
    } else if (_receiptPaper.endsWith('mm')) {
      final parsed = double.tryParse(_receiptPaper.replaceAll('mm', '').trim());
      if (parsed != null && parsed > 0) {
        return PdfPageFormat(parsed * PdfPageFormat.mm, 300 * PdfPageFormat.mm);
      }
    }
    final numeric = double.tryParse(_receiptPaper.trim());
    if (numeric != null && numeric > 0) {
      return PdfPageFormat(numeric * PdfPageFormat.mm, 300 * PdfPageFormat.mm);
    }
    return PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm);
  }

  Future<void> _printDemoReceipt() async {
    final demoSale = _SaleRecord(
      id: 'DEMO-RECEIPT',
      customerName: 'Walk-in Customer',
      paymentMethod: 'CASH',
      subtotal: 2000,
      tax: _receiptShowTax
          ? 2000 * ((double.tryParse(_taxRate) ?? 0) / 100)
          : 0,
      total: _receiptShowTax ? 2200 : 2000,
      amountPaid: _receiptShowTax ? 2200 : 2000,
      balance: 0,
      status: 'COMPLETED',
      createdAt: DateTime.now(),
    );

    final demoLines = [
      _CartLine(
        product: _ProductItem(
          id: 'D1',
          name: 'Demo Item A',
          category: 'Demo',
          price: 1200,
          stock: 0,
          minStock: 0,
        ),
        qty: 1,
      ),
      _CartLine(
        product: _ProductItem(
          id: 'D2',
          name: 'Demo Item B',
          category: 'Demo',
          price: 800,
          stock: 0,
          minStock: 0,
        ),
        qty: 1,
      ),
    ];

    await _printReceipt(sale: demoSale, lines: demoLines);
  }

  Future<void> _loadStoreLogins() async {
    final authService = context.read<AuthService>();
    final isPlatformAdmin = widget.user.role == 'platform_admin';

    if (isPlatformAdmin) {
      if (!mounted) return;
      setState(() => _isLoadingPlatformData = true);
      try {
        final stats = await authService.getAdminStats();
        final tenants = await authService.getAdminTenants();
        final plans = await authService.getAdminPlans();
        final users = await authService.getAdminUsers();
        final activityLogs = await authService.getAdminActivity();
        final releases = await authService.getAdminReleases();
        final qrPayments = await authService.getAdminQrPayments();
        final docs = await authService.getAdminDocs();
        final tutorials = await authService.getAdminTutorials();

        if (!mounted) return;
        setState(() {
          _adminStats = stats;
          _storeLogins = tenants;
          _adminPlans = plans;
          _adminUsers = users;
          _adminActivityLogs = activityLogs;
          _adminReleases = releases;
          _adminQrPaymentsData = qrPayments;
          _adminDocs = docs;
          _adminTutorials = tutorials;
          _isLoadingPlatformData = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoadingPlatformData = false);
      }
    } else {
      List<Map<String, dynamic>> logins;
      try {
        logins = await authService.getPlatformStores();
        if (logins.isEmpty) {
          logins = await authService.getStoreLogins();
        }
      } catch (_) {
        logins = await authService.getStoreLogins();
      }
      if (!mounted) return;
      setState(() => _storeLogins = logins);
    }
  }

  void _recordPlatformActivity(
    String title, {
    String? detail,
    IconData icon = Icons.circle,
    Color color = const Color(0xFF6D28D9),
  }) {
    if (!mounted) return;
    setState(() {
      _platformActivity.insert(
        0,
        _PlatformActivityEntry(
          title: title,
          detail: detail,
          icon: icon,
          color: color,
          timestamp: DateTime.now(),
        ),
      );
      if (_platformActivity.length > 25) {
        _platformActivity.removeRange(25, _platformActivity.length);
      }
    });
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final date = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day-$month-$date $hour:$minute';
  }

  Future<void> _reactivateStoreTrial(
    String tenantId, {
    DateTime? trialEndsAt,
  }) async {
    if (tenantId.trim().isEmpty || _trialUpdatingTenants.contains(tenantId)) {
      return;
    }

    setState(() => _trialUpdatingTenants.add(tenantId));
    final authService = context.read<AuthService>();
    bool success = false;
    try {
      success = await authService.reactivateStoreTrial(
        tenantId: tenantId,
        trialEndsAt: trialEndsAt,
      );
      if (success) {
        await _loadStoreLogins();
      }
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _trialUpdatingTenants.remove(tenantId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Trial reactivated for $tenantId'
              : 'Could not reactivate trial for $tenantId',
        ),
      ),
    );
    if (success) {
      _recordPlatformActivity(
        'Trial reactivated',
        detail: tenantId,
        icon: Icons.replay_rounded,
        color: const Color(0xFF2563EB),
      );
    }
  }

  Future<void> _showReactivateDialog(String tenantId) async {
    final daysCtrl = TextEditingController(text: '30');
    final dateCtrl = TextEditingController();
    DateTime? pickedDate;
    String selectedType = '1month';

    final confirmed = await showDialog<bool?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Reactivate Store / Activate Subscription'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a subscription plan or a custom extension duration to reactivate this store.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Subscription Plan',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '1month',
                          child: Text(
                            'Monthly Subscription (30 Days - 1 Month Plan)',
                          ),
                        ),
                        DropdownMenuItem(
                          value: '1year',
                          child: Text(
                            'Yearly Subscription (365 Days - 1 Year Plan)',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('Custom Extension'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    if (selectedType == 'custom') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Enter the number of extension days or pick an exact expiry date below.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dateCtrl,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date (optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Pick date',
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: dialogCtx,
                                initialDate: now.add(const Duration(days: 30)),
                                firstDate: now.add(const Duration(days: 1)),
                                lastDate: now.add(const Duration(days: 3650)),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  pickedDate = picked;
                                  dateCtrl.text = picked
                                      .toLocal()
                                      .toIso8601String()
                                      .split('T')
                                      .first;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: daysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Days (used if date not set)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Activate'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    String? planId;
    int days = 30;

    if (selectedType == '1month') {
      planId = '1month';
      days = 30;
    } else if (selectedType == '1year') {
      planId = '1year';
      days = 365;
    } else {
      days = int.tryParse(daysCtrl.text.trim()) ?? 30;
      if (pickedDate != null) {
        days = pickedDate!.difference(DateTime.now()).inDays;
      }
      if (days <= 0 || days > 3650) days = 30;
    }

    if (tenantId.trim().isEmpty || _trialUpdatingTenants.contains(tenantId))
      return;

    setState(() => _trialUpdatingTenants.add(tenantId));
    final authService = context.read<AuthService>();
    bool success = false;
    try {
      final res = await authService.activateAdminTenant(
        tenantId: tenantId,
        days: days,
        planId: planId,
      );
      success = res != null;
      if (success) await _loadStoreLogins();
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _trialUpdatingTenants.remove(tenantId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Store activated successfully'
              : (authService.lastActionError ?? 'Could not activate store'),
        ),
      ),
    );
  }

  Future<void> _confirmDeactivateStore(Map<String, dynamic> entry) async {
    final tenantId = (entry['tenant_id'] ?? entry['tenantId'] ?? '')
        .toString()
        .trim();
    final storeName = (entry['store_name'] ?? entry['storeName'] ?? '-')
        .toString();
    if (tenantId.isEmpty || _trialUpdatingTenants.contains(tenantId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Store'),
        content: Text(
          'Temporarily suspend "$storeName" (tenant: $tenantId)? This will block access but keep data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _trialUpdatingTenants.add(tenantId));
    final authService = context.read<AuthService>();
    bool success = false;
    try {
      final res = await authService.suspendAdminTenant(tenantId: tenantId);
      success = res != null;
      if (success) await _loadStoreLogins();
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _trialUpdatingTenants.remove(tenantId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Store suspended'
              : (authService.lastActionError ?? 'Could not suspend store'),
        ),
      ),
    );
    if (success) {
      _recordPlatformActivity(
        'Store suspended',
        detail: tenantId,
        icon: Icons.pause_circle_outline,
        color: const Color(0xFFB45309),
      );
    }
  }

  Future<void> _createStoreLogin() async {
    final storeName = _storeNameController.text.trim();
    final tenantId = _tenantIdController.text.trim();
    final email = _storeEmailController.text.trim();
    final password = _storePasswordController.text.trim();

    if (storeName.isEmpty ||
        tenantId.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all store login fields')),
      );
      return;
    }

    setState(() => _isCreatingStore = true);
    final authService = context.read<AuthService>();
    final created = await authService.createStoreLogin(
      storeName: storeName,
      tenantId: tenantId,
      email: email,
      password: password,
    );
    if (!mounted) return;

    setState(() => _isCreatingStore = false);

    if (!created) {
      final errorMessage = authService.lastActionError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ?? 'Could not create store login. Please try again.',
          ),
        ),
      );
      return;
    }

    _storeNameController.clear();
    _tenantIdController.clear();
    _storeEmailController.clear();
    _storePasswordController.clear();
    await _loadStoreLogins();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Store login created successfully')),
    );
    _recordPlatformActivity(
      'Store created',
      detail: '$storeName • $tenantId',
      icon: Icons.storefront_rounded,
      color: const Color(0xFF16A34A),
    );
  }

  Future<void> _copyActivationCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: trimmed));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activation code copied to clipboard.')),
    );
    _recordPlatformActivity(
      'Activation code copied',
      detail: trimmed,
      icon: Icons.copy_rounded,
      color: const Color(0xFF7C3AED),
    );
  }

  void _logoutFromPlatformAdmin() {
    _disposeTenantScopedResources();
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  Future<void> _showEditStoreDialog(Map<String, dynamic> entry) async {
    final tenantId = (entry['tenant_id'] ?? entry['tenantId'] ?? '')
        .toString()
        .trim();
    if (tenantId.isEmpty || _trialUpdatingTenants.contains(tenantId)) {
      return;
    }

    final storeNameController = TextEditingController(
      text: (entry['store_name'] ?? entry['storeName'] ?? '').toString(),
    );
    final ownerEmailController = TextEditingController(
      text: (entry['owner_email'] ?? entry['email'] ?? '').toString(),
    );
    final maxLocationsController = TextEditingController(
      text: (entry['max_locations'] ?? entry['maxLocations'] ?? 3).toString(),
    );
    final maxUsersController = TextEditingController(
      text: (entry['max_users'] ?? entry['maxUsers'] ?? 15).toString(),
    );
    final maxProductsController = TextEditingController(
      text: (entry['max_products'] ?? entry['maxProducts'] ?? 500).toString(),
    );

    Widget fieldLabel(String label) => Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final isNarrow = screenSize.width < 600;
        final dialogWidth = isNarrow ? screenSize.width * 0.94 : 460.0;
        final dialogMaxHeight = screenSize.height * 0.88;

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
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: dialogMaxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.brandIndigo.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: AppTheme.brandIndigo,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Edit Store',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  // ── Body ─────────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        20 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fieldLabel('Store Name'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: storeNameController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.storefront_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          fieldLabel('Owner Email'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: ownerEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Divider(),
                          const SizedBox(height: 4),
                          fieldLabel('Max Locations Limit'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: maxLocationsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          fieldLabel('Max Users Limit'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: maxUsersController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.people_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          fieldLabel('Max Products Limit'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: maxProductsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Footer actions ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandIndigo,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      setState(() => _trialUpdatingTenants.add(tenantId));
      final authService = context.read<AuthService>();
      final updated = await authService.updatePlatformStore(
        tenantId: tenantId,
        storeName: storeNameController.text.trim(),
        ownerEmail: ownerEmailController.text.trim(),
        maxLocations: int.tryParse(maxLocationsController.text.trim()),
        maxUsers: int.tryParse(maxUsersController.text.trim()),
        maxProducts: int.tryParse(maxProductsController.text.trim()),
      );

      if (updated) {
        await _loadStoreLogins();
      }

      if (mounted) {
        setState(() => _trialUpdatingTenants.remove(tenantId));
        final message = updated
            ? 'Store updated successfully.'
            : (authService.lastActionError ?? 'Could not update store.');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        if (updated) {
          _recordPlatformActivity(
            'Store updated',
            detail: tenantId,
            icon: Icons.edit_outlined,
            color: const Color(0xFF0EA5E9),
          );
        }
      }
    }

    storeNameController.dispose();
    ownerEmailController.dispose();
    maxLocationsController.dispose();
    maxUsersController.dispose();
    maxProductsController.dispose();
  }

  Future<void> _confirmDeleteStore(Map<String, dynamic> entry) async {
    final tenantId = (entry['tenant_id'] ?? entry['tenantId'] ?? '')
        .toString()
        .trim();
    final storeName = (entry['store_name'] ?? entry['storeName'] ?? '-')
        .toString();
    if (tenantId.isEmpty || _trialUpdatingTenants.contains(tenantId)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Store'),
        content: Text(
          'Delete "$storeName" and all related store users and sessions? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Store'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _trialUpdatingTenants.add(tenantId));
    final authService = context.read<AuthService>();
    final deleted = await authService.deletePlatformStore(tenantId: tenantId);

    if (deleted) {
      await _loadStoreLogins();
    }

    if (!mounted) return;
    setState(() => _trialUpdatingTenants.remove(tenantId));
    final message = deleted
        ? 'Store deleted successfully.'
        : (authService.lastActionError ?? 'Could not delete store.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (deleted) {
      _recordPlatformActivity(
        'Store deleted',
        detail: tenantId,
        icon: Icons.delete_outline,
        color: const Color(0xFFEF4444),
      );
    }
  }

  List<Map<String, dynamic>> _platformVisibleStores() {
    final query = _platformSearchController.text.trim().toLowerCase();
    final entries = _storeLogins.where((entry) {
      final tenantId = (entry['tenant_id'] ?? entry['tenantId'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final storeName = (entry['store_name'] ?? entry['storeName'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final ownerEmail = (entry['owner_email'] ?? entry['email'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final assignment = _platformPlanAssignments[tenantId];
      final planName = assignment?.planName.toLowerCase() ?? '';
      final cycle = assignment?.billingCycle.toLowerCase() ?? '';
      final status = _platformStoreStatusLabel(entry).toLowerCase();
      if (query.isEmpty) return true;
      return storeName.contains(query) ||
          tenantId.contains(query) ||
          ownerEmail.contains(query) ||
          planName.contains(query) ||
          cycle.contains(query) ||
          status.contains(query);
    }).toList();

    entries.sort((a, b) {
      final aName = (a['store_name'] ?? a['storeName'] ?? '')
          .toString()
          .toLowerCase();
      final bName = (b['store_name'] ?? b['storeName'] ?? '')
          .toString()
          .toLowerCase();
      return aName.compareTo(bName);
    });
    return entries;
  }

  bool _platformStoreIsActive(Map<String, dynamic> entry) {
    final status = (entry['status'] ?? '').toString().toUpperCase();
    if (status == 'ACTIVE' || status == 'TRIAL') {
      return true;
    }
    if (status == 'SUSPENDED') {
      return false;
    }
    final trialEndsRaw = (entry['trial_ends_at'] ?? entry['trialEndsAt'] ?? '')
        .toString();
    final trialEndsAt = DateTime.tryParse(trialEndsRaw);
    final trialActive =
        (entry['trial_active'] as bool?) ??
        (trialEndsAt != null && DateTime.now().isBefore(trialEndsAt));
    return trialActive;
  }

  String _platformStoreStatusLabel(Map<String, dynamic> entry) {
    final status = (entry['status'] ?? '').toString().toUpperCase();
    if (status.isNotEmpty) {
      if (status == 'ACTIVE') return 'Active';
      if (status == 'TRIAL') return 'Trial';
      if (status == 'SUSPENDED') return 'Suspended';
      if (status == 'OFFLINE') return 'Offline';
      return status;
    }
    return _platformStoreIsActive(entry) ? 'Active' : 'Expired';
  }

  Color _platformStoreStatusColor(Map<String, dynamic> entry) {
    final status = (entry['status'] ?? '').toString().toUpperCase();
    if (status == 'ACTIVE') return const Color(0xFF16A34A);
    if (status == 'TRIAL') return const Color(0xFF0EA5E9);
    if (status == 'SUSPENDED') return const Color(0xFFEF4444);
    if (status == 'OFFLINE') return const Color(0xFF6B7280);
    return _platformStoreIsActive(entry)
        ? const Color(0xFF15803D)
        : const Color(0xFFB42318);
  }

  _PlatformPlanAssignment? _platformPlanForTenant(String tenantId) {
    return _platformPlanAssignments[tenantId.trim().toLowerCase()];
  }

  int _platformActiveStoreCount() {
    return _storeLogins.where(_platformStoreIsActive).length;
  }

  int _platformExpiredStoreCount() {
    return _storeLogins.where((entry) => !_platformStoreIsActive(entry)).length;
  }

  int _platformAssignedPlanCount() {
    return _platformPlanAssignments.length;
  }

  Map<String, dynamic> _platformStoreFieldMap(Map<String, dynamic> entry) {
    final tenantId = (entry['tenant_id'] ?? entry['tenantId'] ?? '')
        .toString()
        .trim();
    final storeName = (entry['store_name'] ?? entry['storeName'] ?? '-')
        .toString()
        .trim();
    final ownerEmail = (entry['owner_email'] ?? entry['email'] ?? '-')
        .toString()
        .trim();
    final trialEndsRaw = (entry['trial_ends_at'] ?? entry['trialEndsAt'] ?? '')
        .toString();
    final trialEndsAt = DateTime.tryParse(trialEndsRaw);
    final assignment = _platformPlanForTenant(tenantId);

    final planExpiresRaw =
        (entry['plan_expires_at'] ?? entry['planExpiresAt'] ?? '').toString();
    final planExpiresAt = DateTime.tryParse(planExpiresRaw);

    return {
      'tenantId': tenantId,
      'storeName': storeName,
      'ownerEmail': ownerEmail,
      'trialEndsAt': trialEndsAt,
      'planName':
          entry['plan_name'] ??
          entry['planName'] ??
          assignment?.planName ??
          'Trial',
      'billingCycle': assignment?.billingCycle ?? 'Monthly',
      'paymentReceived': assignment?.paymentReceived ?? true,
      'paymentAmount': assignment?.paymentAmount ?? 0,
      'paymentReference': assignment?.paymentReference ?? '',
      'paymentNote': assignment?.adminNote ?? '',
    };
  }

  Future<void> _showAssignPlanDialog(Map<String, dynamic> entry) async {
    final tenantId = (entry['tenant_id'] ?? entry['tenantId'] ?? '')
        .toString()
        .trim();
    if (tenantId.isEmpty) return;

    final storeName = (entry['store_name'] ?? entry['storeName'] ?? tenantId)
        .toString();

    final planOptions = _adminPlans.isNotEmpty
        ? _adminPlans
        : [
            {'planId': 'free', 'name': 'Free'},
            {'planId': 'trial', 'name': 'Trial'},
            {'planId': 'starter', 'name': 'Starter'},
            {'planId': 'growth', 'name': 'Growth'},
            {'planId': 'enterprise', 'name': 'Enterprise'},
          ];

    final planExpiresRaw =
        (entry['plan_expires_at'] ?? entry['planExpiresAt'] ?? '').toString();
    DateTime? nextPaymentDue = DateTime.tryParse(planExpiresRaw);
    if (nextPaymentDue == null || nextPaymentDue.isBefore(DateTime.now())) {
      nextPaymentDue = DateTime.now().add(const Duration(days: 30));
    }

    String selectedPlanId = (entry['plan_id'] ?? entry['planId'] ?? '')
        .toString()
        .trim();
    final validIds = planOptions
        .map((p) => (p['planId'] ?? p['plan_id'] ?? '').toString())
        .toList();
    if (!validIds.contains(selectedPlanId)) {
      selectedPlanId = validIds.isNotEmpty ? validIds.first : 'trial';
    }

    final dueDateController = TextEditingController(
      text: nextPaymentDue.toIso8601String().split('T').first,
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Assign Plan to $storeName'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current plan: ${entry['plan_name'] ?? entry['planName'] ?? 'Trial'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedPlanId,
                        decoration: const InputDecoration(
                          labelText: 'Select Plan',
                        ),
                        items: planOptions
                            .map(
                              (p) => DropdownMenuItem<String>(
                                value: (p['planId'] ?? p['plan_id'] ?? '')
                                    .toString(),
                                child: Text((p['name'] ?? '').toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedPlanId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dueDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Next Payment Due / Expiry Date',
                          suffixIcon: IconButton(
                            tooltip: 'Choose Date',
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate:
                                    nextPaymentDue ??
                                    DateTime.now().add(
                                      const Duration(days: 30),
                                    ),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );
                              if (picked == null) return;
                              setDialogState(() {
                                nextPaymentDue = picked;
                                dueDateController.text = picked
                                    .toIso8601String()
                                    .split('T')
                                    .first;
                              });
                            },
                            icon: const Icon(Icons.date_range_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Assign Plan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      return;
    }

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      final res = await authService.assignAdminPlan(
        tenantId: tenantId,
        planId: selectedPlanId,
        expiresAt: nextPaymentDue?.toIso8601String(),
      );
      if (res != null) {
        await _loadStoreLogins();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan assigned successfully to $storeName')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to assign plan',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error assigning plan: $e')));
    }
  }

  Widget _buildPlatformMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.62),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformInfoCard({
    required String title,
    required String body,
    required IconData icon,
    required List<Widget> actions,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star_border_rounded,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(icon, color: const Color(0xFF7C3AED)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSidebar(
    AuthAuthenticated state, {
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    const sidebarBackground = Color(0xFF0F1020);
    final activeColor = colorScheme.tertiary;
    final stores = _platformVisibleStores();

    Widget navItem(_PlatformNavItem item) {
      final selected = item.key == _selectedPlatformNavKey;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected
              ? activeColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (compact) {
                Navigator.of(context).pop();
              }
              setState(() => _selectedPlatformNavKey = item.key);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: selected ? activeColor : const Color(0xFFB7C0CE),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _t(item.label),
                      style: TextStyle(
                        color: selected ? activeColor : const Color(0xFFE5E7EB),
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 272,
      decoration: const BoxDecoration(
        color: sidebarBackground,
        border: Border(right: BorderSide(color: Color(0x142F3550))),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF17162B), Color(0xFF24183E)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dine Buddy Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Platform Admin',
                        style: TextStyle(
                          color: Color(0xFFB9C0D0),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                ..._platformNavItems.map(navItem),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181A32),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stores.length} stores',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_platformActiveStoreCount()} active · ${_platformExpiredStoreCount()} expired',
                        style: const TextStyle(
                          color: Color(0xFFB9C0D0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Material(
              color: const Color(0xFF181A32),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _logoutFromPlatformAdmin,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: activeColor,
                        child: Text(
                          state.user.name.isNotEmpty
                              ? state.user.name[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              state.user.role.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFB9C0D0),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: Color(0xFFF87171),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformTopBar(
    AuthAuthenticated state, {
    bool compact = false,
    VoidCallback? onOpenMenu,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBackground = isDark ? const Color(0xFF111827) : Colors.white;
    final sectionTitle = _platformSelectedSectionTitle();

    final controls = <Widget>[
      if (compact)
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            onPressed: onOpenMenu,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.outline),
              padding: EdgeInsets.zero,
            ),
            icon: Icon(
              Icons.menu_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
        ),
      if (compact) const SizedBox(width: 10),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 18 : 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Welcome back, ${state.user.name.isEmpty ? 'Admin' : state.user.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      if (!compact) ...[
        SizedBox(
          width: 260,
          child: TextField(
            controller: _platformSearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search stores, plans, emails',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
      _buildNotificationBellButton(colorScheme),
      const SizedBox(width: 8),
      SizedBox(
        width: 44,
        height: 44,
        child: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF7C3AED),
          child: Text(
            state.user.name.isNotEmpty
                ? state.user.name.substring(0, 1).toUpperCase()
                : 'A',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ];

    return Container(
      height: compact ? 76 : 72,
      decoration: BoxDecoration(
        color: barBackground,
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
        boxShadow: UiShadows.light,
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
      child: Row(children: controls),
    );
  }

  String _platformSelectedSectionTitle() {
    final item = _platformNavItems.firstWhere(
      (section) => section.key == _selectedPlatformNavKey,
      orElse: () => _platformNavItems.first,
    );
    return _t(item.label);
  }

  Widget _buildPlatformInfoPage({
    required String title,
    required String description,
    required IconData icon,
    required List<Widget> actions,
  }) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildPlatformInfoCard(
          title: title,
          body: description,
          icon: icon,
          actions: actions,
        ),
      ],
    );
  }

  Widget _buildPlatformOverviewPage() {
    final recentTenants =
        (_adminStats['recent_tenants'] as List<dynamic>?) ?? [];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_isLoadingPlatformData)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 240,
              child: _buildPlatformMetricCard(
                title: 'Total Shops',
                value: (_adminStats['total_tenants'] ?? _storeLogins.length)
                    .toString(),
                subtitle: 'All onboarded tenants',
                icon: Icons.storefront_rounded,
                color: const Color(0xFF7C3AED),
              ),
            ),
            SizedBox(
              width: 240,
              child: _buildPlatformMetricCard(
                title: 'Active Stores',
                value:
                    (_adminStats['active_tenants'] ??
                            _platformActiveStoreCount())
                        .toString(),
                subtitle: 'Active subscription plans',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF16A34A),
              ),
            ),
            SizedBox(
              width: 240,
              child: _buildPlatformMetricCard(
                title: 'Trial Stores',
                value: (_adminStats['trial_tenants'] ?? 0).toString(),
                subtitle: 'Trial or free tier',
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFF0EA5E9),
              ),
            ),
            SizedBox(
              width: 240,
              child: _buildPlatformMetricCard(
                title: 'Suspended Stores',
                value:
                    (_adminStats['suspended_tenants'] ??
                            _platformExpiredStoreCount())
                        .toString(),
                subtitle: 'Blocked or suspended access',
                icon: Icons.pause_circle_rounded,
                color: const Color(0xFFB45309),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPlatformInfoCard(
          title: 'Platform quick actions',
          body:
              'Create a shop, assign a plan, or review store access from this panel.',
          icon: Icons.tune_rounded,
          actions: [
            FilledButton.icon(
              onPressed: () =>
                  setState(() => _selectedPlatformNavKey = 'restaurants'),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Manage Shops'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _selectedPlatformNavKey = 'plans'),
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: const Text('Assign Plan'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Recent Shops', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (recentTenants.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _isLoadingPlatformData ? 'Loading...' : 'No shops found.',
              ),
            ),
          )
        else
          ...recentTenants.map(
            (e) => _buildPlatformStoreCard(Map<String, dynamic>.from(e as Map)),
          ),
      ],
    );
  }

  Widget _buildPlatformShopsPage() {
    final stores = _platformVisibleStores();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Shop',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create, edit, activate, and remove store access from one place.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _storeNameController,
                        decoration: const InputDecoration(
                          labelText: 'Store Name',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _tenantIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tenant ID',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _storeEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Owner Email',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _storePasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Store Login Password',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        onPressed: _isCreatingStore ? null : _createStoreLogin,
                        child: _isCreatingStore
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create Store Login'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Shops', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('${stores.length} shops matched your search.'),
        const SizedBox(height: 12),
        if (stores.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No shops found.'),
            ),
          )
        else
          ...stores.map(_buildPlatformStoreCard),
      ],
    );
  }

  Future<void> _showCreateEditPlanDialog([
    Map<String, dynamic>? existingPlan,
  ]) async {
    final isEditing = existingPlan != null;
    final planIdCtrl = TextEditingController(
      text: existingPlan != null
          ? (existingPlan['planId'] ?? existingPlan['plan_id'] ?? '').toString()
          : '',
    );
    final nameCtrl = TextEditingController(
      text: existingPlan != null ? (existingPlan['name'] ?? '').toString() : '',
    );
    final monthlyPriceCtrl = TextEditingController(
      text: existingPlan != null
          ? (existingPlan['priceMonthly'] ?? existingPlan['price_monthly'] ?? 0)
                .toString()
          : '0',
    );
    final yearlyPriceCtrl = TextEditingController(
      text: existingPlan != null
          ? (existingPlan['priceYearly'] ?? existingPlan['price_yearly'] ?? 0)
                .toString()
          : '0',
    );
    final durationDaysCtrl = TextEditingController(
      text: existingPlan != null
          ? (existingPlan['durationDays'] ??
                    existingPlan['duration_days'] ??
                    30)
                .toString()
          : '30',
    );
    final maxUsersCtrl = TextEditingController(
      text: existingPlan != null
          ? (existingPlan['maxUsers'] ?? existingPlan['max_users'] ?? 15)
                .toString()
          : '15',
    );
    final maxProductsCtrl = TextEditingController(
      text: existingPlan != null
          ? (existingPlan['maxProducts'] ?? existingPlan['max_products'] ?? 500)
                .toString()
          : '500',
    );
    final descCtrl = TextEditingController(
      text: existingPlan != null
          ? (existingPlan['description'] ?? '').toString()
          : '',
    );
    final featuresCtrl = TextEditingController(
      text: existingPlan != null
          ? ((existingPlan['features'] as List<dynamic>?)?.join(', ') ?? '')
          : '',
    );

    String selectedType = existingPlan != null
        ? (existingPlan['type'] ?? 'MONTHLY').toString().toUpperCase()
        : 'MONTHLY';
    bool syncEnabled = existingPlan != null
        ? (existingPlan['syncEnabled'] ?? existingPlan['sync_enabled'] ?? true)
        : true;

    final typeOptions = [
      'FREE',
      'TRIAL',
      'MONTHLY',
      'BIANNUAL',
      'ANNUAL',
      'CUSTOM',
      'OFFLINE',
    ];

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Edit Subscription Plan'
                    : 'Create Subscription Plan',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: planIdCtrl,
                        readOnly: isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Plan ID (slug, e.g. starter)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Plan Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Billing Cycle Type',
                        ),
                        items: typeOptions
                            .map(
                              (t) => DropdownMenuItem<String>(
                                value: t,
                                child: Text(t),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setDialogState(() => selectedType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: monthlyPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Monthly Price (\$)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: yearlyPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Yearly Price (\$)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: durationDaysCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duration (Days, 0=Lifetime)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxUsersCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Users Limit',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: maxProductsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Products Limit',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: syncEnabled,
                        onChanged: (val) =>
                            setDialogState(() => syncEnabled = val),
                        title: const Text('Enable Cloud Syncing'),
                        subtitle: const Text(
                          'If disabled, clients must run in local-only offline mode.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: featuresCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Features (comma separated list)',
                          hintText: 'POS Module, Barcode Printing, Reports',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Plan Description',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save Plan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final data = {
      'planId': planIdCtrl.text.trim().toLowerCase(),
      'name': nameCtrl.text.trim(),
      'type': selectedType,
      'priceMonthly': double.tryParse(monthlyPriceCtrl.text.trim()) ?? 0,
      'priceYearly': double.tryParse(yearlyPriceCtrl.text.trim()) ?? 0,
      'durationDays': int.tryParse(durationDaysCtrl.text.trim()) ?? 30,
      'maxUsers': int.tryParse(maxUsersCtrl.text.trim()) ?? 15,
      'maxProducts': int.tryParse(maxProductsCtrl.text.trim()) ?? 500,
      'syncEnabled': syncEnabled,
      'description': descCtrl.text.trim(),
      'features': featuresCtrl.text
          .trim()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    };

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      dynamic res;
      if (isEditing) {
        res = await authService.updateAdminPlan(planIdCtrl.text.trim(), data);
      } else {
        res = await authService.createAdminPlan(data);
      }
      if (res != null) {
        await _loadStoreLogins();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan saved successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.lastActionError ?? 'Failed to save plan'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving plan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  Future<void> _confirmDeletePlan(String planId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete subscription plan "$name" ($planId)? This will not affect existing tenants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      final success = await authService.deleteAdminPlan(planId);
      if (success) {
        await _loadStoreLogins();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to delete plan',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting plan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  Widget _buildPlatformPlansPage() {
    final stores = _platformVisibleStores();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_isLoadingPlatformData)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subscription Plans',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            FilledButton.icon(
              onPressed: () => _showCreateEditPlanDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Plan'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_adminPlans.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No plans found. Create a plan using the button above.',
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 340,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: _adminPlans.length,
            itemBuilder: (context, index) {
              final plan = _adminPlans[index];
              final planId = (plan['planId'] ?? plan['plan_id'] ?? '')
                  .toString();
              final name = (plan['name'] ?? '').toString();
              final type = (plan['type'] ?? '').toString();
              final monthly =
                  (plan['priceMonthly'] ?? plan['price_monthly'] ?? 0)
                      .toString();
              final yearly = (plan['priceYearly'] ?? plan['price_yearly'] ?? 0)
                  .toString();
              final syncEnabled =
                  plan['syncEnabled'] ?? plan['sync_enabled'] ?? true;
              final duration =
                  (plan['durationDays'] ?? plan['duration_days'] ?? 0)
                      .toString();

              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Price: \$$monthly/mo • \$$yearly/yr'),
                      Text(
                        'Duration: $duration Days ${duration == "0" ? "(Unlimited)" : ""}',
                      ),
                      Text(
                        'Sync Mode: ${syncEnabled ? "Cloud Sync" : "Offline Only"}',
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Edit Plan',
                            onPressed: () => _showCreateEditPlanDialog(plan),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Delete Plan',
                            onPressed: () => _confirmDeletePlan(planId, name),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 36),

        Text(
          'Active Shop Assignments',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (stores.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No shops available.'),
            ),
          )
        else
          ...stores.map((entry) {
            final fields = _platformStoreFieldMap(entry);
            final tenantId = fields['tenantId'] as String;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fields['storeName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Tenant ID: $tenantId'),
                          Text('Plan: ${fields['planName']}'),
                          if (fields['nextPaymentDue'] != null)
                            Text(
                              'Expires: ${fields['nextPaymentDue'].toIso8601String().split('T').first}',
                            ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showAssignPlanDialog(entry),
                      icon: const Icon(Icons.dashboard_customize_rounded),
                      label: const Text('Assign / Update'),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPlatformUsersPage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_isLoadingPlatformData)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),
        _buildPlatformInfoCard(
          title: 'Users & Access',
          body:
              'Review and manage platform operators and restaurant tenant users who have access to the system.',
          icon: Icons.people_alt_rounded,
          actions: [
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _selectedPlatformNavKey = 'restaurants'),
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('Open Shop List'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_adminUsers.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No platform users found.')),
            ),
          )
        else
          ..._adminUsers.map((user) {
            final name = (user['name'] ?? '').toString();
            final email = (user['email'] ?? '').toString();
            final role = (user['role'] ?? '').toString().toUpperCase();
            final tenantId =
                (user['tenant_id'] ?? user['tenantId'] ?? 'Platform')
                    .toString();
            final active = user['active'] ?? true;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(
                        0xFF7C3AED,
                      ).withValues(alpha: 0.18),
                      child: Text(
                        name.isNotEmpty
                            ? name.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (role.contains('ADMIN') ||
                                          role == 'OWNER')
                                      ? Colors.purple.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        (role.contains('ADMIN') ||
                                            role == 'OWNER')
                                        ? Colors.purple
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Email: $email'),
                          Text('Tenant / Store: $tenantId'),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        active ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPlatformActivityPage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_isLoadingPlatformData)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),
        _buildPlatformInfoCard(
          title: 'Activity Log',
          body:
              'Track platform administration actions, tenant events, plan changes, and license key generation.',
          icon: Icons.receipt_long_rounded,
          actions: const [],
        ),
        const SizedBox(height: 20),
        if (_adminActivityLogs.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No activity logs found.')),
            ),
          )
        else
          ..._adminActivityLogs.map((entry) {
            final action = (entry['action'] ?? '').toString().toUpperCase();
            final details = (entry['details'] ?? '').toString();
            final userName =
                (entry['user_name'] ?? entry['userName'] ?? 'Platform Admin')
                    .toString();
            final createdVal = entry['created_at'] ?? entry['createdAt'] ?? '';
            final timestamp =
                DateTime.tryParse(createdVal.toString()) ?? DateTime.now();

            IconData icon = Icons.receipt_long_rounded;
            Color color = const Color(0xFF2563EB);

            if (action.contains('CREATE')) {
              icon = Icons.storefront_rounded;
              color = const Color(0xFF16A34A);
            } else if (action.contains('SUSPEND')) {
              icon = Icons.pause_circle_outline;
              color = const Color(0xFFEF4444);
            } else if (action.contains('ACTIVATE')) {
              icon = Icons.play_circle_outline;
              color = const Color(0xFF16A34A);
            } else if (action.contains('PLAN')) {
              icon = Icons.dashboard_customize_rounded;
              color = const Color(0xFF7C3AED);
            } else if (action.contains('KEY') || action.contains('LICENSE')) {
              icon = Icons.vpn_key_rounded;
              color = const Color(0xFF6B7280);
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(icon, color: color),
                ),
                title: Text(details.isNotEmpty ? details : action),
                subtitle: Text(
                  ['By $userName', _formatDateTime(timestamp)].join(' • '),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPlatformReleasesPage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_isLoadingPlatformData)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Platform Releases',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            FilledButton.icon(
              onPressed: () => _showCreateEditReleaseDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Release'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_adminReleases.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No releases found. Click Add Release to create one.',
                ),
              ),
            ),
          )
        else
          ..._adminReleases.map((rel) {
            final id = (rel['id'] ?? rel['_id'] ?? '').toString();
            final version = (rel['version'] ?? '').toString();
            final platform = (rel['platform'] ?? 'all')
                .toString()
                .toUpperCase();
            final channel = (rel['channel'] ?? 'stable')
                .toString()
                .toUpperCase();
            final downloadUrl =
                (rel['downloadUrl'] ?? rel['download_url'] ?? '').toString();
            final releaseNotes =
                (rel['releaseNotes'] ?? rel['release_notes'] ?? '').toString();
            final published = rel['published'] ?? true;
            final dateVal =
                rel['releaseDate'] ??
                rel['release_date'] ??
                rel['created_at'] ??
                '';
            final timestamp =
                DateTime.tryParse(dateVal.toString()) ?? DateTime.now();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.rocket_launch_rounded,
                            size: 18,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Version $version',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            platform,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: channel == 'STABLE'
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            channel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: channel == 'STABLE'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: published
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            published ? 'Published' : 'Draft',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: published
                                  ? Colors.green
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (releaseNotes.isNotEmpty) ...[
                      const Text(
                        'Release Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(releaseNotes),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Download URL: $downloadUrl',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Release Date: ${_formatDateTime(timestamp)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Copy Download URL',
                          onPressed: downloadUrl.isEmpty
                              ? null
                              : () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: downloadUrl),
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Download URL copied to clipboard',
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                        ),
                        IconButton(
                          tooltip: 'Edit Release',
                          onPressed: () => _showCreateEditReleaseDialog(rel),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: 'Delete Release',
                          onPressed: () => _confirmDeleteRelease(id, version),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showCreateEditReleaseDialog([
    Map<String, dynamic>? existingRelease,
  ]) async {
    final isEditing = existingRelease != null;
    final id = existingRelease != null
        ? (existingRelease['id'] ?? existingRelease['_id'] ?? '').toString()
        : '';
    final versionCtrl = TextEditingController(
      text: existingRelease != null
          ? (existingRelease['version'] ?? '').toString()
          : '',
    );
    final urlCtrl = TextEditingController(
      text: existingRelease != null
          ? (existingRelease['downloadUrl'] ??
                    existingRelease['download_url'] ??
                    '')
                .toString()
          : '',
    );
    final notesCtrl = TextEditingController(
      text: existingRelease != null
          ? (existingRelease['releaseNotes'] ??
                    existingRelease['release_notes'] ??
                    '')
                .toString()
          : '',
    );

    String selectedPlatform = existingRelease != null
        ? (existingRelease['platform'] ?? 'windows').toString().toLowerCase()
        : 'windows';
    String selectedChannel = existingRelease != null
        ? (existingRelease['channel'] ?? 'stable').toString().toLowerCase()
        : 'stable';
    bool published = existingRelease != null
        ? (existingRelease['published'] ?? true)
        : true;

    final platformOptions = ['windows', 'mac', 'linux', 'android'];
    final channelOptions = ['stable', 'beta'];

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Platform Release' : 'Add Platform Release',
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: versionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Version (e.g. 1.0.4)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedPlatform,
                        decoration: const InputDecoration(
                          labelText: 'Platform OS',
                        ),
                        items: platformOptions
                            .map(
                              (p) => DropdownMenuItem<String>(
                                value: p,
                                child: Text(p.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setDialogState(() => selectedPlatform = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedChannel,
                        decoration: const InputDecoration(
                          labelText: 'Release Channel',
                        ),
                        items: channelOptions
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setDialogState(() => selectedChannel = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Download Package URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: published,
                        onChanged: (val) =>
                            setDialogState(() => published = val),
                        title: const Text('Publish Immediately'),
                        subtitle: const Text(
                          'If disabled, this release will remain as a draft.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Release Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save Release'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final data = {
      'version': versionCtrl.text.trim(),
      'platform': selectedPlatform,
      'channel': selectedChannel,
      'downloadUrl': urlCtrl.text.trim(),
      'releaseNotes': notesCtrl.text.trim(),
      'published': published,
    };

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      dynamic res;
      if (isEditing) {
        res = await authService.updateAdminRelease(id, data);
      } else {
        res = await authService.createAdminRelease(data);
      }
      if (res != null) {
        await _loadStoreLogins();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Release saved successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to save release',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving release: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  Future<void> _confirmDeleteRelease(String id, String version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Release'),
        content: Text(
          'Are you sure you want to delete platform release version "$version"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      final success = await authService.deleteAdminRelease(id);
      if (success) {
        await _loadStoreLogins();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Release deleted successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to delete release',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting release: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  Future<void> _showGenerateOfflineKeyDialog(Map<String, dynamic> entry) async {
    final tenantId = (entry['tenant_id'] ?? entry['tenantId'] ?? '')
        .toString()
        .trim();
    if (tenantId.isEmpty) return;

    final planOptions = _adminPlans.isNotEmpty
        ? _adminPlans
        : [
            {'planId': 'free', 'name': 'Free'},
            {'planId': 'trial', 'name': 'Trial'},
            {'planId': 'starter', 'name': 'Starter'},
            {'planId': 'growth', 'name': 'Growth'},
            {'planId': 'enterprise', 'name': 'Enterprise'},
          ];
    String selectedPlanId = planOptions.first['planId'] ?? 'free';
    final daysController = TextEditingController(text: '365');

    final generate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Generate Offline License Key'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This will generate a license key that the POS client can validate locally without an internet connection.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPlanId,
                      decoration: const InputDecoration(labelText: 'Plan Tier'),
                      items: planOptions
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: (p['planId'] ?? '').toString(),
                              child: Text((p['name'] ?? '').toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedPlanId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Validity Period (Days)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Generate Key'),
                ),
              ],
            );
          },
        );
      },
    );

    if (generate != true) return;

    final days = int.tryParse(daysController.text.trim()) ?? 365;

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    final result = await authService.generateAdminOfflineKey(
      tenantId: tenantId,
      planId: selectedPlanId,
      days: days,
    );
    await _loadStoreLogins();

    if (!mounted) return;

    if (result == null || result['offline_license_key'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authService.lastActionError ?? 'Failed to generate offline key',
          ),
        ),
      );
      return;
    }

    final generatedKey = result['offline_license_key'].toString();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Key Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Here is the generated offline license key:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                generatedKey,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Copy this key and paste it into the POS client in offline setup mode.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: generatedKey));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offline key copied to clipboard'),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Copy & Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStoreCard(Map<String, dynamic> entry) {
    final fields = _platformStoreFieldMap(entry);
    final tenantId = fields['tenantId'] as String;
    final storeName = fields['storeName'] as String;
    final ownerEmail = fields['ownerEmail'] as String;
    final active = _platformStoreIsActive(entry);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(
                      0xFF7C3AED,
                    ).withValues(alpha: 0.16),
                    child: Text(
                      storeName.isNotEmpty ? storeName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Tenant: $tenantId'),
                        Text('Owner: $ownerEmail'),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _platformStoreStatusColor(
                        entry,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _platformStoreStatusLabel(entry),
                      style: TextStyle(
                        color: _platformStoreStatusColor(entry),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                    label: Text('Plan: ${fields['planName']}'),
                  ),
                  Chip(
                    avatar: Icon(
                      entry['sync_enabled'] == false
                          ? Icons.cloud_off_rounded
                          : Icons.cloud_done_rounded,
                      size: 16,
                    ),
                    label: Text(
                      entry['sync_enabled'] == false
                          ? 'Offline Mode'
                          : 'Cloud Sync',
                    ),
                  ),
                  if (fields['nextPaymentDue'] != null)
                    Chip(
                      avatar: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                      ),
                      label: Text(
                        'Expires: ${fields['nextPaymentDue'].toIso8601String().split('T').first}',
                      ),
                    )
                  else if (fields['trialEndsAt'] != null)
                    Chip(
                      avatar: const Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 16,
                      ),
                      label: Text(
                        'Trial Ends: ${fields['trialEndsAt'].toIso8601String().split('T').first}',
                      ),
                    ),
                  if (entry['offline_license_key'] != null &&
                      entry['offline_license_key'].toString().isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.vpn_key_rounded, size: 16),
                      label: const Text('Offline Key Generated'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showAssignPlanDialog(entry),
                    icon: const Icon(Icons.dashboard_customize_rounded),
                    label: const Text('Assign Plan'),
                  ),
                  if (active)
                    OutlinedButton.icon(
                      onPressed: () => _confirmDeactivateStore(entry),
                      icon: const Icon(Icons.pause_circle_outline),
                      label: const Text('Suspend'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => _showReactivateDialog(tenantId),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Reactivate'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _showGenerateOfflineKeyDialog(entry),
                    icon: const Icon(Icons.vpn_key_rounded),
                    label: const Text('Offline Key'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showEditStoreDialog(entry),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDeleteStore(entry),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy Activation Code',
                    onPressed:
                        (entry['activation_code'] ??
                                entry['activationCode'] ??
                                '')
                            .toString()
                            .trim()
                            .isEmpty
                        ? null
                        : () => _copyActivationCode(
                            (entry['activation_code'] ??
                                    entry['activationCode'] ??
                                    '')
                                .toString(),
                          ),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Browser Launch Helper ───────────────────────────────────────────────
  Future<void> _launchUrl(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd.exe', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  // ─── Platform QR Payments Page ───────────────────────────────────────────
  Widget _buildPlatformQrPaymentsPage() {
    final payments = List<Map<String, dynamic>>.from(
      _adminQrPaymentsData['payments'] ?? [],
    );
    final totalSessions = _adminQrPaymentsData['total'] ?? 0;
    final totalAmount =
        double.tryParse(
          (_adminQrPaymentsData['total_amount'] ?? 0.0).toString(),
        ) ??
        0.0;
    final paidAmount =
        double.tryParse(
          (_adminQrPaymentsData['paid_amount'] ?? 0.0).toString(),
        ) ??
        0.0;

    int countPaid = 0,
        countPending = 0,
        countFailed = 0,
        countExpired = 0,
        countCancelled = 0;
    for (final p in payments) {
      final status = (p['status'] ?? '').toString().toUpperCase();
      if (status == 'PAID')
        countPaid++;
      else if (status == 'PENDING')
        countPending++;
      else if (status == 'FAILED')
        countFailed++;
      else if (status == 'EXPIRED')
        countExpired++;
      else if (status == 'CANCELLED')
        countCancelled++;
    }

    final filteredPayments = _selectedQrStatus == 'ALL'
        ? payments
        : payments
              .where(
                (p) =>
                    (p['status'] ?? '').toString().toUpperCase() ==
                    _selectedQrStatus,
              )
              .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_isLoadingPlatformData)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(),
          ),
        Text(
          'Platform QR Payments',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Track all QR payment sessions created across shops, including status, references, and provider details.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        // QR Stats Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 600;
            final cardChildren = [
              _buildStatCard(
                'Sessions',
                '$totalSessions',
                Icons.phone_android_rounded,
                Colors.purple,
              ),
              _buildStatCard(
                'Total Amount',
                'Rs ${totalAmount.toStringAsFixed(2)}',
                Icons.credit_card_rounded,
                Colors.blue,
              ),
              _buildStatCard(
                'Paid Amount',
                'Rs ${paidAmount.toStringAsFixed(2)}',
                Icons.check_circle_rounded,
                Colors.green,
              ),
            ];
            return isSmall
                ? Column(
                    children: cardChildren
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: c,
                          ),
                        )
                        .toList(),
                  )
                : Row(
                    children: cardChildren
                        .map(
                          (c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: c,
                            ),
                          ),
                        )
                        .toList(),
                  );
          },
        ),
        const SizedBox(height: 24),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill('ALL', 'All Sessions (${payments.length})'),
              _buildFilterPill('PAID', 'Paid ($countPaid)'),
              _buildFilterPill('PENDING', 'Pending ($countPending)'),
              _buildFilterPill('FAILED', 'Failed ($countFailed)'),
              _buildFilterPill('EXPIRED', 'Expired ($countExpired)'),
              _buildFilterPill('CANCELLED', 'Cancelled ($countCancelled)'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filteredPayments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No QR payment sessions found')),
            ),
          )
        else
          ...filteredPayments.map((p) {
            final storeName = (p['store_name'] ?? p['storeName'] ?? '')
                .toString();
            final paymentMethod =
                (p['payment_method'] ?? p['paymentMethod'] ?? '').toString();
            final status = (p['status'] ?? '').toString().toUpperCase();
            final orderId = (p['order_id'] ?? p['orderId'] ?? '').toString();
            final amount =
                double.tryParse((p['amount'] ?? 0).toString()) ?? 0.0;
            final customerType = (p['customer_type'] ?? p['customerType'] ?? '')
                .toString();
            final reference = (p['reference'] ?? '').toString();
            final qrReference = (p['qr_reference'] ?? p['qrReference'] ?? '')
                .toString();
            final saleId = (p['sale_id'] ?? p['saleId'] ?? '').toString();
            final method = (p['method'] ?? '').toString();
            final dateStr = p['created_at'] ?? p['createdAt'] ?? '';
            final timestamp =
                DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
            final statusMsg = (p['status_msg'] ?? p['statusMsg'] ?? '')
                .toString();

            Color statusColor = Colors.amber;
            if (status == 'PAID') statusColor = Colors.green;
            if (status == 'FAILED' || status == 'CANCELLED')
              statusColor = Colors.red;
            if (status == 'EXPIRED') statusColor = Colors.grey;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      paymentMethod,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Order ID: $orderId',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rs ${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: status == 'PAID'
                                ? Colors.green
                                : Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    if (customerType.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        customerType,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        'Ref: $reference | QR Ref: $qrReference | Sale ID: $saleId | Method: $method | Created: ${_formatDateTime(timestamp)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    if (statusMsg.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        statusMsg,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusMsg.toLowerCase().contains('success')
                              ? Colors.green
                              : Colors.orange[800],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      color: color.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String status, String label) {
    final active = _selectedQrStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedQrStatus = status);
          }
        },
      ),
    );
  }

  // ─── Platform Docs Actions ───────────────────────────────────────────────
  Future<void> _togglePublishDoc(Map<String, dynamic> doc) async {
    final id = (doc['id'] ?? doc['_id'] ?? '').toString();
    final currentStatus = (doc['status'] ?? 'DRAFT').toString();
    final nextStatus = currentStatus == 'PUBLISHED' ? 'DRAFT' : 'PUBLISHED';

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      final updated = await authService.updateAdminDoc(id, {
        'status': nextStatus,
      });
      if (updated != null) {
        await _loadStoreLogins();
        if (!mounted) return;
        setState(() {
          _selectedDoc = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document status updated to $nextStatus')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to update document',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating document: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  Future<void> _confirmDeleteDoc(Map<String, dynamic> doc) async {
    final id = (doc['id'] ?? doc['_id'] ?? '').toString();
    final title = (doc['title'] ?? '').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete document "$title"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      final success = await authService.deleteAdminDoc(id);
      if (success) {
        await _loadStoreLogins();
        if (!mounted) return;
        setState(() {
          _selectedDoc = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to delete document',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting document: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  Future<void> _showCreateEditDocDialog([Map<String, dynamic>? doc]) async {
    final isEditing = doc != null;
    final id = doc != null ? (doc['id'] ?? doc['_id'] ?? '').toString() : '';

    final titleCtrl = TextEditingController(
      text: doc != null ? (doc['title'] ?? '').toString() : '',
    );
    final sectionCtrl = TextEditingController(
      text: doc != null ? (doc['section'] ?? '').toString() : 'Getting Started',
    );
    final contentCtrl = TextEditingController(
      text: doc != null ? (doc['content'] ?? '').toString() : '',
    );
    final rolesCtrl = TextEditingController(
      text: doc != null && doc['roles'] != null
          ? List<String>.from(doc['roles']).join(', ')
          : '',
    );
    String audience = doc != null
        ? (doc['audience'] ?? 'All Users').toString()
        : 'All Users';
    bool publishInstantly = doc != null ? (doc['status'] == 'PUBLISHED') : true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Document' : 'New Document'),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Document Title *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: sectionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Section / Folder *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: audience,
                        decoration: const InputDecoration(
                          labelText: 'Audience',
                        ),
                        items: ['All Users', 'Owners', 'Staff'].map((a) {
                          return DropdownMenuItem(value: a, child: Text(a));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => audience = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: rolesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Roles (comma separated)',
                          hintText: 'e.g. role-restricted, admin-only',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentCtrl,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Document Content (Markdown) *',
                          alignLabelWithHint: true,
                          hintText:
                              'Use Markdown syntax: # Heading, * Bullets, etc.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Publish instantly'),
                        value: publishInstantly,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => publishInstantly = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final title = titleCtrl.text.trim();
    final section = sectionCtrl.text.trim();
    final content = contentCtrl.text;
    final roles = rolesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (title.isEmpty || section.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields')),
      );
      return;
    }

    final payload = {
      'title': title,
      'section': section,
      'content': content,
      'audience': audience,
      'roles': roles,
      'status': publishInstantly ? 'PUBLISHED' : 'DRAFT',
    };

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      Map<String, dynamic>? result;
      if (isEditing) {
        result = await authService.updateAdminDoc(id, payload);
      } else {
        result = await authService.createAdminDoc(payload);
      }

      if (result != null) {
        await _loadStoreLogins();
        if (!mounted) return;
        setState(() {
          _selectedDoc = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Document updated successfully'
                  : 'Document created successfully',
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to save document',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving document: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  // ─── Platform Docs Page ──────────────────────────────────────────────────
  Widget _buildPlatformDocsPage() {
    final sectionsSet = _adminDocs
        .map((d) => (d['section'] ?? '').toString())
        .toSet();
    final draftsCount = _adminDocs.where((d) => d['status'] == 'DRAFT').length;

    // Filter documents
    final searchVal = _platformSearchController.text.trim().toLowerCase();
    var filtered = _adminDocs;
    if (_selectedDocSection != 'ALL') {
      filtered = filtered
          .where((d) => (d['section'] ?? '').toString() == _selectedDocSection)
          .toList();
    }
    if (searchVal.isNotEmpty) {
      filtered = filtered
          .where(
            (d) =>
                (d['title'] ?? '').toString().toLowerCase().contains(
                  searchVal,
                ) ||
                (d['content'] ?? '').toString().toLowerCase().contains(
                  searchVal,
                ) ||
                (d['section'] ?? '').toString().toLowerCase().contains(
                  searchVal,
                ),
          )
          .toList();
    }

    // Group by section
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final d in filtered) {
      final sec = (d['section'] ?? '').toString();
      grouped.putIfAbsent(sec, () => []).add(d);
    }

    return Column(
      children: [
        if (_isLoadingPlatformData) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documentation Studio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build structured guides with markdown, linked topics, and inline media.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _showCreateEditDocDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Document'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5B21B6),
                ),
              ),
            ],
          ),
        ),

        // Stats summary row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Docs',
                  '${_adminDocs.length}',
                  Icons.description_rounded,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Sections',
                  '${sectionsSet.length}',
                  Icons.folder_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Drafts',
                  '$draftsCount',
                  Icons.edit_note_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section Filters and Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _platformSearchController,
                  decoration: const InputDecoration(
                    hintText: 'Search documentation...',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Section badge filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All sections'),
                selected: _selectedDocSection == 'ALL',
                onSelected: (sel) {
                  if (sel) setState(() => _selectedDocSection = 'ALL');
                },
              ),
              const SizedBox(width: 8),
              ...sectionsSet.map((sec) {
                final count = _adminDocs
                    .where((d) => (d['section'] ?? '').toString() == sec)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$sec ($count)'),
                    selected: _selectedDocSection == sec,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedDocSection = sec);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dual pane content layout
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Panel: Topics list
                Card(
                  child: SizedBox(
                    width: 320,
                    child: grouped.isEmpty
                        ? const Center(
                            child: Text('No documents matching filter'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: grouped.length,
                            itemBuilder: (context, index) {
                              final sectionName = grouped.keys.elementAt(index);
                              final sectionDocs = grouped[sectionName]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.folder_open_rounded,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          sectionName.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600],
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...sectionDocs.map((doc) {
                                    final isSelected =
                                        _selectedDoc != null &&
                                        (_selectedDoc!['id'] ??
                                                _selectedDoc!['_id']) ==
                                            (doc['id'] ?? doc['_id']);
                                    final title = (doc['title'] ?? '')
                                        .toString();
                                    final status = (doc['status'] ?? '')
                                        .toString();
                                    return ListTile(
                                      title: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? const Color(0xFF5B21B6)
                                              : null,
                                        ),
                                      ),
                                      subtitle: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: status == 'PUBLISHED'
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                      dense: true,
                                      selected: isSelected,
                                      selectedTileColor: const Color(
                                        0xFFEDE9FE,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedDoc = doc;
                                        });
                                      },
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Right Panel: Document Viewer
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _selectedDoc == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description_rounded,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Select a document from the left pane to view or edit',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (_selectedDoc!['section'] ?? '')
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[500],
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            (_selectedDoc!['title'] ?? '')
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Chip(
                                                label: Text(
                                                  (_selectedDoc!['audience'] ??
                                                          'All Users')
                                                      .toString(),
                                                ),
                                                backgroundColor:
                                                    Colors.blue[50],
                                              ),
                                              Chip(
                                                label: Text(
                                                  (_selectedDoc!['status'] ??
                                                          'DRAFT')
                                                      .toString(),
                                                ),
                                                backgroundColor:
                                                    _selectedDoc!['status'] ==
                                                        'PUBLISHED'
                                                    ? Colors.green[50]
                                                    : Colors.amber[50],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _showCreateEditDocDialog(
                                                _selectedDoc,
                                              ),
                                          icon: const Icon(
                                            Icons.edit_rounded,
                                            size: 14,
                                          ),
                                          label: const Text('Edit'),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _togglePublishDoc(_selectedDoc!),
                                          icon: Icon(
                                            _selectedDoc!['status'] ==
                                                    'PUBLISHED'
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            size: 14,
                                          ),
                                          label: Text(
                                            _selectedDoc!['status'] ==
                                                    'PUBLISHED'
                                                ? 'Unpublish'
                                                : 'Publish',
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed: () =>
                                              _confirmDeleteDoc(_selectedDoc!),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                          ),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),

                                // Document content
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _buildMarkdownContent(
                                      (_selectedDoc!['content'] ?? '')
                                          .toString(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.substring(2),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              line.substring(3),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              line.substring(4),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else if (line.startsWith('* ') || line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(line.substring(2))),
              ],
            ),
          ),
        );
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final match = RegExp(r'^(\d+\.) (.*)$').firstMatch(line);
        if (match != null) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${match.group(1)} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(child: Text(match.group(2)!)),
                ],
              ),
            ),
          );
        }
      } else {
        widgets.add(
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(line)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // ─── Platform Tutorials Actions ──────────────────────────────────────────
  Future<void> _togglePublishTutorial(Map<String, dynamic> tut) async {
    final id = (tut['id'] ?? tut['_id'] ?? '').toString();
    final currentStatus = (tut['status'] ?? 'DRAFT').toString();
    final nextStatus = currentStatus == 'PUBLISHED' ? 'DRAFT' : 'PUBLISHED';

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      final updated = await authService.updateAdminTutorial(id, {
        'status': nextStatus,
      });
      if (updated != null) {
        await _loadStoreLogins();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tutorial status updated to $nextStatus')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to update tutorial',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating tutorial: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  Future<void> _confirmDeleteTutorial(Map<String, dynamic> tut) async {
    final id = (tut['id'] ?? tut['_id'] ?? '').toString();
    final title = (tut['title'] ?? '').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tutorial'),
        content: Text(
          'Are you sure you want to delete tutorial "$title"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      final success = await authService.deleteAdminTutorial(id);
      if (success) {
        await _loadStoreLogins();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutorial deleted successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to delete tutorial',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting tutorial: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  Future<void> _showCreateEditTutorialDialog([
    Map<String, dynamic>? tut,
  ]) async {
    final isEditing = tut != null;
    final id = tut != null ? (tut['id'] ?? tut['_id'] ?? '').toString() : '';

    final titleCtrl = TextEditingController(
      text: tut != null ? (tut['title'] ?? '').toString() : '',
    );
    final videoUrlCtrl = TextEditingController(
      text: tut != null
          ? (tut['videoUrl'] ?? tut['video_url'] ?? '').toString()
          : 'https://www.youtube.com/embed/dQw4w9WgXcQ',
    );
    final thumbUrlCtrl = TextEditingController(
      text: tut != null
          ? (tut['thumbnailUrl'] ?? tut['thumbnail_url'] ?? '').toString()
          : '',
    );
    final descCtrl = TextEditingController(
      text: tut != null ? (tut['description'] ?? '').toString() : '',
    );
    String audience = tut != null
        ? (tut['audience'] ?? 'All Users').toString()
        : 'All Users';
    bool publishInstantly = tut != null ? (tut['status'] == 'PUBLISHED') : true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Tutorial' : 'New Tutorial'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tutorial Title *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: audience,
                        decoration: const InputDecoration(
                          labelText: 'Audience Target',
                        ),
                        items: ['All Users', 'Owners', 'Staff'].map((a) {
                          return DropdownMenuItem(value: a, child: Text(a));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => audience = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: videoUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Video URL / Embed Link *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: thumbUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Thumbnail / Cover Image URL',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Publish instantly'),
                        value: publishInstantly,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => publishInstantly = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final title = titleCtrl.text.trim();
    final videoUrl = videoUrlCtrl.text.trim();
    final thumbnailUrl = thumbUrlCtrl.text.trim();
    final description = descCtrl.text.trim();

    if (title.isEmpty || videoUrl.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields')),
      );
      return;
    }

    final payload = {
      'title': title,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'description': description,
      'audience': audience,
      'status': publishInstantly ? 'PUBLISHED' : 'DRAFT',
    };

    setState(() => _isLoadingPlatformData = true);
    final authService = context.read<AuthService>();
    try {
      Map<String, dynamic>? result;
      if (isEditing) {
        result = await authService.updateAdminTutorial(id, payload);
      } else {
        result = await authService.createAdminTutorial(payload);
      }

      if (result != null) {
        await _loadStoreLogins();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Tutorial updated successfully'
                  : 'Tutorial created successfully',
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authService.lastActionError ?? 'Failed to save tutorial',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving tutorial: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlatformData = false);
      }
    }
  }

  // ─── Platform Tutorials Page ─────────────────────────────────────────────
  Widget _buildPlatformTutorialsPage() {
    final searchVal = _platformSearchController.text.trim().toLowerCase();
    var filtered = _adminTutorials;
    if (_selectedTutAudience != 'ALL') {
      filtered = filtered
          .where(
            (t) => (t['audience'] ?? '').toString() == _selectedTutAudience,
          )
          .toList();
    }
    if (searchVal.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                (t['title'] ?? '').toString().toLowerCase().contains(
                  searchVal,
                ) ||
                (t['description'] ?? '').toString().toLowerCase().contains(
                  searchVal,
                ),
          )
          .toList();
    }

    return Column(
      children: [
        if (_isLoadingPlatformData) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tutorials Admin',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create and target tutorials for owners, staff, or everyone.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _showCreateEditTutorialDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Tutorial'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5B21B6),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _platformSearchController,
            decoration: const InputDecoration(
              hintText: 'Search tutorials...',
              prefixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),

        // Audience target pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Audiences'),
                selected: _selectedTutAudience == 'ALL',
                onSelected: (sel) {
                  if (sel) setState(() => _selectedTutAudience = 'ALL');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All Users'),
                selected: _selectedTutAudience == 'All Users',
                onSelected: (sel) {
                  if (sel) setState(() => _selectedTutAudience = 'All Users');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Owners'),
                selected: _selectedTutAudience == 'Owners',
                onSelected: (sel) {
                  if (sel) setState(() => _selectedTutAudience = 'Owners');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Staff'),
                selected: _selectedTutAudience == 'Staff',
                onSelected: (sel) {
                  if (sel) setState(() => _selectedTutAudience = 'Staff');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tutorials Grid
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No video tutorials found'))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    mainAxisExtent: 350,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    final title = (t['title'] ?? '').toString();
                    final desc = (t['description'] ?? '').toString();
                    final audience = (t['audience'] ?? 'All Users').toString();
                    final status = (t['status'] ?? 'DRAFT').toString();
                    final videoUrl = (t['video_url'] ?? t['videoUrl'] ?? '')
                        .toString();
                    final thumbnailUrl =
                        (t['thumbnail_url'] ?? t['thumbnailUrl'] ?? '')
                            .toString();

                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Video cover image
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                thumbnailUrl.isNotEmpty
                                    ? Image.network(
                                        thumbnailUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildVideoFallbackCover(),
                                      )
                                    : _buildVideoFallbackCover(),
                                Container(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  child: Center(
                                    child: Material(
                                      type: MaterialType.circle,
                                      color: Colors.white,
                                      elevation: 4,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        onTap: () => _launchUrl(videoUrl),
                                        child: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            color: Color(0xFF7C3AED),
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF7C3AED,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        audience,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: status == 'PUBLISHED'
                                            ? Colors.green.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.amber.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: status == 'PUBLISHED'
                                              ? Colors.green
                                              : Colors.amber[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _launchUrl(videoUrl),
                                      icon: const Icon(
                                        Icons.play_circle_outline_rounded,
                                        size: 14,
                                      ),
                                      label: const Text('Watch'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF5B21B6,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                          ),
                                          onPressed: () =>
                                              _showCreateEditTutorialDialog(t),
                                        ),
                                        IconButton(
                                          tooltip: status == 'PUBLISHED'
                                              ? 'Hide'
                                              : 'Publish',
                                          icon: Icon(
                                            status == 'PUBLISHED'
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded,
                                            size: 16,
                                          ),
                                          onPressed: () =>
                                              _togglePublishTutorial(t),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _confirmDeleteTutorial(t),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVideoFallbackCover() {
    return Container(
      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.video_library_rounded,
          color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
          size: 48,
        ),
      ),
    );
  }

  // ─── Platform Support Desk Page ──────────────────────────────────────────
  Widget _buildPlatformSupportPage() {
    return _PlatformSupportPage(onLaunchUrl: _launchUrl);
  }

  // ─── Platform About Page ─────────────────────────────────────────────────
  Widget _buildPlatformAboutPage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'About',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Application information, software updates, and licensing details.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'SB',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'StoreBuddy Admin Panel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cloud POS Platform Administration Suite',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Version', 'v7.0.1'),
                            const SizedBox(height: 4),
                            _buildInfoRow('Platform', 'WINDOWS'),
                            const SizedBox(height: 4),
                            _buildInfoRow('Channel', 'Stable'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Updates Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.sync_rounded,
                                color: Color(0xFF7C3AED),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Updates',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Your software is checking for updates...',
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Text(
                              'Check Now',
                              style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              color: Color(0xFF065F46),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'v7.0.2 available',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065F46),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Bug fix for authentication and sync queue',
                                    style: TextStyle(
                                      color: const Color(0xFF047857),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Downloading StoreBuddy v7.0.2 update...',
                                    ),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                              ),
                              child: const Text('Download Update'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Shop License Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFF7C3AED),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Shop',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildShopDetailRow('Name', 'StoreBuddy Platform Admin'),
                      const Divider(height: 16),
                      _buildShopDetailRow('ID', 'platform'),
                      const Divider(height: 16),
                      _buildShopDetailRow('Device ID', 'system-server-node'),
                      const Divider(height: 16),
                      _buildShopDetailRow(
                        'Status',
                        'Activated',
                        isStatus: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildShopDetailRow(
    String label,
    String value, {
    bool isStatus = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontFamily: (label == 'ID' || label == 'Device ID')
                  ? 'monospace'
                  : null,
              fontWeight: (label == 'Name' || isStatus)
                  ? FontWeight.bold
                  : null,
              color: isStatus ? Colors.green : null,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Platform Contact Page ───────────────────────────────────────────────
  Widget _buildPlatformContactPage() {
    return _PlatformContactPage(onLaunchUrl: _launchUrl);
  }

  Widget _buildPlatformAdminPanel(AuthAuthenticated state) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;
        final body = Container(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0A1018)
              : const Color(0xFFF7F1E8),
          child: Builder(
            builder: (context) {
              switch (_selectedPlatformNavKey) {
                case 'dashboard':
                  return _buildPlatformOverviewPage();
                case 'restaurants':
                  return _buildPlatformShopsPage();
                case 'plans':
                  return _buildPlatformPlansPage();
                case 'users':
                  return _buildPlatformUsersPage();
                case 'activity':
                  return _buildPlatformActivityPage();
                case 'qrPayments':
                  return _buildPlatformQrPaymentsPage();
                case 'releases':
                  return _buildPlatformReleasesPage();
                case 'documentation':
                  return _buildPlatformDocsPage();
                case 'tutorials':
                  return _buildPlatformTutorialsPage();
                case 'support':
                  return _buildPlatformSupportPage();
                case 'about':
                  return _buildPlatformAboutPage();
                case 'contact':
                  return _buildPlatformContactPage();
                default:
                  return _buildPlatformOverviewPage();
              }
            },
          ),
        );

        if (!compact) {
          return SafeArea(
            child: Row(
              children: [
                _buildPlatformSidebar(state, compact: false),
                Expanded(
                  child: Column(
                    children: [
                      _buildPlatformTopBar(state, compact: false),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: Scaffold(
            key: _platformShellScaffoldKey,
            backgroundColor: colorScheme.surface,
            drawer: Drawer(
              width: 292,
              child: _buildPlatformSidebar(state, compact: true),
            ),
            body: Column(
              children: [
                _buildPlatformTopBar(
                  state,
                  compact: true,
                  onOpenMenu: () =>
                      _platformShellScaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreShell(AuthAuthenticated state) {
    _ensureTenantScope(state.user.tenantId);
    _currentUserRole = state.user.role;
    _currentUserId =
        _resolveLinkedEmployeeIdForUser(
          userId: state.user.id,
          email: state.user.email,
        ) ??
        state.user.id;
    _currentUserName = state.user.name;
    _currentUserEmail = state.user.email;
    // Auto-fill agent name in POS initially when empty (for locked mode, agent login, or general default)
    if (_posAgentName.isEmpty) {
      _posAgentName = _currentUserName;
      _posAgentId = _currentUserId;
      _posAgentNameController.text = _currentUserName;
    }
    // Force/lock it ONLY if _agentCommissionLockToLogin is explicitly enabled
    if (_agentCommissionLockToLogin) {
      if (_posAgentName != _currentUserName || _posAgentId != _currentUserId) {
        _posAgentName = _currentUserName;
        _posAgentId = _currentUserId;
        _posAgentNameController.text = _currentUserName;
      }
    }
    final accessibleLocations = _accessibleLocationNames(state);
    if (!_isOwner &&
        !_isAdmin &&
        !_isManager &&
        accessibleLocations.length <= 1 &&
        _selectedLocationScope == _allLocationsLabel) {
      _selectedLocationScope = accessibleLocations.isNotEmpty
          ? accessibleLocations.first
          : (_storeLocation.trim().isEmpty ? 'Main Branch' : _storeLocation);
    }
    if (_selectedLocationScope != _allLocationsLabel) {
      final match = accessibleLocations.firstWhere(
        (loc) =>
            loc.trim().toLowerCase() ==
            _selectedLocationScope.trim().toLowerCase(),
        orElse: () => '',
      );
      if (match.isEmpty) {
        _selectedLocationScope = accessibleLocations.isNotEmpty
            ? accessibleLocations.first
            : (_storeLocation.trim().isEmpty ? 'Main Branch' : _storeLocation);
      } else {
        _selectedLocationScope = match;
      }
    }
    final visibleNavItems = _visibleNavItems();
    if (!visibleNavItems.any((item) => item.key == _selectedNavKey)) {
      _selectedNavKey = visibleNavItems.first.key;
    }
    _ensureSyncService(state.user.tenantId);
    _ensureRepositories(state.user.tenantId);
    if (!_syncQueueLoaded) {
      _syncQueueLoaded = true;
      _refreshPendingSyncQueue();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellBackground = isDark
        ? const Color(0xFF070B14)
        : const Color(0xFFF5F6FF);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLayout = constraints.maxWidth < 1100;

        if (!compactLayout) {
          return Row(
            children: [
              _buildSidebar(state),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(state),
                    Expanded(
                      child: Container(
                        color: shellBackground,
                        child: _buildStorePageContent(state),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return SafeArea(
          child: Scaffold(
            key: _mobileShellScaffoldKey,
            backgroundColor: shellBackground,
            drawer: Drawer(width: 292, child: _buildMobileSidebar(state)),
            body: Column(
              children: [
                _buildTopBar(
                  state,
                  compact: true,
                  onOpenMenu: () {
                    _mobileShellScaffoldKey.currentState?.openDrawer();
                  },
                ),
                Expanded(
                  child: Container(
                    color: shellBackground,
                    child: _buildStorePageContent(state),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(AuthAuthenticated state) {
    final visibleNavItems = _visibleNavItems();
    const sidebarWidth = 256.0;
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        gradient: UiGradients.sidebar,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        children: [
          // ── Logo / Brand Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF070B14),
                  AppTheme.brandIndigo.withValues(alpha: 0.18),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            child: Row(
              children: [
                // Gradient icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: UiGradients.brand,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: UiShadows.glow,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) =>
                            UiGradients.brand.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                        child: const Text(
                          'Store Buddy',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'POS Management',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Navigation items ──
          Expanded(
            child: ListView.builder(
              itemCount: visibleNavItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final item = visibleNavItems[index];
                final selected = item.key == _selectedNavKey;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: AnimatedContainer(
                    duration: UiAnimations.standard,
                    curve: UiAnimations.easeOut,
                    decoration: BoxDecoration(
                      gradient: selected ? UiGradients.brand : null,
                      borderRadius: BorderRadius.circular(UiRadius.md),
                      boxShadow: selected ? UiShadows.glow : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(UiRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(UiRadius.md),
                        onTap: () => setState(() => _selectedNavKey = item.key),
                        overlayColor: WidgetStateProperty.all(
                          Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 17,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  _navItemLabel(item),
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // ── User card / logout ──
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            child: Material(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(UiRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(UiRadius.md),
                onTap: () {
                  _disposeTenantScopedResources();
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: UiGradients.brand,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          state.user.name.isNotEmpty
                              ? state.user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              state.user.role.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar(AuthAuthenticated state) {
    final visibleNavItems = _visibleNavItems();
    final colorScheme = Theme.of(context).colorScheme;
    final sidebarAccent = colorScheme.tertiary;
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF101827)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1220), Color(0xFF172036)],
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: sidebarAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: const Color(0xFF101827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Buddy',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Shop operations',
                        style: TextStyle(
                          color: Color(0xFF9AA3B2),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: visibleNavItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final item = visibleNavItems[index];
                final selected = item.key == _selectedNavKey;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected
                        ? sidebarAccent.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() => _selectedNavKey = item.key);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: selected
                                  ? sidebarAccent
                                  : const Color(0xFFB7C0CE),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _navItemLabel(item),
                                style: TextStyle(
                                  color: selected
                                      ? sidebarAccent
                                      : const Color(0xFFD6DCE5),
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Material(
              color: const Color(0xFF162033),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).pop();
                  _disposeTenantScopedResources();
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: sidebarAccent,
                        child: Text(
                          state.user.name.isNotEmpty
                              ? state.user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Color(0xFF101827),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              state.user.role.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF9AA3B2),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationScopePicker(AuthAuthenticated state) {
    final colorScheme = Theme.of(context).colorScheme;
    final accessibleLocations = _accessibleLocationNames(state);

    if (_isBranchAdmin || accessibleLocations.length == 1) {
      final branchName = accessibleLocations.isNotEmpty
          ? accessibleLocations.first
          : (_storeLocation.isNotEmpty ? _storeLocation : 'Main Branch');
      _selectedLocationScope = branchName;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 16, color: AppTheme.brandIndigo),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                branchName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.lock_outline, size: 13, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      );
    }

    final canViewAll = _isOwner || (_isAdmin && !_isBranchAdmin) || (_isManager && !_isBranchAdmin);
    final options = <String>{
      if (canViewAll || accessibleLocations.length > 1) _allLocationsLabel,
      ...accessibleLocations,
    }.toList();

    final matchingOption = options.firstWhere(
      (opt) =>
          opt.trim().toLowerCase() ==
          _selectedLocationScope.trim().toLowerCase(),
      orElse: () => options.isNotEmpty ? options.first : _storeLocation,
    );
    _selectedLocationScope = matchingOption;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLocationScope,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: options
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedLocationScope = value;
            });
            _persistWorkspaceData();
          },
        ),
      ),
    );
  }

  Widget _buildNotificationBellButton(ColorScheme colorScheme) {
    final relevantNotifs = _notifications.where((n) {
      if (_isOwner ||
          _isAdmin ||
          _selectedLocationScope == _allLocationsLabel ||
          _sameLocationName(_activeLocationForWrites, 'Main Branch')) {
        return true;
      }
      if (n.targetLocation == null || n.targetLocation!.isEmpty) return true;
      return _passesLocationScope(n.targetLocation);
    }).toList();
    final unreadCount = relevantNotifs.where((n) => !n.isRead).length;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => _showNotificationsDialog(relevantNotifs),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface,
              side: BorderSide(color: colorScheme.outline),
              padding: EdgeInsets.zero,
            ),
            icon: Icon(
              unreadCount > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_rounded,
              color: unreadCount > 0
                  ? AppTheme.brandIndigo
                  : colorScheme.onSurface.withValues(alpha: 0.74),
            ),
            tooltip: 'Notifications',
          ),
          if (unreadCount > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(List<_NotificationItem> notifs) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NotificationsDialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return StatefulBuilder(
          builder: (dialogCtx, setLocalState) {
            final theme = Theme.of(ctx);
            final colorScheme = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: math.min(MediaQuery.of(ctx).size.width * 0.9, 520.0),
                  height: math.min(MediaQuery.of(ctx).size.height * 0.8, 620.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined, color: AppTheme.brandIndigo),
                            const SizedBox(width: 10),
                            const Text(
                              'Notifications',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (notifs.any((n) => !n.isRead))
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    for (final n in notifs) {
                                      n.isRead = true;
                                    }
                                  });
                                  setLocalState(() {});
                                  _persistWorkspaceData();
                                },
                                icon: const Icon(Icons.done_all_rounded, size: 16),
                                label: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: notifs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 48,
                                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No notifications yet',
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: notifs.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final item = notifs[idx];
                                  final IconData iconData;
                                  final Color iconColor;
                                  switch (item.type.toLowerCase()) {
                                    case 'transfer':
                                      iconData = Icons.swap_horiz_rounded;
                                      iconColor = Colors.teal;
                                      break;
                                    case 'delivery':
                                      iconData = Icons.local_shipping_outlined;
                                      iconColor = Colors.orange;
                                      break;
                                    case 'sale':
                                      iconData = Icons.receipt_long_outlined;
                                      iconColor = Colors.blue;
                                      break;
                                    default:
                                      iconData = Icons.info_outline_rounded;
                                      iconColor = AppTheme.brandIndigo;
                                  }

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        item.isRead = true;
                                      });
                                      setLocalState(() {});
                                      _persistWorkspaceData();
                                      if (item.type.toLowerCase() == 'transfer') {
                                        Navigator.pop(ctx);
                                        _selectNavByKey('stockTransfers');
                                      } else if (item.type.toLowerCase() == 'delivery' || item.type.toLowerCase() == 'sale') {
                                        Navigator.pop(ctx);
                                        _selectNavByKey('sales');
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: item.isRead
                                            ? Colors.transparent
                                            : AppTheme.brandIndigo.withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: iconColor.withValues(alpha: 0.15),
                                            child: Icon(iconData, size: 18, color: iconColor),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item.title,
                                                        style: TextStyle(
                                                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.message,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!item.isRead) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.brandIndigo,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (notifs.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${notifs.length} notification${notifs.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _notifications.clear();
                                    notifs.clear();
                                  });
                                  setLocalState(() {});
                                  _persistWorkspaceData();
                                },
                                child: const Text(
                                  'Clear all',
                                  style: TextStyle(fontSize: 12, color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar(
    AuthAuthenticated state, {
    bool compact = false,
    VoidCallback? onOpenMenu,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBackground = isDark ? const Color(0xFF111827) : Colors.white;

    if (compact) {
      final pageTitle = _selectedPageTitle();
      final displayName = state.user.name.isEmpty ? 'User' : state.user.name;
      return Container(
        height: 76,
        decoration: BoxDecoration(
          color: barBackground,
          border: Border(bottom: BorderSide(color: colorScheme.outline)),
          boxShadow: UiShadows.light,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: onOpenMenu,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  side: BorderSide(color: colorScheme.outline),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  Icons.menu_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.74),
                ),
                tooltip: 'Open Menu',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Welcome back, $displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: _buildLocationScopePicker(state),
              ),
            ),
            _buildNotificationBellButton(colorScheme),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: () {
                  final nextTheme =
                      Theme.of(context).brightness == Brightness.dark
                      ? 'Light'
                      : 'Dark';
                  setState(() => _uiTheme = nextTheme);
                  _applyUiTheme(nextTheme);
                  _persistWorkspaceData();
                },
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  side: BorderSide(color: colorScheme.outline),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  Icons.dark_mode_outlined,
                  color: colorScheme.onSurface.withValues(alpha: 0.74),
                ),
                tooltip: 'Toggle Theme',
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Account',
              onSelected: (value) {
                if (value == 'logout') {
                  _disposeTenantScopedResources();
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  value: 'role',
                  child: Text(
                    '${state.user.name} (${state.user.role.toUpperCase()})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary,
                child: Text(
                  state.user.name.isNotEmpty
                      ? state.user.name.substring(0, 2).toUpperCase()
                      : 'US',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: UiSize.topBarHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1525) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
          ),
        ),
        boxShadow: isDark ? null : UiShadows.card,
      ),
      child: Column(
        children: [
          // Gradient accent line at top
          Container(
            height: 2,
            decoration: const BoxDecoration(gradient: UiGradients.brand),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) =>
                              UiGradients.brand.createShader(
                                Rect.fromLTWH(
                                  0,
                                  0,
                                  bounds.width,
                                  bounds.height,
                                ),
                              ),
                          child: Text(
                            'Welcome back, ${state.user.name.isEmpty ? 'User' : state.user.name.split(' ').first}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 14 : 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    SizedBox(
                      width: 200,
                      child: _buildLocationScopePicker(state),
                    ),
                    const SizedBox(width: 10),
                  ],
                  // Theme toggle
                  _topBarIconBtn(
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    tooltip: 'Toggle Theme',
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onTap: () {
                      final nextTheme =
                          Theme.of(context).brightness == Brightness.dark
                          ? 'Light'
                          : 'Dark';
                      setState(() => _uiTheme = nextTheme);
                      _applyUiTheme(nextTheme);
                      _persistWorkspaceData();
                    },
                  ),
                  const SizedBox(width: 8),
                  // User avatar
                  PopupMenuButton<String>(
                    tooltip: 'Account',
                    onSelected: (value) {
                      if (value == 'logout') {
                        _disposeTenantScopedResources();
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        enabled: false,
                        value: 'role',
                        child: Text(
                          '${state.user.name} (${state.user.role.toUpperCase()})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: UiGradients.brand,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: UiShadows.glow,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        state.user.name.isNotEmpty
                            ? state.user.name
                                  .substring(
                                    0,
                                    state.user.name.length >= 2 ? 2 : 1,
                                  )
                                  .toUpperCase()
                            : 'US',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBarIconBtn({
    required IconData icon,
    required String tooltip,
    required ColorScheme colorScheme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiRadius.md),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF1F3FF),
            borderRadius: BorderRadius.circular(UiRadius.md),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFDDE1F5),
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color: colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }

  String _selectedPageTitle() {
    final fallback = _storeNavItems.first;
    return _storeNavItems
        .firstWhere(
          (item) => item.key == _selectedNavKey,
          orElse: () => fallback,
        )
        .label;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              if (state.user.role == 'platform_admin') {
                return _buildPlatformAdminPanel(state);
              }
              if (_isSubscriptionExpired) {
                return _buildSubscriptionExpiredScreen(state);
              }
              return _buildStoreShell(state);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildSubscriptionExpiredScreen(AuthAuthenticated state) {
    final status = _subscriptionStatusData ?? {};
    final storeName = status['store_name']?.toString().isNotEmpty == true
        ? status['store_name'].toString()
        : (state.user.name.isNotEmpty ? state.user.name : 'Store Terminal');
    final planName = status['plan_name']?.toString() ?? 'Trial / Subscription';
    final hotline = status['hotline']?.toString() ?? '+94 72 954 5538';
    final supportEmail =
        status['support_email']?.toString() ?? 'contact@bizparkstudio.lk';
    final isOffline =
        status['status'] == 'OFFLINE' || status['sync_enabled'] == false;
    final expiresAtStr = status['plan_expires_at']?.toString();
    final expiresAt =
        expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
    final formattedDate = expiresAt != null
        ? '${expiresAt.year}-${expiresAt.month.toString().padLeft(2, '0')}-${expiresAt.day.toString().padLeft(2, '0')}'
        : 'Expired';

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1525),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  blurRadius: 36,
                  offset: const Offset(0, 8),
                ),
                ...UiShadows.elevated,
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Color(0xFFEF4444),
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Subscription / Trial Expired',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Access to StoreBuddy POS for "$storeName" has expired ($formattedDate). Terminal checkout and operations are locked until reactivated by the administrator.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E2D45)),
                  ),
                  child: Column(
                    children: [
                      _expiredDetailRow('Shop / Terminal', storeName),
                      const Divider(color: Color(0xFF1E2D45), height: 16),
                      _expiredDetailRow('Tenant ID', state.user.tenantId),
                      const Divider(color: Color(0xFF1E2D45), height: 16),
                      _expiredDetailRow('Plan Tier', planName),
                      const Divider(color: Color(0xFF1E2D45), height: 16),
                      _expiredDetailRow(
                        'Expired On',
                        formattedDate,
                        isAlert: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (isOffline) ...[
                  const Text(
                    'Activate Lifetime Offline License (Rs. 70,000)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _offlineLicenseInputController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Enter SBOFF-TENANTID-OFFLINE-YYYYMMDD-CHECKSUM',
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF111827),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                      ),
                      prefixIcon: const Icon(
                        Icons.key_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isCheckingSubscription
                        ? null
                        : () async {
                            final key =
                                _offlineLicenseInputController.text.trim();
                            if (key.isEmpty) return;
                            setState(() => _isCheckingSubscription = true);
                            final authService = context.read<AuthService>();
                            final ok = await authService.activateOfflineLicense(
                              key,
                            );
                            if (!mounted) return;
                            setState(() => _isCheckingSubscription = false);
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Offline Lifetime License Activated! Resuming POS...',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              await _checkSubscriptionAndEnforceExpiry();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    authService.lastActionError ??
                                        'Invalid license key',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.verified_user_rounded, size: 16),
                    label: const Text('Verify & Activate License'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Platform Administration to Renew:',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_in_talk_rounded,
                            color: Colors.greenAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hotline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: hotline));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hotline copied to clipboard!'),
                                ),
                              );
                            },
                            child: const Text(
                              'Copy',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            color: Colors.blueAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            supportEmail,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: supportEmail),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email copied to clipboard!'),
                                ),
                              );
                            },
                            child: const Text(
                              'Copy',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!isOffline) ...[
                  ElevatedButton.icon(
                    onPressed: _isCheckingSubscription
                        ? null
                        : () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Checking subscription status with server...',
                                ),
                              ),
                            );
                            await _checkSubscriptionAndEnforceExpiry();
                            if (!mounted) return;
                            if (!_isSubscriptionExpired) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Account reactivated! Welcome back.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Account is still expired. Please contact admin to activate.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                    icon: _isCheckingSubscription
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      _isCheckingSubscription
                          ? 'Checking...'
                          : 'Check Server Activation Status',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () {
                    _disposeTenantScopedResources();
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Sign Out / Switch Store'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    side: const BorderSide(color: Color(0xFF1E2D45)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _expiredDetailRow(String label, String value, {bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: isAlert ? const Color(0xFFEF4444) : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final String key;
  final String label;
  final IconData icon;

  const _NavItem({required this.key, required this.label, required this.icon});
}

class _PlatformNavItem {
  final String key;
  final String label;
  final IconData icon;

  const _PlatformNavItem(this.key, this.label, this.icon);
}

class _PlatformPlanSpec {
  final String name;
  final String badge;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final int trialDays;
  final Color accentColor;

  const _PlatformPlanSpec({
    required this.name,
    required this.badge,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.trialDays,
    required this.accentColor,
  });
}

class _PlatformPlanAssignment {
  final String tenantId;
  final String storeName;
  final String planName;
  final String billingCycle;
  final bool paymentReceived;
  final double paymentAmount;
  final String paymentReference;
  final String adminNote;
  final DateTime nextPaymentDue;
  final DateTime assignedAt;

  const _PlatformPlanAssignment({
    required this.tenantId,
    required this.storeName,
    required this.planName,
    required this.billingCycle,
    required this.paymentReceived,
    required this.paymentAmount,
    required this.paymentReference,
    required this.adminNote,
    required this.nextPaymentDue,
    required this.assignedAt,
  });
}

class _PlatformActivityEntry {
  final String title;
  final String? detail;
  final IconData icon;
  final Color color;
  final DateTime timestamp;

  const _PlatformActivityEntry({
    required this.title,
    this.detail,
    required this.icon,
    required this.color,
    required this.timestamp,
  });
}

class _UserPermissionOption {
  final String label;
  final Set<String> navKeys;

  const _UserPermissionOption(this.label, this.navKeys);

  String get viewPermission => label.toUpperCase();
  String get editPermission => '${label.toUpperCase()}:EDIT';
  String get deletePermission => '${label.toUpperCase()}:DELETE';
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double? width;
  final String subtitle;
  final String deltaText;
  final String deltaHint;
  final Color deltaColor;
  final Gradient? iconGradient;
  final VoidCallback? onViewMore;

  final double? numericValue;
  final String Function(double)? formatValue;

  const _MetricCard({
    required this.title,
    this.value = '',
    this.numericValue,
    this.formatValue,
    required this.icon,
    this.width,
    this.subtitle = '',
    this.deltaText = '+0.0%',
    this.deltaHint = 'vs last period',
    this.deltaColor = const Color(0xFF10B981),
    this.iconGradient,
    this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveWidth =
        width ?? (screenWidth < UiBreakpoints.phone ? double.infinity : 250);
    final gradient = iconGradient ?? UiGradients.brand;

    return SizedBox(
      width: effectiveWidth,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(UiRadius.lg),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE8EAFF),
          ),
          boxShadow: UiShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UiRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient top accent line
              Container(
                height: 3,
                decoration: BoxDecoration(gradient: gradient),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.62,
                              ),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Gradient icon container
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(UiRadius.md),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (numericValue != null && formatValue != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: numericValue),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, child) {
                          return Text(
                            formatValue!(val),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Delta chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: deltaColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(UiRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            deltaText,
                            style: TextStyle(
                              color: deltaColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            deltaHint,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.50,
                              ),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (onViewMore != null) ...[
                const Divider(height: 1),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onViewMore,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View More',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDialogResult {
  final _ProductItem product;
  final Map<String, double>? locationStocks; // locationName -> stock
  final Map<String, List<String>>?
  locationImeis; // locationName -> list of imeis
  _ProductDialogResult({
    required this.product,
    this.locationStocks,
    this.locationImeis,
  });
}

class _BarcodeLabelEntry {
  final _ProductItem product;
  final String? imei;
  _BarcodeLabelEntry({required this.product, this.imei});
}

class _ProductItem {
  final String id;
  String name;
  String locationId;
  String category;
  String barcode;
  String measureUnit;
  String productType;
  String description;
  double? costPrice;
  int warrantyMonths;
  DateTime? expiryDate;
  String expiryReminderMode;
  int expiryReminderDays;
  Map<String, dynamic> attributeValues;
  double price;
  double minPrice;
  double stock;
  double minStock;
  String supplierId;
  String? imeis;
  String? imageUrl;

  bool get allowLooseSales => attributeValues['allowLooseSales'] == true;
  set allowLooseSales(bool val) => attributeValues['allowLooseSales'] = val;

  String get secondaryUnit {
    final u = attributeValues['secondaryUnit']?.toString().trim();
    return (u != null && u.isNotEmpty) ? u.toUpperCase() : 'KG';
  }
  set secondaryUnit(String val) => attributeValues['secondaryUnit'] = val;

  double get unitConversionRatio {
    final v = attributeValues['unitConversionRatio'];
    if (v is num && v > 0) return v.toDouble();
    return 1.0;
  }
  set unitConversionRatio(double val) =>
      attributeValues['unitConversionRatio'] = val;

  double? get secondaryPrice {
    final v = attributeValues['secondaryPrice'];
    if (v is num && v > 0) return v.toDouble();
    return null;
  }
  set secondaryPrice(double? val) => attributeValues['secondaryPrice'] = val;

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

  _ProductItem({
    required this.id,
    required this.name,
    this.locationId = '',
    required this.category,
    this.barcode = '',
    this.measureUnit = 'PIECE',
    this.productType = 'PRODUCT',
    this.description = '',
    this.costPrice,
    this.warrantyMonths = 0,
    this.expiryDate,
    this.expiryReminderMode = 'WEEK',
    this.expiryReminderDays = 7,
    this.attributeValues = const {},
    required this.price,
    this.minPrice = 0.0,
    required this.stock,
    required this.minStock,
    this.supplierId = '',
    this.imeis,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'locationId': locationId,
      'category': category,
      'barcode': barcode,
      'measureUnit': measureUnit,
      'unitOfMeasure': measureUnit,
      'productType': productType,
      'type': productType,
      'description': description,
      'costPrice': costPrice,
      'warrantyMonths': warrantyMonths,
      'expiryDate': expiryDate?.toIso8601String(),
      'expiryReminderMode': expiryReminderMode,
      'expiryReminderDays': expiryReminderDays,
      'attributeValues': attributeValues,
      'price': price,
      'minPrice': minPrice,
      'stock': stock,
      'minStock': minStock,
      'supplierId': supplierId,
      'imeis': imeis,
      'imageUrl': imageUrl,
      'allowLooseSales': allowLooseSales,
      'secondaryUnit': secondaryUnit,
      'unitConversionRatio': unitConversionRatio,
      'secondaryPrice': secondaryPrice,
    };
  }

  factory _ProductItem.fromJson(Map<String, dynamic> json) {
    final attrs = Map<String, dynamic>.from(
      json['attributeValues'] as Map<String, dynamic>? ?? {},
    );
    if (json.containsKey('allowLooseSales')) {
      attrs['allowLooseSales'] = json['allowLooseSales'] == true;
    }
    if (json.containsKey('secondaryUnit')) {
      attrs['secondaryUnit'] = json['secondaryUnit'];
    }
    if (json.containsKey('unitConversionRatio')) {
      attrs['unitConversionRatio'] =
          (json['unitConversionRatio'] as num?)?.toDouble() ?? 1.0;
    }
    if (json.containsKey('secondaryPrice')) {
      attrs['secondaryPrice'] = (json['secondaryPrice'] as num?)?.toDouble();
    }

    final id = (json['id'] ?? json['_id'] ?? '').toString();
    return _ProductItem(
      id: id,
      name: (json['name'] ?? '').toString(),
      locationId: (json['locationId'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      barcode: (json['barcode'] ?? id).toString(),
      measureUnit: (json['measureUnit'] ?? json['unitOfMeasure'] ?? 'PIECE').toString().toUpperCase(),
      productType: (json['productType'] ?? json['type'] ?? 'PRODUCT').toString().toUpperCase(),
      description: (json['description'] ?? '').toString(),
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt() ?? 0,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      expiryReminderMode: (json['expiryReminderMode'] ?? 'WEEK')
          .toString()
          .toUpperCase(),
      expiryReminderDays: (json['expiryReminderDays'] as num?)?.toInt() ?? 7,
      attributeValues: attrs,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
      minStock: (json['minStock'] as num?)?.toDouble() ?? 0.0,
      supplierId: (json['supplierId'] ?? '').toString(),
      imeis: json['imeis']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class _CategoryAttributeDef {
  final String name;
  final String type;
  final bool required;
  final List<String> options;

  const _CategoryAttributeDef({
    required this.name,
    required this.type,
    this.required = false,
    this.options = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      'options': options,
    };
  }

  factory _CategoryAttributeDef.fromJson(Map<String, dynamic> json) {
    return _CategoryAttributeDef(
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      required: json['required'] == true,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((option) => option.toString())
          .where((option) => option.trim().isNotEmpty)
          .toList(),
    );
  }
}

class _CategoryAttributeDraft {
  final TextEditingController nameController;
  final TextEditingController optionsController;
  String type;
  bool required;

  _CategoryAttributeDraft({
    String name = '',
    this.type = 'text',
    this.required = false,
    List<String> options = const [],
  }) : nameController = TextEditingController(text: name),
       optionsController = TextEditingController(text: options.join(', '));
}

class _CategoryCreateResult {
  final String name;
  final List<_CategoryAttributeDef> attributes;

  const _CategoryCreateResult({required this.name, required this.attributes});
}

class _ReturnItem {
  final String id;
  final String saleId;
  final String customerId;
  final String rmaNumber;
  final String productId;
  String productName;
  String customerName;
  String reason;
  String supplier;
  double amount;
  double qty;
  double subtotalAmount;
  double discountAmount;
  double taxAmount;
  String condition;
  bool cashImpact;
  String? cashAdjustmentId;
  String refundMethod;
  String status;
  String? exchangeSaleId;
  final String createdAt;
  String updatedAt;

  _ReturnItem({
    required this.id,
    this.saleId = '',
    this.customerId = '',
    required this.rmaNumber,
    this.productId = '',
    required this.productName,
    required this.customerName,
    required this.reason,
    this.supplier = '',
    required this.amount,
    this.qty = 1.0,
    this.subtotalAmount = 0.0,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.condition = 'Good',
    this.cashImpact = false,
    this.cashAdjustmentId,
    this.refundMethod = 'CASH',
    required this.status,
    this.exchangeSaleId,
    required this.createdAt,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'customerId': customerId,
      'rmaNumber': rmaNumber,
      'productId': productId,
      'productName': productName,
      'customerName': customerName,
      'reason': reason,
      'supplier': supplier,
      'amount': amount,
      'qty': qty,
      'subtotalAmount': subtotalAmount,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'condition': condition,
      'cashImpact': cashImpact,
      'cashAdjustmentId': cashAdjustmentId,
      'refundMethod': refundMethod,
      'status': status,
      'exchangeSaleId': exchangeSaleId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory _ReturnItem.fromJson(Map<String, dynamic> json) {
    return _ReturnItem(
      id: (json['id'] ?? '').toString(),
      saleId: (json['saleId'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      rmaNumber: (json['rmaNumber'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      supplier: (json['supplier'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      qty: (json['qty'] as num?)?.toDouble() ?? 1.0,
      subtotalAmount: (json['subtotalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      condition: (json['condition'] ?? 'Good').toString(),
      cashImpact: json['cashImpact'] == true,
      cashAdjustmentId: json['cashAdjustmentId']?.toString(),
      refundMethod: (json['refundMethod'] ?? 'CASH').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      exchangeSaleId: json['exchangeSaleId']?.toString(),
      createdAt: (json['createdAt'] ?? DateTime.now().toString()).toString(),
      updatedAt:
          (json['updatedAt'] ?? json['createdAt'] ?? DateTime.now().toString())
              .toString(),
    );
  }
}

class _DamagedInventoryItem {
  final String id;
  final String productId;
  final String productName;
  final double qty;
  final String reason;
  final String condition;
  final String returnId;
  String status; // QUARANTINE, SCRAPPED, RETURNED_TO_SUPPLIER
  final String createdAt;

  _DamagedInventoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.reason,
    this.condition = 'Damaged',
    required this.returnId,
    this.status = 'QUARANTINE',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'qty': qty,
    'reason': reason,
    'condition': condition,
    'returnId': returnId,
    'status': status,
    'createdAt': createdAt,
  };

  factory _DamagedInventoryItem.fromJson(Map<String, dynamic> json) =>
      _DamagedInventoryItem(
        id: (json['id'] ?? '').toString(),
        productId: (json['productId'] ?? '').toString(),
        productName: (json['productName'] ?? '').toString(),
        qty: (json['qty'] as num?)?.toDouble() ?? 1.0,
        reason: (json['reason'] ?? '').toString(),
        condition: (json['condition'] ?? 'Damaged').toString(),
        returnId: (json['returnId'] ?? '').toString(),
        status: (json['status'] ?? 'QUARANTINE').toString(),
        createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String())
            .toString(),
      );
}

class _CashTransactionItem {
  final String id;
  final String type; // IN or OUT
  final String referenceType; // RETURN, SALE, EXPENSE
  final String referenceId;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String note;
  final String createdAt;

  _CashTransactionItem({
    required this.id,
    required this.type,
    required this.referenceType,
    required this.referenceId,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'referenceType': referenceType,
    'referenceId': referenceId,
    'amount': amount,
    'balanceBefore': balanceBefore,
    'balanceAfter': balanceAfter,
    'note': note,
    'createdAt': createdAt,
  };

  factory _CashTransactionItem.fromJson(Map<String, dynamic> json) =>
      _CashTransactionItem(
        id: (json['id'] ?? '').toString(),
        type: (json['type'] ?? 'OUT').toString(),
        referenceType: (json['referenceType'] ?? '').toString(),
        referenceId: (json['referenceId'] ?? '').toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0.0,
        balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0.0,
        note: (json['note'] ?? '').toString(),
        createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String())
            .toString(),
      );
}

class _MobileReloadRecord {
  final String id;
  final String operator; // e.g., Dialog, Mobitel, Hutch, Airtel, SLT
  final String phoneNumber;
  final double amount;
  final double commission;
  final DateTime createdAt;

  _MobileReloadRecord({
    required this.id,
    required this.operator,
    required this.phoneNumber,
    required this.amount,
    required this.commission,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'operator': operator,
    'phoneNumber': phoneNumber,
    'amount': amount,
    'commission': commission,
    'createdAt': createdAt.toIso8601String(),
  };

  factory _MobileReloadRecord.fromJson(Map<String, dynamic> json) =>
      _MobileReloadRecord(
        id: (json['id'] ?? '').toString(),
        operator: (json['operator'] ?? '').toString(),
        phoneNumber: (json['phoneNumber'] ?? '').toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class _CashierSession {
  final String id;
  final String userId;
  final String userName;
  final DateTime openingTime;
  DateTime? closingTime;
  final double openingCash;
  double? closingCash;
  double expectedCash;
  double cashSales;
  double cashExpenses;
  double cashTransfers;
  double? actualCash;
  double? difference;
  double keptCash;
  String status; // 'OPEN' or 'CLOSED'
  final String locationId;

  _CashierSession({
    required this.id,
    required this.userId,
    required this.userName,
    required this.openingTime,
    this.closingTime,
    required this.openingCash,
    this.closingCash,
    this.expectedCash = 0.0,
    this.cashSales = 0.0,
    this.cashExpenses = 0.0,
    this.cashTransfers = 0.0,
    this.actualCash,
    this.difference,
    this.keptCash = 0.0,
    required this.status,
    required this.locationId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'openingTime': openingTime.toIso8601String(),
    'closingTime': closingTime?.toIso8601String(),
    'openingCash': openingCash,
    'closingCash': closingCash,
    'expectedCash': expectedCash,
    'cashSales': cashSales,
    'cashExpenses': cashExpenses,
    'cashTransfers': cashTransfers,
    'actualCash': actualCash,
    'difference': difference,
    'keptCash': keptCash,
    'status': status,
    'locationId': locationId,
  };

  factory _CashierSession.fromJson(Map<String, dynamic> json) =>
      _CashierSession(
        id: (json['id'] ?? '').toString(),
        userId: (json['userId'] ?? '').toString(),
        userName: (json['userName'] ?? '').toString(),
        openingTime:
            DateTime.tryParse(json['openingTime'] ?? '') ?? DateTime.now(),
        closingTime: json['closingTime'] != null
            ? DateTime.tryParse(json['closingTime'])
            : null,
        openingCash: (json['openingCash'] as num?)?.toDouble() ?? 0.0,
        closingCash: (json['closingCash'] as num?)?.toDouble(),
        expectedCash: (json['expectedCash'] as num?)?.toDouble() ?? 0.0,
        cashSales: (json['cashSales'] as num?)?.toDouble() ?? 0.0,
        cashExpenses: (json['cashExpenses'] as num?)?.toDouble() ?? 0.0,
        cashTransfers: (json['cashTransfers'] as num?)?.toDouble() ?? 0.0,
        actualCash: (json['actualCash'] as num?)?.toDouble(),
        difference: (json['difference'] as num?)?.toDouble(),
        keptCash: (json['keptCash'] as num?)?.toDouble() ?? 0.0,
        status: (json['status'] ?? 'OPEN').toString(),
        locationId: (json['locationId'] ?? '').toString(),
      );
}

class _BankTransaction {
  final String id;
  final String
  type; // 'OPEN_SHIFT_WITHDRAW', 'CLOSE_SHIFT_DEPOSIT', 'EXPENSE_PAYMENT', 'PO_PAYMENT', 'MANUAL_DEPOSIT', 'MANUAL_WITHDRAW'
  final double amount;
  final String referenceId;
  final String notes;
  final DateTime createdAt;

  _BankTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.referenceId,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'referenceId': referenceId,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory _BankTransaction.fromJson(Map<String, dynamic> json) =>
      _BankTransaction(
        id: (json['id'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        referenceId: (json['referenceId'] ?? '').toString(),
        notes: (json['notes'] ?? '').toString(),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class _CreditPaymentItem {
  final String id;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String note;
  final DateTime createdAt;

  _CreditPaymentItem({
    required this.id,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _CreditPaymentItem.fromJson(Map<String, dynamic> json) {
    return _CreditPaymentItem(
      id: (json['id'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      note: (json['note'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class _CreditSaleEntry {
  final String id;
  final String saleId;
  final String invoiceNumber;
  final String locationId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double customerOutstandingBefore;
  final double customerOutstandingAfter;
  final double subtotal;
  final double tax;
  final double total;
  final double amountPaidOnSale;
  double outstandingAmount;
  final String paymentMethod;
  final List<String> items;
  final DateTime createdAt;

  _CreditSaleEntry({
    required this.id,
    required this.saleId,
    this.invoiceNumber = '',
    this.locationId = '',
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.customerOutstandingBefore = 0,
    this.customerOutstandingAfter = 0,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.amountPaidOnSale,
    required this.outstandingAmount,
    required this.paymentMethod,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'invoiceNumber': invoiceNumber,
      'locationId': locationId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerOutstandingBefore': customerOutstandingBefore,
      'customerOutstandingAfter': customerOutstandingAfter,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'amountPaidOnSale': amountPaidOnSale,
      'outstandingAmount': outstandingAmount,
      'paymentMethod': paymentMethod,
      'items': items,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _CreditSaleEntry.fromJson(Map<String, dynamic> json) {
    return _CreditSaleEntry(
      id: (json['id'] ?? '').toString(),
      saleId: (json['saleId'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      locationId: (json['locationId'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      customerAddress: (json['customerAddress'] ?? '').toString(),
      customerOutstandingBefore:
          (json['customerOutstandingBefore'] as num?)?.toDouble() ?? 0,
      customerOutstandingAfter:
          (json['customerOutstandingAfter'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      amountPaidOnSale: (json['amountPaidOnSale'] as num?)?.toDouble() ?? 0,
      outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class _CustomerItem {
  final String id;
  String name;
  String locationId;
  String vehicleNumber;
  String phone;
  String email;
  String address;
  String notes;
  double creditLimit;
  int creditDueDays;
  double currentBalance;
  int loyaltyPoints;
  double discountPercent;
  DateTime? birthday;
  String customerType;
  String shippingAddress;

  _CustomerItem({
    required this.id,
    required this.name,
    this.locationId = '',
    this.vehicleNumber = '',
    required this.phone,
    required this.email,
    this.address = '',
    this.notes = '',
    this.creditLimit = 0,
    this.creditDueDays = 30,
    this.currentBalance = 0,
    this.loyaltyPoints = 0,
    this.customerType = 'RETAIL',
    this.discountPercent = 0.0,
    this.birthday,
    this.shippingAddress = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'locationId': locationId,
      'vehicleNumber': vehicleNumber,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'creditLimit': creditLimit,
      'creditDueDays': creditDueDays,
      'currentBalance': currentBalance,
      'loyaltyPoints': loyaltyPoints,
      'customerType': customerType,
      'discountPercent': discountPercent,
      'birthday': birthday?.toIso8601String(),
      'shippingAddress': shippingAddress,
    };
  }

  factory _CustomerItem.fromJson(Map<String, dynamic> json) {
    return _CustomerItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      locationId: (json['locationId'] ?? '').toString(),
      vehicleNumber: (json['vehicleNumber'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      creditDueDays: (json['creditDueDays'] as num?)?.toInt() ?? 30,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
      customerType: json['customerType'] as String? ?? 'RETAIL',
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'].toString())
          : null,
      shippingAddress: (json['shippingAddress'] ?? '').toString(),
    );
  }
}

class _AttendanceRecordItem {
  final String id;
  String employeeId;
  String employeeName;
  DateTime date;
  String status;
  String clockIn;
  String clockOut;
  double regularHours;
  double overtimeHours;
  String notes;
  bool isHoliday;

  _AttendanceRecordItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.status,
    required this.clockIn,
    required this.clockOut,
    required this.regularHours,
    required this.overtimeHours,
    this.notes = '',
    this.isHoliday = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date.toIso8601String(),
      'status': status,
      'clockIn': clockIn,
      'clockOut': clockOut,
      'regularHours': regularHours,
      'overtimeHours': overtimeHours,
      'notes': notes,
      'isHoliday': isHoliday,
    };
  }

  factory _AttendanceRecordItem.fromJson(Map<String, dynamic> json) {
    return _AttendanceRecordItem(
      id: (json['id'] ?? '').toString(),
      employeeId: (json['employeeId'] ?? '').toString(),
      employeeName: (json['employeeName'] ?? '').toString(),
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      status: (json['status'] ?? 'Present').toString(),
      clockIn: (json['clockIn'] ?? '--:--').toString(),
      clockOut: (json['clockOut'] ?? '--:--').toString(),
      regularHours: (json['regularHours'] as num?)?.toDouble() ?? 0,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
      notes: (json['notes'] ?? '').toString(),
      isHoliday: json['isHoliday'] as bool? ?? false,
    );
  }
}

class _PayrollRecordItem {
  final String id;
  String employeeId;
  String employeeName;
  String paymentType;
  double baseSalary;
  double overtime;
  double bonus;
  double deductions;
  double tax;
  String payPeriodStart;
  String payPeriodEnd;
  String payDate;
  int daysWorked;
  double hoursWorked;
  String notes;
  String status;

  _PayrollRecordItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.paymentType,
    required this.baseSalary,
    this.overtime = 0,
    this.bonus = 0,
    this.deductions = 0,
    this.tax = 0,
    required this.payPeriodStart,
    required this.payPeriodEnd,
    required this.payDate,
    this.daysWorked = 0,
    this.hoursWorked = 0,
    this.notes = '',
    this.status = 'Pending',
  });

  double get grossPay => baseSalary + overtime + bonus;
  double get netPay => grossPay - deductions - tax;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'paymentType': paymentType,
      'baseSalary': baseSalary,
      'overtime': overtime,
      'bonus': bonus,
      'deductions': deductions,
      'tax': tax,
      'payPeriodStart': payPeriodStart,
      'payPeriodEnd': payPeriodEnd,
      'payDate': payDate,
      'daysWorked': daysWorked,
      'hoursWorked': hoursWorked,
      'notes': notes,
      'status': status,
    };
  }

  factory _PayrollRecordItem.fromJson(Map<String, dynamic> json) {
    return _PayrollRecordItem(
      id: (json['id'] ?? '').toString(),
      employeeId: (json['employeeId'] ?? '').toString(),
      employeeName: (json['employeeName'] ?? '').toString(),
      paymentType: (json['paymentType'] ?? 'Monthly').toString(),
      baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 0,
      overtime: (json['overtime'] as num?)?.toDouble() ?? 0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      payPeriodStart: (json['payPeriodStart'] ?? '').toString(),
      payPeriodEnd: (json['payPeriodEnd'] ?? '').toString(),
      payDate: (json['payDate'] ?? '').toString(),
      daysWorked: (json['daysWorked'] as num?)?.toInt() ?? 0,
      hoursWorked: (json['hoursWorked'] as num?)?.toDouble() ?? 0,
      notes: (json['notes'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
    );
  }
}

class _StockAdjustmentItem {
  final String id;
  final String productId;
  final String productName;
  final double delta;
  final double beforeStock;
  final double afterStock;
  final String reason;
  final String performedBy;
  final double? unitCost;
  final double? adjustedStockValue;
  final DateTime createdAt;

  _StockAdjustmentItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.delta,
    required this.beforeStock,
    required this.afterStock,
    required this.reason,
    required this.performedBy,
    this.unitCost,
    this.adjustedStockValue,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'delta': delta,
      'beforeStock': beforeStock,
      'afterStock': afterStock,
      'reason': reason,
      'performedBy': performedBy,
      'unitCost': unitCost,
      'adjustedStockValue': adjustedStockValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _StockAdjustmentItem.fromJson(Map<String, dynamic> json) {
    return _StockAdjustmentItem(
      id: (json['id'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      delta: (json['delta'] as num?)?.toDouble() ?? 0.0,
      beforeStock: (json['beforeStock'] as num?)?.toDouble() ?? 0.0,
      afterStock: (json['afterStock'] as num?)?.toDouble() ?? 0.0,
      reason: (json['reason'] ?? '').toString(),
      performedBy: (json['performedBy'] ?? '').toString(),
      unitCost: (json['unitCost'] as num?)?.toDouble(),
      adjustedStockValue: (json['adjustedStockValue'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class _EmployeeItem {
  final String id;
  String name;
  String role;
  bool active;
  String firstName;
  String lastName;
  String email;
  String phone;
  String position;
  String department;
  String paymentType;
  double baseSalary;
  String hireDate;
  String bankAccount;
  String address;
  String emergencyContact;
  String emergencyPhone;
  String notes;
  List<String> assignedLocations;
  String linkedUserId;
  List<String> permissions;

  _EmployeeItem({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.position = '',
    this.department = '',
    this.paymentType = 'Monthly',
    this.baseSalary = 0,
    this.hireDate = '',
    this.bankAccount = '',
    this.address = '',
    this.emergencyContact = '',
    this.emergencyPhone = '',
    this.notes = '',
    this.assignedLocations = const [],
    this.linkedUserId = '',
    this.permissions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'active': active,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'position': position,
      'department': department,
      'paymentType': paymentType,
      'baseSalary': baseSalary,
      'hireDate': hireDate,
      'bankAccount': bankAccount,
      'address': address,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'notes': notes,
      'assignedLocations': assignedLocations,
      'linkedUserId': linkedUserId,
      'permissions': permissions,
    };
  }

  factory _EmployeeItem.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    final splitName = name.trim().split(RegExp(r'\s+'));
    final inferredFirst = splitName.isEmpty ? '' : splitName.first;
    final inferredLast = splitName.length <= 1
        ? ''
        : splitName.sublist(1).join(' ');
    return _EmployeeItem(
      id: (json['id'] ?? '').toString(),
      name: name,
      role: (json['role'] ?? 'CASHIER').toString(),
      active: json['active'] as bool? ?? true,
      firstName: (json['firstName'] ?? inferredFirst).toString(),
      lastName: (json['lastName'] ?? inferredLast).toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      paymentType: (json['paymentType'] ?? 'Monthly').toString(),
      baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 0,
      hireDate: (json['hireDate'] ?? '').toString(),
      bankAccount: (json['bankAccount'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      emergencyContact: (json['emergencyContact'] ?? '').toString(),
      emergencyPhone: (json['emergencyPhone'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      assignedLocations: (json['assignedLocations'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      linkedUserId: (json['linkedUserId'] ?? '').toString(),
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class _UserItem {
  final String id;
  String name;
  String email;
  String role;
  bool active;
  List<String> permissions;
  List<String> locations;
  String linkedEmployeeId;

  _UserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.permissions = const [],
    this.locations = const [],
    this.linkedEmployeeId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'active': active,
      'permissions': permissions,
      'locations': locations,
      'linkedEmployeeId': linkedEmployeeId,
    };
  }

  factory _UserItem.fromJson(Map<String, dynamic> json) {
    return _UserItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'CASHIER').toString(),
      active: json['active'] as bool? ?? true,
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      locations: (json['locations'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      linkedEmployeeId: (json['linkedEmployeeId'] ?? '').toString(),
    );
  }
}

class _UserDialogResult {
  final _UserItem user;
  final String password;

  _UserDialogResult({required this.user, required this.password});
}

class _LocationItem {
  final String id;
  String name;
  String code;
  String address;
  String city;
  String country;
  String phone;
  String email;
  String openingTime;
  String closingTime;
  bool isActive;
  bool isHeadquarters;

  _LocationItem({
    required this.id,
    required this.name,
    required this.code,
    this.address = '',
    this.city = '',
    this.country = '',
    this.phone = '',
    this.email = '',
    this.openingTime = '09:00 AM',
    this.closingTime = '06:00 PM',
    this.isActive = true,
    this.isHeadquarters = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'city': city,
      'country': country,
      'phone': phone,
      'email': email,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'isActive': isActive,
      'isHeadquarters': isHeadquarters,
    };
  }

  factory _LocationItem.fromJson(Map<String, dynamic> json) {
    return _LocationItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      openingTime: (json['openingTime'] ?? '09:00 AM').toString(),
      closingTime: (json['closingTime'] ?? '06:00 PM').toString(),
      isActive: json['isActive']?.toString().toLowerCase() == 'false'
          ? false
          : true,
      isHeadquarters:
          json['isHeadquarters']?.toString().toLowerCase() == 'true',
    );
  }
}

class _StockTransferLine {
  final String productId;
  final String productName;
  double requestedQty;
  double sentQty;
  double receivedQty;
  double shortageQty;
  String shortageReason;
  bool checked;

  _StockTransferLine({
    required this.productId,
    required this.productName,
    required this.requestedQty,
    required this.sentQty,
    required this.receivedQty,
    this.shortageQty = 0.0,
    this.shortageReason = '',
    required this.checked,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'requestedQty': requestedQty,
      'sentQty': sentQty,
      'receivedQty': receivedQty,
      'shortageQty': shortageQty,
      'shortageReason': shortageReason,
      'checked': checked,
    };
  }

  factory _StockTransferLine.fromJson(Map<String, dynamic> json) {
    return _StockTransferLine(
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      requestedQty: (json['requestedQty'] as num?)?.toDouble() ?? 0.0,
      sentQty: (json['sentQty'] as num?)?.toDouble() ?? 0.0,
      receivedQty: (json['receivedQty'] as num?)?.toDouble() ?? 0.0,
      shortageQty: (json['shortageQty'] as num?)?.toDouble() ?? 0.0,
      shortageReason: (json['shortageReason'] ?? '').toString(),
      checked: json['checked'] as bool? ?? false,
    );
  }
}

class _StockTransferItem {
  final String id;
  String referenceNo;
  String fromLocation;
  String toLocation;
  String reason;
  String notes;
  String status;
  String createdBy;
  DateTime createdAt;
  List<_StockTransferLine> items;

  _StockTransferItem({
    required this.id,
    required this.referenceNo,
    required this.fromLocation,
    required this.toLocation,
    required this.reason,
    required this.notes,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceNo': referenceNo,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'reason': reason,
      'notes': notes,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory _StockTransferItem.fromJson(Map<String, dynamic> json) {
    return _StockTransferItem(
      id: (json['id'] ?? '').toString(),
      referenceNo: (json['referenceNo'] ?? '').toString(),
      fromLocation: (json['fromLocation'] ?? '').toString(),
      toLocation: (json['toLocation'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      status: (json['status'] ?? 'DRAFT').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_StockTransferLine.fromJson)
          .toList(),
    );
  }
}

class _StockRequestLine {
  final String productId;
  String productName;
  double requestedQty;
  double approvedQty;
  String notes;

  _StockRequestLine({
    required this.productId,
    required this.productName,
    required this.requestedQty,
    this.approvedQty = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'requestedQty': requestedQty,
    'approvedQty': approvedQty,
    'notes': notes,
  };

  factory _StockRequestLine.fromJson(Map<String, dynamic> json) => _StockRequestLine(
    productId: (json['productId'] ?? '').toString(),
    productName: (json['productName'] ?? '').toString(),
    requestedQty: (json['requestedQty'] as num?)?.toDouble() ?? 0.0,
    approvedQty: (json['approvedQty'] as num?)?.toDouble() ?? 0.0,
    notes: (json['notes'] ?? '').toString(),
  );
}

class _StockRequestItem {
  final String id;
  String requestNo;
  String fromLocation; // supplying location (e.g. Main Branch)
  String toLocation;   // requesting branch (e.g. Jaffna)
  String reason;
  String notes;
  String responseNotes;
  String status;       // 'PENDING', 'APPROVED', 'PARTIALLY_APPROVED', 'REJECTED', 'TRANSFERRED'
  String requestedBy;
  String? approvedBy;
  DateTime createdAt;
  DateTime? updatedAt;
  String? transferId;
  List<_StockRequestLine> items;

  _StockRequestItem({
    required this.id,
    required this.requestNo,
    required this.fromLocation,
    required this.toLocation,
    required this.reason,
    this.notes = '',
    this.responseNotes = '',
    this.status = 'PENDING',
    required this.requestedBy,
    this.approvedBy,
    required this.createdAt,
    this.updatedAt,
    this.transferId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'requestNo': requestNo,
    'fromLocation': fromLocation,
    'toLocation': toLocation,
    'reason': reason,
    'notes': notes,
    'responseNotes': responseNotes,
    'status': status,
    'requestedBy': requestedBy,
    'approvedBy': approvedBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'transferId': transferId,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory _StockRequestItem.fromJson(Map<String, dynamic> json) => _StockRequestItem(
    id: (json['id'] ?? '').toString(),
    requestNo: (json['requestNo'] ?? '').toString(),
    fromLocation: (json['fromLocation'] ?? '').toString(),
    toLocation: (json['toLocation'] ?? '').toString(),
    reason: (json['reason'] ?? '').toString(),
    notes: (json['notes'] ?? '').toString(),
    responseNotes: (json['responseNotes'] ?? '').toString(),
    status: (json['status'] ?? 'PENDING').toString(),
    requestedBy: (json['requestedBy'] ?? '').toString(),
    approvedBy: json['approvedBy']?.toString(),
    createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    transferId: json['transferId']?.toString(),
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_StockRequestLine.fromJson)
        .toList(),
  );
}

class _NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type; // 'transfer', 'delivery', 'sale', 'system'
  final String? targetLocation;
  final String? referenceId;
  final DateTime createdAt;
  bool isRead;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetLocation,
    this.referenceId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'targetLocation': targetLocation,
    'referenceId': referenceId,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };

  factory _NotificationItem.fromJson(Map<String, dynamic> json) => _NotificationItem(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    message: (json['message'] ?? '').toString(),
    type: (json['type'] ?? 'system').toString(),
    targetLocation: json['targetLocation']?.toString(),
    referenceId: json['referenceId']?.toString(),
    createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    isRead: json['isRead'] as bool? ?? false,
  );
}


class _SettingsTabItem {
  final String key;
  final String label;
  final IconData icon;

  const _SettingsTabItem({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class _SupplierItem {
  final String id;
  String name;
  String contact;
  String email;
  String address;
  String taxId;
  String website;
  String companyName;
  String imagePath;
  String idCardImage1;
  String idCardImage2;
  String notes;

  _SupplierItem({
    required this.id,
    required this.name,
    required this.contact,
    required this.email,
    this.address = '',
    this.taxId = '',
    this.website = '',
    this.companyName = '',
    this.imagePath = '',
    this.idCardImage1 = '',
    this.idCardImage2 = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'email': email,
      'address': address,
      'taxId': taxId,
      'website': website,
      'companyName': companyName,
      'imagePath': imagePath,
      'idCardImage1': idCardImage1,
      'idCardImage2': idCardImage2,
      'notes': notes,
    };
  }

  factory _SupplierItem.fromJson(Map<String, dynamic> json) {
    return _SupplierItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      contact: (json['contact'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      taxId: (json['taxId'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      companyName: (json['companyName'] ?? '').toString(),
      imagePath: (json['imagePath'] ?? '').toString(),
      idCardImage1: (json['idCardImage1'] ?? '').toString(),
      idCardImage2: (json['idCardImage2'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
    );
  }
}

class _CouponItem {
  final String code;
  String description;
  double discountPercent;
  bool active;

  _CouponItem({
    required this.code,
    required this.description,
    required this.discountPercent,
    required this.active,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'discountPercent': discountPercent,
      'active': active,
    };
  }

  factory _CouponItem.fromJson(Map<String, dynamic> json) {
    return _CouponItem(
      code: (json['code'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }
}

class _ServiceJobItem {
  final String id;
  String title;
  String sku;
  String description;
  double defaultPrice;
  bool active;
  String technician;
  bool warranty;
  String status;
  String priority;
  String customerName;
  String customerPhone;
  String customerEmail;
  String scheduledDate;
  String scheduledTime;
  String estimatedDurationMinutes;
  String location;
  String deviceInfo;
  double discount;
  double taxAmount;
  String internalNotes;
  String customerNotes;
  List<String> services;
  List<String> materials;
  String tags;

  _ServiceJobItem({
    required this.id,
    required this.title,
    this.sku = '',
    this.description = '',
    this.defaultPrice = 0,
    this.active = true,
    required this.technician,
    required this.warranty,
    required this.status,
    this.priority = 'NORMAL',
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.scheduledDate = '',
    this.scheduledTime = '',
    this.estimatedDurationMinutes = '',
    this.location = '',
    this.deviceInfo = '',
    this.discount = 0,
    this.taxAmount = 0,
    this.internalNotes = '',
    this.customerNotes = '',
    this.services = const [],
    this.materials = const [],
    this.tags = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'sku': sku,
      'description': description,
      'defaultPrice': defaultPrice,
      'price': defaultPrice,
      'active': active,
      'technician': technician,
      'warranty': warranty,
      'status': status,
      'priority': priority,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'location': location,
      'deviceInfo': deviceInfo,
      'discount': discount,
      'taxAmount': taxAmount,
      'internalNotes': internalNotes,
      'customerNotes': customerNotes,
      'services': services,
      'materials': materials,
      'tags': tags,
    };
  }

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List<dynamic>) {
      return value
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  factory _ServiceJobItem.fromJson(Map<String, dynamic> json) {
    return _ServiceJobItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? json['serviceName'] ?? '')
          .toString(),
      sku: (json['sku'] ?? json['code'] ?? json['id'] ?? '').toString(),
      description: (json['description'] ?? json['notes'] ?? '').toString(),
      defaultPrice:
          (json['defaultPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      active: _readBool(json['active'], fallback: true),
      technician: (json['technician'] ?? '').toString(),
      warranty: _readBool(json['warranty']),
      status: (json['status'] ?? json['state'] ?? 'PENDING').toString(),
      priority: (json['priority'] ?? 'NORMAL').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      customerEmail: (json['customerEmail'] ?? '').toString(),
      scheduledDate: (json['scheduledDate'] ?? '').toString(),
      scheduledTime: (json['scheduledTime'] ?? '').toString(),
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] ?? '')
          .toString(),
      location: (json['location'] ?? '').toString(),
      deviceInfo: (json['deviceInfo'] ?? '').toString(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      internalNotes: (json['internalNotes'] ?? '').toString(),
      customerNotes: (json['customerNotes'] ?? '').toString(),
      services: _readStringList(json['services']),
      materials: _readStringList(json['materials']),
      tags: (json['tags'] ?? '').toString(),
    );
  }
}

class _SaleRecord {
  final String id;
  final String invoiceNumber;
  final String locationId;
  final String customerName;
  final String customerId;
  final String customerPhone;
  final String customerAddress;
  final double customerOutstandingBefore;
  final double customerOutstandingAfter;
  final String employeeId;
  final String cashierName;
  final String paymentMethod;
  final List<_SaleItemSnapshot> items;
  final List<_InstallmentScheduleItem> installmentSchedules;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  double amountPaid;
  double balance;
  final String chequeNumber;
  final double shippingCharges;
  final String agentName;
  final double agentCommission;
  final String agentCommissionType;
  final bool agentCommissionPaid;
  String status;
  String? returnReason;
  final DateTime createdAt;
  String notes;
  final String shippingAddress;
  String? deliveryPersonId;
  String? deliveryPersonName;
  String? deliveryStatus;
  DateTime? deliveredAt;
  String? deliveryOtp;
  DateTime? settledAt;
  String? settledByEmployeeId;
  String? settledByCashierName;

  _SaleRecord({
    required this.id,
    this.invoiceNumber = '',
    this.locationId = '',
    required this.customerName,
    this.customerId = '',
    this.customerPhone = '',
    this.customerAddress = '',
    this.customerOutstandingBefore = 0,
    this.customerOutstandingAfter = 0,
    this.employeeId = '',
    this.cashierName = 'Cashier',
    required this.paymentMethod,
    this.items = const [],
    this.installmentSchedules = const [],
    required this.subtotal,
    required this.tax,
    this.discount = 0.0,
    required this.total,
    required this.amountPaid,
    required this.balance,
    this.chequeNumber = '',
    this.shippingCharges = 0.0,
    this.agentName = '',
    this.agentCommission = 0.0,
    this.agentCommissionType = 'PERCENT',
    this.agentCommissionPaid = false,
    required this.status,
    this.returnReason,
    required this.createdAt,
    this.notes = '',
    this.shippingAddress = '',
    this.deliveryPersonId,
    this.deliveryPersonName,
    this.deliveryStatus,
    this.deliveredAt,
    this.deliveryOtp,
    this.settledAt,
    this.settledByEmployeeId,
    this.settledByCashierName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'locationId': locationId,
      'customerName': customerName,
      'customerId': customerId,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerOutstandingBefore': customerOutstandingBefore,
      'customerOutstandingAfter': customerOutstandingAfter,
      'employeeId': employeeId,
      'cashierName': cashierName,
      'paymentMethod': paymentMethod,
      'items': items.map((e) => e.toJson()).toList(),
      'installmentSchedules': installmentSchedules
          .map((item) => item.toJson())
          .toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'amountPaid': amountPaid,
      'balance': balance,
      'chequeNumber': chequeNumber,
      'shippingCharges': shippingCharges,
      'agentName': agentName,
      'agentCommission': agentCommission,
      'agentCommissionType': agentCommissionType,
      'agentCommissionPaid': agentCommissionPaid,
      'status': status,
      'returnReason': returnReason,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'shippingAddress': shippingAddress,
      'deliveryPersonId': deliveryPersonId,
      'deliveryPersonName': deliveryPersonName,
      'deliveryStatus': deliveryStatus,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'deliveryOtp': deliveryOtp,
      'settledAt': settledAt?.toIso8601String(),
      'settledByEmployeeId': settledByEmployeeId,
      'settledByCashierName': settledByCashierName,
    };
  }

  factory _SaleRecord.fromJson(Map<String, dynamic> json) {
    return _SaleRecord(
      id: (json['id'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      locationId: (json['locationId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      customerAddress: (json['customerAddress'] ?? '').toString(),
      customerOutstandingBefore:
          (json['customerOutstandingBefore'] as num?)?.toDouble() ?? 0,
      customerOutstandingAfter:
          (json['customerOutstandingAfter'] as num?)?.toDouble() ?? 0,
      employeeId: (json['employeeId'] ?? '').toString(),
      cashierName: (json['cashierName'] ?? 'Cashier').toString(),
      paymentMethod: (json['paymentMethod'] ?? 'CASH').toString(),
      items: ((json['items'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_SaleItemSnapshot.fromJson)
          .toList(),
      installmentSchedules:
          ((json['installmentSchedules'] as List<dynamic>?) ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(_InstallmentScheduleItem.fromJson)
              .toList(),
      subtotal:
          (json['subtotal'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      amountPaid:
          (json['amountPaid'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0,
      balance:
          (json['balance'] as num?)?.toDouble() ??
          (((json['total'] as num?)?.toDouble() ?? 0) -
                  ((json['amountPaid'] as num?)?.toDouble() ??
                      (json['total'] as num?)?.toDouble() ??
                      0))
              .clamp(0, double.infinity)
              .toDouble(),
      chequeNumber: (json['chequeNumber'] ?? '').toString(),
      shippingCharges: (json['shippingCharges'] as num?)?.toDouble() ?? 0.0,
      agentName: (json['agentName'] ?? '').toString(),
      agentCommission: (json['agentCommission'] as num?)?.toDouble() ?? 0.0,
      agentCommissionType:
          (json['agentCommissionType'] as String? ?? 'PERCENT'),
      agentCommissionPaid: json['agentCommissionPaid'] as bool? ?? false,
      status: (json['status'] ?? 'COMPLETED').toString(),
      returnReason: json['returnReason']?.toString(),
      notes: (json['notes'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      shippingAddress: (json['shippingAddress'] ?? '').toString(),
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
    );
  }
}

class _SaleItemSnapshot {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final String discountType;
  final double lineTotal;
  final String productType;

  _SaleItemSnapshot({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.discountType = 'FIXED',
    required this.lineTotal,
    this.productType = 'PRODUCT',
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'discountType': discountType,
      'lineTotal': lineTotal,
      'productType': productType,
    };
  }

  factory _SaleItemSnapshot.fromJson(Map<String, dynamic> json) {
    return _SaleItemSnapshot(
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      discountType: (json['discountType'] ?? 'FIXED').toString(),
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      productType: (json['productType'] ?? 'PRODUCT').toString(),
    );
  }
}

class _HeldCart {
  final String id;
  final String? customerId;
  final String? paymentMethod;
  final String? amountPaidText;
  final String? chequeNumber;
  final int? installmentCount;
  final int? installmentIntervalDays;
  final List<DateTime>? installmentDueDates;
  final List<double>? installmentAmounts;
  final bool? applyTax;
  final Map<String, double> items;
  final DateTime createdAt;

  _HeldCart({
    required this.id,
    required this.customerId,
    required this.paymentMethod,
    this.amountPaidText,
    this.chequeNumber,
    this.installmentCount,
    this.installmentIntervalDays,
    this.installmentDueDates,
    this.installmentAmounts,
    this.applyTax,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'paymentMethod': paymentMethod,
      'amountPaidText': amountPaidText,
      'chequeNumber': chequeNumber,
      'installmentCount': installmentCount,
      'installmentIntervalDays': installmentIntervalDays,
      'installmentDueDates': installmentDueDates
          ?.map((d) => d.toIso8601String())
          .toList(),
      'installmentAmounts': installmentAmounts,
      'applyTax': applyTax,
      'items': items,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _HeldCart.fromJson(Map<String, dynamic> json) {
    final rawItems = Map<String, dynamic>.from(json['items'] ?? {});
    final rawDueDates = (json['installmentDueDates'] as List<dynamic>? ?? [])
        .map((item) => DateTime.tryParse(item.toString()))
        .whereType<DateTime>()
        .toList();
    final rawAmounts = (json['installmentAmounts'] as List<dynamic>? ?? [])
        .map((item) => (item as num).toDouble())
        .toList();
    return _HeldCart(
      id: (json['id'] ?? '').toString(),
      customerId: json['customerId']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      amountPaidText: json['amountPaidText']?.toString(),
      chequeNumber: json['chequeNumber']?.toString(),
      installmentCount: (json['installmentCount'] as num?)?.toInt(),
      installmentIntervalDays: (json['installmentIntervalDays'] as num?)
          ?.toInt(),
      installmentDueDates: rawDueDates,
      installmentAmounts: rawAmounts,
      applyTax: json['applyTax'] as bool?,
      items: rawItems.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class _InstallmentPlan {
  final String id;
  final String saleId;
  final String invoiceNumber;
  final String locationId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double totalAmount;
  final double subtotal;
  final double taxAmount;
  final double downPayment;
  double remainingAmount;
  final String paymentMethod;
  final String chequeNumber;
  final int numberOfInstallments;
  final int intervalDays;
  final DateTime createdAt;
  final List<_SaleItemSnapshot> items;
  final List<_InstallmentScheduleItem> schedules;

  _InstallmentPlan({
    required this.id,
    required this.saleId,
    this.invoiceNumber = '',
    this.locationId = '',
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    this.customerAddress = '',
    required this.totalAmount,
    required this.subtotal,
    required this.taxAmount,
    required this.downPayment,
    required this.remainingAmount,
    required this.paymentMethod,
    this.chequeNumber = '',
    required this.numberOfInstallments,
    required this.intervalDays,
    required this.createdAt,
    this.items = const [],
    required this.schedules,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'invoiceNumber': invoiceNumber,
      'locationId': locationId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'downPayment': downPayment,
      'remainingAmount': remainingAmount,
      'paymentMethod': paymentMethod,
      'chequeNumber': chequeNumber,
      'numberOfInstallments': numberOfInstallments,
      'intervalDays': intervalDays,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'schedules': schedules.map((item) => item.toJson()).toList(),
    };
  }

  factory _InstallmentPlan.fromJson(Map<String, dynamic> json) {
    return _InstallmentPlan(
      id: (json['id'] ?? '').toString(),
      saleId: (json['saleId'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      locationId: (json['locationId'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      customerAddress: (json['customerAddress'] ?? '').toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      downPayment: (json['downPayment'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: (json['paymentMethod'] ?? 'INSTALLMENT').toString(),
      chequeNumber: (json['chequeNumber'] ?? '').toString(),
      numberOfInstallments:
          (json['numberOfInstallments'] as num?)?.toInt() ?? 1,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 30,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                _SaleItemSnapshot.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      schedules: (json['schedules'] as List<dynamic>? ?? [])
          .map(
            (item) => _InstallmentScheduleItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class _InstallmentScheduleItem {
  final int installmentNo;
  double amount;
  double paidAmount;
  DateTime dueDate;
  bool isPaid;
  DateTime? paidAt;

  _InstallmentScheduleItem({
    required this.installmentNo,
    required this.amount,
    this.paidAmount = 0,
    required this.dueDate,
    this.isPaid = false,
    this.paidAt,
  });

  double get remainingAmount =>
      (amount - paidAmount).clamp(0, double.infinity).toDouble();

  Map<String, dynamic> toJson() {
    return {
      'installmentNo': installmentNo,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  factory _InstallmentScheduleItem.fromJson(Map<String, dynamic> json) {
    return _InstallmentScheduleItem(
      installmentNo: (json['installmentNo'] as num?)?.toInt() ?? 1,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      dueDate:
          DateTime.tryParse((json['dueDate'] ?? '').toString()) ??
          DateTime.now(),
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.tryParse(json['paidAt'].toString()),
    );
  }
}

class _InvoiceItem {
  final String id;
  final String saleId;
  final double amount;
  String status;

  _InvoiceItem({
    required this.id,
    required this.saleId,
    required this.amount,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'saleId': saleId, 'amount': amount, 'status': status};
  }

  factory _InvoiceItem.fromJson(Map<String, dynamic> json) {
    return _InvoiceItem(
      id: (json['id'] ?? '').toString(),
      saleId: (json['saleId'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? 'UNPAID').toString(),
    );
  }
}

class _PurchaseOrderItem {
  final String id;
  final String supplier;
  final String supplierId;
  final String locationId;
  String status;
  final String expectedDate;
  String notes;
  final List<_PurchaseOrderLine> items;
  // Payment tracking
  String paymentMethod; // 'CASH' | 'CARD' | 'CHEQUE' | 'CREDIT' | 'PARTIAL'
  double amountPaid;
  double amountDue;
  String createdAt;
  String updatedAt;
  DateTime? receivedAt;
  String? paymentDueDate;

  _PurchaseOrderItem({
    required this.id,
    required this.supplier,
    this.supplierId = '',
    this.locationId = '',
    this.status = 'PENDING',
    this.expectedDate = '',
    this.notes = '',
    this.items = const [],
    this.paymentMethod = 'CASH',
    this.amountPaid = 0,
    this.amountDue = 0,
    this.createdAt = '',
    String? updatedAt,
    this.receivedAt,
    this.paymentDueDate,
  }) : updatedAt =
           updatedAt ??
           (createdAt.isNotEmpty
               ? createdAt
               : DateTime.now().toUtc().toIso8601String());

  int get itemsCount => items.length;
  double get amount => items.fold(0, (s, l) => s + l.lineTotal);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier': supplier,
      'supplierId': supplierId,
      'locationId': locationId,
      'status': status,
      'expectedDate': expectedDate,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'paymentMethod': paymentMethod,
      'amountPaid': amountPaid,
      'amountDue': amountDue,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'receivedAt': receivedAt?.toIso8601String(),
      'paymentDueDate': paymentDueDate,
    };
  }

  factory _PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return _PurchaseOrderItem(
      id: (json['id'] ?? '').toString(),
      supplier: (json['supplier'] ?? '').toString(),
      supplierId: (json['supplierId'] ?? '').toString(),
      locationId: (json['locationId'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      expectedDate: (json['expectedDate'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_PurchaseOrderLine.fromJson)
          .toList(),
      paymentMethod: (json['paymentMethod'] ?? 'CASH').toString(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0,
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? json['createdAt'] ?? '').toString(),
      receivedAt: json['receivedAt'] != null
          ? DateTime.tryParse(json['receivedAt'].toString())
          : null,
      paymentDueDate: json['paymentDueDate']?.toString(),
    );
  }
}

class _PurchaseOrderLine {
  String productId;
  String productName;
  double qty;
  double costPrice; // unit cost (what we pay)
  double sellingPrice; // unit selling price (what we sell for)
  double get lineTotal => qty * costPrice;

  _PurchaseOrderLine({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.costPrice,
    required this.sellingPrice,
  });

  // Legacy getters so old code referencing unitPrice / quantity / lineTotal still compiles
  double get unitPrice => costPrice;
  double get quantity => qty;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'qty': qty,
      'quantity': qty,
      'costPrice': costPrice,
      'unitPrice': costPrice,
      'sellingPrice': sellingPrice,
      'lineTotal': lineTotal,
    };
  }

  factory _PurchaseOrderLine.fromJson(Map<String, dynamic> json) {
    final qty = (json['qty'] ?? json['quantity'] as num?)?.toDouble() ?? 0.0;
    final costPrice =
        (json['costPrice'] ?? json['unitPrice'] as num?)?.toDouble() ?? 0;
    return _PurchaseOrderLine(
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      qty: qty,
      costPrice: costPrice,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? costPrice,
    );
  }
}

class _SyncItem {
  final DateTime timestamp;
  final String action;
  final String module;
  final String reference;

  _SyncItem({
    required this.timestamp,
    required this.action,
    required this.module,
    required this.reference,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'module': module,
      'reference': reference,
    };
  }

  factory _SyncItem.fromJson(Map<String, dynamic> json) {
    return _SyncItem(
      timestamp:
          DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
      action: (json['action'] ?? '').toString(),
      module: (json['module'] ?? '').toString(),
      reference: (json['reference'] ?? '').toString(),
    );
  }
}

class _DiscountData {
  final double value;
  final String type;
  final String label;
  const _DiscountData({
    required this.value,
    required this.type,
    this.label = '',
  });
}

class _CartLine {
  final _ProductItem product;
  final double qty;
  final double discountValue;
  final String discountType; // 'FIXED' or 'PERCENT'
  final String discountLabel;
  final double? overriddenPrice;

  _CartLine({
    required this.product,
    required this.qty,
    this.discountValue = 0.0,
    this.discountType = 'FIXED',
    this.discountLabel = '',
    this.overriddenPrice,
  });

  double get unitPriceBeforeDiscount => overriddenPrice ?? product.price;

  double get unitPriceAfterDiscount {
    final base = unitPriceBeforeDiscount;
    if (discountType == 'PERCENT') {
      return base * (1 - (discountValue / 100));
    } else {
      return (base - discountValue).clamp(0.0, double.infinity);
    }
  }

  double get discountAmountPerUnit =>
      (unitPriceBeforeDiscount - unitPriceAfterDiscount).clamp(
        0.0,
        double.infinity,
      );

  double get originalLineTotal => unitPriceBeforeDiscount * qty;

  double get discountLineTotal => discountAmountPerUnit * qty;

  double get totalPrice {
    return unitPriceAfterDiscount * qty;
  }
}

class _SideSheetContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final double width;
  final Widget? footer;

  const _SideSheetContainer({
    required this.title,
    required this.child,
    this.width = 600,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = isDark
        ? const Color(0xFF1E2D45)
        : const Color(0xFFE6E2EF);
    final screenWidth = MediaQuery.of(context).size.width;
    final actualWidth = width > screenWidth ? screenWidth : width;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: isDark ? const Color(0xFF0D1525) : Colors.white,
        child: Container(
          width: actualWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: dividerColor, width: 1.5)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) =>
                            UiGradients.brand.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: width > 600 ? 26 : 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFF1F5F9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.close_rounded, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(child: child),
              // Footer
              if (footer != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0A0F1D)
                        : const Color(0xFFF8F4FB),
                    border: Border(top: BorderSide(color: dividerColor)),
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformSupportPage extends StatefulWidget {
  final Future<void> Function(String) onLaunchUrl;

  const _PlatformSupportPage({super.key, required this.onLaunchUrl});

  @override
  State<_PlatformSupportPage> createState() => _PlatformSupportPageState();
}

class _PlatformSupportPageState extends State<_PlatformSupportPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _shopIdCtrl;
  late final TextEditingController _descCtrl;
  String _urgency = 'MEDIUM';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _shopIdCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _shopIdCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7C3AED)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Platform Support Desk',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Submit support requests, view server status reports, and connect with tech support.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, constraints) {
            final formSection = Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Submit a Ticket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Need technical help? Open a platform ticket and our support team will respond within 2 hours.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Your Name *',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Shop Email Address *',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _urgency,
                              decoration: const InputDecoration(
                                labelText: 'Urgency Level',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'LOW',
                                  child: Text('Low - General query'),
                                ),
                                DropdownMenuItem(
                                  value: 'MEDIUM',
                                  child: Text(
                                    'Medium - Issue impeding workflow',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'HIGH',
                                  child: Text(
                                    'High - Terminal offline / Fatal bug',
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _urgency = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _shopIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Affected Shop ID *',
                                hintText: 'e.g. dine-buddy',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Detailed Description of Issue *',
                          hintText:
                              'Please describe what happened, any error messages displayed, and steps to reproduce...',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _formKey.currentState?.reset();
                            _nameCtrl.clear();
                            _emailCtrl.clear();
                            _shopIdCtrl.clear();
                            _descCtrl.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Support ticket submitted successfully! Check your email for confirmation.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.email_outlined, size: 16),
                        label: const Text('Submit Ticket'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5B21B6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            final rightSection = Column(
              children: [
                // System Status
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    side: BorderSide(color: Colors.green, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 14),
                            SizedBox(width: 8),
                            Text(
                              'System Status',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatusRow(
                          'Database Server',
                          'Online',
                          Colors.green,
                        ),
                        const Divider(height: 16),
                        _buildStatusRow(
                          'Cloud Sync API',
                          'Operational',
                          Colors.green,
                        ),
                        const Divider(height: 16),
                        _buildStatusRow(
                          'License Validator',
                          'Operational',
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Tech Support
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Tech Support',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If you have an urgent server outage, you can contact the systems administration hotline directly:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContactItem(
                          Icons.phone_rounded,
                          'Hotline:',
                          '+94 77 123 4567',
                        ),
                        const SizedBox(height: 12),
                        _buildContactItem(
                          Icons.email_rounded,
                          'Support Email:',
                          'support@storebuddy.com',
                        ),
                        const SizedBox(height: 12),
                        _buildContactItem(
                          Icons.access_time_rounded,
                          'Business Hours:',
                          'Mon - Sat (8:00 AM - 10:00 PM)',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );

            return constraints.maxWidth > 900
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: formSection),
                      const SizedBox(width: 24),
                      SizedBox(width: 400, child: rightSection),
                    ],
                  )
                : Column(
                    children: [
                      formSection,
                      const SizedBox(height: 24),
                      rightSection,
                    ],
                  );
          },
        ),
      ],
    );
  }
}

class _PlatformContactPage extends StatefulWidget {
  final Future<void> Function(String) onLaunchUrl;

  const _PlatformContactPage({super.key, required this.onLaunchUrl});

  @override
  State<_PlatformContactPage> createState() => _PlatformContactPageState();
}

class _PlatformContactPageState extends State<_PlatformContactPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _messageCtrl;
  String _subject = 'SALES';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _messageCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7C3AED)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLink(String label, String url) {
    return InkWell(
      onTap: () => widget.onLaunchUrl(url),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7C3AED),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Contact Us',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Get in touch with StoreBuddy developers, sales managers, or business partners.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, constraints) {
            final formSection = Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Send us a message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Have questions about pricing, customized plans, or feature requests? Send us an inquiry.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Business Email *',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _subject,
                        decoration: const InputDecoration(labelText: 'Subject'),
                        items: const [
                          DropdownMenuItem(
                            value: 'SALES',
                            child: Text('Sales & Custom Pricing'),
                          ),
                          DropdownMenuItem(
                            value: 'PARTNERSHIP',
                            child: Text('Partnership / Reseller Program'),
                          ),
                          DropdownMenuItem(
                            value: 'CAREERS',
                            child: Text('Careers & Jobs'),
                          ),
                          DropdownMenuItem(
                            value: 'OTHER',
                            child: Text('Other / Feedback'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _subject = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message *',
                          hintText: 'Write your message details...',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _formKey.currentState?.reset();
                            _nameCtrl.clear();
                            _emailCtrl.clear();
                            _messageCtrl.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Inquiry sent successfully! We will contact you soon.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Send Message'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5B21B6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            final rightSection = Column(
              children: [
                // Head Office Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Head Office',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '🏢 StoreBuddy Tech Labs\n45, Galle Road, Colombo 03,\nSri Lanka.',
                          style: TextStyle(fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        _buildContactItem(
                          Icons.phone_rounded,
                          'General:',
                          '+94 11 234 5678',
                        ),
                        const SizedBox(height: 8),
                        _buildContactItem(
                          Icons.email_rounded,
                          'Sales:',
                          'sales@storebuddy.com',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Follow Us Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Follow Us',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stay updated with releases and POS client version releases on our social feeds:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildSocialLink(
                              'LinkedIn',
                              'https://linkedin.com',
                            ),
                            const SizedBox(width: 16),
                            _buildSocialLink('Twitter', 'https://twitter.com'),
                            const SizedBox(width: 16),
                            _buildSocialLink(
                              'Facebook',
                              'https://facebook.com',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );

            return constraints.maxWidth > 900
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: formSection),
                      const SizedBox(width: 24),
                      SizedBox(width: 400, child: rightSection),
                    ],
                  )
                : Column(
                    children: [
                      formSection,
                      const SizedBox(height: 24),
                      rightSection,
                    ],
                  );
          },
        ),
      ],
    );
  }
}
