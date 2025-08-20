import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../repositories/diary_repository.dart';
import '../services/api_client.dart'; // UnauthorizedException 정의 위치

class HistoryViewModel extends ChangeNotifier {
  final DiaryRepository repo;
  final VoidCallback? onUnauthorized;
  HistoryViewModel(this.repo, {this.onUnauthorized});

  final items = <DiaryEntry>[];
  bool loading = false;
  bool hasMore = true;
  int _page = 1;
  static const _pageSize = 20;

  String? query;
  DateTime? from;
  DateTime? to;
  final Set<String> moods = {};

  String? lastError;

  Future<void> refresh() async {
    _page = 1;
    hasMore = true;
    items.clear();
    lastError = null;
    await load();
  }

  Future<void> load() async {
    if (loading || !hasMore) return;
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
      lastError = null;
    } on UnauthorizedException {
      lastError = '세션이 만료되었거나 로그인되지 않았습니다.';
      hasMore = false;
      onUnauthorized?.call(); // 로그인 화면으로 유도
      rethrow; // 필요시 상위에서 스낵바 등
    } catch (e) {
      // 네트워크/서버 일반 에러
      lastError = e.toString();
      hasMore = false;
      // 실패 시 hasMore는 건드리지 않아 다음에 재시도 가능
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> create({String? mood, String? notes}) async {
    try {
      final created = await repo.create(mood: mood, notes: notes);
      items.insert(0, created);
      notifyListeners();
    } on UnauthorizedException {
      onUnauthorized?.call();
      rethrow;
    }
  }

  Future<void> remove(DiaryEntry e) async {
    try {
      await repo.delete(e.id);
      items.removeWhere((x) => x.id == e.id);
      notifyListeners();
    } on UnauthorizedException {
      onUnauthorized?.call();
      rethrow;
    }
  }

  void updateFilters({
    String? query,
    DateTime? from,
    DateTime? to,
    Set<String>? moods,
    bool autoRefresh = true,
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
    if (autoRefresh) {
      // 필터 적용 즉시 새로고침 (중복 호출 방지를 위해 loading 가드가 이미 있음)
      refresh();
    }
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
