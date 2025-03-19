import 'dart:ui';

import 'package:flutter/material.dart';

import 'add_tag_form.dart';
import 'calendar_week.dart';
import 'generated/l10n/app_localizations.dart';
import 'graph.dart';
import 'settings.dart';
import 'utility.dart';

// --- JournalApp ---

class JournalApp extends StatefulWidget {
  const JournalApp({super.key, required this.initialLocale});

  final Locale? initialLocale;

  @override
  State<JournalApp> createState() => _JournalAppState();

  static void setLocale(BuildContext context, Locale? newLocale) {
    final _JournalAppState? state =
        context.findAncestorStateOfType<_JournalAppState>();
    state?.changeLanguage(newLocale);
  }
}

// --- _JournalAppState ---

class _JournalAppState extends State<JournalApp> {
  late Locale? _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void changeLanguage(Locale? locale) {
    setState(() {
      _locale = locale;
    });
    if (locale != null) {
      saveLocale(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: JournalScrollBehavior(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      onGenerateTitle: (BuildContext context) {
        return AppLocalizations.of(context).appTitle;
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) {
          return JournalPage(title: AppLocalizations.of(context).appTitle);
        },
      },
    );
  }
}

// --- JournalPage ---

enum _JournalPages {
  calendar,
  graphs,
}

class JournalPage extends StatefulWidget {
  const JournalPage({super.key, required this.title});
  final String title;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

// --- _JournalPageState ---

class _JournalPageState extends State<JournalPage> {
  _JournalPages _selectedViewIndex = _JournalPages.calendar;

  static final DateTime _firstDate = DateTime(1);
  static final DateTime _lastDate = DateTime(2100, 12, 31);
  static const int _firstPage = 0;

  late final int _initialPage;
  late final int _lastPage;
  late final DateTime _initialDate;
  late final ValueNotifier<int> _focusedPageNotifier;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _initialDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    _initialPage = _dateToPageIndex(_initialDate);
    _lastPage = _dateToPageIndex(DateTime(2100, 12, 31));
    _focusedPageNotifier = ValueNotifier<int>(_initialPage);
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _focusedPageNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsPage(context),
            tooltip: AppLocalizations.of(context).settingsTitle,
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: Column(children: <Widget>[
        if (_selectedViewIndex == _JournalPages.calendar) ...<Widget>[
          // Calendar View
          _calendarNavigation(),
          _calendarBody(),
        ] else if (_selectedViewIndex == _JournalPages.graphs) ...<Widget>[
          // Graph view
          const Expanded(child: GraphPage()),
        ],
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _selectedViewIndex == _JournalPages.calendar
          ? FloatingActionButton(
              elevation: 8.0,
              shape: const CircleBorder(),
              onPressed: () => _showAddTagWindow(context),
              tooltip: AppLocalizations.of(context).addTag,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          children: <Widget>[
            Expanded(
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(width: 8.0),
                ),
                onTap: () {
                  setState(() {
                    _selectedViewIndex = _JournalPages.calendar;
                  });
                },
                child: Column(
                  children: <Widget>[
                    const Icon(Icons.calendar_today, size: 36.0),
                    Text(AppLocalizations.of(context).navigationCalendar),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 80.0),
            Expanded(
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(width: 8.0),
                ),
                onTap: () {
                  setState(() {
                    _selectedViewIndex = _JournalPages.graphs;
                  });
                },
                child: Column(
                  children: <Widget>[
                    const Icon(Icons.bar_chart, size: 36.0),
                    Text(AppLocalizations.of(context).navigationGraphs),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarBody() {
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (int index) {
          _focusedPageNotifier.value = index;
        },
        itemBuilder: (BuildContext context, int index) => CalendarWeek(
          weekStartDate: _pageIndexToDate(index),
        ),
      ),
    );
  }

  Widget _calendarNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final int page = _pageController.page!.toInt();
            if (page > _firstPage) {
              return _jumpToPage(page - 1);
            }
          },
          tooltip: AppLocalizations.of(context).prevWeek,
        ),
        ValueListenableBuilder<int>(
            valueListenable: _focusedPageNotifier,
            builder: (BuildContext context, int pageIndex, _) {
              final DateTime currentDate = _pageIndexToDate(pageIndex);

              return InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(width: 8.0),
                ),
                onTap: () {
                  _jumpToPage(_initialPage);
                },
                onLongPress: () async {
                  final DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: currentDate,
                    firstDate: _firstDate,
                    lastDate: _lastDate,
                  );
                  if (selectedDate != null) {
                    _jumpToPage(_dateToPageIndex(selectedDate));
                  }
                },
                child: Text(
                  AppLocalizations.of(context).yearAndWeek(
                    currentDate.year,
                    _dateToWeekNumber(currentDate),
                  ),
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            final int page = _pageController.page!.toInt();
            if (page < _lastPage) {
              return _jumpToPage(page + 1);
            }
          },
          tooltip: AppLocalizations.of(context).nextWeek,
        ),
      ],
    );
  }

  int _dateToPageIndex(DateTime date) {
    final int diffDays = date.difference(_firstDate).inDays;
    return diffDays ~/ 7;
  }

  // This is a purely cosmetic number displayed on the screen and might be wrong
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
    return _initialDate.add(Duration(days: 7 * (pageIndex - _initialPage)));
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
        showSnackBar(context, AppLocalizations.of(context).saveTagDone);
        saveTagData();
        saveNextTagId();
      });
    }
  }

  Future<void> _showSettingsPage(BuildContext context) async {
    final bool? result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute<bool?>(
        builder: (BuildContext context) => const SettingsPage(),
      ),
    );

    if (result ?? false) {
      setState(() {
        JournalApp.setLocale(context, null);
      });
    }
  }
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
