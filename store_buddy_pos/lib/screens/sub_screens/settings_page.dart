part of '../dashboard_screen.dart';

extension _settings_pageExt on _DashboardScreenState {
  Widget _buildSettingsPage() {
    return _moduleCard(
      title: _t('Settings'),
      action: ElevatedButton.icon(
        onPressed: _canManageSettings
            ? () async {
                await _persistWorkspaceData();
                await _enqueueSync('UPDATE', 'settings', 'company_settings');
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Settings saved')));
              }
            : null,
        icon: const Icon(Icons.save),
        label: Text(_t('Save Settings')),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage your profile, store preferences and operational settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final colorScheme = Theme.of(context).colorScheme;
              final stacked = constraints.maxWidth < 980;

              final sidePanel = Container(
                width: stacked ? double.infinity : 255,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline),
                  color: colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _settingsTabs.map((tab) {
                      final selected = _settingsTab == tab.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _settingsTab = tab.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: selected
                                  ? colorScheme.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.35,
                                      )
                                    : const Color(0x00000000),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  tab.icon,
                                  size: 18,
                                  color: selected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.65,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _t(tab.label),
                                    style: TextStyle(
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: selected
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );

              final contentPanel = Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline),
                  color: colorScheme.surface,
                ),
                child: _buildSettingsTabContent(),
              );

              if (stacked) {
                return Column(
                  children: [
                    sidePanel,
                    const SizedBox(height: 12),
                    contentPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sidePanel,
                  const SizedBox(width: 14),
                  Expanded(child: contentPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
