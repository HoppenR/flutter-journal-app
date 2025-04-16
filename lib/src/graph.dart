import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'graph/configuration.dart';
import 'graph/dashboard.dart';
import 'graph/grid.dart';

class ChartDashboardManager extends ChangeNotifier {
  ChartDashboardManager({
    required this.dashboards,
  });

  List<ChartDashboardData> dashboards;

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
}

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  int? _dashboardIndex;

  @override
  Widget build(BuildContext context) {
    final ChartDashboardManager dashboardManager =
        context.watch<ChartDashboardManager>();

    if (_dashboardIndex != null &&
        _dashboardIndex! >= dashboardManager.dashboards.length) {
      _dashboardIndex = null;
    }

    final ChartDashboardData? selectedDashboard = _dashboardIndex != null
        ? dashboardManager.dashboards[_dashboardIndex!]
        : null;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: 80.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dashboardManager.dashboards.length,
              itemBuilder: (BuildContext context, int index) {
                final ChartDashboardData dashboard =
                    dashboardManager.dashboards[index];
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _dashboardIndex = index;
                    });
                  },
                  icon: Icon(
                    dashboard.icon,
                    size: 40.0,
                  ),
                );
              },
            ),
          ),
          if (selectedDashboard != null) ...<Widget>[
            Text(
              selectedDashboard.title,
              style: const TextStyle(fontSize: 50.0),
            ),
            Expanded(
              child: ChartDashboardGrid(
                dashboard: selectedDashboard,
                key: selectedDashboard.key,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
