import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'generated/l10n/app_localizations.dart';
import 'graph/dashboard.dart';
import 'graph/grid.dart';
import 'utility.dart';

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
                  onLongPress: () async {
                    final bool didDeleteDashboard =
                        await _showDeleteDashboardWindow(context);
                    if (didDeleteDashboard) {
                      dashboardManager.removeDashboard(dashboard);
                      _dashboardIndex = null;
                      if (context.mounted) {
                        saveChartDashboardData(context);
                      }
                    }
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

  Future<bool> _showDeleteDashboardWindow(BuildContext context) async {
    final bool? didDeleteDashboard = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).clearDataTitle),
          content: Text(AppLocalizations.of(context).clearDataPrompt),
          actions: <Widget>[
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(AppLocalizations.of(context).promptNegative),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(AppLocalizations.of(context).promptAffirmative),
            ),
          ],
        );
      },
    );
    return didDeleteDashboard ?? false;
  }
}
