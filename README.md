# ⚡ iTHUNG - Speed Math Game

iTHUNG adalah aplikasi permainan kecepatan matematika berbasis Flutter dengan Domain-Driven Clean Architecture yang mengombinasikan gameplay cepat, desain fisik berbobot (*chunky playful*), adaptasi kesulitan dinamis (DDA), dan pengulangan berkala (*Spaced Repetition*) berbasis Leitner box.

---

## 🌟 Fitur Utama

- **⏱️ 60fps Gameplay Terisolasi**: Countdown timer progresif 60fps yang di-drive secara efisien oleh local ticker (`RepaintBoundary` + `CustomPainter`) tanpa memicu re-layout atau widget rebuild pada tree parent.
- **🧠 Generator Soal Adaptif (Relaxation Ladder)**: Menghasilkan soal matematika berdasarkan 5 Level Band (Onboarding, Basic, Intermediate, Advanced, Expert) dengan mekanisme mitigasi zero-failure.
- **📈 Dynamic Difficulty Adjustment (DDA)**:
  - *Layer 1*: Penyesuaian batas waktu respon secara halus berdasarkan `confidence_score` sesi.
  - *Layer 2*: Interleaving fakta aritmatika yang lemah dari Mastery Bank secara berkala.
- **📚 Mastery & Mistake Bank (Spaced Repetition)**: Menyimpan rekam jejak ketangkasan pemain per fakta operasi dalam 5 kotak Leitner, dengan algoritma promosi/demosi instan dan penyimpanan lokal berbasis Hive CE.
- **📅 Deterministik Daily Challenge**: Tantangan harian 12 soal yang deterministik per kohor band berbasis FNV-1a hash murni tanpa ketergantungan koneksi jaringan.
- **🎨 Desain Chunky & Tipografi Tersentralisasi**:
  - Angka dan metrik menggunakan font **JetBrains Mono** (*tabular numerals*).
  - Teks dan navigasi menggunakan font **Quicksand**.
  - Seluruh warna, padding, radius, border, dan bayangan solid tersentralisasi via `AppTokens`, `AppIcons`, dan `AppTheme`.

---

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart SDK ^3.7.0)
- **State Management**: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Navigation**: `go_router`
- **Local Persistence**: `hive_ce`, `hive_ce_flutter`
- **Typography & Icons**: `google_fonts`, `tabler_icons`
- **Audio & Haptics**: `audioplayers`

---

## 🚀 Memulai Aplikasi

### Prasyarat
- Flutter SDK (3.29.0 atau lebih baru)
- Android Studio / Xcode / VS Code

### Instalasi Dependensi
```bash
flutter pub get
```

### Menjalankan Aplikasi
```bash
flutter run
```

### Menjalankan Pengujian
```bash
flutter test
```

### Memeriksa Kualitas Kode
```bash
flutter analyze
```

---

## 🏛️ Arsitektur Proyek

```
lib/
├── core/            # Theme, Tokens, Constants, Utilities
├── data/            # Local Repository Implementations (Hive CE), Event Logging
├── domain/          # Pure Dart Models, Repository Contracts, Core Business Services
└── presentation/    # Riverpod Notifiers, State Machines, Screens, & Reusable Widgets
```
