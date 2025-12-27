# VaultOTP

A privacy-first 2FA authenticator app with folder organization. Like Google Authenticator, but with folders.

## Features

- **Folder Organization** - Sort your 2FA codes into Work, Personal, Finance, or custom folders
- **100% Private** - No accounts, no cloud sync, no tracking. All data stays on your device
- **Easy Migration** - Import all your codes from Google Authenticator with one QR scan
- **Export** - Export your accounts as QR codes for backup or migration
- **Secure** - Uses platform-native secure storage (iOS Keychain / Android Keystore)

## Freemium Model

| Free | Premium ($1.99) |
|------|-----------------|
| Add/view/copy 2FA codes | Everything in Free + |
| Import from Google Auth | Create folders |
| Export accounts | Organize into folders |
| | Move accounts between folders |

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Android Studio / Xcode
- RevenueCat account (for in-app purchases)

### Installation

```bash
# Clone the repository
git clone https://github.com/jasonsutter87/valutOTP.git
cd vault_otp_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build iOS

```bash
flutter build ios --release
```

## RevenueCat Setup (In-App Purchases)

To enable the premium folder feature, you need to set up RevenueCat:

### 1. Create RevenueCat Account

Go to [revenuecat.com](https://www.revenuecat.com) and create a free account.

### 2. Add Your Apps

- Add your Android app (package name: `com.example.vault_otp`)
- Add your iOS app (bundle ID from Xcode)

### 3. Create Product

In RevenueCat dashboard:
1. Go to **Products** → **Entitlements**
2. Create entitlement: `premium`
3. Go to **Products** → **Products**
4. Create product: `vaultotp_premium` (non-consumable, $1.99)
5. Attach the product to the `premium` entitlement

### 4. Get API Keys

1. Go to **Project Settings** → **API Keys**
2. Copy your public API keys for Android and iOS

### 5. Update the App

Edit `lib/services/purchase_service.dart`:

```dart
static const String _androidApiKey = 'goog_YourAndroidKeyHere';
static const String _iosApiKey = 'appl_YourIOSKeyHere';
```

### 6. Configure App Stores

**Google Play Console:**
1. Create an in-app product with ID `vaultotp_premium`
2. Set as "One-time" (non-consumable)
3. Price: $1.99
4. Add RevenueCat service account credentials

**App Store Connect:**
1. Create an in-app purchase with ID `vaultotp_premium`
2. Set as "Non-Consumable"
3. Price: $1.99
4. Add RevenueCat shared secret

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration & theme
├── models/
│   ├── account.dart          # 2FA account model
│   └── folder.dart           # Folder model
├── providers/
│   ├── accounts_provider.dart    # Account state management
│   ├── folders_provider.dart     # Folder state management
│   ├── premium_provider.dart     # Premium status management
│   └── selected_folder_provider.dart
├── screens/
│   ├── home_screen.dart          # Main screen with accounts list
│   ├── add_account_screen.dart   # Add account manually
│   ├── scan_qr_screen.dart       # QR code scanner
│   ├── folder_management_screen.dart
│   └── export_screen.dart        # Export accounts as QR
├── services/
│   ├── storage_service.dart      # Secure storage
│   ├── totp_service.dart         # TOTP code generation
│   └── purchase_service.dart     # RevenueCat integration
├── utils/
│   ├── google_auth_migration.dart # Google Auth import parser
│   ├── export_migration.dart      # Export QR generator
│   └── otp_uri_parser.dart        # otpauth:// URI parser
└── widgets/
    ├── account_tile.dart
    ├── folder_chip.dart
    ├── upgrade_modal.dart        # Premium upgrade UI
    └── ...
```

## Landing Site

The `/site` folder contains a Hugo static site for the app landing page.

```bash
cd site

# Development
hugo server -D

# Build for production
hugo
```

Deploy the `site/public/` folder to your hosting.

## Tech Stack

- **Flutter** - Cross-platform UI framework
- **Riverpod** - State management
- **flutter_secure_storage** - Encrypted local storage
- **otp** - TOTP code generation (RFC 6238)
- **mobile_scanner** - QR code scanning
- **qr_flutter** - QR code generation
- **purchases_flutter** - RevenueCat SDK for IAP

## Privacy

VaultOTP is designed with privacy as a core feature:

- No user accounts required
- No data leaves your device
- No analytics or tracking
- No cloud sync
- All secrets encrypted with platform security

## License

MIT

## Support

- Website: [vaultotp.app](https://vaultotp.app)
- Email: support@vaultotp.app
