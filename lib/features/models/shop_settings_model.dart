import '../../core/constants/app_constants.dart';

class ShopSettings {
  final String shopName;
  final String ownerName;
  final String phone;
  final String address;
  final String gstin;
  final bool lowStockAlerts;
  final bool expiryAlerts;
  final String currency;

  const ShopSettings({
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.gstin,
    this.lowStockAlerts = true,
    this.expiryAlerts = true,
    this.currency = AppConstants.currencySymbol,
  });

  factory ShopSettings.defaultSettings() {
    return const ShopSettings(
      shopName: AppConstants.defaultShopName,
      ownerName: AppConstants.defaultOwnerName,
      phone: AppConstants.defaultPhone,
      address: AppConstants.defaultAddress,
      gstin: AppConstants.defaultGstin,
      lowStockAlerts: true,
      expiryAlerts: true,
      currency: AppConstants.currencySymbol,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'gstin': gstin,
      'lowStockAlerts': lowStockAlerts,
      'expiryAlerts': expiryAlerts,
      'currency': currency,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      shopName: map['shopName'] ?? AppConstants.defaultShopName,
      ownerName: map['ownerName'] ?? AppConstants.defaultOwnerName,
      phone: map['phone'] ?? AppConstants.defaultPhone,
      address: map['address'] ?? AppConstants.defaultAddress,
      gstin: map['gstin'] ?? AppConstants.defaultGstin,
      lowStockAlerts: map['lowStockAlerts'] ?? true,
      expiryAlerts: map['expiryAlerts'] ?? true,
      currency: map['currency'] ?? AppConstants.currencySymbol,
    );
  }

  ShopSettings copyWith({
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? gstin,
    bool? lowStockAlerts,
    bool? expiryAlerts,
    String? currency,
  }) {
    return ShopSettings(
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      expiryAlerts: expiryAlerts ?? this.expiryAlerts,
      currency: currency ?? this.currency,
    );
  }
}
