import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';
import '../../data/api/inaturalist_api.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/species.dart';
import '../../widgets/species_card.dart';
import '../../widgets/safety_badge.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final _api = INaturalistApi();
  final _db = DatabaseHelper();

  GoogleMapController? _mapController;

  Position? _position;
  List<Species> _species = [];
  Set<Marker> _markers = {};
  bool _loadingGps = false;
  bool _loadingSpecies = false;
  String? _error;
  int _radiusKm = 10;
  NearbyViewMode _viewMode = NearbyViewMode.list;

  // Filters
  String _filterType = 'All'; // 'All' | 'Fungi' | 'Plantae'

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  // ─── Location ─────────────────────────────────────────────────────────────
  Future<void> _loadLocation() async {
    setState(() {
      _loadingGps = true;
      _error = null;
    });

    try {
      // Check permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _error =
              'Location permission permanently denied.\nPlease enable it in app settings.';
          _loadingGps = false;
        });
        return;
      }
      if (perm == LocationPermission.denied) {
        setState(() {
          _error = 'Location permission denied.';
          _loadingGps = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _position = pos;
        _loadingGps = false;
      });

      // Move map camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 12),
      );

      await _loadNearbySpecies();
    } catch (e) {
      setState(() {
        _error = 'Could not get location. Check GPS is enabled.';
        _loadingGps = false;
      });
    }
  }

  // ─── Fetch nearby species from iNaturalist ────────────────────────────────
  Future<void> _loadNearbySpecies() async {
    if (_position == null) return;
    setState(() {
      _loadingSpecies = true;
      _error = null;
    });

    try {
      final results = await _api.getNearbySpecies(
        lat: _position!.latitude,
        lng: _position!.longitude,
        radiusKm: _radiusKm,
      );

      // Build map markers
      final markers = <Marker>{};

      // User location marker
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(_position!.latitude, _position!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );

      setState(() {
        _species = results;
        _markers = markers;
        _loadingSpecies = false;
      });

      // Cache all nearby species for offline use
      for (final s in _species) {
        await _db.cacheSpecies(s);
      }
    } catch (e) {
      setState(() {
        _error = 'Could not load nearby species. Check your connection.';
        _loadingSpecies = false;
      });
    }
  }

  List<Species> get _filteredSpecies {
    if (_filterType == 'All') return _species;
    return _species.where((s) => s.iconicTaxonName == _filterType).toList();
  }

  void _openSpecies(Species s) {
    _db.cacheSpecies(s);
    Navigator.pushNamed(context, '/species', arguments: s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Nearby Species'),
        actions: [
          // Toggle map / list view
          // IconButton(
          //   icon: Icon(
          //     _viewMode == NearbyViewMode.list
          //         ? Icons.map_outlined
          //         : Icons.list_outlined,
          //   ),
          //   tooltip: _viewMode == NearbyViewMode.list
          //       ? 'Show map'
          //       : 'Show list',
          //   onPressed: () => setState(() {
          //     _viewMode = _viewMode == NearbyViewMode.list
          //         ? NearbyViewMode.map
          //         : NearbyViewMode.list;
          //   }),
          // ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _loadLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          _buildRadiusFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── Top status bar ───────────────────────────────────────────────────────
  Widget _buildStatusBar() {
    if (_loadingGps) {
      return _banner(
        AppTheme.forestGreen.withValues(alpha: 0.1),
        Icons.location_searching_outlined,
        AppTheme.forestGreen,
        'Getting your location...',
      );
    }
    if (_error != null) {
      return _banner(
        AppTheme.dangerRed.withValues(alpha: 0.08),
        Icons.error_outline,
        AppTheme.dangerRed,
        _error!,
        action: TextButton(
          onPressed: _loadLocation,
          child: const Text('Retry'),
        ),
      );
    }
    if (_position != null && !_loadingSpecies) {
      final count = _filteredSpecies.length;
      return _banner(
        AppTheme.safeGreen.withValues(alpha: 0.08),
        Icons.location_on_outlined,
        AppTheme.safeGreen,
        count > 0
            ? '$count species found within $_radiusKm km of you'
            : 'No species recorded nearby — try a larger radius',
      );
    }
    if (_loadingSpecies) {
      return _banner(
        AppTheme.forestGreen.withValues(alpha: 0.08),
        Icons.search_outlined,
        AppTheme.forestGreen,
        'Searching for species nearby...',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _banner(
    Color bg,
    IconData icon,
    Color iconColor,
    String text, {
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bg,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // ─── Radius + type filter ─────────────────────────────────────────────────
  Widget _buildRadiusFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Radius selector
          const Text(
            'Radius:',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          ...[5, 10, 25, 50].map(
            (km) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text('${km}km'),
                selected: _radiusKm == km,
                selectedColor: AppTheme.forestGreen.withValues(alpha: 0.2),
                onSelected: (_) {
                  setState(() => _radiusKm = km);
                  _loadNearbySpecies();
                },

                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _radiusKm == km
                      ? AppTheme.forestGreen
                      : Colors.black54,
                  fontWeight: _radiusKm == km
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
          const Spacer(),
          // Type filter
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filterType,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Fungi', child: Text('Fungi only')),
                DropdownMenuItem(value: 'Plantae', child: Text('Plants only')),
              ],
              onChanged: (v) => setState(() => _filterType = v ?? 'All'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main body ────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loadingGps || _loadingSpecies) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.forestGreen),
      );
    }

    if (_error != null && _position == null) {
      return _buildPermissionError();
    }

    if (_viewMode == NearbyViewMode.map) {
      return _buildMapView();
    }

    return _buildListView();
  }

  // ─── Map view ─────────────────────────────────────────────────────────────
  Widget _buildMapView() {
    final center = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : const LatLng(51.5, -0.12); // Default: London

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 12),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
        if (_position != null) {
          controller.animateCamera(CameraUpdate.newLatLngZoom(center, 12));
        }
      },
    );
  }

  // ─── List view ────────────────────────────────────────────────────────────
  Widget _buildListView() {
    final species = _filteredSpecies;

    if (species.isEmpty && _position != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No species found nearby',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing the radius or changing the filter',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _radiusKm = 50);
                _loadNearbySpecies();
              },
              icon: const Icon(Icons.expand_outlined),
              label: const Text('Expand to 50 km'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.forestGreen,
      onRefresh: _loadNearbySpecies,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards at top
          if (_position != null && species.isNotEmpty)
            _buildSummaryCards(species),

          const SizedBox(height: 12),

          // Species list
          ...species.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SpeciesCard(
                species: e.value,
                onTap: () => _openSpecies(e.value),
              ),
            ),
          ),

          const SizedBox(height: 8),
          // Data attribution
          const Text(
            'Observation data from iNaturalist (inaturalist.org)',
            style: TextStyle(fontSize: 11, color: Colors.black38),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Summary stat cards ───────────────────────────────────────────────────
  Widget _buildSummaryCards(List<Species> species) {
    final fungi = species.where((s) => s.iconicTaxonName == 'Fungi').length;
    final plants = species.where((s) => s.iconicTaxonName == 'Plantae').length;
    final edible = species.where((s) => s.edibilityStatus == 'edible').length;
    final toxic = species.where((s) => s.edibilityStatus == 'toxic').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s around you',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                fungi.toString(),
                'Mushrooms',
                AppTheme.earthBrown,
                Icons.eco_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                plants.toString(),
                'Plants',
                AppTheme.forestGreen,
                Icons.local_florist_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                edible.toString(),
                'Edible',
                AppTheme.safeGreen,
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                toxic.toString(),
                'Toxic',
                AppTheme.dangerRed,
                Icons.dangerous_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black45),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Permission error state ───────────────────────────────────────────────
  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 64,
              color: Colors.black26,
            ),
            const SizedBox(height: 20),
            const Text(
              'Location access needed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'Please allow location access to see species near you.',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadLocation,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
              ),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Allow location access'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Geolocator.openAppSettings(),
              child: const Text('Open app settings'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

enum NearbyViewMode { list, map }
