part of '../dashboard_screen.dart';

extension _store_page_contentExt on _DashboardScreenState {
  Widget _buildStorePageContent(AuthAuthenticated state) {
    if (_selectedNavKey != 'pos') {
      _hasPromptedOpenRegisterThisVisit = false;
    }
    Widget page;
    switch (_selectedNavKey) {
      case 'dashboard':
        page = _dashboardPage();
        break;
      case 'pos':
        page = _buildPosPage();
        break;
      case 'products':
        page = _buildProductsPage();
        break;
      case 'barcodes':
        page = _buildBarcodePrintingPage();
        break;
      case 'categories':
        page = _buildCategoriesPage();
        break;
      case 'locations':
        page = _buildLocationsPage();
        break;
      case 'stockTransfers':
        page = _buildStockTransfersPage();
        break;
      case 'sales':
        page = _buildSalesPage();
        break;
      case 'installments':
        page = _buildInstallmentsPage();
        break;
      case 'customers':
        page = _buildCustomersPage();
        break;
      case 'creditManagement':
        page = _buildCreditManagementPage();
        break;
      case 'employees':
        page = _buildEmployeesPage();
        break;
      case 'attendance':
        page = _buildAttendancePage();
        break;
      case 'payroll':
        page = _buildPayrollPage();
        break;
      case 'users':
        page = _buildUsersPage();
        break;
      case 'reports':
        page = _buildReportsPage();
        break;
      case 'settings':
        page = _buildSettingsPage();
        break;
      case 'mobileReload':
        page = _buildMobileReloadPage();
        break;
      case 'marketing':
        page = _buildMarketingPage();
        break;
      case 'expenses':
        page = ExpensesPage(
          appDatabase: _appDatabase!,
          tenantId: _activeTenantId ?? 'local',
          locationId: _selectedLocationScope,
          currencySymbol: _currency == 'LKR'
              ? 'Rs.'
              : _currency == 'USD'
              ? '\$'
              : _currency,
          onExpensesChanged: _loadCoreDataFromRepositories,
          onEnqueueSync: _enqueueSync,
          onAddBankTransaction: (amount, type, referenceId, notes) async {
            final tx = _BankTransaction(
              id: 'TX-BANK-${DateTime.now().millisecondsSinceEpoch}',
              type: type,
              amount: amount,
              referenceId: referenceId,
              notes: notes,
              createdAt: DateTime.now(),
            );
            setState(() {
              _bankAccountBalance -= amount;
              _bankTransactions.insert(0, tx);
            });
            await _persistWorkspaceData();
            await _enqueueSync('INSERT', 'bank_transactions', tx.id);
          },
        );
        break;
      case 'discounts':
        page = DiscountsPage(
          appDatabase: _appDatabase!,
          tenantId: _activeTenantId ?? 'local',
          onDiscountsChanged: _loadCoreDataFromRepositories,
        );
        break;
      case 'commissions':
        page = CommissionDashboardPage(
          appDatabase: _appDatabase!,
          tenantId: _activeTenantId ?? 'local',
          currencySymbol: _currency == 'LKR'
              ? 'Rs.'
              : _currency == 'USD'
              ? '\$'
              : _currency,
          appUsers: _users
              .map(
                (u) => {
                  'id': u.id,
                  'name': u.name,
                  'role': u.role,
                },
              )
              .toList(),
        );
        break;
      case 'services':
        page = _buildServicesPage();
        break;
      case 'jobCards':
        page = _buildJobCardsPage();
        break;
      case 'warranties':
        page = _buildReturnsRefundsPage();
        break;
      case 'suppliers':
        page = _buildSuppliersPage();
        break;
      case 'purchaseOrders':
        page = _buildPurchaseOrdersPage();
        break;
      case 'bankRegisters':
        page = BankRegistersPage(
          currencySymbol: _currency == 'LKR'
              ? 'Rs.'
              : _currency == 'USD'
              ? '\$'
              : _currency,
          cashierSessions: _cashierSessions,
          bankTransactions: _bankTransactions,
          bankAccountBalance: _bankAccountBalance,
          onAddManualTransaction: (amount, type, notes) async {
            final tx = _BankTransaction(
              id: 'TX-BANK-${DateTime.now().millisecondsSinceEpoch}',
              type: type,
              amount: amount,
              referenceId: '',
              notes: notes,
              createdAt: DateTime.now(),
            );
            setState(() {
              if (type == 'MANUAL_DEPOSIT') {
                _bankAccountBalance += amount;
              } else if (type == 'MANUAL_WITHDRAW') {
                _bankAccountBalance -= amount;
              }
              _bankTransactions.insert(0, tx);
            });
            await _persistWorkspaceData();
            await _enqueueSync('INSERT', 'bank_transactions', tx.id);
          },
          onCloseSession: (session, actualCash, {payoutAmount, payoutReason, keptCash = 0.0}) async {
            await _closeSession(session, actualCash, payoutAmount: payoutAmount, payoutReason: payoutReason, keptCash: keptCash);
          },
          onCalculateSessionBreakdown: _calculateSessionBreakdown,
          appUsers: _users,
        );
        break;
      case 'sync':
        page = _buildSyncPage();
        break;
      case 'whatsapp':
        page = _buildWhatsappConnectPage();
        break;
      default:
        page = const Center(child: Text('Unknown module'));
        break;
    }

    return _wrapSubScreenViewport(page);
  }

  Widget _wrapSubScreenViewport(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;
        if (!compact) {
          return child;
        }

        // Use real device width on compact screens instead of forcing desktop width.
        return SizedBox.expand(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
              maxHeight: constraints.maxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
