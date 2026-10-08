part of '../dashboard_screen.dart';

extension _services_pageExt on _DashboardScreenState {
  Widget _buildServicesPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final query = _serviceSearchController.text.trim().toLowerCase();
    final filtered = _serviceJobs.where((s) {
      if (query.isEmpty) return true;
      return s.title.toLowerCase().contains(query) ||
          s.sku.toLowerCase().contains(query) ||
          s.description.toLowerCase().contains(query);
    }).toList();

    Future<void> addService() async {
      final job = await _showServiceDialog();
      if (job == null) return;
      setState(() => _serviceJobs.insert(0, job));
      await _persistWorkspaceData();
      await _enqueueSync('INSERT', 'services', job.id);
    }

    Future<void> editService(_ServiceJobItem service) async {
      final updated = await _showServiceDialog(existing: service);
      if (updated == null) return;
      final index = _serviceJobs.indexWhere((item) => item.id == service.id);
      if (index < 0) return;
      setState(() => _serviceJobs[index] = updated);
      await _persistWorkspaceData();
      await _enqueueSync('UPDATE', 'services', updated.id);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 640;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Services Management',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: narrow ? 22 : 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your service offerings',
                    style: textTheme.bodyMedium,
                  ),
                ],
              );
              final buttons = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _selectedNavKey = 'jobCards');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Job Cards'),
                  ),
                  ElevatedButton.icon(
                    onPressed: addService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Service'),
                  ),
                ],
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleBlock, const SizedBox(height: 12), buttons],
                );
              }
              return Row(
                children: [
                  Expanded(child: titleBlock),
                  buttons,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outline),
            ),
            child: TextField(
              controller: _serviceSearchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search services by name, SKU, or description...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: colorScheme.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Services (${filtered.length})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No services found',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
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
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                                colorScheme.primary.withValues(
                                                  alpha: 0.16,
                                                ),
                                              ),
                                          columns: const [
                                            DataColumn(label: Text('SERVICE')),
                                            DataColumn(label: Text('SKU')),
                                            DataColumn(label: Text('PRICE')),
                                            DataColumn(label: Text('STATUS')),
                                            DataColumn(label: Text('ACTIONS')),
                                          ],
                                          rows: filtered.map((s) {
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        s.title,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        s.description,
                                                        style: TextStyle(
                                                          color: colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(Text(s.sku)),
                                                DataCell(
                                                  Text(_money(s.defaultPrice)),
                                                ),
                                                DataCell(
                                                  Switch(
                                                    value: s.active,
                                                    onChanged: (v) async {
                                                      setState(
                                                        () => s.active = v,
                                                      );
                                                      await _persistWorkspaceData();
                                                      await _enqueueSync(
                                                        'UPDATE',
                                                        'services',
                                                        s.id,
                                                      );
                                                    },
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        onPressed: () =>
                                                            editService(s),
                                                        tooltip: 'Edit Service',
                                                        icon: const Icon(
                                                          Icons.edit_outlined,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () async {
                                                          setState(() {
                                                            _serviceJobs
                                                                .removeWhere(
                                                                  (x) =>
                                                                      x.id ==
                                                                      s.id,
                                                                );
                                                          });
                                                          await _persistWorkspaceData();
                                                          await _enqueueSync(
                                                            'DELETE',
                                                            'services',
                                                            s.id,
                                                          );
                                                        },
                                                        tooltip:
                                                            'Delete Service',
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                        ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
