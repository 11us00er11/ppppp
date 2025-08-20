import 'package:flutter/material.dart';
import '../services/diary_service.dart';
import 'package:provider/provider.dart';
import '../repositories/diary_repository.dart';
import '../viewmodels/history_view_model.dart';
import '../widgets/diary_list_item.dart';
import '../widgets/diary_filter_sheet.dart';
import '../widgets/diary_editor_sheet.dart';
import '../services/auth_storage.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<bool> _hasToken() async {
    final t = await getStoredToken();
    return t != null && t.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (_) => HistoryViewModel(
        DiaryRepository(DiaryService(apiClient)),
        onUnauthorized: () async {
          await clearStoredToken();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
          }
        },
      )..refresh(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();
  @override State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final vm = context.read<HistoryViewModel>();
      final nearBottom = _scroll.position.pixels >= _scroll.position.maxScrollExtent - 200;
      if (nearBottom) {
        if (!vm.hasMore || vm.loading) return;
        vm.load();
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 기록 히스토리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final r = await showDiaryFilterSheet(
                context,
                initQuery: vm.query, initFrom: vm.from, initTo: vm.to, initMoods: vm.moods,
              );
              if (r != null) {
                vm.updateFilters(query: r.query, from: r.from, to: r.to, moods: r.moods);
                await vm.refresh();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: vm.items.length + (vm.hasMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (i >= vm.items.length) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final e = vm.items[i];
            return DiaryListItem(
              entry: e,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(e.mood ?? '기록'),
                    content: SingleChildScrollView(child: Text(e.notes ?? '(메모 없음)')),
                    actions: [
                      TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('닫기')),
                      TextButton(onPressed: (){
                        Navigator.pop(ctx);
                        vm.remove(e);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
                      }, child: const Text('삭제')),
                    ],
                  ),
                );
              },
              onDelete: () async {
                try {
                  await vm.remove(e);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
                } catch (err) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $err')));
                }
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final r = await showDiaryEditorSheet(context);
          if (r == null) return;
          try {
            await vm.create(mood: r['mood'], notes: r['notes']);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
