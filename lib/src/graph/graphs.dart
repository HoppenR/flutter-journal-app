import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../tag.dart';
import 'configuration.dart';

// --- HEATMAP ---
Widget buildMonthHeatMap(
  BuildContext context,
  TagManager tagManager,
  GraphConfiguration conf,
  DateTime time,
  List<Color> colors,
) {
  return ScatterChart(
    ScatterChartData(
      maxX: 7.0,
      maxY: 5.0,
      minX: 0.0,
      minY: 0.0,
      titlesData: const FlTitlesData(
        show: false,
      ),
      gridData: FlGridData(
        verticalInterval: 1.0,
        horizontalInterval: 1.0,
        getDrawingHorizontalLine: (double value) {
          return _getGraphLine(context, value);
        },
        getDrawingVerticalLine: (double value) {
          return _getGraphLine(context, value);
        },
      ),
      scatterTouchData: ScatterTouchData(
        enabled: false,
      ),
      borderData: FlBorderData(
        show: false,
      ),
      scatterSpots: _getScatterSpots(
        context,
        tagManager,
        conf,
        time,
        colors,
      ),
    ),
  );
}

List<ScatterSpot> _getScatterSpots(
  BuildContext context,
  TagManager tagManager,
  GraphConfiguration conf,
  DateTime time,
  List<Color> colors,
) {
  final List<ScatterSpot> spots = <ScatterSpot>[];

  for (final MapEntry<DateTime, List<AppliedTagData>> entry
      in tagManager.appliedTags.entries) {
    if (entry.key.year == time.year && entry.key.month == time.month) {
      for (final AppliedTagData appliedTag in entry.value) {
        final int tagIndex = conf.ids.indexOf(appliedTag.id);
        if (tagIndex != -1) {
          switch (appliedTag.type) {
            case TagTypes.list:
              break;
            case TagTypes.toggle:
              if (!appliedTag.toggleOption!) {
                continue;
              }
            case TagTypes.multi:
              if (appliedTag.multiOptions!.isEmpty) {
                continue;
              }
          }
          final int firstDayOffset = DateUtils.firstDayOffset(
            entry.key.year,
            entry.key.month,
            MaterialLocalizations.of(context),
          );
          final int index = (entry.key.day - 1) + firstDayOffset - 1;
          spots.add(
            _makeSpot(
              context,
              (index % 7).toDouble(),
              (index ~/ 7).toDouble(),
              colors[tagIndex],
            ),
          );
        }
      }
    }
  }
  return spots;
}

ScatterSpot _makeSpot(
  BuildContext context,
  double x,
  double y,
  Color color,
) {
  final Size screenSz = MediaQuery.of(context).size;
  final double baseRadius = (screenSz.width + screenSz.height) * 0.02 - 20.0;
  return ScatterSpot(
    x + 0.5,
    -y + 4.5,
    dotPainter: FlDotCirclePainter(
      radius: baseRadius,
      color: color,
    ),
  );
}

// --- BARCHART ---
Widget buildMonthBarChart(
  BuildContext context,
  TagManager tagManager,
  GraphConfiguration conf,
  DateTime time,
  List<Color> colors,
) {
  final List<List<double>> weekData = _generateBarGroupData(
    tagManager,
    conf,
    time,
  );

  final double maxValue = weekData.fold(
    1.0,
    (double acc, List<double> right) => max(acc, right.max),
  );

  final List<List<double>> percentData = weekData.map(
    (List<double> barValues) {
      return barValues
          .map((double value) => value * 100.0 / maxValue)
          .toList(growable: false);
    },
  ).toList(growable: false);

  return BarChart(
    BarChartData(
      maxY: 100.0,
      minY: 0.0,
      barGroups: <BarChartGroupData>[
        _buildBarChartGroupData(context, 0, percentData[0], colors),
        _buildBarChartGroupData(context, 1, percentData[1], colors),
        _buildBarChartGroupData(context, 2, percentData[2], colors),
        _buildBarChartGroupData(context, 3, percentData[3], colors),
        _buildBarChartGroupData(context, 4, percentData[4], colors),
        _buildBarChartGroupData(context, 5, percentData[5], colors),
        _buildBarChartGroupData(context, 6, percentData[6], colors),
      ],
      borderData: FlBorderData(
        show: false,
      ),
      gridData: FlGridData(
        verticalInterval: 0.125,
        getDrawingHorizontalLine: (double value) {
          return _getGraphLine(context, value);
        },
        getDrawingVerticalLine: (double value) {
          return _getGraphLine(context, value);
        },
      ),
      titlesData: const FlTitlesData(
        topTitles: AxisTitles(),
        leftTitles: AxisTitles(),
        rightTitles: AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: _bottomTitles,
          ),
        ),
      ),
    ),
  );
}

