<div align="center">

  <img src="assets/images/app_logo_512.png" width="130" height="130" alt="MediaGrab Logo" />

  <h1>MediaGrab</h1>

  <p><strong>A modern, high-performance, cross-platform video & audio downloader built with Flutter & Material 3.</strong></p>

  <p>
    <a href="https://github.com/raffayalizafar/MediaGrab/actions/workflows/ci.yml">
      <img src="https://github.com/raffayalizafar/MediaGrab/actions/workflows/ci.yml/badge.svg" alt="CI Build Status" />
    </a>
    <a href="https://flutter.dev">
      <img src="https://img.shields.io/badge/Flutter-3.48-02569B?logo=flutter&logoColor=white" alt="Flutter 3.48" />
    </a>
    <a href="https://dart.dev">
      <img src="https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white" alt="Dart 3.12" />
    </a>
    <a href="LICENSE">
      <img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="License: GPL v3" />
    </a>
    <a href="https://github.com/raffayalizafar/MediaGrab/releases">
      <img src="https://img.shields.io/badge/Release-v1.0.0--beta.1%20(Pre--release)-indigo" alt="Pre-release v1.0.0-beta.1" />
    </a>
    <a href="CONTRIBUTING.md">
      <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome" />
    </a>
  </p>

  <p>
    <a href="#-key-features">Key Features</a> •
    <a href="#-platform-support">Platform Support</a> •
    <a href="#-download--releases">Downloads</a> •
    <a href="#-quick-start">Quick Start</a> •
    <a href="#-tech-stack">Tech Stack</a> •
    <a href="#-privacy--security">Privacy</a> •
    <a href="#-contributing">Contributing</a> •
    <a href="#-disclaimer">Disclaimer</a>
  </p>

</div>

---

## 📖 Overview

**MediaGrab** is an open-source, client-side media extraction and downloading application designed for speed, flexibility, and privacy. Built with Flutter, it delivers a unified and fluid experience across mobile, desktop, and tablet form factors.

Whether downloading archival videos in 4K/8K, extracting audio tracks with embedded ID3 metadata and album art, downloading subtitle streams, or running custom CLI commands via `aria2c` acceleration, MediaGrab handles the task through an adaptive dual-engine architecture.

> [!NOTE]
> MediaGrab operates **100% locally on your device**. There are no central proxy servers, no telemetry trackers, and no external user accounts.

---

## 📸 UI & Design Showcase

<div align="center">
  <table border="0">
    <tr>
      <td align="center" width="50%">
        <img src="assets/images/app_icon_squircle.png" width="96" height="96" alt="App Icon" /><br />
        <b>Adaptive Icon & Visual System</b><br />
        <i>Claymorphic depth with subtle dual shadows and rim lighting.</i>
      </td>
      <td align="center" width="50%">
        <img src="assets/images/app_logo.png" width="96" height="96" alt="MediaGrab Branding" /><br />
        <b>Stitch Cyber-Luxe TopBar</b><br />
        <i>Live download speeds, active thread telemetry, and engine indicators.</i>
      </td>
    </tr>
  </table>
</div>

### Design Highlights
- **Unified TopBar Branding**: Clean, polished visual hierarchy featuring a single prominent brand mark in `StitchTopBar` across all platforms, paired with contextual action badges and engine telemetry indicators.
- **Clean Single-Border Controls**: Search filters and inputs engineered with borderless input decorators inside claymorphic pill containers, eliminating awkward double borders.
- **Zero-Overflow Adaptive Flex**: Responsive layouts with dynamic breakpoints and auto-truncating telemetry text, mathematically guaranteed against RenderFlex overflows from 320px compact mobile to 4K desktop.
- **Stitch Cyber-Luxe & Claymorphic UI**: Translucent layered cards with dual ambient shadows and soft rim highlights.
- **Floating Glass Bottom Navbar**: Tactile icon spring scaling, sliding active pill indicator (`Curves.easeOutBack`), and touch-blocking backdrop blur.
- **AMOLED Pure Black Mode**: True `#000000` pitch black background for maximum OLED contrast and battery savings.
- **Dynamic Theming**: Automatic Material You dynamic color extraction on Android 12+, with rich dark and light fallback themes.

