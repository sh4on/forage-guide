import 'package:flutter/material.dart';
import '../core/theme.dart';

class SafetyBadge extends StatelessWidget {
  final String status;
  final bool large;
  const SafetyBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'edible' => ('Edible', AppTheme.safeGreen, Icons.check_circle_outline),
      'toxic' => ('Toxic', AppTheme.dangerRed, Icons.dangerous_outlined),
      'caution' => (
        'Caution',
        AppTheme.warningAmber,
        Icons.warning_amber_rounded,
      ),
      _ => ('Unknown', Colors.grey, Icons.help_outline),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(large ? 10 : 6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: large ? 18 : 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: large ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
