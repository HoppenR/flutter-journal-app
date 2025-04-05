import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final TagManager tagManager = context.watch<TagManager>();
    final List<Color> colors = <Color>[
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.inversePrimary,
      Color.alphaBlend(
        Theme.of(context).colorScheme.primary.withAlpha(108),
        Theme.of(context).colorScheme.inversePrimary,
      ),
      Theme.of(context).colorScheme.error,
    ];

    // TODO: this date should be changeable by the user to
    // dynamically change every chart on the dashboard
    final DateTime now = DateTime.now();
    return Row(
      children: configurations.map(
        (GraphConfiguration conf) {
          switch (conf.graphType) {
            case GraphType.heatmap:
              switch (conf.timeSpanPreset) {
                case GraphTimespan.week:
                  // TODO: Handle this case.
                  throw UnimplementedError();
                case GraphTimespan.month:
                  return Expanded(
                    child: buildMonthHeatMap(
                      context,
                      tagManager,
                      conf,
                      now,
                      colors,
                    ),
                  );
                case GraphTimespan.year:
                  // TODO: Handle this case.
                  throw UnimplementedError();
              }
            case GraphType.weekdayBarChart:
              switch (conf.timeSpanPreset) {
                case GraphTimespan.week:
                  // TODO: Handle this case.
                  throw UnimplementedError();
                case GraphTimespan.month:
                  return Expanded(
                    child: buildMonthBarChart(
                      context,
                      tagManager,
                      conf,
                      now,
                      colors,
                    ),
                  );
                case GraphTimespan.year:
                  // TODO: Handle this case.
                  throw UnimplementedError();
              }
            case GraphType.lineChart:
              switch (conf.timeSpanPreset) {
                case GraphTimespan.week:
                  // TODO: Handle this case.
                  throw UnimplementedError();
                case GraphTimespan.month:
                  return Expanded(
                    child: buildMonthLineChart(
                      context,
                      tagManager,
                      conf,
                      now,
                      colors,
                    ),
                  );
                case GraphTimespan.year:
                  // TODO: Handle this case.
                  throw UnimplementedError();
              }
            case GraphType.radar:
              switch (conf.timeSpanPreset) {
                case GraphTimespan.week:
                  // TODO: Handle this case.
                  throw UnimplementedError();
                case GraphTimespan.month:
                  return Expanded(
                    child: buildMonthHabitRadar(
                      context,
                      tagManager,
                      conf,
                      now,
                      colors,
                    ),
                  );
                case GraphTimespan.year:
                  // TODO: Handle this case.
                  throw UnimplementedError();
              }
          }
        },
      ).toList(growable: false),
    );
  }
}
