import 'package:flutter/material.dart';

import '../models/chat_turn.dart';
import '../models/group_info.dart';
import '../models/persona.dart';
import '../services/app_config_loader.dart';
import '../services/background_schedule_service.dart';
import '../services/chat_service.dart';
import '../services/group_loader.dart';
import '../services/persona_loader.dart';
import '../utils/color_utils.dart';
import 'character_select_screen.dart';

/// Content and styling for [ChatScreen], loaded from
/// `assets/data/chat_screen.json` so it can be edited without touching code.
class _ChatUiConfig {
  const _ChatUiConfig({
    required this.inputHint,
    required this.sendButtonText,
    required this.searchHint,
    required this.noResultsText,
    required this.errorText,
    required this.missingApiKeyText,
    required this.panelColor,
    required this.userBubbleColor,
    required this.userBubbleTextColor,
    required this.aiBubbleColor,
    required this.aiBubbleTextColor,
    required this.timestampColor,
  });

  final String inputHint;
  final String sendButtonText;
  final String searchHint;
  final String noResultsText;
  final String errorText;
  final String missingApiKeyText;
  final Color panelColor;
  final Color userBubbleColor;
  final Color userBubbleTextColor;
  final Color aiBubbleColor;
  final Color aiBubbleTextColor;
  final Color timestampColor;

  factory _ChatUiConfig.fromJson(Map<String, dynamic> json) {
    return _ChatUiConfig(
      inputHint: json['inputHint'] as String,
      sendButtonText: json['sendButtonText'] as String,
      searchHint: json['searchHint'] as String,
      noResultsText: json['noResultsText'] as String,
      errorText: json['errorText'] as String,
      missingApiKeyText: json['missingApiKeyText'] as String,
      panelColor: colorFromHex(json['panelColor'] as String),
      userBubbleColor: colorFromHex(json['userBubbleColor'] as String),
      userBubbleTextColor: colorFromHex(json['userBubbleTextColor'] as String),
      aiBubbleColor: colorFromHex(json['aiBubbleColor'] as String),
      aiBubbleTextColor: colorFromHex(json['aiBubbleTextColor'] as String),
      timestampColor: colorFromHex(json['timestampColor'] as String),
    );
  }
}

