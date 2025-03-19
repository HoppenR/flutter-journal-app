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
  TagTypes? selectedType;
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
          _buildTagFormValidateButton(context),
        ],
      ),
      body: _buildTagFormBody(context),
    );
  }

  Widget _buildTagFormBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildTagFormName(context),
            _buildTagOptionType(context),
            ...?_buildOptionFields(context),
            Text(AppLocalizations.of(context).tagSelectIcon),
            _buildIconSelection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFormName(BuildContext context) {
    return TextFormField(
      controller: tagController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).tagNameHint,
      ),
      validator: (String? value) => value == null || value.isEmpty
          ? AppLocalizations.of(context).tagNameMissing
          : null,
      autofocus: true,
    );
  }

  Widget _buildTagOptionType(BuildContext context) {
    return DropdownButtonFormField<TagTypes>(
      value: selectedType,
      hint: Text(AppLocalizations.of(context).tagSelectType),
      items: <DropdownMenuItem<TagTypes>>[
        DropdownMenuItem<TagTypes>(
          value: TagTypes.list,
          child: Text(AppLocalizations.of(context).tagTypeList),
        ),
        DropdownMenuItem<TagTypes>(
          value: TagTypes.toggle,
          child: Text(AppLocalizations.of(context).tagTypeToggle),
        ),
        DropdownMenuItem<TagTypes>(
          value: TagTypes.multi,
          child: Text(AppLocalizations.of(context).tagTypeMulti),
        ),
      ],
      onChanged: (TagTypes? value) => setState(() {
        selectedType = value;
      }),
      validator: (TagTypes? value) =>
          value == null ? AppLocalizations.of(context).tagTypeMissing : null,
    );
  }

  Widget _buildTagFormValidateButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          // NOTE: selectedType validator asserts not null before this
          switch (selectedType!) {
            case TagTypes.list:
              TagManager().addTagList(
                tagController.text,
                optionControllers
                    .map(
                      (TextEditingController controller) => controller.text,
                    )
                    .toList(growable: false),
                selectedIcon!,
              );
            case TagTypes.toggle:
              TagManager().addTagToggle(
                tagController.text,
                selectedIcon!,
              );
            case TagTypes.multi:
              TagManager().addTagMulti(
                tagController.text,
                optionControllers
                    .map(
                      (TextEditingController controller) => controller.text,
                    )
                    .toList(growable: false),
                selectedIcon!,
              );
          }
          Navigator.of(context).pop(true);
        }
      },
      child: Text(AppLocalizations.of(context).saveTag),
    );
  }

  List<Widget>? _buildOptionFields(BuildContext context) {
    switch (selectedType) {
      case null || TagTypes.toggle:
        return null;
      case TagTypes.list || TagTypes.multi:
        return <Widget>[
          const SizedBox(height: 16.0),
          Text(
            AppLocalizations.of(context).tagOptions,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._buildOptionInputs(context),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() {
              optionControllers.add(TextEditingController());
            }),
          ),
        ];
    }
  }

  Iterable<Row> _buildOptionInputs(BuildContext context) {
    return optionControllers.asMap().entries.map(
      (MapEntry<int, TextEditingController> entry) {
        return Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: entry.value,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).tagAddOption,
                ),
                validator: (String? value) => value == null || value.isEmpty
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
    );
  }

  Widget _buildIconSelection(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double availableWidth = constraints.maxWidth;
          final int maxIconsInRow = availableWidth ~/ (_iconSize + 16.0);
          return _buildIconGridBuilder(context, maxIconsInRow);
        },
      ),
    );
  }

  Widget _buildIconGridBuilder(BuildContext context, int maxIconsInRow) {
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
                color: selectedIcon == icon ? Colors.blue : Colors.transparent,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, size: _iconSize),
          ),
        );
      },
    );
  }
}
