import 'package:flutter/material.dart';

import '../tag.dart';
import 'configuration.dart';

class ChartDashboardManager with ChangeNotifier {
  ChartDashboardManager({required this.dashboards});

  void addDashboard(ChartDashboardData dashboard) {
    dashboards.add(dashboard);
    notifyListeners();
  }

  void removeDashboard(ChartDashboardData dashboard) {
    dashboards.remove(dashboard);
    notifyListeners();
  }

  void removeTagFromDashboards(int tagId) {
    dashboards.removeWhere((ChartDashboardData dashboard) {
      dashboard.configurations.removeWhere((GraphConfiguration config) {
        config.ids.remove(tagId);
        return config.ids.length < config.type.minimumItemAmt;
      });
      return dashboard.configurations.isEmpty;
    });
    notifyListeners();
  }

  void clear() {
    dashboards.clear();
    notifyListeners();
  }

  List<ChartDashboardData> dashboards;
}

class ChartDashboardData {
  ChartDashboardData({
    required this.title,
    required this.icon,
    required this.configurations,
  }) : key = UniqueKey();

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
  final Key key;
}
