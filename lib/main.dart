// Vim: set shiftwidth=2 :
// TODO(Christoffer): Week-wise date picker that highlights a full week
//                    (see twitch date picker for past broadcasts)

// TODO(Christoffer): Display overflow tags as "multiple tags here"
// https://media.discordapp.net/attachments/1260545436259717154/1348700838905909268/IMG_1473.png?ex=67d06b09&is=67cf1989&hm=ccff07c32299f9765e07d4bf4421af597c5b98ab47a82423b645c4e729ae3e70&=&format=webp&quality=lossless&width=496&height=1074

// TODO(Christoffer): [tag-overview]: Line wrap overflow. See:
// https://media.discordapp.net/attachments/1260545436259717154/1348702481999200307/IMG_1475.png?ex=67d06c91&is=67cf1b11&hm=10b22452dc6d0baeba26ab2b67dcb7ce4ee72b209e03489c340390d845243570&=&format=webp&quality=lossless&width=496&height=1074

// TODO(Christoffer): Look at this:
// https://discord.com/channels/@me/1260545436259717154/1348701290548695202

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
