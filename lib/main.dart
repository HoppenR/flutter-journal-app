// Vim: set shiftwidth=2 :
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_tag_form.dart';
import 'tag.dart';
import 'tag_overview.dart';

// TODO(Christoffer): More tag types
//                    - [ ] multi-selections
//                    - [ ] on/off
//                    - [ ] levels
//                    - [x] free-text fields
//                    - [_] strike-through (remove)

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

void main() {
  initializeDateFormatting('sv_SE');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

// --- _JournalPageState ---

class _JournalPageState extends State<JournalPage> {
  static const int _initialPage = 1000;

  late DateTime _startDate;
  late ValueNotifier<int> _focusedPageNotifier;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
    _focusedPageNotifier = ValueNotifier<int>(_initialPage);
    _pageController = PageController(initialPage: _initialPage);
    _loadTags();
  }

  @override
  void dispose() {
    _focusedPageNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showClearPreferencesWindow(BuildContext context) {
    showDialog(
      context: context,
      builder: _buildClearPreferencesDialog,
    );
  }

  Widget _buildClearPreferencesDialog(BuildContext context) => AlertDialog(
    title: const Text('Add Tag'),
    content: const Text('Are you sure you want to clear data?'),
    actions: <Widget>[
      TextButton(
        onPressed: Navigator.of(context).pop,
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          _clearPreferences(context);
          _showSnackBar(context, 'Preferences cleared');
          Navigator.of(context).pop();
        },
        child: const Text('Yes'),
      ),
    ],
  );

  Future<void> _clearPreferences(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      tagNames.clear();
      appliedTags.clear();
    });
  }

  void _jumpToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadTags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('tags');

    if (savedData == null) {
      return;
    }

    final Map<String, dynamic> decodedData = json.decode(savedData);

    tagNames = (decodedData['tagNames'] as Map<String, dynamic>).map(
      (String key, dynamic value) {
        return MapEntry<String, TagData>(
          key,
          TagData.fromJson(value),
        );
      },
    );

    appliedTags = (decodedData['appliedTags'] as Map<String, dynamic>).map(
      (String key, dynamic value) {
        return MapEntry<DateTime, List<AppliedTagData>>(
          DateTime.parse(key),
          (value as List<dynamic>).map((dynamic item) {
            return AppliedTagData.fromJson(item as Map<String, dynamic>);
          }).toList(),
        );
      },
    );
  }

  Future<void> _saveTags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final Map<String, Map<String, dynamic>> tagNamesJson = tagNames.map(
      (String key, TagData value) {
        return MapEntry<String, Map<String, dynamic>>(
          key,
          value.toJson(),
        );
      },
    );

    final Map<String, List<Map<String, dynamic>>>
      appliedTagsJson = appliedTags.map(
        (DateTime key, List<AppliedTagData> value) {
          return MapEntry<String, List<Map<String, dynamic>>>(
            key.toIso8601String(),
            value.map((AppliedTagData tag) => tag.toJson()).toList(),
          );
        },
    );

    final String dataToSave = json.encode(<String, dynamic>{
      'tagNames': tagNamesJson,
      'appliedTags': appliedTagsJson,
    });

    await prefs.setString('tags', dataToSave);
  }

  // TODO(Christoffer): Should be in a utility.dart file or something?
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddTagWindow(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<bool?>(
        builder: (BuildContext context) => const AddTagForm(),
      ),
    ).then((bool? result) {
      if (result != null && result) {
        _showSnackBar(context, 'tag added');
        _saveTags();
      }
    });
  }

  void _showTagDayOverview(BuildContext context, DateTime day) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => TagDayOverview(day),
      ),
    ).then((void value) {
      setState(() {
        _saveTags();
      });
    });
  }

  DateTime _pageIndexToDate(int pageIndex) {
    return _startDate.add(Duration(days: 7 * (pageIndex - _initialPage)));
  }

  int _dateToPageIndex(DateTime date) {
    return (date.difference(_startDate).inDays / 7).floor() + _initialPage;
  }

  int _dateToWeekNumber(DateTime date) {
    return (date.difference(DateTime(date.year)).inDays / 7).ceil() + 1;
  }

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
    body: Column(
      children: <Widget>[
        _calendarNavigation(),
        _calendarBody(),
      ],
    ),
  );

  Widget _calendarNavigation() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _jumpToPage(_pageController.page!.toInt() - 1),
      ),
      ValueListenableBuilder<int>(
        valueListenable: _focusedPageNotifier,
        builder: (BuildContext context, int pageIndex, _) {
          final DateTime currentDate = _pageIndexToDate(pageIndex);
          final int weekNumber = _dateToWeekNumber(currentDate);

          return InkWell(
            onTap: () async {
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
              '${currentDate.year} v${weekNumber}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        }
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => _jumpToPage(_pageController.page!.toInt() + 1),
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
      itemBuilder: (BuildContext context, int index) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildCalendarWeek(constraints, index),
        ),
      ),
    ),
  );

  Widget _buildCalendarWeek(
    BoxConstraints constraints,
    int index,
  ) {
    final DateTime weekStartDate = _pageIndexToDate(index);

    final double itemHeight = constraints.maxHeight;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: itemHeight,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
      ),
      itemCount: DateTime.daysPerWeek,
      itemBuilder: (BuildContext context, int dayIndex) {
        final DateTime curDay = weekStartDate.add(Duration(days: dayIndex));
        return TextButton(
          onPressed: () => _showTagDayOverview(context, curDay),
          style: _buttonStyle(context),
          child: _buttonContent(context, curDay)
        );
      },
    );
  }

  ButtonStyle _buttonStyle(BuildContext context) => TextButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    padding: EdgeInsets.zero,
  );

  Widget _buttonContent(
    BuildContext context,
    DateTime curDay,
  ) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Text(
        '${curDay.day}',
        style: TextStyle(
          fontSize: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      if (appliedTags.containsKey(curDay))
        ...appliedTags[curDay]!.map((AppliedTagData tag) {
          return Text(
            tag.string,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary,
              decoration: tag.tagData.type == TagType.strikethrough
                ? TextDecoration.lineThrough
                : null,
            ),
          );
        }),
    ],
  );
}
