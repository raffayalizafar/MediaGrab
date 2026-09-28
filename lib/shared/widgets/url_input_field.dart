import 'package:flutter/material.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/theme/app_colors.dart';
import 'animated_pressable.dart';

/// URL Input bar with quick paste and clear actions styled after the Stitch design.
class UrlInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onPaste;
  final VoidCallback? onClear;
  final String? errorText;
  final bool isBusy;

  const UrlInputField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onPaste,
    this.onClear,
    this.errorText,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      enabled: !isBusy,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.go,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Paste video, playlist, or audio link here...',
        hintStyle: TextStyle(
          color: isDark ? AppColors.slate500 : Colors.grey.shade500,
          fontSize: 14,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.link_rounded, color: AppColors.indigo400, size: 22),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
          minHeight: 46,
        ),
        errorText: errorText,
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  tooltip: 'Clear',
                  color: isDark ? AppColors.slate400 : Colors.grey.shade600,
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                ),
              AnimatedPressable(
                onTap: () async {
                  final clip = await ClipboardService.getClipboardText();
                  if (clip != null && clip.isNotEmpty) {
                    controller.text = clip;
                    onPaste?.call();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.slate800
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.slate700
                          : theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.content_paste_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.slate400
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Paste',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.slate300
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slate900 : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isDark
                                ? AppColors.slate700
                                : Colors.grey.shade300,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '⌘V',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: isDark
                                ? AppColors.slate400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
