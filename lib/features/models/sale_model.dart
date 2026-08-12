import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

enum PaymentMethod { cash, upi, card }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.upi:
        return '📱';
      case PaymentMethod.card:
        return '💳';
    }
  }
}

class Sale {
  final String id;
  final String invoiceNumber;
  final DateTime dateTime;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final String shopName;
  final String shopAddress;
  final String shopPhone;

  const Sale({
    required this.id,
    required this.invoiceNumber,
    required this.dateTime,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.shopName,
    required this.shopAddress,
    required this.shopPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'dateTime': Timestamp.fromDate(dateTime),
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.name,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'shopPhone': shopPhone,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, String docId, List<CartItem> parsedItems) {
    DateTime date;
    final rawDate = map['dateTime'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    PaymentMethod pm;
    final methodStr = (map['paymentMethod'] ?? 'cash').toString().toLowerCase();
    if (methodStr.contains('upi')) {
      pm = PaymentMethod.upi;
    } else if (methodStr.contains('card')) {
      pm = PaymentMethod.card;
    } else {
      pm = PaymentMethod.cash;
    }

    return Sale(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      invoiceNumber: map['invoiceNumber'] ?? '',
      dateTime: date,
      items: parsedItems,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: pm,
      shopName: map['shopName'] ?? '',
      shopAddress: map['shopAddress'] ?? '',
      shopPhone: map['shopPhone'] ?? '',
    );
  }
}
