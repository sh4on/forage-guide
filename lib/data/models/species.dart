class Species {
  final int id;
  final String commonName;
  final String scientificName;
  final String? photoUrl;
  final String? wikipediaSummary;
  final String? wikipediaUrl;
  final String edibilityStatus; // 'edible' | 'toxic' | 'caution' | 'unknown'
  final String? edibilityReason;
  final List<String> tags;
  final int? observationsCount;
  final String? iconicTaxonName;
  final String? matchedTerm;
  final String? photoAttribution;
  final String? photoLicense;

  const Species({
    required this.id,
    required this.commonName,
    required this.scientificName,
    this.photoUrl,
    this.wikipediaSummary,
    this.wikipediaUrl,
    required this.edibilityStatus,
    this.edibilityReason,
    required this.tags,
    this.observationsCount,
    this.iconicTaxonName,
    this.matchedTerm,
    this.photoAttribution,
    this.photoLicense,
  });

  factory Species.fromJson(Map<String, dynamic> json) {
    final List<String> tags = [];
    if (json['tags'] is List) {
      tags.addAll(
        (json['tags'] as List).map((t) => t.toString().toLowerCase()),
      );
    }

    String? photo;
    String? attribution;
    String? license;
    final dp = json['default_photo'];
    if (dp != null) {
      photo = (dp['medium_url'] ?? dp['square_url']) as String?;
      attribution = dp['attribution'] as String?;
      license = dp['license_code'] as String?;
    }

    final name =
        ((json['preferred_common_name'] ?? json['name'] ?? '') as String)
            .toLowerCase();
    final sciName = ((json['name'] ?? '') as String).toLowerCase();
    final iconic = ((json['iconic_taxon_name'] ?? '') as String);

    final (edibility, reason) = _detectEdibility(
      name: name,
      sciName: sciName,
      iconic: iconic,
      tags: tags,
    );

    return Species(
      id: json['id'] as int,
      commonName:
          (json['preferred_common_name'] ?? json['name'] ?? 'Unknown')
              as String,
      scientificName: (json['name'] ?? '') as String,
      photoUrl: photo,
      wikipediaSummary: json['wikipedia_summary'] as String?,
      wikipediaUrl: json['wikipedia_url'] as String?,
      edibilityStatus: edibility,
      edibilityReason: reason,
      tags: tags,
      observationsCount: json['observations_count'] as int?,
      iconicTaxonName: iconic.isNotEmpty ? iconic : null,
      matchedTerm: json['matched_term'] as String?,
      photoAttribution: attribution,
      photoLicense: license,
    );
  }

  static (String, String) _detectEdibility({
    required String name,
    required String sciName,
    required String iconic,
    required List<String> tags,
  }) {
    // 1. Tags (most reliable)
    const edibleTags = [
      'edible',
      'edible mushroom',
      'edible plant',
      'edible fruit',
    ];
    const toxicTags = ['toxic', 'poisonous', 'deadly', 'harmful', 'inedible'];
    if (tags.any((t) => edibleTags.contains(t)))
      return ('edible', 'Confirmed edible');
    if (tags.any((t) => toxicTags.contains(t)))
      return ('toxic', 'Confirmed toxic');

    // 2. Common name signals
    const toxicNames = [
      'death cap',
      'destroying angel',
      'death angel',
      'false death cap',
      'deadly webcap',
      'fool\'s webcap',
      'deadly dapperling',
      'panther cap',
      'fly agaric',
      'false morel',
      'brain mushroom',
      'jack-o-lantern',
      'false chanterelle',
      'funeral bell',
      'deadly skullcap',
      'autumn skullcap',
      'deadly fibercap',
      'nightshade',
      'deadly nightshade',
      'foxglove',
      'hemlock',
      'monkshood',
      'wolfsbane',
      'belladonna',
      'henbane',
      'yew',
      'laburnum',
      'lily of the valley',
      'angel\'s trumpet',
      'jimsonweed',
    ];
    for (final t in toxicNames) {
      if (name.contains(t))
        return ('toxic', 'Known dangerous species — do not consume');
    }

    const cautionNames = ['false ', 'fool\'s ', 'mock ', 'lookalike'];
    for (final c in cautionNames) {
      if (name.contains(c)) {
        return ('caution', 'May be confused with toxic lookalikes');
      }
    }

    const edibleFungiNames = [
      'chanterelle',
      'porcini',
      'cep',
      'penny bun',
      'morel',
      'oyster mushroom',
      'oyster',
      'shiitake',
      'puffball',
      'giant puffball',
      'hen of the woods',
      'maitake',
      'chicken of the woods',
      'lion\'s mane',
      'black trumpet',
      'horn of plenty',
      'yellowfoot',
      'yellow foot',
      'winter chanterelle',
      'king bolete',
      'saffron milk cap',
      'matsutake',
      'truffle',
      'enoki',
      'portobello',
      'cremini',
      'cauliflower mushroom',
      'velvet shank',
      'shimeji',
      'wood ear',
      'cloud ear',
      'pig\'s ears',
      'beech mushroom',
    ];
    for (final e in edibleFungiNames) {
      if (name.contains(e)) return ('edible', 'Well-known edible species');
    }

    const ediblePlantNames = [
      'blackberry',
      'raspberry',
      'strawberry',
      'blueberry',
      'elderberry',
      'elderflower',
      'wild garlic',
      'ramsons',
      'nettle',
      'stinging nettle',
      'dandelion',
      'hawthorn',
      'rosehip',
      'bilberry',
      'bramble',
      'watercress',
      'sorrel',
      'chickweed',
      'wild mint',
      'sloe',
      'crab apple',
      'mulberry',
      'gooseberry',
      'currant',
      'wild cherry',
      'beechnut',
      'hazelnut',
      'sweet chestnut',
    ];
    for (final e in ediblePlantNames) {
      if (name.contains(e)) return ('edible', 'Well-known edible plant');
    }

    const toxicPlantNames = [
      'nightshade',
      'foxglove',
      'hemlock',
      'monkshood',
      'buttercup',
      'lords and ladies',
      'arum',
      'spurge',
    ];
    for (final t in toxicPlantNames) {
      if (name.contains(t)) return ('toxic', 'Known toxic plant');
    }

    // 3. Scientific genus detection
    final genus = sciName.split(' ').first;
    const edibleGenera = [
      'cantharellus',
      'craterellus',
      'boletus',
      'leccinum',
      'suillus',
      'pleurotus',
      'laetiporus',
      'grifola',
      'hericium',
      'calvatia',
      'morchella',
      'tuber',
      'tricholoma',
      'flammulina',
      'marasmius',
    ];
    const toxicGenera = [
      'amanita',
      'galerina',
      'lepiota',
      'cortinarius',
      'inocybe',
      'conocybe',
      'pholiotina',
    ];
    if (edibleGenera.contains(genus))
      return ('edible', 'Genus is typically edible');
    if (toxicGenera.contains(genus))
      return ('toxic', 'Genus contains deadly species');

    return ('unknown', 'Edibility unconfirmed — do not eat without expert ID');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'common_name': commonName,
    'scientific_name': scientificName,
    'photo_url': photoUrl,
    'wiki_summary': wikipediaSummary,
    'wiki_url': wikipediaUrl,
    'edibility': edibilityStatus,
    'edibility_reason': edibilityReason,
    'tags': tags.join(','),
    'observations': observationsCount,
    'iconic_taxon': iconicTaxonName,
    'matched_term': matchedTerm,
    'photo_attr': photoAttribution,
    'photo_license': photoLicense,
  };

  factory Species.fromMap(Map<String, dynamic> map) => Species(
    id: map['id'] as int,
    commonName: map['common_name'] as String,
    scientificName: map['scientific_name'] as String,
    photoUrl: map['photo_url'] as String?,
    wikipediaSummary: map['wiki_summary'] as String?,
    wikipediaUrl: map['wiki_url'] as String?,
    edibilityStatus: map['edibility'] as String,
    edibilityReason: map['edibility_reason'] as String?,
    tags: (map['tags'] as String? ?? '')
        .split(',')
        .where((t) => t.isNotEmpty)
        .toList(),
    observationsCount: map['observations'] as int?,
    iconicTaxonName: map['iconic_taxon'] as String?,
    matchedTerm: map['matched_term'] as String?,
    photoAttribution: map['photo_attr'] as String?,
    photoLicense: map['photo_license'] as String?,
  );
}
