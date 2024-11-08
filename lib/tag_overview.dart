// Vim: set shiftwidth=2 :
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'tag.dart';

class TagDayOverview extends StatefulWidget {
  const TagDayOverview(DateTime day, {super.key}) : _day = day;

  final DateTime _day;

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
        widget._day,
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
    builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
      title: Text('Add Tag for ${DateFormat('yyyy-MM-dd').format(date)}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButton<String>(
            value: selectedTagName,
            hint: const Text('Select Tag'),
            items: tagNames.keys.map((String key) => DropdownMenuItem<String>(
              value: key,
              child: Text(key),
            )).toList(),
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
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Tag Overview'),
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
              IconButton(
                // <++>
                icon: const Icon(Icons.add),
                onPressed: () => _showApplyTagWindow(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
