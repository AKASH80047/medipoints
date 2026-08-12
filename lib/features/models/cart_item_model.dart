import 'medicine_model.dart';
import 'batch_model.dart';

class CartItem {
  final Medicine medicine;
  final Batch batch;
  final int quantity;
  final double unitPrice;

  const CartItem({
    required this.medicine,
    required this.batch,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;

  CartItem copyWith({
    Medicine? medicine,
    Batch? batch,
    int? quantity,
    double? unitPrice,
  }) {
    return CartItem(
      medicine: medicine ?? this.medicine,
      batch: batch ?? this.batch,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicine.id,
      'medicineName': medicine.name,
      'genericName': medicine.genericName,
      'batchId': batch.id,
      'batchNumber': batch.batchNumber,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, Medicine medicine, Batch batch) {
    return CartItem(
      medicine: medicine,
      batch: batch,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
