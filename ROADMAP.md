# VaultOTP - Project Roadmap

> Google Authenticator, but with folders.

## Overview

A cross-platform TOTP authenticator app with folder organization. Mobile-first, built with Flutter.

---

## Tech Stack

| Component | Choice | Why |
|-----------|--------|-----|
| Framework | Flutter | Cross-platform (iOS, Android, macOS, Windows, Linux) |
| Language | Dart | Comes with Flutter, similar to JS/TS |
| TOTP Generation | `otp` package | Battle-tested RFC 6238 implementation |
| Secure Storage | `flutter_secure_storage` | Uses Keychain (iOS/macOS), Keystore (Android) |
| QR Scanning | `mobile_scanner` | Modern, well-maintained camera/QR library |
| State Management | `riverpod` | Clean, testable, good for this scale |
| Local Database | `isar` | Fast, type-safe, works offline |

---

## Data Models

### Folder
```dart
class Folder {
  String id;          // UUID
  String name;        // "Work", "Personal", etc.
  int sortOrder;      // For custom ordering
  DateTime createdAt;
}
```

### Account
```dart
class Account {
  String id;          // UUID
  String name;        // "GitHub", "AWS", etc.
  String issuer;      // Optional issuer from QR
  String secret;      // TOTP secret (stored encrypted)
  String? folderId;   // null = unfiled
  int digits;         // Usually 6, sometimes 8
  int period;         // Usually 30 seconds
  Algorithm algorithm; // SHA1 (default), SHA256, SHA512
  DateTime createdAt;
}
```

---

## App Architecture

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # MaterialApp setup
│
├── models/                   # Data classes
│   ├── account.dart
│   └── folder.dart
│
├── services/                 # Business logic
│   ├── totp_service.dart     # Generate TOTP codes
│   ├── storage_service.dart  # Secure storage wrapper
│   └── database_service.dart # Isar database operations
│
├── providers/                # Riverpod state management
│   ├── accounts_provider.dart
│   ├── folders_provider.dart
│   └── totp_provider.dart
│
├── screens/                  # Full-page views
│   ├── home_screen.dart      # Main screen with folders + codes
│   ├── add_account_screen.dart
│   ├── scan_qr_screen.dart
│   ├── folder_manage_screen.dart
│   └── settings_screen.dart
│
├── widgets/                  # Reusable components
│   ├── account_tile.dart     # Shows account name + live code
│   ├── folder_tab.dart
│   ├── countdown_indicator.dart
│   └── code_display.dart
│
└── utils/                    # Helpers
    ├── otp_uri_parser.dart   # Parse otpauth:// URLs
    └── constants.dart
```

---

## Screens & User Flows

### 1. Home Screen (Main View)
```
┌─────────────────────────────────────┐
│  VaultOTP                      [+]  │  <- Add button
├─────────────────────────────────────┤
│  [All] [Work] [Personal] [Edit]     │  <- Folder tabs
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │ GitHub            ●●●●●●   │    │  <- Countdown dot
│  │ 482 193              [12s] │    │  <- Code + time left
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ AWS                         │    │
│  │ 847 291              [24s] │    │
│  └─────────────────────────────┘    │
│  ...                                │
└─────────────────────────────────────┘
```

### 2. Add Account Flow
- Tap [+] button
- Choose: "Scan QR Code" or "Enter Manually"
- **QR Scan**: Opens camera, parses `otpauth://totp/...` URI
- **Manual**: Form for name, secret, optional settings
- Select folder (or leave unfiled)
- Save

### 3. Folder Management
- Tap [Edit] on folder tabs
- Add new folder
- Rename existing folders
- Delete folder (accounts become unfiled)
- Reorder folders (drag & drop)

### 4. Settings Screen
- App lock (biometric/PIN) - Phase 2
- Export/Import (encrypted backup) - Phase 2
- Theme (light/dark/system)
- About

---

## Implementation Phases

### Phase 1: Core MVP (Current Focus)
1. **Project setup** - Flutter project, dependencies, folder structure
2. **Data layer** - Models, Isar database, secure storage
3. **TOTP engine** - Generate codes, parse otpauth:// URIs
4. **Basic UI** - Home screen, account list with live codes
5. **Folder system** - Create folders, assign accounts
6. **QR scanner** - Add accounts via camera

### Phase 2: Polish
- Biometric/PIN app lock
- Search accounts
- Copy code on tap (with haptic feedback)
- Account editing
- Folder reordering

### Phase 3: Advanced
- Encrypted cloud backup (optional)
- Desktop builds (macOS, Windows)
- Widgets (iOS/Android home screen)

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.4.9

  # Database
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  path_provider: ^2.1.1

  # Secure storage (for encryption key)
  flutter_secure_storage: ^9.0.0

  # TOTP generation
  otp: ^3.1.4
  base32: ^2.1.3

  # QR code scanning
  mobile_scanner: ^3.5.5

  # Utilities
  uuid: ^4.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.7
```

---

## Security Model

1. **TOTP Secrets**: Stored in Isar database, encrypted with a key
2. **Encryption Key**: Stored in platform secure storage (Keychain/Keystore)
3. **No network calls**: 100% offline, no analytics, no telemetry
4. **Optional app lock**: Biometric/PIN before showing codes

```
┌─────────────────────────────────────────────┐
│                  App Layer                  │
├─────────────────────────────────────────────┤
│  Isar Database (encrypted account data)     │
├─────────────────────────────────────────────┤
│  Encryption Key (in Keychain/Keystore)      │
├─────────────────────────────────────────────┤
│  Platform Secure Storage                    │
└─────────────────────────────────────────────┘
```

---

## QR Code Format (otpauth://)

Standard URI format we need to parse:
```
otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&digits=6&period=30&algorithm=SHA1
```

Parsed into:
- **Type**: totp
- **Label**: GitHub:user@example.com
- **Secret**: JBSWY3DPEHPK3PXP (base32)
- **Issuer**: GitHub
- **Digits**: 6 (default)
- **Period**: 30 (default)
- **Algorithm**: SHA1 (default)

---

## Getting Started Commands

```bash
# Create project
flutter create --org com.vaultotp vault_otp
cd vault_otp

# Add dependencies
flutter pub add flutter_riverpod isar isar_flutter_libs path_provider flutter_secure_storage otp base32 mobile_scanner uuid

# Add dev dependencies
flutter pub add --dev isar_generator build_runner

# Generate Isar schemas (after creating models)
dart run build_runner build

# Run on iOS simulator
flutter run
```

---

## Definition of Done (MVP)

- [ ] Can add account via QR scan
- [ ] Can add account manually
- [ ] Shows live TOTP codes with countdown
- [ ] Can create folders
- [ ] Can assign accounts to folders
- [ ] Can filter view by folder
- [ ] Codes copy to clipboard on tap
- [ ] Secrets stored securely
- [ ] Works on iOS
- [ ] Works on Android

---

Let's build this thing.
