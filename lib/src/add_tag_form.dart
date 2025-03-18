import 'package:flutter/material.dart';

import 'generated/l10n/app_localizations.dart';
import 'tag.dart';

class AddTagForm extends StatefulWidget {
  const AddTagForm({super.key});

  @override
  AddTagFormState createState() => AddTagFormState();
}

class AddTagFormState extends State<AddTagForm> {
  final TextEditingController tagController = TextEditingController();
  final List<TextEditingController> optionControllers = <TextEditingController>[
    TextEditingController(),
  ];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TagType? selectedType;
  IconData? selectedIcon = Icons.favorite;

  static const double _iconSize = 40.0;

  @override
  void dispose() {
    tagController.dispose();
    for (final TextEditingController controller in optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context).addTag),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                // NOTE: selectedType validator asserts not null before this
                switch (selectedType!) {
                  case TagType.list:
                    tagData[tagController.text] = TagData.list(
                      tagController.text,
                      optionControllers
                          .map(
                            (TextEditingController controller) =>
                                controller.text,
                          )
                          .toList(growable: false),
                      selectedIcon!,
                    );
                  case TagType.toggle:
                    tagData[tagController.text] = TagData.toggle(
                      tagController.text,
                      selectedIcon!,
                    );
                  case TagType.multi:
                    tagData[tagController.text] = TagData.multi(
                      tagController.text,
                      optionControllers
                          .map(
                            (TextEditingController controller) =>
                                controller.text,
                          )
                          .toList(growable: false),
                      selectedIcon!,
                    );
                }
                Navigator.of(context).pop(true);
              }
            },
            child: Text(AppLocalizations.of(context).saveTag),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: tagController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).tagNameHint,
                ),
                validator: (String? value) => value == null || value.isEmpty
                    ? AppLocalizations.of(context).tagNameMissing
                    : null,
                autofocus: true,
              ),
              DropdownButtonFormField<TagType>(
                value: selectedType,
                hint: Text(AppLocalizations.of(context).tagSelectType),
                items: <DropdownMenuItem<TagType>>[
                  DropdownMenuItem<TagType>(
                    value: TagType.list,
                    child: Text(AppLocalizations.of(context).tagTypeList),
                  ),
                  DropdownMenuItem<TagType>(
                    value: TagType.toggle,
                    child: Text(AppLocalizations.of(context).tagTypeToggle),
                  ),
                  DropdownMenuItem<TagType>(
                    value: TagType.multi,
                    child: Text(AppLocalizations.of(context).tagTypeMulti),
                  ),
                ],
                onChanged: (TagType? value) => setState(() {
                  selectedType = value;
                }),
                validator: (TagType? value) => value == null
                    ? AppLocalizations.of(context).tagTypeMissing
                    : null,
              ),
              ...?_buildOptionFields(),
              Text(AppLocalizations.of(context).tagSelectIcon),
              _buildIconSelection(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget>? _buildOptionFields() {
    switch (selectedType) {
      case null || TagType.toggle:
        return null;
      case TagType.list || TagType.multi:
        return <Widget>[
          const SizedBox(height: 16.0),
          Text(
            AppLocalizations.of(context).tagOptions,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...optionControllers.asMap().entries.map(
            (MapEntry<int, TextEditingController> entry) {
              return Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).tagAddOption,
                      ),
                      validator: (String? value) =>
                          value == null || value.isEmpty
                              ? AppLocalizations.of(context).tagOptionMissing
                              : null,
                      onChanged: (String? value) => setState(() {}),
                    ),
                  ),
                  if (entry.key > 0)
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () => setState(() {
                        optionControllers.removeAt(entry.key);
                      }),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() {
              optionControllers.add(TextEditingController());
            }),
          ),
        ];
    }
  }

  Widget _buildIconSelection() {
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double availableWidth = constraints.maxWidth;
          final int maxIconsInRow = availableWidth ~/ (_iconSize + 16.0);

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: maxIconsInRow,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (BuildContext context, int index) {
              final int codePoint = availableIcons.keys.elementAt(index);
              final IconData icon = availableIcons[codePoint]!;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIcon = icon;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedIcon == icon
                          ? Colors.blue
                          : Colors.transparent,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(icon, size: _iconSize),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
