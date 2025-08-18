import 'package:flutter/material.dart';
import '../models/diary_entry.dart';

Color moodColor(String? mood) {
  switch (mood) {
    case 'happy': return Colors.amber;
    case 'sad': return Colors.blueAccent;
    case 'angry': return Colors.redAccent;
    case 'anxious': return Colors.deepPurpleAccent;
    case 'neutral': return Colors.grey;
    default: return Colors.teal;
  }
}

String fmtYMD(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
String fmtHM(DateTime d)  => '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

class DiaryListItem extends StatelessWidget {
  const DiaryListItem({super.key, required this.entry, required this.onTap, required this.onDelete});
  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final e = entry;
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
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('삭제'),
            content: const Text('이 기록을 삭제하시겠어요?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('취소')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('삭제')),
            ],
          ),
        );
        if (ok == true) onDelete();
        return false;
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: moodColor(e.mood),
          child: Text((e.mood ?? '…').substring(0,1).toUpperCase()),
        ),
        title: Text(
          (e.notes ?? '').isEmpty ? '(메모 없음)' : e.notes!.split('\n').first,
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${fmtYMD(e.createdAt)} ${fmtHM(e.createdAt)}'),
        onTap: onTap,
      ),
    );
  }
}
