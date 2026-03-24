import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

Future<void> showExitAlertDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app_rounded,
                  size: 32,
                  color: AppTheme.forestGreen,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                'Exit ForageGuide',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // Description
              const Text(
                'Are you sure you want to exit?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Exit
                  Expanded(
                    child: ElevatedButton(
                      onPressed: SystemNavigator.pop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.forestGreen,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