/// The app's third screen: chat with the selected character over a
/// time-of-day background, with the character's portrait reacting to its
/// own emotion.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.character});

  final CharacterInfo character;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _uiConfigPath = 'assets/data/chat_screen.json';

  late final Future<void> _initFuture;

  late Persona _persona;
  late _ChatUiConfig _uiConfig;
  late BackgroundScheduleService _backgroundService;
  ChatService? _chatService;
  bool _apiKeyMissing = false;

  final _messages = <ChatTurn>[];
  // One GlobalKey per message (same index as _messages), so a search match
  // can be scrolled into view with Scrollable.ensureVisible regardless of
  // where it currently sits in the list.
  final _messageKeys = <GlobalKey>[];
  final _inputController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _searchActive = false;
  String _searchQuery = '';
  List<int> _matchIndices = [];
  int _currentMatchPointer = -1;
  bool _sending = false;
  String _currentEmotion = Persona.fallbackEmotion;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _updateMatches();
      });
      _scrollToCurrentMatch();
    });
  }

  void _addTurn(ChatTurn turn) {
    _messages.add(turn);
    _messageKeys.add(GlobalKey());
  }

  void _updateMatches() {
    if (_searchQuery.isEmpty) {
      _matchIndices = [];
      _currentMatchPointer = -1;
      return;
    }
    final query = _searchQuery.toLowerCase();
    _matchIndices = [
      for (var i = 0; i < _messages.length; i++)
        if (_messages[i].text.toLowerCase().contains(query)) i,
    ];
    _currentMatchPointer = _matchIndices.isEmpty ? -1 : 0;
  }

  void _goToPreviousMatch() {
    if (_matchIndices.isEmpty) return;
    setState(() {
      _currentMatchPointer =
          (_currentMatchPointer - 1 + _matchIndices.length) %
          _matchIndices.length;
    });
    _scrollToCurrentMatch();
  }

  void _goToNextMatch() {
    if (_matchIndices.isEmpty) return;
    setState(() {
      _currentMatchPointer = (_currentMatchPointer + 1) % _matchIndices.length;
    });
    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (_currentMatchPointer < 0) return;
    final messageIndex = _matchIndices[_currentMatchPointer];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _messageKeys[messageIndex].currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.5,
      );
    });
  }

  Future<void> _initialize() async {
    final results = await Future.wait([
      PersonaLoader.load(widget.character.id),
      AppConfigLoader.load(_uiConfigPath),
      BackgroundScheduleService.load(),
      GroupLoader.load(),
    ]);
    _persona = results[0] as Persona;
    _uiConfig = _ChatUiConfig.fromJson(results[1] as Map<String, dynamic>);
    _backgroundService = results[2] as BackgroundScheduleService;
    _backgroundService.addListener(_onBackgroundChanged);
    final group = results[3] as GroupInfo;

    try {
      _chatService = ChatService(persona: _persona, group: group);
    } on MissingApiKeyException {
      _apiKeyMissing = true;
    }

    _addTurn(
      ChatTurn(isUser: false, text: _persona.greeting, timestamp: DateTime.now()),
    );
  }

  void _onBackgroundChanged() => setState(() {});

  @override
  void dispose() {
    _backgroundService.removeListener(_onBackgroundChanged);
    _backgroundService.dispose();
    _inputController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending || _chatService == null) return;

    final historyBeforeThisTurn = List<ChatTurn>.from(_messages);
    _inputController.clear();
    setState(() {
      _addTurn(ChatTurn(isUser: true, text: text, timestamp: DateTime.now()));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await _chatService!.send(
        history: historyBeforeThisTurn,
        userInput: text,
      );
      if (!mounted) return;
      setState(() {
        _addTurn(
          ChatTurn(
            isUser: false,
            text: reply.text,
            timestamp: DateTime.now(),
            emotion: reply.emotion,
          ),
        );
        _currentEmotion = reply.emotion;
        _sending = false;
      });
      _scrollToBottom();
    } catch (e, st) {
      debugPrint('Chat send failed: $e\n$st');
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_uiConfig.errorText)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _backgroundService,
                  builder: (context, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: Image.asset(
                        _backgroundService.current,
                        key: ValueKey(_backgroundService.current),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Image.asset(
                            _persona.imageForEmotion(_currentEmotion),
                            key: ValueKey(_currentEmotion),
                            height: 260,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    _buildChatPanel(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    // A translucent bar (not just padding) so the back button and name stay
    // legible over busy or dark backgrounds (e.g. the night bedroom scene).
    return Container(
      color: _uiConfig.panelColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _searchActive
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: _uiConfig.searchHint,
                      border: InputBorder.none,
                    ),
                  )
                : Text(
                    widget.character.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          if (_searchActive && _searchQuery.isNotEmpty) ...[
            Text(
              _matchIndices.isEmpty
                  ? _uiConfig.noResultsText
                  : '${_currentMatchPointer + 1}/${_matchIndices.length}',
              style: TextStyle(fontSize: 12, color: _uiConfig.timestampColor),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              visualDensity: VisualDensity.compact,
              onPressed: _matchIndices.isEmpty ? null : _goToPreviousMatch,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              visualDensity: VisualDensity.compact,
              onPressed: _matchIndices.isEmpty ? null : _goToNextMatch,
            ),
          ],
          IconButton(
            icon: Icon(_searchActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchActive = !_searchActive;
                if (!_searchActive) {
                  _searchController.clear();
                  _updateMatches();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(BuildContext context) {
    final panelHeight = MediaQuery.of(context).size.height * 0.42;
    return Container(
      height: panelHeight,
      decoration: BoxDecoration(
        color: _uiConfig.panelColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            // Built eagerly (not ListView.builder) so every message's
            // GlobalKey has a context even before it's scrolled into view —
            // required for Scrollable.ensureVisible to jump to a search
            // match anywhere in the log.
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              children: [
                for (var i = 0; i < _messages.length; i++)
                  _ChatBubble(
                    key: _messageKeys[i],
                    turn: _messages[i],
                    config: _uiConfig,
                    isCurrentMatch:
                        _currentMatchPointer >= 0 &&
                        _matchIndices[_currentMatchPointer] == i,
                    isMatch: _matchIndices.contains(i),
                  ),
              ],
            ),
          ),
          if (_apiKeyMissing)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Text(
                _uiConfig.missingApiKeyText,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: !_sending && !_apiKeyMissing,
                    decoration: InputDecoration(
                      hintText: _uiConfig.inputHint,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                _sending
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        color: _uiConfig.userBubbleColor,
                        onPressed: _apiKeyMissing ? null : _handleSend,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    super.key,
    required this.turn,
    required this.config,
    this.isMatch = false,
    this.isCurrentMatch = false,
  });

  final ChatTurn turn;
  final _ChatUiConfig config;

  /// Whether this message matches the active search query.
  final bool isMatch;

  /// Whether this is the match the search's </> navigation is currently on.
  final bool isCurrentMatch;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = turn.isUser
        ? config.userBubbleColor
        : config.aiBubbleColor;
    final textColor = turn.isUser
        ? config.userBubbleTextColor
        : config.aiBubbleTextColor;

    return Align(
      alignment: turn.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: isMatch
              ? Border.all(
                  color: isCurrentMatch
                      ? config.userBubbleColor
                      : config.userBubbleColor.withValues(alpha: 0.4),
                  width: isCurrentMatch ? 2.5 : 1.5,
                )
              : null,
        ),
        child: Text(turn.text, style: TextStyle(color: textColor)),
      ),
    );
  }
}
