import 'package:flutter/material.dart';

import 'src/journal.dart';
import 'src/utility.dart';

// TODO(Christoffer): [etc.] Make all these TODOs into github issues
//                           learn workflow of making/fixing github issues/PRs
//                           Also add README.md/images?

// TODO(Christoffer): [settings] Use monocolor emojis for "stack-icon" of book
//                               and crescent moon. NotoEmoji maybe?
//                               alternatively the delete button should be made
//                               into purple/magenta.

// TODO(Christoffer): [etc.] Implement routes for back-button popping states
// TODO(Christoffer): [tag] Use tagDataID in AppliedTagData instead of storing
//                    the entire tagData each time (see local storage / userprefs)

// TODO(Christoffer): [tag] Use Set<int> for multiselection?

// TODO(Christoffer): [graph] Display overviews of weeks/months

// TODO(Christoffer): [add-tag-form] Ensure tag names are unique.
//                    Later the name will tie appliedTagData to TagData instead
//                    of copying the entire TagData each time
//                    src/add_tag_form.dart:39
// TODO(Christoffer): [add-tag-form] Add menstruation related icons
// TODO(Christoffer): [add-tag-form] Add ImageIcons for emojis?

// TODO(Christoffer): [DatePicker] Week-wise date picker that highlights a full
//                    week (see twitch date picker for past broadcasts)

// TODO(Christoffer): [tag-overview] use ChoiceChip over TextButton with colored
//                                   styles

// ----- Check With Luunie First -----

// TODO(Christoffer): [tag-overview] Highlight the relevant tag when opening the
//                                   tag-overview, based on what square the user
//                                   pressed

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
