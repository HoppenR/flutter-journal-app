// Vim: set shiftwidth=2 :
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'tag.dart';

class TagDayOverview extends StatefulWidget {
  const TagDayOverview(DateTime day, {super.key}) : _date = day;

  final DateTime _date;

  @override
  TagDayOverviewState createState() => TagDayOverviewState();
}

class TagDayOverviewState extends State<TagDayOverview> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _showApplyTagWindow(BuildContext context) {
    String? selectedTagName;
    TagData? selectedTagData;
    Object? tagData;

    showDialog(
      context: context,
      builder: (BuildContext context) => _buildApplyTagDialog(
        widget._date,
        selectedTagName,
        selectedTagData,
        tagData,
      ),
    );
  }

  Widget _buildApplyTagDialog(
    DateTime date,
    String? selectedTagName,
    TagData? selectedTagData,
    Object? selectedTagOption,
  ) => StatefulBuilder(
    builder: (BuildContext context, StateSetter setDialogState) {
    final appliedTagNames = appliedTags[date]?.map((tag) => tag.name).toSet() ?? <String>{};

      return AlertDialog(
        title: Text('Add Tag for ${DateFormat('yyyy-MM-dd').format(date)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButton<String>(
              value: selectedTagName,
              hint: const Text('Select Tag'),
              // TODO(Christoffer): Filter out already applied tags
              items: tagNames.keys
                .where((String key) => !appliedTagNames.contains(key))
                .map((String key) => DropdownMenuItem<String>(
                  value: key,
                  child: Text(key),
                ),
              ).toList(),
              onChanged: (String? value) {
                setDialogState(() {
                  selectedTagName = value;
                  if (value != null && tagNames.containsKey(value)) {
                    selectedTagData = tagNames[value];
                  }
                  selectedTagOption = null;
                });
              },
            ),
            if (selectedTagData != null && selectedTagData!.type == TagType.list)
              ...<Widget>[
                const Text('Select an option:'),
                DropdownButton<String>(
                  value: selectedTagOption != null
                    ? selectedTagData!.list[selectedTagOption! as int]
                    : null,
                  hint: const Text('Options'),
                  items: selectedTagData!.list.map(
                    (String opt) => DropdownMenuItem<String>(
                      value: opt,
                      child: Text(opt),
                    ),
                  ).toList(),
                  onChanged: (String? value) {
                    setDialogState(() {
                      selectedTagOption = selectedTagData!.list.indexOf(value!);
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
            onPressed: (
              selectedTagData?.type == TagType.strikethrough ||
              (
                selectedTagData?.type == TagType.list &&
                selectedTagOption != null
              )
            ) ? () {
                  setState(() {
                    AppliedTagData? td;
                    switch (selectedTagData!.type) {
                      case TagType.list:
                        td = AppliedTagData.list(
                          selectedTagData!,
                          selectedTagOption! as int,
                        );
                      case TagType.strikethrough:
                        td = AppliedTagData.strikethrough(
                          selectedTagData!,
                        );
                    }
                    final List<AppliedTagData> tagList = appliedTags.putIfAbsent(
                      date,
                      () => <AppliedTagData>[],
                    );
                    final int existingTagIndex = tagList.indexWhere(
                      (AppliedTagData tag) => tag.name == selectedTagName,
                    );
                    if (existingTagIndex != -1) {
                      tagList[existingTagIndex] = td;
                    } else {
                      tagList.add(td);
                    }
                  });
                  Navigator.of(context).pop();
                }
              : null,
            child: const Text('Save'),
          ),
        ],
      );
    }
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          'Tag Overview (${DateFormat('yyyy-MM-dd').format(widget._date)})',
        ),
        actions: const <Widget>[
        ],
      ),
      // TODO(Christoffer): Display all the currently applied tags,
      //                    with a plus button to add a new tag.
      //                    Reason being to be able to edit/remove tags
      //                    as well as view/add them in a single screen.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...tagNames.entries.map((MapEntry<String, TagData> entry) {
                final String tagName = entry.key;
                final TagData tagData = entry.value;
                final List<AppliedTagData>? tagList = appliedTags[widget._date];
                final AppliedTagData? appliedTagData = tagList?.firstWhereOrNull(
                  (AppliedTagData tag) => tag.name == tagName,
                );
                return Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '$tagName : ${appliedTagData?.string ?? 'No data'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    if (appliedTagData != null) ...<Widget>[
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // TODO(Christoffer): Implement an edit tag form
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            appliedTags[widget._date]!.remove(appliedTagData);
                            if (appliedTags[widget._date]!.isEmpty) {
                              appliedTags.remove(widget._date);
                            }
                          });
                        },
                      ),
                    ] else
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          // TODO(Christoffer): Implement adding a new tag
                          _showApplyTagWindow(context);
                        },
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
