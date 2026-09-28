import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../models/command_template.dart';

/// Modal dialog to create or edit a custom yt-dlp command template.
class TemplateEditorDialog extends StatefulWidget {
  final CommandTemplate? initialTemplate;

  const TemplateEditorDialog({super.key, this.initialTemplate});

  @override
  State<TemplateEditorDialog> createState() => _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends State<TemplateEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _argsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialTemplate?.name ?? '',
    );
    _descController = TextEditingController(
      text: widget.initialTemplate?.description ?? '',
    );
    _argsController = TextEditingController(
      text: widget.initialTemplate?.templateArgs ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _argsController.dispose();
    super.dispose();
  }

  void _appendArg(String arg) {
    final current = _argsController.text.trim();
    if (current.isEmpty) {
      _argsController.text = arg;
    } else {
      _argsController.text = '$current $arg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTemplate != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    return AlertDialog(
      backgroundColor: isDark
          ? (isAmoled ? const Color(0xFF0D0D0D) : AppColors.slate900)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? (isAmoled ? const Color(0xFF222222) : AppColors.slate800)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: AppColors.indigo400,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Edit Command Recipe' : 'New Command Recipe',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Template Name
                _buildFieldLabel('Recipe Name *', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'e.g. 1080p MP4 with Embedded Subtitles',
                    isDark: isDark,
                    isAmoled: isAmoled,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Name required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Description
                _buildFieldLabel('Description', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descController,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                  decoration: _buildInputDecoration(
                    hint: 'Brief summary of what this execution profile does',
                    isDark: isDark,
                    isAmoled: isAmoled,
                  ),
                ),
                const SizedBox(height: 14),

                // yt-dlp Arguments
                _buildFieldLabel('yt-dlp Arguments *', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _argsController,
                  maxLines: 3,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: AppColors.sky400,
                  ),
                  decoration: _buildInputDecoration(
                    hint: '-S res:1080 --write-subs --embed-subs',
                    isDark: isDark,
                    isAmoled: isAmoled,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Arguments required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Quick Insert Flag Chips
                Text(
                  'QUICK INSERT FLAGS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.slate400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildInsertChip('-S res:1080', isDark),
                    _buildInsertChip('--write-subs --embed-subs', isDark),
                    _buildInsertChip('-x --audio-format mp3', isDark),
                    _buildInsertChip('--embed-thumbnail', isDark),
                    _buildInsertChip('--sponsorblock-remove all', isDark),
                    _buildInsertChip('--downloader aria2c', isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? AppColors.slate400 : Colors.grey.shade600,
            ),
          ),
        ),
        AnimatedPressable(
          onTap: () {
            if (_formKey.currentState?.validate() ?? false) {
              final result = CommandTemplate(
                id: widget.initialTemplate?.id ?? '',
                name: _nameController.text.trim(),
                description: _descController.text.trim(),
                templateArgs: _argsController.text.trim(),
                isBuiltIn: false,
              );
              Navigator.pop(context, result);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.indigo500, AppColors.indigo600],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Save Recipe',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.slate300 : AppColors.slate800,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required bool isDark,
    bool isAmoled = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: isDark ? AppColors.slate500 : Colors.grey.shade400,
      ),
      filled: true,
      fillColor: isDark
          ? (isAmoled ? Colors.black : AppColors.slate950)
          : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? (isAmoled ? const Color(0xFF222222) : AppColors.slate800)
              : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? (isAmoled ? const Color(0xFF222222) : AppColors.slate800)
              : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.indigo500, width: 1.5),
      ),
    );
  }

  Widget _buildInsertChip(String text, bool isDark) {
    return AnimatedPressable(
      onTap: () => _appendArg(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.slate800.withValues(alpha: 0.6)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.slate700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 13, color: AppColors.indigo400),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.slate300 : AppColors.slate800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
