// Vim: set shiftwidth=2 :
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'tag.dart';
import 'tag_overview.dart';
import 'utility.dart';

class CalendarWeek extends StatefulWidget {
  const CalendarWeek(this.weekStartDate, {super.key});

  final DateTime weekStartDate;

  @override
  CalendarWeekState createState() => CalendarWeekState();
}

class CalendarWeekState extends State<CalendarWeek> {
  static const double calendarGridEdgeInset = 8.0;

  bool _isExpanded = false;

  double _getMaxTagColumnWidth() {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: tagNames.keys.reduce(
          (String a, String b) => a.length > b.length ? a : b,
        ),
        style: const TextStyle(fontSize: 16.0),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return textPainter.size.width;
  }

  void _showTagDayOverview(BuildContext context, DateTime day) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => TagDayOverview(day),
      ),
    ).then((_) {
      setState(() {
        saveTags();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double totalSpacing = (tagNames.length - 1) * 4.0;
        final double cellHeight = (
          constraints.maxHeight - 2 * calendarGridEdgeInset - totalSpacing
        ) / tagNames.length;

        return Padding(
          padding: const EdgeInsets.all(calendarGridEdgeInset),
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  // TODO(Christoffer): Use a global constant
                  width: _isExpanded ? _getMaxTagColumnWidth() : 40.0,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisExtent: cellHeight,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: tagNames.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Container(
                          height: cellHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                tagNames.values.elementAt(index).icon,
                                // TODO(Christoffer): Use a global constant
                                size: 40.0,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _isExpanded ? 1.0 : 0.0,
                                child: Text(
                                  tagNames.keys.elementAt(index),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: DateTime.daysPerWeek,
                    mainAxisExtent: cellHeight,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                  ),
                  itemCount: tagNames.length * DateTime.daysPerWeek,
                  itemBuilder: (BuildContext context, int index) {
                    final int dayIndex = index % DateTime.daysPerWeek;
                    final int tagIndex = index ~/ DateTime.daysPerWeek;
                    final DateTime curDay = widget.weekStartDate.add(
                      Duration(days: dayIndex),
                    );
                    return TextButton(
                      onPressed: () => _showTagDayOverview(context, curDay),
                      style: _buttonStyle(context),
                      child: _buttonContent(context, curDay, tagIndex),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
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
    int tagIndex,
  ) {
    final String targetTagName = tagNames.keys.elementAt(tagIndex);
    AppliedTagData? tag;
    if (appliedTags.containsKey(curDay)) {
      tag = appliedTags[curDay]?.firstWhereOrNull(
        (AppliedTagData t) => t.tagData.name == targetTagName,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (tagIndex == 0)
          Text(_getWeekdayAbbreviation(curDay.weekday)),
        const Spacer(),
        if (tag != null)
          if (tag.tagData.type == TagType.list)
            Text(
              tag.string,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
        if (tag != null)
          if (tag.tagData.type == TagType.toggle && (tag.toggleOption ?? false))
            Icon(
              tag.tagData.icon,
              size: 40.0,
            ),
        const Spacer(),
      ]
    );
  }

  String _getWeekdayAbbreviation(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'M';
      case DateTime.tuesday: return 'Ti';
      case DateTime.wednesday: return 'O';
      case DateTime.thursday: return 'To';
      case DateTime.friday: return 'F';
      case DateTime.saturday: return 'L';
      case DateTime.sunday: return 'S';
      default: throw AssertionError('invalid day');
    }
  }
}
