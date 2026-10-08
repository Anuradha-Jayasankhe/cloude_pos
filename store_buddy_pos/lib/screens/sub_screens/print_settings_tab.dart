part of '../dashboard_screen.dart';

class PrintSettingsContent extends StatefulWidget {
  final db.AppDatabase appDatabase;
  final String tenantId;

  const PrintSettingsContent({
    super.key,
    required this.appDatabase,
    required this.tenantId,
  });

  @override
  State<PrintSettingsContent> createState() => _PrintSettingsContentState();
}

class _PrintSettingsContentState extends State<PrintSettingsContent> {
  db.PrintSetting? _settings;
  bool _loading = true;

  // 1. Device-Local Hardware Printer Configuration (Per-Terminal, SharedPreferences)
  final TextEditingController _printerNameController = TextEditingController();
  final TextEditingController _labelPrinterController = TextEditingController();
  final TextEditingController _customPaperWidthController =
      TextEditingController(text: '72');
  final TextEditingController _marginVMmController =
      TextEditingController(text: '3.0');
  final TextEditingController _marginHMmController =
      TextEditingController(text: '2.0');

  String _paperSize = 'thermal_80'; // thermal_80 | thermal_58 | a4 | a5 | custom
  String _printerType = 'THERMAL';
  String _invoiceTemplate = 'PROFESSIONAL';
  bool _autoPrint = false;
  bool _promptDeliveryLabel = false;
  String _deliveryNoteFormat = 'THERMAL_80MM';
  final TextEditingController _deliveryNotePrinterController =
      TextEditingController();

  // 2. Device-Local Cash Drawer Configuration (ESC/POS)
  bool _cashDrawerEnabled = true;
  String? _cashDrawerPrinterName;
  String _cashDrawerMethod = 'print_job'; // 'print_job' | 'network' | 'hybrid'
  int _cashDrawerPulsePin = 0; // 0 for Pin 2, 1 for Pin 5
  int _cashDrawerPulseOnMs = 120;
  int _cashDrawerPulseOffMs = 240;
  final TextEditingController _cashDrawerNetworkIpController =
      TextEditingController();
  final TextEditingController _cashDrawerNetworkPortController =
      TextEditingController(text: '9100');

  // 3. Store-Wide Bill Layout & Structure Toggles
  bool _showShopHeader = true;
  bool _showSlogan = false;
  final TextEditingController _sloganController = TextEditingController();
  bool _showInvoiceNumber = true;
  final TextEditingController _invoicePrefixController =
      TextEditingController(text: 'INV-');
  bool _showDateTime = true;
  bool _showCashierName = true;
  bool _showCustomerName = true;
  bool _showCustomerAddress = false;
  bool _showItemTable = true;
  bool _showItemNumbers = true;
  bool _showSubtotal = true;
  bool _showDiscount = true;
  bool _showTax = true;
  bool _showTotal = true;
  bool _showPaymentDetails = true;
  bool _showTerms = false;
  final TextEditingController _termsController = TextEditingController();
  bool _showFooter = true;
  final TextEditingController _thankYouController = TextEditingController();
  final TextEditingController _returnPolicyController = TextEditingController();
  final TextEditingController _socialLinksController = TextEditingController();

  bool _showLogo = true;
  bool _showBarcode = false;
  bool _showQr = true;
  double _fontSize = 10;
  double _lineSpacing = 1.2;

