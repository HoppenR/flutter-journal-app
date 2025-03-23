import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'tag.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  @override
  Widget build(BuildContext context) {
    return _buildBarChart(context);
  }

  Widget _buildBarChart(BuildContext context) {
    final TagManager tagManager = context.read<TagManager>();

    final List<double> weekData = List<double>.generate(7, (int index) {
      double counter = 0.0;
      for (final MapEntry<DateTime, List<AppliedTagData>> entry
          in tagManager.appliedTags.entries) {
        if (entry.key.weekday - 1 == index) {
          for (final AppliedTagData data in entry.value) {
            switch (tagManager.tags[data.id]!.type) {
              case TagTypes.list:
                throw UnimplementedError();
              case TagTypes.toggle:
                counter += data.toggleOption! ? 1.0 : 0.0;
              case TagTypes.multi:
                throw UnimplementedError();
            }
          }
        }
      }
      return counter;
    });
    return AspectRatio(
      aspectRatio: 1.0,
      child: BarChart(
        BarChartData(
          maxY: 100.0,
          barGroups: <BarChartGroupData>[
            buildBarChartGroupData(context, 0, weekData[0]),
            buildBarChartGroupData(context, 1, weekData[1]),
            buildBarChartGroupData(context, 2, weekData[2]),
            buildBarChartGroupData(context, 3, weekData[3]),
            buildBarChartGroupData(context, 4, weekData[4]),
            buildBarChartGroupData(context, 5, weekData[5]),
            buildBarChartGroupData(context, 6, weekData[6]),
          ],
          borderData: FlBorderData(
            show: false,
          ),
          gridData: FlGridData(
            checkToShowHorizontalLine: (double value) => value % 5 == 0,
            getDrawingHorizontalLine: (double value) {
              return getLine(context, value);
            },
            getDrawingVerticalLine: (double value) {
              return getLine(context, value);
            },
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 50.0,
                showTitles: true,
                interval: 10.0,
                getTitlesWidget: sideTitles,
              ),
            ),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: bottomTitles,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData buildBarChartGroupData(
    BuildContext context,
    int x,
    double y,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: <BarChartRodData>[
        BarChartRodData(
          toY: y,
          color: Theme.of(context).colorScheme.primary,
          width: 12.0,
        ),
      ],
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const List<String> days = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return SideTitleWidget(
      meta: meta,
      child: Text(
        days[value.toInt()],
      ),
    );
  }

  Widget sideTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text('${value.toInt()}%'),
    );
  }

  FlLine getLine(BuildContext context, double value) {
    return FlLine(
      color: Theme.of(context).colorScheme.inversePrimary,
      strokeWidth: 1.4,
      dashArray: <int>[10, 9],
    );
  }
}
