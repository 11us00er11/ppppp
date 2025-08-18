import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../repositories/diary_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  final DiaryRepository repo;
  HistoryViewModel(this.repo);

  final items = <DiaryEntry>[];
  bool loading = false;
  bool hasMore = true;
  int _page = 1;
  static const _pageSize = 20;

  String? query;
  DateTime? from;
  DateTime? to;
  final Set<String> moods = {};

  Future<void> refresh() async {
    _page = 1;
    hasMore = true;
    items.clear();
    await load();
  }

  Future<void> load() async {
    if (loading || !hasMore) return;   // ✅ 이중 가드
    loading = true; notifyListeners();
    try {
      final list = await repo.list(
        page: _page,
        pageSize: _pageSize,                 // Repo에서 size로 변환
        from: from == null ? null : _ymd(from!),
        to:   to   == null ? null : _ymd(to!),
        moods: moods.isEmpty ? null : moods.toList(),
        q: query,
      );
      items.addAll(list);
      hasMore = list.length == _pageSize;   // 또는 서버 pages 메타 사용
      _page += 1;
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> create({String? mood, String? notes}) async {
    final created = await repo.create(mood: mood, notes: notes);
    items.insert(0, created);               // 서버 정렬(created_at desc)과 일치
    notifyListeners();
  }

  Future<void> remove(DiaryEntry e) async {
    await repo.delete(e.id);
    items.removeWhere((x) => x.id == e.id);
    notifyListeners();
  }

  void updateFilters({
    String? query,
    DateTime? from,
    DateTime? to,
    Set<String>? moods,
  }) {
    this.query = query;
    this.from  = from;
    this.to    = to;
    if (moods != null) {
      this.moods
        ..clear()
        ..addAll(moods);
    }
    notifyListeners();
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
