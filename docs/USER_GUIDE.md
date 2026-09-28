# MediaGrab User Guide 🦭

Welcome to **MediaGrab**, your modern, high-performance, cross-platform video and audio archiving companion. This guide explains how to get the most out of MediaGrab across desktop and mobile devices.

---

## Table of Contents
1. [Getting Started](#1-getting-started)
2. [Downloading Video and Audio](#2-downloading-video-and-audio)
3. [Managing Downloads](#3-managing-downloads)
4. [Using Command Templates](#4-using-command-templates)
5. [Customizing Settings & Appearance](#5-customizing-settings--appearance)
6. [Power-User Features & Acceleration](#6-power-user-features--acceleration)
7. [Troubleshooting & FAQ](#7-troubleshooting--faq)

---

## 1. Getting Started

When you first launch MediaGrab, you will be greeted by the animated splash screen and the unified **Stitch TopBar**:
- **App Logo & Version**: Displays the active version badge (`v1.0`).
- **Telemetry Ribbon**: Shows real-time aggregate download speed (`MB/s`), active engine status (`Engine Online`), and worker thread counts.
- **Active Task Indicator**: If downloads are actively running in the background, a compact badge appears on the right edge of the top bar. Tapping it instantly jumps you to the Downloads queue.

### Navigation Modes
- **Mobile (Phones & Tablets)**: A floating claymorphic bottom bar (`AppBottomNavBar`) appears at the bottom with translucent blur, tactile animations, and an animated sliding pill indicator.
- **Desktop (macOS, Windows, Linux)**: An 80px sleek side navigation rail expands navigation real estate while keeping downloads and telemetry visible.

---

## 2. Downloading Video and Audio

### Step 1: Provide a Media URL
- **Auto-Paste**: If you have a supported media URL copied to your system clipboard, tap the **Paste** button next to the input field on the Home Screen.
- **Manual Input**: Type or paste any video, playlist, or audio URL from over 1,800+ supported sites (YouTube, TikTok, Instagram, Twitter/X, Reddit, Twitch, Facebook, and more).

### Step 2: Fetch Metadata
Tap the **Fetch Media** button. MediaGrab queries the active download engine and displays the **Media Configuration Sheet** with:
- Video title, author/channel, duration, and thumbnail preview.
- Mode Selector: **Video** or **Audio**.

### Step 3: Choose Output Preferences

#### For Video Downloads:
- **Quality / Resolution**: Select from available streams (4K/2160p, 1440p, 1080p, 720p, 480p, 360p, or Best Available).
- **Container Format**: MP4 (standard compatibility), MKV (supports multiple audio/subtitle tracks), or WebM.
- **Embed Subtitles**: Toggle to automatically download and mux subtitles into the video container.
- **Thumbnail Cover Art**: Toggle to embed video thumbnail as file metadata.

#### For Audio Extraction:
- **Audio Format**: MP3 (universal compatibility), M4A (AAC), Opus (ultra-efficient), FLAC (lossless), or WAV.
- **Audio Quality**: Best (320 kbps), High (256 kbps), Medium (192 kbps), Standard (128 kbps).
- **ID3 Metadata Embedding**: Automatically tags the audio file with song title, artist, and album art.

### Step 4: Start Download
Tap **Start Download**. A notification toast will confirm the task has been queued and you can monitor real-time progress.

---

## 3. Managing Downloads

Navigate to the **Downloads** tab to monitor active tasks and review past downloads.

### Active Queue
- **Live Metrics**: Track percentage completion, downloaded bytes, total file size, real-time download speed (`MB/s`), and estimated time remaining (ETA).
- **Task Controls**:
  - **Pause / Resume**: Temporarily halt a download or resume from the last received byte chunk.
  - **Cancel**: Abort an ongoing download and clean up partial temporary files.

### Completed History
- **Open File**: Instantly play the completed video or audio file using your default system player.
- **Reveal in Finder / Folder**: Open the file's containing folder in your system file manager.
- **Share**: Export or share the downloaded file to other applications.
- **Delete Record / File**: Remove the download record from history or permanently remove the physical file from disk.

---

## 4. Using Command Templates

Command Templates give you 1-click access to advanced `yt-dlp` commands and batch configurations.

### Built-in Curated Presets
1. **Fast Audio Extraction**: Extracts best audio as 320 kbps MP3 with full ID3 tagging and thumbnail cover art.
2. **4K Master Archiving**: Downloads maximum quality video up to 4K/8K, muxing video and audio into a lossless MKV container.
3. **SponsorBlock Ad Removal**: Uses the SponsorBlock API (`--sponsorblock-remove sponsor,selfpromo`) to automatically cut sponsored segments out of videos.
4. **Mobile 1080p MP4**: Optimized 1080p H.264/AAC video in standard MP4 container for instant phone playback.
5. **Subtitle Extractor**: Downloads all available subtitle languages as clean `.srt`/`.vtt` files.

### Creating Custom Templates
1. Go to the **Templates** tab and tap **New Template** (`+`).
2. Enter a descriptive title and description.
3. Input custom CLI arguments (e.g., `--limit-rate 5M --write-auto-subs --sub-lang en`).
4. Save the template. It will immediately appear in your template library and on the Home screen's quick preset carousel.

---

## 5. Customizing Settings & Appearance

Open the **Settings** tab to fine-tune your MediaGrab experience:

### Appearance & Display
- **Theme Mode**: Choose between **System Default**, **Dark**, or **Light**.
- **AMOLED Pure Black**: Switches all dark backgrounds and cards to true `#000000` pitch black, maximizing battery life on OLED displays and eliminating halo glows.

### Engine & Network Acceleration
- **Download Engine Info**: Displays the currently active engine (`yt-dlp` subprocess or pure Dart `youtube_explode_dart`), binary version, and thread pool.
- **aria2c Multi-Connection**: Toggle multi-socket accelerated downloading (up to 16 concurrent HTTP streams per file).
- **Concurrent Download Limit**: Adjust how many tasks download concurrently (1 to 8 tasks).

### Storage & Directories
- **Download Directory**: View and customize the destination folder for all downloaded files.
- **Clear Download History**: Clean up completed history entries without deleting files from disk.

---

## 6. Power-User Features & Acceleration

### Multi-Socket Acceleration via aria2c
When aria2c is installed on your system (desktop platforms) and enabled in Settings:
- MediaGrab splits large video files into 16 simultaneous chunks.
- Download speeds can increase by 300%–800% on bandwidth-throttled servers.

### CLI Command Sanitization
MediaGrab inspects and sanitizes all custom command arguments through `TaskFactory`, ensuring safety while granting full access to `yt-dlp`'s extensive feature set.

---

## 7. Troubleshooting & FAQ

### Q: Why do I see "Pure Dart Engine" instead of "yt-dlp"?
**A**: On mobile platforms (iOS/Android), MediaGrab uses the pure Dart engine to comply with operating system sandboxes. On desktop platforms (macOS/Windows/Linux), ensure `yt-dlp` is installed on your system `PATH`. You can install it using Homebrew (`brew install yt-dlp`) on macOS or Winget (`winget install yt-dlp`) on Windows.

### Q: Why is a video failing to download?
**A**: 
1. Ensure your internet connection is active.
2. Check if the video is private, region-restricted, or requires login credentials.
3. Update `yt-dlp` to the latest version, as video platforms frequently update their streaming protocols.

### Q: Can I download an entire playlist?
**A**: Yes. Simply paste the playlist URL into the Home screen input. MediaGrab will detect the playlist structure and allow you to download all items or specific ranges.
