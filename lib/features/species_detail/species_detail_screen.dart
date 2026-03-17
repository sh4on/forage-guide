import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/species.dart';
import '../../widgets/safety_badge.dart';
import '../../core/theme.dart';

class SpeciesDetailScreen extends StatelessWidget {
  final Species species;
  const SpeciesDetailScreen({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildSafetySection(),
                _buildQuickFacts(),
                if (species.wikipediaSummary != null &&
                    species.wikipediaSummary!.isNotEmpty)
                  _buildAboutSection(),
                _buildForagingTips(),
                _buildPhotoCredit(),
                _buildDisclaimer(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── App bar with big photo ───────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            species.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: species.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.forestGreen.withValues(alpha: 0.3),
                    ),
                    errorWidget: (_, __, ___) => _photoPlaceholder(),
                  )
                : _photoPlaceholder(),
            // Gradient overlay so back button is visible
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
    color: AppTheme.forestGreen.withValues(alpha: 0.15),
    child: const Center(
      child: Icon(Icons.eco, size: 96, color: AppTheme.forestGreen),
    ),
  );

  // ─── Name + badge header ──────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      species.commonName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      species.scientificName,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black45,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SafetyBadge(status: species.edibilityStatus, large: true),
            ],
          ),
          const SizedBox(height: 12),
          // Kingdom / type chips
          Wrap(
            spacing: 8,
            children: [
              if (species.iconicTaxonName != null)
                _chip(
                  species.iconicTaxonName! == 'Fungi'
                      ? 'Mushroom / Fungi'
                      : species.iconicTaxonName! == 'Plantae'
                      ? 'Plant'
                      : species.iconicTaxonName!,
                  AppTheme.forestGreen,
                  Icons.eco_outlined,
                ),
              if (species.observationsCount != null)
                _chip(
                  '${_formatCount(species.observationsCount!)} sightings',
                  Colors.blueGrey,
                  Icons.people_outline,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Safety section ───────────────────────────────────────────────────────
  Widget _buildSafetySection() {
    final (
      bgColor,
      borderColor,
      icon,
      title,
      body,
    ) = switch (species.edibilityStatus) {
      'edible' => (
        AppTheme.safeGreen.withValues(alpha: 0.08),
        AppTheme.safeGreen.withValues(alpha: 0.3),
        Icons.check_circle_outline,
        'Edible species',
        species.edibilityReason ??
            'This species is generally considered edible. Always verify with a local expert before consuming.',
      ),
      'toxic' => (
        AppTheme.dangerRed.withValues(alpha: 0.08),
        AppTheme.dangerRed.withValues(alpha: 0.4),
        Icons.dangerous_outlined,
        'DO NOT EAT — Toxic',
        species.edibilityReason ??
            'This species is known to be toxic or deadly. Never consume it under any circumstances.',
      ),
      'caution' => (
        AppTheme.warningAmber.withValues(alpha: 0.08),
        AppTheme.warningAmber.withValues(alpha: 0.4),
        Icons.warning_amber_rounded,
        'Caution required',
        species.edibilityReason ??
            'This species may be confused with toxic lookalikes. Expert identification is essential before consuming.',
      ),
      _ => (
        Colors.grey.withValues(alpha: 0.08),
        Colors.grey.withValues(alpha: 0.3),
        Icons.help_outline,
        'Edibility unknown',
        'The edibility of this species has not been confirmed. Do not consume without expert verification.',
      ),
    };

    final iconColor = switch (species.edibilityStatus) {
      'edible' => AppTheme.safeGreen,
      'toxic' => AppTheme.dangerRed,
      'caution' => AppTheme.warningAmber,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick facts grid ─────────────────────────────────────────────────────
  Widget _buildQuickFacts() {
    final facts = <_Fact>[];

    // Scientific name
    facts.add(
      _Fact(
        icon: Icons.biotech_outlined,
        label: 'Scientific name',
        value: species.scientificName,
        italic: true,
      ),
    );

    // Kingdom
    if (species.iconicTaxonName != null) {
      facts.add(
        _Fact(
          icon: Icons.category_outlined,
          label: 'Kingdom',
          value: species.iconicTaxonName!,
        ),
      );
    }

    // Observations count with rarity indicator
    if (species.observationsCount != null) {
      final count = species.observationsCount!;
      final rarity = count > 50000
          ? 'Very common'
          : count > 10000
          ? 'Common'
          : count > 1000
          ? 'Occasional'
          : 'Rare';
      facts.add(
        _Fact(
          icon: Icons.bar_chart_outlined,
          label: 'How common',
          value: '$rarity (${_formatCount(count)} recorded sightings)',
        ),
      );
    }

    // Matched search term — shows alternative names
    if (species.matchedTerm != null &&
        species.matchedTerm!.toLowerCase() !=
            species.commonName.toLowerCase()) {
      facts.add(
        _Fact(
          icon: Icons.translate_outlined,
          label: 'Also known as',
          value: species.matchedTerm!,
        ),
      );
    }

    // Wikipedia link
    if (species.wikipediaUrl != null) {
      facts.add(
        _Fact(
          icon: Icons.open_in_new_outlined,
          label: 'Learn more',
          value: 'View on Wikipedia',
          isLink: true,
          linkUrl: species.wikipediaUrl,
        ),
      );
    }

    if (facts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Quick facts',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          ...facts.asMap().entries.map(
            (e) => Column(
              children: [
                if (e.key > 0)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                _buildFactRow(e.value),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFactRow(_Fact fact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(fact.icon, size: 18, color: AppTheme.forestGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                fact.isLink
                    ? GestureDetector(
                        onTap: () {
                          /* open URL in Phase 3 */
                        },
                        child: Text(
                          fact.value,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.forestGreen,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : Text(
                        fact.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: fact.italic
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── About (Wikipedia summary) ────────────────────────────────────────────
  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this species',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            species.wikipediaSummary!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Foraging tips (contextual, based on edibility) ───────────────────────
  Widget _buildForagingTips() {
    final tips = _getForagingTips();
    if (tips.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.forestGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.forestGreen.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: AppTheme.forestGreen,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Foraging tips',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•  ',
                    style: TextStyle(
                      color: AppTheme.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getForagingTips() {
    final name = species.commonName.toLowerCase();
    final sci = species.scientificName.toLowerCase();

    // Species-specific tips
    if (name.contains('chanterelle')) {
      return [
        'Found in deciduous and conifer forests, often near oak, beech, and pine.',
        'Season: summer through autumn (June–November in Europe/North America).',
        'The false chanterelle (Hygrophoropsis aurantiaca) is toxic — check that gills are forked ridges, not true gills.',
        'Smells faintly of apricot. The cap has wavy, irregular edges.',
        'Cut at the base — don\'t uproot. This helps regrowth for next year.',
      ];
    }
    if (name.contains('morel')) {
      return [
        'Spring mushroom — look for them in April–May in North America and Europe.',
        'Found near dead or dying elm, ash, and apple trees.',
        'The false morel (Gyromitra) is toxic — true morels are fully hollow when cut in half.',
        'Always cook thoroughly before eating — never eat raw.',
        'Excellent when sautéed in butter. Highly prized in French cuisine.',
      ];
    }
    if (name.contains('porcini') ||
        name.contains('cep') ||
        sci.contains('boletus edulis')) {
      return [
        'Found in deciduous and coniferous forests across Europe and North America.',
        'Season: late summer to autumn (August–November).',
        'Has a distinctive sponge-like underside (pores) instead of gills.',
        'Check for the beige/white pore surface — bitter bolete lookalikes have red or orange pores.',
        'Can be dried for long-term storage. Intensifies in flavour when dried.',
      ];
    }
    if (name.contains('oyster')) {
      return [
        'Grows on dead or dying trees, especially beech, oak, and elm.',
        'Can be found year-round but peaks in autumn and mild winters.',
        'One of the safest mushrooms for beginners — few dangerous lookalikes.',
        'Has a distinctive shell-like shape and grows in overlapping clusters.',
        'Delicious sautéed with garlic and butter.',
      ];
    }
    if (name.contains('wild garlic') || name.contains('ramsons')) {
      return [
        'Grows in dense carpets in damp woodland, especially near streams.',
        'Season: March–May — look for the strong garlic smell to confirm.',
        'IMPORTANT: Can be confused with lily of the valley (toxic) or wild arum (toxic). Always smell before picking.',
        'Both the leaves and flowers are edible. Leaves are best before flowering.',
        'Use like spinach or basil — great in pesto, soup, or stir-fries.',
      ];
    }
    if (name.contains('elderberry') || name.contains('elderflower')) {
      return [
        'Elderflowers appear May–June; elderberries ripen August–October.',
        'Raw elderberries can cause nausea — always cook before eating.',
        'The leaves, bark, and unripe berries are toxic.',
        'Elderflower cordial and elderberry wine are traditional European recipes.',
        'Grows as a shrub or small tree in hedgerows and woodland edges.',
      ];
    }
    if (name.contains('nettle')) {
      return [
        'Best harvested in spring (March–May) before flowering, using gloves.',
        'Cooking or blanching removes the sting completely.',
        'Use young top leaves only — older leaves become tough and bitter.',
        'Rich in iron and vitamins. Used in soups, risotto, and tea.',
        'Grows in nitrogen-rich soil — common near buildings and streams.',
      ];
    }

    // Generic tips by edibility
    if (species.edibilityStatus == 'edible') {
      return [
        'Always carry a field guide when foraging and cross-reference multiple features.',
        'Harvest only what you need — leave plenty for wildlife and regrowth.',
        'Bring a local expert or join a guided foraging walk the first time.',
        'When in doubt, leave it out.',
      ];
    }
    if (species.edibilityStatus == 'toxic') {
      return [
        'Do not touch or consume this species.',
        'If accidentally ingested, contact Poison Control immediately.',
        'Familiarise yourself with this species so you can identify and avoid it.',
      ];
    }
    return [];
  }

  // ─── Photo credit ─────────────────────────────────────────────────────────
  Widget _buildPhotoCredit() {
    if (species.photoAttribution == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        'Photo: ${species.photoAttribution}',
        style: const TextStyle(fontSize: 11, color: Colors.black38),
      ),
    );
  }

  // ─── Bottom disclaimer ────────────────────────────────────────────────────
  Widget _buildDisclaimer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'For educational purposes only. Always verify with a qualified local expert '
        'before consuming any wild plant or mushroom. The authors accept no liability '
        'for foraging decisions made based on this app.',
        style: TextStyle(color: Colors.black38, fontSize: 11, height: 1.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _Fact {
  final IconData icon;
  final String label;
  final String value;
  final bool italic;
  final bool isLink;
  final String? linkUrl;

  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.italic = false,
    this.isLink = false,
    this.linkUrl,
  });
}
