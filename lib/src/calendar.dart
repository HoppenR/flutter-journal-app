import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import 'tag/appliedtag.dart';
import 'tag/manager.dart';
import 'tag/tag.dart';
import 'tag/tag_overview.dart';

class CalendarWeek extends StatefulWidget {
  const CalendarWeek({super.key, required this.weekStartDate});

  final DateTime weekStartDate;

  @override
  CalendarWeekState createState() => CalendarWeekState();
}

class CalendarWeekState extends State<CalendarWeek> {
  bool _isExpanded = false;

  double _getMaxTagColumnWidth(BuildContext context) {
    final TagManager tagManager = context.watch<TagManager>();
    final Tag longestTag = tagManager.tags.values.reduce(
      (Tag lhs, Tag rhs) {
        if (lhs.name.length > rhs.name.length) {
          return lhs;
        }
        return rhs;
      },
    );

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: longestTag.name,
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
        builder: (BuildContext context) => TagDayOverview(day: day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double gridEdgeInset = 8.0;
    final TagManager tagManager = context.watch<TagManager>();
    return LayoutBuilder(builder: (
      BuildContext context,
      BoxConstraints constraints,
    ) {
      final int tagCount = tagManager.tags.length;
      final double totalSpacing = (tagCount - 1) * 4.0;
      final double cellHeight =
          (constraints.maxHeight - 2 * gridEdgeInset - totalSpacing) / tagCount;

      return Padding(
        padding: const EdgeInsets.all(gridEdgeInset),
        child: Row(
          children: <Widget>[
            _buildTagBannerColumn(context, cellHeight, tagCount),
            const SizedBox(width: 4.0),
            Expanded(
              child: _buildCalendarGrid(context, cellHeight),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCalendarGrid(BuildContext context, double cellHeight) {
    final TagManager tagManager = context.watch<TagManager>();
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: DateTime.daysPerWeek,
        mainAxisExtent: cellHeight,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: tagManager.tags.length * DateTime.daysPerWeek,
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
    );
  }

  Widget _buildTagBannerColumn(
    BuildContext context,
    double cellHeight,
    int tagCount,
  ) {
    return GestureDetector(
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
          itemCount: tagCount,
          itemBuilder: (BuildContext context, int index) {
            return _buildTagBannerCell(context, index, cellHeight);
          },
        ),
      ),
    );
  }

  Widget _buildTagBannerCell(
    BuildContext context,
    int index,
    double cellHeight,
  ) {
    final TagManager tagManager = context.watch<TagManager>();
    final Tag curTag = tagManager.tags.values.elementAt(index);
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
              curTag.icon,
              size: 40.0,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isExpanded ? 1.0 : 0.0,
            child: Text(
              curTag.name,
              style: const TextStyle(fontSize: 16.0),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
    final TagManager tagManager = context.watch<TagManager>();
    final int targetTagId = tagManager.tags.keys.elementAt(tagIndex);
    final AppliedTag? tag = tagManager.appliedTags[curDay]
        ?.firstWhereOrNull((AppliedTag t) => t.id == targetTagId);
    final Widget? tagShorthand = _buildTagShorthand(tag);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (tagIndex == 0)
          Positioned(
            top: 0.0,
            child: Text(_getWeekdayAbbreviation(context, curDay)),
          ),
        if (tagShorthand != null) Center(child: tagShorthand),
      ],
    );
  }

  Widget? _buildTagShorthand(AppliedTag? appliedTag) {
    if (appliedTag == null) {
      return null;
    }

    switch (appliedTag) {
      case AppliedList():
        return Text(
          appliedTag.string(),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18.0,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      case AppliedMulti():
        if (appliedTag.options.isEmpty) {
          return null;
        } else if (appliedTag.options.length == 1) {
          return Text(
            appliedTag.string(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18.0,
              color: Theme.of(context).colorScheme.secondary,
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
              shape: BoxShape.circle,
              border: Border.all(),
            ),
            constraints: const BoxConstraints(
              minWidth: 32.0,
              minHeight: 32.0,
            ),
            child: Text(
              appliedTag.options.length.toString(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
      case AppliedToggle():
        return Icon(
          appliedTag.tag.icon,
          color: (appliedTag.option)
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          size: 40.0,
        );
    }
  }

  String _getWeekdayAbbreviation(BuildContext context, DateTime date) {
    return intl.DateFormat.E(
      Localizations.localeOf(context).languageCode,
    ).format(date);
  }
}
