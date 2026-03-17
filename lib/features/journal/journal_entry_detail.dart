import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/journal_entry.dart';

class JournalEntryDetail extends StatefulWidget {
  final JournalEntry entry;
  const JournalEntryDetail({super.key, required this.entry});

  @override
  State<JournalEntryDetail> createState() => _JournalEntryDetailState();
}

class _JournalEntryDetailState extends State<JournalEntryDetail> {
  final _db = DatabaseHelper();
  final _noteCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl.text = widget.entry.note ?? '';
  }

  Future<void> _saveNote() async {
    setState(() => _saving = true);
    // Update note in DB
    final db = await _db.database;
    await db.update(
      'journal_entries',
      {'note': _noteCtrl.text.trim()},
      where: 'id = ?',
      whereArgs: [widget.entry.id],
    );
    setState(() {
      _saving = false;
      _editing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note saved')));
      Navigator.pop(context, true); // signal refresh
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this find?'),
        content: Text('Remove ${widget.entry.speciesName} from your journal?'),
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
      await _db.deleteJournalEntry(widget.entry.id);
      if (widget.entry.hasPhoto) {
        final f = File(widget.entry.photoPath!);
        if (await f.exists()) await f.delete();
      }
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(entry.speciesName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit note',
            onPressed: () => setState(() => _editing = !_editing),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            if (entry.hasPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(entry.photoPath!),
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppTheme.forestGreen.withOpacity(0.1),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppTheme.forestGreen,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Species name card
            _infoCard(
              children: [
                Row(
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
                          const Text(
                            'Species',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.speciesName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date + location card
            _infoCard(
              children: [
                _detailRow(
                  Icons.access_time_outlined,
                  'Found on',
                  DateFormat('EEEE, d MMMM yyyy  HH:mm').format(entry.foundAt),
                ),
                if (entry.hasLocation) ...[
                  const Divider(height: 20),
                  _detailRow(
                    Icons.location_on_outlined,
                    'Location',
                    '${entry.latitude!.toStringAsFixed(5)}, '
                        '${entry.longitude!.toStringAsFixed(5)}',
                    color: AppTheme.forestGreen,
                  ),
                  const SizedBox(height: 8),
                  // Open in maps button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // url_launcher opens maps — implement in Phase 5
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Map link coming in next update'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('View on map'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.forestGreen,
                        side: BorderSide(
                          color: AppTheme.forestGreen.withOpacity(0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Notes card
            _infoCard(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notes_outlined,
                      color: AppTheme.forestGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (!_editing)
                      GestureDetector(
                        onTap: () => setState(() => _editing = true),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_editing) ...[
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 5,
                    maxLength: 500,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Add your notes...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _editing = false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saving ? null : _saveNote,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.forestGreen,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    (entry.note?.isNotEmpty == true)
                        ? entry.note!
                        : 'No notes added. Tap Edit to add some.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: entry.note?.isNotEmpty == true
                          ? Colors.black87
                          : Colors.black38,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.dangerRed,
                  size: 18,
                ),
                label: const Text(
                  'Delete this find',
                  style: TextStyle(color: AppTheme.dangerRed),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.dangerRed.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.black38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: color ?? Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
