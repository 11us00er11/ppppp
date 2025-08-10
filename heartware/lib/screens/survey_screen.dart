import 'package:flutter/material.dart';
import 'chat_screen.dart';

class SurveyScreen extends StatefulWidget {
  final int userId;
  final String? displayName;

  const SurveyScreen({
    required this.userId,
    this.displayName,
    super.key,
  });

  @override
  State<SurveyScreen> createState() => _SurveyScreenState(); // ✅ 필수
}

class _SurveyScreenState extends State<SurveyScreen> {
  final List<String> _questions = const [
    "최근 2주간, 슬프거나 우울한 기분을 느낀 적이 있나요?",
    "일상에서 흥미를 느끼지 못한 적이 있었나요?",
    "피곤하고 의욕이 없다고 느꼈나요?",
    "잠을 잘 못 자거나 너무 많이 잤나요?",
    "불안하거나 초조한 상태가 자주 있었나요?",
  ];

  // index -> 0~3 점수
  final Map<int, int> _answers = {};
  final List<String> _options = const ["전혀 아니다", "약간 그렇다", "꽤 그렇다", "매우 그렇다"];

  String _resultMessage = "";
  int _totalScore = 0;

  void _submitSurvey() {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 문항에 응답해주세요.")),
      );
      return;
    }

    final totalScore = _answers.values.fold<int>(0, (sum, v) => sum + v);
    String message;
    if (totalScore <= 5) {
      message = "정서 상태가 비교적 안정적입니다.";
    } else if (totalScore <= 10) {
      message = "가벼운 우울 또는 불안의 가능성이 있습니다.";
    } else {
      message = "심리적인 어려움이 있는 상태일 수 있습니다. 전문가 상담을 고려해보세요.";
    }

    setState(() {
      _resultMessage = message;
      _totalScore = totalScore;
    });

    // 챗봇 안내
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("챗봇과 대화하시겠어요?"),
        content: const Text("진단 결과에 기반한 위로를 받아보실 수 있습니다."),
        actions: [
          TextButton(
            child: const Text("아니오"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("예"),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    initialMessage: message,
                    // 필요하면 userId/displayName도 넘기세요
                    // userId: widget.userId,
                    // displayName: widget.displayName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = (widget.displayName != null && widget.displayName!.trim().isNotEmpty)
        ? '${widget.displayName}님, 자가 진단을 시작합니다.'
        : '자가 진단을 시작합니다.';

    return Scaffold(
      appBar: AppBar(title: const Text("자가 진단")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(greeting, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Q${index + 1}. $question",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(_options.length, (i) {
                      return RadioListTile<int>(
                        title: Text(_options[i]),
                        value: i,
                        groupValue: _answers[index],
                        onChanged: (int? value) {
                          if (value == null) return;
                          setState(() {
                            _answers[index] = value;
                          });
                        },
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      );
                    }),
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitSurvey,
              child: const Text("결과 확인"),
            ),
            if (_resultMessage.isNotEmpty)
              Card(
                color: Colors.purple[50],
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "진단 결과: $_resultMessage\n총점: $_totalScore / 15",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
