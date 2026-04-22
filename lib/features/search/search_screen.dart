import 'package:flutter/material.dart';
import 'package:forage_guide/features/search/search_controller.dart';
import 'package:forage_guide/widgets/exit_alert_dialog.dart';
import 'package:upgrader/upgrader.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/species.dart';
import '../../widgets/species_card.dart';
import '../../core/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = AppSearchController();
  final _textCtrl = TextEditingController();
  final _db = DatabaseHelper();

  @override
  void dispose() {
    _controller.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _openSpecies(Species s) {
    _db.cacheSpecies(s);
    Navigator.pushNamed(context, '/species', arguments: s);
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      showIgnore: false,
      showLater: false,
      barrierDismissible: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ForageGuide'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showSafetyDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textCtrl,
                onChanged: (v) {
                  if (v.length >= 2) _controller.search(v);
                  if (v.isEmpty) _controller.clear();
                },
                decoration: InputDecoration(
                  hintText: 'Search mushrooms, plants...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.forestGreen,
                  ),
                  suffixIcon: _textCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _textCtrl.clear();
                            _controller.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  if (_controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.forestGreen,
                      ),
                    );
                  }
                  if (_controller.error != null) {
                    return _buildError();
                  }
                  if (_controller.results.isNotEmpty) {
                    return _buildResults();
                  }
                  return _buildWelcome();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _controller.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => SpeciesCard(
        species: _controller.results[i],
        onTap: () => _openSpecies(_controller.results[i]),
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular searches',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'Chanterelle',
                      'Porcini',
                      'Morel',
                      'Blackberry',
                      'Elderberry',
                      'Wild garlic',
                      'Nettle',
                      'Oyster mushroom',
                    ]
                    .map(
                      (term) => ActionChip(
                        label: Text(term),
                        backgroundColor: AppTheme.forestGreen.withValues(
                          alpha: 0.08,
                        ),
                        onPressed: () {
                          _textCtrl.text = term;
                          _controller.search(term);
                          setState(() {});
                        },
                      ),
                    )
                    .toList(),
          ),
          if (_controller.recent.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Recently viewed',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 10),
            ..._controller.recent.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SpeciesCard(species: s, onTap: () => _openSpecies(s)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            _controller.error!,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _controller.search(_textCtrl.text),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSafetyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Safety reminder'),
        content: const Text(
          'This app is for educational purposes only.\n\n'
          'Never eat any wild plant or mushroom based solely on '
          'this app. Always verify with a local expert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
