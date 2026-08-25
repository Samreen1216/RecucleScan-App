# ♻️ RecycleScan

> **Scan. Learn. Recycle.** — Scan everyday items and instantly learn how to dispose of them responsibly.

---

## 📱 App Screenshots Overview

| Screen | Description |
|--------|-------------|
| Splash | Animated logo with fade-in |
| Onboarding | 3 illustrated slides (first launch only) |
| Home | Greeting, scan button, categories, recent scans, eco tip |
| Scanner | Full-screen camera with animated scan overlay |
| Result | Product details, category badge, disposal guide |
| Guide | All 7 recycling categories with full info |
| History | Searchable, filterable scan log with swipe-to-delete |
| Settings | Preferences, stats, clear history, about |

---

## 🌿 Color Theme

| Role | Color |
|------|-------|
| Primary | Forest Green `#1B5E20` |
| Secondary | Mint Green `#A5D6A7` |
| Accent | Amber `#F57F17` |
| Background | Warm White `#F9FBF9` |

---

## 🛠 Tech Stack

| Technology | Purpose |
|-----------|---------|
| Flutter + Dart | Cross-platform mobile app |
| Riverpod | State management |
| GoRouter | Navigation |
| mobile_scanner | Barcode/QR scanning |
| Hive | Local storage for scan history |
| flutter_animate | Smooth UI animations |
| Lottie | Animated illustrations |
| google_fonts | Poppins typeface |
| SharedPreferences | Onboarding flag, settings |

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # Root widget + theme
├── core/
│   ├── constants/               # Colors, strings, recycling data
│   ├── models/                  # ScanItem (Hive), RecyclingCategory
│   ├── providers/               # Riverpod state providers
│   ├── router/                  # GoRouter config
│   └── services/                # Hive + barcode lookup
├── features/
│   ├── splash/                  # Splash screen
│   ├── onboarding/              # 3-slide onboarding
│   ├── home/                    # Home + widgets
│   ├── scanner/                 # Camera scanner + overlay
│   ├── result/                  # Scan result + widgets
│   ├── guide/                   # Guide + category detail
│   ├── history/                 # Scan history
│   └── settings/                # App settings
└── shared/
    └── widgets/                 # App shell (bottom nav)
```

---

## 🚀 Getting Started

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build debug APK
flutter build apk --debug
```

### Required Permissions
- **Camera** — for barcode scanning
- **Flashlight** — for torch toggle

---

## 🗃 Local Product Database

20 pre-loaded products with barcodes including:
- Coca-Cola, Heinz, Nutella, NIVEA, Barilla, Nescafé, and more
- Each mapped to: name, brand, category, emoji, and disposal notes

## 🌱 30 Rotating Eco Tips
- Tips rotate daily based on day-of-year index
- Cover: plastics, water, energy, food waste, composting, e-waste, etc.

## ♻️ 7 Recycling Categories
Each with: what goes in, what stays out, preparation tips, fun fact

1. 🔵 Plastic (PET, HDPE, etc.)
2. 🟤 Paper (cardboard, newspapers)
3. 🩵 Glass (bottles, jars)
4. ⚫ Metal (aluminium, steel)
5. 🟫 General Waste
6. 🟣 E-Waste (electronics, batteries)
7. 🟢 Organic (food scraps, garden)
