// TODO(Christoffer): [etc.] Implement routes for back-button popping states
// TODO(Christoffer): [tag] Use tagDataID in AppliedTagData instead of storing
//                    the entire tagData each time (see local storage / userprefs)

// TODO(Christoffer): [graph] Display overviews of weeks/months

// TODO(Christoffer): [add-tag-form] Ensure tag names are unique.
//                    Later the name will tie appliedTagData to TagData instead
//                    of copying the entire TagData each time
//                    src/add_tag_form.dart:39
// TODO(Christoffer): [add-tag-form] Add menstruation related icons
// TODO(Christoffer): [add-tag-form] Add ImageIcons for emojis?

// TODO(Christoffer): [DatePicker] Week-wise date picker that highlights a full
//                    week (see twitch date picker for past broadcasts)


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
