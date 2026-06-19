# new-progect-2026
# 🛫 elmahdi_travel_suite
### وكالة سامح عبدالله للسفر والسياحة

## 🚀 Quick Start

### Prerequisites
- Flutter SDK >= 3.3.0
- Android Studio + Android SDK
- Cairo font files in `assets/fonts/`

### Setup

```bash
# 1. Get dependencies
flutter pub get

# 2. Generate Drift + Riverpod code
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run
flutter run
```

### Windows
```cmd
build.bat
```

### Linux / macOS
```bash
chmod +x build.sh && ./build.sh
```

## ⚙️ Configuration

Edit `lib/core/constants/app_constants.dart`:

```dart
static const supabaseUrl     = 'https://YOUR_PROJECT.supabase.co';
static const supabaseAnonKey = 'YOUR_ANON_KEY';
```

## 📂 Structure
```
lib/
├── core/           # Theme, Router, Constants
├── database/       # Drift DB, Tables, DAOs
├── features/       # Screens by feature
│   ├── dashboard/
│   ├── customers/
│   ├── bookings/
│   ├── payments/
│   ├── reports/
│   ├── ledger/
│   ├── expenses/
│   └── settings/
├── shared/         # Reusable Widgets
└── main.dart
```

## 🏗️ Tech Stack
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| Database | Drift (SQLite) |
| Cloud | Supabase |
| State | Riverpod |
| Navigation | GoRouter |
| PDF | pdf package |
| Charts | fl_chart |

## 📋 Phases
- ✅ Phase 1 — Foundation
- ✅ Phase 2 — Customers
- ✅ Phase 3 — Bookings
- ✅ Phase 4 — Payments
- ✅ Phase 5 — Dashboard + Reports
- ✅ Phase 6 — Supabase Sync
- ✅ Phase 7 — PDF Documents

---
Built with ❤️ for Sameh Abdullah Travel & Tourism Agency, Cairo 🇪🇬
