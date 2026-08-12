import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../models/medicine_model.dart';
import '../../models/batch_model.dart';
import '../../models/sale_model.dart';
import '../../models/shop_settings_model.dart';
import '../../providers/pharmacy_providers.dart';
import '../../services/pdf_invoice_service.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Sale? _completedSale;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final medicinesAsync = ref.watch(medicinesProvider);
    final batchesAsync = ref.watch(batchesProvider);
    final isTablet = MediaQuery.of(context).size.width >= 720;

    // Show Bill Success screen if last bill was completed
    if (_completedSale != null) {
      return _BillSuccessView(
        sale: _completedSale!,
        onNewBill: () {
          setState(() {
            _completedSale = null;
          });
          cartNotifier.resetCart();
        },
      );
    }

    final meds = medicinesAsync.value ?? [];
    final batches = batchesAsync.value ?? [];

    // Filter medicines by search query (Section 12: Manual Search Fallback)
    final filteredMeds = meds.where((m) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.genericName.toLowerCase().contains(q) ||
          m.brand.toLowerCase().contains(q) ||
          m.barcode.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bill 🧾'),
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => cartNotifier.resetCart(),
              icon: const Icon(Icons.delete_sweep, color: AppColors.expired, size: 20),
              label: const Text(
                'Clear',
                style: TextStyle(color: AppColors.expired, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner for stock limits or expired warnings
            if (cartState.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.expiredBg,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.expired, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cartState.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.expired,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.expired),
                      onPressed: () => cartNotifier.clearErrorMessage(),
                    ),
                  ],
                ),
              ),
            ],

            // Top Search Bar & Barcode Scanner Button (Sections 9 & 10)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search medicine by name, generic, brand or barcode...',
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
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openBarcodeScannerModal(context, meds, batches),
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    label: const Text('📷 Scan'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 52),
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

            // Content Layout (Tablet Split View vs Mobile Stack)
            Expanded(
              child: isTablet
                  ? Row(
                      children: [
                        // Left Pane: Search Results Catalog
                        Expanded(
                          flex: 5,
                          child: _buildMedicineCatalog(filteredMeds, batches),
                        ),
                        const VerticalDivider(width: 1, color: AppColors.border),
                        // Right Pane: Live Cart Pane
                        Expanded(
                          flex: 4,
                          child: _buildCartPane(cartState, cartNotifier),
                        ),
                      ],
                    )
                  : _buildMedicineCatalog(filteredMeds, batches),
            ),

            // Mobile Sticky Bottom Bar showing Cart Total and CHARGE button
            if (!isTablet && cartState.items.isNotEmpty)
              _buildMobileCheckoutBar(context, cartState, cartNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCatalog(List<Medicine> meds, List<Batch> allBatches) {
    if (meds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No medicine found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Try searching by medicine name or generic name',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        final medBatches = allBatches.where((b) => b.medicineId == med.id).toList();

        final totalStock = medBatches.fold(0, (sum, b) => sum + b.quantity);
        final activeBatches = medBatches.where((b) => !b.isExpired && b.quantity > 0).toList();
        final hasExpiredBatch = medBatches.any((b) => b.isExpired && b.quantity > 0);

        final defaultBatch = activeBatches.isNotEmpty
            ? activeBatches.first
            : (medBatches.isNotEmpty ? medBatches.first : null);
        final price = defaultBatch != null ? defaultBatch.sellingPrice : 0.0;

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              med.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  '${med.genericName} • ${med.brand}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Stock: $totalStock',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: totalStock <= med.minStockAlert ? AppColors.lowStock : AppColors.textMuted,
                      ),
                    ),
                    if (hasExpiredBatch) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.expiredBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '⚠ Expired Batch Present',
                          style: TextStyle(fontSize: 10, color: AppColors.expired, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: totalStock > 0
                  ? () => _openBatchSelectionModal(context, med, medBatches)
                  : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Add'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(90, 42),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openBatchSelectionModal(BuildContext context, Medicine medicine, List<Batch> batches) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _BatchSelectorBottomSheet(
          medicine: medicine,
          batches: batches,
          onBatchSelected: (batch, quantity) {
            ref.read(cartProvider.notifier).addItem(medicine, batch, qty: quantity);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // --- Real Camera Barcode Scanner Modal (Section 10) ---
  void _openBarcodeScannerModal(BuildContext context, List<Medicine> meds, List<Batch> batches) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _BarcodeScannerBottomSheet(
          onBarcodeDetected: (scannedCode) {
            Navigator.pop(context);
            _processScannedBarcode(context, scannedCode, meds, batches);
          },
        );
      },
    );
  }

  void _processScannedBarcode(BuildContext context, String code, List<Medicine> meds, List<Batch> batches) {
    final matchedMed = meds.firstWhere(
      (m) => m.barcode == code || m.barcode.endsWith(code),
      orElse: () => Medicine(
        id: '',
        name: '',
        genericName: '',
        brand: '',
        category: '',
        barcode: '',
        minStockAlert: 0,
      ),
    );

    // Section 11: Barcode Not Found
    if (matchedMed.id.isEmpty) {
      _showBarcodeNotFoundDialog(context, code);
      return;
    }

    final medBatches = batches.where((b) => b.medicineId == matchedMed.id).toList();
    _openBatchSelectionModal(context, matchedMed, medBatches);
  }

  void _showBarcodeNotFoundDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Barcode Not Found'),
          content: Text(
            'This barcode ($code) is not registered in your stock yet.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/stock');
              },
              child: const Text('Search Manually'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/stock?action=add');
              },
              child: const Text('+ Add Medicine'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartPane(CartState cartState, CartNotifier cartNotifier) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Bill (${cartState.totalItemCount} Items)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ₹${cartState.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: cartState.items.isEmpty
                ? const Center(
                    child: Text(
                      'No items added to bill yet.\nTap "+ Add" or scan a barcode.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cartState.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.medicine.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    'Batch: ${item.batch.batchNumber} • ₹${item.unitPrice.toStringAsFixed(0)} each',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Controls: [-] 1 [+]
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                                  onPressed: () => cartNotifier.updateQuantity(index, item.quantity - 1),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                  onPressed: () => cartNotifier.updateQuantity(index, item.quantity + 1),
                                ),
                              ],
                            ),

                            const SizedBox(width: 8),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Cart Footer & Charge Button
          if (cartState.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(color: AppColors.textMuted)),
                      Text('₹${cartState.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _openPaymentModal(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inStock,
                      ),
                      child: Text(
                        'CHARGE  ₹${cartState.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileCheckoutBar(BuildContext context, CartState cartState, CartNotifier cartNotifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _openMobileCartBottomSheet(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items: ${cartState.totalItemCount}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  'Total: ₹${cartState.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _openPaymentModal(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(160, 50),
              backgroundColor: AppColors.inStock,
            ),
            child: Text(
              'CHARGE ₹${cartState.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openMobileCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final cartState = ref.watch(cartProvider);
            final cartNotifier = ref.read(cartProvider.notifier);
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: _buildCartPane(cartState, cartNotifier),
            );
          },
        );
      },
    );
  }

  void _openPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PaymentBottomSheet(
          onCompleted: (sale) {
            setState(() {
              _completedSale = sale;
            });
          },
        );
      },
    );
  }
}

