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
  TagData(this.tag, this.value);
  factory TagData.fromJson(Map<String, dynamic> json) {
    return TagData(
      json['tag'],
      json['value'],
    );
  }

  final String tag;
  final String value;

  Map<String, dynamic> toJson() {
    return <String, String>{
      'tag': tag,
      'value': value,
    };
  }
}

enum TagType {
  list,
  boolean,
}

// --- _JournalPageState ---

class _JournalPageState extends State<JournalPage> {
  static const int _initialPage = 500;
  static const double calendarGridEdgeInset = 8.0;
  static const double calendarGridMainAxisSpacing = 10.0;

  // TODO(Hop): Save the tag type as well in this, so we can differentiate
  //            between boolean and list (Use `TagType` enum)
  Map<String, List<String>> _tagNames = <String, List<String>>{};
  // TODO(Hop): Change this to Map<String, Map<String, String>>
  //            so that each day can have multiple tags
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
          .map((String key, dynamic value) => MapEntry<String, List<String>>(
            key,
            List<String>.from(value),
          ));

        _appliedTags = (decodedData['appliedTags'] as Map<String, dynamic>)
          .map((String key, dynamic value) => MapEntry<DateTime, TagData>(
            DateTime.parse(key),
            TagData.fromJson(value),
          ));
      });
    }
  }

  Future<void> _saveTags() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> dataToSave = <String, dynamic>{
      'tagNames': _tagNames,
      'appliedTags': _appliedTags
        .map((DateTime key, TagData value) => MapEntry<String, dynamic>(
          key.toIso8601String(),
          value.toJson(),
        )),
    };

    await prefs.setString('tags', json.encode(dataToSave));
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddTagWindow(BuildContext context) {
    final TextEditingController tagController = TextEditingController();
    final List<TextEditingController>
      optionControllers = <TextEditingController>[TextEditingController()];
    TagType? selectedType;

    showDialog(
      context: context,
      builder: (BuildContext context) => _buildAddTagDialog(
        tagController,
        optionControllers,
        selectedType,
      ),
    );
  }

  // TODO(Christoffer): These dialogs could be Form-widgets in a new page.
  //                    We don't need to see what's behind it and we are
  //                    interacting with it for a longer time.
  Widget _buildAddTagDialog(
    TextEditingController tagController,
    List<TextEditingController> optionControllers,
    TagType? selectedType,
  ) => StatefulBuilder(
    builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
      title: const Text('Add Tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: tagController,
            decoration: const InputDecoration(hintText: 'Enter a tag'),
            onChanged: (String value) {
              setDialogState(() {
                // Trigger an update for the save-button state
              });
            },
          ),
          DropdownButton<TagType>(
            value: selectedType,
            hint: const Text('Select tag type'),
            items: const <DropdownMenuItem<TagType>>[
              DropdownMenuItem<TagType>(
                value: TagType.boolean,
                child: Text('Checkmark'),
              ),
              DropdownMenuItem<TagType>(
                value: TagType.list,
                child: Text('Options'),
              ),
            ],
            onChanged: (TagType? value) {
              setDialogState(() {
                selectedType = value;
              });
            },
          ),
          if (selectedType == TagType.list) ...<Widget>[
            ...optionControllers.map(
              (TextEditingController controller) => TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Enter an option'),
                onChanged: (String value) {
                  setDialogState(() {
                    // Trigger an update for the save-button state
                  });
                },
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
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isTagValid(tagController, selectedType, optionControllers)
          ? () {
            setDialogState(() {
              if (selectedType == TagType.list) {
                _tagNames[tagController.text] = optionControllers
                  .map((TextEditingController controller) => controller.text)
                  .where((String text) => text.isNotEmpty)
                  .toList();
              } else if(selectedType == TagType.boolean) {
                // TODO(Hop): Think through this, rather have small text +
                //            strikethrough when checked?
                //            Need to rethink the entire boolean type
                _tagNames[tagController.text] = <String>['✅', '❎'];
              }
              _showSnackBar(context, 'Tag added');
            });
            _saveTags();
            Navigator.of(context).pop();
          }
          : null,
          child: const Text('Save'),
        ),
      ],
    ),
  );

  bool _isTagValid(
    TextEditingController tagController,
    TagType? selectedType,
    List<TextEditingController> optionControllers,
  ) {
    if (tagController.text.isEmpty) {
      return false;
    }
    if (selectedType == null) {
      return false;
    }
    if (selectedType == TagType.list) {
      return optionControllers.any(
        (TextEditingController controller) => controller.text.isNotEmpty,
      );
    }
    return true;
  }

  void _showApplyTagWindow(BuildContext context, DateTime date) {
    String? selectedTagname;
    String? selectedTagvalue;
    final List<String> optionsList = <String>[];

    showDialog(
      context: context,
      builder: (BuildContext context) => _buildApplyTagDialog(
        date,
        selectedTagname,
        selectedTagvalue,
        optionsList,
      ),
    );
  }

  // TODO(Christoffer): These dialogs could be Form-widgets in a new page.
  //                    We don't need to see what's behind it and we are
  //                    interacting with it for a longer time.
  Widget _buildApplyTagDialog(
    DateTime date,
    String? selectedTagname,
    String? selectedTagvalue,
    List<String> optionsList,
  ) => StatefulBuilder(
    builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
      title: Text('Add Tag for ${DateFormat('yyyy-MM-dd').format(date)}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButton<String>(
            value: selectedTagname,
            hint: const Text('Select Tag'),
            items: _tagNames.keys.map((String key) => DropdownMenuItem<String>(
              value: key,
              child: Text(key),
            )).toList(),
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
              items: optionsList.map((String opt) => DropdownMenuItem<String>(
                value: opt,
                child: Text(opt),
              )).toList(),
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
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: (selectedTagname != null && selectedTagvalue != null)
            ? () {
                setState(() {
                  final TagData td = TagData(
                    selectedTagname!,
                    selectedTagvalue!,
                  );
                  _appliedTags[date] = td;
                });
                _saveTags();
                _showSnackBar(context, 'Tag applied to date');
                Navigator.of(context).pop();
              }
            : null,
          child: const Text('Save'),
        ),
      ],
    ),
  );

  DateTime _calculateMonth(int index) => DateTime(
    _startMonth.year,
    _startMonth.month + index - _initialPage,
  );

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
        onPressed: () => _jumpToPage(-1),
      ),
      // TODO(Hop): Pressing this might open a selection for manually
      //            inputting a date with the builtin flutter picker. And it
      //            should calculate the new `offset` and then call
      //            `_jumpToPage(offset)` with that.
      ValueListenableBuilder<DateTime>(
        valueListenable: _focusedMonthNotifier,
        builder: (BuildContext context, DateTime month, Widget? child) => Text(
          DateFormat.yMMMM('sv_SE').format(month),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => _jumpToPage(1),
      ),
    ],
  );

  Widget _calendarBody() => Expanded(
    child: PageView.builder(
      controller: _pageController,
      // scrollDirection: Axis.horizontal,
      onPageChanged: (int index) {
        _focusedMonthNotifier.value = _calculateMonth(index);
      },
      itemBuilder: (BuildContext context, int index) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Padding(
          padding: const EdgeInsets.all(calendarGridEdgeInset),
          child: _buildCalendarMonth(constraints, index),
        ),
      ),
    ),
  );

  Widget _buildCalendarMonth(
    BoxConstraints constraints,
    int index,
  ) {
    final DateTime month = _calculateMonth(index);
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int firstDayOffset = DateTime(month.year, month.month).weekday - 1;
    final int totalBoxes = ((firstDayOffset + daysInMonth) / 7).ceil() * 7;
    final int rowCount = (totalBoxes / 7).ceil();
    final double calendarHeight = constraints.maxHeight - (
      (rowCount - 1) * calendarGridMainAxisSpacing + 2 * calendarGridEdgeInset
    );
    final double itemHeight = calendarHeight / (totalBoxes / 7).ceil();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: itemHeight,
        mainAxisSpacing: calendarGridMainAxisSpacing,
        crossAxisSpacing: 10.0,
      ),
      itemCount: totalBoxes,
      itemBuilder: (BuildContext context, int index) {
        final int dayNumber = index - firstDayOffset + 1;
        final bool isDayInMonth = dayNumber > 0 && dayNumber <= daysInMonth;
        final DateTime curDay = DateTime(month.year, month.month, dayNumber);

        return TextButton(
          onPressed: isDayInMonth
            // TODO(Christoffer): Display a page with the applied tags,
            //                    with a plus button to add a new tag.
            //                    Reason being to be able to edit/remove tags
            //                    as well as view/add them in a single screen.
            ? () => _showApplyTagWindow(context, curDay)
            : null,
          style: _buttonStyle(context),
          child: isDayInMonth
            ? _buttonContent(context, curDay)
            : const SizedBox.shrink(),
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
      if (_appliedTags.containsKey(curDay))
        Text(
          _appliedTags[curDay]!.value,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
    ],
  );
}
