import 'package:flutter/material.dart';
const kMoodOptions = ['happy','sad','angry','anxious','neutral'];

Future<Map<String, String?>?> showDiaryEditorSheet(BuildContext context) {
  final notesCtrl = TextEditingController();
  String? selectedMood;

  return showModalBottomSheet<Map<String, String?>?>(
    context: context, isScrollControlled: true,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(left:16,right:16,top:16,bottom:16+MediaQuery.of(sheetCtx).viewInsets.bottom),
      child: StatefulBuilder(
        builder: (ctx,setS)=> Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('새 기록', style: TextStyle(fontSize:18, fontWeight: FontWeight.bold)),
            const SizedBox(height:12),
            Wrap(
              spacing:8, runSpacing:8,
              children: kMoodOptions.map((m)=>ChoiceChip(
                label: Text(m), selected: selectedMood==m,
                onSelected: (_)=> setS(()=> selectedMood=m),
              )).toList(),
            ),
            const SizedBox(height:12),
            TextField(
              controller: notesCtrl, maxLines: 5,
              decoration: const InputDecoration(
                hintText:'메모를 입력하세요', border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height:12),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: ()=> Navigator.pop(sheetCtx),
                child: const Text('취소'),
              )),
              const SizedBox(width:8),
              Expanded(child: ElevatedButton(
                onPressed: ()=> Navigator.pop(sheetCtx, {'mood': selectedMood, 'notes': notesCtrl.text.trim()}),
                child: const Text('저장'),
              )),
            ]),
            const SizedBox(height:8),
          ],
        ),
      ),
    ),
  );
}
