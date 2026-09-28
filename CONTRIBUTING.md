# Contributing to MediaGrab

Thank you for your interest in contributing to **MediaGrab**! We welcome bug reports, feature suggestions, architectural improvements, and code contributions from developers of all backgrounds.

---

## 1. Code of Conduct

All contributors and maintainers are expected to follow our [Code of Conduct](CODE_OF_CONDUCT.md). Please ensure interactions across issues, pull requests, and discussions remain welcoming, constructive, and respectful.

---

## 2. Ways to Contribute

1. **Reporting Bugs**: Found unexpected behavior, crash, or extraction failure? Open an issue using our [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.yml).
2. **Suggesting Features**: Have an idea to make MediaGrab faster, more capable, or more intuitive? Submit a proposal via our [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.yml).
3. **Submitting Code**: Fix bugs, add new engine capabilities, or optimize UI components by submitting a Pull Request.
4. **Improving Documentation**: Fix typos, add translation guides, or improve user documentation.

---

## 3. Development Setup

### 3.1 Prerequisites
- **Flutter SDK**: 3.48.0 or newer (Stable channel).
- **Dart SDK**: 3.12.0 or newer.
- **yt-dlp & ffmpeg**: Installed and available on your system `PATH` for desktop testing:
  - **macOS**: `brew install yt-dlp ffmpeg aria2`
  - **Windows**: `winget install yt-dlp ffmpeg aria2`
  - **Linux**: `sudo apt install yt-dlp ffmpeg aria2`

### 3.2 Local Workspace Setup
```bash
# Clone the repository
git clone https://github.com/raffayalizafar/downloader_all_platform.git
cd downloader_all_platform

# Install Flutter packages
flutter pub get

# Verify system toolchain & connected devices
flutter doctor
```

---

## 4. Core Development Principles

Before writing or modifying code, review these core architectural mandates:

1. **Zero Hardcoded / Static Telemetry**:
   - Never hardcode mock download statistics, static download speeds, or fake resolutions.
   - All system metrics, directory locations, and engine statuses must be dynamically queried from Riverpod providers or device APIs.

2. **Strict Responsive Design**:
   - Mobile displays down to 320px width must render cleanly without `RenderFlex` layout overflow.
   - Always wrap flexible UI components, badges, or chips in `Flexible`, `Expanded`, or `Wrap` with `TextOverflow.ellipsis`.

3. **AMOLED Pure Black Standard**:
   - Any new screen or container must properly support AMOLED pure black mode (`scaffoldBackgroundColor == Colors.black`).
   - Radial glow gradients and blurred gray shadows must be omitted when AMOLED mode is active.

4. **Engine Decoupling & Sanitization**:
   - Never invoke `Process.start('yt-dlp')` directly from UI widgets.
   - All media extraction and downloading must route through the `DownloadEngine` interface via Riverpod providers.
   - All CLI arguments passed to subprocesses must be strictly validated and sanitized to prevent parameter injection.

---

## 5. Quality Assurance & Verification

Every pull request must pass all automated verification checks prior to merging.

### 5.1 Code Formatting
Format all Dart source files according to official Flutter conventions:
```bash
dart format --output=none --set-exit-if-changed lib test
```

### 5.2 Static Analysis
Ensure there are **0 errors, 0 warnings, and 0 linter violations**:
```bash
flutter analyze
```

### 5.3 Automated Test Suite
Run the full automated test suite:
```bash
flutter test
```

### 5.4 Adding Tests
- When introducing a new feature or fixing a bug, add a corresponding unit or widget test in `test/`.
- Test responsive constraints on compact mobile viewports (e.g., `tester.view.physicalSize = const Size(371, 800)`) to guard against UI regressions.

---

## 6. Pull Request Workflow

1. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/dynamic-preset-editor
   ```

2. **Make Surgical, Atomic Commits**:
   Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
   - `feat: add aria2c socket pooling configuration`
   - `fix: prevent layout overflow on compact 360px devices`
   - `docs: update architecture diagram with telemetry flow`

3. **Verify Locally**:
   Run `flutter analyze` and `flutter test` locally to ensure all quality gates pass.

4. **Open a Pull Request**:
   Push your branch and open a PR against `main`. Fill in the provided [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md), describing your changes and attaching screenshots for any visual updates.
