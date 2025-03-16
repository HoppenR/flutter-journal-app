// Vim: set shiftwidth=2 :
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'generated/l10n/app_localizations.dart';
import 'tag.dart';

class TagDayOverview extends StatefulWidget {
  const TagDayOverview(DateTime day, {super.key}) : _date = day;

  final DateTime _date;

  @override
  TagDayOverviewState createState() => TagDayOverviewState();
}

class TagDayOverviewState extends State<TagDayOverview> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          AppLocalizations.of(context).tagOverviewTitle(widget._date),
        ),
        actions: const <Widget>[],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...tagData.entries.map((MapEntry<String, TagData> entry) {
                final String tagName = entry.key;
                final TagData tagData = entry.value;
                return _buildTagRow(context, tagName, tagData);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagRow(BuildContext context, String tagName, TagData tagData) {
    final List<AppliedTagData>? tagList = appliedTags[widget._date];
    final AppliedTagData? appliedTagData = tagList?.firstWhereOrNull(
      (AppliedTagData tag) => tag.name == tagName,
    );
    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Text(
                '$tagName: ',
                style: const TextStyle(fontSize: 18),
              ),
              _buildTagRowContent(tagName, tagData, appliedTagData),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          color: appliedTagData != null ? Colors.black : Colors.grey,
          onPressed: appliedTagData != null
              ? () {
                  setState(() {
                    appliedTags[widget._date]!.remove(appliedTagData);
                    if (appliedTags[widget._date]!.isEmpty) {
                      appliedTags.remove(widget._date);
                    }
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildTagRowContent(
      String tagName, TagData tagData, AppliedTagData? appliedTagData) {
    switch (tagData.type) {
      case TagType.list:
        return _buildTagOptions(context, tagData);
      case TagType.toggle:
        return Switch(
          value: appliedTagData?.toggleOption ?? false,
          onChanged: (bool value) {
            _handleToggleChange(tagData, value);
          },
        );
      case TagType.multi:
        return _buildTagOptions(context, tagData);
    }
  }

  Widget _buildTagOptions(BuildContext context, TagData tagData) {
    return Row(
      children: tagData.list.asMap().entries.map(
        (MapEntry<int, String> listEntry) {
          final int index = listEntry.key;
          final String option = listEntry.value;
          final bool isSelected =
              appliedTags[widget._date]?.any((AppliedTagData tag) {
                    if (tag.name != tagData.name) {
                      return false;
                    }
                    if (tag.type == TagType.list) {
                      return tag.listOption == index;
                    } else if (tag.type == TagType.multi) {
                      return tag.multiOptions?.contains(index) ?? false;
                    }
                    return false;
                  }) ??
                  false;
          return TextButton(
            onPressed: () {
              _handleTagSelection(tagData, index);
            },
            style: TextButton.styleFrom(
              foregroundColor: isSelected ? Colors.white : Colors.black,
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.inversePrimary,
            ),
            child: Text(option),
          );
        },
      ).toList(),
    );
  }

  void _handleTagSelection(TagData tagData, int index) {
    final bool dateExists = appliedTags.containsKey(widget._date);
    if (!dateExists) {
      appliedTags[widget._date] = <AppliedTagData>[];
    }

    final int tagIndex = appliedTags[widget._date]!.indexWhere(
      (AppliedTagData tag) => tag.name == tagData.name,
    );

    if (tagData.type == TagType.list) {
      if (tagIndex != -1) {
        appliedTags[widget._date]![tagIndex].listOption = index;
      } else {
        appliedTags[widget._date]!.add(AppliedTagData.list(tagData, index));
      }
    } else if (tagData.type == TagType.multi) {
      if (tagIndex != -1) {
        appliedTags[widget._date]![tagIndex].multiOptions!.contains(index)
            ? appliedTags[widget._date]![tagIndex].multiOptions!.remove(index)
            : appliedTags[widget._date]![tagIndex].multiOptions!.add(index);
      } else {
        appliedTags[widget._date]!
            .add(AppliedTagData.multi(tagData, <int>[index]));
      }
    }
    setState(() {});
  }

  void _handleToggleChange(TagData tagData, bool value) {
    if (!appliedTags.containsKey(widget._date)) {
      appliedTags[widget._date] = <AppliedTagData>[];
    }

    final int tagIndex = appliedTags[widget._date]!.indexWhere(
      (AppliedTagData tag) => tag.name == tagData.name,
    );

    if (tagIndex != -1) {
      appliedTags[widget._date]![tagIndex].toggleOption = value;
    } else {
      final AppliedTagData newTag = AppliedTagData.toggle(tagData, false);
      newTag.toggleOption = value;
      appliedTags[widget._date]!.add(newTag);
    }
    setState(() {});
  }
}
