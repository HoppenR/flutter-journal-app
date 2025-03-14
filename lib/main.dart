// Vim: set shiftwidth=2 :
// TODO(Christoffer): Week-wise date picker that highlights a full week
//                    (see twitch date picker for past broadcasts)

// TODO(Christoffer): Add multilanguage support with intl/flutter_localizations

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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'add_tag_form.dart';
import 'calendar_week.dart';
import 'graph.dart';
import 'tag.dart';
import 'utility.dart';

void main() {
  initializeDateFormatting('sv_SE');
  runApp(const JournalApp());
}

class JournalApp extends StatelessWidget {
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: JournalScrollBehavior(),
      locale: const Locale('sv', 'SE'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('sv', 'SE'),
      ],
      title: "Luunie's Journal",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const JournalPage(title: 'Journal'),
    );
  }
}

class JournalPage extends StatefulWidget {
  const JournalPage({super.key, required this.title});
  final String title;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class JournalScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
      };
}

// --- _JournalPageState ---

class _JournalPageState extends State<JournalPage> {
  static const int _initialPage = 1000;
  int _selectedViewIndex = 0;

  late DateTime _startDate;
  late ValueNotifier<int> _focusedPageNotifier;
  late PageController _pageController;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddTagWindow(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showClearPreferencesWindow(context),
            ),
          ],
        ),
        resizeToAvoidBottomInset: false,
        body: Column(children: <Widget>[
          if (_selectedViewIndex == 0) ...<Widget>[
            // Calendar View
            _calendarNavigation(),
            _calendarBody(),
          ] else if (_selectedViewIndex == 1) ...<Widget>[
            // Graph view
            const Expanded(child: GraphPage()),
          ],
        ]),
        bottomNavigationBar: BottomNavigationBar(
          onTap: (int index) {
            setState(() {
              _selectedViewIndex = index;
            });
          },
          currentIndex: _selectedViewIndex,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today, size: 36),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart, size: 36),
              label: 'Graphs',
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _focusedPageNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    _focusedPageNotifier = ValueNotifier<int>(_initialPage);
    _pageController = PageController(initialPage: _initialPage);
    loadTags();
  }

  Widget _buildClearPreferencesDialog(BuildContext context) => AlertDialog(
        title: const Text('Clear tags'),
        content: const Text('Are you sure you want to clear data?'),
        actions: <Widget>[
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              clearPreferences(context);
              setState(() {
                tagNames.clear();
                appliedTags.clear();
              });
              showSnackBar(context, 'Preferences cleared');
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      );

  Widget _calendarBody() => Expanded(
        child: PageView.builder(
          controller: _pageController,
          // scrollDirection: Axis.horizontal,
          onPageChanged: (int index) {
            _focusedPageNotifier.value = index;
          },
          itemBuilder: (BuildContext context, int index) => CalendarWeek(
            _pageIndexToDate(index),
          ),
        ),
      );

  Widget _calendarNavigation() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _jumpToPage(_pageController.page!.toInt() - 1),
            tooltip: 'Föregående månad',
          ),
          ValueListenableBuilder<int>(
              valueListenable: _focusedPageNotifier,
              builder: (BuildContext context, int pageIndex, _) {
                final DateTime currentDate = _pageIndexToDate(pageIndex);
                final int weekNumber = _dateToWeekNumber(currentDate);

                return InkWell(
                  onTap: () {
                    _jumpToPage(_initialPage);
                  },
                  onLongPress: () async {
                    final DateTime? selectedDate = await showDatePicker(
                      context: context,
                      initialDate: currentDate,
                      firstDate: _pageIndexToDate(0),
                      lastDate: _pageIndexToDate(_initialPage * 2),
                    );
                    if (selectedDate != null) {
                      _jumpToPage(_dateToPageIndex(selectedDate));
                    }
                  },
                  child: Text(
                    '${currentDate.year} v$weekNumber',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                );
              }),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => _jumpToPage(_pageController.page!.toInt() + 1),
            tooltip: 'Nästa månad',
          ),
        ],
      );

  int _dateToPageIndex(DateTime date) {
    return (date.difference(_startDate).inDays / 7).floor() + _initialPage;
  }

  int _dateToWeekNumber(DateTime date) {
    return (date.difference(DateTime(date.year)).inDays / 7).ceil() + 1;
  }

  void _jumpToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  DateTime _pageIndexToDate(int pageIndex) {
    return _startDate.add(Duration(days: 7 * (pageIndex - _initialPage)));
  }

  Future<void> _showAddTagWindow(BuildContext context) async {
    final bool? result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute<bool?>(
        builder: (BuildContext context) => const AddTagForm(),
      ),
    );
    if (result ?? false) {
      setState(() {
        if (result != null && result) {
          showSnackBar(context, 'tag added');
          saveTags();
        }
      });
    }
  }

  void _showClearPreferencesWindow(BuildContext context) {
    showDialog(
      context: context,
      builder: _buildClearPreferencesDialog,
    );
  }
}
