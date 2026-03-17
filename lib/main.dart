import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final seenDisclaimer = prefs.getBool('seen_disclaimer') ?? false;
  runApp(ForageGuideApp(seenDisclaimer: seenDisclaimer));
}

class ForageGuideApp extends StatelessWidget {
  final bool seenDisclaimer;
  const ForageGuideApp({super.key, required this.seenDisclaimer});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ForageGuide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: seenDisclaimer ? '/home' : '/disclaimer',
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
