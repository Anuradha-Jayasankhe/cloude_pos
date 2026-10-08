part of '../dashboard_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Job Cards Page
// ─────────────────────────────────────────────────────────────────────────────
extension _job_cards_pageExt on _DashboardScreenState {
  Widget _buildJobCardsPage() {
    bool isJobCard(_ServiceJobItem item) {
      return item.customerName.trim().isNotEmpty ||
          item.services.isNotEmpty ||
          item.materials.isNotEmpty;
    }

    final jobs = _serviceJobs.where(isJobCard).where((job) {
      final statusOk =
          _jobCardStatusFilter == 'ALL' || job.status == _jobCardStatusFilter;
      final priorityOk =
          _jobCardPriorityFilter == 'ALL' ||
          job.priority == _jobCardPriorityFilter;
      return statusOk && priorityOk;
    }).toList();

    Future<void> createJobCard() async {
      final job = await _showJobCardDialog();
      if (job == null) return;
      setState(() => _serviceJobs.insert(0, job));
      await _persistWorkspaceData();
      await _enqueueSync('INSERT', 'job_cards', job.id);
    }

    Future<void> editJobCard(_ServiceJobItem existing) async {
      final updated = await _showJobCardDialog(existing: existing);
      if (updated == null) return;
      setState(() {
        final idx = _serviceJobs.indexWhere((j) => j.id == existing.id);
        if (idx != -1) _serviceJobs[idx] = updated;
      });
      await _persistWorkspaceData();
      await _enqueueSync('UPDATE', 'job_cards', updated.id);
    }

    Future<void> deleteJobCard(_ServiceJobItem job) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Job Card'),
          content: Text('Delete "${job.title}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      setState(() => _serviceJobs.removeWhere((j) => j.id == job.id));
      await _persistWorkspaceData();
      await _enqueueSync('DELETE', 'job_cards', job.id);
    }

    Color priorityColor(String priority) {
      switch (priority) {
        case 'HIGH':
          return const Color(0xFFE53935);
        case 'MEDIUM':
          return const Color(0xFFFF9800);
        default:
          return const Color(0xFF2E7D32);
      }
    }

    Color statusColor(String status) {
      switch (status) {
        case 'COMPLETED':
          return const Color(0xFF10B981);
        case 'IN_PROGRESS':
          return const Color(0xFF3B82F6);
        case 'CANCELLED':
          return const Color(0xFF6B7280);
        default: // OPEN
          return const Color(0xFF6A1B9A);
      }
    }

    Color statusBg(String status) {
      switch (status) {
        case 'COMPLETED':
          return const Color(0xFFD1FAE5);
        case 'IN_PROGRESS':
          return const Color(0xFFDBEAFE);
        case 'CANCELLED':
          return const Color(0xFFF3F4F6);
        default: // OPEN
          return const Color(0xFFEEE8FA);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Cards',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage service job cards and track progress',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: createJobCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create Job Card'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Job Cards',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            initialValue: _jobCardStatusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'ALL',
                                child: Text('All Statuses'),
                              ),
                              DropdownMenuItem(
                                value: 'OPEN',
                                child: Text('Open'),
                              ),
                              DropdownMenuItem(
                                value: 'IN_PROGRESS',
                                child: Text('In Progress'),
                              ),
                              DropdownMenuItem(
                                value: 'COMPLETED',
                                child: Text('Completed'),
                              ),
                              DropdownMenuItem(
                                value: 'CANCELLED',
                                child: Text('Cancelled'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(
                                () => _jobCardStatusFilter = value ?? 'ALL',
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            initialValue: _jobCardPriorityFilter,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'ALL',
                                child: Text('All Priorities'),
                              ),
                              DropdownMenuItem(
                                value: 'LOW',
                                child: Text('Low'),
                              ),
                              DropdownMenuItem(
                                value: 'MEDIUM',
                                child: Text('Medium'),
                              ),
                              DropdownMenuItem(
                                value: 'HIGH',
                                child: Text('High'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(
                                () => _jobCardPriorityFilter = value ?? 'ALL',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: jobs.isEmpty
                          ? Center(
                              child: Text(
                                'No job cards found',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                  fontSize: 20,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    isDark
                                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                                        : const Color(0xFFF5F2FB),
                                  ),
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        'TITLE',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'CUSTOMER',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'PRIORITY',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'SCHEDULED',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'STATUS',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'TOTAL',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'ACTIONS',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: jobs.map((job) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(job.title)),
                                        DataCell(
                                          Text(
                                            job.customerName.isEmpty
                                                ? 'Walk-in Customer'
                                                : job.customerName,
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: priorityColor(
                                                job.priority,
                                              ).withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              job.priority,
                                              style: TextStyle(
                                                color: priorityColor(
                                                  job.priority,
                                                ),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            [
                                                  job.scheduledDate,
                                                  job.scheduledTime,
                                                ]
                                                .where(
                                                  (s) => s.trim().isNotEmpty,
                                                )
                                                .join(' ')
                                                .trim(),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusBg(job.status),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              job.status.replaceAll('_', ' '),
                                              style: TextStyle(
                                                color: statusColor(job.status),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(_money(job.defaultPrice)),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                ),
                                                color: AppTheme.brandIndigo,
                                                tooltip: 'Edit',
                                                onPressed: () =>
                                                    editJobCard(job),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                ),
                                                color: const Color(0xFFEF4444),
                                                tooltip: 'Delete',
                                                onPressed: () =>
                                                    deleteJobCard(job),
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
