// Vim: set shiftwidth=2 :

// --- ETCETERA ---

// TODO(Christoffer): Test on mobile, fix bug where expanding tag collapses it
//                    and adds unnecessary "…"

// TODO(Christoffer): Display options on different lines in Tag Overview if
//                    overflow

// TODO(Christoffer): Use tagDataID in AppliedTagData instead of storing the
//                    entire tagData each time (see local storage / userprefs)

// TODO(Christoffer): Week-wise date picker that highlights a full week
//                    (see twitch date picker for past broadcasts)

// TODO(Christoffer): Display overflow tags as "multiple tags here"
// https://media.discordapp.net/attachments/1260545436259717154/1348700838905909268/IMG_1473.png?ex=67d06b09&is=67cf1989&hm=ccff07c32299f9765e07d4bf4421af597c5b98ab47a82423b645c4e729ae3e70&=&format=webp&quality=lossless&width=496&height=1074

// TODO(Christoffer): [tag-overview]: Line wrap overflow. See:
// https://discord.com/channels/@me/1260545436259717154/1348701290548695202
// > Maybe hmmm make it show up as number as amount of tags and if want to see
// > what specifically then that page shows it?

// TODO(Christoffer): Implement back-button popping state:
//  html.window.onPopState.listen((event) {
//    debugPrint("Back button pressed");
//    // Handle navigation manually
//    // Example: Navigate to a specific route or update state
//    navigatorKey.currentState?.maybePop();
//  });
//
// OR when navigating forward, add a new history entry:
// pushState(null, '', '#second');

// --- GRAPH ---

// TODO(Christoffer): Display overviews of weeks/months

// --- ADD TAG FORM ---


// TODO(Christoffer): Ensure tag names are unique.
//                    Later the name will tie appliedTagData to TagData instead
//                    of copying the entire TagData each time
//                    src/add_tag_form.dart:39
// TODO(Christoffer): Add menstruation related icons
// TODO(Christoffer): Add ImageIcons for emojis?

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
