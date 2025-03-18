import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 5.0,
        centerSpaceRadius: 40.0,
        sections: _generateSections(),
        // pieTouchData: PieTouchData(enabled: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    return <PieChartSectionData>[
      PieChartSectionData(
        color: Colors.blue,
        value: 40.0,
        title: '40%',
        radius: 50.0,
        titleStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: true,
        titlePositionPercentageOffset: 0.55,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: 30.0,
        title: '30%',
        radius: 50.0,
        titleStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.green,
        value: 20.0,
        title: '20%',
        radius: 50.0,
        titleStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.yellow,
        value: 10.0,
        title: '10%',
        radius: 50.0,
        titleStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }
}
