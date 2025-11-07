import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'health_state.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthState = Provider.of<HealthState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('週間レポート')),
      body: kIsWeb
          ? const Center(child: Text("週間レポート機能はWeb版では利用できません。"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildChart(context, '睡眠 (時間)', healthState.sleepData),
                  const SizedBox(height: 40),
                  _buildChart(context, '歩数', healthState.stepsData),
                ],
              ),
            ),
    );
  }

  Widget _buildChart(BuildContext context, String title, List<HealthData> data) {
    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('$title のデータがありません')),
      );
    }

    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(data),
              barGroups: _createBarGroups(data),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final day = data[value.toInt()].date;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(DateFormat('E', 'ja_JP').format(day)),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  double _getMaxY(List<HealthData> data) {
    if (data.isEmpty) return 100.0;
    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  List<BarChartGroupData> _createBarGroups(List<HealthData> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final healthData = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: healthData.value,
            color: Colors.teal,
            width: 16,
          ),
        ],
      );
    }).toList();
  }
}