---

## ✨ Key Features

| Category | Capabilities |
| :--- | :--- |
| **🌐 Broad Site Support** | Extracts media from YouTube, TikTok, Instagram, Twitter/X, Reddit, Twitch, Facebook, and **1,800+** sites via `yt-dlp` on desktop and pure Dart extraction on mobile. |
| **🎬 High-Resolution Video** | Download videos up to 1080p, 1440p, 4K, and 8K with automatic video/audio stream muxing into MP4, MKV, and WebM containers. |
| **🎵 Audio Extraction & Tagging** | Extract audio in MP3, M4A, Opus, FLAC, and WAV with automatic ID3 metadata (title, artist, album) and high-resolution thumbnail embedding. |
| **⏸️ Pause & Resumable Downloads** | True resumability across all engines. Pure Dart utilizes HTTP `Range: bytes=$offset-` headers on partial `.part` files, while `yt-dlp` runs with `--continue` for zero byte waste on paused or interrupted transfers. |
| **⏰ Schedule Downloads** | Schedule downloads for later (presets: `+30m`, `+1h`, `+2h`, `Tonight 2 AM` or custom date/time). Background ticker starts tasks automatically, with live countdown and "Start Now" overrides. |
| **📶 Network Resilience & Wi-Fi Only** | "Download Over Wi-Fi Only" setting auto-holds downloads on mobile data; automatic auto-resume on reconnection; real-time slow speed (<20 KB/s) and stall detection with alert pills. |
| **💬 Subtitles & Captions** | Download and embed multi-language subtitles or auto-generated captions directly into video containers. |
| **📁 Full Playlist Support** | Automatically detect playlist URLs, preview item counts, and batch-download entire playlists or custom item ranges. |
| **📂 Smart Folder Hierarchy** | Pick custom destinations per-download or change the default in Settings. Automatically sorts into `MediaGrab/video/` and `MediaGrab/audio/`, isolating playlists in dedicated subfolders. |
| **📊 Real-Time Download Manager** | Live speed metrics (`MB/s`), progress percentages, ETA countdowns, active queue concurrency limits, pause, resume, retry, and cancellation. |
| **🛠️ Custom Command Presets** | Save, customize, and execute custom `yt-dlp` CLI arguments (e.g. SponsorBlock ad removal, speed rate limits, custom cookies). |
| **🏎️ Multi-Connection Acceleration** | Optional external downloader integration with `aria2c` for maximum download speeds on supported desktop platforms. |
| **🔒 Zero Hardcoded Metrics** | All engine states, download speeds, filesystem paths, and active threads are calculated and queried dynamically via Riverpod. |

---

## 🌐 Platform Support

MediaGrab uses a platform-abstracted **Dual-Engine Architecture** to provide optimal extraction capabilities tailored to each operating system:

| Platform | Engine | Capabilities | Status |
| :--- | :--- | :--- | :--- |
| **Android** | `DartEngine` / Native Channels | Direct stream extraction, background downloads, native share intent | :white_check_mark: Supported |
| **iOS** | `DartEngine` (Pure Dart) | Sandbox-safe extraction without external binaries | :white_check_mark: Supported |
| **macOS** | `YtDlpEngine` (Subprocess) | 1,800+ sites, JSON progress parsing, `aria2c` acceleration, multi-stream muxing | :white_check_mark: Supported |
| **Windows** | `YtDlpEngine` (Subprocess) | 1,800+ sites, JSON progress parsing, `aria2c` acceleration, multi-stream muxing | :white_check_mark: Supported |
| **Linux** | `YtDlpEngine` (Subprocess) | 1,800+ sites, JSON progress parsing, `aria2c` acceleration, multi-stream muxing | :white_check_mark: Supported |

---

## 📥 Download & Releases

