import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/graph/dashboard.dart';
import 'src/journal.dart';
import 'src/tag/manager.dart';
import 'src/utility.dart';

// TODO: Customize palletes?
void main() async {
  runApp(const InitializationWidget());
}

class InitializationWidget extends StatelessWidget {
  const InitializationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserPrefs>(
      future: loadUserPrefs(context),
      builder: (BuildContext context, AsyncSnapshot<UserPrefs> snapshot) {
        // Show a loading icon until UserPrefs finishes loading
        if (snapshot.connectionState == .waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (snapshot.hasError) {
          throw AssertionError('error loading user prefs: ${snapshot.error}');
        }

        final Locale? initialLocale = snapshot.data!.locale;
        final Color? initialTheme = snapshot.data!.theme;

        return MultiProvider(
          providers: <ChangeNotifierProvider<ChangeNotifier>>[
            ChangeNotifierProvider<TagManager>(
              create: (_) => TagManager(
                tags: snapshot.data!.tagData,
                appliedTags: snapshot.data!.appliedTags,
                categories: snapshot.data!.categories,
                nextTagId: snapshot.data!.nextTagId,
                nextCategory: snapshot.data!.nextCategory,
              ),
            ),
            ChangeNotifierProvider<ChartDashboardManager>(
              create: (_) =>
                  ChartDashboardManager(dashboards: snapshot.data!.dashboards),
            ),
          ],
          child: JournalApp(
            initialLocale: initialLocale,
            initialTheme: initialTheme,
          ),
        );
      },
    );
  }
}
