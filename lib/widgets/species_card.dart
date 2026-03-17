import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/models/species.dart';
import 'safety_badge.dart';

class SpeciesCard extends StatelessWidget {
  final Species species;
  final VoidCallback onTap;
  const SpeciesCard({super.key, required this.species, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: species.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: species.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.eco_outlined,
                          color: Colors.grey,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[100],
                      child: const Icon(
                        Icons.eco_outlined,
                        color: Colors.grey,
                        size: 36,
                      ),
                    ),
            ),
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
                      species.commonName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      species.scientificName,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    SafetyBadge(status: species.edibilityStatus),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
