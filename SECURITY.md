# Security Policy

## Supported Versions

We actively maintain and provide security patches for the following versions of MediaGrab:

| Version | Supported          | Status             |
| ------- | ------------------ | ------------------ |
| 1.0.x   | :white_check_mark: | Active support     |
| < 1.0.0 | :x:                | Unsupported        |

---

## Reporting a Vulnerability

We take the security of MediaGrab and its users seriously. If you believe you have found a security vulnerability in MediaGrab, please follow the responsible disclosure process below:

### 1. How to Report
- **Preferred Method**: Submit a private advisory report directly via [GitHub Security Advisory](https://github.com/raffayalizafar/MediaGrab/security/advisories/new).
- Please **do not** open a public issue or discuss the vulnerability publicly until a patch has been published and released.

### 2. Information to Include
To help us triage and resolve the issue quickly, please include:
- A detailed description of the vulnerability.
- The affected component or file (e.g., download engine, template sanitizer, path provider).
- Steps to reproduce the issue or a proof-of-concept (PoC).
- Potential impact and severity (e.g., arbitrary code execution, path traversal, sensitive data leak).
- The operating system and MediaGrab version tested.

### 3. Response & Timeline
- **Acknowledgment**: We aim to acknowledge reports within 48 to 72 hours.
- **Investigation & Patch**: We will investigate the root cause, determine severity, and prepare a fix on a private branch.
- **Coordinated Disclosure**: Once a fix is verified and packaged into a release, we will publish the release notes and credit the reporter (unless you request anonymity).

---

## Scope & Out-of-Scope Items

### In Scope
- Arbitrary command injection or CLI parameter injection through URL inputs or custom command templates.
- Path traversal or unauthorized arbitrary file writes when saving downloaded media.
- Improper data handling, credential leakage, or insecure temporary file permissions.
- Insecure IPC or local socket vulnerabilities (e.g., aria2c RPC configurations).

### Out of Scope
- Bugs, extraction failures, or rate-limiting caused by upstream streaming platforms altering their APIs.
- Upstream vulnerabilities in `yt-dlp` or `ffmpeg` that have already been reported upstream and are pending vendor release.
- Physical attacks requiring root or unlocked physical access to the user's personal device.
- Attacks relying on social engineering or malicious user tampering with their own local configuration files.
