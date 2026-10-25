# Receipt Scanner — OCR Expense Tracker

A Flutter mobile app using **Google ML Kit Text Recognition** for on-device receipt scanning — no cloud cost, works fully offline.

## ✨ Features

| Feature | Detail |
|---------|--------|
| 📸 Camera Capture | Live viewfinder, flash toggle, framing overlay with corner guides |
| 🤖 On-device OCR | `google_mlkit_text_recognition` — offline, zero cloud cost |
| 🧠 Regex Parser | Extracts VND/USD totals, dates (DD/MM/YYYY), merchant names |
| ✏️ Review Screen | Edit OCR results; view raw extracted text |
| 🗄️ SQLite Storage | Full CRUD via `sqflite` |
| 📂 Categories | Food, Study, Travel, Gear, Entertainment, Other |
| 📊 Donut Chart | Animated category distribution (pure `CustomPainter`) |
| 📉 Bar Chart | Animated 7-day spending trend (pure `CustomPainter`) |
| 🌙 Dark/Light | Runtime theme toggle |
| 🗑️ Swipe-to-delete | `Dismissible` gesture |

## 🛠️ Tech Stack

- **Flutter 3.x / Dart 3**
- `google_mlkit_text_recognition` ^0.13.0
- `camera` ^0.10.5+9
- `sqflite` ^2.3.3+1
- `CustomPainter` (charts — no 3rd-party library)

## 📁 Structure

```
lib/
├── main.dart
├── core/
│   ├── database/database_helper.dart
│   ├── models/transaction_model.dart
│   ├── services/
│   │   ├── ocr_service.dart
│   │   └── receipt_parser.dart
│   └── theme/app_theme.dart
└── features/
    ├── home/home_screen.dart
    ├── camera/camera_screen.dart
    ├── transactions/
    │   ├── review_screen.dart
    │   ├── add_transaction_screen.dart
    │   └── transaction_detail_screen.dart
    └── analytics/
        ├── analytics_screen.dart
        └── painters/
            ├── donut_chart_painter.dart
            └── bar_chart_painter.dart
```

## 🚀 Setup & Build

### Prerequisites
- Flutter SDK 3.x — [install](https://docs.flutter.dev/get-started/install)
- Android SDK (API 21+) or Xcode 14+
- Physical device or emulator with camera

### Run

```bash
git clone <your-repo-url>
cd receipt_scanner
flutter pub get
flutter run
```

### Build Release APK

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (Play Store)

```bash
flutter build appbundle --release
```

## 🧠 Regex Parser Details

`lib/core/services/receipt_parser.dart` handles:

```
VND:  TỔNG: 150.000đ  |  150,000 VND  |  Tổng cộng: 85,000
USD:  Total: $12.50   |  Amount Due: 12.50
Date: 24/10/2026  |  2026-10-24  |  24 Oct 2026
```

Amount normalization:
- `1.234,56` → European decimal → `1234.56`
- `1,234.56` → US → `1234.56`
- `150.000`  → VN thousands → `150000`

## 📊 Chart Implementation

Both charts animate 0→100% via `AnimationController(duration: 1200ms)`:

- **DonutChartPainter** — arc sweep, gap between segments, center count label
- **BarChartPainter** — gradient bars grow upward, Y-grid, K/M value labels

## 📦 Submission Checklist

- [ ] APK: `flutter build apk --release` → GitHub Releases
- [ ] Demo video (2–3 min): OCR scan flow, review, analytics charts
- [ ] GitHub public repo with this README
- [ ] PDF report (2–4 pages)

## 📄 Architecture Diagram

```
Camera → OcrService (ML Kit) → ReceiptParser (Regex)
                                        ↓
                               ReviewScreen (edit)
                                        ↓
                               DatabaseHelper (SQLite)
                                   ↙       ↘
                           HomeScreen    AnalyticsScreen
                          (list/CRUD)   (Donut + Bar charts)
```
