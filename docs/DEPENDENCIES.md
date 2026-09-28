# Third-Party Dependencies & Licenses

MediaGrab is built on top of outstanding open-source libraries and utilities. This document outlines the key runtime packages, build tools, external binaries, and their respective licenses.

---

## Direct Flutter / Dart Dependencies

| Package | Version | License | Primary Purpose |
| :--- | :--- | :--- | :--- |
| [`flutter`](https://flutter.dev) | SDK | BSD-3-Clause | Core cross-platform UI framework |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | `^2.6.1` | MIT | Reactive, compile-safe state management across the application |
| [`dynamic_color`](https://pub.dev/packages/dynamic_color) | `^1.7.0` | Apache-2.0 | Material You / Android 12+ wallpaper accent extraction |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | `^6.2.1` | Apache-2.0 | High-legibility typography (JetBrains Mono, Inter) |
| [`youtube_explode_dart`](https://pub.dev/packages/youtube_explode_dart) | `^2.3.6` | MIT | Pure Dart media stream extraction engine (universal/iOS) |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | `^2.3.5` | BSD-3-Clause | Persistent user preferences, theme options, and custom presets |
| [`path_provider`](https://pub.dev/packages/path_provider) | `^2.1.5` | BSD-3-Clause | Platform filesystem directory location discovery |
| [`path`](https://pub.dev/packages/path) | `^1.9.1` | BSD-3-Clause | Filesystem path manipulation and sanitization |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | `^6.3.1` | BSD-3-Clause | Launching external documentation and web links |
| [`share_plus`](https://pub.dev/packages/share_plus) | `^10.1.4` | BSD-3-Clause | Cross-platform native system share sheet integration |
| [`uuid`](https://pub.dev/packages/uuid) | `^4.5.1` | MIT | Unique task and command preset ID generation |
| [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) | `^22.3.1` | BSD-3-Clause | Native notification dispatch upon task completion |
| [`window_manager`](https://pub.dev/packages/window_manager) | `^0.5.2` | MIT | Desktop window chrome, resizing, and positioning control |

---

## Development & Testing Dependencies

| Package | Version | License | Primary Purpose |
| :--- | :--- | :--- | :--- |
| [`flutter_test`](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html) | SDK | BSD-3-Clause | Unit, widget, and layout testing framework |
| [`flutter_lints`](https://pub.dev/packages/flutter_lints) | `^6.0.0` | BSD-3-Clause | Official Flutter static analysis and lint rule set |

---

## External Runtime Engines & Tools

On desktop environments (macOS, Windows, Linux), MediaGrab can leverage external binaries for extended extraction capabilities:

| Utility | License | Usage & Attribution |
| :--- | :--- | :--- |
| [**yt-dlp**](https://github.com/yt-dlp/yt-dlp) | The Unlicense | Subprocess extraction engine supporting over 1,800 media sites, format selection, and metadata parsing. |
| [**ffmpeg**](https://ffmpeg.org) | LGPL 2.1+ / GPL 2.0+ | Transcoding media streams, container muxing (MP4, MKV, WebM), audio conversion, and ID3 cover art embedding. |
| [**aria2**](https://aria2.github.io) | GPL 2.0+ | Multi-connection external download accelerator integrated via `--downloader aria2c`. |

---

## License Compliance Notice

MediaGrab itself is licensed under the [GNU General Public License v3.0 (GPL-3.0)](../LICENSE). All third-party libraries incorporated into this project retain their original licenses and copyrights. Users distributing packaged binaries must ensure compliance with respective licenses, particularly when bundling optional GPL or LGPL binaries such as `ffmpeg` and `aria2c`.
