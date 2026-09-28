import 'package:flutter/material.dart';
import 'animated_pressable.dart';

/// Selectable quality chip (e.g. 1080p, 720p, 480p).
class QualityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final String? subtitle;

  const QualityChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedPressable(
      child: FilterChip(
        selected: isSelected,
        label: subtitle != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Text(label),
        onSelected: onSelected,
        showCheckmark: true,
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.onSecondaryContainer
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
