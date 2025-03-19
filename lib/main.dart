import 'package:flutter/material.dart';

import 'src/journal.dart';
import 'src/utility.dart';

// TODO(Christoffer): [etc.] Make all these TODOs into github issues learn
//                    workflow of making/fixing github issues/PRs
//                    Also add README.md/images?

// TODO(Christoffer): [settings] Use images/icons for "stack-icon" of book
//                    and crescent moon. No need to bundle expensive truetype
//                    fonts for 2 icons.

// TODO(Christoffer): [graph] Display overviews of weeks/months

// TODO(Christoffer): [add-tag-form] Add menstruation related icons
// TODO(Christoffer): [add-tag-form] Add ImageIcons for emojis?

// TODO(Christoffer): [DatePicker] Week-wise date picker that highlights a full
//                    week (see twitch date picker for past broadcasts)

// TODO(Christoffer): [etc.] Implement routes for back-button popping states

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
        return JournalApp(initialLocale: initialLocale);
      },
    );
  }
}
