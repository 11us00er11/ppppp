import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../repositories/diary_repository.dart';
import '../services/api_client.dart';

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
        pageSize: _pageSize,
        from: from == null ? null : _ymd(from!),
        to:   to   == null ? null : _ymd(to!),
        moods: moods.isEmpty ? null : moods.toList(),
        q: query,
      );
      items.addAll(list);
      hasMore = list.length == _pageSize;
      _page += 1;
      lastError = null;
    } on UnauthorizedException {
      lastError = '세션이 만료되었거나 로그인되지 않았습니다.';
      hasMore = false;
      onUnauthorized?.call();
      rethrow;
    } catch (e) {
      lastError = e.toString();
      hasMore = false;
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
      refresh();
    }
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
