part of '../dashboard_screen.dart';

extension _attendance_pageExt on _DashboardScreenState {
  Widget _buildAttendancePage() {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.of(context).size.width < UiBreakpoints.tablet;
    final visible = _attendanceRecords.where((r) {
      if (r.date.year != _attendanceMonth.year ||
          r.date.month != _attendanceMonth.month) {
        return false;
      }
      final q = _attendanceSearchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.employeeName.toLowerCase().contains(q) ||
          r.status.toLowerCase().contains(q);
    }).toList();

    final today = DateTime.now();
    final presentToday = visible
        .where(
          (r) =>
              r.date.year == today.year &&
              r.date.month == today.month &&
              r.date.day == today.day &&
              r.status == 'Present',
        )
        .length;
    final absentToday = visible
        .where(
          (r) =>
              r.date.year == today.year &&
              r.date.month == today.month &&
              r.date.day == today.day &&
              r.status == 'Absent',
        )
        .length;
    final totalHours = visible.fold<double>(
      0,
      (sum, r) => sum + r.regularHours + r.overtimeHours,
    );

    Widget stat(String label, String value, Color valueColor) {
      return Expanded(
        child: GlassContainer(
          borderRadius: UiRadius.md,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget compactStat(String label, String value, Color valueColor) {
      return SizedBox(
        width: _adaptiveWidth(260, minWidth: 180, horizontalPadding: 40),
        child: GlassContainer(
          borderRadius: UiRadius.md,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget attendanceActionButton({
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
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? double.infinity : 620,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                              'Attendance Management',
                              style: TextStyle(
                                fontSize: compact ? 26 : 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track employee attendance and working hours.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: _adaptiveWidth(
                        220,
                        minWidth: 160,
                        horizontalPadding: 40,
                      ),
                      child: TextField(
                        controller: _attendanceSearchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search employee...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(UiRadius.md),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _adaptiveWidth(
                        180,
                        minWidth: 150,
                        horizontalPadding: 40,
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _monthKey(_attendanceMonth),
                        isExpanded: true,
                        items: List.generate(12, (i) {
                          final month = DateTime(today.year, i + 1, 1);
                          final key = _monthKey(month);
                          return DropdownMenuItem(
                            value: key,
                            child: Text(
                              _formatMonthLabel(month),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        onChanged: (value) {
                          if (value == null) return;
                          final parts = value.split('-');
                          if (parts.length != 2) return;
                          setState(
                            () => _attendanceMonth = DateTime(
                              int.tryParse(parts[0]) ?? today.year,
                              int.tryParse(parts[1]) ?? today.month,
                              1,
                            ),
                          );
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(UiRadius.md),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final record = await _showAttendanceDialog();
                        if (record == null || !mounted) return;
                        setState(() => _attendanceRecords.insert(0, record));
                        await _persistWorkspaceData();
                        await _enqueueSync('INSERT', 'attendance', record.id);
                      },
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
                        'Add Attendance',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.watch_later_outlined,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Today's Quick Actions",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (compact)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      compactStat(
                        'Total Records',
                        '${visible.length}',
                        colorScheme.onSurface,
                      ),
                      compactStat(
                        'Present Today',
                        '$presentToday',
                        colorScheme.secondary,
                      ),
                      compactStat(
                        'Absent Today',
                        '$absentToday',
                        colorScheme.error,
                      ),
                      compactStat(
                        'Total Hours',
                        totalHours.toStringAsFixed(1),
                        colorScheme.tertiary,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      stat(
                        'Total Records',
                        '${visible.length}',
                        colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      stat(
                        'Present Today',
                        '$presentToday',
                        colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      stat('Absent Today', '$absentToday', colorScheme.error),
                      const SizedBox(width: 12),
                      stat(
                        'Total Hours',
                        totalHours.toStringAsFixed(1),
                        colorScheme.tertiary,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GlassContainer(
                borderRadius: UiRadius.xl,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Attendance Records (${visible.length})',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    visible.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_note_outlined,
                                    size: 48,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No attendance records found for ${_formatMonthLabel(_attendanceMonth)}.',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final record = await _showAttendanceDialog();
                                      if (record == null || !mounted) return;
                                      setState(() => _attendanceRecords.insert(0, record));
                                      await _persistWorkspaceData();
                                      await _enqueueSync('INSERT', 'attendance', record.id);
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Attendance'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    headingRowColor:
                                        WidgetStateProperty.all(
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white.withValues(
                                                  alpha: 0.03,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.03,
                                                ),
                                        ),
                                    columns: const [
                                      DataColumn(label: Text('EMPLOYEE')),
                                      DataColumn(label: Text('DATE')),
                                      DataColumn(
                                        label: Text('CLOCK IN/OUT'),
                                      ),
                                      DataColumn(label: Text('HOURS')),
                                      DataColumn(label: Text('STATUS')),
                                      DataColumn(label: Text('ACTIONS')),
                                    ],
                                    rows: visible.map((r) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(r.employeeName)),
                                          DataCell(
                                            Text(_formatDate(r.date)),
                                          ),
                                          DataCell(
                                            Text(
                                              '${r.clockIn} - ${r.clockOut}',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              (r.regularHours +
                                                      r.overtimeHours)
                                                  .toStringAsFixed(1),
                                            ),
                                          ),
                                          DataCell(
                                            StatusChip(
                                              label: r.status.toUpperCase(),
                                              color:
                                                  r.status.toLowerCase() ==
                                                      'present'
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                attendanceActionButton(
                                                  tooltip: 'Edit',
                                                  onPressed: () async {
                                                    final updated =
                                                        await _showAttendanceDialog(
                                                          existing: r,
                                                        );
                                                    if (updated == null || !mounted)
                                                      return;
                                                    setState(() {
                                                      final idx =
                                                          _attendanceRecords
                                                              .indexWhere(
                                                                (x) =>
                                                                    x.id ==
                                                                    r.id,
                                                              );
                                                      if (idx >= 0)
                                                        _attendanceRecords[idx] =
                                                            updated;
                                                    });
                                                    await _persistWorkspaceData();
                                                    await _enqueueSync(
                                                      'UPDATE',
                                                      'attendance',
                                                      updated.id,
                                                    );
                                                  },
                                                  icon: Icons.edit_outlined,
                                                ),
                                                const SizedBox(width: 6),
                                                attendanceActionButton(
                                                  tooltip: 'Delete',
                                                  onPressed: () async {
                                                    setState(() {
                                                      _attendanceRecords
                                                          .removeWhere(
                                                            (x) =>
                                                                x.id ==
                                                                r.id,
                                                          );
                                                    });
                                                    await _persistWorkspaceData();
                                                    await _enqueueSync(
                                                      'DELETE',
                                                      'attendance',
                                                      r.id,
                                                    );
                                                  },
                                                  icon:
                                                      Icons.delete_outline,
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
    );
  }
}
