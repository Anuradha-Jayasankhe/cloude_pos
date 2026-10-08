import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'dart:convert';
import '../models/models.dart';

class PrintService {
  static Future<bool> kickCashDrawer({
    String? printerName,
    String method = 'print_job',
    int pin = 0,
    int onMs = 120,
    int offMs = 240,
    String? networkIp,
    int networkPort = 9100,
  }) async {
    final pulsePin = (pin == 1) ? 1 : 0;
    final tOn = (onMs ~/ 2).clamp(1, 255);
    final tOff = (offMs ~/ 2).clamp(1, 255);
    final kickCommand = Uint8List.fromList([0x1B, 0x70, pulsePin, tOn, tOff]);

    // 1. Network direct TCP socket kick
    if (method == 'network' || (method == 'hybrid' && networkIp != null && networkIp.trim().isNotEmpty)) {
      if (networkIp != null && networkIp.trim().isNotEmpty) {
        try {
          final socket = await Socket.connect(networkIp.trim(), networkPort, timeout: const Duration(seconds: 2));
          socket.add(kickCommand);
          await socket.flush();
          await socket.close();
          return true;
        } catch (_) {}
      }
    }

    // 2. Windows Raw Spooler / PowerShell kick
    if (Platform.isWindows && printerName != null && printerName.isNotEmpty && printerName != '__FIRST_PRINTER__') {
      try {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}\\SB_drawer_kick_${DateTime.now().millisecondsSinceEpoch}.bin');
        await tempFile.writeAsBytes(kickCommand);

        final res = await Process.run('powershell', [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          '''
          try {
            [System.IO.File]::WriteAllBytes("${tempFile.path.replaceAll(r'\', r'\\')}", [byte[]]@(0x1B, 0x70, $pulsePin, $tOn, $tOff))
            Get-Content -Path "${tempFile.path.replaceAll(r'\', r'\\')}" -Raw -Encoding Byte | Out-Printer -Name "$printerName"
          } catch {}
          '''
        ]);
        if (await tempFile.exists()) {
          try { await tempFile.delete(); } catch (_) {}
        }
        return res.exitCode == 0;
      } catch (_) {}
    }

