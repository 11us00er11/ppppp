import '../models/diary_entry.dart';
import '../services/diary_service.dart';

class DiaryRepository {
  final DiaryService api;
  DiaryRepository(this.api);

  Future<List<DiaryEntry>> list({
    required int page,
    required int pageSize,
    String? from,
    String? to,
    List<String>? moods,
    String? q,
  }) async {
    final params = {
      'page': '$page',
      'size': '$pageSize', // 서버는 size 사용
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (q?.isNotEmpty == true) 'q': q!,
      if (moods != null && moods.isNotEmpty) 'mood': moods.join(','),
    };

    final json = await api.list(params);

    final items = (json['items'] as List? ?? [])
        .map((e) => DiaryEntry.fromJson(
      e as Map<String, dynamic>,
      toInt: (v) => v is num ? v.toInt() : int.parse(v.toString()),
      parseDT: (s) => DateTime.tryParse(s) ?? DateTime.now(),
    ))
        .toList();

    return items;
  }

  Future<DiaryEntry> create({String? mood, String? notes}) async {
    final json = await api.create({
      'mood': mood,
      'notes': notes,
    });

    return DiaryEntry.fromJson(
      json['item'] as Map<String, dynamic>,
      toInt: (v) => v is num ? v.toInt() : int.parse(v.toString()),
      parseDT: (s) => DateTime.tryParse(s) ?? DateTime.now(),
    );
  }

  Future<void> delete(int id) async {
    await api.delete(id);
  }
}
