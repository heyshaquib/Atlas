<h2 align="center"><b>Atlas 🌍</b></h2>
<h4 align="center">A privacy-first, fully offline Android bookmark manager featuring Material You Monet dynamic theming, intelligent metadata extraction, and robust organization to give users complete control over their saved links.</h4>

<hr>
<p align="center"><a href="#description">Description</a> &bull; <a href="#features">Features</a> &bull; <a href="#getting-started">Getting Started</a> &bull; <a href="#contributing">Contributing</a> &bull; <a href="#privacy-policy">Privacy Policy</a> &bull; <a href="#license">License</a></p>
<hr>

<p align="center">
  <img src="https://img.shields.io/badge/license-GPLv3-blue" alt="License">
  <img src="https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/platform-Android-3DDC84?logo=android" alt="Android">
</p>

## Description

Atlas is a modern, Material Design 3 bookmark management application. Built with Flutter, it offers a fresh, beautiful, and native-feeling Android experience while maintaining a core philosophy: providing a private, secure, and completely offline environment for managing your web bookmarks.

Since it is free and open-source software, Atlas does not use any cloud servers, proprietary tracking libraries, or data collection frameworks. This means your bookmark data never leaves your device and you retain 100% ownership of your information.

### Features

* **🔒 100% Offline & Private:** No cloud dependency, servers, or trackers. All data stays on your device in a local SQLite database (powered by Drift).
* **✨ Intelligent Metadata Extraction:** Automatically fetches titles, descriptions, favicons, preview images, estimated reading time, and word counts for your saved URLs.
* **🎨 Dynamic Monet Theming:** Material 3 UI with `dynamic_color` support. Adapts to your wallpaper colors with full Light/Dark mode support and an exclusive pure AMOLED black mode.
* **🌐 Domain Hub:** Automatically groups and categorizes your bookmarks by domain, providing a birds-eye view of your most visited websites.
* **📅 Timeline View:** A beautifully crafted chronological timeline showing your saving habits across months and years.
* **📁 Robust Organization:** Manage your bookmarks using custom folders, searchable tags, and rich-text notes attached directly to your bookmarks.
* **⚡ Native Share Intent:** Share any link directly to Atlas from any app on your phone via Android's native share menu for quick saving.
* **💾 Backup & Restore:** Complete portability via robust JSON exports, as well as universal Netscape HTML importing and exporting to seamlessly migrate from or to browser bookmarks.
* **🧹 Smart Maintenance:** Background tasks for dead link checking and automatic trash bin cleanup so your database stays pristine.

## Getting Started

### Prerequisites

- Flutter SDK `^3.24.0`
- Android SDK with Build Tools (min SDK 26, target SDK 35)
- Java 17 (for Gradle / Kotlin DSL builds)

### Installation / Build from source

To build a debug APK yourself:

1. Clone the repository:
   ```bash
   git clone https://github.com/heyshaquib/Atlas.git
   cd Atlas
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run Drift code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Contributing

Whether you have ideas, translations, design changes, code cleaning, or even major code changes, help is always welcome. The app gets better and better with each contribution, no matter how big or small!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Privacy Policy

Atlas aims to provide a completely private and secure experience for managing your bookmarks. Therefore, the app does not collect, transmit, or store any data on external servers. All your bookmark data, settings, and reading history remain strictly on your local device within an offline SQLite database.

## License

[![GNU GPLv3 Image](https://www.gnu.org/graphics/gplv3-127x51.png)](https://www.gnu.org/licenses/gpl-3.0.en.html)

Atlas is Free Software: You can use, study, share, and improve it at will. Specifically, you can redistribute and/or modify it under the terms of the [GNU General Public License](https://www.gnu.org/licenses/gpl.html) as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
