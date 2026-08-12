import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine_model.dart';
import '../models/batch_model.dart';
import '../models/sale_model.dart';
import '../models/purchase_model.dart';
import '../models/shop_settings_model.dart';

class PharmacyRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  // Local Seed State Fallback (Offline / Demo Mode)
  final List<Medicine> _localMedicines = [];
  final List<Batch> _localBatches = [];
  final List<Sale> _localSales = [];
  final List<Purchase> _localPurchases = [];
  ShopSettings _localSettings = ShopSettings.defaultSettings();

  bool _isUsingLocal = true;

  PharmacyRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth {
    _initSeedData();
  }

  void _initSeedData() {
    final now = DateTime.now();

    // Seed Medicines
    _localMedicines.addAll([
      Medicine(
        id: 'med_1',
        name: 'Paracetamol 500mg',
        genericName: 'Acetaminophen',
        brand: 'Dolo 650 / Calpol',
        category: 'Tablet',
        barcode: '8901234567890',
        minStockAlert: 15,
      ),
      Medicine(
        id: 'med_2',
        name: 'Amoxicillin 500mg',
        genericName: 'Amoxicillin Trihydrate',
        brand: 'Mox 500',
        category: 'Capsule',
        barcode: '8901234567891',
        minStockAlert: 20,
      ),
      Medicine(
        id: 'med_3',
        name: 'Benadryl Cough Syrup 100ml',
        genericName: 'Diphenhydramine HCI',
        brand: 'Benadryl',
        category: 'Syrup',
        barcode: '8901234567892',
        minStockAlert: 10,
      ),
      Medicine(
        id: 'med_4',
        name: 'Pantoprazole 40mg',
        genericName: 'Pantoprazole Sodium',
        brand: 'Pan 40',
        category: 'Tablet',
        barcode: '8901234567893',
        minStockAlert: 25,
      ),
      Medicine(
        id: 'med_5',
        name: 'Cetirizine 10mg',
        genericName: 'Cetirizine Hydrochloride',
        brand: 'Cetzine',
        category: 'Tablet',
        barcode: '8901234567894',
        minStockAlert: 30,
      ),
      Medicine(
        id: 'med_6',
        name: 'Azithromycin 500mg',
        genericName: 'Azithromycin Dihydrate',
        brand: 'Azee 500',
        category: 'Tablet',
        barcode: '8901234567895',
        minStockAlert: 15,
      ),
      Medicine(
        id: 'med_7',
        name: 'Volini Pain Relief Gel 50g',
        genericName: 'Diclofenac Diethylamine',
        brand: 'Volini',
        category: 'Ointment',
        barcode: '8901234567896',
        minStockAlert: 8,
      ),
      Medicine(
        id: 'med_8',
        name: 'Insulin Glargine 100IU/ml',
        genericName: 'Insulin Glargine',
        brand: 'Lantus',
        category: 'Injection',
        barcode: '8901234567897',
        minStockAlert: 5,
      ),
    ]);

    // Seed Batches (Active, Expiring Soon, Expired, Low Stock)
    _localBatches.addAll([
      Batch(
        id: 'batch_101',
        medicineId: 'med_1',
        batchNumber: 'PCM-2025A',
        quantity: 40,
        purchasePrice: 18.0,
        sellingPrice: 25.0,
        mrp: 30.0,
        expiryDate: now.add(const Duration(days: 365)),
      ),
      Batch(
        id: 'batch_102',
        medicineId: 'med_1',
        batchNumber: 'PCM-2024B',
        quantity: 5,
        purchasePrice: 16.0,
        sellingPrice: 22.0,
        mrp: 28.0,
        expiryDate: now.add(const Duration(days: 25)),
      ),
      Batch(
        id: 'batch_201',
        medicineId: 'med_2',
        batchNumber: 'AMX-9988X',
        quantity: 12,
        purchasePrice: 40.0,
        sellingPrice: 60.0,
        mrp: 75.0,
        expiryDate: now.subtract(const Duration(days: 15)),
      ),
      Batch(
        id: 'batch_202',
        medicineId: 'med_2',
        batchNumber: 'AMX-2026A',
        quantity: 45,
        purchasePrice: 42.0,
        sellingPrice: 65.0,
        mrp: 80.0,
        expiryDate: now.add(const Duration(days: 400)),
      ),
      Batch(
        id: 'batch_301',
        medicineId: 'med_3',
        batchNumber: 'BND-7711',
        quantity: 4,
        purchasePrice: 85.0,
        sellingPrice: 115.0,
        mrp: 135.0,
        expiryDate: now.add(const Duration(days: 180)),
      ),
      Batch(
        id: 'batch_401',
        medicineId: 'med_4',
        batchNumber: 'PAN-3321',
        quantity: 35,
        purchasePrice: 35.0,
        sellingPrice: 50.0,
        mrp: 62.0,
        expiryDate: now.add(const Duration(days: 45)),
      ),
      Batch(
        id: 'batch_501',
        medicineId: 'med_5',
        batchNumber: 'CTZ-5544',
        quantity: 120,
        purchasePrice: 10.0,
        sellingPrice: 18.0,
        mrp: 22.0,
        expiryDate: now.add(const Duration(days: 500)),
      ),
      Batch(
        id: 'batch_601',
        medicineId: 'med_6',
        batchNumber: 'AZI-1122',
        quantity: 15,
        purchasePrice: 70.0,
        sellingPrice: 110.0,
        mrp: 130.0,
        expiryDate: now.subtract(const Duration(days: 40)),
      ),
    ]);

    // Seed Initial Sales
    _localSales.addAll([
      Sale(
        id: 'sale_1',
        invoiceNumber: 'MP-1001',
        dateTime: now.subtract(const Duration(hours: 2)),
        items: [],
        subtotal: 450.0,
        discount: 0.0,
        totalAmount: 450.0,
        paymentMethod: PaymentMethod.upi,
        shopName: _localSettings.shopName,
        shopAddress: _localSettings.address,
        shopPhone: _localSettings.phone,
      ),
      Sale(
        id: 'sale_2',
        invoiceNumber: 'MP-1002',
        dateTime: now.subtract(const Duration(hours: 4)),
        items: [],
        subtotal: 1200.0,
        discount: 50.0,
        totalAmount: 1150.0,
        paymentMethod: PaymentMethod.cash,
        shopName: _localSettings.shopName,
        shopAddress: _localSettings.address,
        shopPhone: _localSettings.phone,
      ),
      Sale(
        id: 'sale_3',
        invoiceNumber: 'MP-1003',
        dateTime: now.subtract(const Duration(hours: 6)),
        items: [],
        subtotal: 280.0,
        discount: 0.0,
        totalAmount: 280.0,
        paymentMethod: PaymentMethod.card,
        shopName: _localSettings.shopName,
        shopAddress: _localSettings.address,
        shopPhone: _localSettings.phone,
      ),
    ]);
  }

  void resetToSeedData() {
    _localMedicines.clear();
    _localBatches.clear();
    _localSales.clear();
    _localPurchases.clear();
    _initSeedData();
  }

  User? get currentUser => _auth?.currentUser;

  Future<void> loginOwner(String email, String password) async {
    final auth = _auth;
    if (auth != null) {
      try {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        _isUsingLocal = false;
        return;
      } catch (_) {}
    }
    _isUsingLocal = true;
  }

  Future<void> logoutOwner() async {
    final auth = _auth;
    if (auth != null) {
      await auth.signOut();
    }
  }

  Future<List<Medicine>> getMedicines() async {
    final firestore = _firestore;
    if (!_isUsingLocal && firestore != null) {
      try {
        final snap = await firestore.collection('medicines').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => Medicine.fromMap(doc.data(), doc.id))
              .toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_localMedicines);
  }

  Future<List<Batch>> getBatches() async {
    final firestore = _firestore;
    if (!_isUsingLocal && firestore != null) {
      try {
        final snap = await firestore.collection('batches').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((doc) => Batch.fromMap(doc.data(), doc.id)).toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_localBatches);
  }

  Future<Medicine> addMedicine(Medicine medicine, Batch initialBatch) async {
    final medId = medicine.id.isEmpty
        ? 'med_${DateTime.now().millisecondsSinceEpoch}'
        : medicine.id;
    final newMed = medicine.copyWith(id: medId);

    final batchId = initialBatch.id.isEmpty
        ? 'batch_${DateTime.now().millisecondsSinceEpoch}'
        : initialBatch.id;
    final newBatch = initialBatch.copyWith(id: batchId, medicineId: medId);

    _localMedicines.add(newMed);
    _localBatches.add(newBatch);

    final firestore = _firestore;
    if (!_isUsingLocal && firestore != null) {
      try {
        await firestore.collection('medicines').doc(medId).set(newMed.toMap());
        await firestore.collection('batches').doc(batchId).set(newBatch.toMap());
      } catch (_) {}
    }

    return newMed;
  }

  Future<Sale> createSale(Sale sale) async {
    final saleId = sale.id.isEmpty
        ? 'sale_${DateTime.now().millisecondsSinceEpoch}'
        : sale.id;

    final newSale = Sale(
      id: saleId,
      invoiceNumber: sale.invoiceNumber,
      dateTime: sale.dateTime,
      items: sale.items,
      subtotal: sale.subtotal,
      discount: sale.discount,
      totalAmount: sale.totalAmount,
      paymentMethod: sale.paymentMethod,
      shopName: sale.shopName,
      shopAddress: sale.shopAddress,
      shopPhone: sale.shopPhone,
    );

    for (final cartItem in sale.items) {
      final index = _localBatches.indexWhere((b) => b.id == cartItem.batch.id);
      if (index != -1) {
        final currentQty = _localBatches[index].quantity;
        final updatedQty = (currentQty - cartItem.quantity).clamp(0, 999999);
        _localBatches[index] = _localBatches[index].copyWith(quantity: updatedQty);
      }
    }

    _localSales.insert(0, newSale);

    final firestore = _firestore;
    if (!_isUsingLocal && firestore != null) {
      try {
        final batchRef = firestore.batch();
        batchRef.set(firestore.collection('sales').doc(saleId), newSale.toMap());
        for (final cartItem in sale.items) {
          final bDoc = firestore.collection('batches').doc(cartItem.batch.id);
          batchRef.update(bDoc, {'quantity': FieldValue.increment(-cartItem.quantity)});
        }
        await batchRef.commit();
      } catch (_) {}
    }

    return newSale;
  }

  Future<List<Sale>> getSales() async {
    final firestore = _firestore;
    if (!_isUsingLocal && firestore != null) {
      try {
        final snap = await firestore
            .collection('sales')
            .orderBy('dateTime', descending: true)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => Sale.fromMap(doc.data(), doc.id, []))
              .toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_localSales);
  }

  Future<Purchase> recordPurchase(Purchase purchase) async {
    final pId = purchase.id.isEmpty
        ? 'pur_${DateTime.now().millisecondsSinceEpoch}'
        : purchase.id;

    final newPurchase = Purchase(
      id: pId,
      supplierName: purchase.supplierName,
      supplierPhone: purchase.supplierPhone,
      invoiceNumber: purchase.invoiceNumber,
      purchaseDate: purchase.purchaseDate,
      items: purchase.items,
      totalAmount: purchase.totalAmount,
    );

    for (final item in purchase.items) {
      final existingIndex = _localBatches.indexWhere((b) =>
          b.medicineId == item.medicineId && b.batchNumber == item.batchNumber);

      if (existingIndex != -1) {
        final cur = _localBatches[existingIndex];
        _localBatches[existingIndex] = cur.copyWith(
          quantity: cur.quantity + item.quantity,
          purchasePrice: item.purchasePrice,
          sellingPrice: item.sellingPrice,
          mrp: item.mrp,
          expiryDate: item.expiryDate,
        );
      } else {
        final newBatchId = 'batch_${DateTime.now().millisecondsSinceEpoch}_${item.batchNumber}';
        _localBatches.add(Batch(
          id: newBatchId,
          medicineId: item.medicineId,
          batchNumber: item.batchNumber,
          quantity: item.quantity,
          purchasePrice: item.purchasePrice,
          sellingPrice: item.sellingPrice,
          mrp: item.mrp,
          expiryDate: item.expiryDate,
        ));
      }
    }

    _localPurchases.insert(0, newPurchase);

    final firestore = _firestore;
    if (!_isUsingLocal && firestore != null) {
      try {
        await firestore.collection('purchases').doc(pId).set(newPurchase.toMap());
      } catch (_) {}
    }

    return newPurchase;
  }

  Future<List<Purchase>> getPurchases() async {
    final firestore = _firestore;
    if (!_isUsingLocal && firestore != null) {
      try {
        final snap = await firestore
            .collection('purchases')
            .orderBy('purchaseDate', descending: true)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((doc) => Purchase.fromMap(doc.data(), doc.id)).toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_localPurchases);
  }

  Future<ShopSettings> getSettings() async {
    final firestore = _firestore;
    if (!_isUsingLocal && firestore != null) {
      try {
        final doc = await firestore.collection('settings').doc('shop').get();
        if (doc.exists && doc.data() != null) {
          return ShopSettings.fromMap(doc.data()!);
        }
      } catch (_) {}
    }
    return _localSettings;
  }

  Future<void> saveSettings(ShopSettings settings) async {
    _localSettings = settings;
    final firestore = _firestore;
    if (!_isUsingLocal && firestore != null) {
      try {
        await firestore.collection('settings').doc('shop').set(settings.toMap());
      } catch (_) {}
    }
  }
}
