import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/journal_entry.dart';
import 'journal_entry_detail.dart';
import 'add_find_sheet.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _db = DatabaseHelper();
  List<JournalEntry> _entries = [];
  bool _loading = true;
  String _sortBy = 'date'; // 'date' | 'name'

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final entries = await _db.getJournalEntries();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  List<JournalEntry> get _sortedEntries {
    final list = List<JournalEntry>.from(_entries);
    if (_sortBy == 'name') {
      list.sort((a, b) => a.speciesName.compareTo(b.speciesName));
    }
    // 'date' is already sorted by DB (found_at DESC)
    return list;
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this find?'),
        content: Text('Remove ${entry.speciesName} from your journal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteJournalEntry(entry.id);
      // Also delete local photo if exists
      if (entry.hasPhoto) {
        final file = File(entry.photoPath!);
        if (await file.exists()) await file.delete();
      }
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
      }
    }
  }

  void _openAddFind() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFindSheet(),
    );
    if (added == true) await _loadEntries();
  }

  void _openDetail(JournalEntry entry) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => JournalEntryDetail(entry: entry)),
    );
    if (changed == true) await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('My Finds'),
        automaticallyImplyLeading: false,
        actions: [
          if (_entries.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort_outlined),
              tooltip: 'Sort',
              onSelected: (v) => setState(() => _sortBy = v),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 16,
                        color: _sortBy == 'date'
                            ? AppTheme.forestGreen
                            : Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sort by date',
                        style: TextStyle(
                          color: _sortBy == 'date'
                              ? AppTheme.forestGreen
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sort_by_alpha_outlined,
                        size: 16,
                        color: _sortBy == 'name'
                            ? AppTheme.forestGreen
                            : Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sort by name',
                        style: TextStyle(
                          color: _sortBy == 'name'
                              ? AppTheme.forestGreen
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddFind,
        backgroundColor: AppTheme.forestGreen,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Log a find'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.forestGreen),
            )
          : _entries.isEmpty
          ? _buildEmptyState()
          : _buildJournalList(),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.forestGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.book_outlined,
                size: 44,
                color: AppTheme.forestGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your foraging journal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Record every species you find with a photo, '
              'location and notes. Build your personal field diary.',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _openAddFind,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text(
                'Log your first find',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Journal list ─────────────────────────────────────────────────────────
  Widget _buildJournalList() {
    final entries = _sortedEntries;

    // Group by month-year when sorted by date
    if (_sortBy == 'date') {
      return _buildGroupedList(entries);
    }

    return RefreshIndicator(
      color: AppTheme.forestGreen,
      onRefresh: _loadEntries,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _buildStatsRow(entries),
          const SizedBox(height: 16),
          ...entries.map((e) => _buildEntryCard(e)),
        ],
      ),
    );
  }

  Widget _buildGroupedList(List<JournalEntry> entries) {
    // Group entries by month
    final groups = <String, List<JournalEntry>>{};
    for (final e in entries) {
      final key = DateFormat('MMMM yyyy').format(e.foundAt);
      groups.putIfAbsent(key, () => []).add(e);
    }

    return RefreshIndicator(
      color: AppTheme.forestGreen,
      onRefresh: _loadEntries,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _buildStatsRow(entries),
          const SizedBox(height: 16),
          ...groups.entries.expand(
            (group) => [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  group.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...group.value.map((e) => _buildEntryCard(e)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stats row at top ─────────────────────────────────────────────────────
  Widget _buildStatsRow(List<JournalEntry> entries) {
    final withPhoto = entries.where((e) => e.hasPhoto).length;
    final withLocation = entries.where((e) => e.hasLocation).length;
    final uniqueNames = entries.map((e) => e.speciesName).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _statChip(
            entries.length.toString(),
            'Total finds',
            AppTheme.forestGreen,
            Icons.eco_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statChip(
            uniqueNames.toString(),
            'Species',
            AppTheme.earthBrown,
            Icons.category_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statChip(
            withPhoto.toString(),
            'With photo',
            Colors.blueGrey,
            Icons.photo_camera_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statChip(
            withLocation.toString(),
            'Located',
            AppTheme.safeGreen,
            Icons.location_on_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statChip(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

  // ─── Entry card ───────────────────────────────────────────────────────────
  Widget _buildEntryCard(JournalEntry entry) {
    return Dismissible(
      key: Key('entry_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.dangerRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        await _deleteEntry(entry);
        return false; // we handle deletion ourselves
      },
      child: GestureDetector(
        onTap: () => _openDetail(entry),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Photo or placeholder
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: entry.hasPhoto
                      ? Image.file(
                          File(entry.photoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.speciesName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            size: 12,
                            color: Colors.black38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(entry.foundAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (entry.hasLocation) ...[
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppTheme.forestGreen,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${entry.latitude!.toStringAsFixed(3)}, '
                              '${entry.longitude!.toStringAsFixed(3)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.forestGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (entry.hasNote)
                            const Icon(
                              Icons.notes_outlined,
                              size: 12,
                              color: Colors.black38,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
    color: AppTheme.forestGreen.withOpacity(0.08),
    child: const Center(
      child: Icon(Icons.eco_outlined, color: AppTheme.forestGreen, size: 32),
    ),
  );

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('d MMM yyyy').format(dt);
  }
}
