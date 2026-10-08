part of '../dashboard_screen.dart';

extension _locations_pageExt on _DashboardScreenState {
  Widget _buildLocationsPage() {
    final query = _employeeSearchController.text.trim().toLowerCase();
    final filtered = _locations.where((location) {
      if (query.isEmpty) return true;
      return location.name.toLowerCase().contains(query) ||
          location.code.toLowerCase().contains(query) ||
          location.city.toLowerCase().contains(query) ||
          location.country.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locations',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage branches and warehouses for this store.',
                      style: TextStyle(color: Color(0xFF6F7A8A), fontSize: 16),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _canManageSettings
                    ? () async {
                        final location = await _showLocationDialog();
                        if (location == null) return;
                        await Future.delayed(const Duration(milliseconds: 300));
                        setState(() {
                          _locations.add(location);
                          if (_storeLocation.trim().isEmpty) {
                            _storeLocation = location.name;
                          }
                        });
                        await _persistWorkspaceData();
                        await _enqueueSync('INSERT', 'locations', location.id);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiRadius.md),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Location'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _pageSurfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _pageBorderColor),
            ),
            child: TextField(
              controller: _employeeSearchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search locations...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: _pageBorderColor),
              ),
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No locations found.',
                        style: TextStyle(
                          color: Color(0xFF7A8093),
                          fontSize: 18,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final location = filtered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          title: Text(
                            location.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [location.code, location.city, location.country]
                                .where((item) => item.trim().isNotEmpty)
                                .join('  •  '),
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              if (location.isHeadquarters)
                                const Chip(label: Text('HQ')),
                              if (!location.isActive)
                                const Chip(label: Text('Inactive')),
                              IconButton(
                                onPressed: _canManageSettings
                                    ? () async {
                                        final updated =
                                            await _showLocationDialog(
                                              existing: location,
                                            );
                                        if (updated == null) return;
                                        await Future.delayed(const Duration(milliseconds: 300));
                                        setState(() {
                                          final i = _locations.indexWhere(
                                            (item) => item.id == location.id,
                                          );
                                          if (i >= 0) {
                                            _locations[i] = updated;
                                          }
                                          if (_storeLocation == location.name) {
                                            _storeLocation = updated.name;
                                          }
                                          if (_selectedLocationScope ==
                                              location.name) {
                                            _selectedLocationScope =
                                                updated.name;
                                          }
                                        });
                                        await _persistWorkspaceData();
                                        await _enqueueSync(
                                          'UPDATE',
                                          'locations',
                                          updated.id,
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed:
                                    _canManageSettings && _locations.length > 1
                                    ? () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Delete Location',
                                            ),
                                            content: const Text(
                                              'Are you sure you want to delete this location?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFD1495B,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) return;
                                        setState(() {
                                          _locations.removeWhere(
                                            (item) => item.id == location.id,
                                          );
                                          if (_storeLocation == location.name &&
                                              _locations.isNotEmpty) {
                                            _storeLocation =
                                                _locations.first.name;
                                          }
                                        });
                                        await _persistWorkspaceData();
                                        await _enqueueSync(
                                          'DELETE',
                                          'locations',
                                          location.id,
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemCount: filtered.length,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<_LocationItem?> _showLocationDialog({_LocationItem? existing}) async {
    final result = await showGeneralDialog<_LocationItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'LocationDialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _LocationDialogContent(existing: existing);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    );

    return result;
  }
}

class _LocationDialogContent extends StatefulWidget {
  final _LocationItem? existing;

  const _LocationDialogContent({Key? key, this.existing}) : super(key: key);

  @override
  State<_LocationDialogContent> createState() => _LocationDialogContentState();
}

class _LocationDialogContentState extends State<_LocationDialogContent> {
  late final TextEditingController nameController;
  late final TextEditingController codeController;
  late final TextEditingController addressController;
  late final TextEditingController cityController;
  late final TextEditingController countryController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late String openingTime;
  late String closingTime;
  late bool active;
  late bool headOffice;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.existing?.name ?? '');
    codeController = TextEditingController(text: widget.existing?.code ?? '');
    addressController =
        TextEditingController(text: widget.existing?.address ?? '');
    cityController = TextEditingController(text: widget.existing?.city ?? '');
    countryController =
        TextEditingController(text: widget.existing?.country ?? '');
    phoneController = TextEditingController(text: widget.existing?.phone ?? '');
    emailController = TextEditingController(text: widget.existing?.email ?? '');
    openingTime = widget.existing?.openingTime ?? '09:00 AM';
    closingTime = widget.existing?.closingTime ?? '06:00 PM';
    active = widget.existing?.isActive ?? true;
    headOffice = widget.existing?.isHeadquarters ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    addressController.dispose();
    cityController.dispose();
    countryController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SideSheetContainer(
      title: widget.existing == null ? 'Add Location' : 'Edit Location',
      width: 520,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiRadius.md),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              if (name.isEmpty || code.isEmpty) {
                return;
              }

              Navigator.pop(
                context,
                _LocationItem(
                  id:
                      widget.existing?.id ??
                      'LOC${DateTime.now().microsecondsSinceEpoch}',
                  name: name,
                  code: code,
                  address: addressController.text.trim(),
                  city: cityController.text.trim(),
                  country: countryController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  openingTime: openingTime,
                  closingTime: closingTime,
                  isActive: active,
                  isHeadquarters: headOffice,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiRadius.md),
              ),
            ),
            child: Text(
              widget.existing == null ? 'Add Location' : 'Update Location',
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name *',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Location Code *',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: openingTime,
                    decoration: const InputDecoration(
                      labelText: 'Opening Time',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '08:00 AM',
                        child: Text('08:00 AM'),
                      ),
                      DropdownMenuItem(
                        value: '09:00 AM',
                        child: Text('09:00 AM'),
                      ),
                      DropdownMenuItem(
                        value: '10:00 AM',
                        child: Text('10:00 AM'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => openingTime = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: closingTime,
                    decoration: const InputDecoration(
                      labelText: 'Closing Time',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '06:00 PM',
                        child: Text('06:00 PM'),
                      ),
                      DropdownMenuItem(
                        value: '07:00 PM',
                        child: Text('07:00 PM'),
                      ),
                      DropdownMenuItem(
                        value: '08:00 PM',
                        child: Text('08:00 PM'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => closingTime = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: active,
              onChanged: (value) => setState(() => active = value ?? true),
              title: const Text('Active'),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: headOffice,
              onChanged: (value) => setState(() => headOffice = value ?? false),
              title: const Text('Headquarters'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
