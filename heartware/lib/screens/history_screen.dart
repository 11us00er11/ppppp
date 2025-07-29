import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _emotionHistory = []; // 날짜, 점수 데이터

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmotionHistory();
  }

  Future<void> fetchEmotionHistory() async {
    await Future.delayed(Duration(seconds: 1)); // 네트워크 지연 시뮬레이션
    final fetchedData = [
      {'date': '7/25', 'score': 3},
      {'date': '7/26', 'score': 2},
      {'date': '7/27', 'score': 1},
      {'date': '7/28', 'score': 2},
      {'date': '7/29', 'score': 3},
    ];

    setState(() {
      _emotionHistory = fetchedData;
      _isLoading = false;
    });
  }

  List<FlSpot> get _moodSpots => List.generate(
    _emotionHistory.length,
        (index) =>
        FlSpot(index.toDouble(), _emotionHistory[index]['score'].toDouble()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("감정 히스토리")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < _emotionHistory.length) {
                      return Text(_emotionHistory[index]['date'],
                          style: TextStyle(fontSize: 10));
                    } else {
                      return Text("");
                    }
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    switch (value.toInt()) {
                      case 1:
                        return Text("우울");
                      case 2:
                        return Text("불안");
                      case 3:
                        return Text("안정");
                      default:
                        return Text("");
                    }
                  },
                  reservedSize: 42,
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            gridData: FlGridData(show: true),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: Colors.teal,
                barWidth: 3,
                dotData: FlDotData(show: true),
                spots: _moodSpots,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
