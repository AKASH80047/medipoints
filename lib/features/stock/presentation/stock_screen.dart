import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/widgets/custom_badge.dart';
import '../../common/widgets/empty_state.dart';
import '../../models/medicine_model.dart';
import '../../models/batch_model.dart';
import '../../providers/pharmacy_providers.dart';

class StockScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  final bool initialOpenAdd;

  const StockScreen({
    super.key,
    this.initialFilter,
    this.initialOpenAdd = false,
  });

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all', 'low', 'expiring30', 'expiring60', 'expiring90', 'expired'

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _activeFilter = widget.initialFilter!;
    }
    if (widget.initialOpenAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openAddMedicineDialog(context);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider);
    final batchesAsync = ref.watch(batchesProvider);

    final meds = medicinesAsync.value ?? [];
    final batches = batchesAsync.value ?? [];

    // Filter medicines
    final filteredMeds = meds.where((m) {
      final q = _searchQuery.trim().toLowerCase();
      final textMatches = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.genericName.toLowerCase().contains(q) ||
          m.brand.toLowerCase().contains(q);

      if (!textMatches) return false;

      final mBatches = batches.where((b) => b.medicineId == m.id).toList();
      final totalStock = mBatches.fold(0, (sum, b) => sum + b.quantity);

      if (_activeFilter == 'low') {
        return totalStock <= m.minStockAlert;
      }
      if (_activeFilter == 'expired') {
        return mBatches.any((b) => b.isExpired);
      }
      if (_activeFilter == 'expiring30') {
        return mBatches.any((b) => b.isExpiringWithin(30));
      }
      if (_activeFilter == 'expiring60' || _activeFilter == 'expiring') {
        return mBatches.any((b) => b.isExpiringWithin(60));
      }
      if (_activeFilter == 'expiring90') {
        return mBatches.any((b) => b.isExpiringWithin(90));
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock 📦'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: () => _openAddMedicineDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Add Medicine'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 42),
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search medicine by name, generic or brand...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Filter Chips (Section 24, 31, 33 Requirements)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Medicines', '📦'),
                  const SizedBox(width: 8),
                  _buildFilterChip('low', 'Reorder List (Low Stock)', '🟠'),
                  const SizedBox(width: 8),
                  _buildFilterChip('expiring30', 'Expires < 30 Days', '🟡'),
                  const SizedBox(width: 8),
                  _buildFilterChip('expiring60', 'Expires < 60 Days', '🟡'),
                  const SizedBox(width: 8),
                  _buildFilterChip('expiring90', 'Expires < 90 Days', '🟡'),
                  const SizedBox(width: 8),
                  _buildFilterChip('expired', 'Expired', '🔴'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Medicine Stock List
            Expanded(
              child: filteredMeds.isEmpty
                  ? EmptyStateWidget(
                      title: 'No Medicines Found',
                      message: _activeFilter == 'all'
                          ? 'Add your first medicine to start managing your stock.'
                          : 'No medicines match the selected filter.',
                      icon: Icons.inventory_2_outlined,
                      buttonLabel: '+ Add Medicine',
                      onAction: () => _openAddMedicineDialog(context),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredMeds.length,
                      itemBuilder: (context, index) {
                        final med = filteredMeds[index];
                        final medBatches = batches.where((b) => b.medicineId == med.id).toList();

                        return _MedicineStockCard(
                          medicine: med,
                          batches: medBatches,
                          onPurchaseMore: () {
                            context.go('/purchase?medId=${med.id}');
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String emoji) {
    final isSelected = _activeFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text('$emoji $label'),
      selectedColor: AppColors.primaryLight,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isSelected ? AppColors.primary : AppColors.textDark,
      ),
      onSelected: (_) {
        setState(() {
          _activeFilter = value;
        });
      },
    );
  }

  void _openAddMedicineDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddMedicineStepperBottomSheet(),
    );
  }
}

// --- Medicine Stock Card ---
class _MedicineStockCard extends StatelessWidget {
  final Medicine medicine;
  final List<Batch> batches;
  final VoidCallback onPurchaseMore;

  const _MedicineStockCard({
    required this.medicine,
    required this.batches,
    required this.onPurchaseMore,
  });

  @override
  Widget build(BuildContext context) {
    final totalStock = batches.fold(0, (sum, b) => sum + b.quantity);
    final hasExpired = batches.any((b) => b.isExpired && b.quantity > 0);
    final isLowStock = totalStock <= medicine.minStockAlert;
    final isExpiringSoon = batches.any((b) => b.isExpiringWithin(60) && b.quantity > 0);

    final defaultBatch = batches.isNotEmpty ? batches.first : null;
    final dateFormat = DateFormat('MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Medicine Name + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${medicine.genericName} • ${medicine.brand} • ${medicine.category}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (hasExpired)
                  CustomBadge.status(StockStatus.expired)
                else if (isLowStock)
                  CustomBadge.status(StockStatus.lowStock, quantity: totalStock)
                else if (isExpiringSoon)
                  CustomBadge.status(StockStatus.expiringSoon)
                else
                  CustomBadge.status(StockStatus.inStock, quantity: totalStock),
              ],
            ),
            const SizedBox(height: 12),

            // Price & Min Stock Metrics
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PriceMetric(
                    label: 'Selling Price',
                    price: defaultBatch?.sellingPrice ?? 0,
                    color: AppColors.primary,
                  ),
                  _PriceMetric(
                    label: 'MRP',
                    price: defaultBatch?.mrp ?? 0,
                    color: AppColors.textDark,
                  ),
                  _PriceMetric(
                    label: 'Cost',
                    price: defaultBatch?.purchasePrice ?? 0,
                    color: AppColors.textMuted,
                  ),
                  Column(
                    children: [
                      const Text('Min Alert', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text(
                        '${medicine.minStockAlert}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.lowStock),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Batches List
            if (batches.isNotEmpty) ...[
              const Text(
                'Available Batches:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              ...batches.map((batch) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Batch: ${batch.batchNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Exp: ${dateFormat.format(batch.expiryDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: batch.isExpired ? AppColors.expired : AppColors.textMuted,
                              fontWeight: batch.isExpired ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Qty: ${batch.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: batch.quantity <= medicine.minStockAlert
                              ? AppColors.lowStock
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 12),
            if (isLowStock)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPurchaseMore,
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('+ Purchase More Stock'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.lowStock,
                    side: const BorderSide(color: AppColors.lowStock),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceMetric extends StatelessWidget {
  final String label;
  final double price;
  final Color color;

  const _PriceMetric({
    required this.label,
    required this.price,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        Text(
          '₹${price.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// --- Step-by-Step 3 Step Add Medicine Modal (Section 27 Requirements) ---
class _AddMedicineStepperBottomSheet extends ConsumerStatefulWidget {
  const _AddMedicineStepperBottomSheet();

  @override
  ConsumerState<_AddMedicineStepperBottomSheet> createState() =>
      _AddMedicineStepperBottomSheetState();
}

class _AddMedicineStepperBottomSheetState
    extends ConsumerState<_AddMedicineStepperBottomSheet> {
  int _currentStep = 1;

  // Step 1 — Medicine Info
  final _nameController = TextEditingController();
  final _genericController = TextEditingController();
  final _brandController = TextEditingController();
  final _manufacturerController = TextEditingController(text: 'Standard Pharma');
  String _category = AppConstants.medicineCategories.first;
  String _unit = AppConstants.medicineUnits.first;

  // Step 2 — Stock & Pricing
  final _batchNumController = TextEditingController();
  final _qtyController = TextEditingController(text: '10');
  final _costPriceController = TextEditingController(text: '15');
  final _sellingPriceController = TextEditingController(text: '25');
  final _mrpController = TextEditingController(text: '30');

  // Step 3 — Expiry & Min Stock
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  final _minStockController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _batchNumController.text = 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericController.dispose();
    _brandController.dispose();
    _manufacturerController.dispose();
    _batchNumController.dispose();
    _qtyController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _mrpController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _saveMedicine() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Medicine Name.')),
      );
      return;
    }

    final med = Medicine(
      id: '',
      name: name,
      genericName: _genericController.text.trim(),
      brand: _brandController.text.trim(),
      category: _category,
      manufacturer: _manufacturerController.text.trim(),
      unit: _unit,
      barcode: DateTime.now().millisecondsSinceEpoch.toString(),
      minStockAlert: int.tryParse(_minStockController.text) ?? 10,
    );

    final batch = Batch(
      id: '',
      medicineId: '',
      batchNumber: _batchNumController.text.trim().isNotEmpty
          ? _batchNumController.text.trim()
          : 'BATCH-001',
      quantity: int.tryParse(_qtyController.text) ?? 1,
      purchasePrice: double.tryParse(_costPriceController.text) ?? 0.0,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
      mrp: double.tryParse(_mrpController.text) ?? 0.0,
      expiryDate: _expiryDate,
    );

    await ref.read(pharmacyDataNotifierProvider.notifier).addMedicine(med, batch);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Medicine Added to Stock!'),
          backgroundColor: AppColors.inStock,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '+ Add Medicine',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step $_currentStep of 3',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step 1 — Medicine Information
          if (_currentStep == 1) ...[
            const Text('Step 1 — Medicine Info', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medicine Name * (e.g. Paracetamol 500mg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genericController,
              decoration: const InputDecoration(labelText: 'Generic Name (e.g. Acetaminophen)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Brand (e.g. Dolo / Calpol)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: AppConstants.medicineCategories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
              ],
            ),
          ],

          // Step 2 — Stock & Pricing
          if (_currentStep == 2) ...[
            const Text('Step 2 — Stock & Pricing', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _batchNumController,
                    decoration: const InputDecoration(labelText: 'Batch Number'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Initial Quantity'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cost Price (₹)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _sellingPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Selling Price (₹)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _mrpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'MRP (₹)'),
                  ),
                ),
              ],
            ),
          ],

          // Step 3 — Expiry & Alerts
          if (_currentStep == 3) ...[
            const Text('Step 3 — Expiry & Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              title: const Text('Expiry Month & Year'),
              subtitle: Text(
                DateFormat('MMMM yyyy').format(_expiryDate),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
              trailing: const Icon(Icons.calendar_month, color: AppColors.primary),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) {
                  setState(() => _expiryDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minStockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Stock Alert Level (Notify when below)',
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              if (_currentStep > 1)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 1) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep < 3) {
                      if (_currentStep == 1 && _nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter Medicine Name.')),
                        );
                        return;
                      }
                      setState(() => _currentStep++);
                    } else {
                      _saveMedicine();
                    }
                  },
                  child: Text(_currentStep < 3 ? 'Next Step →' : 'Save Medicine'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
