class JournalEntry {
  final int id;
  final int speciesId;
  final String speciesName;
  final String? photoPath;
  final String? note;
  final double? latitude;
  final double? longitude;
  final DateTime foundAt;

  const JournalEntry({
    required this.id,
    required this.speciesId,
    required this.speciesName,
    this.photoPath,
    this.note,
    this.latitude,
    this.longitude,
    required this.foundAt,
  });

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;
  bool get hasNote => note != null && note!.isNotEmpty;

  factory JournalEntry.fromMap(Map<String, dynamic> map) => JournalEntry(
    id: map['id'] as int,
    speciesId: map['species_id'] as int,
    speciesName: map['species_name'] as String,
    photoPath: map['photo_path'] as String?,
    note: map['note'] as String?,
    latitude: map['latitude'] as double?,
    longitude: map['longitude'] as double?,
    foundAt: DateTime.fromMillisecondsSinceEpoch(map['found_at'] as int),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'species_id': speciesId,
    'species_name': speciesName,
    'photo_path': photoPath,
    'note': note,
    'latitude': latitude,
    'longitude': longitude,
    'found_at': foundAt.millisecondsSinceEpoch,
  };
}
