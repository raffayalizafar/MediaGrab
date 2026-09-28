# Changelog

All notable changes to **MediaGrab** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0-beta.1] - 2026-09-20 (Pre-release for Testing)

### 🧪 Pre-release Highlights & Multi-Platform Validation
- **Multi-Platform Deployment Matrix**: Initial public pre-release providing testing binaries across Android (`.apk`), macOS (`.dmg`, `.zip`), Windows (`.zip`, `.exe`), and Linux (`.tar.gz`).
- **Native Desktop Branding & Windows Setup**: Added automated Inno Setup script (`MediaGrab-windows-setup.exe`), Windows PE metadata, and native macOS DMG packaging (`MediaGrab-macos.dmg`).
- **CI/CD Cloud Automation**: Configured multi-runner GitHub Actions CI/CD pipeline with cryptographic SHA-256 checksum verification.
- **Categorized Release Notes**: Integrated `.github/release.yml` for automated GitHub release note categorization.
- **TopBar-Centric Logo Polish**: Streamlined branding to a single primary brand mark in `StitchTopBar` across all screens and platforms; replaced repetitive side-rail and hero card logos with contextual action icons and engine telemetry indicators.
- **Single-Border Controls**: Removed inherited `InputDecoration` outline borders from Downloads and Templates search fields, eliminating awkward double borders.
- **Zero-Overflow Responsive Header**: Resolved RenderFlex overflow in `DownloadsScreen` on intermediate widths (700px–970px) and compact mobile displays by implementing dynamic flex wrapping, expanded title sections, and responsive action buttons.

---

## [1.0.0] - 2026-09-17

### 🌟 Highlights & Major Milestones

MediaGrab 1.0.0 is the inaugural production release of our unified, cross-platform video and audio archiving powerhouse. Inspired by the best of Seal and engineered with Flutter 3, MediaGrab delivers desktop-grade `yt-dlp` capability and pure Dart stream extraction alongside an ultra-responsive, cyber-luxe visual design.

---

### 🎨 Visual Redesign & UI/UX Experience

- **Stitch Visual Style Overhaul**:
  - Premium cyber-luxe dark aesthetic with curated slate/indigo color palettes (`#0F172A`, `#6366F1`, `#38BDF8`, `#10B981`).
  - Ambient radial gradients with subtle glowing lights in dark mode, dynamically suppressed in AMOLED mode for true `#000000` pitch black.
  - Consistent elevated claymorphism cards with dual ambient shadows and crisp rim highlights via `ClayTheme.decoration`.

- **Mobile Floating Claymorphic Bottom Navigation Bar (`AppBottomNavBar`)**:
  - Implemented an animated floating claymorphic bar with spring curve physics (`Curves.easeOutBack`).
  - Animated sliding active pill indicator with tactile icon scaling (`AnimatedScale` 1.12x when active).
  - Translucent backdrop blur (`ImageFilter.blur(sigmaX: 3, sigmaY: 3)`) allowing background content to be visible behind the floating bar.
  - Opaque touch interception (`GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {})`) ensuring background elements cannot be accidentally tapped through the bar.
  - Dual layout modes: horizontal icon + label on wide devices, stacked vertical layout on compact devices to eliminate horizontal overflow.

- **Unified Sticky `StitchTopBar`**:
  - Replaced legacy app bars across Home, Downloads, Templates, and Settings with the unified `StitchTopBar`.
  - Integrates the high-resolution transparent neon app logo and dynamic `v1.0` version pill.
  - Live system telemetry ribbon displaying realtime download speed metrics (`MB/s`), active thread pool indicators, and animated engine status (`PulsingDot`).
  - Trailing active download badge counter with direct 1-tap jump to the Downloads tab.

- **Brand Identity & App Logo Overhaul**:
  - Designed and extracted transparent neon MediaGrab app icon with glowing gradient halo.
  - Generated and deployed cross-platform icon assets across:
    - Android (`res/mipmap-*/ic_launcher.png`)
    - iOS (`Runner.xcassets/AppIcon.appiconset`)
    - macOS (`Assets.xcassets/AppIcon.appiconset`)
    - Windows (`windows/runner/resources/app_icon.ico`)
    - Web (`web/icons/Icon-*.png` & `favicon.png`)
  - Created animated high-performance `SplashScreen` with synchronized logo glow and scale animations.

- **AMOLED Pure Black Mode**:
  - Dedicated AMOLED pure black toggle (`#000000` surface and scaffold background).
  - High-contrast card borders (`#1E1E1E`) and optimized low-power OLED display efficiency.

---

### ⚡ Download Engines & Core Architecture

- **Dual-Engine Abstraction Layer**:
  - `YtDlpEngine`: Robust desktop subprocess execution on macOS, Windows, and Linux with JSON progress streaming and comprehensive metadata extraction.
  - `DartEngine`: Zero-dependency, sandbox-safe pure Dart engine powered by `youtube_explode_dart` for mobile platforms and fallback scenarios.
  - `EngineResolver`: Automatic runtime detection and resolution based on host operating system capabilities and external binary availability.

- **Dynamic System Telemetry**:
  - Removed all hardcoded resolutions, mock template counts, and static directory strings.
  - Engine detection provider (`engineInfoProvider`) dynamically reports active binary versions, thread pool status, and subprocess paths.
  - Live download manager telemetry tracking active, queued, paused, completed, and failed tasks with byte-level progress calculation.

- **Accelerated Multi-Socket Downloads**:
  - Integrated `aria2c` external multi-connection downloader support with configurable concurrent connections (up to 16 threads).

- **1-Click Power-User Batch Presets**:
  - Dynamic preset cards loaded from active `CommandTemplate` definitions (Fast Audio Extraction, 4K Master Video Archiving, SponsorBlock Ad Removal, Mobile 1080p, Subtitle Extraction).
  - Interactive template editor dialog with real-time argument validation and JSON import/export.

---

### 🛠️ Bug Fixes & Stability

- **Layout & Overflow Resolutions**:
  - Fixed 1.7px horizontal overflow on Home Screen download cards.
  - Fixed 6.6px horizontal overflow on quick preset cards.
  - Fixed 16px horizontal overflow on ultra-compact mobile viewports (371px and 360px devices) by making text badges responsive with `Flexible` and `Wrap`.
  - Added width-constrained section headers in Settings to eliminate clipping.

- **AMOLED State Consistency**:
  - Resolved theme state synchronization in `widget_test.dart` by mapping `AppConstants.keyAmoledDark` and `AppConstants.keyThemeMode` to persistent storage.

- **Clean Static Analysis**:
  - Resolved all linter warnings and info diagnostics across the codebase (0 issues reported by `flutter analyze`).
  - Achieved 100% test pass rate across 23 unit and widget test cases.

---

### 📦 Platform Support

- **macOS**: Fully functional native desktop app with subprocess execution and window constraints.
- **Windows**: Native desktop support with custom `.ico` and `yt-dlp.exe` integration.
- **Linux**: Native desktop support with standard GTK integration.
- **Android**: Responsive touch layout, adaptive icons, and sandbox-compatible background architecture.
- **iOS**: Pure Dart download engine with sandbox safety and gesture-driven UI.
- **Web**: Progressive web app compatibility with responsive layout switching.
