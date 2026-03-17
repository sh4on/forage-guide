import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/species.dart';
import '../models/journal_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'forage_guide.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Cache for recently viewed species (offline support)
        await db.execute('''
          CREATE TABLE species_cache (
            id               INTEGER PRIMARY KEY,
            common_name      TEXT NOT NULL,
            scientific_name  TEXT NOT NULL,
            photo_url        TEXT,
            wiki_summary     TEXT,
            wiki_url         TEXT,
            edibility        TEXT NOT NULL,
            edibility_reason TEXT,
            tags             TEXT,
            observations     INTEGER,
            iconic_taxon     TEXT,
            matched_term     TEXT,
            photo_attr       TEXT,
            photo_license    TEXT,
            cached_at        INTEGER NOT NULL
          )
        ''');

        // User's personal finds journal
        await db.execute('''
          CREATE TABLE journal_entries (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            species_id  INTEGER NOT NULL,
            species_name TEXT NOT NULL,
            photo_path  TEXT,
            note        TEXT,
            latitude    REAL,
            longitude   REAL,
            found_at    INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ─── Cache a species locally ──────────────────────────────────────────────
  Future<void> cacheSpecies(Species species) async {
    final db = await database;
    final map = species.toMap();
    map['cached_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'species_cache',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Get cached species by ID ─────────────────────────────────────────────
  Future<Species?> getCachedSpecies(int id) async {
    final db = await database;
    final results = await db.query(
      'species_cache',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Species.fromMap(results.first);
  }

  // ─── Get all cached species (for offline browsing) ───────────────────────
  Future<List<Species>> getAllCached() async {
    final db = await database;
    final results = await db.query(
      'species_cache',
      orderBy: 'cached_at DESC',
      limit: 50,
    );
    return results.map((r) => Species.fromMap(r)).toList();
  }

  // ─── Journal: save a find ─────────────────────────────────────────────────
  Future<int> saveJournalEntry({
    required int speciesId,
    required String speciesName,
    String? photoPath,
    String? note,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;
    return db.insert('journal_entries', {
      'species_id': speciesId,
      'species_name': speciesName,
      'photo_path': photoPath,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'found_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ─── Journal: get all entries ─────────────────────────────────────────────
  Future<List<JournalEntry>> getJournalEntries() async {
    final db = await database;
    final rows = await db.query('journal_entries', orderBy: 'found_at DESC');
    return rows.map((r) => JournalEntry.fromMap(r)).toList();
  }

  // ─── Journal: delete an entry ─────────────────────────────────────────────
  Future<void> deleteJournalEntry(int id) async {
    final db = await database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }
}
