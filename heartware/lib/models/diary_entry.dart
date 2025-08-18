class DiaryEntry {
  final int id;
  final int userPk;
  final String? mood;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DiaryEntry({
    required this.id,
    required this.userPk,
    required this.mood,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> j, {
    required DateTime? Function(dynamic) parseDT,
    required int Function(dynamic) toInt,
  }) {
    return DiaryEntry(
      id: toInt(j['id']),
      userPk: toInt(j['user_pk']),
      mood: j['mood']?.toString(),
      notes: j['notes']?.toString(),
      createdAt: parseDT(j['created_at']) ?? DateTime.now(),
      updatedAt: parseDT(j['updated_at']),
    );
  }
}
