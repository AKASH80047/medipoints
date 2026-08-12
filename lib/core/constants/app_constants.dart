class AppConstants {
  static const String appName = 'MediPoint';
  static const String appTagline = 'Smart Pharmacy Management';
  static const String currencySymbol = '₹';
  
  // Storage & Firestore collection names
  static const String collectionUsers = 'users';
  static const String collectionMedicines = 'medicines';
  static const String collectionBatches = 'batches';
  static const String collectionSales = 'sales';
  static const String collectionPurchases = 'purchases';
  static const String collectionSuppliers = 'suppliers';
  static const String collectionSettings = 'settings';

  // Default Shop Details
  static const String defaultShopName = 'HealthCare Pharmacy';
  static const String defaultOwnerName = 'Rajesh Kumar';
  static const String defaultPhone = '+91 98765 43210';
  static const String defaultAddress = 'Shop No. 12, Main Market, MG Road, New Delhi';
  static const String defaultGstin = '07AAAAA0000A1Z5';

  // Categories
  static const List<String> medicineCategories = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Ointment',
    'Drops',
    'Inhaler',
    'Powder',
    'Equipment',
    'Other',
  ];

  // Units
  static const List<String> medicineUnits = [
    'Tablet',
    'Capsule',
    'Strip',
    'Bottle',
    'Box',
    'Vial',
    'Tube',
    'Pack',
  ];
}
