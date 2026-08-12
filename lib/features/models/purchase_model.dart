import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseItem {
  final String medicineId;
  final String medicineName;
  final String batchNumber;
  final int quantity;
  final double purchasePrice;
  final double mrp;
  final double sellingPrice;
  final DateTime expiryDate;

  const PurchaseItem({
    required this.medicineId,
    required this.medicineName,
    required this.batchNumber,
    required this.quantity,
    required this.purchasePrice,
    required this.mrp,
    required this.sellingPrice,
    required this.expiryDate,
  });

  double get totalAmount => quantity * purchasePrice;

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'mrp': mrp,
      'sellingPrice': sellingPrice,
      'expiryDate': Timestamp.fromDate(expiryDate),
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    DateTime date;
    final rawDate = map['expiryDate'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return PurchaseItem(
      medicineId: map['medicineId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      batchNumber: map['batchNumber'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      expiryDate: date,
    );
  }
}

class Purchase {
  final String id;
  final String supplierName;
  final String supplierPhone;
  final String invoiceNumber;
  final DateTime purchaseDate;
  final List<PurchaseItem> items;
  final double totalAmount;

  const Purchase({
    required this.id,
    required this.supplierName,
    required this.supplierPhone,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.items,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierName': supplierName,
      'supplierPhone': supplierPhone,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map, String docId) {
    DateTime date;
    final rawDate = map['purchaseDate'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => PurchaseItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return Purchase(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      supplierName: map['supplierName'] ?? '',
      supplierPhone: map['supplierPhone'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      purchaseDate: date,
      items: items,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
