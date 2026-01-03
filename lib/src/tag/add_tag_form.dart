import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/l10n/app_localizations.dart';
import '../graph/configuration.dart';
import '../graph/dashboard.dart';
import 'icons.dart';
import 'manager.dart';
import 'tag.dart';

class AddTagForm extends StatefulWidget {
  const AddTagForm({super.key});

  @override
  AddTagFormState createState() => AddTagFormState();
}

class AddTagFormState extends State<AddTagForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _options = <TextEditingController>[
    TextEditingController(),
  ];
  final TextEditingController _nameController = TextEditingController();

  TagTypes? _selectedType;
  IconData _selectedIcon = Icons.favorite;

  static const double _iconSize = 40.0;

  @override
  void dispose() {
    _nameController.dispose();
    for (final TextEditingController controller in _options) {
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
        actions: <Widget>[_buildTagFormValidateButton(context)],
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
          crossAxisAlignment: .start,
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
      controller: _nameController,
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
      initialValue: _selectedType,
      hint: Text(AppLocalizations.of(context).tagSelectType),
      items: <DropdownMenuItem<TagTypes>>[
        DropdownMenuItem<TagTypes>(
          value: .list,
          child: Text(AppLocalizations.of(context).tagTypeList),
        ),
        DropdownMenuItem<TagTypes>(
          value: .toggle,
          child: Text(AppLocalizations.of(context).tagTypeToggle),
        ),
        DropdownMenuItem<TagTypes>(
          value: .multi,
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
    final ChartDashboardManager dashboardManager = context
        .read<ChartDashboardManager>();
    return TextButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          // NOTE: selectedType validator asserts not null before this
          final TagFactory<Tag> factory = switch (_selectedType!) {
            TagTypes.list => ListTag.new,
            TagTypes.multi => MultiTag.new,
            TagTypes.toggle => ToggleTag.new,
          };
          final int addedId = tagManager.addTag(
            factory,
            _nameController.text,
            _selectedIcon,
            _options
                .map((TextEditingController controller) => controller.text)
                .toList(growable: false),
          );
          dashboardManager.addDashboard(
            ChartDashboardData(
              title: _nameController.text,
              icon: _selectedIcon,
              configurations: <GraphConfiguration>[
                GraphConfiguration(
                  type: .lineChart,
                  ids: <int>[addedId],
                  offset: .zero,
                ),
                GraphConfiguration(
                  type: .weekdayBarChart,
                  ids: <int>[addedId],
                  offset: const Offset(1.0, 0.0),
                ),
                GraphConfiguration(
                  type: .heatmap,
                  ids: <int>[addedId],
                  offset: const Offset(2.0, 0.0),
                ),
              ],
            ),
          );
          Navigator.of(context).pop(true);
        }
      },
      child: Text(AppLocalizations.of(context).saveTag),
    );
  }

  List<Widget>? _buildOptionFields(BuildContext context) {
    switch (_selectedType) {
      case null:
      case TagTypes.toggle:
        return null;
      case TagTypes.list || TagTypes.multi:
        return <Widget>[
          const SizedBox(height: 16.0),
          Text(
            AppLocalizations.of(context).tagOptions,
            style: const TextStyle(fontWeight: .bold),
          ),
          ..._buildOptionInputs(context),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _options.add(TextEditingController());
              });
            },
          ),
        ];
    }
  }

  List<Row> _buildOptionInputs(BuildContext context) {
    return List<Row>.generate(_options.length, (int index) {
      return Row(
        children: <Widget>[
          Expanded(
            child: TextFormField(
              controller: _options[index],
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
                  _options.removeAt(index);
                });
              },
            ),
        ],
      );
    }, growable: false);
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
              border: .all(
                color: _selectedIcon == icon
                    ? Theme.of(context).colorScheme.inversePrimary
                    : Colors.transparent,
                width: 2.0,
              ),
              borderRadius: .circular(8.0),
            ),
            child: Icon(icon, size: _iconSize),
          ),
        );
      },
    );
  }
}
