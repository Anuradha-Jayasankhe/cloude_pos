import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../blocs/auth/auth_bloc.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_system.dart';
import 'dashboard_screen.dart';

class _LoginText {
  static const rightTitle = 'Activate This Device';
  static const rightSubtitle =
      'Bind this device to the Store Buddy cloud before allowing shop work or offline sync.';
  static const brandName = 'Store Buddy POS';
  static const heroTagline = 'Next-gen point-of-sale for modern businesses.';
  static const heroDescription =
      'Connect this device to your Store Buddy Cloud workspace for full offline capability.';
  static const stepOne = 'Connect to Store Buddy Cloud.';
  static const stepTwo =
      'Sign in, use an activation code, or start a free trial.';
  static const stepThree = 'Bootstrap local data for offline operation.';

  static const signInTab = 'Sign In';
  static const activationTab = 'Activation';
  static const trialTab = '7-Day Trial';

  static const emailHint = 'Owner Email';
  static const passwordHint = 'Password';
  static const restaurantNameHint = 'Restaurant / Store Name';
  static const streetAddressHint = 'Street Address';
  static const cityHint = 'City';
  static const stateHint = 'State / Province';
  static const zipHint = 'ZIP / Postal Code';
  static const countryHint = 'Country';
  static const businessPhoneHint = 'Business Phone';
  static const ownerFirstNameHint = 'Owner First Name';
  static const ownerLastNameHint = 'Owner Last Name';
  static const activationCodeHint = 'Activation Code';
  static const deviceLabelHint = 'Device Label';
  static const trialHelpText =
      'This creates a new restaurant account, enrolls it in a 7-day trial, and stores a local device claim for offline use.';

  static const signIn = 'Sign In & Activate';
  static const activateCode = 'Activate Device';
  static const startTrial = 'Create Trial & Activate';
}

class _LoginSize {
  static const desktopBreakpoint = 980.0;
  static const contentMaxWidth = 1280.0;
  static const desktopHeight = 780.0;
  static const mobileHeaderHeight = 240.0;
  static const heroIconBox = 72.0;
  static const heroIconSize = 32.0;
  static const tabHeight = 52.0;
  static const actionButtonHeight = 54.0;
  static const progressSize = 20.0;
  static const progressStroke = 2.0;
}

enum _LoginTab { signIn, activationCode, trial }

class LoginScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialPassword;

  const LoginScreen({super.key, this.initialEmail, this.initialPassword});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _signInDeviceLabelController = TextEditingController(
    text: 'Front Counter POS',
  );
  final _activationCodeController = TextEditingController();
  final _activationDeviceLabelController = TextEditingController(
    text: 'Front Counter POS',
  );
  final _trialStoreNameController = TextEditingController();
  final _trialStreetAddressController = TextEditingController();
  final _trialCityController = TextEditingController();
  final _trialStateController = TextEditingController();
  final _trialZipController = TextEditingController();
  final _trialCountryController = TextEditingController(text: 'Sri Lanka');
  final _trialPhoneController = TextEditingController();
  final _trialOwnerFirstNameController = TextEditingController();
  final _trialOwnerLastNameController = TextEditingController();
  final _trialEmailController = TextEditingController();
  final _trialPasswordController = TextEditingController();
  final _trialDeviceLabelController = TextEditingController(
    text: 'Front Counter POS',
  );

  _LoginTab _activeTab = _LoginTab.signIn;
  bool _obscurePassword = true;
  bool _obscureTrialPassword = true;
  bool _isActivationSubmitting = false;
  bool _isTrialSubmitting = false;
  bool _isOfflineTrialSelected = false;

  late final AnimationController _fadeController;
  late final AnimationController _orbController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: UiAnimations.slow,
    );
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: UiAnimations.easeOut,
    );
    _fadeController.forward();

    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
      _trialEmailController.text = widget.initialEmail!;
    }
    if (widget.initialPassword != null) {
      _passwordController.text = widget.initialPassword!;
      _trialPasswordController.text = widget.initialPassword!;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _orbController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _signInDeviceLabelController.dispose();
    _activationCodeController.dispose();
    _activationDeviceLabelController.dispose();
    _trialStoreNameController.dispose();
    _trialStreetAddressController.dispose();
    _trialCityController.dispose();
    _trialStateController.dispose();
    _trialZipController.dispose();
    _trialCountryController.dispose();
    _trialPhoneController.dispose();
    _trialOwnerFirstNameController.dispose();
    _trialOwnerLastNameController.dispose();
    _trialEmailController.dispose();
    _trialPasswordController.dispose();
    _trialDeviceLabelController.dispose();
    super.dispose();
  }

  Future<void> _persistDeviceLabel(String label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_label', label.trim());
  }

  Future<void> _storeTrialClaimProfile({
    required String storeName,
    required String streetAddress,
    required String city,
    required String state,
    required String zip,
    required String country,
    required String phone,
    required String ownerFirstName,
    required String ownerLastName,
    required String ownerEmail,
    required String deviceLabel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'store_name': storeName,
      'street_address': streetAddress,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
      'business_phone': phone,
      'owner_first_name': ownerFirstName,
      'owner_last_name': ownerLastName,
      'owner_email': ownerEmail,
      'device_label': deviceLabel,
      'created_at': DateTime.now().toIso8601String(),
    };
    await prefs.setString('trial_claim_profile', jsonEncode(payload));
  }

  void _submitSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final deviceLabel = _signInDeviceLabelController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required.')),
      );
      return;
    }

    if (deviceLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device label is required.')),
      );
      return;
    }

    _persistDeviceLabel(deviceLabel);
    context.read<AuthBloc>().add(AuthLoginRequested(email, password));
  }

  Future<void> _activateWithCode() async {
    final code = _activationCodeController.text.trim();
    final deviceLabel = _activationDeviceLabelController.text.trim();

    if (code.isEmpty || deviceLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activation code and device label are required.'),
        ),
      );
      return;
    }

    setState(() => _isActivationSubmitting = true);
    final authService = context.read<AuthService>();
    final activated = await authService.activateDeviceWithCode(
      code,
      deviceLabel: deviceLabel,
    );

    if (!mounted) return;
    setState(() => _isActivationSubmitting = false);

    if (activated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authService.lastActionError ??
                'Activation failed. Please check your code.',
          ),
        ),
      );
      return;
    }

    _signInDeviceLabelController.text = deviceLabel;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Device activated for ${activated.storeName.isEmpty ? activated.tenantId : activated.storeName}. Sign in to continue.',
        ),
      ),
    );
    setState(() => _activeTab = _LoginTab.signIn);
  }

  Future<void> _createTrialAndActivate() async {
    final storeName = _trialStoreNameController.text.trim();
    final streetAddress = _trialStreetAddressController.text.trim();
    final city = _trialCityController.text.trim();
    final state = _trialStateController.text.trim();
    final zip = _trialZipController.text.trim();
    final country = _trialCountryController.text.trim();
    final phone = _trialPhoneController.text.trim();
    final ownerFirstName = _trialOwnerFirstNameController.text.trim();
    final ownerLastName = _trialOwnerLastNameController.text.trim();
    final ownerEmail = _trialEmailController.text.trim();
    final ownerPassword = _trialPasswordController.text.trim();
    final deviceLabel = _trialDeviceLabelController.text.trim();
    final ownerName = '$ownerFirstName $ownerLastName'.trim();

    if (storeName.isEmpty ||
        streetAddress.isEmpty ||
        city.isEmpty ||
        state.isEmpty ||
        country.isEmpty ||
        phone.isEmpty ||
        ownerFirstName.isEmpty ||
        ownerLastName.isEmpty ||
        ownerEmail.isEmpty ||
        ownerPassword.isEmpty ||
        deviceLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required trial fields.'),
        ),
      );
      return;
    }

    setState(() => _isTrialSubmitting = true);
    final authService = context.read<AuthService>();
    final created = await authService.createTrialStoreOwner(
      storeName: storeName,
      ownerEmail: ownerEmail,
      ownerPassword: ownerPassword,
      ownerName: ownerName,
      isOfflineOnly: _isOfflineTrialSelected,
    );

    if (!mounted) return;
    setState(() => _isTrialSubmitting = false);

    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authService.lastActionError ??
                'Could not create trial account. Please try again.',
          ),
        ),
      );
      return;
    }

    await _persistDeviceLabel(deviceLabel);
    await _storeTrialClaimProfile(
      storeName: storeName,
      streetAddress: streetAddress,
      city: city,
      state: state,
      zip: zip,
      country: country,
      phone: phone,
      ownerFirstName: ownerFirstName,
      ownerLastName: ownerLastName,
      ownerEmail: ownerEmail,
      deviceLabel: deviceLabel,
    );
    _emailController.text = ownerEmail;
    _passwordController.text = ownerPassword;
    _signInDeviceLabelController.text = deviceLabel;
    setState(() => _activeTab = _LoginTab.signIn);
    _submitSignIn();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => DashboardScreen(user: state.user),
                transitionDuration: UiAnimations.page,
                transitionsBuilder: (_, anim, __, child) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: FadeTransition(
          opacity: _fadeAnim,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop =
                  constraints.maxWidth >= _LoginSize.desktopBreakpoint;
              if (desktop) {
                return _buildDesktopLayout(context);
              }
              return _buildMobileLayout(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _LoginSize.contentMaxWidth,
            ),
            child: SizedBox(
              height: _LoginSize.desktopHeight,
              child: Row(
                children: [
                  Expanded(flex: 44, child: _buildHeroPane(context)),
                  const SizedBox(width: 24),
                  Expanded(flex: 56, child: _buildRightPane(context, mobile: false)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final headerH = screenH < 650
        ? (screenH * 0.28).clamp(140.0, 240.0)
        : _LoginSize.mobileHeaderHeight;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: SizedBox(
                height: headerH,
                child: _buildHeroPane(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _buildRightPane(context, mobile: true),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Hero / Left Pane ──────────────────────────────
  Widget _buildHeroPane(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 460 || constraints.maxWidth < 560;
        final panePadding = compact ? 24.0 : 44.0;
        final titleStyle = (compact
                ? textTheme.headlineSmall
                : textTheme.headlineLarge)
            ?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        );

        return AnimatedBuilder(
          animation: _orbController,
          builder: (context, child) {
            final t = _orbController.value;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: UiGradients.heroPanel,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Animated orb 1
                    Positioned(
                      left: -60 + (t * 30),
                      top: -60 + (t * 20),
                      child: _glowOrb(220, const Color(0xFF6366F1), 0.18),
                    ),
                    // Animated orb 2
                    Positioned(
                      right: -50 - (t * 20),
                      bottom: -50 + (t * 30),
                      child: _glowOrb(180, const Color(0xFF8B5CF6), 0.14),
                    ),
                    // Animated orb 3 — amber accent
                    Positioned(
                      left: constraints.maxWidth * 0.6 + (t * 15),
                      top: constraints.maxHeight * 0.3 - (t * 20),
                      child: _glowOrb(100, AppTheme.brandAmber, 0.10),
                    ),
                    // Grid pattern overlay
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.03,
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                    ),
                    // Content
                    child!,
                  ],
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(panePadding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / icon
                  Container(
                    width: _LoginSize.heroIconBox,
                    height: _LoginSize.heroIconBox,
                    decoration: BoxDecoration(
                      gradient: UiGradients.brand,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: UiShadows.glow,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: _LoginSize.heroIconSize,
                    ),
                  ),
                  SizedBox(height: compact ? 20 : 40),
                  // Brand name with gradient
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        UiGradients.brand.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: Text(
                      _LoginText.brandName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_LoginText.heroTagline, style: titleStyle),
                  SizedBox(height: compact ? 10 : 18),
                  Text(
                    _LoginText.heroDescription,
                    maxLines: compact ? 2 : null,
                    overflow: compact ? TextOverflow.ellipsis : null,
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 32),
                    _setupStep(1, _LoginText.stepOne),
                    const SizedBox(height: 16),
                    _setupStep(2, _LoginText.stepTwo),
                    const SizedBox(height: 16),
                    _setupStep(3, _LoginText.stepThree),
                    const SizedBox(height: 32),
                    // Bottom trust badges
                    Row(
                      children: [
                        _trustBadge(Icons.cloud_done_rounded, 'Cloud Sync'),
                        const SizedBox(width: 12),
                        _trustBadge(Icons.offline_bolt_rounded, 'Offline Ready'),
                        const SizedBox(width: 12),
                        _trustBadge(Icons.security_rounded, 'Secure'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _glowOrb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _setupStep(int step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: UiGradients.brand,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandIndigo.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            '$step',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(UiRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.brandAmber),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Right / Form Pane ─────────────────────────────
  Widget _buildRightPane(BuildContext context, {required bool mobile}) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1525),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1E2D45), width: 1),
        boxShadow: UiShadows.elevated,
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 20 : 36),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final authBusy = state is AuthLoading;

            final header = [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          child: Text(
                            _LoginText.rightTitle,
                            style: (mobile
                                    ? textTheme.headlineSmall
                                    : textTheme.headlineMedium)
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _LoginText.rightSubtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF94A3B8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTabBar(),
              const SizedBox(height: 22),
            ];

            if (mobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...header,
                  AnimatedSwitcher(
                    duration: UiAnimations.standard,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: child,
                    ),
                    child: _buildTabContent(authBusy),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...header,
                Expanded(
                  child: AnimatedSwitcher(
                    duration: UiAnimations.standard,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: child,
                    ),
                    child: _buildTabContent(authBusy),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: _LoginSize.tabHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(UiRadius.md),
        border: Border.all(color: const Color(0xFF1E2D45)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabButton(_LoginText.signInTab, _LoginTab.signIn,
              Icons.login_rounded),
          _tabButton(_LoginText.activationTab, _LoginTab.activationCode,
              Icons.key_rounded),
          _tabButton(
              _LoginText.trialTab, _LoginTab.trial, Icons.rocket_launch_rounded),
        ],
      ),
    );
  }

  Widget _tabButton(String label, _LoginTab tab, IconData icon) {
    final selected = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: AnimatedContainer(
          duration: UiAnimations.standard,
          curve: UiAnimations.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? UiGradients.brand : null,
            borderRadius: BorderRadius.circular(UiRadius.sm),
            boxShadow: selected ? UiShadows.glow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? Colors.white
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                    color: selected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool authBusy) {
    switch (_activeTab) {
      case _LoginTab.signIn:
        return _scrollableTabContent(
          key: const ValueKey('signin'),
          child: Column(
            children: [
              _field(
                controller: _emailController,
                hint: _LoginText.emailHint,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _passwordController,
                hint: _LoginText.passwordHint,
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                trailing: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _signInDeviceLabelController,
                hint: _LoginText.deviceLabelHint,
                icon: Icons.computer_outlined,
              ),
              const SizedBox(height: 20),
              _submitButton(
                label: _LoginText.signIn,
                busy: authBusy,
                onPressed: _submitSignIn,
              ),
            ],
          ),
        );
      case _LoginTab.activationCode:
        return _scrollableTabContent(
          key: const ValueKey('activation'),
          child: Column(
            children: [
              _field(
                controller: _activationCodeController,
                hint: _LoginText.activationCodeHint,
                icon: Icons.key_outlined,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _activationDeviceLabelController,
                hint: _LoginText.deviceLabelHint,
                icon: Icons.computer_outlined,
              ),
              const SizedBox(height: 20),
              _submitButton(
                label: _LoginText.activateCode,
                busy: _isActivationSubmitting,
                onPressed: _activateWithCode,
              ),
            ],
          ),
        );
      case _LoginTab.trial:
        return _scrollableTabContent(
          key: const ValueKey('trial'),
          child: Column(
            children: [
              _buildStoreTypeSelector(),
              _field(
                controller: _trialStoreNameController,
                hint: _LoginText.restaurantNameHint,
                icon: Icons.store_mall_directory_outlined,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _trialStreetAddressController,
                hint: _LoginText.streetAddressHint,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _trialCityController,
                      hint: _LoginText.cityHint,
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      controller: _trialStateController,
                      hint: _LoginText.stateHint,
                      icon: Icons.map_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _trialZipController,
                      hint: _LoginText.zipHint,
                      icon: Icons.local_post_office_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      controller: _trialCountryController,
                      hint: _LoginText.countryHint,
                      icon: Icons.flag_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                controller: _trialPhoneController,
                hint: _LoginText.businessPhoneHint,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _trialOwnerFirstNameController,
                      hint: _LoginText.ownerFirstNameHint,
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      controller: _trialOwnerLastNameController,
                      hint: _LoginText.ownerLastNameHint,
                      icon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                controller: _trialEmailController,
                hint: _LoginText.emailHint,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _trialPasswordController,
                hint: _LoginText.passwordHint,
                icon: Icons.lock_outline,
                obscureText: _obscureTrialPassword,
                trailing: IconButton(
                  onPressed: () => setState(
                    () => _obscureTrialPassword = !_obscureTrialPassword,
                  ),
                  icon: Icon(
                    _obscureTrialPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _trialDeviceLabelController,
                hint: _LoginText.deviceLabelHint,
                icon: Icons.computer_outlined,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isOfflineTrialSelected ? Colors.indigo : AppTheme.brandAmber).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(UiRadius.md),
                  border: Border.all(
                    color: (_isOfflineTrialSelected ? Colors.indigo : AppTheme.brandAmber).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isOfflineTrialSelected ? Icons.wifi_off_rounded : Icons.info_outline_rounded,
                      size: 16,
                      color: _isOfflineTrialSelected ? Colors.indigoAccent : AppTheme.brandAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isOfflineTrialSelected
                            ? 'Offline Standalone mode creates a 100% local SQLite store that runs with zero internet. Includes a 7-day free evaluation, and can later be activated lifetime with an SBOFF license key (Rs. 70,000) or upgraded to Cloud Online from the Admin Panel.'
                            : _LoginText.trialHelpText,
                        style: TextStyle(
                          color: _isOfflineTrialSelected ? Colors.indigoAccent : AppTheme.brandAmber,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _submitButton(
                label: _isOfflineTrialSelected
                    ? 'Start 7-Day Offline Trial & Launch'
                    : _LoginText.startTrial,
                busy: _isTrialSubmitting,
                onPressed: _createTrialAndActivate,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStoreTypeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(UiRadius.md),
        border: Border.all(color: const Color(0xFF1E2D45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isOfflineTrialSelected = false),
              borderRadius: BorderRadius.circular(UiRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: !_isOfflineTrialSelected ? UiGradients.brand : null,
                  borderRadius: BorderRadius.circular(UiRadius.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_queue_rounded,
                      size: 15,
                      color: !_isOfflineTrialSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cloud Online',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: !_isOfflineTrialSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: !_isOfflineTrialSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isOfflineTrialSelected = true),
              borderRadius: BorderRadius.circular(UiRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _isOfflineTrialSelected ? UiGradients.brand : null,
                  borderRadius: BorderRadius.circular(UiRadius.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 15,
                      color: _isOfflineTrialSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Offline Standalone',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isOfflineTrialSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _isOfflineTrialSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scrollableTabContent({required Key key, required Widget child}) {
    return SizedBox(
      key: key,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: child,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? trailing,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 13.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF475569)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF475569)),
        suffixIcon: trailing,
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiRadius.md),
          borderSide: const BorderSide(color: Color(0xFF1E2D45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiRadius.md),
          borderSide: const BorderSide(color: Color(0xFF1E2D45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiRadius.md),
          borderSide: BorderSide(
            color: AppTheme.brandIndigo,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }

  Widget _submitButton({
    required String label,
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: _LoginSize.actionButtonHeight,
      child: AnimatedContainer(
        duration: UiAnimations.fast,
        decoration: BoxDecoration(
          gradient: busy ? null : UiGradients.brand,
          color: busy ? const Color(0xFF1E2D45) : null,
          borderRadius: BorderRadius.circular(UiRadius.md),
          boxShadow: busy ? null : UiShadows.glow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: BorderRadius.circular(UiRadius.md),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: _LoginSize.progressSize,
                      height: _LoginSize.progressSize,
                      child: CircularProgressIndicator(
                        strokeWidth: _LoginSize.progressStroke,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Painters ─────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