// --- Barcode Scanner Bottom Sheet (Section 10) ---
class _BarcodeScannerBottomSheet extends StatefulWidget {
  final Function(String barcode) onBarcodeDetected;

  const _BarcodeScannerBottomSheet({required this.onBarcodeDetected});

  @override
  State<_BarcodeScannerBottomSheet> createState() => _BarcodeScannerBottomSheetState();
}

class _BarcodeScannerBottomSheetState extends State<_BarcodeScannerBottomSheet> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isTorchOn = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📷 Scan Medicine Barcode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  _scannerController.toggleTorch();
                  setState(() {
                    _isTorchOn = !_isTorchOn;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Point camera at medicine box or strip barcode',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Camera Frame Container
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      if (_hasScanned) return;
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final code = barcodes.first.rawValue;
                        if (code != null && code.isNotEmpty) {
                          _hasScanned = true;
                          widget.onBarcodeDetected(code);
                        }
                      }
                    },
                  ),
                  // Framing Overlay
                  Center(
                    child: Container(
                      width: 250,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 3),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Simulation fallback button for testing on web/desktop without camera
          OutlinedButton.icon(
            onPressed: () {
              widget.onBarcodeDetected('8901234567890'); // Simulates Paracetamol scan
            },
            icon: const Icon(Icons.touch_app),
            label: const Text('Simulate Barcode Scan (Paracetamol)'),
          ),
        ],
      ),
    );
  }
}

// --- Batch Selector Bottom Sheet ---
class _BatchSelectorBottomSheet extends StatefulWidget {
  final Medicine medicine;
  final List<Batch> batches;
  final Function(Batch batch, int quantity) onBatchSelected;

  const _BatchSelectorBottomSheet({
    required this.medicine,
    required this.batches,
    required this.onBatchSelected,
  });

  @override
  State<_BatchSelectorBottomSheet> createState() => _BatchSelectorBottomSheetState();
}

