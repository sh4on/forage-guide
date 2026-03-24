import 'package:flutter/material.dart';
import 'package:forage_guide/widgets/exit_alert_dialog.dart';
import '../features/search/search_screen.dart';
import '../features/nearby/nearby_screen.dart';
import '../features/journal/journal_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [SearchScreen(), NearbyScreen(), JournalScreen()];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          showExitAlertDialog(context);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.forestGreen.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppTheme.forestGreen),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(
                Icons.location_on,
                color: AppTheme.forestGreen,
              ),
              label: 'Nearby',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book, color: AppTheme.forestGreen),
              label: 'My Finds',
            ),
          ],
        ),
      ),
    );
  }
}
