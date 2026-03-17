import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'theme.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  Future<void> _accept(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keySeenDisclaimer, true);
    if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: AppTheme.forestGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Before you forage',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forestGreen,
                ),
              ),
              const SizedBox(height: 16),
              _point(
                Icons.warning_amber_rounded,
                AppTheme.warningAmber,
                'Never eat anything based solely on this app.',
                'Wild foraging requires expert knowledge. This app is a guide, not a guarantee.',
              ),
              const SizedBox(height: 12),
              _point(
                Icons.person_search_outlined,
                AppTheme.forestGreen,
                'Always verify with a local expert.',
                'Many edible species have toxic lookalikes. When in doubt, do not eat it.',
              ),
              const SizedBox(height: 12),
              _point(
                Icons.local_hospital_outlined,
                AppTheme.dangerRed,
                'If you feel ill after foraging, seek medical help immediately.',
                'Tell the doctor what you consumed and when.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _accept(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "I understand — let's forage",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By continuing you agree this app is for educational purposes only.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _point(IconData icon, Color color, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
