import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../models/batch_model.dart';
import '../models/cart_item_model.dart';
import '../models/sale_model.dart';
import '../models/purchase_model.dart';
import '../models/shop_settings_model.dart';
import '../services/pharmacy_repository.dart';

// Repository Provider
final repositoryProvider = Provider<PharmacyRepository>((ref) {
  return PharmacyRepository();
});

// Data Notifier for App Refresh State
class PharmacyDataNotifier extends StateNotifier<int> {
  final PharmacyRepository _repo;

  PharmacyDataNotifier(this._repo) : super(0);

  void refresh() {
    state++;
  }

  Future<void> addMedicine(Medicine med, Batch batch) async {
    await _repo.addMedicine(med, batch);
    refresh();
  }

  Future<Sale> recordSale(Sale sale) async {
    final result = await _repo.createSale(sale);
    refresh();
    return result;
  }

  Future<Purchase> recordPurchase(Purchase purchase) async {
    final result = await _repo.recordPurchase(purchase);
    refresh();
    return result;
  }

  Future<void> updateSettings(ShopSettings settings) async {
    await _repo.saveSettings(settings);
    refresh();
  }

  void resetSeedData() {
    _repo.resetToSeedData();
    refresh();
  }
}

final pharmacyDataNotifierProvider =
    StateNotifierProvider<PharmacyDataNotifier, int>((ref) {
  final repo = ref.watch(repositoryProvider);
  return PharmacyDataNotifier(repo);
});

// Medicines Provider
final medicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  ref.watch(pharmacyDataNotifierProvider);
  final repo = ref.watch(repositoryProvider);
  return await repo.getMedicines();
});

// Batches Provider
final batchesProvider = FutureProvider<List<Batch>>((ref) async {
  ref.watch(pharmacyDataNotifierProvider);
  final repo = ref.watch(repositoryProvider);
  return await repo.getBatches();
});

// Sales Provider
final salesProvider = FutureProvider<List<Sale>>((ref) async {
  ref.watch(pharmacyDataNotifierProvider);
  final repo = ref.watch(repositoryProvider);
  return await repo.getSales();
});

// Purchases Provider
final purchasesProvider = FutureProvider<List<Purchase>>((ref) async {
  ref.watch(pharmacyDataNotifierProvider);
  final repo = ref.watch(repositoryProvider);
  return await repo.getPurchases();
});

// Settings Provider
final settingsProvider = FutureProvider<ShopSettings>((ref) async {
  ref.watch(pharmacyDataNotifierProvider);
  final repo = ref.watch(repositoryProvider);
  return await repo.getSettings();
});

// Combined Stock Summary Alert State
class StockAlertsSummary {
  final List<Batch> lowStockBatches;
  final List<Batch> expiredBatches;
  final List<Batch> expiringSoonBatches;
  final int totalMedicineTypes;

  const StockAlertsSummary({
    required this.lowStockBatches,
    required this.expiredBatches,
    required this.expiringSoonBatches,
    required this.totalMedicineTypes,
  });
}

final stockAlertsProvider = Provider<StockAlertsSummary>((ref) {
  final medsAsync = ref.watch(medicinesProvider);
  final batchesAsync = ref.watch(batchesProvider);

  final meds = medsAsync.value ?? [];
  final batches = batchesAsync.value ?? [];

  final List<Batch> lowStock = [];
  final List<Batch> expired = [];
  final List<Batch> expiringSoon = [];

  for (final batch in batches) {
    if (batch.isExpired) {
      expired.add(batch);
    } else if (batch.isExpiringWithin(60)) {
      expiringSoon.add(batch);
    }

    final medicine = meds.firstWhere(
      (m) => m.id == batch.medicineId,
      orElse: () => Medicine(
        id: '',
        name: '',
        genericName: '',
        brand: '',
        category: '',
        barcode: '',
        minStockAlert: 10,
      ),
    );

    if (batch.quantity <= medicine.minStockAlert) {
      lowStock.add(batch);
    }
  }

  return StockAlertsSummary(
    lowStockBatches: lowStock,
    expiredBatches: expired,
    expiringSoonBatches: expiringSoon,
    totalMedicineTypes: meds.length,
  );
});

