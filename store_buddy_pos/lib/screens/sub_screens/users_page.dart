part of '../dashboard_screen.dart';

extension _users_pageExt on _DashboardScreenState {
  Widget _buildUsersPage() {
    final compact = MediaQuery.of(context).size.width < UiBreakpoints.tablet;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageSurfaceColor = isDark ? const Color(0xFF111827) : Colors.white;
    final pageBorderColor = isDark
        ? const Color(0xFF1E2D45)
        : const Color(0xFFE8EAFF);
    final tableHeaderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF8FAFC);

    final locationOptions = {
      'All Locations',
      _storeLocation.trim(),
      ..._availableLocationNames,
    }.where((v) => v.isNotEmpty).toList();

    final roleOptions = {
      'All Roles',
      ..._scopedUsers.map((u) => u.role),
    }.toList();

    final query = _usersSearchController.text.trim().toLowerCase();
    final filtered = _scopedUsers.where((user) {
      if (query.isNotEmpty &&
          !user.name.toLowerCase().contains(query) &&
          !user.email.toLowerCase().contains(query)) {
        return false;
      }
      if (_usersRoleFilter != 'All Roles' && user.role != _usersRoleFilter) {
        return false;
      }
      if (_usersStatusFilter == 'Active' && !user.active) return false;
      if (_usersStatusFilter == 'Inactive' && user.active) return false;
      if (_usersLocationFilter != 'All Locations' &&
          !user.locations.contains(_usersLocationFilter)) {
        return false;
      }
      return true;
    }).toList();

    final totalUsers = _scopedUsers.length;
    final activeUsers = _scopedUsers.where((u) => u.active).length;
    final admins = _scopedUsers.where((u) => u.role == 'ADMIN').length;
    final owners = _scopedUsers.where((u) => u.role == 'OWNER').length;
    final cashiers = _scopedUsers.where((u) => u.role == 'CASHIER').length;

