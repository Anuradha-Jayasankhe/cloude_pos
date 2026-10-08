part of '../dashboard_screen.dart';

extension _whatsappPageExt on _DashboardScreenState {
  Widget _buildWhatsappConnectPage() {
    return _WhatsappConnectView(
      apiClient: context.read<ApiClient>(),
      isWhatsappEnabled: _enableWhatsappCodNotifications,
      onToggleWhatsapp: (val) {
        setState(() => _enableWhatsappCodNotifications = val);
        _persistWorkspaceData();
      },
      storeName: _companyName.isNotEmpty ? _companyName : 'StoreBuddy Store',
    );
  }
}

class _WhatsappConnectView extends StatefulWidget {
  final ApiClient apiClient;
  final bool isWhatsappEnabled;
  final ValueChanged<bool> onToggleWhatsapp;
  final String storeName;

  const _WhatsappConnectView({
    required this.apiClient,
    required this.isWhatsappEnabled,
    required this.onToggleWhatsapp,
    required this.storeName,
  });

  @override
  State<_WhatsappConnectView> createState() => _WhatsappConnectViewState();
}

class _WhatsappConnectViewState extends State<_WhatsappConnectView> {
  late final WhatsAppService _whatsappService;
  bool _isLoading = false;
  String _status = 'DISCONNECTED'; // 'DISCONNECTED' | 'SCAN_QR' | 'CONNECTING' | 'CONNECTED'
  String? _qrCodeDataUrl;
  String? _phoneNumber;
  DateTime? _lastConnectedAt;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _whatsappService = WhatsAppService(widget.apiClient);
    _fetchStatus();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && (_status == 'SCAN_QR' || _status == 'CONNECTING')) {
        _fetchStatus(silent: true);
      }
    });
  }

  Future<void> _fetchStatus({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final res = await _whatsappService.getStatus();
    if (mounted) {
      setState(() {
        if (!silent) _isLoading = false;
        _status = res['status']?.toString() ?? 'DISCONNECTED';
        _qrCodeDataUrl = res['qrCodeDataUrl']?.toString();
        _phoneNumber = res['phoneNumber']?.toString();
        final lastConn = res['lastConnectedAt']?.toString();
        if (lastConn != null) {
          _lastConnectedAt = DateTime.tryParse(lastConn);
        }
      });
    }
  }

  Future<void> _initiateConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'CONNECTING';
    });

    final res = await _whatsappService.connect();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _status = res['status']?.toString() ?? 'CONNECTING';
        _qrCodeDataUrl = res['qrCodeDataUrl']?.toString();
      });
      if (res['success'] == false && _qrCodeDataUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Failed to initialize WhatsApp. Please check server.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      _startPolling();
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Disconnect WhatsApp'),
          ],
        ),
        content: const Text(
          'Are you sure you want to disconnect WhatsApp? Customer delivery note messages and OTPs will not be sent until reconnected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    await _whatsappService.disconnect();
    await _fetchStatus();
  }

  void _showTestMessageDialog() {
    final phoneCtrl = TextEditingController();
    final otpCtrl = TextEditingController(text: '1234');
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.send_rounded, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Send Test Delivery Note'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Phone Number *',
                        hintText: 'e.g. 0771234567 or +94771234567',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sample Delivery OTP',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSending
                      ? null
                      : () async {
                          final phone = phoneCtrl.text.trim();
                          if (phone.isEmpty) return;
                          setLocal(() => isSending = true);
                          final res = await _whatsappService.sendDeliveryNote(
                            customerPhone: phone,
                            customerName: 'Test Customer',
                            invoiceNumber: 'INV-TEST-001',
                            deliveryOtp: otpCtrl.text.trim(),
                            totalAmount: 2500.0,
                            shippingAddress: '123 Test Street, Colombo',
                            assignedDriverName: 'Saman Driver',
                            storeName: widget.storeName,
                          );
                          setLocal(() => isSending = false);
                          Navigator.pop(dialogCtx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? (res['success'] == true ? 'Test message sent successfully!' : 'Failed to send message')),
                                backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
                              ),
                            );
                          }
                        },
                  icon: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('Send Test'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Uint8List? _decodeQrDataUrl(String? dataUrl) {
    if (dataUrl == null || !dataUrl.contains(',')) return null;
    try {
      final base64Str = dataUrl.split(',').last;
      return base64Decode(base64Str);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isConnected = _status == 'CONNECTED';
    final isScanning = _status == 'SCAN_QR';
    final isConnecting = _status == 'CONNECTING';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF25D366),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WhatsApp Connect & Notifications',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connect your store WhatsApp via QR scan to automatically send Delivery Notes and OTP codes to COD customers.',
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.65)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh Status',
                      onPressed: _isLoading ? null : () => _fetchStatus(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Connection Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Header
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected
                                    ? Colors.green
                                    : (isScanning || isConnecting ? Colors.orange : Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isConnected
                                  ? 'Connected to WhatsApp'
                                  : (isScanning
                                      ? 'Waiting for QR Code Scan...'
                                      : (isConnecting ? 'Initializing Session...' : 'Disconnected')),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isConnected
                                    ? Colors.green
                                    : (isScanning || isConnecting ? Colors.orange : null),
                              ),
                            ),
                            const Spacer(),
                            if (isConnected && _phoneNumber != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+$_phoneNumber',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 32),

                        // Body depending on state
                        if (isConnected) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 36),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'WhatsApp is Active & Ready',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'All COD orders placed at checkout will automatically receive a WhatsApp Delivery Note summary and a 4-digit verification OTP.',
                                        style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showTestMessageDialog,
                                icon: const Icon(Icons.send_rounded),
                                label: const Text('Send Test Message'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _disconnect,
                                icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
                                label: const Text('Disconnect WhatsApp', style: TextStyle(color: Colors.redAccent)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ] else if (_qrCodeDataUrl != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // QR Code display
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Image.memory(
                                  _decodeQrDataUrl(_qrCodeDataUrl)!,
                                  width: 240,
                                  height: 240,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 28),
                              // Instructions
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'How to Connect:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStepItem(1, 'Open WhatsApp on your phone'),
                                    _buildStepItem(2, 'Tap Menu (⋮ on Android) or Settings (⚙ on iPhone)'),
                                    _buildStepItem(3, 'Select "Linked Devices"'),
                                    _buildStepItem(4, 'Tap "Link a Device" and scan this QR code'),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _isLoading ? null : _initiateConnection,
                                          icon: const Icon(Icons.refresh_rounded),
                                          label: const Text('Refresh QR Code'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF25D366),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else if (isConnecting || _isLoading) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  const SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF25D366),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Initializing WhatsApp Session...',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Connecting to WhatsApp socket & generating QR code. This usually takes 2-5 seconds...',
                                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.65)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // Disconnected state
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      size: 56,
                                      color: Color(0xFF25D366),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Connect Store WhatsApp',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 480),
                                    child: Text(
                                      'Link your mobile WhatsApp to StoreBuddy POS. Once connected, customers placing COD orders will receive instant delivery confirmation and an OTP code.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.65)),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _initiateConnection,
                                    icon: _isLoading
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Icon(Icons.qr_code_2_rounded),
                                    label: Text(_isLoading ? 'Generating QR Code...' : 'Link WhatsApp (Scan QR)'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                      elevation: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Settings & Preferences Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Automation Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Send Delivery Note & OTP via WhatsApp'),
                          subtitle: const Text('Automatically dispatch delivery note text and 4-digit verification OTP to customer on COD orders.'),
                          value: widget.isWhatsappEnabled,
                          onChanged: widget.onToggleWhatsapp,
                        ),
                      ],
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

  Widget _buildStepItem(int stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              '$stepNumber',
              style: const TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
