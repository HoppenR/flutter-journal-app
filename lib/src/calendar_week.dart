import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  double _getMaxTagColumnWidth(BuildContext context) {
    final String longestTag = tagData.keys.reduce(
      (String a, String b) => a.length > b.length ? a : b,
    );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: longestTag,
        style: const TextStyle(fontSize: 16.0),
      ),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout(minWidth: 40.0, maxWidth: 120.0);

    return textPainter.width + 8.0;
  }

  Future<void> _showTagDayOverview(BuildContext context, DateTime day) async {
    await Navigator.push<bool?>(
      context,
      MaterialPageRoute<bool?>(
        builder: (BuildContext context) => TagDayOverview(day),
      ),
    );

    setState(() {
      saveAppliedTags();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final double totalSpacing = (tagData.length - 1) * 4.0;
      final double cellHeight =
          (constraints.maxHeight - 2 * calendarGridEdgeInset - totalSpacing) /
              tagData.length;

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
                width: _isExpanded ? _getMaxTagColumnWidth(context) : 40.0,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisExtent: cellHeight,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                  ),
                  itemCount: tagData.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      height: cellHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _isExpanded ? 0.0 : 1.0,
                            child: Icon(
                              tagData.values.elementAt(index).icon,
                              size: 40.0,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _isExpanded ? 1.0 : 0.0,
                            child: Text(
                              tagData.keys.elementAt(index),
                              style: const TextStyle(fontSize: 16.0),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                itemCount: tagData.length * DateTime.daysPerWeek,
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
    });
  }

  ButtonStyle _buttonStyle(BuildContext context) {
    return TextButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(
            alpha: 0.1,
          ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buttonContent(
    BuildContext context,
    DateTime curDay,
    int tagIndex,
  ) {
    final String targetTagName = tagData.keys.elementAt(tagIndex);
    AppliedTagData? tag;
    if (appliedTags.containsKey(curDay)) {
      tag = appliedTags[curDay]?.firstWhereOrNull(
        (AppliedTagData t) => t.tagData.name == targetTagName,
      );
    }
    final Widget? tagShorthand = _buildTagShorthand(tag);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (tagIndex == 0) Text(_getWeekdayAbbreviation(context, curDay)),
        const Spacer(),
        if (tagShorthand != null) tagShorthand,
        const Spacer(),
      ],
    );
  }

  Widget? _buildTagShorthand(AppliedTagData? tag) {
    if (tag == null) {
      return null;
    }
    switch (tag.type) {
      case TagType.list:
        return Text(
          tag.string,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      case TagType.toggle:
        return Icon(
          tag.tagData.icon,
          color: (tag.toggleOption ?? false)
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          size: 40.0,
        );
      case TagType.multi:
        if (tag.multiOptions!.isEmpty) {
          return null;
        } else if (tag.multiOptions!.length == 1) {
          return Text(
            tag.string,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
          );
        } else {
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              const Icon(
                Icons.edit_note_rounded,
                size: 32.0,
              ),
              Positioned(
                right: -1.0,
                top: -8.0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    shape: BoxShape.circle,
                    border: Border.all(),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    tag.multiOptions!.length.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }
    }
  }

  String _getWeekdayAbbreviation(BuildContext context, DateTime date) {
    return DateFormat.E(
      Localizations.localeOf(context).languageCode,
    ).format(date);
  }
}
