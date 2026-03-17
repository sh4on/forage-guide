import 'package:flutter/foundation.dart';
import '../../data/api/inaturalist_api.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/species.dart';

class AppSearchController extends ChangeNotifier {
  final _api = INaturalistApi();
  final _db = DatabaseHelper();

  List<Species> results = [];
  List<Species> recent = [];
  bool isLoading = false;
  String? error;
  String _lastQuery = '';

  AppSearchController() {
    loadRecent();
  }

  Future<void> loadRecent() async {
    final cached = await _db.getAllCached();
    recent = cached.take(5).toList();
    notifyListeners();
  }

  Future<void> search(String query) async {
    final q = query.trim();
    if (q == _lastQuery || q.isEmpty) return;
    _lastQuery = q;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      results = await _api.searchSpecies(q);
      isLoading = false;
    } catch (e) {
      error = 'Search failed. Check your connection.';
      isLoading = false;
    }
    notifyListeners();
  }

  void clear() {
    results = [];
    _lastQuery = '';
    error = null;
    notifyListeners();
  }
}
