# 🎬 Demo Video Script & Recording Guide (2–3 Minutes)
## Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)

This guide provides a structured, step-by-step storyboard to record a 2–3 minute video demonstration required for submission.

---

### ⏱️ Video Timeline Breakdown (Total: 2m 30s)

| Section | Duration | Screen / Feature | Voiceover / Action Script |
| :--- | :--- | :--- | :--- |
| **1. Intro** | 0:00 – 0:25 | Home Screen | "Hello! This is Mini-Project 3: OCR Expense Tracker & Receipt Parser built in Flutter with on-device AI. The app helps students and treasurers scan physical supermarket receipts offline with zero cloud cost." |
| **2. Camera & OCR** | 0:25 – 1:05 | Camera Screen | • Tap the Floating Action Button ("Scan Receipt").<br>• Demonstrate **Tap-to-focus** (yellow focus ring appears).<br>• Toggle **Flash / Torch** on and off.<br>• Frame receipt within the **Framing Crop Overlay**.<br>• Tap capture button. Point out that OCR extraction runs locally via Google ML Kit in under 100ms. |
| **3. Interactive Review** | 1:05 – 1:35 | Review Screen | • Show the cropped receipt preview and extracted details.<br>• Expand **"View Raw OCR"** to display extracted text.<br>• Demonstrate manual edits: adjust merchant name or select category (e.g., Food, Study, Travel).<br>• Tap **"Save Receipt"**. |
| **4. Database & Home** | 1:35 – 2:00 | Home Screen | • Show the new transaction appearing immediately on the list.<br>• Highlight the **cached receipt thumbnail**.<br>• Show monthly spending total updating automatically in the SliverAppBar header.<br>• Demonstrate **Swipe-to-delete** or manual edit. |
| **5. CustomPainter Charts** | 2:00 – 2:30 | Analytics Screen | • Switch to **Analytics Tab**.<br>• Show the **animated Donut Chart** drawing smoothly with CustomPainter.<br>• **Tap a slice** on the donut: show dynamic expansion, percentage, and category breakdown in center.<br>• Show the **animated 7-Day Bar Chart** with gradient bars.<br>• **Tap a bar**: show the active column highlight and amount badge.<br>• Conclude: "Built with Flutter 3.x, SQLite, and 100% pure CustomPainter without any third-party chart libraries." |

---

### 💡 Pro Tips for Recording:
1. **Screen Recording:** Use Android's built-in Screen Recorder (`adb shell screenrecord` or Quick Settings) or OBS Studio with emulator.
2. **Audio:** Speak clearly with an external mic or headset.
3. **Receipt Sample:** Prepare 1–2 real physical receipts or display receipt images on another screen to scan directly.
4. **Resolution:** 1080p (portrait or 16:9 canvas with mobile frame).
5. **Upload:** Upload the recording to **YouTube (Unlisted)** or **Google Drive (Anyone with link can view)** and place the URL in your GitHub repository README.md.
