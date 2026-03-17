import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/species.dart';
import '../../core/constants.dart';

class INaturalistApi {
  static final INaturalistApi _instance = INaturalistApi._internal();
  factory INaturalistApi() => _instance;
  INaturalistApi._internal();

  final _client = http.Client();

  Future<List<Species>> searchSpecies(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('${AppConstants.iNatBaseUrl}/taxa').replace(
      queryParameters: {
        'q': query,
        'rank': 'species',
        'per_page': AppConstants.searchPageSize.toString(),
        'page': page.toString(),
        'locale': 'en',
        'iconic_taxa': 'Plantae,Fungi',
      },
    );

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Search failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    debugPrint('🚨 [$uri]');
    log(const JsonEncoder.withIndent('  ').convert(data), name: '🚨 RESPONSE');

    final results = (data['results'] as List? ?? []);
    return results
        .map((r) => Species.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Species>> getNearbySpecies({
    required double lat,
    required double lng,
    int radiusKm = 10,
  }) async {
    final uri = Uri.parse('${AppConstants.iNatBaseUrl}/observations').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radiusKm.toString(),
        'order_by': 'observed_on',
        'per_page': '30',
        'iconic_taxa': 'Plantae,Fungi',
        'quality_grade': 'research',
        'locale': 'en',
      },
    );

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Nearby fetch failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List? ?? []);

    final seen = <int>{};
    final species = <Species>[];
    for (final obs in results) {
      final taxon = obs['taxon'];
      if (taxon == null) continue;
      final id = taxon['id'] as int?;
      if (id == null || seen.contains(id)) continue;
      seen.add(id);
      species.add(Species.fromJson(taxon as Map<String, dynamic>));
    }
    return species;
  }
}