BarChartGroupData _buildBarChartGroupData(
  BuildContext context,
  int x,
  List<double> ys,
  List<Color> colors,
) {
  // TODO: dynamic width based on widget size
  return BarChartGroupData(
    x: x,
    barRods: <BarChartRodData>[
      ...ys.asMap().entries.map((MapEntry<int, double> entry) {
        return BarChartRodData(
          toY: entry.value,
          color: colors[entry.key],
          width: 14.0,
        );
      })
    ],
  );
}

// Returns a list grouped by day in first order and tag in second order
List<List<double>> _generateBarGroupData(
  TagManager tagManager,
  GraphConfiguration conf,
  DateTime time,
) {
  return List<List<double>>.generate(7, (int index) {
    return conf.ids.map((int tagId) {
      double counter = 0.0;
      for (final MapEntry<DateTime, List<AppliedTagData>> entry
          in tagManager.appliedTags.entries) {
        if (entry.key.year == time.year &&
            entry.key.month == time.month &&
            entry.key.weekday - 1 == index) {
          for (final AppliedTagData data in entry.value) {
            if (data.tag.id == tagId) {
              switch (data.type) {
                case TagTypes.list:
                  break;
                case TagTypes.toggle:
                  if (!data.toggleOption!) {
                    continue;
                  }
                case TagTypes.multi:
                  if (data.multiOptions!.isEmpty) {
                    continue;
                  }
              }
              counter++;
            }
          }
        }
      }
      return counter;
    }).toList(growable: false);
  }, growable: false);
}

// --- LINECHART ---
Widget buildMonthLineChart(
  BuildContext context,
  TagManager tagManager,
  GraphConfiguration conf,
  DateTime time,
  List<Color> colors,
) {
  final List<List<double>> weekData = _generateLineChartData(
    tagManager,
    conf,
    time,
  );

  final double maxValue = weekData.fold(
    1.0,
    (double acc, List<double> right) => max(acc, right.max),
  );

  final List<List<double>> percentData = weekData.map(
    (List<double> barValues) {
      return barValues
          .map((double value) => value * 100.0 / maxValue)
          .toList(growable: false);
    },
  ).toList(growable: false);

  return LineChart(
    LineChartData(
      maxY: 100.0,
      minY: 0.0,
      baselineY: 0.0,
      minX: -0.99,
      maxX: 6.99,
      lineBarsData: percentData.asMap().entries.map(
        (MapEntry<int, List<double>> entry) {
          return LineChartBarData(
            color: colors[entry.key],
            isCurved: true,
            barWidth: 6.0,
            spots: _buildLineChartBarData(context, entry.key, entry.value),
          );
        },
      ).toList(growable: false),
      borderData: FlBorderData(
        show: false,
      ),
      gridData: FlGridData(
        verticalInterval: 1.0,
        getDrawingHorizontalLine: (double value) {
          return _getGraphLine(context, value);
        },
        getDrawingVerticalLine: (double value) {
          return _getGraphLine(context, value);
        },
      ),
      titlesData: const FlTitlesData(
        topTitles: AxisTitles(),
        leftTitles: AxisTitles(),
        rightTitles: AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: _bottomTitles,
          ),
        ),
      ),
    ),
  );
}

