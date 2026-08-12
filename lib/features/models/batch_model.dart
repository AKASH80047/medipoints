import 'package:cloud_firestore/cloud_firestore.dart';

class Batch {
  final String id;
  final String medicineId;
  final String batchNumber;
  final int quantity;
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final DateTime expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Batch({
    required this.id,
    required this.medicineId,
    required this.batchNumber,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.mrp,
    required this.expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isExpired {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.isBefore(today);
  }

  bool isExpiringWithin(int days) {
    if (isExpired) return false;
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference >= 0 && difference <= days;
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'mrp': mrp,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field) ?? DateTime.now();
      return DateTime.now();
    }

    return Batch(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      medicineId: map['medicineId'] ?? '',
      batchNumber: map['batchNumber'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      expiryDate: parseDate(map['expiryDate']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Batch copyWith({
    String? id,
    String? medicineId,
    String? batchNumber,
    int? quantity,
    double? purchasePrice,
    double? sellingPrice,
    double? mrp,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Batch(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      batchNumber: batchNumber ?? this.batchNumber,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
