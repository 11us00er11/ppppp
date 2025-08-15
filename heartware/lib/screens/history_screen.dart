import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://127.0.0.1:5000';

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

  factory DiaryEntry.fromJson(Map<String, dynamic> j) {
    DateTime parseDT(dynamic v) =>
        v == null ? DateTime.now() : DateTime.parse(v.toString()).toLocal();
    return DiaryEntry(
      id: (j['id'] as num).toInt(),
      userPk: (j['user_pk'] as num).toInt(),
      mood: j['mood']?.toString(),
      notes: j['notes']?.toString(),
      createdAt: parseDT(j['created_at']),
      updatedAt: j['updated_at'] == null ? null : parseDT(j['updated_at']),
    );
  }
}

class DiaryService {
  static Future<List<DiaryEntry>> fetch({
    required String token,
    int page = 1,
    int pageSize = 20,
    String? from, // 'YYYY-MM-DD'
    String? to, // 'YYYY-MM-DD'
    List<String>? moods,
    String? q,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
      if (moods != null && moods.isNotEmpty) 'mood': moods.join(','),
      if (q != null && q.isNotEmpty) 'q': q,
    };
    // ✅ 컬렉션 엔드포인트는 트레일링 슬래시
    final uri =
    Uri.parse('$baseUrl/api/diary/').replace(queryParameters: qp);

    final resp = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final data =
    jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final items = (data['items'] as List? ?? const [])
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return items;
  }

  static Future<DiaryEntry> create({
    required String token,
    String? mood,
    String? notes,
  }) async {
    // ✅ 컬렉션 엔드포인트는 트레일링 슬래시
    final uri = Uri.parse('$baseUrl/api/diary/');
    final resp = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'mood': mood, 'notes': notes}),
    )
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    final j = jsonDecode(utf8.decode(resp.bodyBytes));
    return DiaryEntry.fromJson(
        j is Map<String, dynamic> ? j : (j['item'] as Map<String, dynamic>));
  }

  static Future<void> delete({
    required String token,
    required int id,
  }) async {
    // ✅ 개별 리소스는 슬래시 없이
    final uri = Uri.parse('$baseUrl/api/diary/$id');
    final resp = await http
        .delete(uri, headers: {
      'Authorization': 'Bearer $token',
    })
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
  }
}

/// 간단 무드 팔레트
const List<String> kMoodOptions = [
  'happy',
  'sad',
  'angry',
  'anxious',
  'neutral'
];

Color moodColor(String? mood) {
  switch (mood) {
    case 'happy':
      return Colors.amber;
    case 'sad':
      return Colors.blueAccent;
    case 'angry':
      return Colors.redAccent;
    case 'anxious':
      return Colors.deepPurpleAccent;
    case 'neutral':
      return Colors.grey;
    default:
      return Colors.teal;
  }
}

String fmtYMD(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fmtHM(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class HistoryScreen extends StatefulWidget {
  final String token; // JWT
  const HistoryScreen({super.key, required this.token});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _items = <DiaryEntry>[];
  final _scroll = ScrollController();
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  static const _pageSize = 20;

  // 필터
  String? _query;
  DateTime? _from;
  DateTime? _to;
  final Set<String> _moods = {};

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 200) {
        if (_hasMore && !_loading) _load();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading || !mounted) return;
    setState(() => _loading = true);
    final int page = refresh ? 1 : _page;
    try {
      final items = await DiaryService.fetch(
        token: widget.token,
        page: page,
        pageSize: _pageSize,
        from: _from == null ? null : fmtYMD(_from!),
        to: _to == null ? null : fmtYMD(_to!),
        moods: _moods.isEmpty ? null : _moods.toList(),
        q: _query,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) _items.clear();
        _items.addAll(items);
        _hasMore = items.length == _pageSize;
        _page = page + 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('목록을 불러오지 못했습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createEntry() async {
    // ✅ 컨트롤러를 밖에서 만들고 종료 후 dispose
    final notesCtrl = TextEditingController();
    String? selectedMood;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setS) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('새 기록',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kMoodOptions
                      .map((m) => ChoiceChip(
                    label: Text(m),
                    selected: selectedMood == m,
                    selectedColor:
                    moodColor(m).withOpacity(0.25),
                    onSelected: (_) =>
                        setS(() => selectedMood = m),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '메모를 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final created = await DiaryService.create(
                              token: widget.token,
                              mood: selectedMood,
                              notes: notesCtrl.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(
                                  sheetCtx, created.mood ?? '');
                            }
                            if (!mounted) return;
                            // 상단에 바로 반영
                            setState(() {
                              _items.insert(0, created);
                            });
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                    content:
                                    Text('저장 실패: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('저장'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    // 선택 결과가 필요하면 사용 가능
    // final chosenMood = result;

    // ✅ 메모리 정리
    notesCtrl.dispose();
    return;
  }

  Future<void> _deleteEntry(DiaryEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 기록을 삭제하시겠어요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await DiaryService.delete(token: widget.token, id: e.id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((x) => x.id == e.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _openFilter() async {
    final qCtrl = TextEditingController(text: _query ?? '');
    DateTime? from = _from, to = _to;
    final moods = Set<String>.from(_moods);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setS) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('필터 / 검색',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: '키워드(메모 내용)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(from == null
                              ? '시작일'
                              : fmtYMD(from!)),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: from ?? now,
                              firstDate: DateTime(now.year - 3),
                              lastDate: DateTime(now.year + 1),
                            );
                            if (picked != null) setS(() => from = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label:
                          Text(to == null ? '종료일' : fmtYMD(to!)),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: to ?? now,
                              firstDate: DateTime(now.year - 3),
                              lastDate: DateTime(now.year + 1),
                            );
                            if (picked != null) setS(() => to = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kMoodOptions
                        .map((m) => FilterChip(
                      label: Text(m),
                      selected: moods.contains(m),
                      selectedColor:
                      moodColor(m).withOpacity(0.25),
                      onSelected: (v) =>
                          setS(() => v ? moods.add(m) : moods.remove(m)),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setS(() {
                            qCtrl.text = '';
                            from = null;
                            to = null;
                            moods.clear();
                          });
                        },
                        child: const Text('초기화'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(sheetCtx, true),
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _query = qCtrl.text.trim().isEmpty ? null : qCtrl.text.trim();
      _from = from;
      _to = to;
      _moods..clear()..addAll(moods);
    });
    _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 기록 히스토리'),
        actions: [
          IconButton(onPressed: _openFilter, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _items.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= _items.length) {
              return const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final e = _items[i];
            return Dismissible(
              key: ValueKey('diary_${e.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                await _deleteEntry(e);
                return false;
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: moodColor(e.mood),
                  child: Text((e.mood ?? '…').substring(0, 1).toUpperCase()),
                ),
                title: Text(
                  (e.notes ?? '').isEmpty
                      ? '(메모 없음)'
                      : e.notes!.split('\n').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${fmtYMD(e.createdAt)} ${fmtHM(e.createdAt)}'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: moodColor(e.mood),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(e.mood ?? '기록'),
                        ],
                      ),
                      content: SingleChildScrollView(
                        child: Text(e.notes ?? '(메모 없음)'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('닫기'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteEntry(e);
                          },
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createEntry,
        child: const Icon(Icons.add),
      ),
    );
  }
}
