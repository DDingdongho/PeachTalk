/// The idol group all characters belong to, loaded from
/// `assets/data/group.json` — shared across every persona so debut info
/// only needs editing in one place.
class GroupInfo {
  const GroupInfo({
    required this.name,
    required this.debutSong,
    required this.debutDate,
    required this.debutSongYoutube,
  });

  final String name;
  final String debutSong;
  final String debutDate;
  final String debutSongYoutube;

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      name: json['name'] as String,
      debutSong: json['debutSong'] as String,
      debutDate: json['debutDate'] as String,
      debutSongYoutube: json['debutSongYoutube'] as String,
    );
  }
}
