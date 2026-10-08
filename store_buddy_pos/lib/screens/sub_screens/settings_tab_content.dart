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
                    child:
                        _companyLogoPath.isNotEmpty &&
                            File(_companyLogoPath).existsSync()
                        ? Image.file(File(_companyLogoPath), fit: BoxFit.cover)
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
                      onPressed: () {
                        setState(() => _companyLogoPath = '');
                        _persistWorkspaceData();
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const SizedBox(width: 4),
                  ],
                  OutlinedButton(
                    onPressed: () async {
                      final path = await _pickImagePath();
                      if (path == null || path.isEmpty) return;
                      setState(() => _companyLogoPath = path);
                      _persistWorkspaceData();
                    },
                    child: const Text('Upload Logo'),
                  ),
                ],
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
      default:
        return const Text(
          'This settings section is ready for integration configuration.',
        );
    }
  }
}
