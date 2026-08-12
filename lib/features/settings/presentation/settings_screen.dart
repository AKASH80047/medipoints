import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../models/shop_settings_model.dart';
import '../../providers/pharmacy_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();

  bool _lowStockAlerts = true;
  bool _expiryAlerts = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider).value;
      if (settings != null) {
        _populateFields(settings);
      }
    });
  }

  void _populateFields(ShopSettings settings) {
    _shopNameController.text = settings.shopName;
    _ownerNameController.text = settings.ownerName;
    _phoneController.text = settings.phone;
    _addressController.text = settings.address;
    _gstinController.text = settings.gstin;
    setState(() {
      _lowStockAlerts = settings.lowStockAlerts;
      _expiryAlerts = settings.expiryAlerts;
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    setState(() => _isSaving = true);

    final currentSettings = ref.read(settingsProvider).value ?? ShopSettings.defaultSettings();
    final updated = currentSettings.copyWith(
      shopName: _shopNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      gstin: _gstinController.text.trim(),
      lowStockAlerts: _lowStockAlerts,
      expiryAlerts: _expiryAlerts,
    );

    await ref.read(pharmacyDataNotifierProvider.notifier).updateSettings(updated);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Shop Details Saved Successfully'),
          backgroundColor: AppColors.inStock,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings ⚙️'),
      ),
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Failed to load settings')),
          data: (settings) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Details Section
                  const Text(
                    'Shop Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _shopNameController,
                            decoration: const InputDecoration(
                              labelText: 'Shop Name',
                              prefixIcon: Icon(Icons.storefront),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _ownerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Owner Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Shop Address',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _gstinController,
                            decoration: const InputDecoration(
                              labelText: 'GSTIN (Optional)',
                              prefixIcon: Icon(Icons.receipt_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveSettings,
                              child: _isSaving
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Save Shop Details'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Options
                  const Text(
                    'App Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Low Stock Alerts'),
                          subtitle: const Text('Notify when medicine stock falls below minimum level'),
                          value: _lowStockAlerts,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => _lowStockAlerts = val);
                            _saveSettings();
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Expiry Alerts'),
                          subtitle: const Text('Notify when medicines are within 60 days of expiry'),
                          value: _expiryAlerts,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => _expiryAlerts = val);
                            _saveSettings();
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Reset Demo Data'),
                          subtitle: const Text('Restore initial sample medicines, batches & sales'),
                          trailing: const Icon(Icons.refresh, color: AppColors.secondary),
                          onTap: () {
                            ref.read(pharmacyDataNotifierProvider.notifier).resetSeedData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ Sample demo data restored!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account / Logout
                  const Text(
                    'Account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.expired),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: AppColors.expired, fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        context.go('/login');
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
