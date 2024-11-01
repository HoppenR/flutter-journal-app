// Vim: set shiftwidth=2 :
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class TagData {
  final String tag;
  final String value;

  TagData(this.tag, this.value);

  Map<String, dynamic> toJson() {
    return <String, String>{
      'tag': tag,
      'value': value,
    };
  }

  factory TagData.fromJson(Map<String, dynamic> json) {
    return TagData(
      json['tag'],
      json['value'],
    );
  }
}

class _JournalPageState extends State<JournalPage> {
  final int _initialPage = 500;

  Map<String, List<String>> _tagNames = <String, List<String>>{};
  // TODO: Change this to Map<String, Map<String, String>>
  //       so that each day can have multiple tags
  Map<DateTime, TagData> _appliedTags = <DateTime, TagData>{};

  late DateTime _startMonth;
  late ValueNotifier<DateTime> _focusedMonthNotifier;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _startMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _focusedMonthNotifier = ValueNotifier<DateTime>(_startMonth);
    _pageController = PageController(initialPage: _initialPage);
    _loadTags();
  }

  @override
  void dispose() {
    _focusedMonthNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _clearPreferences() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clearing preferences...')),
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _tagNames.clear();
      _appliedTags.clear();
    });
  }

  void _jumpToPage(int offset) {
    _pageController.animateToPage(
      _pageController.page!.toInt() + offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadTags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('tags');

    if (savedData != null) {
      setState(() {
        final Map<String, dynamic> decodedData = json.decode(savedData);

        _tagNames = (decodedData['tagNames'] as Map<String, dynamic>)
          .map((String key, dynamic value) =>
            MapEntry<String, List<String>>(key, List<String>.from(value)));

        _appliedTags = (decodedData['appliedTags'] as Map<String, dynamic>)
          .map((String key, dynamic value) =>
            MapEntry<DateTime, TagData>(
              DateTime.parse(key),
              TagData.fromJson(value),
            ),
          );
      });
    }
  }

  Future<void> _saveTags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> dataToSave = <String, dynamic>{
      'tagNames': _tagNames,
      'appliedTags': _appliedTags
        .map((DateTime key, TagData value) =>
          MapEntry<String, dynamic>(
            key.toIso8601String(),
            value.toJson(),
          ),
        ),
    };

    await prefs.setString('tags', json.encode(dataToSave));
  }

  void _showAddTagWindow() {
    final TextEditingController tagController = TextEditingController();
    final List<TextEditingController>
      optionControllers = <TextEditingController>[TextEditingController()];
    String? selectedType;

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: const Text('Add Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: tagController,
                decoration: const InputDecoration(hintText: 'Enter a tag'),
              ),
              DropdownButton<String>(
                value: selectedType,
                hint: const Text('Select tag type'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'boolean',
                    child: Text('Checkmark'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'list',
                    child: Text('Options'),
                  ),
                ],
                onChanged: (String? value) {
                  setDialogState(() {
                    selectedType = value;
                  });
                },
              ),
              if (selectedType == 'list') ...<Widget>[
                for (final TextEditingController controller in optionControllers)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Enter an option',
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setDialogState(() {
                      optionControllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                  setDialogState(() {
                    if (selectedType == 'list') {
                      _tagNames[tagController.text] = optionControllers
                        .map((TextEditingController controller) => controller.text)
                        .where((String text) => text.isNotEmpty)
                        .toList();
                    } else {
                      // TODO: Think through this, rather have small text +
                      //       strikethrough when checked?
                      _tagNames[tagController.text] = <String>['✅', '❎'];
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tag added')),
                    );
                  });
                _saveTags();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyTag(DateTime date) {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    String? selectedTagname;
    String? selectedTagvalue;
    List<String> optionsList = <String>[];

    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: Text('Add Tag for $formattedDate'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButton<String>(
                  value: selectedTagname,
                  hint: const Text('Select Tag'),
                  items: _tagNames.keys.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setDialogState(() {
                      selectedTagname = value;
                      if (value != null && _tagNames[value] != null) {
                        optionsList = _tagNames[value]!;
                      }
                    });
                  },
                ),
                if (optionsList.isNotEmpty) ...<Widget>[
                  const Text('Select an option:'),
                  DropdownButton<String>(
                    value: selectedTagvalue,
                    hint: const Text('Options'),
                    items: optionsList.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setDialogState(() {
                        selectedTagvalue = value;
                      });
                    },
                  ),
                ],
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selectedTagname != null
                  ? () {
                      setState(() {
                        final TagData td = TagData(
                          selectedTagname!,
                          selectedTagvalue!,
                        );
                        _appliedTags[date] = td;
                      });
                      _saveTags();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tag applied to date')),
                      );
                      Navigator.of(context).pop();
                    }
                  : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime _calculateMonth(int index) {
    final int monthOffset = index - _initialPage;
    return DateTime(_startMonth.year, _startMonth.month + monthOffset);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTagWindow,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearPreferences,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _calendarNavigation(),
          _calendarBody(),
        ],
      ),
    );
  }

  Widget _calendarNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _jumpToPage(-1),
        ),
        // TODO: Pressing this might open a selection for manually inputting a
        //       date with the builtin flutter picker. And it should calculate
        //       the new `offset` and then call `_jumpToPage(offset)` with that.
        ValueListenableBuilder<DateTime>(
          valueListenable: _focusedMonthNotifier,
          builder: (BuildContext context, DateTime focusedMonth, Widget? child) {
            return Text(
              DateFormat.yMMMM('sv_SE').format(focusedMonth),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => _jumpToPage(1),
        ),
      ],
    );
  }

  Widget _calendarBody() {
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        // scrollDirection: Axis.horizontal,
        onPageChanged: (int index) {
          _focusedMonthNotifier.value = _calculateMonth(index);
        },
        itemBuilder: (BuildContext context, int index) {
          final DateTime monthToDisplay = _calculateMonth(index);
          return _buildCalendarMonth(monthToDisplay);
        }
      ),
    );
  }

  Widget _buildCalendarMonth(DateTime month) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int firstDayOffset = DateTime(month.year, month.month).weekday - 1;
    final int totalBoxes = ((firstDayOffset + daysInMonth) / 7).ceil() * 7;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double calendarHeight = constraints.maxHeight - 40;
        final double itemHeight = calendarHeight / (totalBoxes / 7).ceil();

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: itemHeight,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
            ),
            itemCount: totalBoxes,
            itemBuilder: (BuildContext context, int index) {
              final int dayNumber = index - firstDayOffset + 1;
              final bool isDayInMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final DateTime curDay = DateTime(month.year, month.month, dayNumber);

              return GestureDetector(
                onTap: isDayInMonth ? () => _applyTag(curDay) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: isDayInMonth
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            if (_appliedTags.containsKey(curDay))
                              Text(
                                _appliedTags[curDay]!.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                          ],
                        )
                      : const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

