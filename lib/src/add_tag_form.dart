import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'generated/l10n/app_localizations.dart';
import 'tag.dart';

class AddTagForm extends StatefulWidget {
  const AddTagForm({super.key});

  @override
  AddTagFormState createState() => AddTagFormState();
}

class AddTagFormState extends State<AddTagForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _optionControllers =
      <TextEditingController>[
    TextEditingController(),
  ];
  final TextEditingController _tagController = TextEditingController();

  TagTypes? _selectedType;
  IconData _selectedIcon = Icons.favorite;

  static const double _iconSize = 40.0;

  @override
  void dispose() {
    _tagController.dispose();
    for (final TextEditingController controller in _optionControllers) {
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
      controller: _tagController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).tagNameHint,
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context).tagNameMissing;
        }
        return null;
      },
      autofocus: true,
    );
  }

  Widget _buildTagOptionType(BuildContext context) {
    return DropdownButtonFormField<TagTypes>(
      value: _selectedType,
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
      onChanged: (TagTypes? value) {
        setState(() {
          _selectedType = value;
        });
      },
      validator: (TagTypes? value) {
        if (value == null) {
          return AppLocalizations.of(context).tagTypeMissing;
        }
        return null;
      },
    );
  }

  Widget _buildTagFormValidateButton(BuildContext context) {
    final TagManager tagManager = context.read<TagManager>();
    return TextButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          // NOTE: selectedType validator asserts not null before this
          switch (_selectedType!) {
            case TagTypes.list:
              tagManager.addTagList(
                _tagController.text,
                _optionControllers
                    .map((TextEditingController controller) => controller.text)
                    .toList(growable: false),
                _selectedIcon,
              );
            case TagTypes.toggle:
              tagManager.addTagToggle(
                _tagController.text,
                _selectedIcon,
              );
            case TagTypes.multi:
              tagManager.addTagMulti(
                _tagController.text,
                _optionControllers
                    .map((TextEditingController controller) => controller.text)
                    .toList(growable: false),
                _selectedIcon,
              );
          }
          Navigator.of(context).pop(true);
        }
      },
      child: Text(AppLocalizations.of(context).saveTag),
    );
  }

  List<Widget>? _buildOptionFields(BuildContext context) {
    switch (_selectedType) {
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
            onPressed: () {
              setState(() {
                _optionControllers.add(TextEditingController());
              });
            },
          ),
        ];
    }
  }

  List<Row> _buildOptionInputs(BuildContext context) {
    return List<Row>.generate(
      _optionControllers.length,
      (int index) {
        return Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _optionControllers[index],
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).tagAddOption,
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).tagOptionMissing;
                  }
                  return null;
                },
              ),
            ),
            if (index > 0)
              IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: () {
                  setState(() {
                    _optionControllers.removeAt(index);
                  });
                },
              ),
          ],
        );
      },
      growable: false,
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
              _selectedIcon = icon;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedIcon == icon
                    ? Theme.of(context).colorScheme.inversePrimary
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
  }
}
