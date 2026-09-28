# Release & Distribution Guide

This document outlines the end-to-end process for packaging, verifying, and publishing official releases of MediaGrab on GitHub.

---

## 1. Versioning Standard

MediaGrab follows [Semantic Versioning (SemVer 2.0.0)](https://semver.org/):
- **MAJOR** (`vX.0.0`): Incompatible architectural changes or substantial platform rewrites.
- **MINOR** (`v1.X.0`): Backwards-compatible features, new engine capabilities, or UI revamps.
- **PATCH** (`v1.0.X`): Backwards-compatible bug fixes, dependency patches, or security updates.

Version numbers are defined in `pubspec.yaml`:
```yaml
version: 1.0.0+1 # [SemVer]+[BuildNumber]
```

---

## 2. Pre-Release Quality Gates

Before creating any release tag, all of the following checks must succeed locally:

```bash
# 1. Verify code formatting
dart format --output=none --set-exit-if-changed lib test

# 2. Verify static analysis (0 warnings, 0 errors)
flutter analyze

# 3. Verify complete automated test suite
flutter test

# 4. Verify no secret or signing files are staged
git status
```

### Documentation Updates
1. Increment the version in `pubspec.yaml`.
2. Add a new release section to [`CHANGELOG.md`](../CHANGELOG.md) documenting:
   - ✨ New Features
   - 🐛 Bug Fixes & Stability
   - 🎨 UI/UX Improvements
   - 🔧 Build & Dependency Updates
3. Commit documentation updates:
   ```bash
   git add pubspec.yaml CHANGELOG.md
   git commit -m "chore(release): prepare v1.0.0"
   ```

---

## 3. Building Platform Artifacts

### 3.1 Android (APK & App Bundle)

#### Split per ABI (Recommended for direct APK distribution)
Reduces file size significantly for end-users:
```bash
flutter build apk --release --split-per-abi
```
Output files located in `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (modern 64-bit devices)
- `app-armeabi-v7a-release.apk` (legacy 32-bit devices)
- `app-x86_64-release.apk` (Intel/AMD emulators & Chromebooks)

#### Universal APK
```bash
flutter build apk --release
```
Output file: `build/app/outputs/flutter-apk/app-release.apk`

---

### 3.2 macOS Desktop

```bash
flutter build macos --release
```
Output bundle: `build/macos/Build/Products/Release/MediaGrab.app`

To package into a distributable `.zip`:
```bash
cd build/macos/Build/Products/Release
zip -r -y MediaGrab-macos.zip MediaGrab.app
cd -
```

---

### 3.3 Windows Desktop

*(Run on Windows 10/11 with Visual Studio C++ build tools installed)*
```powershell
flutter build windows --release
```
Output directory: `build\windows\x64\runner\Release\`

Compress the `Release\` folder into `MediaGrab-windows-x64.zip`.

---

### 3.4 Linux Desktop

*(Run on Linux with clang, cmake, and GTK 3 development headers)*
```bash
flutter build linux --release
```
Output directory: `build/linux/x64/release/bundle/`

Compress the `bundle/` folder into `MediaGrab-linux-x64.tar.gz`:
```bash
tar -czvf MediaGrab-linux-x64.tar.gz -C build/linux/x64/release/bundle .
```

---

## 4. Checksums Generation

Generate cryptographic SHA-256 hashes for all binaries to allow users to verify download integrity:

```bash
sha256sum MediaGrab-*.apk MediaGrab-*.zip MediaGrab-*.tar.gz > SHA256SUMS.txt
```

---

## 5. Publishing on GitHub

### 5.1 Tagging the Release
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### 5.2 Creating the GitHub Release

#### Using GitHub CLI (`gh`):
```bash
gh release create v1.0.0 \
  --title "MediaGrab v1.0.0" \
  --notes-file CHANGELOG.md \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  build/app/outputs/flutter-apk/app-release.apk \
  SHA256SUMS.txt
```

#### Via GitHub Web Interface:
1. Navigate to your repository at `https://github.com/raffayalizafar/MediaGrab/releases`.
2. Click **"Draft a new release"**.
3. Select the tag `v1.0.0`.
4. Set release title: `MediaGrab v1.0.0`.
5. Copy the relevant release notes from [`CHANGELOG.md`](../CHANGELOG.md).
6. Drag and drop your built binaries and `SHA256SUMS.txt` into the binaries section.
7. Click **"Publish release"**.

---

### 5.3 Automated Multi-Platform Release (Recommended)

MediaGrab includes a fully automated GitHub Actions pipeline ([`.github/workflows/release.yml`](../.github/workflows/release.yml)).
Whenever a version tag is pushed:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

GitHub Actions will automatically:
1. Build all **Android** APK architectures (ARM64, ARMv7, x86_64, Universal).
2. Build and package the **macOS** app bundle (`MediaGrab-macos.zip`).
3. Build and package the **Windows** binary and dependencies (`MediaGrab-windows-x64.zip`).
4. Build and package the **Linux** GTK bundle (`MediaGrab-linux-x64.tar.gz`).
5. Compute cryptographic checksums (`SHA256SUMS.txt`).
6. Publish the GitHub Release with all binaries and checksums attached.

