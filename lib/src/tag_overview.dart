import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'generated/l10n/app_localizations.dart';
import 'tag.dart';
import 'utility.dart';

class TagDayOverview extends StatefulWidget {
  const TagDayOverview({super.key, required this.day});

  final DateTime day;

  @override
  TagDayOverviewState createState() => TagDayOverviewState();
}

class TagDayOverviewState extends State<TagDayOverview> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Timer? _debouncedSaveTimer;
  bool _hasMadeChanges = false;
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          return;
        }
        if (_debouncedSaveTimer?.isActive ?? false) {
          _debouncedSaveTimer!.cancel();
          _saveCallback(context);
        }
        Navigator.of(context).pop(_hasMadeChanges);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(
            AppLocalizations.of(context).tagOverviewTitle(widget.day),
          ),
          actions: <Widget>[
            Text(AppLocalizations.of(context).moveModeToggle),
            Switch(
              value: _editMode,
              onChanged: (bool newValue) {
                setState(() {
                  _editMode = newValue;
                });
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: _editMode
                ? _buildReorderableTagList(context)
                : _buildDismissibleTagList(context),
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableTagList(BuildContext context) {
    final TagManager tagManager = context.read<TagManager>();
    final List<TagData> orderedTags = tagManager.tags.values
        .sorted((TagData lhs, TagData rhs) => lhs.order - rhs.order);
    return ReorderableListView(
      onReorder: (int oldIndex, int newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final TagData oldIndexTag = orderedTags.elementAt(oldIndex);
        final int oldIndexOrder = oldIndexTag.order;
        final int newIndexOrder = orderedTags.elementAt(newIndex).order;

        for (final TagData tag in tagManager.tags.values) {
          if (tag.order < oldIndexOrder && tag.order >= newIndexOrder) {
            tag.order += 1;
          } else if (tag.order > oldIndexOrder && tag.order <= newIndexOrder) {
            tag.order -= 1;
          }
        }
        oldIndexTag.order = newIndexOrder;
        _debounceSave(context);
      },
      children: orderedTags.map(_buildReorderTagRow).toList(growable: false),
    );
  }

  Widget _buildReorderTagRow(TagData entry) {
    final TagManager tagManager = context.read<TagManager>();
    final AppliedTagData? appliedTagData = tagManager.appliedTags[widget.day]
        ?.firstWhereOrNull((AppliedTagData tag) => tag.id == entry.id);
    return _buildTagRow(entry, appliedTagData);
  }

  Widget _buildDismissibleTagList(BuildContext context) {
    final TagManager tagManager = context.read<TagManager>();
    return Column(
      children: tagManager.tags.values
          .sorted((TagData lhs, TagData rhs) => lhs.order - rhs.order)
          .map((TagData entry) => _buildDismissibleTagRow(context, entry))
          .toList(growable: false),
    );
  }

  Widget _buildDismissibleTagRow(BuildContext context, TagData tagData) {
    final TagManager tagManager = context.read<TagManager>();
    final AppliedTagData? appliedTagData = tagManager.appliedTags[widget.day]
        ?.firstWhereOrNull((AppliedTagData tag) => tag.id == tagData.id);

    return Dismissible(
      key: tagData.key,
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          return _showDeleteTagWindow(context);
        } else if (direction == DismissDirection.endToStart) {
          if (appliedTagData != null) {
            tagManager.unapplyTag(appliedTagData, widget.day);
          }
          _debounceSave(context);
          return false;
        }
        return true;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            Theme.of(context).colorScheme.primary.withAlpha(108),
            Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        child: const Row(
          children: <Widget>[
            SizedBox(width: 10.0),
            Icon(Icons.delete),
            Spacer(),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryFixed,
        ),
        child: const Row(
          children: <Widget>[
            Spacer(),
            Icon(Icons.restore),
            SizedBox(width: 10.0),
          ],
        ),
      ),
      onDismissed: (DismissDirection direction) {
        if (direction == DismissDirection.startToEnd) {
          tagManager.removeTag(tagData.id);
          _debounceSave(context);
        }
      },
      child: _buildTagRow(tagData, appliedTagData),
    );
  }

  List<Widget> _buildTagOptions(BuildContext context, TagData tagData) {
    final TagManager tagManager = context.read<TagManager>();

    return List<Widget>.generate(
      tagData.list.length,
      (int index) {
        final bool isSelected = tagManager.appliedTags[widget.day]?.any(
              (AppliedTagData tag) {
                if (tag.id != tagData.id) {
                  return false;
                }
                final TagTypes type = tagManager.tags[tag.id]!.type;
                switch (type) {
                  case TagTypes.list:
                    return tag.listOption == index;
                  case TagTypes.multi:
                    return tag.multiOptions?.contains(index) ?? false;
                  case TagTypes.toggle:
                    throw ArgumentError.value(
                      type,
                      'tag.type',
                      'argument does not have tag options',
                    );
                }
              },
            ) ??
            false;
        return ChoiceChip(
          label: Text(tagData.list[index]),
          selected: isSelected,
          onSelected: (bool selected) => _handleTagSelection(tagData, index),
        );
      },
      growable: false,
    );
  }

  void _handleTagSelection(TagData tagData, int index) {
    final TagManager tagManager = context.read<TagManager>();
    final int tagIndex = tagManager.appliedTags[widget.day]
            ?.indexWhere((AppliedTagData tag) => tag.id == tagData.id) ??
        -1;

    switch (tagData.type) {
      case TagTypes.list:
        if (tagIndex != -1) {
          final AppliedTagData appliedTag =
              tagManager.appliedTags[widget.day]![tagIndex];
          tagManager.changeListOption(appliedTag, index);
        } else {
          tagManager.applyTag(
            AppliedTagData.list(tagData.id, index),
            widget.day,
          );
        }
      case TagTypes.toggle:
        throw ArgumentError.value(
          tagData.type,
          'tagData.type',
          'argument does not have tag options',
        );
      case TagTypes.multi:
        if (tagIndex != -1) {
          final AppliedTagData appliedTag =
              tagManager.appliedTags[widget.day]![tagIndex];
          tagManager.toggleMultiOption(appliedTag, index);
        } else {
          tagManager.applyTag(
            AppliedTagData.multi(tagData.id, <int>[index]),
            widget.day,
          );
        }
    }
    _debounceSave(context);
  }

  void _handleToggleChange(TagData tagData, bool value) {
    final TagManager tagManager = context.read<TagManager>();

    final int tagIndex = tagManager.appliedTags[widget.day]
            ?.indexWhere((AppliedTagData tag) => tag.id == tagData.id) ??
        -1;

    if (tagIndex != -1) {
      final AppliedTagData appliedTag =
          tagManager.appliedTags[widget.day]![tagIndex];
      tagManager.toggleTo(appliedTag, value);
    } else {
      final AppliedTagData newTag = AppliedTagData.toggle(tagData.id, value);
      tagManager.applyTag(newTag, widget.day);
    }
    _debounceSave(context);
  }

  void _debounceSave(BuildContext context) {
    _debouncedSaveTimer?.cancel();
    _debouncedSaveTimer = Timer(
      const Duration(seconds: 3),
      () => _saveCallback(context),
    );
    _hasMadeChanges = true;
  }

  void _saveCallback(BuildContext context) {
    saveTagData(context);
    saveAppliedTags(context);
  }

  Widget _buildTagRow(TagData tagData, AppliedTagData? appliedTagData) {
    return Column(
      key: tagData.key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(tagData.icon, size: 40.0),
            Expanded(
              child: Text(
                tagData.name,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Wrap(
          runSpacing: 4.0,
          spacing: 8.0,
          children: _buildTagRowContent(tagData, appliedTagData),
        ),
      ],
    );
  }

  List<Widget> _buildTagRowContent(
    TagData tagData,
    AppliedTagData? appliedTagData,
  ) {
    switch (tagData.type) {
      case TagTypes.list:
        return _buildTagOptions(context, tagData);
      case TagTypes.toggle:
        return <Widget>[
          Switch(
            value: appliedTagData?.toggleOption ?? false,
            onChanged: (bool value) {
              _handleToggleChange(tagData, value);
            },
          ),
        ];
      case TagTypes.multi:
        return _buildTagOptions(context, tagData);
    }
  }

  Future<bool> _showDeleteTagWindow(BuildContext context) async {
    final bool? didDeleteTag = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).clearDataTitle),
          content: Text(AppLocalizations.of(context).clearDataPrompt),
          actions: <Widget>[
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(AppLocalizations.of(context).promptNegative),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                AppLocalizations.of(context).promptAffirmative,
              ),
            ),
          ],
        );
      },
    );
    return didDeleteTag ?? false;
  }
}
