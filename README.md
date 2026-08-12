# MediPoint — Smart Pharmacy Management

**MediPoint** is a production-ready, human-friendly Flutter pharmacy management and billing application built specifically for small, single-owner medical shops.

Designed so that a shop owner with zero software background can operate it comfortably at a pharmacy counter without training.

---

## 🌟 Key Features

- **Billing POS Counter**: Fast customer billing with live cart, discount input, payment mode distribution (Cash, UPI, Card), and thermal/standard printable PDF receipts.
- **Camera Barcode Scanner**: Built-in barcode scanner via `mobile_scanner` with flashlight toggle, framing overlay, and automatic medicine/batch lookup.
- **Expiry & Safety Block**: Hard blocks sales of expired medicine batches (`⚠ Cannot Sell: This medicine batch has expired`).
- **Stock Management & Reorder List**: Track stock by batch with low stock alerts, reorder filters, and 3-step medicine setup.
- **Supplier Purchase Logger**: Record incoming stock purchases with supplier details, invoice reference, and automatic inventory updating.
- **Analytics & Reports**: Clear sales summaries, daily bill count, total stock value, and printable sales history.
- **Offline / Seed Fallback**: Out-of-the-box demo mode functioning seamlessly offline or with Firebase integration.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.12.0 or higher)
- Dart SDK

### Installation

```bash
# Clone repository
git clone https://github.com/AKASH80047/medipoints.git

# Navigate to project directory
cd medipoints

# Get dependencies
flutter pub get

# Run application
flutter run
```

---

## 📱 Tech Stack

- **Framework**: Flutter / Dart
- **State Management**: Flutter Riverpod
- **Routing**: GoRouter
- **Backend / Database**: Firebase Cloud Firestore & Auth (with local persistent fallback)
- **PDF & Printing**: `pdf` and `printing` packages
- **Barcode Scanning**: `mobile_scanner`
