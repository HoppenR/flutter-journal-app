import 'package:collection/collection.dart';
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
  // TODO This should be _selectedTagIndex and start at 0?
  TagData? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final TagManager tagManager = context.watch<TagManager>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: 80.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tagManager.tags.length,
              shrinkWrap: true,
              prototypeItem: const Icon(Icons.favorite, size: 40),
              itemBuilder: (BuildContext context, int index) {
                final TagData tag =
                    tagManager.tags.entries.elementAt(index).value;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedTag = tag;
                    });
                  },
                  icon: Icon(
                    tag.icon,
                    size: 40.0,
                  ),
                );
              },
            ),
          ),
          const Text(
            'March',
            style: TextStyle(fontSize: 50.0),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(child: _buildHeatMap(context, tagManager)),
                Expanded(child: _buildBarChart(context, tagManager)),
                Expanded(child: _buildLineChart(context, tagManager)),
              ],
            ),
          ),
        ],
      ),
    );

    //Center(
    //  child: SizedBox(
    //    height: 200.0,
    //    width: 200.0,
    //    child: _buildBarChart(context, tagManager),
    //  ),
    //);
  }

  Widget _buildHeatMap(BuildContext context, TagManager tagManager) {
    if (_selectedTag == null) {
      return const SizedBox.expand();
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: ScatterChart(
        ScatterChartData(
          maxX: 7.0,
          maxY: 5.0,
          titlesData: const FlTitlesData(
            show: false,
          ),
          gridData: const FlGridData(
            verticalInterval: 1.0,
            horizontalInterval: 1.0,
          ),
          scatterTouchData: ScatterTouchData(
            enabled: false,
          ),
          borderData: FlBorderData(
            show: false,
          ),
          scatterSpots: _getScatterSpots(context, tagManager),
        ),
      ),
    );
  }

  ScatterSpot makeSpot(BuildContext context, double x, double y, bool toggled) {
    return ScatterSpot(
      x + 0.5,
      -y + 4.5,
      dotPainter: FlDotCirclePainter(
        radius: 50.0,
        color: toggled
            ? Theme.of(context).colorScheme.secondaryContainer
            : Colors.transparent,
      ),
    );
  }

  List<ScatterSpot> _getScatterSpots(
    BuildContext context,
    TagManager tagManager,
  ) {
    final List<ScatterSpot> spots = <ScatterSpot>[];

    for (final MapEntry<DateTime, List<AppliedTagData>> entry
        in tagManager.appliedTags.entries) {
      if (entry.key.month == DateTime.march) {
        for (final AppliedTagData appliedTag in entry.value) {
          if (appliedTag.tag == _selectedTag!) {
            final int firstDayOffset = DateUtils.firstDayOffset(
              entry.key.year,
              entry.key.month,
              MaterialLocalizations.of(context),
            );
            final int index = (entry.key.day - 1) + firstDayOffset;
            spots.add(
              makeSpot(
                context,
                (index % 7).toDouble(),
                (index ~/ 7).toDouble(),
                appliedTag.toggleOption!,
              ),
            );
          }
        }
      }
    }
    return spots;
  }

  Widget _buildBarChart(BuildContext context, TagManager tagManager) {
    if (_selectedTag == null) {
      return const SizedBox.expand();
    }

    final List<double> weekData = _generateBarData(tagManager);

    final double max = weekData.max;

    final List<double> percentData = weekData.map(
      (double barValue) {
        return barValue * 100.0 / max;
      },
    ).toList(growable: false);

    return BarChart(
      BarChartData(
        maxY: 100.0,
        barGroups: <BarChartGroupData>[
          buildBarChartGroupData(context, 0, percentData[0]),
          buildBarChartGroupData(context, 1, percentData[1]),
          buildBarChartGroupData(context, 2, percentData[2]),
          buildBarChartGroupData(context, 3, percentData[3]),
          buildBarChartGroupData(context, 4, percentData[4]),
          buildBarChartGroupData(context, 5, percentData[5]),
          buildBarChartGroupData(context, 6, percentData[6]),
        ],
        borderData: FlBorderData(
          show: false,
        ),
        gridData: FlGridData(
          verticalInterval: 0.125,
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
              interval: 50.0,
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
    );
  }

  List<double> _generateBarData(TagManager tagManager) {
    return List<double>.generate(7, (int index) {
      double counter = 0.0;
      for (final MapEntry<DateTime, List<AppliedTagData>> entry
          in tagManager.appliedTags.entries) {
        if (entry.key.weekday - 1 == index) {
          for (final AppliedTagData data in entry.value) {
            if (data.tag == _selectedTag) {
              switch (data.type) {
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
      }
      return counter;
    });
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
          // TODO dynamic width based on widget size
          width: 14.0,
        ),
      ],
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const List<String> days = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (value.toInt() != value) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
      space: 0.0,
      meta: meta,
      child: Text(days[value.toInt()]),
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
      dashArray: <int>[6, 5],
    );
  }

  Widget _buildLineChart(BuildContext context, TagManager tagManager) {
    if (_selectedTag == null) {
      return const SizedBox.expand();
    }

    final List<double> weekData = _generateBarData(tagManager);

    final double max = weekData.max;

    final List<double> percentData = weekData.map(
      (double barValue) {
        return barValue * 100.0 / max;
      },
    ).toList(growable: false);

    return LineChart(
      LineChartData(
        maxY: 100.0,
        minY: 0.0,
        baselineY: 0.0,
        minX: -0.99,
        maxX: 6.99,
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            color: Theme.of(context).colorScheme.primary,
            isCurved: true,
            barWidth: 6.0,
            spots: <FlSpot>[
              FlSpot(0, percentData[0]),
              FlSpot(1, percentData[1]),
              FlSpot(2, percentData[2]),
              FlSpot(3, percentData[3]),
              FlSpot(4, percentData[4]),
              FlSpot(5, percentData[5]),
              FlSpot(6, percentData[6]),
            ],
          ),
        ],
        borderData: FlBorderData(
          show: false,
        ),
        gridData: FlGridData(
          verticalInterval: 1.0,
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
              interval: 50.0,
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
    );
  }
}
