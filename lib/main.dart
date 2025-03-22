import 'package:flutter/material.dart';

import 'src/journal.dart';
import 'src/utility.dart';

void main() async {
  runApp(const InitializationWidget());
}

class InitializationWidget extends StatelessWidget {
  const InitializationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserPrefs>(
      future: loadUserPrefs(),
      builder: (BuildContext context, AsyncSnapshot<UserPrefs> snapshot) {
        // Show a loading icon until UserPrefs finishes loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final Locale? initialLocale = snapshot.data!.locale;
        final Color? initialTheme = snapshot.data!.theme;
        return JournalApp(
          initialLocale: initialLocale,
          initialTheme: initialTheme,
        );
      },
    );
  }
}
