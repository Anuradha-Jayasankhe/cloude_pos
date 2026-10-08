part of '../dashboard_screen.dart';

extension _employees_pageExt on _DashboardScreenState {
  Widget _buildEmployeesPage() {
    final query = _employeeSearchController.text.trim().toLowerCase();
    final filtered = _scopedEmployees.where((e) {
      if (query.isEmpty) return true;
      return e.name.toLowerCase().contains(query) ||
          e.email.toLowerCase().contains(query) ||
          e.phone.toLowerCase().contains(query) ||
          e.position.toLowerCase().contains(query);
    }).toList();

    final colorScheme = Theme.of(context).colorScheme;

    Widget employeeActionButton({
      required String tooltip,
      required VoidCallback? onPressed,
      required IconData icon,
      Color? color,
    }) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Tooltip(
        message: tooltip,
        child: Material(
          color: onPressed == null
              ? Colors.transparent
              : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9)),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                icon,
                size: 16,
                color: onPressed == null
                    ? (isDark ? Colors.white24 : Colors.black26)
                    : (color ??
                          (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569))),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(UiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      child: const Text(
                        'Employees',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your employee records and information.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _canManageEmployees
                    ? () async {
                        final employee = await _showEmployeeDialog();
                        if (employee == null) return;

                        // Ensure the employee is visible under the active
                        // location filter (same branch the user is viewing).
                        final activeScope = _selectedLocationScope.trim();
                        final isAllLocations =
                            activeScope.isEmpty ||
                            activeScope.toLowerCase() == 'all locations';
                        if (!isAllLocations) {
                          final hasActiveScope = employee.assignedLocations.any(
                            (l) =>
                                l.trim().toLowerCase() ==
                                activeScope.toLowerCase(),
                          );
                          if (!hasActiveScope) {
                            employee.assignedLocations.add(activeScope);
                          }
                        }
                        if (employee.assignedLocations.isEmpty &&
                            _availableLocationNames.isNotEmpty) {
                          employee.assignedLocations = [
                            _availableLocationNames.first,
                          ];
                        }

                        setState(() {
                          // Avoid accidental duplicates if dialog is retried.
                          _employees.removeWhere((e) => e.id == employee.id);
                          _employees.insert(0, employee);
                        });
                        await _persistWorkspaceData();
                        if (_appDatabase != null) {
                          try {
                            await _appDatabase!.insertEmployee(
                              _employeeItemToCompanion(employee),
                            );
                          } catch (_) {}
                        }
                        await _enqueueSync('INSERT', 'employees', employee.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${employee.name} added to employees',
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiRadius.md),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text(
                  'Add Employee',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassContainer(
            borderRadius: UiRadius.lg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _employeeSearchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search employees by name, email, position...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  size: 20,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: GlassContainer(
                borderRadius: UiRadius.xl,
                padding: EdgeInsets.zero,
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No employees found matching your criteria.',
                          style: TextStyle(
                            color: Color(0xFF7A8093),
                            fontSize: 20,
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.03)
                                        : Colors.black.withValues(alpha: 0.03),
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('EMPLOYEE')),
                                    DataColumn(label: Text('EMAIL')),
                                    DataColumn(label: Text('POSITION')),
                                    DataColumn(label: Text('DEPARTMENT')),
                                    DataColumn(label: Text('PAYMENT TYPE')),
                                    DataColumn(label: Text('SALARY')),
                                    DataColumn(label: Text('STATUS')),
                                    DataColumn(label: Text('ACTIONS')),
                                  ],
                                  rows: filtered.map((e) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(e.name)),
                                        DataCell(
                                          Text(
                                            e.email.isEmpty ? 'N/A' : e.email,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            e.position.isEmpty
                                                ? e.role
                                                : e.position,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            e.department.isEmpty
                                                ? 'N/A'
                                                : e.department,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            e.paymentType.isEmpty
                                                ? 'Monthly'
                                                : e.paymentType,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            e.paymentType == 'Hourly'
                                                ? '${_money(e.baseSalary)}/hr'
                                                : _money(e.baseSalary),
                                          ),
                                        ),
                                        DataCell(
                                          StatusChip(
                                            label: e.active
                                                ? 'ACTIVE'
                                                : 'INACTIVE',
                                            color: e.active
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              employeeActionButton(
                                                tooltip: 'Edit',
                                                onPressed: _canManageEmployees
                                                    ? () async {
                                                        final edited =
                                                            await _showEmployeeDialog(
                                                              existing: e,
                                                            );
                                                        if (edited == null)
                                                          return;
                                                        setState(() {
                                                          final i = _employees
                                                              .indexWhere(
                                                                (x) =>
                                                                    x.id ==
                                                                    e.id,
                                                              );
                                                          _employees[i] =
                                                              edited;
                                                        });
                                                        await _persistWorkspaceData();
                                                        if (_appDatabase !=
                                                            null) {
                                                          try {
                                                            await _appDatabase!
                                                                .insertEmployee(
                                                                  _employeeItemToCompanion(
                                                                    edited,
                                                                  ),
                                                                );
                                                          } catch (_) {}
                                                        }
                                                        await _enqueueSync(
                                                          'UPDATE',
                                                          'employees',
                                                          edited.id,
                                                        );
                                                      }
                                                    : null,
                                                icon: Icons.edit_outlined,
                                              ),
                                              const SizedBox(width: 6),
                                              employeeActionButton(
                                                tooltip: e.linkedUserId.isEmpty
                                                    ? 'Create User Account'
                                                    : 'User Account Linked',
                                                onPressed:
                                                    _canManageEmployees &&
                                                        e.linkedUserId.isEmpty
                                                    ? () async {
                                                        final passwordController =
                                                            TextEditingController();
                                                        final confirmed = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            title: const Text(
                                                              'Create User Account',
                                                            ),
                                                            content: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  'Create a login for ${e.name} using ${e.email.isEmpty ? 'this employee record' : e.email}.',
                                                                ),
                                                                const SizedBox(
                                                                  height: 12,
                                                                ),
                                                                TextField(
                                                                  controller:
                                                                      passwordController,
                                                                  obscureText:
                                                                      true,
                                                                  decoration: const InputDecoration(
                                                                    labelText:
                                                                        'Initial password',
                                                                    border:
                                                                        OutlineInputBorder(),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      true,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Create',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (confirmed != true) {
                                                          passwordController
                                                              .dispose();
                                                          return;
                                                        }
                                                        final authService =
                                                            context
                                                                .read<
                                                                  AuthService
                                                                >();
                                                        final createdUserId = await authService
                                                            .createTenantUserLogin(
                                                              tenantId:
                                                                  _activeTenantId ??
                                                                  'local',
                                                              email: e.email,
                                                              password:
                                                                  passwordController
                                                                      .text,
                                                              role: e.role
                                                                  .toLowerCase(),
                                                              locationIds: e
                                                                  .assignedLocations,
                                                              active: e.active,
                                                              userName: e.name,
                                                            );
                                                        passwordController
                                                            .dispose();
                                                        if (createdUserId ==
                                                                null ||
                                                            createdUserId
                                                                .isEmpty) {
                                                          if (!mounted) return;
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                authService
                                                                        .lastActionError ??
                                                                    'Could not create user account.',
                                                              ),
                                                            ),
                                                          );
                                                          return;
                                                        }
                                                        setState(() {
                                                          final employeeIndex =
                                                              _employees
                                                                  .indexWhere(
                                                                    (
                                                                      employee,
                                                                    ) =>
                                                                        employee
                                                                            .id ==
                                                                        e.id,
                                                                  );
                                                          if (employeeIndex >=
                                                              0) {
                                                            _employees[employeeIndex]
                                                                    .linkedUserId =
                                                                createdUserId;
                                                          }
                                                          final user =
                                                              _userFromEmployee(
                                                                e,
                                                                userId:
                                                                    createdUserId,
                                                                permissions: e
                                                                    .permissions,
                                                                locations: e
                                                                    .assignedLocations,
                                                              );
                                                          _users.add(user);
                                                        });
                                                        await _persistWorkspaceData();
                                                        await _enqueueSync(
                                                          'INSERT',
                                                          'users',
                                                          createdUserId,
                                                        );
                                                        await _enqueueSync(
                                                          'UPDATE',
                                                          'employees',
                                                          e.id,
                                                        );
                                                        if (!mounted) return;
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'User account created for ${e.name}.',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    : null,
                                                icon: e.linkedUserId.isEmpty
                                                    ? Icons
                                                          .person_add_alt_1_outlined
                                                    : Icons
                                                          .verified_user_outlined,
                                                color: e.linkedUserId.isEmpty
                                                    ? null
                                                    : Colors.green,
                                              ),
                                              const SizedBox(width: 6),
                                              employeeActionButton(
                                                tooltip: 'Delete',
                                                onPressed: _canManageEmployees
                                                    ? () async {
                                                        final confirm = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            title: const Text(
                                                              'Delete Employee',
                                                            ),
                                                            content: Text(
                                                              'Are you sure you want to delete "${e.name}"? This cannot be undone.',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      true,
                                                                    ),
                                                                child: const Text(
                                                                  'Delete',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (confirm != true)
                                                          return;
                                                        setState(
                                                          () => _employees
                                                              .removeWhere(
                                                                (x) =>
                                                                    x.id ==
                                                                    e.id,
                                                              ),
                                                        );
                                                        await _persistWorkspaceData();
                                                        if (_appDatabase !=
                                                            null) {
                                                          try {
                                                            await _appDatabase!
                                                                .deleteEmployee(
                                                                  e.id,
                                                                );
                                                          } catch (_) {}
                                                        }
                                                        await _enqueueSync(
                                                          'DELETE',
                                                          'employees',
                                                          e.id,
                                                        );
                                                      }
                                                    : null,
                                                icon: Icons.delete_outline,
                                                color: colorScheme.error,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
