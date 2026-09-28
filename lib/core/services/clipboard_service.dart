import 'package:flutter/services.dart';

/// Helper service for reading and checking URLs from the system clipboard.
class ClipboardService {
  /// Reads text from system clipboard, returns null if empty or non-text.
  static Future<String?> getClipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text?.trim();
    } catch (_) {
      return null;
    }
  }

  /// Copies text to clipboard.
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Checks if a string looks like a valid media / web URL.
  static bool isValidUrl(String text) {
    if (text.isEmpty) return false;
    final uri = Uri.tryParse(text);
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }
}
