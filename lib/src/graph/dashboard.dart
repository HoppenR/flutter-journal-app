import 'package:flutter/material.dart';

import '../tag.dart';
import 'configuration.dart';
import 'graphs.dart';

class ChartDashboardData {
  const ChartDashboardData({
    required this.title,
    required this.icon,
    required this.configurations,
  });

  factory ChartDashboardData.fromJson(Map<String, dynamic> json) {
    final int codePoint = json['icon'];
    return ChartDashboardData(
      title: json['title'],
      icon: availableIcons[codePoint]!,
      configurations: (json['configurations'] as List<dynamic>)
          .map((dynamic value) => GraphConfiguration.fromJson(value))
          .toList(growable: true),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'icon': icon.codePoint,
      'configurations': configurations
          .map((GraphConfiguration conf) => conf.toJson())
          .toList(growable: false),
    };
  }

  final List<GraphConfiguration> configurations;
  final String title;
  final IconData icon;
}

class ChartDashboard extends StatelessWidget {
  const ChartDashboard({super.key, required this.configurations});
  final List<GraphConfiguration> configurations;

  // NOTE: Order should be saved as index into this array

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = <Color>[
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.inversePrimary,
      Color.alphaBlend(
        Theme.of(context).colorScheme.primary.withAlpha(108),
        Theme.of(context).colorScheme.inversePrimary,
      ),
      Color.alphaBlend(
        Theme.of(context).colorScheme.primary.withAlpha(150),
        Theme.of(context).colorScheme.inversePrimary,
      ),
    ];

    // TODO: this date should be changeable by the user to
    // dynamically change every chart on the dashboard
    final DateTime now = DateTime.now();
    return Row(
      children: configurations.map(
        (GraphConfiguration conf) {
          switch (conf.type) {
            case GraphTypes.heatmap:
              switch (conf.timeSpan) {
                case GraphTimespans.month:
                  return Expanded(
                    child: buildMonthHeatMap(context, conf, now, colors[0]),
                  );
                case GraphTimespans.year:
                  return Expanded(
                    child: buildYearHeatMap(context, conf, now, colors),
                  );
              }
            case GraphTypes.weekdayBarChart:
              switch (conf.timeSpan) {
                case GraphTimespans.month:
                  return Expanded(
                    child: buildMonthBarChart(context, conf, now, colors),
                  );
                case GraphTimespans.year:
                  // TODO: Handle this case.
                  throw UnimplementedError();
              }
            case GraphTypes.lineChart:
              switch (conf.timeSpan) {
                case GraphTimespans.month:
                  return Expanded(
                    child: buildMonthLineChart(context, conf, now, colors),
                  );
                case GraphTimespans.year:
                  // TODO: Handle this case.
                  throw UnimplementedError();
              }
            case GraphTypes.radar:
              // TODO: can create new types: radarHabit and radarCategory?
              //       alternatively make it an option at tag creation
              switch (conf.timeSpan) {
                case GraphTimespans.month:
                  return Expanded(
                    child: buildMonthHabitRadar(context, conf, now, colors),
                  );
                case GraphTimespans.year:
                  return Expanded(
                    child: buildYearCategoryRadar(context, conf, now, colors),
                  );
              }
          }
        },
      ).toList(growable: false),
    );
  }
}
