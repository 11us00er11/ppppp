import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryScreen extends StatelessWidget {
  // 테스트용 감정 점수 데이터 (날짜순)
  final List<FlSpot> _moodData = [
    FlSpot(1, 3),
    FlSpot(2, 2),
    FlSpot(3, 1),
    FlSpot(4, 2),
    FlSpot(5, 3),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("감정 히스토리")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) {
                    return Text("Day ${value.toInt()}");
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
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: Colors.indigo,
                barWidth: 3,
                dotData: FlDotData(show: true),
                spots: _moodData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
