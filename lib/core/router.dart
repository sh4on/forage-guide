import 'package:flutter/material.dart';
import '../features/search/search_screen.dart';
import '../features/species_detail/species_detail_screen.dart';
import '../features/nearby/nearby_screen.dart';
import '../features/journal/journal_screen.dart';
import '../data/models/species.dart';
import 'disclaimer_screen.dart';
import 'home_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    '/disclaimer': (_) => const DisclaimerScreen(),
    '/home': (_) => const HomeScreen(),
    '/search': (_) => const SearchScreen(),
    '/nearby': (_) => const NearbyScreen(),
    '/journal': (_) => const JournalScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/species') {
      final species = settings.arguments as Species;
      return MaterialPageRoute(
        builder: (_) => SpeciesDetailScreen(species: species),
      );
    }
    return MaterialPageRoute(builder: (_) => const HomeScreen());
  }
}
