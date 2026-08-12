import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String name;
  final String genericName;
  final String brand;
  final String category;
  final String manufacturer;
  final String unit;
  final String barcode;
  final int minStockAlert;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.brand,
    required this.category,
    this.manufacturer = 'Standard Pharma',
    this.unit = 'Tablet',
    required this.barcode,
    required this.minStockAlert,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'genericName': genericName,
      'brand': brand,
      'category': category,
      'manufacturer': manufacturer,
      'unit': unit,
      'barcode': barcode,
      'minStockAlert': minStockAlert,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field) ?? DateTime.now();
      return DateTime.now();
    }

    return Medicine(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? '',
      genericName: map['genericName'] ?? '',
      brand: map['brand'] ?? '',
      category: map['category'] ?? 'Tablet',
      manufacturer: map['manufacturer'] ?? 'Standard Pharma',
      unit: map['unit'] ?? 'Tablet',
      barcode: map['barcode'] ?? '',
      minStockAlert: (map['minStockAlert'] as num?)?.toInt() ?? 10,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? genericName,
    String? brand,
    String? category,
    String? manufacturer,
    String? unit,
    String? barcode,
    int? minStockAlert,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
