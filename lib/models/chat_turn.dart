/// One message in a conversation, shown in the chat log and searchable.
class ChatTurn {
  ChatTurn({
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.emotion,
  });

  final bool isUser;
  final String text;
  final DateTime timestamp;

  /// The character's emotion for this turn (AI turns only); null for user
  /// turns and for the character's opening greeting before any reply.
  final String? emotion;
}