    Widget metric({
      required IconData icon,
      required Color iconColor,
      required Color iconBg,
      required String value,
      required String label,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pageSurfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: pageBorderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(label, style: const TextStyle(color: Color(0xFF7A8093))),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget compactMetric({
      required IconData icon,
      required Color iconColor,
      required Color iconBg,
      required String value,
      required String label,
    }) {
      return SizedBox(
        width: _adaptiveWidth(260, minWidth: 180, horizontalPadding: 40),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pageSurfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: pageBorderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF7A8093)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: compact ? double.infinity : 600,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        color: AppTheme.brandIndigo,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
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
                                'User Management',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 30 : 40,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Text(
                              'Manage user accounts and permissions.',
                              maxLines: compact ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6D7383),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _canCreateUsers
                      ? () async {
                          final authService = context.read<AuthService>();
                          final created = await _showUserDialog();
                          if (created == null) return;
                          String? finalUserId = await authService
                              .createTenantUserLogin(
                                tenantId: _activeTenantId ?? 'local',
                                email: created.user.email,
                                password: created.password,
                                role: created.user.role.toLowerCase(),
                                locationIds: created.user.locations,
                                active: created.user.active,
                                userName: created.user.name,
                              );

                          if (finalUserId == null || finalUserId.isEmpty) {
                            final errorMessage = authService.lastActionError;
                            if (errorMessage != null &&
                                errorMessage.contains('already used')) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                              return;
                            }
                            // Fallback to local user ID for local/offline POS operation
                            finalUserId = created.user.id.isNotEmpty
                                ? created.user.id
                                : 'U${DateTime.now().microsecondsSinceEpoch}';

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  errorMessage ?? 'Created user locally.',
                                ),
                              ),
                            );
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User created successfully.'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }

                          final syncedUser = _UserItem(
                            id: finalUserId,
                            name: created.user.name,
                            email: created.user.email,
                            role: created.user.role,
                            active: created.user.active,
                            permissions: List<String>.from(
                              created.user.permissions,
                            ),
                            locations: List<String>.from(
                              created.user.locations,
                            ),
                            linkedEmployeeId: finalUserId,
                          );
                          final mirroredEmployee = _employeeFromUser(
                            syncedUser,
                          );

                          setState(() {
                            _users.add(syncedUser);
                            final existingEmployeeIndex = _employees.indexWhere(
                              (employee) =>
                                  employee.id == mirroredEmployee.id ||
                                  employee.email.trim().toLowerCase() ==
                                      mirroredEmployee.email
                                          .trim()
                                          .toLowerCase(),
                            );
                            if (existingEmployeeIndex >= 0) {
                              _employees[existingEmployeeIndex] =
                                  mirroredEmployee;
                            } else {
                              _employees.add(mirroredEmployee);
                            }
                          });
                          await _persistWorkspaceData();
                          if (_appDatabase != null) {
                            try {
                              await _appDatabase!.insertEmployee(
                                _employeeItemToCompanion(mirroredEmployee),
                              );
                            } catch (_) {}
                          }
                          await _enqueueSync(
                            'INSERT',
                            'employees',
                            mirroredEmployee.id,
                          );
                          await _enqueueSync('INSERT', 'users', syncedUser.id);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandIndigo,
                    foregroundColor: Colors.white,
                    padding: compact
                        ? const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          )
                        : const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (compact)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  compactMetric(
                    icon: Icons.groups_outlined,
                    iconColor: AppTheme.brandIndigo,
                    iconBg: const Color(0xFFF4E8FA),
                    value: '$totalUsers',
                    label: 'Total Users',
                  ),
                  compactMetric(
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF1DAA65),
                    iconBg: const Color(0xFFE6F7EE),
                    value: '$activeUsers',
                    label: 'Active Users',
                  ),
                  compactMetric(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFFE35D5D),
                    iconBg: const Color(0xFFFCECED),
                    value: '$admins',
                    label: 'Admins',
                  ),
                  compactMetric(
                    icon: Icons.business_outlined,
                    iconColor: AppTheme.brandIndigo,
                    iconBg: const Color(0xFFF7EAFD),
                    value: '$owners',
                    label: 'Owners',
                  ),
                  compactMetric(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFFF59A23),
                    iconBg: const Color(0xFFFFF4DD),
                    value: '$cashiers',
                    label: 'Cashiers',
                  ),
                ],
              )
            else
              Row(
                children: [
                  metric(
                    icon: Icons.groups_outlined,
                    iconColor: AppTheme.brandIndigo,
                    iconBg: const Color(0xFFF4E8FA),
                    value: '$totalUsers',
                    label: 'Total Users',
                  ),
                  const SizedBox(width: 12),
                  metric(
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF1DAA65),
                    iconBg: const Color(0xFFE6F7EE),
                    value: '$activeUsers',
                    label: 'Active Users',
                  ),
                  const SizedBox(width: 12),
                  metric(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFFE35D5D),
                    iconBg: const Color(0xFFFCECED),
                    value: '$admins',
                    label: 'Admins',
                  ),
                  const SizedBox(width: 12),
                  metric(
                    icon: Icons.business_outlined,
                    iconColor: AppTheme.brandIndigo,
                    iconBg: const Color(0xFFF7EAFD),
                    value: '$owners',
                    label: 'Owners',
                  ),
                  const SizedBox(width: 12),
                  metric(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFFF59A23),
                    iconBg: const Color(0xFFFFF4DD),
                    value: '$cashiers',
                    label: 'Cashiers',
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pageSurfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: pageBorderColor),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: _adaptiveWidth(
                      420,
                      minWidth: 220,
                      horizontalPadding: 40,
                    ),
                    child: TextField(
                      controller: _usersSearchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _adaptiveWidth(
                      160,
                      minWidth: 150,
                      horizontalPadding: 40,
                    ),
                    child: _salesFilterDropdown(
                      value: _usersRoleFilter,
                      items: roleOptions,
                      onChanged: (v) => setState(() => _usersRoleFilter = v),
                    ),
                  ),
                  SizedBox(
                    width: _adaptiveWidth(
                      180,
                      minWidth: 160,
                      horizontalPadding: 40,
                    ),
                    child: _salesFilterDropdown(
                      value: _usersStatusFilter,
                      items: const ['All Statuses', 'Active', 'Inactive'],
                      onChanged: (v) => setState(() => _usersStatusFilter = v),
                      labelMapper: (v) =>
                          v == 'All Statuses' ? 'All Statuses' : v,
                    ),
                  ),
                  SizedBox(
                    width: _adaptiveWidth(
                      200,
                      minWidth: 170,
                      horizontalPadding: 40,
                    ),
                    child: _salesFilterDropdown(
                      value: _usersLocationFilter,
                      items: locationOptions,
                      onChanged: (v) =>
                          setState(() => _usersLocationFilter = v),
                      labelMapper: (v) =>
                          v == 'All Locations' ? 'All Locations' : v,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: pageSurfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pageBorderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Users (${filtered.length})',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (layoutContext, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  tableHeaderColor,
                                ),
                                columns: const [
                                  DataColumn(label: Text('USER')),
                                  DataColumn(label: Text('EMAIL')),
                                  DataColumn(label: Text('ROLE')),
                                  DataColumn(label: Text('USERS.LOCATIONS')),
                                  DataColumn(label: Text('STATUS')),
                                  DataColumn(label: Text('LAST LOGIN')),
                                  DataColumn(label: Text('ACTIONS')),
                                ],
                                rows: filtered.map((user) {
                                  final initials = user.name.trim().isEmpty
                                      ? 'U'
                                      : user.name
                                            .trim()
                                            .split(' ')
                                            .take(2)
                                            .map((x) => x.substring(0, 1))
                                            .join()
                                            .toUpperCase();

                                  final roleUpper = user.role.toUpperCase();
                                  final Color roleBg;
                                  final Color roleFg;
                                  if (roleUpper == 'OWNER') {
                                    roleBg = isDark
                                        ? const Color(0xFF3B0764)
                                        : const Color(0xFFF3E8FF);
                                    roleFg = isDark
                                        ? const Color(0xFFE9D5FF)
                                        : const Color(0xFF7E22CE);
                                  } else if (roleUpper == 'ADMIN') {
                                    roleBg = isDark
                                        ? const Color(0xFF4C0519)
                                        : const Color(0xFFFFE4E6);
                                    roleFg = isDark
                                        ? const Color(0xFFFECDD3)
                                        : const Color(0xFFBE123C);
                                  } else if (roleUpper == 'CASHIER') {
                                    roleBg = isDark
                                        ? const Color(0xFF451A03)
                                        : const Color(0xFFFEF3C7);
                                    roleFg = isDark
                                        ? const Color(0xFFFDE68A)
                                        : const Color(0xFFB45309);
                                  } else {
                                    roleBg = isDark
                                        ? const Color(0xFF172554)
                                        : const Color(0xFFDBEAFE);
                                    roleFg = isDark
                                        ? const Color(0xFFBFDBFE)
                                        : const Color(0xFF1D4ED8);
                                  }

                                  final Color statusBg = user.active
                                      ? (isDark
                                            ? const Color(0xFF052E16)
                                            : const Color(0xFFDCFCE7))
                                      : (isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9));
                                  final Color statusFg = user.active
                                      ? (isDark
                                            ? const Color(0xFF86EFAC)
                                            : const Color(0xFF15803D))
                                      : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF475569));

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: roleBg,
                                              child: Text(
                                                initials,
                                                style: TextStyle(
                                                  color: roleFg,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${user.permissions.length} custom permissions',
                                                  style: const TextStyle(
                                                    color: Color(0xFF7E8495),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(user.email)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: roleBg,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            user.role[0] +
                                                user.role
                                                    .substring(1)
                                                    .toLowerCase(),
                                            style: TextStyle(
                                              color: roleFg,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          user.locations.isEmpty
                                              ? 'None assigned'
                                              : user.locations.join(', '),
                                          style: TextStyle(
                                            fontStyle: user.locations.isEmpty
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                            color: const Color(0xFF767D96),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBg,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            user.active ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: statusFg,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const DataCell(Text('Never')),
                                      DataCell(
                                        IconButton(
                                          onPressed: _canEditUsers
                                              ? () async {
                                                  final authService = context
                                                      .read<AuthService>();
                                                  final edited =
                                                      await _showUserDialog(
                                                        existing: user,
                                                      );
                                                  if (edited == null) return;
                                                  final i = _users.indexWhere(
                                                    (x) => x.id == user.id,
                                                  );
                                                  final previousLinkedEmployeeId =
                                                      _users[i]
                                                          .linkedEmployeeId;
                                                  edited.user.linkedEmployeeId =
                                                      previousLinkedEmployeeId;

                                                  final employeeIndex =
                                                      _employees.indexWhere(
                                                        (employee) =>
                                                            employee.id ==
                                                                previousLinkedEmployeeId ||
                                                            employee.email
                                                                    .trim()
                                                                    .toLowerCase() ==
                                                                edited
                                                                    .user
                                                                    .email
                                                                    .trim()
                                                                    .toLowerCase(),
                                                      );
                                                  final mirroredEmployee =
                                                      _employeeFromUser(
                                                        edited.user,
                                                        linkedUserId:
                                                            previousLinkedEmployeeId
                                                                .isNotEmpty
                                                            ? previousLinkedEmployeeId
                                                            : edited.user.id,
                                                      );
                                                  setState(() {
                                                    _users[i] = edited.user;
                                                    if (employeeIndex >= 0) {
                                                      _employees[employeeIndex] =
                                                          mirroredEmployee;
                                                    } else {
                                                      _employees.add(
                                                        mirroredEmployee,
                                                      );
                                                    }
                                                  });
                                                  await _persistWorkspaceData();
                                                  if (_appDatabase != null) {
                                                    try {
                                                      await _appDatabase!
                                                          .insertEmployee(
                                                            _employeeItemToCompanion(
                                                              mirroredEmployee,
                                                            ),
                                                          );
                                                    } catch (_) {}
                                                  }
                                                  await _enqueueSync(
                                                    'UPDATE',
                                                    'employees',
                                                    edited
                                                        .user
                                                        .linkedEmployeeId,
                                                  );

                                                  if (edited
                                                      .password
                                                      .isNotEmpty) {
                                                    final updatedLogin =
                                                        await authService
                                                            .updateTenantUserPassword(
                                                              tenantId:
                                                                  _activeTenantId ??
                                                                  'local',
                                                              email: edited
                                                                  .user
                                                                  .email,
                                                              password: edited
                                                                  .password,
                                                            );

                                                    if (!updatedLogin) {
                                                      if (!mounted) return;
                                                      final errorMessage =
                                                          authService
                                                              .lastActionError;
                                                      ScaffoldMessenger.of(
                                                        this.context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            errorMessage ??
                                                                'Could not update login credentials.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }

                                                  await _enqueueSync(
                                                    'UPDATE',
                                                    'users',
                                                    edited.user.id,
                                                  );
                                                }
                                              : null,
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
