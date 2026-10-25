# 📷 OCR Expense Tracker & Receipt Parser (Flutter & Dart)
> **Mini-Project 3: Personal Finance Management with On-Device AI**

[![Flutter](https://img.shields.io/badge/Flutter-3.47.8-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.7-0175C2?logo=dart)](https://dart.dev)
[![ML Kit](https://img.shields.io/badge/Google%20ML%20Kit-Offline%20OCR-4285F4?logo=google)](https://developers.google.com/ml-kit)
[![SQLite](https://img.shields.io/badge/SQLite-sqflite-003B57?logo=sqlite)](https://pub.dev/packages/sqflite)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)]()

---

## 🎯 Project Overview & Problem Scenario
Students, club treasurers, and individuals frequently accumulate physical supermarket bills and receipts. Manually transcribing expenses into spreadsheets is tedious and prone to human error.

**Receipt Scanner** provides an offline, privacy-first mobile solution developed in **Flutter 3.x**. Using **Google ML Kit Text Recognition**, receipt text is extracted locally in sub-100ms with zero cloud cost. A custom heuristic regex engine parses monetary totals (VND/USD), transaction dates, and merchant names into an interactive review screen, which saves into a local SQLite database. Expenses are visualized using **pure CustomPainter animated canvas graphics** without third-party chart dependencies.

---

## 📦 Mandatory Mini-Project Submission Package (3 Deliverables)

### 1. 🌐 Live Demo & Release APK
- **Automated CI/CD Build:** Every push automatically triggers GitHub Actions (`.github/workflows/build_apk.yml`) to compile `app-release.apk` with zero local configuration.
- **Download Release APK:** Check [Releases / Actions](../../actions) on GitHub to download `app-release.apk`.
- **2–3 Minute Demo Video Script:** Complete storyboard and recording guide in [`demo/DEMO_VIDEO_SCRIPT.md`](demo/DEMO_VIDEO_SCRIPT.md).

### 2. 💻 Public GitHub Repository
- Clean commit history, modular clean architecture, comprehensive test suite.
- Verified with `flutter analyze` (**0 issues found**) and `flutter test` (**100% tests passed**).

### 3. 📄 Short Technical Report (2–4 Pages PDF)
- Concise technical report following the official template:
  - Markdown Report: [`report/TECHNICAL_REPORT.md`](report/TECHNICAL_REPORT.md)
  - Printable A4 HTML Template: Open [`report/generate_pdf_report.html`](report/generate_pdf_report.html) in your browser and press `Ctrl + P` &rarr; **Save as PDF**.

---

## 📋 Core Functional Specifications & Feature Matrix


📸 **Live Viewfinder & Flash** | Camera viewfinder with real-time torch/flash mode toggling 
🎯 **Focus Tap** | Touch-to-focus and exposure with animated golden focus reticle 
🔲 **Framing Crop Overlay** | Cutout framing overlay with isolate-based image cropping 
🤖 **On-Device OCR** | Google ML Kit text recognition (offline, sub-100ms, 0 cloud cost) 
🧠 **Regex Heuristic Parser** | Multi-pass regex for VND (`150.000 đ`, `150,000 VND`), USD, and dates 
✏️ **Interactive Review** | Review & edit merchant, amount, category, date, and raw OCR text 
🗄️ **Persistent SQLite Storage** | Full CRUD, date filtering, and category aggregates via `sqflite` 
🏷️ **Category Classification** | Food, Study, Travel, Gear, Entertainment, and Other 
🖼️ **Receipt Thumbnail Caching** | Local application storage caching with list item preview thumbnails 
🍩 **Interactive Donut Chart** | Animated category distribution drawn via CustomPainter with slice tap 
📊 **Interactive Bar Chart** | Animated 7-day spending trend with bar tap selection and value badges 
🚫 **No 3rd-Party Chart Libraries**| 100% Canvas math (`CustomPainter`) for all graphs 

---

## 🏗️ Architecture & Project Structure

```
receipt_scanner/
├── .github/workflows/
│   └── build_apk.yml          # GitHub Actions CI/CD for automated APK builds
├── android/                   # Native Android manifest & configuration
├── demo/
│   └── DEMO_VIDEO_SCRIPT.md   # 2-3 minute video demonstration script
├── report/
│   ├── TECHNICAL_REPORT.md    # Official format technical report
│   └── generate_pdf_report.html # Direct printable A4 HTML template (Ctrl+P -> PDF)
├── test/
│   └── receipt_parser_test.dart # Unit tests for regex heuristics (100% pass)
├── lib/
│   ├── main.dart              # Application bootstrap & runtime theme toggle
│   ├── core/
│   │   ├── database/
│   │   │   └── database_helper.dart      # SQLite singleton & aggregate queries
│   │   ├── models/
│   │   │   └── transaction_model.dart    # Transaction model & ExpenseCategory enum
│   │   ├── services/
│   │   │   ├── ocr_service.dart          # Google ML Kit wrapper
│   │   │   └── receipt_parser.dart       # Heuristic regex extraction engine
│   │   └── theme/
│   │       └── app_theme.dart            # Material 3 light/dark themes
│   └── features/
│       ├── home/
│       │   └── home_screen.dart          # SliverAppBar, monthly total, thumbnail cards
│       ├── camera/
│       │   └── camera_screen.dart        # Viewfinder, tap-to-focus, isolate cropping
│       ├── transactions/
│       │   ├── review_screen.dart        # Pre-save confirmation screen
│       │   ├── add_transaction_screen.dart # Manual expense entry
│       │   └── transaction_detail_screen.dart # Full receipt details & raw text
│       └── analytics/
│           ├── analytics_screen.dart     # Interactive charts & summary cards
│           └── painters/
│               ├── donut_chart_painter.dart # CustomPainter animated donut chart
│               └── bar_chart_painter.dart   # CustomPainter animated 7-day bar chart
```

---

## 🚀 Setup & Build Instructions

### Prerequisites
- **Flutter SDK:** `3.47.8` or any Flutter 3.x (`flutter --version`)
- **Dart SDK:** `3.13.7` or any Dart 3.x

### 1. Clone & Install
```bash
git clone <your-repo-url>
cd receipt_scanner
flutter pub get
```

### 2. Run Static Analysis & Tests
```bash
# Verify static code health (0 issues found)
flutter analyze

# Run heuristic parser unit tests (100% pass)
flutter test
```

### 3. Launch App
```bash
# Run on connected phone or emulator
flutter run
```

### 4. Build Production Release APK
```bash
flutter build apk --release
# Generated APK: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Heuristic Regex Engine Specifics

The heuristic engine in [`receipt_parser.dart`](lib/core/services/receipt_parser.dart) processes:
- **Totals:**
  - Vietnamese format: `TỔNG CỘNG: 150.000 đ`, `150,000 VND`, `Thành tiền: 85000`
  - International format: `Total: $12.50`, `Amount Due: 10.26`
- **Dates:**
  - ISO format: `2026-10-25`
  - Vietnamese slash format: `24/10/2026`, `24-10-2026`
  - Textual dates: `Ngày 25 tháng 10 năm 2026`, `24 Oct 2026`
- **Merchant Names:**
  - Extracts title-case headers while filtering administrative noise (e.g., `HÓA ĐƠN`, `PHIẾU THU`, `MÃ SỐ THUẾ`, phone numbers, street addresses).