  List<Printer> _availablePrinters = [];
  bool _scanningPrinters = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scanPrinters();
  }

  Future<void> _scanPrinters() async {
    setState(() => _scanningPrinters = true);
    try {
      final list = await Printing.listPrinters();
      if (!mounted) return;
      setState(() {
        _availablePrinters = list;
        _scanningPrinters = false;
      });
    } catch (_) {
      if (mounted) setState(() => _scanningPrinters = false);
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();

    // 1. Device-Local Hardware Settings
    final savedReceiptPrinter = prefs.getString('local_printer_receipt_name');
    _printerNameController.text = savedReceiptPrinter ?? '';
    _labelPrinterController.text = prefs.getString('local_printer_label_name') ?? '';
    _paperSize = prefs.getString('local_printer_paper_size') ?? 'thermal_80';
    final paperWidth = prefs.getDouble('local_printer_paper_width_mm') ?? 72.0;
    _customPaperWidthController.text = paperWidth.toInt().toString();
    final marginV = prefs.getDouble('local_printer_margin_v_mm') ?? 3.0;
    final marginH = prefs.getDouble('local_printer_margin_h_mm') ?? 2.0;
    _marginVMmController.text = marginV.toString();
    _marginHMmController.text = marginH.toString();
    _autoPrint = prefs.getBool('local_printer_auto_print') ?? false;
    _promptDeliveryLabel = prefs.getBool('local_printer_prompt_delivery_label') ?? false;
    _deliveryNoteFormat = prefs.getString('local_printer_delivery_note_format') ?? 'THERMAL_80MM';
    _deliveryNotePrinterController.text = prefs.getString('local_printer_delivery_note_printer_name') ?? '';

    // 2. Device-Local Cash Drawer
    _cashDrawerEnabled = prefs.getBool('local_cash_drawer_enabled') ?? true;
    _cashDrawerPrinterName = prefs.getString('local_cash_drawer_printer_name');
    _cashDrawerMethod = prefs.getString('local_cash_drawer_method') ?? 'print_job';
    _cashDrawerPulsePin = prefs.getInt('local_cash_drawer_pulse_pin') ?? 0;
    _cashDrawerPulseOnMs = prefs.getInt('local_cash_drawer_pulse_on_ms') ?? 120;
    _cashDrawerPulseOffMs = prefs.getInt('local_cash_drawer_pulse_off_ms') ?? 240;
    _cashDrawerNetworkIpController.text = prefs.getString('local_cash_drawer_network_ip') ?? '';
    _cashDrawerNetworkPortController.text = (prefs.getInt('local_cash_drawer_network_port') ?? 9100).toString();

    // 3. Bill Structure Toggles from prefs / database
    _showShopHeader = prefs.getBool('bill_show_shop_header') ?? true;
    _showSlogan = prefs.getBool('bill_show_slogan') ?? false;
    _sloganController.text = prefs.getString('bill_invoice_slogan') ?? '';
    _showInvoiceNumber = prefs.getBool('bill_show_invoice_no') ?? true;
    _invoicePrefixController.text = prefs.getString('bill_invoice_prefix') ?? 'INV-';
    _showDateTime = prefs.getBool('bill_show_date_time') ?? true;
    _showCashierName = prefs.getBool('bill_show_cashier') ?? true;
    _showCustomerName = prefs.getBool('bill_show_customer') ?? true;
    _showCustomerAddress = prefs.getBool('bill_show_customer_address') ?? false;
    _showItemTable = prefs.getBool('bill_show_item_table') ?? true;
    _showItemNumbers = prefs.getBool('bill_show_item_numbers') ?? true;
    _showSubtotal = prefs.getBool('bill_show_subtotal') ?? true;
    _showDiscount = prefs.getBool('bill_show_discount') ?? true;
    _showTax = prefs.getBool('bill_show_tax') ?? true;
    _showTotal = prefs.getBool('bill_show_total') ?? true;
    _showPaymentDetails = prefs.getBool('bill_show_payment_details') ?? true;
    _showTerms = prefs.getBool('bill_show_terms') ?? false;
    _termsController.text = prefs.getString('bill_invoice_terms') ?? '';
    _showFooter = prefs.getBool('bill_show_footer') ?? true;

    // 4. Database Print Settings
    final existing = await widget.appDatabase.getPrintSettings(widget.tenantId);
    if (existing != null) {
      _settings = existing;
      _printerType = existing.printerType;
      _invoiceTemplate = existing.invoiceTemplate;
      _showLogo = existing.showLogo;
      _showBarcode = existing.showBarcode;
      _showQr = existing.showQr;
      _fontSize = existing.fontSize;
      _lineSpacing = existing.lineSpacing;
      _thankYouController.text = existing.thankYouMessage;
      _returnPolicyController.text = existing.returnPolicy ?? '';
      _socialLinksController.text = existing.socialLinks ?? '';
    } else {
      _thankYouController.text = 'Thank you for your business!';
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Save Device-Local Hardware Settings
    final receiptPrinter = _printerNameController.text.trim();
    if (receiptPrinter.isNotEmpty) {
      await prefs.setString('local_printer_receipt_name', receiptPrinter);
    } else {
      await prefs.remove('local_printer_receipt_name');
    }
    final labelPrinter = _labelPrinterController.text.trim();
    if (labelPrinter.isNotEmpty) {
      await prefs.setString('local_printer_label_name', labelPrinter);
    } else {
      await prefs.remove('local_printer_label_name');
    }

    await prefs.setString('local_printer_paper_size', _paperSize);
    final customW = double.tryParse(_customPaperWidthController.text.trim()) ?? 72.0;
    await prefs.setDouble('local_printer_paper_width_mm', customW);
    final marginV = double.tryParse(_marginVMmController.text.trim()) ?? 3.0;
    final marginH = double.tryParse(_marginHMmController.text.trim()) ?? 2.0;
    await prefs.setDouble('local_printer_margin_v_mm', marginV);
    await prefs.setDouble('local_printer_margin_h_mm', marginH);
    await prefs.setBool('local_printer_auto_print', _autoPrint);
    await prefs.setBool('local_printer_prompt_delivery_label', _promptDeliveryLabel);
    await prefs.setString('local_printer_delivery_note_format', _deliveryNoteFormat);
    final deliveryNotePrinter = _deliveryNotePrinterController.text.trim();
    if (deliveryNotePrinter.isNotEmpty) {
      await prefs.setString('local_printer_delivery_note_printer_name', deliveryNotePrinter);
    } else {
      await prefs.remove('local_printer_delivery_note_printer_name');
    }

    // 2. Save Device-Local Cash Drawer Settings
    await prefs.setBool('local_cash_drawer_enabled', _cashDrawerEnabled);
    if (_cashDrawerPrinterName != null && _cashDrawerPrinterName!.isNotEmpty) {
      await prefs.setString('local_cash_drawer_printer_name', _cashDrawerPrinterName!);
    } else {
      await prefs.remove('local_cash_drawer_printer_name');
    }
    await prefs.setString('local_cash_drawer_method', _cashDrawerMethod);
    await prefs.setInt('local_cash_drawer_pulse_pin', _cashDrawerPulsePin);
    await prefs.setInt('local_cash_drawer_pulse_on_ms', _cashDrawerPulseOnMs);
    await prefs.setInt('local_cash_drawer_pulse_off_ms', _cashDrawerPulseOffMs);
    await prefs.setString('local_cash_drawer_network_ip', _cashDrawerNetworkIpController.text.trim());
    await prefs.setInt(
      'local_cash_drawer_network_port',
      int.tryParse(_cashDrawerNetworkPortController.text.trim()) ?? 9100,
    );

    // 3. Save Bill Structure Toggles
    await prefs.setBool('bill_show_shop_header', _showShopHeader);
    await prefs.setBool('bill_show_slogan', _showSlogan);
    await prefs.setString('bill_invoice_slogan', _sloganController.text.trim());
    await prefs.setBool('bill_show_invoice_no', _showInvoiceNumber);
    await prefs.setString('bill_invoice_prefix', _invoicePrefixController.text.trim());
    await prefs.setBool('bill_show_date_time', _showDateTime);
    await prefs.setBool('bill_show_cashier', _showCashierName);
    await prefs.setBool('bill_show_customer', _showCustomerName);
    await prefs.setBool('bill_show_customer_address', _showCustomerAddress);
    await prefs.setBool('bill_show_item_table', _showItemTable);
    await prefs.setBool('bill_show_item_numbers', _showItemNumbers);
    await prefs.setBool('bill_show_subtotal', _showSubtotal);
    await prefs.setBool('bill_show_discount', _showDiscount);
    await prefs.setBool('bill_show_tax', _showTax);
    await prefs.setBool('bill_show_total', _showTotal);
    await prefs.setBool('bill_show_payment_details', _showPaymentDetails);
    await prefs.setBool('bill_show_terms', _showTerms);
    await prefs.setString('bill_invoice_terms', _termsController.text.trim());
    await prefs.setBool('bill_show_footer', _showFooter);

    // 4. Save to Database
    final companion = db.PrintSettingsCompanion(
      id: Value(
        _settings?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      tenantId: Value(widget.tenantId),
      paperSize: Value(_paperSize),
      printerName: Value(receiptPrinter.isNotEmpty ? receiptPrinter : null),
      printerType: Value(_printerType),
      invoiceTemplate: Value(_invoiceTemplate),
      autoPrint: Value(_autoPrint),
      showLogo: Value(_showLogo),
      showBarcode: Value(_showBarcode),
      showQr: Value(_showQr),
      showTax: Value(_showTax),
      showDiscount: Value(_showDiscount),
      showCustomerAddress: Value(_showCustomerAddress),
      marginTop: Value(marginV),
      marginLeft: Value(marginH),
      fontSize: Value(_fontSize),
      lineSpacing: Value(_lineSpacing),
      thankYouMessage: Value(_thankYouController.text.trim()),
      returnPolicy: Value(
        _returnPolicyController.text.trim().isEmpty
            ? null
            : _returnPolicyController.text.trim(),
      ),
      socialLinks: Value(
        _socialLinksController.text.trim().isEmpty
            ? null
            : _socialLinksController.text.trim(),
      ),
      updatedAt: Value(DateTime.now()),
    );

    await widget.appDatabase.upsertPrintSettings(companion);

    // Also update parent dashboard state if mounted
    final dashState = context.findAncestorStateOfType<_DashboardScreenState>();
    if (dashState != null) {
      await dashState._loadDeviceLocalPrinterSettings();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('POS Print & Hardware Settings Saved Successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _testPrintSlip() async {
    final printerName = _printerNameController.text.trim();
    final customW = double.tryParse(_customPaperWidthController.text.trim()) ?? 72.0;
    final marginV = double.tryParse(_marginVMmController.text.trim()) ?? 3.0;
    final marginH = double.tryParse(_marginHMmController.text.trim()) ?? 2.0;

    final fakeSale = domain.Sale(
      id: 'SALE-TEST-${DateTime.now().millisecondsSinceEpoch % 10000}',
      tenantId: widget.tenantId,
      customerId: null,
      employeeId: 'EMP-01',
      cashierName: 'Admin Cashier',
      invoiceNumber: '${_invoicePrefixController.text.trim()}1001',
      total: 1250.0,
      tax: 0.0,
      discount: 50.0,
      amountPaid: 1250.0,
      balance: 0.0,
      paymentMethod: 'CASH',
      status: 'COMPLETED',
      locationId: 'LOC-1',
      synced: true,
      createdAt: DateTime.now(),
      shippingCharges: 0.0,
      items: [
        domain.SaleItem(
          id: 'TEST-1',
          saleId: 'TEST',
          tenantId: widget.tenantId,
          productId: 'P-1',
          productName: 'Sample Retail Product A',
          quantity: 2.0,
          unitPrice: 400.0,
          originalPrice: 400.0,
          total: 800.0,
        ),
        domain.SaleItem(
          id: 'TEST-2',
          saleId: 'TEST',
          tenantId: widget.tenantId,
          productId: 'P-2',
          productName: 'Sample Retail Product B',
          quantity: 1.0,
          unitPrice: 500.0,
          originalPrice: 500.0,
          total: 500.0,
        ),
      ],
    );

    final currentSettings = domain.PrintSettingsModel(
      id: 'test',
      tenantId: widget.tenantId,
      paperSize: _paperSize,
      printerName: printerName.isNotEmpty ? printerName : null,
      printerType: _printerType,
      invoiceTemplate: _invoiceTemplate,
      autoPrint: _autoPrint,
      showLogo: _showLogo,
      showBarcode: _showBarcode,
      showQr: _showQr,
      showTax: _showTax,
      showDiscount: _showDiscount,
      showCustomerAddress: _showCustomerAddress,
      marginTop: marginV,
      marginLeft: marginH,
      fontSize: _fontSize,
      lineSpacing: _lineSpacing,
      thankYouMessage: _thankYouController.text.trim(),
      returnPolicy: _returnPolicyController.text.trim(),
      socialLinks: _socialLinksController.text.trim(),
      showShopHeader: _showShopHeader,
      showInvoiceNumber: _showInvoiceNumber,
      showDateTime: _showDateTime,
      showCashierName: _showCashierName,
      showCustomerName: _showCustomerName,
      showItemTable: _showItemTable,
      showItemNumbers: _showItemNumbers,
      showSubtotal: _showSubtotal,
      showTotal: _showTotal,
      showPaymentDetails: _showPaymentDetails,
      showFooter: _showFooter,
      showTerms: _showTerms,
      showSlogan: _showSlogan,
      invoiceSlogan: _sloganController.text.trim(),
      invoiceTerms: _termsController.text.trim(),
      paperWidthMm: _paperSize == 'custom' ? customW : (_paperSize == 'thermal_58' ? 48.0 : 72.0),
      marginVerticalMm: marginV,
      marginHorizontalMm: marginH,
      receiptLanguage: 'en',
    );

    try {
      await PrintService.printReceipt(
        sale: fakeSale,
        settings: currentSettings,
        currencySymbol: 'LKR',
        storeName: 'StoreBuddy Demo Store',
        storeAddress: '123 Main Street, Colombo',
        storePhone: '+94 77 123 4567',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              printerName.isNotEmpty
                  ? 'Test print sent directly to $printerName!'
                  : 'Test print sent to system print dialog.',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testPrintDeliveryNote() async {
    final customW = double.tryParse(_customPaperWidthController.text.trim()) ?? 72.0;
    final marginV = double.tryParse(_marginVMmController.text.trim()) ?? 3.0;
    final marginH = double.tryParse(_marginHMmController.text.trim()) ?? 2.0;
    final deliveryPrinter = _deliveryNotePrinterController.text.trim();
    final effectivePrinter = deliveryPrinter.isNotEmpty
        ? deliveryPrinter
        : (_printerNameController.text.trim().isNotEmpty
            ? _printerNameController.text.trim()
            : null);

    final fakeSale = domain.Sale(
      id: 'DELIV-TEST-${DateTime.now().millisecondsSinceEpoch % 10000}',
      tenantId: widget.tenantId,
      customerId: 'CUST-001',
      employeeId: 'EMP-01',
      cashierName: 'Admin Cashier',
      invoiceNumber: '${_invoicePrefixController.text.trim()}COD-101',
      total: 3450.0,
      tax: 0.0,
      discount: 0.0,
      amountPaid: 0.0,
      balance: 3450.0,
      paymentMethod: 'COD',
      status: 'DELIVERY_PENDING',
      locationId: 'LOC-1',
      synced: true,
      createdAt: DateTime.now(),
      shippingCharges: 350.0,
      shippingAddress: 'No. 128, Kandy Road, Kiribathgoda',
      customer: domain.Customer(
        id: 'CUST-001',
        tenantId: widget.tenantId,
        name: 'Kamal Perera',
        phone: '077 123 4567',
        address: 'No. 128, Kandy Road, Kiribathgoda',
        creditLimit: 0,
        currentBalance: 0,
        synced: true,
      ),
      items: [
        domain.SaleItem(
          id: 'TEST-1',
          saleId: 'TEST',
          tenantId: widget.tenantId,
          productId: 'P-1',
          productName: 'Sample Product 01 (Milk Powder)',
          quantity: 2.0,
          unitPrice: 1150.0,
          originalPrice: 1150.0,
          total: 2300.0,
        ),
        domain.SaleItem(
          id: 'TEST-2',
          saleId: 'TEST',
          tenantId: widget.tenantId,
          productId: 'P-2',
          productName: 'Sample Product 02 (Premium Tea)',
          quantity: 1.0,
          unitPrice: 800.0,
          originalPrice: 800.0,
          total: 800.0,
        ),
      ],
    );

    final currentSettings = domain.PrintSettingsModel(
      id: 'test',
      tenantId: widget.tenantId,
      paperSize: _paperSize,
      printerName: _printerNameController.text.trim().isNotEmpty ? _printerNameController.text.trim() : null,
      printerType: _printerType,
      invoiceTemplate: _invoiceTemplate,
      autoPrint: _autoPrint,
      showLogo: _showLogo,
      showBarcode: _showBarcode,
      showQr: _showQr,
      showTax: _showTax,
      showDiscount: _showDiscount,
      showCustomerAddress: _showCustomerAddress,
      marginTop: marginV,
      marginLeft: marginH,
      fontSize: _fontSize,
      lineSpacing: _lineSpacing,
      thankYouMessage: _thankYouController.text.trim(),
      returnPolicy: _returnPolicyController.text.trim(),
      socialLinks: _socialLinksController.text.trim(),
      showShopHeader: _showShopHeader,
      showInvoiceNumber: _showInvoiceNumber,
      showDateTime: _showDateTime,
      showCashierName: _showCashierName,
      showCustomerName: _showCustomerName,
      showItemTable: _showItemTable,
      showItemNumbers: _showItemNumbers,
      showSubtotal: _showSubtotal,
      showTotal: _showTotal,
      showPaymentDetails: _showPaymentDetails,
      showFooter: _showFooter,
      showTerms: _showTerms,
      showSlogan: _showSlogan,
      invoiceSlogan: _sloganController.text.trim(),
      invoiceTerms: _termsController.text.trim(),
      paperWidthMm: _paperSize == 'custom' ? customW : (_paperSize == 'thermal_58' ? 48.0 : 72.0),
      marginVerticalMm: marginV,
      marginHorizontalMm: marginH,
      receiptLanguage: 'en',
      deliveryNoteFormat: _deliveryNoteFormat,
      deliveryNotePrinterName: deliveryPrinter.isNotEmpty ? deliveryPrinter : null,
    );

    try {
      await PrintService.printDeliveryNote(
        sale: fakeSale,
        settings: currentSettings,
        currencySymbol: 'Rs.',
        storeName: 'StoreBuddy Demo Store',
        storeAddress: 'No. 45, Galle Road, Colombo 03',
        storePhone: '+94 11 234 5678',
        formatOverride: _deliveryNoteFormat,
        printerNameOverride: effectivePrinter,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              effectivePrinter != null && effectivePrinter.isNotEmpty
                  ? 'Test Delivery Note sent directly to $effectivePrinter!'
                  : 'Test Delivery Note opened in print dialog.',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery Note print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testCashDrawer() async {
    try {
      final success = await PrintService.kickCashDrawer(
        printerName: _cashDrawerPrinterName?.isNotEmpty == true
            ? _cashDrawerPrinterName
            : (_printerNameController.text.trim().isNotEmpty
                ? _printerNameController.text.trim()
                : null),
        method: _cashDrawerMethod,
        pin: _cashDrawerPulsePin,
        onMs: _cashDrawerPulseOnMs,
        offMs: _cashDrawerPulseOffMs,
        networkIp: _cashDrawerNetworkIpController.text.trim(),
        networkPort: int.tryParse(_cashDrawerNetworkPortController.text.trim()) ?? 9100,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Cash Drawer kick pulse sent successfully!'
                  : 'Cash Drawer kick command executed. Check hardware.',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drawer kick error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPreview() {
    final customW = double.tryParse(_customPaperWidthController.text.trim()) ?? 72.0;
    final marginV = double.tryParse(_marginVMmController.text.trim()) ?? 3.0;
    final marginH = double.tryParse(_marginHMmController.text.trim()) ?? 2.0;

    final fakeSale = domain.Sale(
      id: 'SALE-PREVIEW-001',
      tenantId: widget.tenantId,
      customerId: null,
      employeeId: 'EMP-01',
      cashierName: 'Cashier 1',
      invoiceNumber: '${_invoicePrefixController.text.trim()}202601',
      total: 1650.0,
      tax: 0.0,
      discount: 100.0,
      amountPaid: 2000.0,
      balance: -350.0,
      paymentMethod: 'CASH',
      status: 'COMPLETED',
      locationId: 'LOC-1',
      synced: true,
      createdAt: DateTime.now(),
      shippingCharges: 0.0,
      items: [
        domain.SaleItem(
          id: 'ITEM-1',
          saleId: 'PREVIEW',
          tenantId: widget.tenantId,
          productId: 'PROD-1',
          productName: 'Anchor Milk Powder 400g',
          quantity: 2.0,
          unitPrice: 550.0,
          originalPrice: 550.0,
          total: 1100.0,
        ),
        domain.SaleItem(
          id: 'ITEM-2',
          saleId: 'PREVIEW',
          tenantId: widget.tenantId,
          productId: 'PROD-2',
          productName: 'Munchee Super Cream Cracker',
          quantity: 3.0,
          unitPrice: 200.0,
          originalPrice: 200.0,
          total: 600.0,
        ),
      ],
    );

    final currentSettings = domain.PrintSettingsModel(
      id: 'preview',
      tenantId: widget.tenantId,
      paperSize: _paperSize,
      printerName: _printerNameController.text.trim().isNotEmpty
          ? _printerNameController.text.trim()
          : null,
      printerType: _printerType,
      invoiceTemplate: _invoiceTemplate,
      autoPrint: _autoPrint,
      showLogo: _showLogo,
      showBarcode: _showBarcode,
      showQr: _showQr,
      showTax: _showTax,
      showDiscount: _showDiscount,
      showCustomerAddress: _showCustomerAddress,
      marginTop: marginV,
      marginLeft: marginH,
      fontSize: _fontSize,
      lineSpacing: _lineSpacing,
      thankYouMessage: _thankYouController.text.trim(),
      returnPolicy: _returnPolicyController.text.trim(),
      socialLinks: _socialLinksController.text.trim(),
      showShopHeader: _showShopHeader,
      showInvoiceNumber: _showInvoiceNumber,
      showDateTime: _showDateTime,
      showCashierName: _showCashierName,
      showCustomerName: _showCustomerName,
      showItemTable: _showItemTable,
      showItemNumbers: _showItemNumbers,
      showSubtotal: _showSubtotal,
      showTotal: _showTotal,
      showPaymentDetails: _showPaymentDetails,
      showFooter: _showFooter,
      showTerms: _showTerms,
      showSlogan: _showSlogan,
      invoiceSlogan: _sloganController.text.trim(),
      invoiceTerms: _termsController.text.trim(),
      paperWidthMm: _paperSize == 'custom' ? customW : (_paperSize == 'thermal_58' ? 48.0 : 72.0),
      marginVerticalMm: marginV,
      marginHorizontalMm: marginH,
      receiptLanguage: 'en',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt Layout Preview'),
        content: SizedBox(
          width: ResponsiveLayout.adaptiveDialogWidth(context, 750),
          height: ResponsiveLayout.adaptiveDialogHeight(context, 650),
          child: PdfPreview(
            build: (format) async => PrintService.generateReceiptPdf(
              sale: fakeSale,
              settings: currentSettings,
              currencySymbol: 'LKR',
              storeName: 'StoreBuddy Supermarket',
              storeAddress: 'No. 45, Galle Road, Colombo 03',
              storePhone: '+94 11 234 5678',
            ),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POS Bill & Hardware Printing Setup',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure terminal hardware bindings, cash drawer, and store-wide bill structure.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _showPreview,
                    icon: const Icon(Icons.preview_outlined, size: 18),
                    label: const Text('Preview Layout'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save All Settings'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // SECTION 1: Local Terminal Printer Setup (Hardware binding per machine)
          _buildCard(
            context,
            title: '1. Local Terminal Receipt Printer',
            subtitle: 'This printer selection is stored on this computer only and will NOT conflict with other cashier terminals.',
            icon: Icons.print_rounded,
            iconColor: const Color(0xFF4F46E5),
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _scanningPrinters ? null : _scanPrinters,
                  icon: _scanningPrinters
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(_scanningPrinters ? 'Scanning...' : 'Scan Printers'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _testPrintSlip,
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('Test Print Slip'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_availablePrinters.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _availablePrinters.any((p) => p.name == _printerNameController.text.trim())
                        ? _printerNameController.text.trim()
                        : (_printerNameController.text.trim() == '__FIRST_PRINTER__'
                            ? '__FIRST_PRINTER__'
                            : null),
                    decoration: const InputDecoration(
                      labelText: 'Select Discovered System Printer',
                      border: inputBorder,
                      prefixIcon: Icon(Icons.devices_rounded, size: 18),
                    ),
                    isExpanded: true,
                    hint: const Text('Choose a connected USB, Bluetooth or Network printer...'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '__FIRST_PRINTER__',
                        child: Text('⚡ Auto-Select First Available Printer (Silent Direct Print)'),
                      ),
                      ..._availablePrinters.map((p) {
                        final isDef = p.isDefault ? ' (Default)' : '';
                        return DropdownMenuItem<String>(
                          value: p.name,
                          child: Text('${p.name}$isDef', overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _printerNameController.text = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _printerNameController,
                        decoration: InputDecoration(
                          labelText: 'Target Receipt Printer Name / Port',
                          hintText: 'Leave empty for system dialog, or enter printer name / __FIRST_PRINTER__',
                          border: inputBorder,
                          prefixIcon: const Icon(Icons.print_outlined),
                          suffixIcon: _printerNameController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => setState(() => _printerNameController.clear()),
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _paperSize,
                        items: const [
                          DropdownMenuItem(value: 'thermal_80', child: Text('80mm Thermal (Standard POS)')),
                          DropdownMenuItem(value: 'thermal_58', child: Text('58mm Thermal (Compact POS)')),
                          DropdownMenuItem(value: 'a4', child: Text('A4 Full Sheet')),
                          DropdownMenuItem(value: 'a5', child: Text('A5 Half Sheet')),
                          DropdownMenuItem(value: 'custom', child: Text('Custom Width (mm)')),
                        ],
                        onChanged: (v) => setState(() => _paperSize = v ?? 'thermal_80'),
                        decoration: const InputDecoration(
                          labelText: 'Paper Format Preset',
                          border: inputBorder,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_paperSize == 'custom') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _customPaperWidthController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Print Width (mm)',
                            hintText: 'e.g. 72',
                            suffixText: 'mm',
                            border: inputBorder,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Set exact printable width in millimeters according to your thermal paper roll.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                // Millimeter Margins & Automation
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _marginVMmController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Vertical Margin (mm)',
                          hintText: '3.0',
                          suffixText: 'mm',
                          border: inputBorder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _marginHMmController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Horizontal Margin (mm)',
                          hintText: '2.0',
                          suffixText: 'mm',
                          border: inputBorder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto Silent Print', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Print bill automatically upon checkout', style: TextStyle(fontSize: 11)),
                        value: _autoPrint,
                        onChanged: (v) => setState(() => _autoPrint = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SECTION 2: Cash Drawer Setup (Device Local Hardware)
          _buildCard(
            context,
            title: '2. Cash Drawer Kick Configuration (ESC/POS)',
            subtitle: 'Configure automatic cash drawer pulse trigger when cash transactions complete.',
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF10B981),
            action: FilledButton.icon(
              onPressed: _testCashDrawer,
              icon: const Icon(Icons.bolt_rounded, size: 16),
              label: const Text('⚡ Test Open Cash Drawer'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Cash Drawer Automation', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Automatically triggers drawer kick pulse upon CASH, COD or Split payment checkouts.'),
                  value: _cashDrawerEnabled,
                  onChanged: (v) => setState(() => _cashDrawerEnabled = v),
                ),
                if (_cashDrawerEnabled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _cashDrawerMethod,
                          items: const [
                            DropdownMenuItem(value: 'print_job', child: Text('Receipt Printer (Windows Spooler / USB)')),
                            DropdownMenuItem(value: 'network', child: Text('Direct TCP Socket (Network IP : Port)')),
                            DropdownMenuItem(value: 'hybrid', child: Text('Hybrid (Network first, then Printer)')),
                          ],
                          onChanged: (v) => setState(() => _cashDrawerMethod = v ?? 'print_job'),
                          decoration: const InputDecoration(
                            labelText: 'Drawer Kick Trigger Method',
                            border: inputBorder,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _cashDrawerPulsePin,
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Pin 2 (Standard ESC/POS Cash Drawer)')),
                            DropdownMenuItem(value: 1, child: Text('Pin 5 (Secondary Cash Drawer)')),
                          ],
                          onChanged: (v) => setState(() => _cashDrawerPulsePin = v ?? 0),
                          decoration: const InputDecoration(
                            labelText: 'Solenoid Connector Pin',
                            border: inputBorder,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_cashDrawerMethod == 'network' || _cashDrawerMethod == 'hybrid') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cashDrawerNetworkIpController,
                            decoration: const InputDecoration(
                              labelText: 'Printer / Drawer Network IP',
                              hintText: 'e.g. 192.168.1.100',
                              border: inputBorder,
                              prefixIcon: Icon(Icons.wifi_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cashDrawerNetworkPortController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              hintText: '9100',
                              border: inputBorder,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pulse On Duration: ${_cashDrawerPulseOnMs}ms  |  Pulse Off Duration: ${_cashDrawerPulseOffMs}ms',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: Slider(
                          value: _cashDrawerPulseOnMs.toDouble(),
                          min: 50,
                          max: 300,
                          divisions: 10,
                          label: '${_cashDrawerPulseOnMs}ms',
                          onChanged: (val) => setState(() => _cashDrawerPulseOnMs = val.toInt()),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SECTION 3: Bill Structure & Branding Toggles (Store-Wide)
          _buildCard(
            context,
            title: '3. Bill & Receipt Structure Toggles (Store-Wide Branding)',
            subtitle: 'Choose which elements appear on receipts given to customers.',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFFF59E0B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildToggleBox(context, 'Show Shop Header', _showShopHeader, (v) => setState(() => _showShopHeader = v)),
                    _buildToggleBox(context, 'Show Slogan', _showSlogan, (v) => setState(() => _showSlogan = v)),
                    _buildToggleBox(context, 'Show Invoice Number', _showInvoiceNumber, (v) => setState(() => _showInvoiceNumber = v)),
                    _buildToggleBox(context, 'Show Date & Time', _showDateTime, (v) => setState(() => _showDateTime = v)),
                    _buildToggleBox(context, 'Show Cashier Name', _showCashierName, (v) => setState(() => _showCashierName = v)),
                    _buildToggleBox(context, 'Show Customer Name', _showCustomerName, (v) => setState(() => _showCustomerName = v)),
                    _buildToggleBox(context, 'Show Items Table', _showItemTable, (v) => setState(() => _showItemTable = v)),
                    _buildToggleBox(context, 'Show Item Numbers (1, 2..)', _showItemNumbers, (v) => setState(() => _showItemNumbers = v)),
                    _buildToggleBox(context, 'Show Subtotal', _showSubtotal, (v) => setState(() => _showSubtotal = v)),
                    _buildToggleBox(context, 'Show Discounts', _showDiscount, (v) => setState(() => _showDiscount = v)),
                    _buildToggleBox(context, 'Show Tax Info', _showTax, (v) => setState(() => _showTax = v)),
                    _buildToggleBox(context, 'Show Grand Total', _showTotal, (v) => setState(() => _showTotal = v)),
                    _buildToggleBox(context, 'Show Payment Details', _showPaymentDetails, (v) => setState(() => _showPaymentDetails = v)),
                    _buildToggleBox(context, 'Show Terms & Conditions', _showTerms, (v) => setState(() => _showTerms = v)),
                    _buildToggleBox(context, 'Show Footer Note', _showFooter, (v) => setState(() => _showFooter = v)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _invoicePrefixController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number Prefix',
                          hintText: 'e.g. INV-, BILL-, SB-',
                          border: inputBorder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _sloganController,
                        decoration: const InputDecoration(
                          labelText: 'Store Slogan (Printed below store name)',
                          hintText: 'e.g. "Your Trusted Fashion Partner"',
                          border: inputBorder,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _termsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Terms & Conditions (Printed at the bottom of the bill)',
                    hintText: 'e.g. Goods once sold can be exchanged within 7 days with original invoice.',
                    border: inputBorder,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _thankYouController,
                  decoration: const InputDecoration(
                    labelText: 'Thank You Message',
                    hintText: 'Thank you for shopping with us! Please come again.',
                    border: inputBorder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SECTION 4: Barcode & Delivery Labels
          _buildCard(
            context,
            title: '4. Barcode Label & Delivery Note Automation',
            subtitle: 'Configure dedicated label printers for Zebra, Dymo, Brother, or 80mm sticky labels.',
            icon: Icons.qr_code_2_rounded,
            iconColor: const Color(0xFF06B6D4),
            action: FilledButton.icon(
              onPressed: _testPrintDeliveryNote,
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Test Delivery Note'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _labelPrinterController,
                        decoration: const InputDecoration(
                          labelText: 'Dedicated Barcode / Label Printer Name',
                          hintText: 'e.g. Zebra ZD230, Dymo LabelWriter 450',
                          border: inputBorder,
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Prompt Delivery Label on COD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Ask to print delivery address label when COD/Shipping order is placed', style: TextStyle(fontSize: 11)),
                        value: _promptDeliveryLabel,
                        onChanged: (v) => setState(() => _promptDeliveryLabel = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Note Printing Configuration (Fixed Hardware Binding)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Select your fixed printer and paper format. POS orders will print directly without asking to pick a printer.',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_availablePrinters.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _availablePrinters.any((p) => p.name == _deliveryNotePrinterController.text.trim())
                        ? _deliveryNotePrinterController.text.trim()
                        : (_deliveryNotePrinterController.text.trim().isEmpty ? '' : null),
                    decoration: const InputDecoration(
                      labelText: 'Select Discovered Fixed Printer for Delivery Notes',
                      border: inputBorder,
                      prefixIcon: Icon(Icons.devices_rounded, size: 18),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('🖨️ Same as Main Receipt Printer (Default)'),
                      ),
                      ..._availablePrinters.map((p) {
                        final isDef = p.isDefault ? ' (Default)' : '';
                        return DropdownMenuItem<String>(
                          value: p.name,
                          child: Text('${p.name}$isDef', overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _deliveryNotePrinterController.text = val ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _deliveryNoteFormat,
                        decoration: const InputDecoration(
                          labelText: 'Default Delivery Note Format',
                          border: inputBorder,
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'THERMAL_80MM',
                            child: Text('Thermal Receipt (80mm) - Recommended'),
                          ),
                          DropdownMenuItem(
                            value: 'THERMAL_58MM',
                            child: Text('Thermal Receipt (58mm)'),
                          ),
                          DropdownMenuItem(
                            value: 'A4',
                            child: Text('Standard A4 Sheet Document'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _deliveryNoteFormat = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _deliveryNotePrinterController,
                        decoration: InputDecoration(
                          labelText: 'Delivery Note Fixed Printer Name / URL',
                          hintText: 'Leave empty to use main receipt printer',
                          border: inputBorder,
                          prefixIcon: const Icon(Icons.print_outlined),
                          suffixIcon: _deliveryNotePrinterController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  tooltip: 'Use main receipt printer',
                                  onPressed: () => setState(() => _deliveryNotePrinterController.clear()),
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 16),
                action,
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleBox(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value
              ? (isDark ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFFEEF2FF))
              : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB)),
          border: Border.all(
            color: value
                ? const Color(0xFF6366F1)
                : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              visualDensity: VisualDensity.compact,
              activeColor: const Color(0xFF6366F1),
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: value ? FontWeight.bold : FontWeight.w500,
                  color: value ? const Color(0xFF6366F1) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _printerNameController.dispose();
    _labelPrinterController.dispose();
    _customPaperWidthController.dispose();
    _marginVMmController.dispose();
    _marginHMmController.dispose();
    _cashDrawerNetworkIpController.dispose();
    _cashDrawerNetworkPortController.dispose();
    _deliveryNotePrinterController.dispose();
    _sloganController.dispose();
    _invoicePrefixController.dispose();
    _termsController.dispose();
    _thankYouController.dispose();
    _returnPolicyController.dispose();
    _socialLinksController.dispose();
    super.dispose();
  }
}