Download official precompiled release packages directly from [**GitHub Releases**](https://github.com/raffayalizafar/MediaGrab/releases).

### Direct Downloads (Latest Pre-release: `v1.0.0-beta.1`)

| Platform | Format | Package | Target / Notes |
| :--- | :--- | :--- | :--- |
| **macOS** | **DMG** | [**`MediaGrab-macos.dmg`**](https://github.com/raffayalizafar/MediaGrab/releases/latest/download/MediaGrab-macos.dmg) | Drag-and-drop installer for macOS 12+ (Universal Intel & Apple Silicon) |
| | **ZIP** | [**`MediaGrab-macos.zip`**](https://github.com/raffayalizafar/MediaGrab/releases/latest/download/MediaGrab-macos.zip) | Portable `.app` archive |
| **Windows** | **Setup EXE** | [**`MediaGrab-windows-setup.exe`**](https://github.com/raffayalizafar/MediaGrab/releases/latest/download/MediaGrab-windows-setup.exe) | Standard Windows installer with desktop and Start Menu shortcuts |
| | **ZIP** | [**`MediaGrab-windows-x64.zip`**](https://github.com/raffayalizafar/MediaGrab/releases/latest/download/MediaGrab-windows-x64.zip) | Portable 64-bit standalone package |
| **Linux** | **Tarball** | [**`MediaGrab-linux-x64.tar.gz`**](https://github.com/raffayalizafar/MediaGrab/releases/latest/download/MediaGrab-linux-x64.tar.gz) | Standalone GTK 3 desktop application bundle |
| **Android** | **APK (arm64-v8a)** | [**`MediaGrab-android-arm64-v8a.apk`**](https://github.com/raffayalizafar/MediaGrab/releases/latest/download/MediaGrab-android-arm64-v8a.apk) | Modern 64-bit Android devices *(Recommended)* |
| | **APK (armeabi-v7a)** | [**`MediaGrab-android-armeabi-v7a.apk`**](https://github.com/raffayalizafar/MediaGrab/releases/latest/download/MediaGrab-android-armeabi-v7a.apk) | Legacy 32-bit Android devices |
| | **APK (x86_64)** | [**`MediaGrab-android-x86_64.apk`**](https://github.com/raffayalizafar/MediaGrab/releases/latest/download/MediaGrab-android-x86_64.apk) | Android x86_64 emulators & Chromebooks |
| | **APK (Universal)** | [**`MediaGrab-android-universal.apk`**](https://github.com/raffayalizafar/MediaGrab/releases/latest/download/MediaGrab-android-universal.apk) | All-in-one universal Android APK |

### Installation Notes for Open-Source Desktop Binaries

* **macOS**: After opening `MediaGrab-macos.dmg` and dragging to Applications, if macOS Gatekeeper displays an *unidentified developer* dialog on first launch:
  * Right-click `MediaGrab.app` in `/Applications` and select **Open**, or run:
    ```bash
    xattr -cr /Applications/MediaGrab.app
    ```
* **Windows**: If Microsoft Defender SmartScreen displays a warning for a freshly downloaded unsigned binary:
  * Click **More info**, then click **Run anyway**.

For detailed build commands and packaging guides, refer to [**docs/RELEASES.md**](docs/RELEASES.md).

---

## 🚀 Quick Start

### Prerequisites

1. **Flutter SDK**: 3.48.0 or newer ([Install Guide](https://flutter.dev/docs/get-started/install)).
2. **Dart SDK**: 3.12.0 or newer.
3. *(Optional for Desktop)* **yt-dlp, ffmpeg, aria2c**:
   - **macOS**: `brew install yt-dlp ffmpeg aria2`
   - **Windows**: `winget install yt-dlp ffmpeg aria2`
   - **Linux**: `sudo apt install yt-dlp ffmpeg aria2`

### Clone & Run

```bash
# 1. Clone repository
git clone https://github.com/raffayalizafar/MediaGrab.git
cd MediaGrab

# 2. Fetch dependencies
flutter pub get

# 3. Run automated tests
flutter test

# 4. Launch on connected device or simulator
flutter run
```

---

## 🏗️ Tech Stack

```
MediaGrab
├── UI Framework:         Flutter (Material 3 + Claymorphic Glass System)
├── State Management:     flutter_riverpod (Compile-safe reactive state)
├── Dynamic Theming:      dynamic_color (Material You) + Google Fonts (JetBrains Mono)
├── Media Engines:
│   ├── Pure Dart:        youtube_explode_dart (Sandbox-compliant extraction)
│   └── Subprocess:       yt-dlp + ffmpeg + aria2c (Advanced desktop capabilities)
├── Utilities:            shared_preferences, path_provider, share_plus, url_launcher
└── Quality Assurance:    flutter_test, flutter_lints, GitHub Actions CI
```

For full details on individual dependencies and licenses, consult [**docs/DEPENDENCIES.md**](docs/DEPENDENCIES.md).

---

## 🔒 Privacy & Security

- **Zero Data Collection**: MediaGrab does not collect, store, transmit, or monetize any user data, search queries, or download history.
- **No Third-Party Analytics**: No Google Analytics, Firebase, Sentry, or proprietary trackers are included.
- **Direct P2P Connections**: All network connections are established directly between your device and the media host URL you provide.
- **Responsible Vulnerability Disclosure**: Found a security issue? Please report it confidentially via [GitHub Security Advisories](https://github.com/raffayalizafar/MediaGrab/security/advisories/new) or consult [**SECURITY.md**](SECURITY.md).

---

## 🤝 Contributing

Contributions make the open-source community an incredible place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Review our [**Code of Conduct**](CODE_OF_CONDUCT.md) and [**Contributing Guidelines**](CONTRIBUTING.md).
2. Fork the repository and create your feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/):
   ```bash
   git commit -m "feat: add support for custom user agent strings"
   ```
4. Run verification gates:
   ```bash
   flutter analyze
   flutter test
   ```
5. Open a Pull Request using our [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md).

---

## 🐛 Bug Reporting & Feature Requests

- **Found a bug?** Submit a [Bug Report](.github/ISSUE_TEMPLATE/bug_report.yml) with your device specifications and reproduction steps.
- **Have an idea?** Submit a [Feature Request](.github/ISSUE_TEMPLATE/feature_request.yml) describing your proposal and use cases.

---

## 📚 Project Documentation

- 📖 [**User Guide**](docs/USER_GUIDE.md): Complete guide on downloads, audio conversion, subtitles, and template presets.
- 🏗️ [**Architecture Guide**](ARCHITECTURE.md): In-depth review of the dual-engine abstraction, Riverpod providers, and design tokens.
- 📦 [**Dependencies & Licenses**](docs/DEPENDENCIES.md): Comprehensive inventory of all libraries and external binaries.
- 🚀 [**Release & Distribution**](docs/RELEASES.md): Detailed packaging instructions for Android, macOS, Windows, and Linux.
- 📝 [**Changelog**](CHANGELOG.md): Historical record of versions, milestones, and enhancements.

---

## 🙏 Credits & Acknowledgements

We are grateful to the broader open-source community for the tools and libraries that made MediaGrab possible:
- [**yt-dlp**](https://github.com/yt-dlp/yt-dlp) — The powerful command-line media downloader.
- [**youtube_explode_dart**](https://github.com/Hexer10/youtube_explode_dart) — High-performance pure Dart YouTube stream extractor.
- [**Flutter Team**](https://flutter.dev) — For the exceptional cross-platform UI framework and Material 3 design primitives.
- [**aria2**](https://aria2.github.io) — Ultra-fast multi-connection download engine.
- [**FFmpeg**](https://ffmpeg.org) — The universal multimedia processing framework.

---

## ⚖️ License

MediaGrab is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the [**LICENSE**](LICENSE) file for the complete terms and conditions.

---

## ⚠️ Disclaimer

**MediaGrab is an independent, community-driven open-source software project.**

- MediaGrab is **NOT** affiliated, associated, authorized, endorsed by, or in any way officially connected with Seal, YouTube, Google LLC, Alphabet Inc., TikTok, Meta, Twitter/X, or any of their subsidiaries or affiliates.
- The names YouTube, TikTok, Instagram, Twitter, Reddit, Seal, as well as related names, marks, emblems, and images are registered trademarks of their respective owners.
- MediaGrab is designed exclusively for personal archiving, backup, and fair-use educational purposes. Users are solely responsible for ensuring that their downloads comply with all applicable local copyright laws, intellectual property rights, and terms of service of the third-party platforms from which media is retrieved.
