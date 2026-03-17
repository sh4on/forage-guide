import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../data/api/inaturalist_api.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/species.dart';

class AddFindSheet extends StatefulWidget {
  const AddFindSheet({super.key});

  @override
  State<AddFindSheet> createState() => _AddFindSheetState();
}

class _AddFindSheetState extends State<AddFindSheet> {
  final _db = DatabaseHelper();
  final _api = INaturalistApi();
  final _noteCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _picker = ImagePicker();

  File? _photo;
  Species? _selectedSpecies;
  Position? _position;
  List<Species> _searchResults = [];

  bool _loadingLocation = false;
  bool _loadingSearch = false;
  bool _saving = false;
  bool _useLocation = true;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  // ─── Photo ────────────────────────────────────────────────────────────────
  Future<void> _takePhoto() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (xFile != null) setState(() => _photo = File(xFile.path));
  }

  Future<void> _pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (xFile != null) setState(() => _photo = File(xFile.path));
  }

  // ─── Location ─────────────────────────────────────────────────────────────
  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _loadingLocation = false;
          _useLocation = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        _position = pos;
        _loadingLocation = false;
      });
    } catch (_) {
      setState(() {
        _loadingLocation = false;
        _useLocation = false;
      });
    }
  }

  // ─── Species search ───────────────────────────────────────────────────────
  Future<void> _searchSpecies(String q) async {
    if (q.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _loadingSearch = true;
      _searchError = null;
    });
    try {
      final results = await _api.searchSpecies(q);
      setState(() {
        _searchResults = results;
        _loadingSearch = false;
      });
    } catch (_) {
      setState(() {
        _searchError = 'Search failed';
        _loadingSearch = false;
      });
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_selectedSpecies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a species first')),
      );
      return;
    }

    setState(() => _saving = true);

    await _db.saveJournalEntry(
      speciesId: _selectedSpecies!.id,
      speciesName: _selectedSpecies!.commonName,
      photoPath: _photo?.path,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      latitude: _useLocation ? _position?.latitude : null,
      longitude: _useLocation ? _position?.longitude : null,
    );

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Log a find',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 20),
                  _buildSpeciesSearch(),
                  const SizedBox(height: 20),
                  _buildLocationSection(),
                  const SizedBox(height: 20),
                  _buildNotesSection(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Photo section ────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Photo', Icons.photo_camera_outlined),
        const SizedBox(height: 10),
        if (_photo != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _photo!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _photo = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _photoButton(
                  Icons.camera_alt_outlined,
                  'Camera',
                  _takePhoto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _photoButton(
                  Icons.photo_library_outlined,
                  'Gallery',
                  _pickFromGallery,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _photoButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppTheme.forestGreen.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.forestGreen.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.forestGreen, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.forestGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Species search ───────────────────────────────────────────────────────
  Widget _buildSpeciesSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Species *', Icons.search_outlined),
        const SizedBox(height: 10),

        // Selected species pill
        if (_selectedSpecies != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.forestGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.forestGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.eco_outlined,
                  color: AppTheme.forestGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSpecies!.commonName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _selectedSpecies!.scientificName,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedSpecies = null;
                    _searchCtrl.clear();
                    _searchResults = [];
                  }),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          )
        else ...[
          TextField(
            controller: _searchCtrl,
            onChanged: _searchSpecies,
            decoration: InputDecoration(
              hintText: 'Search species name...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.forestGreen),
              suffixIcon: _loadingSearch
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: _searchResults.take(5).toList().asMap().entries.map((
                  e,
                ) {
                  final s = e.value;
                  return Column(
                    children: [
                      if (e.key > 0) const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.eco_outlined,
                          color: AppTheme.forestGreen,
                          size: 20,
                        ),
                        title: Text(
                          s.commonName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          s.scientificName,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => setState(() {
                          _selectedSpecies = s;
                          _searchCtrl.clear();
                          _searchResults = [];
                        }),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _searchError!,
                style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12),
              ),
            ),
        ],
      ],
    );
  }

  // ─── Location section ─────────────────────────────────────────────────────
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('Location', Icons.location_on_outlined),
            const Spacer(),
            Switch.adaptive(
              value: _useLocation,
              activeColor: AppTheme.forestGreen,
              onChanged: (v) => setState(() => _useLocation = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_useLocation)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _position != null
                  ? AppTheme.safeGreen.withOpacity(0.06)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _position != null
                    ? AppTheme.safeGreen.withOpacity(0.3)
                    : Colors.black12,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                _loadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.forestGreen,
                        ),
                      )
                    : Icon(
                        _position != null
                            ? Icons.location_on
                            : Icons.location_off_outlined,
                        color: _position != null
                            ? AppTheme.safeGreen
                            : Colors.black38,
                        size: 18,
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _loadingLocation
                        ? 'Getting location...'
                        : _position != null
                        ? 'GPS: ${_position!.latitude.toStringAsFixed(4)}, '
                              '${_position!.longitude.toStringAsFixed(4)}'
                        : 'Location unavailable',
                    style: TextStyle(
                      fontSize: 13,
                      color: _position != null
                          ? AppTheme.safeGreen
                          : Colors.black38,
                    ),
                  ),
                ),
                if (!_loadingLocation)
                  TextButton(
                    onPressed: _getLocation,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Refresh',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Notes section ────────────────────────────────────────────────────────
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Notes', Icons.notes_outlined),
        const SizedBox(height: 10),
        TextField(
          controller: _noteCtrl,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText:
                'Where did you find it? What did it look like?\nAny other observations...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // ─── Save button ──────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.forestGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save to journal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.forestGreen),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
