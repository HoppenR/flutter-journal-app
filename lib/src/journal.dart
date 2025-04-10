import 'dart:ui';

import 'package:flutter/material.dart';

import 'add_tag_form.dart';
import 'calendar_week.dart';
import 'generated/l10n/app_localizations.dart';
import 'graph.dart';
import 'graph/add_dashboard_form.dart';
import 'settings.dart';
import 'utility.dart';

// --- JournalApp ---

class JournalApp extends StatefulWidget {
  const JournalApp({
    super.key,
    required this.initialLocale,
    required this.initialTheme,
  });

  final Locale? initialLocale;
  final Color? initialTheme;

  @override
  State<JournalApp> createState() => _JournalAppState();

  static void setLocale(BuildContext context, Locale? newLocale) {
    final _JournalAppState? state =
        context.findAncestorStateOfType<_JournalAppState>();
    state?.changeLanguage(newLocale);
  }

  static void setTheme(BuildContext context, String? newTheme) {
    final _JournalAppState? state =
        context.findAncestorStateOfType<_JournalAppState>();
    state?.changeTheme(newTheme);
  }
}

// --- _JournalAppState ---

class _JournalAppState extends State<JournalApp> {
  late Locale? _locale;
  late Color? _theme;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _theme = widget.initialTheme;
  }

  void changeLanguage(Locale? locale) {
    setState(() {
      _locale = locale;
    });
    if (locale != null) {
      saveLocale(locale);
    }
  }

  void changeTheme(String? theme) {
    setState(() {
      _theme = SettingsPage.themes[theme];
    });
    if (theme != null) {
      saveTheme(theme);
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: _theme ?? Colors.deepPurple,
          surface: Colors.white,
        ),
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

class _JournalPageState extends State<JournalPage>
    with SingleTickerProviderStateMixin {
  _JournalPages _selectedViewIndex = _JournalPages.calendar;

  static final DateTime _firstDate = DateTime(1);
  static final DateTime _lastDate = DateTime(2100, 12, 31);
  static const int _firstPage = 0;

  late final int _initialPage;
  late final int _lastPage;
  late final DateTime _initialDate;
  late final ValueNotifier<int> _focusedPageNotifier;
  late final PageController _pageController;

  late Animation<double> _fabIconAnimation;
  late AnimationController _fabIconAnimationController;

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

    _fabIconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fabIconAnimation = CurvedAnimation(
      curve: Curves.linear,
      parent: _fabIconAnimationController,
    );
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 8.0,
        shape: const CircleBorder(),
        onPressed: () => _selectedViewIndex == _JournalPages.calendar
            ? _showAddTagWindow(context)
            : _showAddDashboardWindow(context),
        tooltip: _selectedViewIndex == _JournalPages.calendar
            ? AppLocalizations.of(context).addTag
            : AppLocalizations.of(context).addDashboard,
        child: AnimatedIcon(
          icon: AnimatedIcons.event_add,
          progress: _fabIconAnimation,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          children: <Widget>[
            Expanded(child: _buildCalendarNavigationButton(context)),
            const SizedBox(width: 80.0),
            Expanded(child: _buildGraphsNavigationButton(context)),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          if (_selectedViewIndex == _JournalPages.calendar) ...<Widget>[
            // Calendar View
            _buildCalendarNavigationTopBar(context),
            _buildCalendarBody(context),
          ] else if (_selectedViewIndex == _JournalPages.graphs) ...<Widget>[
            // Graph view
            const Expanded(child: GraphPage()),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarNavigationButton(BuildContext context) {
    return InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(width: 8.0),
      ),
      onTap: () {
        setState(() {
          _selectedViewIndex = _JournalPages.calendar;
          _fabIconAnimationController.reverse();
        });
      },
      child: Column(
        children: <Widget>[
          const Icon(Icons.calendar_today, size: 36.0),
          Text(AppLocalizations.of(context).navigationCalendar),
        ],
      ),
    );
  }

  Widget _buildGraphsNavigationButton(BuildContext context) {
    return InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(width: 8.0),
      ),
      onTap: () {
        setState(() {
          _selectedViewIndex = _JournalPages.graphs;
          _fabIconAnimationController.forward();
        });
      },
      child: Column(
        children: <Widget>[
          const Icon(Icons.bar_chart, size: 36.0),
          Text(AppLocalizations.of(context).navigationGraphs),
        ],
      ),
    );
  }

  Widget _buildCalendarBody(BuildContext context) {
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (int index) {
          _focusedPageNotifier.value = index;
        },
        itemBuilder: (BuildContext context, int index) {
          return CalendarWeek(weekStartDate: _pageIndexToDate(index));
        },
      ),
    );
  }

  Widget _buildCalendarNavigationTopBar(BuildContext context) {
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
            return _buildDateWeekHoldButton(context, pageIndex);
          },
        ),
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

  Widget _buildDateWeekHoldButton(BuildContext context, int pageIndex) {
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
    final bool? didAddTag = await Navigator.push<bool?>(
      context,
      MaterialPageRoute<bool?>(
        builder: (BuildContext context) => const AddTagForm(),
      ),
    );
    if (didAddTag ?? false) {
      if (context.mounted) {
        saveTagData(context);
        saveNextTagId(context);
        saveChartDashboardData(context);
        showSnackBar(context, AppLocalizations.of(context).saveTagDone);
      }
    }
  }

  Future<void> _showAddDashboardWindow(BuildContext context) async {
    final bool? didAddDashboard = await Navigator.push<bool?>(
      context,
      MaterialPageRoute<bool?>(
        builder: (BuildContext context) => const AddDashboardForm(),
      ),
    );
    if (didAddDashboard ?? false) {
      if (context.mounted) {
        //saveTagData(context);
        //saveNextTagId(context);
        saveChartDashboardData(context);
        showSnackBar(context, AppLocalizations.of(context).saveDataDone);
      }
    }
  }

  Future<void> _showSettingsPage(BuildContext context) async {
    final bool? didClearData = await Navigator.push<bool?>(
      context,
      MaterialPageRoute<bool?>(
        builder: (BuildContext context) => const SettingsPage(),
      ),
    );

    if (didClearData ?? false) {
      if (context.mounted) {
        JournalApp.setLocale(context, null);
        JournalApp.setTheme(context, null);
      }
    }
  }
}

class JournalScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices {
    return <PointerDeviceKind>{
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
      PointerDeviceKind.stylus,
      PointerDeviceKind.invertedStylus,
      PointerDeviceKind.trackpad,
    };
  }
}
