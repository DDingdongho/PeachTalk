/// A character's conversational persona, loaded from
/// `assets/data/personas/<id>.json` — kept separate from
/// `character_select_screen.json` so the personality/profile content can be
/// edited on its own without touching the selection screen's asset.
class Persona {
  const Persona({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.birthDate,
    required this.origin,
    required this.mbti,
    required this.job,
    required this.systemPrompt,
    required this.greeting,
    required this.emotionImages,
    this.soloSong,
    this.soloSongReleaseDate,
    this.soloSongYoutube,
  });

  final String id;
  final String name;
  final String gender;
  final int age;

  /// Free-form text (e.g. "미정" for "TBD") rather than a real [DateTime]
  /// since this is lore the character sheet may leave undecided.
  final String birthDate;
  final String origin;

  /// Free-form text; may be "미정" if not decided yet.
  final String mbti;
  final String job;

  /// Personality and speech-style description used as (part of) the LLM
  /// system prompt — see [ChatService].
  final String systemPrompt;
  final String greeting;

  /// Maps an emotion key (e.g. "happy", "sad") to the character image shown
  /// for it. Currently every emotion points at the same base portrait —
  /// drop in additional art per emotion and update the paths here to enable
  /// per-emotion expressions.
  final Map<String, String> emotionImages;

  /// Null if this character has no solo song (yet).
  final String? soloSong;
  final String? soloSongReleaseDate;
  final String? soloSongYoutube;

  static const fallbackEmotion = 'neutral';

  /// The image for [emotion], falling back to the neutral portrait (and then
  /// to whatever image is available) if that emotion has no art yet.
  String imageForEmotion(String emotion) {
    return emotionImages[emotion] ??
        emotionImages[fallbackEmotion] ??
        emotionImages.values.first;
  }

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      id: json['id'] as String,
      name: json['name'] as String,
      gender: json['gender'] as String,
      age: json['age'] as int,
      birthDate: json['birthDate'] as String,
      origin: json['origin'] as String,
      mbti: json['mbti'] as String,
      job: json['job'] as String,
      systemPrompt: json['systemPrompt'] as String,
      greeting: json['greeting'] as String,
      emotionImages: Map<String, String>.from(
        json['emotionImages'] as Map,
      ),
      soloSong: json['soloSong'] as String?,
      soloSongReleaseDate: json['soloSongReleaseDate'] as String?,
      soloSongYoutube: json['soloSongYoutube'] as String?,
    );
  }
}