List<FlSpot> _buildLineChartBarData(
  BuildContext context,
  int x,
  List<double> ys,
) {
  return <FlSpot>[
    FlSpot(0, ys[0]),
    FlSpot(1, ys[1]),
    FlSpot(2, ys[2]),
    FlSpot(3, ys[3]),
    FlSpot(4, ys[4]),
    FlSpot(5, ys[5]),
    FlSpot(6, ys[6]),
  ];
}

// Returns a list grouped by tags in first order and day in second order
List<List<double>> _generateLineChartData(
  TagManager tagManager,
  GraphConfiguration conf,
  DateTime time,
) {
  return conf.ids.map((int tagId) {
    return List<double>.generate(7, (int index) {
      double counter = 0.0;
      for (final MapEntry<DateTime, List<AppliedTagData>> entry
          in tagManager.appliedTags.entries) {
        if (entry.key.year == time.year &&
            entry.key.month == time.month &&
            entry.key.weekday - 1 == index) {
          for (final AppliedTagData data in entry.value) {
            if (data.tag.id == tagId) {
              switch (data.type) {
                case TagTypes.list:
                  break;
                case TagTypes.toggle:
                  if (!data.toggleOption!) {
                    continue;
                  }
                case TagTypes.multi:
                  if (data.multiOptions!.isEmpty) {
                    continue;
                  }
              }
              counter++;
            }
          }
        }
      }
      return counter;
    }, growable: false);
  }).toList(growable: false);
}

// --- RADAR GRAPH ---
class RadarGraphData {
  RadarGraphData({required this.name, required this.count});
  final String name;
  double count;
}

Widget buildMonthHabitRadar(
  BuildContext context,
  TagManager tagManager,
  GraphConfiguration conf,
  DateTime now,
  List<Color> colors,
) {
  // User case one:
  // we want to view monthly view and see which HABIT has been used the most
  // often.
  // Data will be based on 30-31 days (one month). (Current?)
  // Habit will be shown on outer area.
  final Map<int, RadarGraphData> radarChartData = <int, RadarGraphData>{
    for (final MapEntry<int, TagData> entry in tagManager.tags.entries)
      if (conf.ids.contains(entry.key))
        entry.key: RadarGraphData(name: entry.value.name, count: 0.0)
  };
  for (final MapEntry<DateTime, List<AppliedTagData>> entry
      in tagManager.appliedTags.entries) {
    for (final AppliedTagData appliedTag in entry.value) {
      switch (appliedTag.type) {
        case TagTypes.list:
          break;
        case TagTypes.toggle:
          if (appliedTag.toggleOption!) {
            continue;
          }
        case TagTypes.multi:
          if (appliedTag.multiOptions!.isEmpty) {
            continue;
          }
      }
      radarChartData[appliedTag.id]?.count += 1;
    }
  }
  return RadarChart(
    RadarChartData(
      getTitle: (int index, _) {
        return RadarChartTitle(
          text: radarChartData.entries.elementAt(index).value.name,
        );
      },
      dataSets: <RadarDataSet>[
        RadarDataSet(
          dataEntries: radarChartData.entries.map(
            (MapEntry<int, RadarGraphData> arg) {
              return RadarEntry(value: arg.value.count);
            },
          ).toList(growable: false),
        )
      ],
      //dataSets: <RadarDataSet>[
      //  RadarDataSet(
      //    dataEntries: conf.ids.map(
      //      (int categoryId) {
      //        return RadarEntry(
      //          value: tagManager.tags.values
      //              .where((TagData tag) => tag.categoryId == categoryId)
      //              .fold(0, (double acc, _) => acc + 1),
      //        );
      //      },
      //    ).toList(growable: false),
      //  )
      //],
      borderData: FlBorderData(
        show: false,
      ),
    ),
  );
}

// --- COMMON ---

Widget _bottomTitles(double value, TitleMeta meta) {
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

FlLine _getGraphLine(BuildContext context, double value) {
  return FlLine(
    color: Theme.of(context).colorScheme.inversePrimary,
    strokeWidth: 1.4,
    dashArray: <int>[6, 5],
  );
}
