import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/widgets/empty_state.dart';
import '../../models/medicine_model.dart';
import '../../models/batch_model.dart';
import '../../models/purchase_model.dart';
import '../../providers/pharmacy_providers.dart';

class PurchaseScreen extends ConsumerStatefulWidget {
  final String? initialMedicineId;

  const PurchaseScreen({super.key, this.initialMedicineId});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final purchases = purchasesAsync.value ?? [];
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Stock 🛒'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top CTA Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primaryLight,
              child: Row(
                children: [
                  const Icon(Icons.inventory, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Supplier Purchases',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                        ),
                        Text(
                          'New purchases automatically add batch stock to inventory.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openPurchaseModal(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('+ Purchase'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(110, 44),
                    ),
                  ),
                ],
              ),
            ),

            // Purchase Records History List
            Expanded(
              child: purchases.isEmpty
                  ? EmptyStateWidget(
                      title: 'No Purchases Yet',
                      message: 'Add your first purchase to update your shop stock.',
                      icon: Icons.local_shipping_outlined,
                      buttonLabel: '+ Purchase Stock',
                      onAction: () => _openPurchaseModal(context),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        final p = purchases[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Supplier: ${p.supplierName.isNotEmpty ? p.supplierName : "Direct Supplier"}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      '₹${p.totalAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Invoice #: ${p.invoiceNumber} • Date: ${dateFormat.format(p.purchaseDate)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                if (p.supplierPhone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Phone: ${p.supplierPhone}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                ...p.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '• ${item.medicineName} (Batch: ${item.batchNumber})',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${item.quantity} units @ ₹${item.purchasePrice.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPurchaseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddPurchaseBottomSheet(
        initialMedicineId: widget.initialMedicineId,
      ),
    );
  }
}

// --- Add Purchase Form Modal (Section 17 Requirements) ---
class _AddPurchaseBottomSheet extends ConsumerStatefulWidget {
  final String? initialMedicineId;

  const _AddPurchaseBottomSheet({this.initialMedicineId});

  @override
  ConsumerState<_AddPurchaseBottomSheet> createState() => __AddPurchaseBottomSheetState();
}

class __AddPurchaseBottomSheetState extends ConsumerState<_AddPurchaseBottomSheet> {
  final _supplierNameController = TextEditingController();
  final _supplierPhoneController = TextEditingController();
  final _invoiceNumController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  Medicine? _selectedMedicine;
  final _customMedicineNameController = TextEditingController();
  final _batchNumController = TextEditingController();
  final _qtyController = TextEditingController(text: '50');
  final _purchasePriceController = TextEditingController(text: '20');
  final _sellingPriceController = TextEditingController(text: '30');
  final _mrpController = TextEditingController(text: '35');
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _invoiceNumController.text = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _batchNumController.text = 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final meds = ref.read(medicinesProvider).value ?? [];
      if (widget.initialMedicineId != null && meds.isNotEmpty) {
        final found = meds.firstWhere((m) => m.id == widget.initialMedicineId, orElse: () => meds.first);
        setState(() {
          _selectedMedicine = found;
        });
      } else if (meds.isNotEmpty) {
        setState(() {
          _selectedMedicine = meds.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _supplierPhoneController.dispose();
    _invoiceNumController.dispose();
    _customMedicineNameController.dispose();
    _batchNumController.dispose();
    _qtyController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _mrpController.dispose();
    super.dispose();
  }

  void _savePurchase() async {
    final supplierName = _supplierNameController.text.trim();
    final medName = _selectedMedicine != null
        ? _selectedMedicine!.name
        : _customMedicineNameController.text.trim();

    if (medName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a Medicine Name.')),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 1;
    final costPrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
    final mrp = double.tryParse(_mrpController.text) ?? 0.0;

    final medId = _selectedMedicine?.id ?? 'med_${DateTime.now().millisecondsSinceEpoch}';

    // If new medicine name typed manually, add medicine record first
    if (_selectedMedicine == null) {
      final newMed = Medicine(
        id: medId,
        name: medName,
        genericName: '',
        brand: '',
        category: 'Tablet',
        barcode: DateTime.now().millisecondsSinceEpoch.toString(),
        minStockAlert: 10,
      );
      final initialBatch = Batch(
        id: '',
        medicineId: medId,
        batchNumber: _batchNumController.text.trim(),
        quantity: qty,
        purchasePrice: costPrice,
        sellingPrice: sellingPrice,
        mrp: mrp,
        expiryDate: _expiryDate,
      );
      await ref.read(pharmacyDataNotifierProvider.notifier).addMedicine(newMed, initialBatch);
    }

    final item = PurchaseItem(
      medicineId: medId,
      medicineName: medName,
      batchNumber: _batchNumController.text.trim().isNotEmpty
          ? _batchNumController.text.trim()
          : 'BATCH-001',
      quantity: qty,
      purchasePrice: costPrice,
      mrp: mrp,
      sellingPrice: sellingPrice,
      expiryDate: _expiryDate,
    );

    final purchase = Purchase(
      id: '',
      supplierName: supplierName.isNotEmpty ? supplierName : 'Supplier',
      supplierPhone: _supplierPhoneController.text.trim(),
      invoiceNumber: _invoiceNumController.text.trim(),
      purchaseDate: _purchaseDate,
      items: [item],
      totalAmount: item.totalAmount,
    );

    await ref.read(pharmacyDataNotifierProvider.notifier).recordPurchase(purchase);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Stock Added Successfully'),
          backgroundColor: AppColors.inStock,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(medicinesProvider);
    final meds = medsAsync.value ?? [];
    final dateFormat = DateFormat('dd MMM yyyy');

    final qty = int.tryParse(_qtyController.text) ?? 0;
    final costPrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
    final totalAmount = qty * costPrice;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Record Purchase Stock',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Supplier Section
            const Text('Supplier Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _supplierNameController,
                    decoration: const InputDecoration(labelText: 'Supplier Name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _supplierPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Supplier Phone'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _invoiceNumController,
                    decoration: const InputDecoration(labelText: 'Invoice Number'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _purchaseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _purchaseDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Purchase Date'),
                      child: Text(dateFormat.format(_purchaseDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Purchased Item Section
            const Text('Medicine Batch Purchased', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),

            if (meds.isNotEmpty) ...[
              DropdownButtonFormField<Medicine>(
                initialValue: _selectedMedicine,
                decoration: const InputDecoration(labelText: 'Select Existing Medicine'),
                items: meds
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedMedicine = val;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedMedicine == null) ...[
              TextField(
                controller: _customMedicineNameController,
                decoration: const InputDecoration(labelText: 'New Medicine Name (if not in list)'),
              ),
              const SizedBox(height: 12),
            ],

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
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _purchasePriceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Purchase Price (₹)'),
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
            const SizedBox(height: 12),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              title: const Text('Expiry Date'),
              subtitle: Text(
                DateFormat('MMMM yyyy').format(_expiryDate),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              trailing: const Icon(Icons.calendar_month, color: AppColors.primary),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _expiryDate = picked);
              },
            ),

            const SizedBox(height: 20),

            // Total Amount Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Purchase Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '₹${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _savePurchase,
                child: const Text('Save Purchase'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
