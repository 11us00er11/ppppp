import 'package:flutter/material.dart';
import 'chat_screen.dart';

class SurveyScreen extends StatefulWidget {
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final List<String> _questions = [
    "최근 2주간, 슬프거나 우울한 기분을 느낀 적이 있나요?",
    "일상에서 흥미를 느끼지 못한 적이 있었나요?",
    "피곤하고 의욕이 없다고 느꼈나요?",
    "잠을 잘 못 자거나 너무 많이 잤나요?",
    "불안하거나 초조한 상태가 자주 있었나요?",
  ];

  final Map<int, int> _answers = {}; // index -> 0~3

  final List<String> _options = ["전혀 아니다", "약간 그렇다", "꽤 그렇다", "매우 그렇다"];

  String _resultMessage = "";
  int _totalScore = 0;

  void _submitSurvey() {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 문항에 응답해주세요.")),
      );
      return;
    }

    int totalScore = _answers.values.reduce((a, b) => a + b);
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(initialMessage: message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("자가 진단")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ..._questions.asMap().entries.map((entry) {
              int index = entry.key;
              String question = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Q${index + 1}. $question", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Column(
                    children: List.generate(_options.length, (i) {
                      return RadioListTile(
                        title: Text(_options[i]),
                        value: i,
                        groupValue: _answers[index],
                        onChanged: (value) {
                          setState(() {
                            _answers[index] = value as int;
                          });
                        },
                      );
                    }),
                  ),
                  Divider(),
                ],
              );
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitSurvey,
              child: Text("결과 확인"),
            ),
            Card(
              color: Colors.purple[50],
              margin: EdgeInsets.symmetric(vertical: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "진단 결과: $_resultMessage\n총점: $_totalScore / 15",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