// --- Billing Cart State ---
class CartState {
  final List<CartItem> items;
  final double discount;
  final PaymentMethod paymentMethod;
  final bool isProcessing;
  final Sale? lastCompletedSale;
  final String? errorMessage;

  const CartState({
    this.items = const [],
    this.discount = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.isProcessing = false,
    this.lastCompletedSale,
    this.errorMessage,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalAmount => (subtotal - discount).clamp(0.0, 999999.0);

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    double? discount,
    PaymentMethod? paymentMethod,
    bool? isProcessing,
    Sale? lastCompletedSale,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      lastCompletedSale: lastCompletedSale,
      errorMessage: errorMessage,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;

  CartNotifier(this._ref) : super(const CartState());

  void addItem(Medicine medicine, Batch batch, {int qty = 1}) {
    if (batch.isExpired) {
      state = state.copyWith(
        errorMessage: 'This batch has expired and cannot be sold.',
      );
      return;
    }

    final existingIndex = state.items.indexWhere(
        (i) => i.medicine.id == medicine.id && i.batch.id == batch.id);

    if (existingIndex != -1) {
      final currentQty = state.items[existingIndex].quantity;
      final newQty = currentQty + qty;
      if (newQty > batch.quantity) {
        state = state.copyWith(
          errorMessage: 'Not enough stock available in this batch (${batch.quantity} available).',
        );
        return;
      }
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] =
          updatedItems[existingIndex].copyWith(quantity: newQty);
      state = state.copyWith(items: updatedItems, errorMessage: null);
    } else {
      if (qty > batch.quantity) {
        state = state.copyWith(
          errorMessage: 'Not enough stock available in this batch.',
        );
        return;
      }
      final newItem = CartItem(
        medicine: medicine,
        batch: batch,
        quantity: qty,
        unitPrice: batch.sellingPrice,
      );
      state = state.copyWith(
        items: [...state.items, newItem],
        errorMessage: null,
      );
    }
  }

  void updateQuantity(int index, int newQty) {
    if (index < 0 || index >= state.items.length) return;
    if (newQty <= 0) {
      removeItem(index);
      return;
    }

    final item = state.items[index];
    if (newQty > item.batch.quantity) {
      state = state.copyWith(
        errorMessage: 'Not enough stock available (${item.batch.quantity} max).',
      );
      return;
    }

    final updatedItems = List<CartItem>.from(state.items);
    updatedItems[index] = item.copyWith(quantity: newQty);
    state = state.copyWith(items: updatedItems, errorMessage: null);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updatedItems = List<CartItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: updatedItems, errorMessage: null);
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount.clamp(0.0, state.subtotal));
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  void resetCart() {
    state = const CartState();
  }

  Future<Sale?> checkout(ShopSettings settings) async {
    if (state.items.isEmpty) {
      state = state.copyWith(errorMessage: 'Cart is empty. Please add items.');
      return null;
    }

    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final invoiceNum = 'MP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final sale = Sale(
        id: '',
        invoiceNumber: invoiceNum,
        dateTime: DateTime.now(),
        items: state.items,
        subtotal: state.subtotal,
        discount: state.discount,
        totalAmount: state.totalAmount,
        paymentMethod: state.paymentMethod,
        shopName: settings.shopName,
        shopAddress: settings.address,
        shopPhone: settings.phone,
      );

      final completedSale =
          await _ref.read(pharmacyDataNotifierProvider.notifier).recordSale(sale);

      state = CartState(
        items: [],
        lastCompletedSale: completedSale,
        isProcessing: false,
      );
      return completedSale;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Bill transaction failed. Please try again.',
      );
      return null;
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});
