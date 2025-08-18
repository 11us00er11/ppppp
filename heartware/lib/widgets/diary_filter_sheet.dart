import 'package:flutter/material.dart';

class DiaryFilterResult {
  final String? query;
  final DateTime? from;
  final DateTime? to;
  final Set<String> moods;
  DiaryFilterResult({this.query, this.from, this.to, required this.moods});
}

const kMoodOptions = ['happy','sad','angry','anxious','neutral'];

Future<DiaryFilterResult?> showDiaryFilterSheet(BuildContext context, {
  String? initQuery, DateTime? initFrom, DateTime? initTo, Set<String>? initMoods,
}) {
  final qCtrl = TextEditingController(text: initQuery ?? '');
  DateTime? from = initFrom, to = initTo;
  final moods = Set<String>.from(initMoods ?? {});

  return showModalBottomSheet<DiaryFilterResult>(
    context: context, isScrollControlled: true,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(
        left:16,right:16,top:16,
        bottom:16 + MediaQuery.of(sheetCtx).viewInsets.bottom,
      ),
      child: StatefulBuilder(
        builder: (ctx,setS) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
            children: [
              const Text('필터 / 검색', style: TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
              const SizedBox(height:12),
              TextField(
                controller: qCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '키워드(메모 내용)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height:12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(from==null?'시작일':'${from!.year}-${from!.month.toString().padLeft(2,'0')}-${from!.day.toString().padLeft(2,'0')}'),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(context: context, initialDate: from??now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+1));
                    if (picked!=null) setS(()=>from=picked);
                  },
                )),
                const SizedBox(width:8),
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(to==null?'종료일':'${to!.year}-${to!.month.toString().padLeft(2,'0')}-${to!.day.toString().padLeft(2,'0')}'),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(context: context, initialDate: to??now, firstDate: DateTime(now.year-3), lastDate: DateTime(now.year+1));
                    if (picked!=null) setS(()=>to=picked);
                  },
                )),
              ]),
              const SizedBox(height:12),
              Wrap(
                spacing:8, runSpacing:8,
                children: kMoodOptions.map((m)=>FilterChip(
                  label: Text(m),
                  selected: moods.contains(m),
                  onSelected: (v)=> setS(()=> v?moods.add(m):moods.remove(m)),
                )).toList(),
              ),
              const SizedBox(height:16),
              Row(children: [
                TextButton(onPressed: (){
                  setS(() { qCtrl.text=''; from=null; to=null; moods.clear();});
                }, child: const Text('초기화')),
                const Spacer(),
                ElevatedButton(
                  onPressed: ()=> Navigator.pop(sheetCtx, DiaryFilterResult(
                    query: qCtrl.text.trim().isEmpty? null: qCtrl.text.trim(),
                    from: from, to: to, moods: moods,
                  )),
                  child: const Text('적용'),
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  );
}