class _BatchSelectorBottomSheetState extends State<_BatchSelectorBottomSheet> {
  Batch? _selectedBatch;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final validBatches = widget.batches.where((b) => !b.isExpired && b.quantity > 0).toList();
    if (validBatches.isNotEmpty) {
      _selectedBatch = validBatches.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM yyyy');

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.medicine.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            '${widget.medicine.genericName} • ${widget.medicine.brand}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),

          const Text(
            'Select Batch:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),

          if (widget.batches.isEmpty)
            const Text(
              'No batch stock available for this medicine.',
              style: TextStyle(color: AppColors.expired, fontWeight: FontWeight.bold),
            )
          else
            ...widget.batches.map((batch) {
              final isExpired = batch.isExpired;
              final isSelected = _selectedBatch?.id == batch.id;

              return Card(
                color: isExpired
                    ? AppColors.expiredBg
                    : (isSelected ? AppColors.primaryLight : AppColors.surface),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isExpired
                        ? AppColors.expired
                        : (isSelected ? AppColors.primary : AppColors.border),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: isExpired
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠ Cannot Sell: This medicine batch has expired.'),
                              backgroundColor: AppColors.expired,
                            ),
                          );
                        }
                      : () {
                          setState(() {
                            _selectedBatch = batch;
                            if (_quantity > batch.quantity) _quantity = batch.quantity;
                          });
                        },
                  title: Row(
                    children: [
                      Text(
                        'Batch: ${batch.batchNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      if (isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.expired,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⚠ EXPIRED',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    'Exp: ${dateFormat.format(batch.expiryDate)} • Stock: ${batch.quantity} • MRP: ₹${batch.mrp.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '₹${batch.sellingPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),

          if (_selectedBatch != null && !_selectedBatch!.isExpired) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantity:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 28, color: AppColors.primary),
                      onPressed: _quantity > 1
                          ? () {
                              setState(() {
                                _quantity--;
                              });
                            }
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 28, color: AppColors.primary),
                      onPressed: _quantity < _selectedBatch!.quantity
                          ? () {
                              setState(() {
                                _quantity++;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.onBatchSelected(_selectedBatch!, _quantity);
                },
                child: Text('Add to Bill (₹${(_selectedBatch!.sellingPrice * _quantity).toStringAsFixed(0)})'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --- Payment Method Bottom Sheet ---
class _PaymentBottomSheet extends ConsumerStatefulWidget {
  final Function(Sale sale) onCompleted;

  const _PaymentBottomSheet({required this.onCompleted});

  @override
  ConsumerState<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<_PaymentBottomSheet> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _discountController = TextEditingController(text: '0');

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final settingsAsync = ref.watch(settingsProvider);

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
          const Text(
            'How did the customer pay?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Amount: ₹${cartState.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Payment Option Cards
          Row(
            children: [
              Expanded(
                child: _PaymentOptionCard(
                  title: 'Cash',
                  emoji: '💵',
                  isSelected: _selectedMethod == PaymentMethod.cash,
                  onTap: () {
                    setState(() {
                      _selectedMethod = PaymentMethod.cash;
                    });
                    cartNotifier.setPaymentMethod(PaymentMethod.cash);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PaymentOptionCard(
                  title: 'UPI',
                  emoji: '📱',
                  isSelected: _selectedMethod == PaymentMethod.upi,
                  onTap: () {
                    setState(() {
                      _selectedMethod = PaymentMethod.upi;
                    });
                    cartNotifier.setPaymentMethod(PaymentMethod.upi);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PaymentOptionCard(
                  title: 'Card',
                  emoji: '💳',
                  isSelected: _selectedMethod == PaymentMethod.card,
                  onTap: () {
                    setState(() {
                      _selectedMethod = PaymentMethod.card;
                    });
                    cartNotifier.setPaymentMethod(PaymentMethod.card);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Discount Field
          TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final d = double.tryParse(val) ?? 0.0;
              cartNotifier.setDiscount(d);
            },
            decoration: const InputDecoration(
              labelText: 'Discount (₹)',
              prefixIcon: Icon(Icons.discount_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Charge/Complete Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: cartState.isProcessing
                  ? null
                  : () async {
                      final settings = settingsAsync.value ?? ShopSettings.defaultSettings();
                      final completedSale = await cartNotifier.checkout(settings);
                      if (completedSale != null && mounted) {
                        Navigator.pop(context);
                        widget.onCompleted(completedSale);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inStock,
              ),
              child: cartState.isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'COMPLETE BILL (₹${cartState.totalAmount.toStringAsFixed(0)})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.title,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.primaryLight : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Bill Success View ---
class _BillSuccessView extends StatelessWidget {
  final Sale sale;
  final VoidCallback onNewBill;

  const _BillSuccessView({
    required this.sale,
    required this.onNewBill,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.inStockBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.inStock,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '✓ Bill Created',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inStock,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invoice #: ${sale.invoiceNumber}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${sale.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Print Bill Action
                    ElevatedButton.icon(
                      onPressed: () => PdfInvoiceService.printInvoice(sale),
                      icon: const Icon(Icons.print, size: 20),
                      label: const Text('Print Bill'),
                    ),
                    const SizedBox(height: 12),

                    // Share Bill Action
                    OutlinedButton.icon(
                      onPressed: () => PdfInvoiceService.shareInvoice(sale),
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text('Share Bill'),
                    ),
                    const SizedBox(height: 12),

                    // New Bill Action
                    TextButton.icon(
                      onPressed: onNewBill,
                      icon: const Icon(Icons.add_shopping_cart, size: 20, color: AppColors.primary),
                      label: const Text(
                        '+ Next Customer Bill',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
