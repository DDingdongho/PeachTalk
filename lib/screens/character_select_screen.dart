import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/app_config_loader.dart';
import '../utils/color_utils.dart';
import 'chat_screen.dart';

/// One character's profile, as listed in `assets/data/character_select_screen.json`.
class CharacterInfo {
  const CharacterInfo({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
  });

  final String id;
  final String name;
  final String image;
  final String description;

  factory CharacterInfo.fromJson(Map<String, dynamic> json) {
    return CharacterInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      description: json['description'] as String,
    );
  }
}

/// Content and styling for [CharacterSelectScreen], loaded from
/// `assets/data/character_select_screen.json` so it can be edited without
/// touching code.
class _CharacterSelectConfig {
  const _CharacterSelectConfig({
    required this.chatButtonText,
    required this.backgroundColor,
    required this.cardColor,
    required this.nameColor,
    required this.descriptionColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.characters,
  });

  final String chatButtonText;
  final Color backgroundColor;
  final Color cardColor;
  final Color nameColor;
  final Color descriptionColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final List<CharacterInfo> characters;

  factory _CharacterSelectConfig.fromJson(Map<String, dynamic> json) {
    return _CharacterSelectConfig(
      chatButtonText: json['chatButtonText'] as String,
      backgroundColor: colorFromHex(json['backgroundColor'] as String),
      cardColor: colorFromHex(json['cardColor'] as String),
      nameColor: colorFromHex(json['nameColor'] as String),
      descriptionColor: colorFromHex(json['descriptionColor'] as String),
      buttonColor: colorFromHex(json['buttonColor'] as String),
      buttonTextColor: colorFromHex(json['buttonTextColor'] as String),
      characters: (json['characters'] as List)
          .map((e) => CharacterInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// The app's second screen: pick which character to chat with.
class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  static const _configPath = 'assets/data/character_select_screen.json';

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  // Card size is fixed (not derived from screen width) so it looks the same
  // on desktop and mobile; the value matches what a 2-column grid computes
  // on a typical phone screen (~411dp wide).
  static const double _cardWidth = 178;
  static const double _cardHeight = 270;
  static const double _cardSpacing = 12;
  static const double _rowSpacing = 16;

  // Desktop shows every card in a single row; mobile keeps a 2-column grid.
  static const _desktopPlatforms = {
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  };
  static bool get _isDesktop =>
      _desktopPlatforms.contains(defaultTargetPlatform);

  late final Future<Map<String, dynamic>> _configFuture;

  @override
  void initState() {
    super.initState();
    _configFuture = AppConfigLoader.load(CharacterSelectScreen._configPath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final config = _CharacterSelectConfig.fromJson(snapshot.data!);

        return Scaffold(
          backgroundColor: config.backgroundColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 32,
              ),
              children: [..._buildCardRows(config)],
            ),
          ),
        );
      },
    );
  }

  /// Groups the character cards into rows: one single row on desktop, or a
  /// 2-column matrix on mobile (an incomplete last row keeps its empty slot
  /// so every card stays aligned to its column instead of drifting to center).
  List<Widget> _buildCardRows(_CharacterSelectConfig config) {
    final perRow = _isDesktop ? config.characters.length : 2;
    final rows = <Widget>[];
    for (var i = 0; i < config.characters.length; i += perRow) {
      final rowCharacters = config.characters.skip(i).take(perRow).toList();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: _rowSpacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < perRow; col++) ...[
                if (col > 0) const SizedBox(width: _cardSpacing),
                SizedBox(
                  width: _cardWidth,
                  height: _cardHeight,
                  // Empty (invisible) slot when this row is short a card, so
                  // the column alignment of a full 2x2 grid is preserved.
                  child: col < rowCharacters.length
                      ? _CharacterCard(
                          character: rowCharacters[col],
                          config: config,
                        )
                      : null,
                ),
              ],
            ],
          ),
        ),
      );
    }
    return rows;
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character, required this.config});

  final CharacterInfo character;
  final _CharacterSelectConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: config.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              character.image,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            character.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: config.nameColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            character.description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: config.descriptionColor,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: config.buttonColor,
                foregroundColor: config.buttonTextColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: Size.zero,
                textStyle: const TextStyle(fontSize: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(character: character),
                  ),
                );
              },
              child: Text(config.chatButtonText),
            ),
          ),
        ],
      ),
    );
  }
}
