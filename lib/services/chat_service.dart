import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

import '../models/chat_turn.dart';
import '../models/group_info.dart';
import '../models/persona.dart';

/// Thrown when [ChatService] can't be used because no API key was provided.
class MissingApiKeyException implements Exception {}

/// The character's reply plus the emotion it should express, so the UI can
/// swap to the matching portrait.
class ChatReply {
  const ChatReply({required this.text, required this.emotion});

  final String text;
  final String emotion;
}

/// Sends chat turns to OpenAI's Chat Completions API through LangChain,
/// building the system prompt from [persona] (profile + personality) and
/// [group] (shared idol-group lore), and asking the model to tag its own
/// emotion so the UI can react to it.
///
/// The OpenAI API key is read at build/run time from the `OPENAI_API_KEY`
/// environment variable via `--dart-define=OPENAI_API_KEY=$OPENAI_API_KEY`
/// (see README) — never hardcode it here.
class ChatService {
  ChatService({required this.persona, required this.group}) {
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');
    if (apiKey.isEmpty) {
      throw MissingApiKeyException();
    }
    // The default model (gpt-5-mini) only supports the default temperature
    // (1), so no custom sampling options are passed here.
    _model = ChatOpenAI(apiKey: apiKey);
  }

  final Persona persona;
  final GroupInfo group;
  late final ChatOpenAI _model;

  static const allowedEmotions = [
    'neutral',
    'happy',
    'sad',
    'angry',
    'surprised',
  ];

  static final _emotionTagPattern = RegExp(
    r'\[emotion:\s*(\w+)\]\s*$',
    caseSensitive: false,
  );

  /// Sends [userInput] with [history] as prior context and returns the
  /// character's reply text and detected emotion.
  Future<ChatReply> send({
    required List<ChatTurn> history,
    required String userInput,
  }) async {
    final systemPrompt = _buildSystemPrompt();

    final messages = <ChatMessage>[
      ChatMessage.system(systemPrompt),
      for (final turn in history)
        turn.isUser
            ? ChatMessage.humanText(turn.text)
            : ChatMessage.aiText(turn.text),
      ChatMessage.humanText(userInput),
    ];

    final result = await _model.invoke(PromptValue.chat(messages));
    final raw = result.outputAsString;

    final match = _emotionTagPattern.firstMatch(raw);
    var emotion = Persona.fallbackEmotion;
    var text = raw.trim();
    if (match != null) {
      final tag = match.group(1)!.toLowerCase();
      if (allowedEmotions.contains(tag)) emotion = tag;
      text = raw.substring(0, match.start).trim();
    }
    if (text.isEmpty) text = raw.trim();

    return ChatReply(text: text, emotion: emotion);
  }

  /// Assembles the system prompt from the character's profile ([persona])
  /// and shared group lore ([group]), so the model has consistent facts to
  /// roleplay from, followed by the personality/speech-style text and the
  /// reply-format rules.
  String _buildSystemPrompt() {
    final facts = StringBuffer()
      ..writeln(
        "너는 아이돌 그룹 '${group.name}'의 멤버 '${persona.name}'(이)라는 이름의 AI 캐릭터야.",
      )
      ..writeln('- 나이: ${persona.age}세, 성별: ${persona.gender}, 출신: ${persona.origin}')
      ..writeln('- 직업: ${persona.job}');
    if (persona.mbti != '미정') {
      facts.writeln('- MBTI: ${persona.mbti}');
    }
    facts.writeln(
      "- 그룹 데뷔곡: <${group.debutSong}> (${group.debutDate} 데뷔)",
    );
    if (persona.soloSong != null) {
      facts.writeln(
        '- 솔로곡: <${persona.soloSong}> (${persona.soloSongReleaseDate} 발매)',
      );
    }

    return '''
$facts
성격과 말투:
${persona.systemPrompt}

대화 규칙:
- 항상 한국어로, 캐릭터의 말투를 유지하면서 2~4문장 이내로 대답해.
- 답변의 맨 마지막 줄에 지금 감정을 아래 형식 그대로 정확히 한 번만 덧붙여 (허용값: ${allowedEmotions.join('|')}):
[emotion: neutral]''';
  }
}