    return false;
  }

  static Map<String, List<String>> _parseImeisFromNotes(String? notes) {
    if (notes == null || notes.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(notes);
      if (decoded is Map && decoded.containsKey('imeis')) {
        final imeisMap = decoded['imeis'];
        if (imeisMap is Map) {
          return imeisMap.map((k, v) {
            if (v is List) {
              return MapEntry(k.toString(), List<String>.from(v));
            }
            return MapEntry(k.toString(), <String>[]);
          });
        }
      }
    } catch (_) {}
    return {};
  }

  static String _parseCustomNotes(String? notes) {
    if (notes == null || notes.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(notes);
      if (decoded is Map && decoded.containsKey('custom')) {
        return decoded['custom']?.toString() ?? '';
      }
    } catch (_) {}
    return notes;
  }

  /// `pdf` core fonts (Helvetica/Courier) are limited for Unicode glyphs.
  /// Normalize dynamic text to avoid render warnings/crashes on unsupported chars.
  static String _pdfSafe(String value) {
    final normalized = value
        .replaceAll('රු.', 'Rs.')
        .replaceAll('රු', 'Rs.')
        .replaceAll('ரூ.', 'Rs.')
        .replaceAll('ரூ', 'Rs.')
        .replaceAll('\u2022', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u00A0', ' ');
    return normalized.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), '?');
  }

  static Future<Uint8List> generateReceiptPdf({
    required Sale sale,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
  }) async {
    final pdf = pw.Document();

    // Load embedded Unicode-capable font for reliable glyph rendering.
    pw.ThemeData? theme;
    try {
      final ttfData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final baseFont = pw.Font.ttf(ttfData);
      theme = pw.ThemeData.withFont(
        base: baseFont,
        bold: baseFont,
        italic: baseFont,
        boldItalic: baseFont,
      );
    } catch (e) {
      theme = null;
    }

    final isA4Printer = settings.printerType.trim().toUpperCase() == 'A4' ||
        settings.paperSize.trim().toUpperCase() == 'A4';
    final paperFormat = isA4Printer
        ? PdfPageFormat.a4
        : ((settings.paperWidthMm != null && settings.paperWidthMm! > 0)
            ? PdfPageFormat(
                settings.paperWidthMm! * PdfPageFormat.mm,
                double.infinity,
                marginAll: 2 * PdfPageFormat.mm,
              )
            : getThermalPaperFormat(settings.paperSize));

    final topMargin = (settings.marginVerticalMm != null && settings.marginVerticalMm! > 0)
        ? settings.marginVerticalMm! * PdfPageFormat.mm
        : settings.marginTop;
    final leftMargin = (settings.marginHorizontalMm != null && settings.marginHorizontalMm! > 0)
        ? settings.marginHorizontalMm! * PdfPageFormat.mm
        : settings.marginLeft;

    if (isA4Printer) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(topMargin),
          theme: theme,
          build: (context) => buildA4Invoice(
            sale: sale,
            settings: settings,
            currencySymbol: currencySymbol,
            storeName: storeName,
            storeAddress: storeAddress,
            storePhone: storePhone,
          ),
        ),
      );
    } else {
      // Thermal receipt
      pdf.addPage(
        pw.Page(
          pageFormat: paperFormat,
          margin: pw.EdgeInsets.only(
            top: topMargin,
            left: leftMargin,
            right: leftMargin,
            bottom: 10,
          ),
          theme: theme,
          build: (context) => buildThermalReceipt(
            sale: sale,
            settings: settings,
            currencySymbol: currencySymbol,
            storeName: storeName,
            storeAddress: storeAddress,
            storePhone: storePhone,
          ),
        ),
      );
    }

    return pdf.save();
  }

  static Future<void> printReceipt({
    required Sale sale,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
  }) async {
    final pdfBytes = await generateReceiptPdf(
      sale: sale,
      settings: settings,
      currencySymbol: currencySymbol,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
    );

    if (settings.printerName != null && settings.printerName!.isNotEmpty) {
      final printers = await Printing.listPrinters();
      Printer? target;
      if (settings.printerName == '__FIRST_PRINTER__' && printers.isNotEmpty) {
        target = printers.first;
      } else {
        target = printers.firstWhere(
          (p) =>
              p.name.toLowerCase().contains(settings.printerName!.toLowerCase()) ||
              p.url.toLowerCase().contains(settings.printerName!.toLowerCase()),
          orElse: () => const Printer(url: '', name: 'default'),
        );
      }
      if (target != null && target.url.isNotEmpty) {
        await Printing.directPrintPdf(
          printer: target,
          onLayout: (_) async => pdfBytes,
        );
        return;
      }
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Invoice_${sale.id}',
    );
  }

  static Future<void> printCreditPaymentReceipt({
    required String customerName,
    required String customerPhone,
    required String? customerAddress,
    required double paymentAmount,
    required double balanceBefore,
    required double balanceAfter,
    required String note,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
  }) async {
    final pdf = pw.Document();

    pw.ThemeData? theme;
    try {
      final ttfData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final baseFont = pw.Font.ttf(ttfData);
      theme = pw.ThemeData.withFont(
        base: baseFont,
        bold: baseFont,
        italic: baseFont,
        boldItalic: baseFont,
      );
    } catch (e) {
      theme = null;
    }

    final isA4Printer = settings.printerType.trim().toUpperCase() == 'A4';
    final paperFormat = isA4Printer
        ? PdfPageFormat.a4
        : getThermalPaperFormat(settings.paperSize);

    pw.Widget buildReceipt() {
      final titleStyle = pw.TextStyle(
        fontSize: settings.fontSize + 4,
        fontWeight: pw.FontWeight.bold,
      );
      final labelStyle = pw.TextStyle(fontSize: settings.fontSize);
      final valueStyle = pw.TextStyle(
        fontSize: settings.fontSize,
        fontWeight: pw.FontWeight.bold,
      );

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              'CREDIT PAYMENT RECEIPT',
              style: titleStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.Text(_pdfSafe(storeName), style: valueStyle),
          if (storeAddress.trim().isNotEmpty)
            pw.Text(_pdfSafe(storeAddress), style: labelStyle),
          if (storePhone.trim().isNotEmpty)
            pw.Text(_pdfSafe(storePhone), style: labelStyle),
          pw.SizedBox(height: 8),
          pw.Text('Customer: ${_pdfSafe(customerName)}', style: labelStyle),
          if (customerPhone.trim().isNotEmpty)
            pw.Text('Phone: ${_pdfSafe(customerPhone)}', style: labelStyle),
          if ((customerAddress ?? '').trim().isNotEmpty)
            pw.Text(
              'Address: ${_pdfSafe(customerAddress!.trim())}',
              style: labelStyle,
            ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Previous Balance', style: labelStyle),
              pw.Text(_money(currencySymbol, balanceBefore), style: valueStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Paid', style: labelStyle),
              pw.Text(_money(currencySymbol, paymentAmount), style: valueStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Outstanding', style: labelStyle),
              pw.Text(_money(currencySymbol, balanceAfter), style: valueStyle),
            ],
          ),
          if (note.trim().isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Note: ${_pdfSafe(note.trim())}', style: labelStyle),
          ],
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              'Thank you for your payment',
              style: valueStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      );
    }

    if (isA4Printer) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(settings.marginTop),
          theme: theme,
          build: (context) => [buildReceipt()],
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
          theme: theme,
          build: (context) => buildReceipt(),
        ),
      );
    }

    if (settings.printerName != null && settings.printerName!.isNotEmpty) {
      final printers = await Printing.listPrinters();
      final target = printers.firstWhere(
        (p) =>
            p.name.toLowerCase().contains(settings.printerName!.toLowerCase()) ||
            p.url.toLowerCase().contains(settings.printerName!.toLowerCase()),
        orElse: () => const Printer(url: '', name: 'default'),
      );
      if (target.url.isNotEmpty) {
        await Printing.directPrintPdf(
          printer: target,
          onLayout: (_) => pdf.save(),
        );
        return;
      }
    }

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'CreditPayment_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static String _getItemName(dynamic item) {
    if (item == null) return '';
    try {
      final name = item.productName;
      if (name != null) return name.toString();
    } catch (_) {}
    try {
      final name = item.name;
      if (name != null) return name.toString();
    } catch (_) {}
    return '';
  }

  static double _getItemQuantity(dynamic item) {
    if (item == null) return 0.0;
    try {
      final q = item.quantity;
      if (q != null) return (q as num).toDouble();
    } catch (_) {}
    try {
      final q = item.qty;
      if (q != null) return (q as num).toDouble();
    } catch (_) {}
    return 0.0;
  }

  static double _getItemTotal(dynamic item) {
    if (item == null) return 0.0;
    try {
      final lt = item.lineTotal;
      if (lt != null) return (lt as num).toDouble();
    } catch (_) {}
    try {
      final t = item.total;
      if (t != null) return (t as num).toDouble();
    } catch (_) {}
    return 0.0;
  }

  static int _getScheduleNo(dynamic schedule) {
    if (schedule == null) return 1;
    try {
      final no = schedule.installmentNo;
      if (no != null) return (no as num).toInt();
    } catch (_) {}
    return 1;
  }

  static DateTime _getScheduleDueDate(dynamic schedule) {
    if (schedule == null) return DateTime.now();
    try {
      final d = schedule.dueDate;
      if (d is DateTime) return d;
      if (d != null) return DateTime.tryParse(d.toString()) ?? DateTime.now();
    } catch (_) {}
    return DateTime.now();
  }

  static double _getScheduleAmount(dynamic schedule) {
    if (schedule == null) return 0.0;
    try {
      final amt = schedule.amount;
      if (amt != null) return (amt as num).toDouble();
    } catch (_) {}
    try {
      final amt = schedule.scheduledAmount;
      if (amt != null) return (amt as num).toDouble();
    } catch (_) {}
    return 0.0;
  }

  static double _getSchedulePaidAmount(dynamic schedule) {
    if (schedule == null) return 0.0;
    try {
      final paid = schedule.paidAmount;
      if (paid != null) return (paid as num).toDouble();
    } catch (_) {}
    return 0.0;
  }

  static double _getScheduleRemainingAmount(dynamic schedule) {
    if (schedule == null) return 0.0;
    try {
      final rem = schedule.remainingAmount;
      if (rem != null) return (rem as num).toDouble();
    } catch (_) {}
    final amt = _getScheduleAmount(schedule);
    final paid = _getSchedulePaidAmount(schedule);
    return (amt - paid).clamp(0, double.infinity).toDouble();
  }

  static bool _getScheduleIsPaid(
    dynamic schedule,
    double schedAmt,
    double paidAmt,
    double remAmt,
  ) {
    if (schedule == null) return false;
    try {
      if (schedule.isPaid == true) return true;
    } catch (_) {}
    return remAmt <= 0.01 || (paidAmt >= schedAmt && schedAmt > 0);
  }

  static Future<Uint8List> generateInstallmentPaymentReceiptPdf({
    required String customerName,
    required String customerPhone,
    required String? customerAddress,
    required String planId,
    required String saleId,
    required String paymentMethod,
    required double paymentAmount,
    required double balanceBefore,
    required double balanceAfter,
    required String note,
    required List<dynamic> items,
    required List<dynamic> schedules,
    required List<InstallmentPaymentLine> allocations,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
  }) async {
    final pdf = pw.Document();

    pw.ThemeData? theme;
    try {
      final ttfData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final baseFont = pw.Font.ttf(ttfData);
      theme = pw.ThemeData.withFont(
        base: baseFont,
        bold: baseFont,
        italic: baseFont,
        boldItalic: baseFont,
      );
    } catch (e) {
      theme = null;
    }

    final isA4Printer = settings.printerType.trim().toUpperCase() == 'A4';
    final paperFormat = isA4Printer
        ? PdfPageFormat.a4
        : getThermalPaperFormat(settings.paperSize);

    pw.Widget buildReceipt() {
      final baseFontSize = isA4Printer
          ? (settings.fontSize < 10.0 ? 10.0 : settings.fontSize)
          : (settings.fontSize < 9.0 ? 9.0 : settings.fontSize);

      final titleStyle = pw.TextStyle(
        fontSize: baseFontSize + 4,
        fontWeight: pw.FontWeight.bold,
      );
      final headerStyle = pw.TextStyle(
        fontSize: baseFontSize + 1.5,
        fontWeight: pw.FontWeight.bold,
      );
      final labelStyle = pw.TextStyle(fontSize: baseFontSize);
      final valueStyle = pw.TextStyle(
        fontSize: baseFontSize,
        fontWeight: pw.FontWeight.bold,
      );
      final paymentDate = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());
      final totalAmount = schedules.fold<double>(
        0,
        (sum, line) => sum + _getScheduleAmount(line),
      );
      final paidInstallments = schedules.where((line) {
        final schedAmt = _getScheduleAmount(line);
        final paidAmt = _getSchedulePaidAmount(line);
        final remAmt = _getScheduleRemainingAmount(line);
        return _getScheduleIsPaid(line, schedAmt, paidAmt, remAmt);
      }).length;
      final pendingInstallments = schedules.length - paidInstallments;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              'INSTALLMENT PAYMENT RECEIPT',
              style: titleStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1, color: const PdfColor(0.7, 0.7, 0.7)),
          pw.SizedBox(height: 4),
          pw.Text(_pdfSafe(storeName), style: valueStyle),
          if (storeAddress.trim().isNotEmpty)
            pw.Text(_pdfSafe(storeAddress), style: labelStyle),
          if (storePhone.trim().isNotEmpty)
            pw.Text(_pdfSafe(storePhone), style: labelStyle),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Invoice', style: labelStyle),
              pw.Text(_pdfSafe(saleId), style: valueStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Payment Date', style: labelStyle),
              pw.Text(_pdfSafe(paymentDate), style: labelStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Method', style: labelStyle),
              pw.Text(_pdfSafe(paymentMethod), style: labelStyle),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text('Customer: ${_pdfSafe(customerName)}', style: labelStyle),
          if (customerPhone.trim().isNotEmpty)
            pw.Text('Phone: ${_pdfSafe(customerPhone)}', style: labelStyle),
          if ((customerAddress ?? '').trim().isNotEmpty)
            pw.Text(
              'Address: ${_pdfSafe(customerAddress!.trim())}',
              style: labelStyle,
            ),
          pw.Text('Plan: ${_pdfSafe(planId)}', style: labelStyle),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.8, color: const PdfColor(0.8, 0.8, 0.8)),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Amount', style: labelStyle),
              pw.Text(_money(currencySymbol, totalAmount), style: valueStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Previous Balance', style: labelStyle),
              pw.Text(_money(currencySymbol, balanceBefore), style: valueStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Paid', style: labelStyle),
              pw.Text(_money(currencySymbol, paymentAmount), style: valueStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Remaining', style: labelStyle),
              pw.Text(_money(currencySymbol, balanceAfter), style: valueStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Paid Installments', style: labelStyle),
              pw.Text(
                '$paidInstallments / ${schedules.length}',
                style: valueStyle,
              ),
            ],
          ),
          if (pendingInstallments > 0)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Pending Installments', style: labelStyle),
                pw.Text(pendingInstallments.toString(), style: valueStyle),
              ],
            ),
          if (items.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Items', style: headerStyle),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(
                color: const PdfColor(0.75, 0.75, 0.75),
                width: 0.5,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.0),
                1: pw.FlexColumnWidth(0.8),
                2: pw.FlexColumnWidth(2.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor(0.35, 0.35, 0.35),
                  ),
                  children: [
                    _a4Cell('Item', bold: true, color: PdfColors.white),
                    _a4Cell(
                      'Qty',
                      bold: true,
                      color: PdfColors.white,
                      align: pw.TextAlign.center,
                    ),
                    _a4Cell(
                      'Total',
                      bold: true,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                ...items.map(
                  (item) => pw.TableRow(
                    children: [
                      _a4Cell(_pdfSafe(_getItemName(item))),
                      _a4Cell(
                        _formatQuantity(_getItemQuantity(item)),
                        align: pw.TextAlign.center,
                      ),
                      _a4Cell(
                        _money(currencySymbol, _getItemTotal(item)),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (note.trim().isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Note: ${_pdfSafe(note.trim())}', style: labelStyle),
          ],
          pw.SizedBox(height: 10),
          pw.Text('Payment Schedule', style: headerStyle),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(
              color: const PdfColor(0.75, 0.75, 0.75),
              width: 0.5,
            ),
            columnWidths: isA4Printer
                ? const {
                    0: pw.FlexColumnWidth(0.6),
                    1: pw.FlexColumnWidth(2.2),
                    2: pw.FlexColumnWidth(1.8),
                    3: pw.FlexColumnWidth(1.8),
                    4: pw.FlexColumnWidth(1.8),
                    5: pw.FlexColumnWidth(1.8),
                  }
                : const {
                    0: pw.FlexColumnWidth(0.5),
                    1: pw.FlexColumnWidth(2.1),
                    2: pw.FlexColumnWidth(1.6),
                    3: pw.FlexColumnWidth(1.6),
                    4: pw.FlexColumnWidth(1.6),
                    5: pw.FlexColumnWidth(1.5),
                  },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor(0.35, 0.35, 0.35),
                ),
                children: [
                  _a4Cell(
                    'No',
                    bold: true,
                    color: PdfColors.white,
                    align: pw.TextAlign.center,
                    fontSize: isA4Printer ? 8.5 : 7.5,
                  ),
                  _a4Cell(
                    'Due Date',
                    bold: true,
                    color: PdfColors.white,
                    fontSize: isA4Printer ? 8.5 : 7.5,
                  ),
                  _a4Cell(
                    'Amount',
                    bold: true,
                    color: PdfColors.white,
                    align: pw.TextAlign.right,
                    fontSize: isA4Printer ? 8.5 : 7.5,
                  ),
                  _a4Cell(
                    'Paid',
                    bold: true,
                    color: PdfColors.white,
                    align: pw.TextAlign.right,
                    fontSize: isA4Printer ? 8.5 : 7.5,
                  ),
                  _a4Cell(
                    'Due',
                    bold: true,
                    color: PdfColors.white,
                    align: pw.TextAlign.right,
                    fontSize: isA4Printer ? 8.5 : 7.5,
                  ),
                  _a4Cell(
                    'Status',
                    bold: true,
                    color: PdfColors.white,
                    align: pw.TextAlign.center,
                    fontSize: isA4Printer ? 8.5 : 7.5,
                  ),
                ],
              ),
              ...schedules.map((schedule) {
                final schedAmt = _getScheduleAmount(schedule);
                final paidAmt = _getSchedulePaidAmount(schedule);
                final remAmt = _getScheduleRemainingAmount(schedule);
                final isPaid = _getScheduleIsPaid(
                  schedule,
                  schedAmt,
                  paidAmt,
                  remAmt,
                );
                final status = isPaid
                    ? 'PAID'
                    : paidAmt > 0
                    ? 'PARTIAL'
                    : 'DUE';
                final tblFontSize = isA4Printer ? 8.5 : 7.5;
                return pw.TableRow(
                  children: [
                    _a4Cell(
                      '${_getScheduleNo(schedule)}',
                      align: pw.TextAlign.center,
                      fontSize: tblFontSize,
                    ),
                    _a4Cell(
                      _formatDateShort(_getScheduleDueDate(schedule)),
                      fontSize: tblFontSize,
                    ),
                    _a4Cell(
                      _money(currencySymbol, schedAmt),
                      align: pw.TextAlign.right,
                      fontSize: tblFontSize,
                    ),
                    _a4Cell(
                      _money(currencySymbol, paidAmt),
                      align: pw.TextAlign.right,
                      fontSize: tblFontSize,
                    ),
                    _a4Cell(
                      _money(currencySymbol, remAmt),
                      align: pw.TextAlign.right,
                      fontSize: tblFontSize,
                    ),
                    _a4Cell(
                      status,
                      align: pw.TextAlign.center,
                      bold: isPaid,
                      fontSize: tblFontSize,
                    ),
                  ],
                );
              }),
            ],
          ),
          if (allocations.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('This Payment Applied To', style: headerStyle),
            pw.SizedBox(height: 4),
            ...allocations.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  '#${line.installmentNo} ${_formatDateShort(line.dueDate)}  Scheduled ${_money(currencySymbol, line.scheduledAmount)}  Paid ${_money(currencySymbol, line.paidAmount)}  Due ${_money(currencySymbol, line.remainingAmount)}',
                  style: labelStyle,
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Divider(thickness: 0.8, color: const PdfColor(0.8, 0.8, 0.8)),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Thank you for your payment',
              style: valueStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      );
    }

    if (isA4Printer) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(
            settings.marginTop > 0 ? settings.marginTop : 15,
          ),
          theme: theme,
          build: (context) => [buildReceipt()],
        ),
      );
    } else {
      pdf.addPage(
        pw.Page(
          pageFormat: paperFormat,
          margin: pw.EdgeInsets.only(
            top: settings.marginTop > 0 ? settings.marginTop : 6,
            left: settings.marginLeft > 0 ? settings.marginLeft : 6,
            right: settings.marginLeft > 0 ? settings.marginLeft : 6,
            bottom: 8,
          ),
          theme: theme,
          build: (context) => buildReceipt(),
        ),
      );
    }

    return pdf.save();
  }

  static Future<void> printInstallmentPaymentReceipt({
    required String customerName,
    required String customerPhone,
    required String? customerAddress,
    required String planId,
    required String saleId,
    required String paymentMethod,
    required double paymentAmount,
    required double balanceBefore,
    required double balanceAfter,
    required String note,
    required List<dynamic> items,
    required List<dynamic> schedules,
    required List<InstallmentPaymentLine> allocations,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
  }) async {
    final pdfBytes = await generateInstallmentPaymentReceiptPdf(
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      planId: planId,
      saleId: saleId,
      paymentMethod: paymentMethod,
      paymentAmount: paymentAmount,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      note: note,
      items: items,
      schedules: schedules,
      allocations: allocations,
      settings: settings,
      currencySymbol: currencySymbol,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
    );

    if (settings.printerName != null && settings.printerName!.isNotEmpty) {
      final printers = await Printing.listPrinters();
      final target = printers.firstWhere(
        (p) =>
            p.name.toLowerCase().contains(settings.printerName!.toLowerCase()) ||
            p.url.toLowerCase().contains(settings.printerName!.toLowerCase()),
        orElse: () => const Printer(url: '', name: 'default'),
      );
      if (target.url.isNotEmpty) {
        await Printing.directPrintPdf(
          printer: target,
          onLayout: (_) async => pdfBytes,
        );
        return;
      }
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'InstallmentPayment_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static PdfPageFormat getThermalPaperFormat(String size) {
    if (size == '58mm') {
      return PdfPageFormat(
        58 * PdfPageFormat.mm,
        double.infinity,
        marginAll: 2 * PdfPageFormat.mm,
      );
    }
    if (size.endsWith('mm')) {
      final parsed = double.tryParse(size.replaceAll('mm', '').trim());
      if (parsed != null && parsed > 0) {
        return PdfPageFormat(
          parsed * PdfPageFormat.mm,
          double.infinity,
          marginAll: 3 * PdfPageFormat.mm,
        );
      }
    }
    final numeric = double.tryParse(size.trim());
    if (numeric != null && numeric > 0) {
      return PdfPageFormat(
        numeric * PdfPageFormat.mm,
        double.infinity,
        marginAll: 3 * PdfPageFormat.mm,
      );
    }
    return PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 3 * PdfPageFormat.mm,
    );
  }

  static String _money(String currencySymbol, double value) {
    return _pdfSafe('$currencySymbol ${value.toStringAsFixed(2)}');
  }

  static String _negativeMoney(String currencySymbol, double value) {
    return _pdfSafe('-$currencySymbol ${value.toStringAsFixed(2)}');
  }

  static String _formatQuantity(double quantity) {
    return quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);
  }

  static String _displayInvoiceNumber(Sale sale) {
    final invoiceNumber = sale.invoiceNumber?.trim();
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      return invoiceNumber;
    }
    final source = sale.id.trim();
    if (source.length <= 18) {
      return source;
    }

    final compactSource = source.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (compactSource.length >= 8) {
      return 'INV-${compactSource.substring(compactSource.length - 8).toUpperCase()}';
    }

    return '${source.substring(0, 15)}...';
  }

  static String _displayCashierName(Sale sale) {
    final cashierName = sale.cashierName?.trim();
    if (cashierName != null && cashierName.isNotEmpty) {
      return cashierName;
    }

    final employeeId = sale.employeeId.trim();
    return employeeId.isEmpty ? 'Cashier' : employeeId;
  }

  static String _formatDateShort(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  static pw.Widget buildThermalReceipt({
    required Sale sale,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
  }) {
    final fontSize = settings.fontSize;
    final textStyle = pw.TextStyle(fontSize: fontSize);
    final boldStyle = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: pw.FontWeight.bold,
    );
    final titleStyle = pw.TextStyle(
      fontSize: fontSize + 5,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 1.2,
    );
    final sectionStyle = pw.TextStyle(
      fontSize: fontSize + 1,
      fontWeight: pw.FontWeight.bold,
    );
    final smallStyle = pw.TextStyle(fontSize: fontSize - 1);
    final customNote = _parseCustomNotes(sale.notes);
    final invoiceNumber = _displayInvoiceNumber(sale);
    final cashierName = _displayCashierName(sale);
    final saleDate = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format((sale.createdAt ?? DateTime.now()).toLocal());
    final amountPaid = sale.amountPaid ?? sale.total;
    final balance = sale.balance ?? (sale.total - amountPaid);
    final lineDiscountTotal = sale.items.fold<double>(
      0.0,
      (sum, item) =>
          sum +
          ((item.originalPrice - item.unitPrice) * item.quantity).clamp(
            0.0,
            double.infinity,
          ),
    );
    final originalSubtotal = sale.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.originalPrice * item.quantity),
    );
    final isInstallmentSale =
        sale.paymentMethod.trim().toUpperCase() == 'INSTALLMENT';
    final installmentCount = sale.installmentSchedules.length;
    final monthlyInstallment = installmentCount > 0
        ? sale.installmentSchedules.first.scheduledAmount
        : balance;
    final customerOutstandingBefore = sale.customerOutstandingBefore;
    double? customerOutstandingAfter = sale.customerOutstandingAfter;
    if (isInstallmentSale && installmentCount > 0) {
      customerOutstandingAfter = sale.installmentSchedules.fold<double>(
        0.0,
        (sum, item) => sum + item.remainingAmount,
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (settings.showShopHeader) ...[
          pw.Center(
            child: pw.Text(
              _pdfSafe(storeName),
              style: pw.TextStyle(
                fontSize: fontSize + 4,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          if (settings.showSlogan && (settings.invoiceSlogan?.trim().isNotEmpty == true)) ...[
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                _pdfSafe(settings.invoiceSlogan?.trim() ?? ''),
                style: pw.TextStyle(
                  fontSize: fontSize - 1,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
          if (storeAddress.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                _pdfSafe(storeAddress),
                style: smallStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
          if (storePhone.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                _pdfSafe(storePhone),
                style: smallStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
          pw.SizedBox(height: 6),
        ],
        pw.Divider(thickness: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            isInstallmentSale ? 'INSTALLMENT AGREEMENT' : 'RECEIPT',
            style: titleStyle,
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 6),
        if (settings.showInvoiceNumber)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Invoice', style: textStyle),
              pw.Text(_pdfSafe(invoiceNumber), style: boldStyle),
            ],
          ),
        if (settings.showDateTime)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Date', style: textStyle),
              pw.Text(_pdfSafe(saleDate), style: textStyle),
            ],
          ),
        if (settings.showCashierName)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cashier', style: textStyle),
              pw.Text(_pdfSafe(cashierName), style: textStyle),
            ],
          ),
        if (settings.showCustomerName &&
            sale.customer != null &&
            sale.customer!.name.trim().isNotEmpty &&
            sale.customer!.name != 'Walk-in Customer') ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Customer', style: textStyle),
              pw.Text(_pdfSafe(sale.customer!.name), style: boldStyle),
            ],
          ),
          if (sale.customer!.phone.trim().isNotEmpty)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Phone', style: textStyle),
                pw.Text(_pdfSafe(sale.customer!.phone), style: textStyle),
              ],
            ),
          if (settings.showCustomerAddress &&
              sale.customer!.address != null &&
              sale.customer!.address!.trim().isNotEmpty)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Address', style: textStyle),
                pw.Text(_pdfSafe(sale.customer!.address!), style: textStyle),
              ],
            ),
          if (sale.shippingAddress != null &&
              sale.shippingAddress!.trim().isNotEmpty)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Shipping Address', style: boldStyle),
                pw.Text(_pdfSafe(sale.shippingAddress!), style: textStyle),
              ],
            ),
        ],
        if ((customerOutstandingBefore ?? 0) > 0 ||
            (customerOutstandingAfter ?? 0) > 0) ...[
          pw.SizedBox(height: 8),
          pw.Text('Customer Balance', style: sectionStyle),
          if ((customerOutstandingBefore ?? 0) > 0)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Before', style: smallStyle),
                pw.Text(
                  _money(currencySymbol, customerOutstandingBefore ?? 0.0),
                  style: smallStyle,
                ),
              ],
            ),
          if ((customerOutstandingAfter ?? 0) > 0)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('After', style: smallStyle),
                pw.Text(
                  _money(currencySymbol, customerOutstandingAfter ?? 0.0),
                  style: smallStyle,
                ),
              ],
            ),
        ],
        if (settings.showItemTable) ...[
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 0.8, color: PdfColors.black),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('Item', style: sectionStyle)),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'Qty',
                    style: sectionStyle,
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Total',
                    style: sectionStyle,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          pw.Divider(thickness: 0.8, color: PdfColors.black),
          ...sale.items.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            final lineDiscount =
                ((item.originalPrice - item.unitPrice) * item.quantity).clamp(
                  0.0,
                  double.infinity,
                );
            final imeisMap = _parseImeisFromNotes(sale.notes);
            final itemImeis = imeisMap[item.productId] ?? [];
            final itemDisplayName = settings.showItemNumbers
                ? '$idx. ${_pdfSafe(item.productName)}'
                : _pdfSafe(item.productName);

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          itemDisplayName,
                          style: textStyle,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          _formatQuantity(item.quantity),
                          style: textStyle,
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          _money(currencySymbol, item.total),
                          style: textStyle,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${_money(currencySymbol, item.originalPrice)} x ${_formatQuantity(item.quantity)}',
                    style: smallStyle,
                  ),
                  if (itemImeis.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        'IMEI: ${itemImeis.join(", ")}',
                        style: smallStyle.copyWith(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  if (lineDiscount > 0)
                    pw.Text(
                      'Discount: ${_negativeMoney(currencySymbol, lineDiscount)}',
                      style: smallStyle,
                    ),
                ],
              ),
            );
          }),
        ],
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.8, color: PdfColors.black),
        if (settings.showSubtotal)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Sub Total', style: textStyle),
              pw.Text(_money(currencySymbol, originalSubtotal), style: textStyle),
            ],
          ),
        if (settings.showDiscount && lineDiscountTotal > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Discount', style: textStyle),
              pw.Text(
                _negativeMoney(currencySymbol, lineDiscountTotal),
                style: textStyle,
              ),
            ],
          ),
        if (settings.showDiscount && sale.discount > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Invoice Discount', style: textStyle),
              pw.Text(
                _negativeMoney(currencySymbol, sale.discount),
                style: textStyle,
              ),
            ],
          ),
        if (settings.showTax && sale.tax > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tax', style: textStyle),
              pw.Text(_money(currencySymbol, sale.tax), style: textStyle),
            ],
          ),
        if (sale.shippingCharges > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Shipping / Delivery', style: textStyle),
              pw.Text(
                _money(currencySymbol, sale.shippingCharges),
                style: textStyle,
              ),
            ],
          ),
        if (settings.showTotal) ...[
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 0.8, color: PdfColors.black),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total',
                style: pw.TextStyle(
                  fontSize: fontSize + 3,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _money(currencySymbol, sale.total),
                style: pw.TextStyle(
                  fontSize: fontSize + 3,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        if (isInstallmentSale && installmentCount > 0) ...[
          pw.SizedBox(height: 10),
          pw.Text('FINANCIAL SUMMARY', style: sectionStyle),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Amount', style: textStyle),
              pw.Text(_money(currencySymbol, sale.total), style: textStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Down Payment', style: textStyle),
              pw.Text(_money(currencySymbol, amountPaid), style: textStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Remaining Amount', style: textStyle),
              pw.Text(_money(currencySymbol, balance), style: textStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Number of Installments', style: textStyle),
              pw.Text(installmentCount.toString(), style: textStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Monthly Installment', style: textStyle),
              pw.Text(
                _money(currencySymbol, monthlyInstallment),
                style: textStyle,
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('PAYMENT SCHEDULE', style: sectionStyle),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(
              color: const PdfColor(0.72, 0.72, 0.72),
              width: 0.5,
            ),
            columnWidths: const {
              0: pw.FixedColumnWidth(18),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FixedColumnWidth(54),
              3: pw.FixedColumnWidth(54),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor(0.45, 0.45, 0.45),
                ),
                children: [
                  _a4Cell(
                    '#',
                    bold: true,
                    color: PdfColors.white,
                    align: pw.TextAlign.center,
                  ),
                  _a4Cell('Due Date', bold: true, color: PdfColors.white),
                  _a4Cell(
                    'Amount',
                    bold: true,
                    color: PdfColors.white,
                    align: pw.TextAlign.right,
                  ),
                  _a4Cell(
                    'Status',
                    bold: true,
                    color: PdfColors.white,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              ...sale.installmentSchedules.map(
                (schedule) => pw.TableRow(
                  children: [
                    _a4Cell(
                      '${schedule.installmentNo}',
                      align: pw.TextAlign.center,
                    ),
                    _a4Cell(_formatDateShort(schedule.dueDate)),
                    _a4Cell(
                      _money(currencySymbol, schedule.scheduledAmount),
                      align: pw.TextAlign.right,
                    ),
                    _a4Cell(
                      schedule.isPaid
                          ? 'Paid'
                          : (schedule.paidAmount > 0
                                ? 'Bal: ${_money(currencySymbol, schedule.remainingAmount)}'
                                : 'Unpaid'),
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('IMPORTANT NOTES', style: sectionStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            '- Please make payments on or before the due date',
            style: smallStyle,
          ),
          pw.Text(
            '- Late payments may incur additional charges',
            style: smallStyle,
          ),
          pw.Text('- Keep this receipt for your records', style: smallStyle),
        ] else if (settings.showPaymentDetails) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Payment Details',
            style: pw.TextStyle(
              fontSize: fontSize + 2,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(_pdfSafe(sale.paymentMethod), style: textStyle),
              pw.Text(
                _money(
                  currencySymbol,
                  sale.paymentMethod.trim().toUpperCase() == 'CREDIT'
                      ? balance
                      : amountPaid,
                ),
                style: textStyle,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 0.8, color: PdfColors.black),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Paid', style: textStyle),
              pw.Text(_money(currencySymbol, amountPaid), style: textStyle),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                sale.paymentMethod.trim().toUpperCase() == 'COD'
                    ? 'Due Amount'
                    : (sale.paymentMethod.trim().toUpperCase() == 'CREDIT' ||
                              sale.paymentMethod.trim().toUpperCase() ==
                                  'INSTALLMENT'
                          ? 'Remaining Due'
                          : (balance < 0 ? 'Change Due' : 'Balance')),
                style: textStyle,
              ),
              pw.Text(
                _money(currencySymbol, balance < 0 ? -balance : balance),
                style: textStyle,
              ),
            ],
          ),
          if (isInstallmentSale && sale.installmentSchedules.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Installment Schedule', style: sectionStyle),
            pw.SizedBox(height: 4),
            ...sale.installmentSchedules.map(
              (schedule) => pw.Text(
                '#${schedule.installmentNo} ${_formatDateShort(schedule.dueDate)} ${_money(currencySymbol, schedule.scheduledAmount)} paid ${_money(currencySymbol, schedule.paidAmount)} due ${_money(currencySymbol, schedule.remainingAmount)}',
                style: smallStyle,
              ),
            ),
          ],
        ],
        if (sale.paymentMethod.trim().toUpperCase() == 'COD') ...[
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('[  ] PAID      [  ] UNPAID', style: boldStyle),
          ),
          pw.SizedBox(height: 10),
        ],
        if (customNote.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text('Notes: ${_pdfSafe(customNote)}', style: smallStyle),
        ],
        if (settings.showTerms && (settings.invoiceTerms?.trim().isNotEmpty == true)) ...[
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 0.5, color: PdfColors.grey),
          pw.Text(
            'Terms & Conditions:',
            style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(_pdfSafe(settings.invoiceTerms?.trim() ?? ''), style: smallStyle),
        ],
        if (settings.showFooter) ...[
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              _pdfSafe(settings.thankYouMessage),
              style: textStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Thank you for your purchase!',
              style: boldStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
        if (sale.paymentMethod.trim().toUpperCase() == 'COD') ...[
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('.............................', style: smallStyle),
                  pw.SizedBox(height: 2),
                  pw.Text('Delivery Person', style: boldStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('.............................', style: smallStyle),
                  pw.SizedBox(height: 2),
                  pw.Text('Customer Sign', style: boldStyle),
                ],
              ),
            ],
          ),
        ],
        if (settings.showFooter) ...[
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              _pdfSafe(
                'Powered by StoreBuddy POS Software | ${storePhone.trim().isEmpty ? storeName : storePhone} | www.storebuddy.com.lk',
              ),
              style: smallStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  static List<pw.Widget> buildA4Invoice({
    required Sale sale,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
  }) {
    final invoiceNo = _displayInvoiceNumber(sale);
    final invoiceDate = DateFormat(
      'dd-MM-yyyy',
    ).format((sale.createdAt ?? DateTime.now()).toLocal());
    final subtotal =
        sale.total - sale.tax + sale.discount - sale.shippingCharges;
    final amountPaid = sale.amountPaid ?? sale.total;
    final balance = sale.balance ?? (sale.total - amountPaid);
    final outstandingPayment = balance.clamp(0.0, double.infinity);
    final isInstallmentSale =
        sale.paymentMethod.trim().toUpperCase() == 'INSTALLMENT';
    final installmentCount = sale.installmentSchedules.length;
    final monthlyInstallment = installmentCount > 0
        ? sale.installmentSchedules.first.scheduledAmount
        : balance;
    final customerOutstandingBefore = sale.customerOutstandingBefore;
    double? customerOutstandingAfter = sale.customerOutstandingAfter;
    if (isInstallmentSale && installmentCount > 0) {
      customerOutstandingAfter = sale.installmentSchedules.fold<double>(
        0.0,
        (sum, item) => sum + item.remainingAmount,
      );
    }

    return [
      if (settings.showShopHeader)
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          color: const PdfColor(0.38, 0.38, 0.38),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 78,
                height: 78,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.white, width: 1),
                ),
                child: pw.Text(
                  'LOGO',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _pdfSafe(storeName),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (settings.showSlogan && (settings.invoiceSlogan?.trim().isNotEmpty == true)) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _pdfSafe(settings.invoiceSlogan?.trim() ?? ''),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _pdfSafe(storeAddress),
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      _pdfSafe(storePhone),
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      pw.SizedBox(height: 10),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                isInstallmentSale ? 'INSTALLMENT AGREEMENT' : 'INVOICE',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.45, 0.45, 0.45),
                ),
              ),
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (settings.showInvoiceNumber)
                pw.Text(
                  invoiceNo,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor(0.35, 0.35, 0.35),
                  ),
                ),
              if (settings.showDateTime)
                pw.Text(
                  invoiceDate,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
                ),
            ],
          ),
        ],
      ),
      if (isInstallmentSale && sale.installmentSchedules.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        pw.Text(
          'PAYMENT SCHEDULE',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(
            color: const PdfColor(0.75, 0.75, 0.75),
            width: 0.5,
          ),
          columnWidths: const {
            0: pw.FixedColumnWidth(36),
            1: pw.FlexColumnWidth(4),
            2: pw.FixedColumnWidth(78),
            3: pw.FixedColumnWidth(90),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor(0.45, 0.45, 0.45),
              ),
              children: [
                _a4Cell(
                  'No',
                  bold: true,
                  color: PdfColors.white,
                  align: pw.TextAlign.center,
                ),
                _a4Cell('Due Date', bold: true, color: PdfColors.white),
                _a4Cell(
                  'Amount',
                  bold: true,
                  color: PdfColors.white,
                  align: pw.TextAlign.right,
                ),
                _a4Cell(
                  'Status',
                  bold: true,
                  color: PdfColors.white,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
            ...sale.installmentSchedules.map(
              (schedule) => pw.TableRow(
                children: [
                  _a4Cell(
                    '${schedule.installmentNo}',
                    align: pw.TextAlign.center,
                  ),
                  _a4Cell(_formatDateShort(schedule.dueDate)),
                  _a4Cell(
                    _money(currencySymbol, schedule.scheduledAmount),
                    align: pw.TextAlign.right,
                  ),
                  _a4Cell(
                    schedule.isPaid
                        ? 'Paid'
                        : (schedule.paidAmount > 0
                              ? 'Bal: ${_money(currencySymbol, schedule.remainingAmount)}'
                              : 'Unpaid'),
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      pw.SizedBox(height: 12),
      if (settings.showCustomerName)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _pdfSafe(sale.customer?.phone ?? ''),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _pdfSafe(sale.customer?.name ?? 'Walk-in Customer'),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    if (settings.showCustomerAddress &&
                        sale.customer?.address != null &&
                        sale.customer!.address!.trim().isNotEmpty)
                      pw.Text(
                        _pdfSafe(sale.customer!.address!),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (sale.shippingAddress != null &&
                        sale.shippingAddress!.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Shipping Address:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        _pdfSafe(sale.shippingAddress!),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      if ((customerOutstandingBefore ?? 0) > 0 ||
          (customerOutstandingAfter ?? 0) > 0)
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if ((customerOutstandingBefore ?? 0) > 0)
                pw.Text(
                  'Customer Balance Before: $currencySymbol ${(customerOutstandingBefore ?? 0.0).toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                )
              else
                pw.SizedBox(),
              if ((customerOutstandingAfter ?? 0) > 0)
                pw.Text(
                  'Customer Balance After: $currencySymbol ${(customerOutstandingAfter ?? 0.0).toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
      if (isInstallmentSale && sale.installmentSchedules.isNotEmpty)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'Installment Schedule',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(
                color: const PdfColor(0.75, 0.75, 0.75),
                width: 0.5,
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(34),
                1: pw.FixedColumnWidth(70),
                2: pw.FixedColumnWidth(72),
                3: pw.FixedColumnWidth(72),
                4: pw.FixedColumnWidth(72),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor(0.45, 0.45, 0.45),
                  ),
                  children: [
                    _a4Cell('No', bold: true, color: PdfColors.white),
                    _a4Cell('Due Date', bold: true, color: PdfColors.white),
                    _a4Cell(
                      'Amount',
                      bold: true,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _a4Cell(
                      'Paid',
                      bold: true,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                    _a4Cell(
                      'Remaining',
                      bold: true,
                      color: PdfColors.white,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                ...sale.installmentSchedules.map(
                  (schedule) => pw.TableRow(
                    children: [
                      _a4Cell(
                        '${schedule.installmentNo}',
                        align: pw.TextAlign.center,
                      ),
                      _a4Cell(_formatDateShort(schedule.dueDate)),
                      _a4Cell(
                        _money(currencySymbol, schedule.scheduledAmount),
                        align: pw.TextAlign.right,
                      ),
                      _a4Cell(
                        _money(currencySymbol, schedule.paidAmount),
                        align: pw.TextAlign.right,
                      ),
                      _a4Cell(
                        _money(currencySymbol, schedule.remainingAmount),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
        ),
      if (settings.showItemTable)
        pw.Table(
          border: pw.TableBorder.all(
            color: const PdfColor(0.75, 0.75, 0.75),
            width: 0.6,
          ),
          columnWidths: {
            if (settings.showItemNumbers) 0: const pw.FixedColumnWidth(34),
            1: const pw.FlexColumnWidth(4),
            2: const pw.FixedColumnWidth(52),
            3: const pw.FixedColumnWidth(72),
            4: const pw.FixedColumnWidth(72),
            5: const pw.FixedColumnWidth(88),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor(0.45, 0.45, 0.45),
              ),
              children: [
                if (settings.showItemNumbers)
                  _a4Cell('Sr no.', bold: true, color: PdfColors.white),
                _a4Cell('Product', bold: true, color: PdfColors.white),
                _a4Cell(
                  'Qty',
                  bold: true,
                  color: PdfColors.white,
                  align: pw.TextAlign.right,
                ),
                _a4Cell(
                  'Rate',
                  bold: true,
                  color: PdfColors.white,
                  align: pw.TextAlign.right,
                ),
                _a4Cell(
                  'Disc',
                  bold: true,
                  color: PdfColors.white,
                  align: pw.TextAlign.right,
                ),
                _a4Cell(
                  'Amount',
                  bold: true,
                  color: PdfColors.white,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
            ...sale.items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              final lineDiscount =
                  ((item.originalPrice - item.unitPrice) * item.quantity).clamp(
                    0.0,
                    double.infinity,
                  );
              final imeisMap = _parseImeisFromNotes(sale.notes);
              final itemImeis = imeisMap[item.productId] ?? [];

              return pw.TableRow(
                children: [
                  if (settings.showItemNumbers)
                    _a4Cell('$idx', align: pw.TextAlign.center),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _pdfSafe(item.productName),
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                        if (itemImeis.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'IMEI: ${itemImeis.join(", ")}',
                              style: pw.TextStyle(
                                fontSize: 8.0,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _a4Cell(
                    item.quantity.toStringAsFixed(2),
                    align: pw.TextAlign.right,
                  ),
                  _a4Cell(
                    item.originalPrice.toStringAsFixed(2),
                    align: pw.TextAlign.right,
                  ),
                  _a4Cell(
                    lineDiscount > 0 ? lineDiscount.toStringAsFixed(2) : '-',
                    align: pw.TextAlign.right,
                  ),
                  _a4Cell(
                    item.total.toStringAsFixed(2),
                    align: pw.TextAlign.right,
                  ),
                ],
              );
            }),
          ],
        ),
      pw.SizedBox(height: 12),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (_parseCustomNotes(sale.notes).isNotEmpty) ...[
                  pw.Text(
                    'Notes: ${_pdfSafe(_parseCustomNotes(sale.notes))}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],
                pw.Container(height: 1, color: const PdfColor(0.7, 0.7, 0.7)),
                if (settings.showTerms && (settings.invoiceTerms?.trim().isNotEmpty == true)) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Terms & Conditions',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _pdfSafe(settings.invoiceTerms?.trim() ?? ''),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
                if (settings.showFooter) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Please Note',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _pdfSafe(settings.thankYouMessage),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (settings.returnPolicy != null &&
                      settings.returnPolicy!.trim().isNotEmpty)
                    pw.Text(
                      _pdfSafe(settings.returnPolicy!),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
                if (sale.paymentMethod.trim().toUpperCase() == 'COD') ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Payment Status: [  ] Paid    [  ] Unpaid',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Container(
            width: 230,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: const PdfColor(0.7, 0.7, 0.7),
                width: 0.6,
              ),
            ),
            child: pw.Column(
              children: [
                if (isInstallmentSale && installmentCount > 0) ...[
                  _a4SummaryRow(
                    'Total Amount',
                    '$currencySymbol ${sale.total.toStringAsFixed(2)}',
                  ),
                  _a4SummaryRow(
                    'Down Payment',
                    '$currencySymbol ${amountPaid.toStringAsFixed(2)}',
                  ),
                  _a4SummaryRow(
                    'Remaining Amount',
                    '$currencySymbol ${balance.toStringAsFixed(2)}',
                  ),
                  _a4SummaryRow(
                    'Number of Installments',
                    installmentCount.toString(),
                  ),
                  _a4SummaryRow(
                    'Monthly Installment',
                    '$currencySymbol ${monthlyInstallment.toStringAsFixed(2)}',
                  ),
                  pw.SizedBox(height: 4),
                ],
                if (settings.showSubtotal)
                  _a4SummaryRow(
                    'Sub Total',
                    '$currencySymbol ${subtotal.toStringAsFixed(2)}',
                    bold: true,
                  ),
                if (settings.showDiscount && sale.discount > 0)
                  _a4SummaryRow(
                    '(-) Discount',
                    '$currencySymbol ${sale.discount.toStringAsFixed(2)}',
                  ),
                if (settings.showTax && sale.tax != 0)
                  _a4SummaryRow(
                    '(+/-) Adjustment',
                    sale.tax < 0
                        ? '-$currencySymbol ${sale.tax.abs().toStringAsFixed(2)}'
                        : '$currencySymbol ${sale.tax.toStringAsFixed(2)}',
                  ),
                if (sale.shippingCharges > 0)
                  _a4SummaryRow(
                    '(+) Shipping / Delivery',
                    '$currencySymbol ${sale.shippingCharges.toStringAsFixed(2)}',
                  ),
                if (settings.showTotal)
                  pw.Container(
                    height: 20,
                    color: const PdfColor(0.35, 0.35, 0.35),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Grand Total',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          '$currencySymbol ${sale.total.toStringAsFixed(2)}',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (settings.showPaymentDetails) ...[
                  _a4SummaryRow(
                    'Paid ($invoiceDate)',
                    '$currencySymbol ${amountPaid.toStringAsFixed(2)}',
                  ),
                  _a4SummaryRow(
                    sale.paymentMethod.trim().toUpperCase() == 'COD'
                        ? 'Due Amount'
                        : (sale.paymentMethod.trim().toUpperCase() == 'CREDIT' ||
                                  sale.paymentMethod.trim().toUpperCase() ==
                                      'INSTALLMENT'
                              ? 'Remaining Due'
                              : (balance < 0 ? 'Change Due' : 'Balance')),
                    '$currencySymbol ${(balance < 0 ? -balance : balance).toStringAsFixed(2)}',
                  ),
                ],
                if ((customerOutstandingBefore ?? 0) > 0)
                  _a4SummaryRow(
                    'Customer Balance Before',
                    '$currencySymbol ${(customerOutstandingBefore ?? 0.0).toStringAsFixed(2)}',
                  ),
                if ((customerOutstandingAfter ?? 0) > 0)
                  _a4SummaryRow(
                    'Customer Balance After',
                    '$currencySymbol ${(customerOutstandingAfter ?? 0.0).toStringAsFixed(2)}',
                  ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 16),
      pw.Text(
        'Total Outstanding Payment : $currencySymbol ${outstandingPayment.toStringAsFixed(2)}',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 20),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          if (outstandingPayment <= 0.01 && sale.status == 'COMPLETED')
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: const PdfColor(0.8, 0.1, 0.1),
                  width: 2,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'PAID',
                style: pw.TextStyle(
                  color: const PdfColor(0.8, 0.1, 0.1),
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        _pdfSafe(sale.paymentMethod),
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      if (sale.paymentMethod.trim().toUpperCase() == 'COD') ...[
        pw.SizedBox(height: 35),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 160, height: 0.8, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Delivery Person Signature',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(width: 160, height: 0.8, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Customer Signature',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ];
  }

  static pw.Widget _a4Cell(
    String text, {
    bool bold = false,
    PdfColor color = PdfColors.black,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8.5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _a4SummaryRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> buildThermalDeliveryNote({
    required Sale sale,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required bool is58mm,
  }) {
    final isCod = sale.paymentMethod.toUpperCase() == 'COD';
    final isPaid = sale.status.toUpperCase() == 'COMPLETED';
    final fontSize = is58mm ? (settings.fontSize - 1).clamp(7.0, 11.0) : settings.fontSize;
    final textStyle = pw.TextStyle(fontSize: fontSize);
    final boldStyle = pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold);
    final smallStyle = pw.TextStyle(fontSize: (fontSize - 2).clamp(6.5, 9.0));
    final smallBoldStyle = pw.TextStyle(fontSize: (fontSize - 2).clamp(6.5, 9.0), fontWeight: pw.FontWeight.bold);
    final titleStyle = pw.TextStyle(fontSize: fontSize + 4, fontWeight: pw.FontWeight.bold);

    final createdAtStr = sale.createdAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(sale.createdAt!.toLocal())
        : DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final customerName = (sale.customer?.name.trim().isNotEmpty == true)
        ? sale.customer!.name
        : 'Walk-in Customer';
    final customerPhone = sale.customer?.phone ?? '';
    final deliveryAddress = (sale.shippingAddress != null && sale.shippingAddress!.trim().isNotEmpty)
        ? sale.shippingAddress!
        : (sale.customer?.address ?? '');

    final subtotal = sale.total - sale.tax + sale.discount - sale.shippingCharges;

    return [
      // Store header
      pw.Center(
        child: pw.Text(_pdfSafe(storeName), style: titleStyle, textAlign: pw.TextAlign.center),
      ),
      if (storeAddress.trim().isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(_pdfSafe(storeAddress), style: smallStyle, textAlign: pw.TextAlign.center),
        ),
      ],
      if (storePhone.trim().isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text('Tel: ${_pdfSafe(storePhone)}', style: smallStyle, textAlign: pw.TextAlign.center),
        ),
      ],
      pw.SizedBox(height: 4),
      pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

      // Title & COD Badge
      pw.Center(
        child: pw.Text('DELIVERY NOTE', style: pw.TextStyle(fontSize: fontSize + 3, fontWeight: pw.FontWeight.bold)),
      ),
      if (isCod) ...[
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text('CASH ON DELIVERY (COD)', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
          ),
        ),
      ],
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Date: $createdAtStr', style: smallStyle),
          pw.Text('Inv: ${_pdfSafe(_displayInvoiceNumber(sale))}', style: smallBoldStyle),
        ],
      ),
      pw.Divider(thickness: 0.8),

      // Deliver to box
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('DELIVER TO:', style: smallBoldStyle),
            pw.SizedBox(height: 2),
            pw.Text(_pdfSafe(customerName), style: boldStyle),
            if (customerPhone.trim().isNotEmpty)
              pw.Text('Phone: ${_pdfSafe(customerPhone)}', style: textStyle),
            if (deliveryAddress.trim().isNotEmpty)
              pw.Text('Address: ${_pdfSafe(deliveryAddress)}', style: smallStyle),
            if (sale.deliveryPersonName != null && sale.deliveryPersonName!.trim().isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text('Driver: ${_pdfSafe(sale.deliveryPersonName!)}', style: smallBoldStyle),
            ],
          ],
        ),
      ),
      pw.SizedBox(height: 6),

      // Payment Status & Collect Cash Banner
      if (isCod) ...[
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1.2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                isPaid ? 'PAYMENT STATUS: PAID' : 'PAYMENT STATUS: UNPAID',
                style: boldStyle,
              ),
              if (!isPaid) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'COLLECT CASH: ${_pdfSafe(_money(currencySymbol, sale.total))}',
                  style: pw.TextStyle(fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 6),
      ],

      // Items section
      pw.Text('ITEMS TO DELIVER:', style: boldStyle),
      pw.SizedBox(height: 2),
      pw.Divider(thickness: 0.8),

      ...sale.items.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final item = entry.value;
        final imeisMap = _parseImeisFromNotes(sale.notes);
        final itemImeis = imeisMap[item.productId] ?? [];

        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('$idx. ', style: boldStyle),
                  pw.Expanded(
                    child: pw.Text(_pdfSafe(item.productName), style: boldStyle),
                  ),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${_money(currencySymbol, item.unitPrice)} x ${_formatQuantity(item.quantity)}',
                      style: smallStyle,
                    ),
                    pw.Text(_money(currencySymbol, item.total), style: textStyle),
                  ],
                ),
              ),
              if (itemImeis.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, top: 1),
                  child: pw.Text('IMEI: ${itemImeis.join(", ")}', style: smallBoldStyle),
                ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, top: 2),
                child: pw.Text('[  ] Pending    [  ] Received', style: smallBoldStyle),
              ),
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
            ],
          ),
        );
      }),

      // Financial breakdown
      pw.SizedBox(height: 2),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Subtotal', style: smallStyle),
          pw.Text(_money(currencySymbol, subtotal), style: smallStyle),
        ],
      ),
      if (sale.discount > 0)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Discount', style: smallStyle),
            pw.Text(_negativeMoney(currencySymbol, sale.discount), style: smallStyle),
          ],
        ),
      if (sale.tax > 0)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Tax', style: smallStyle),
            pw.Text(_money(currencySymbol, sale.tax), style: smallStyle),
          ],
        ),
      if (sale.shippingCharges > 0)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Delivery Fee', style: textStyle),
            pw.Text(_money(currencySymbol, sale.shippingCharges), style: boldStyle),
          ],
        ),
      pw.Divider(thickness: 1),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('TOTAL', style: pw.TextStyle(fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            _money(currencySymbol, sale.total),
            style: pw.TextStyle(fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
      pw.Divider(thickness: 1),

      // Signatures
      pw.SizedBox(height: 14),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('.............................', style: smallStyle),
              pw.SizedBox(height: 1),
              pw.Text('Delivered By', style: smallBoldStyle),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('.............................', style: smallStyle),
              pw.SizedBox(height: 1),
              pw.Text('Customer Sign', style: smallBoldStyle),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Center(
        child: pw.Text('Please inspect goods upon delivery', style: smallStyle),
      ),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Text('Powered by StoreBuddy POS', style: smallStyle),
      ),
    ];
  }

  static Future<Uint8List> generateDeliveryNotePdf({
    required Sale sale,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    String? formatOverride,
  }) async {
    final pdf = pw.Document();
    final effectiveFormat = (formatOverride ?? settings.deliveryNoteFormat).toUpperCase();
    final isA4 = effectiveFormat == 'A4';
    final is58mm = effectiveFormat == 'THERMAL_58MM';
    final isCod = sale.paymentMethod.toUpperCase() == 'COD';
    final isPaid = sale.status.toUpperCase() == 'COMPLETED';

    pw.ThemeData? theme;
    try {
      final ttfData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final baseFont = pw.Font.ttf(ttfData);
      theme = pw.ThemeData.withFont(
        base: baseFont,
        bold: baseFont,
        italic: baseFont,
        boldItalic: baseFont,
      );
    } catch (e) {
      theme = null;
    }

    if (isA4) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: theme,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _pdfSafe(storeName),
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _pdfSafe(storeAddress),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Phone: $storePhone',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DELIVERY NOTE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      if (isCod) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'CASH ON DELIVERY (COD)',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red800,
                          ),
                        ),
                      ],
                      pw.Text(
                        'Date: ${sale.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(sale.createdAt!.toLocal()) : ''}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Container(
                        width: 180,
                        alignment: pw.Alignment.topRight,
                        child: pw.Text(
                          'Invoice #: ${sale.id}',
                          style: const pw.TextStyle(fontSize: 9),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            // Delivery details
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DELIVER TO:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _pdfSafe(sale.customer?.name ?? 'Walk-in Customer'),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      () {
                        final a4Address = (sale.shippingAddress != null && sale.shippingAddress!.trim().isNotEmpty)
                            ? sale.shippingAddress!
                            : (sale.customer?.address ?? '');
                        if (a4Address.trim().isNotEmpty) {
                          return pw.Text(
                            'Address: ${_pdfSafe(a4Address)}',
                            style: const pw.TextStyle(fontSize: 10),
                          );
                        }
                        return pw.SizedBox();
                      }(),
                      if (sale.customer?.phone != null &&
                          sale.customer!.phone.isNotEmpty)
                        pw.Text(
                          'Phone: ${sale.customer!.phone}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      if (sale.deliveryPersonName != null &&
                          sale.deliveryPersonName!.trim().isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            'Driver: ${_pdfSafe(sale.deliveryPersonName!)}',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCod) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                      color: isPaid ? PdfColors.green50 : PdfColors.orange50,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          isPaid
                              ? 'PAYMENT STATUS: PAID'
                              : 'PAYMENT STATUS: UNPAID',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                            color: isPaid
                                ? PdfColors.green800
                                : PdfColors.orange800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          isPaid
                              ? 'No collection needed.'
                              : 'COLLECT CASH: $currencySymbol ${sale.total.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: isPaid ? PdfColors.green900 : PdfColors.red900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(3),
                2: pw.FixedColumnWidth(70),
                3: pw.FixedColumnWidth(50),
                4: pw.FixedColumnWidth(70),
                5: pw.FixedColumnWidth(110),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey700,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        '#',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'ITEM NAME',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'PRICE',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'QTY',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'AMOUNT',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'STATUS',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                ...sale.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final imeisMap = _parseImeisFromNotes(sale.notes);
                  final itemImeis = imeisMap[item.productId] ?? [];

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${index + 1}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              _pdfSafe(item.productName),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            if (itemImeis.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 2),
                                child: pw.Text(
                                  'IMEI: ${itemImeis.join(", ")}',
                                  style: pw.TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '$currencySymbol ${item.unitPrice.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${item.quantity.toInt()}',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '$currencySymbol ${item.total.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '[  ] Pending   [  ] Received',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  );
                }),
                if (sale.shippingCharges > 0)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.SizedBox(),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Delivery Fee',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.SizedBox(),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.SizedBox(),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '$currencySymbol ${sale.shippingCharges.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.SizedBox(),
                      ),
                    ],
                  ),
                // Summary row
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.SizedBox(),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.SizedBox(),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.SizedBox(),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '$currencySymbol ${sale.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.SizedBox(),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 50),
            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: isCod
                  ? [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 130,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(
                                  width: 1,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Prepared By',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 130,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(
                                  width: 1,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Delivered By',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 130,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(
                                  width: 1,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Customer Signature',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ]
                  : [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 150,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(
                                  width: 1,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Prepared By',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 150,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                top: pw.BorderSide(
                                  width: 1,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Customer Signature',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
            ),
          ],
        ),
      );
    } else {
      // Thermal continuous roll (80mm or 58mm)
      final rollWidth = is58mm ? 58 * PdfPageFormat.mm : 80 * PdfPageFormat.mm;
      final pageMargin = is58mm ? 2 * PdfPageFormat.mm : 3 * PdfPageFormat.mm;
      final paperFormat = PdfPageFormat(
        rollWidth,
        double.infinity,
        marginAll: pageMargin,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: paperFormat,
          theme: theme,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: buildThermalDeliveryNote(
              sale: sale,
              settings: settings,
              currencySymbol: currencySymbol,
              storeName: storeName,
              storeAddress: storeAddress,
              storePhone: storePhone,
              is58mm: is58mm,
            ),
          ),
        ),
      );
    }

    return await pdf.save();
  }

  static Future<void> printDeliveryNote({
    required Sale sale,
    required PrintSettingsModel settings,
    required String currencySymbol,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    String? formatOverride,
    String? printerNameOverride,
  }) async {
    final effectiveFormat = formatOverride ?? settings.deliveryNoteFormat;
    final pdfBytes = await generateDeliveryNotePdf(
      sale: sale,
      settings: settings,
      currencySymbol: currencySymbol,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      formatOverride: effectiveFormat,
    );

    final targetPrinterName = printerNameOverride ?? settings.deliveryNotePrinterName ?? settings.printerName;

    if (targetPrinterName != null && targetPrinterName.trim().isNotEmpty && targetPrinterName != '__FIRST_PRINTER__') {
      try {
        final printers = await Printing.listPrinters();
        final target = printers.firstWhere(
          (p) =>
              p.name.toLowerCase().contains(targetPrinterName.toLowerCase()) ||
              p.url.toLowerCase().contains(targetPrinterName.toLowerCase()),
          orElse: () => const Printer(url: '', name: ''),
        );
        if (target.url.isNotEmpty || target.name.isNotEmpty) {
          await Printing.directPrintPdf(
            printer: target,
            onLayout: (_) async => pdfBytes,
            name: 'DeliveryNote_${sale.id}',
          );
          return;
        }
      } catch (_) {}
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'DeliveryNote_${sale.id}',
    );
  }
}
