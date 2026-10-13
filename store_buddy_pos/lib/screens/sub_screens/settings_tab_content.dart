part of '../dashboard_screen.dart';

extension _settings_tab_contentExt on _DashboardScreenState {
  Widget _buildSettingsTabContent() {
    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );

    Widget sectionTitle(String title, String subtitle) {
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodyMedium),
        ],
      );
    }

    switch (_settingsTab) {
      case 'profile':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Profile Settings',
              'Update your account information and password.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _profileName,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _profileName = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _profileEmail,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _profileEmail = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _profilePhone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: inputBorder,
              ),
              onChanged: (v) => _profilePhone = v,
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 18),
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _profileCurrentPassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: inputBorder,
              ),
              onChanged: (v) => _profileCurrentPassword = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _profileNewPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _profileNewPassword = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _profileConfirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _profileConfirmPassword = v,
                  ),
                ),
              ],
            ),
          ],
        );
      case 'print_settings':
        return PrintSettingsContent(
          appDatabase: _appDatabase!,
          tenantId: _activeTenantId ?? 'local',
        );
      case 'general':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Store Operations',
              'Configure business hours, payment options, delivery, and active modules.',
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Hours & Location',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _storeLocation,
                      decoration: const InputDecoration(
                        labelText: 'Store Branch / Location',
                        hintText: 'e.g. Colombo 03, Main Street',
                        border: inputBorder,
                        prefixIcon: Icon(Icons.store_mall_directory_outlined),
                      ),
                      onChanged: (v) {
                        _storeLocation = v;
                        _persistWorkspaceData();
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _openFrom,
                            decoration: const InputDecoration(
                              labelText: 'Opening Time',
                              hintText: '08:30 AM',
                              border: inputBorder,
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            onChanged: (v) {
                              _openFrom = v;
                              _persistWorkspaceData();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _openTo,
                            decoration: const InputDecoration(
                              labelText: 'Closing Time',
                              hintText: '09:00 PM',
                              border: inputBorder,
                              prefixIcon: Icon(Icons.access_time_filled),
                            ),
                            onChanged: (v) {
                              _openTo = v;
                              _persistWorkspaceData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accepted Payment Methods',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Accept Cash'),
                      value: _acceptCash,
                      onChanged: (v) {
                        setState(() => _acceptCash = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Accept Card (Visa / Mastercard)'),
                      value: _acceptCard,
                      onChanged: (v) {
                        setState(() => _acceptCard = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Accept Cheque'),
                      value: _acceptCheque,
                      onChanged: (v) {
                        setState(() => _acceptCheque = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Accept Installment / Credit'),
                      value: _acceptInstallment,
                      onChanged: (v) {
                        setState(() => _acceptInstallment = v);
                        _persistWorkspaceData();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery & Cash on Delivery (COD)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Shipping Charges in POS'),
                      subtitle: const Text(
                        'Displays a shipping/courier charge field in checkout.',
                      ),
                      value: _enableShippingCharges,
                      onChanged: (v) {
                        setState(() => _enableShippingCharges = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Cash on Delivery (COD)'),
                      subtitle: const Text(
                        'Allows placing sales as COD orders without immediate payment, generating Delivery Notes, and tracking completion.',
                      ),
                      value: _enableCod,
                      onChanged: (v) {
                        setState(() => _enableCod = v);
                        _persistWorkspaceData();
                      },
                    ),
                    if (_enableCod) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _defaultDeliveryFee.toStringAsFixed(2),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Default Delivery Fee (LKR)',
                          hintText: '350.00',
                          border: inputBorder,
                          helperText: 'Auto-fills delivery fee in POS cart when COD is selected.',
                          prefixText: 'Rs. ',
                        ),
                        onChanged: (v) {
                          final parsed = double.tryParse(v.trim());
                          if (parsed != null) {
                            _defaultDeliveryFee = parsed;
                            _persistWorkspaceData();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'POS Customer Selection & Checkout Rules',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Configure whether cashiers can select or add customers on all payment methods or strictly for COD & Credit.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Allow Customer Selection on All Payments (Cash, Card, etc.)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _posAllowCustomerOnAllPayments
                            ? 'Enabled: Customer search and "Add Customer" appear for Cash and Card sales too (Defaults to Walk-in Customer if none chosen).'
                            : 'Disabled (COD / Credit Only): Customer selection is ONLY displayed when billing with COD, Credit, or Installments. Cash & Card sales stay streamlined.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _posAllowCustomerOnAllPayments,
                      onChanged: (v) {
                        setState(() => _posAllowCustomerOnAllPayments = v);
                        _persistWorkspaceData();
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'විකල්පයන් ක්‍රියාත්මක වන ආකාරය (How it works):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• ON කළ විට: Cash හෝ Card මඟින් pay කරන විටත් Customer කෙනෙකු තෝරා ගැනීමට (Search Customer) හෝ අලුත් Customer කෙනෙක් එක් කිරීමට (Add Customer) හැකියාව ලැබේ. පාරිභෝගිකයාගේ නම බිල්පතෙහි සටහන් වේ.\n'
                            '• OFF කළ විට: Customer තේරීම පෙන්වන්නේ COD (Cash on Delivery) සහ Credit (ණය) බිල්පත් සඳහා පමණි. Cash/Card විකුණුම් සඳහා Walk-in Customer ස්වයංක්‍රීයව තෝරාගෙන තිරය සරලව තබා ගනී.',
                            style: TextStyle(fontSize: 11.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currency & Tax',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            items: const [
                              DropdownMenuItem(value: 'LKR', child: Text('LKR (Rs)')),
                              DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                              DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _currency = v);
                              _persistWorkspaceData();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: inputBorder,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _taxRate,
                            decoration: const InputDecoration(
                              labelText: 'Default Tax Rate (%)',
                              border: inputBorder,
                            ),
                            onChanged: (v) {
                              _taxRate = v;
                              _persistWorkspaceData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice & Receipt Number Format',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Define the pattern used to generate receipt and invoice numbers. Click tags to add placeholders.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey('invoice_pattern_field_$_invoicePatternResetCounter'),
                      initialValue: _invoicePattern,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number Pattern',
                        helperText: 'E.g. {PREFIX}-{LOC}-{DATE}-{SEQ}{RAND}',
                        border: inputBorder,
                      ),
                      onChanged: (v) {
                        _invoicePattern = v;
                        _persistWorkspaceData();
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Click to add placeholder tag:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('{PREFIX}'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '{PREFIX}';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          label: const Text('{LOC}'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '{LOC}';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          label: const Text('{USR}'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '{USR}';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          label: const Text('{CASHIER}'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '{CASHIER}';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          label: const Text('{DATE}'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '{DATE}';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          label: const Text('{SEQ}'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '{SEQ}';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          label: const Text('{SEQ4} (0001)'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '{SEQ4}';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          label: const Text('{RAND}'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '{RAND}';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          label: const Text('- (Dash)'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '-';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          label: const Text('/ (Slash)'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern += '/';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('Standard Pattern'),
                          onPressed: () {
                            setState(() {
                              _invoicePattern = '{PREFIX}-{CASHIER}-{DATE}-{SEQ4}';
                              _invoicePatternResetCounter++;
                            });
                            _persistWorkspaceData();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Feature Modules',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mobile Reload Module'),
                      subtitle: const Text(
                        'Allows processing mobile reloads (Dialog, Mobitel, Hutch, Airtel, SLT) and tracks history.',
                      ),
                      value: _mobileReloadEnabled,
                      onChanged: (v) {
                        setState(() => _mobileReloadEnabled = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mobile Shop & IMEI Tracking'),
                      subtitle: const Text(
                        'Enables IMEI (EMI) serialization tracking, barcodes for serials, and automatic stock deduction for mobile shops.',
                      ),
                      value: _enableMobileShopFeatures,
                      onChanged: (v) {
                        setState(() => _enableMobileShopFeatures = v ?? false);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Agent Commission in POS'),
                      subtitle: const Text(
                        'Shows agent name and commission fields in the cart summary during checkout.',
                      ),
                      value: _enableAgentCommission,
                      onChanged: (v) {
                        setState(() => _enableAgentCommission = v);
                        _persistWorkspaceData();
                      },
                    ),
                    if (_enableAgentCommission) ...[
                      SwitchListTile(
                        contentPadding: const EdgeInsets.only(left: 16),
                        secondary: const Icon(Icons.lock_person_outlined, size: 20),
                        title: const Text('Lock commission to logged-in user'),
                        subtitle: Text(
                          _agentCommissionLockToLogin
                              ? 'Agent name is fixed to whoever is logged in — cannot be changed during a sale.'
                              : 'Any agent can be selected from the dropdown during a sale.',
                        ),
                        value: _agentCommissionLockToLogin,
                        onChanged: (v) {
                          setState(() {
                            _agentCommissionLockToLogin = v;
                            if (!v && !_isAgent) {
                              _posAgentName = '';
                              _posAgentId = '';
                              _posAgentNameController.clear();
                            }
                          });
                          _persistWorkspaceData();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Mode & Cloud Integration',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _integrationMode,
                      items: const [
                        DropdownMenuItem(value: 'Cloud Sync', child: Text('Cloud Sync (Realtime)')),
                        DropdownMenuItem(value: 'Local Only', child: Text('Local Only (Offline)')),
                        DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid (Periodic Sync)')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _integrationMode = v);
                        _persistWorkspaceData();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Sync Mode',
                        border: inputBorder,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _integrationWebhook,
                      decoration: const InputDecoration(
                        labelText: 'Webhook URL (optional)',
                        hintText: 'https://example.com/api/webhook',
                        border: inputBorder,
                      ),
                      onChanged: (v) {
                        _integrationWebhook = v;
                        _persistWorkspaceData();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 'navigation':
        final navItems = _storeNavItems;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Sidebar Navigation',
              'Drag items to change the sidebar order. Location and Settings can be moved lower if they are used less often.',
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: SizedBox(
                height: 420,
                child: ReorderableListView.builder(
                  itemCount: navItems.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = _sidebarNavOrder.removeAt(oldIndex);
                      _sidebarNavOrder.insert(newIndex, item);
                    });
                  },
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    return ListTile(
                      key: ValueKey(item.key),
                      leading: Icon(item.icon),
                      title: Text(_navItemLabel(item)),
                      subtitle: Text(item.key),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(_resetSidebarNavOrder),
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset Default Order'),
                ),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Save Settings to keep the sidebar order.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Reminder'),
                ),
              ],
            ),
          ],
        );
      case 'company':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Company Information',
              'Maintain your legal and contact details used in invoices.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _companyName,
                    decoration: const InputDecoration(
                      labelText: 'Company Display Name',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _companyName = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _companyRegNo,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _companyRegNo = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _companyEmail,
                    decoration: const InputDecoration(
                      labelText: 'Company Email',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _companyEmail = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _companyPhone,
                    decoration: const InputDecoration(
                      labelText: 'Company Phone',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _companyPhone = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _companyAddress,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Company Address',
                border: inputBorder,
              ),
              onChanged: (v) => _companyAddress = v,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.14),
                    ),
                    child: _companyLogoPath.isNotEmpty
                        ? AppImage(
                            imageUrl: _companyLogoPath,
                            width: 52,
                            height: 52,
                            fit: BoxFit.contain,
                            placeholder: const Icon(Icons.image_outlined),
                          )
                        : const Icon(Icons.image_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upload your company logo to show on receipts and invoices.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_companyLogoPath.isNotEmpty) ...[
                    IconButton(
                      tooltip: 'Remove logo',
                      onPressed: () async {
                        setState(() {
                          _companyLogoPath = '';
                          _receiptShowLogo = false;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('company_logo_path');
                        await prefs.setBool('bill_show_logo', false);
                        await _persistWorkspaceData();
                        if (_appDatabase != null) {
                          try {
                            final existing = await _appDatabase!.getPrintSettings(_activeTenantId ?? 'local');
                            if (existing != null) {
                              await _appDatabase!.upsertPrintSettings(
                                existing.toCompanion(true).copyWith(showLogo: const Value(false)),
                              );
                            }
                          } catch (_) {}
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const SizedBox(width: 4),
                  ],
                  OutlinedButton(
                    onPressed: () async {
                      final path = await _pickImagePath();
                      if (path == null || path.isEmpty) return;
                      setState(() {
                        _companyLogoPath = path;
                        _receiptShowLogo = true;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('company_logo_path', path);
                      await prefs.setBool('bill_show_logo', true);
                      await _persistWorkspaceData();
                      if (_appDatabase != null) {
                        try {
                          final existing = await _appDatabase!.getPrintSettings(_activeTenantId ?? 'local');
                          if (existing != null) {
                            await _appDatabase!.upsertPrintSettings(
                              existing.toCompanion(true).copyWith(showLogo: const Value(true)),
                            );
                          }
                        } catch (_) {}
                      }

                      // Auto-upload to sync server so all devices get this logo
                      try {
                        final apiClient = context.read<ApiClient>();
                        final serverUrl = await apiClient.uploadImage(
                          filePath: path,
                          folder: 'logos',
                        );
                        if (serverUrl != null && serverUrl.isNotEmpty) {
                          setState(() => _companyLogoPath = serverUrl);
                          await prefs.setString('company_logo_path', serverUrl);
                          await _persistWorkspaceData();
                        }
                      } catch (e) {
                        debugPrint('[Settings] Logo upload error: $e');
                      }
                    },
                    child: const Text('Upload Logo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _receiptShowLogo
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
                    : Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _receiptShowLogo
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  width: _receiptShowLogo ? 1.4 : 1.0,
                ),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                value: _receiptShowLogo,
                onChanged: _companyLogoPath.isEmpty
                    ? null
                    : (val) async {
                        setState(() => _receiptShowLogo = val);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('bill_show_logo', val);
                        await _persistWorkspaceData();
                        if (_appDatabase != null) {
                          try {
                            final existing = await _appDatabase!.getPrintSettings(_activeTenantId ?? 'local');
                            if (existing != null) {
                              await _appDatabase!.upsertPrintSettings(
                                existing.toCompanion(true).copyWith(showLogo: Value(val)),
                              );
                            }
                          } catch (_) {}
                        }
                      },
                title: Row(
                  children: [
                    Text(
                      'Print Logo at Top of Receipts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: _receiptShowLogo
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _receiptShowLogo
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _receiptShowLogo ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _receiptShowLogo ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    _companyLogoPath.isEmpty
                        ? 'Upload a company logo first to enable printing it at the top of receipts.'
                        : (_receiptShowLogo
                            ? 'Enabled: Store logo will be printed centered at the very top of customer receipts.'
                            : 'Disabled: Customer receipts will be printed without the store logo.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                secondary: Icon(
                  Icons.receipt_long_rounded,
                  color: _receiptShowLogo
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 26,
                ),
              ),
            ),
          ],
        );
      case 'preferences':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Display & Preferences',
              'Customize application appearance, language, sound effects, and POS behavior.',
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme & Language',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _uiTheme,
                            items: const [
                              DropdownMenuItem(value: 'Light', child: Text('Light Theme')),
                              DropdownMenuItem(value: 'Dark', child: Text('Dark Theme')),
                              DropdownMenuItem(
                                value: 'System',
                                child: Text('System Default'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _uiTheme = v);
                              _applyUiTheme(v);
                              _persistWorkspaceData();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Color Theme',
                              border: inputBorder,
                              prefixIcon: Icon(Icons.palette_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _uiLanguage,
                            items: const [
                              DropdownMenuItem(
                                value: 'English',
                                child: Text('English'),
                              ),
                              DropdownMenuItem(
                                value: 'Sinhala',
                                child: Text('සිංහල (Sinhala)'),
                              ),
                              DropdownMenuItem(
                                value: 'Tamil',
                                child: Text('தமிழ் (Tamil)'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _uiLanguage = v);
                              _persistWorkspaceData();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Language',
                              border: inputBorder,
                              prefixIcon: Icon(Icons.language_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POS Interaction & Sound',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sound Effects & Audio Beeps'),
                      subtitle: const Text('Play beep sounds on barcode scan and completed sales.'),
                      value: _prefSound,
                      onChanged: (v) {
                        setState(() => _prefSound = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto Print Receipts After Sale'),
                      subtitle: const Text('Immediately send print command to receipt printer upon payment completion.'),
                      value: _prefAutoPrint,
                      onChanged: (v) {
                        setState(() => _prefAutoPrint = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow Re-printing Bill in Sales'),
                      subtitle: const Text('Allow staff/cashiers to re-print sales bills from the sales history. If disabled, only Admins/Owners can re-print.'),
                      value: _allowReprintSalesBill,
                      onChanged: (v) {
                        setState(() => _allowReprintSalesBill = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Send Delivery Note & OTP via WhatsApp'),
                      subtitle: const Text('Send WhatsApp Delivery Note message and 4-digit verification OTP to customer for COD orders.'),
                      value: _enableWhatsappCodNotifications,
                      onChanged: (v) {
                        setState(() => _enableWhatsappCodNotifications = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Use Compact Table Rows'),
                      subtitle: const Text('Show denser rows in product and transaction tables to fit more items on screen.'),
                      value: _prefCompact,
                      onChanged: (v) {
                        setState(() => _prefCompact = v);
                        _persistWorkspaceData();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Require Confirmation Before Checkout'),
                      subtitle: const Text('Show confirmation dialog before charging or finalizing a sale.'),
                      value: _prefRequireSaleConfirmation,
                      onChanged: (v) {
                        setState(() => _prefRequireSaleConfirmation = v);
                        _persistWorkspaceData();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 'notifications':
        return Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Low Stock Alerts'),
              value: _notifyLowStock,
              onChanged: (v) => setState(() => _notifyLowStock = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily Sales Summary'),
              value: _notifyDailySummary,
              onChanged: (v) => setState(() => _notifyDailySummary = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Return Notifications'),
              value: _notifyReturns,
              onChanged: (v) => setState(() => _notifyReturns = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Email Alerts'),
              value: _notifyEmail,
              onChanged: (v) => setState(() => _notifyEmail = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('SMS Alerts'),
              value: _notifySms,
              onChanged: (v) => setState(() => _notifySms = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Payroll Reminder Alerts'),
              value: _notifyPayroll,
              onChanged: (v) => setState(() => _notifyPayroll = v),
            ),
          ],
        );
      case 'payroll':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(
              'Payroll Configuration',
              'Set default payroll cycle, overtime and deductions.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _payrollCycle,
                    items: const [
                      DropdownMenuItem(
                        value: 'Monthly',
                        child: Text('Monthly'),
                      ),
                      DropdownMenuItem(
                        value: 'Bi-Weekly',
                        child: Text('Bi-Weekly'),
                      ),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _payrollCycle = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Pay Cycle',
                      border: inputBorder,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _payrollWorkingDays,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Working Days / Month',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _payrollWorkingDays = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _payrollOtRate,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Overtime Multiplier',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _payrollOtRate = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _payrollLatePenalty,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Late Penalty ($_currency)',
                      border: inputBorder,
                    ),
                    onChanged: (v) => _payrollLatePenalty = v,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto Generate Payroll at Month End'),
              value: _payrollAutoGenerate,
              onChanged: (v) => setState(() => _payrollAutoGenerate = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable EPF/ETF Calculations'),
              value: _payrollEnableEpf,
              onChanged: (v) => setState(() => _payrollEnableEpf = v),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Text(
                'These settings define defaults for payroll records created from the Payroll module.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        );
      case 'shortcuts':
        return _buildKeyboardShortcutsSettingsTab();
      default:
        return const Text(
          'This settings section is ready for integration configuration.',
        );
    }
  }

  Widget _buildKeyboardShortcutsSettingsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final shortcutsList = [
      {
        'key': 'completeSale',
        'title': 'Complete Sale / Fast Checkout',
        'sinhala': 'බිල අවසන් කිරීම / Fast Checkout',
        'desc': 'Instantly process checkout or complete the sale with exact cash / selected payment.',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'key': 'focusSearch',
        'title': 'Focus Product Search',
        'sinhala': 'භාණ්ඩ සෙවුම (Search Bar) වෙත යෑම',
        'desc': 'Focuses on the search bar so you can instantly search by name, barcode, or SKU.',
        'icon': Icons.search_rounded,
        'color': const Color(0xFF6366F1),
      },
      {
        'key': 'payCash',
        'title': 'Select Cash Payment',
        'sinhala': 'මුදල් ගෙවීම (Cash) තෝරාගැනීම',
        'desc': 'Switches payment method to CASH and sets exact grand total.',
        'icon': Icons.payments_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'key': 'payCard',
        'title': 'Select Card Payment',
        'sinhala': 'කාඩ්පත් ගෙවීම (Card) තෝරාගැනීම',
        'desc': 'Switches payment method to CARD for card swipe / terminal.',
        'icon': Icons.credit_card_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'key': 'holdCart',
        'title': 'Hold Current Cart',
        'sinhala': 'දැනට ඇති බිල Hold කිරීම',
        'desc': 'Suspends the current cart so you can serve another customer.',
        'icon': Icons.pause_circle_outline_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'key': 'resumeCart',
        'title': 'Resume Held Cart',
        'sinhala': 'Hold කළ බිල්පතක් ආපසු ගැනීම',
        'desc': 'Restores a previously held transaction back to the cart.',
        'icon': Icons.play_circle_outline_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'key': 'clearCart',
        'title': 'Clear Shopping Cart',
        'sinhala': 'Cart එක හිස් කිරීම',
        'desc': 'Empties all items currently in the POS cart.',
        'icon': Icons.delete_sweep_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'key': 'billPreview',
        'title': 'Preview Receipt / Bill',
        'sinhala': 'බිල්පතේ මුද්‍රණ පෙරදසුන (Preview)',
        'desc': 'Opens live receipt preview before finalizing the sale.',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'key': 'openDiscount',
        'title': 'Apply Bill Discount',
        'sinhala': 'මුළු බිලට වට්ටමක් (Discount) ලබා දීම',
        'desc': 'Opens the invoice discount modal to give percent or fixed discount.',
        'icon': Icons.discount_rounded,
        'color': const Color(0xFFEC4899),
      },
      {
        'key': 'addCustomer',
        'title': 'Add Customer to Bill',
        'sinhala': 'Customer කෙනෙකු තෝරා ගැනීම',
        'desc': 'Focuses customer search or opens customer picker.',
        'icon': Icons.person_add_alt_1_rounded,
        'color': const Color(0xFF06B6D4),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POS Keyboard Shortcuts (යතුරුපුවරු කෙටිමං)',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'කැෂියර්ට ඉතා පහසුවෙන් Keyboard එකෙන් පමණක් POS මෙහෙයුම් සිදු කිරීමට අවශ්‍ය පරිදි Keys සකසා ගන්න.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Reset All Shortcuts?'),
                    content: const Text(
                      'සියලුම Keyboard Shortcuts මුල් සැකසුම් (Default Keys) වෙත ආපසු හරවන්නද?',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset Defaults')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _resetKeyboardShortcuts();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Shortcuts reset to factory defaults!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Defaults (මුල් සැකසුම්)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Helpful tip card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF6366F1), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💡 ඉඟිය: වෙනස් කිරීමට කැමති Shortcut එක මත click කර, Keyboard එකේ ඔබ කැමති Key එකක් (e.g. Enter, F1-F12, Space) ඔබන්න. Barcode Scanner මඟින් scan කරන විට එය ස්වයංක්‍රීයව හඳුනා ගන්නා අතර Shortcuts වලට බාධා නොවේ.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Shortcuts Table / Grid
        Card(
          elevation: 0,
          color: isDark ? const Color(0xFF131D2E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? const Color(0xFF1E2D45) : const Color(0xFFE2E8F0),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shortcutsList.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final item = shortcutsList[index];
              final actionKey = item['key'] as String;
              final currentKey = _posShortcuts[actionKey] ?? _DashboardScreenState._defaultPosShortcuts[actionKey] ?? '';
              final color = item['color'] as Color;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item['icon'] as IconData, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${item['sinhala']})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['desc'] as String,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => _showCaptureShortcutKeyDialog(
                        actionKey: actionKey,
                        actionLabel: item['title'] as String,
                        sinhalaLabel: item['sinhala'] as String,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: color.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentKey,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.edit_rounded, size: 14, color: color.withValues(alpha: 0.7)),
                          ],
                        ),
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
}
