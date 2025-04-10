import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/l10n/app_localizations.dart';
import '../graph.dart';
import '../tag.dart';
import 'configuration.dart';
import 'dashboard.dart';

class AddDashboardForm extends StatefulWidget {
  const AddDashboardForm({super.key});

  @override
  AddDashboardFormState createState() => AddDashboardFormState();
}

class AddDashboardFormState extends State<AddDashboardForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<int?> _selectedTagIds = <int?>[null];
  final TextEditingController _nameController = TextEditingController();

  GraphTypes? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context).addDashboard),
        actions: <Widget>[
          _buildTagFormValidateButton(context),
        ],
      ),
      body: _buildDashboardFormBody(context),
    );
  }

  Widget _buildDashboardFormBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildDashboardFormName(context),
            _buildDashboardOptionType(context),
            ..._buildOptionFields(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardFormName(BuildContext context) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).dashboardNameHint,
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context).dashboardNameMissing;
        }
        return null;
      },
      autofocus: true,
    );
  }

  Widget _buildDashboardOptionType(BuildContext context) {
    return DropdownButtonFormField<GraphTypes>(
      value: _selectedType,
      hint: Text(AppLocalizations.of(context).chartSelectType),
      items: <DropdownMenuItem<GraphTypes>>[
        DropdownMenuItem<GraphTypes>(
          value: GraphTypes.lineChart,
          child: Text(AppLocalizations.of(context).chartTypeLine),
        ),
        DropdownMenuItem<GraphTypes>(
          value: GraphTypes.weekdayBarChart,
          child: Text(AppLocalizations.of(context).chartTypeBar),
        ),
        DropdownMenuItem<GraphTypes>(
          value: GraphTypes.heatmap,
          child: Text(AppLocalizations.of(context).chartTypeHeatmap),
        ),
        DropdownMenuItem<GraphTypes>(
          value: GraphTypes.radar,
          child: Text(AppLocalizations.of(context).chartTypeRadar),
        ),
      ],
      onChanged: (GraphTypes? value) {
        if (value == GraphTypes.radar) {
          while (_selectedTagIds.length < 3) {
            _selectedTagIds.add(null);
          }
        }
        setState(() {
          _selectedType = value;
        });
      },
      validator: (GraphTypes? value) {
        if (value == null) {
          return AppLocalizations.of(context).chartTypeMissing;
        }
        return null;
      },
    );
  }

  List<Widget> _buildOptionFields(BuildContext context) {
    return <Widget>[
      const SizedBox(height: 16.0),
      Text(
        AppLocalizations.of(context).tagOptions,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      ..._buildOptionInputs(context),
      if (_selectedTagIds.length < 4)
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            setState(() {
              _selectedTagIds.add(null);
            });
          },
        ),
    ];
  }

  List<Row> _buildOptionInputs(BuildContext context) {
    final TagManager tagManager = context.read<TagManager>();
    return List<Row>.generate(
      _selectedTagIds.length,
      (int index) {
        return Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedTagIds[index],
                items: tagManager.tags.entries.where(
                  (MapEntry<int, TagData> val) {
                    // Must include its own selection as a possible value
                    return val.key == _selectedTagIds[index] ||
                        !_selectedTagIds.contains(val.key);
                  },
                ).map(
                  (MapEntry<int, TagData> entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value.name),
                    );
                  },
                ).toList(growable: false),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedTagIds[index] = newValue;
                  });
                },
                validator: (int? value) {
                  if (value == null) {
                    return AppLocalizations.of(context).tagOptionMissing;
                  }
                  return null;
                },
              ),
            ),
            if (index > (_selectedType?.minimumItemAmt ?? 0))
              IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: () {
                  setState(() {
                    _selectedTagIds.removeAt(index);
                  });
                },
              ),
          ],
        );
      },
      growable: false,
    );
  }

  Widget _buildTagFormValidateButton(BuildContext context) {
    final ChartDashboardManager dashboardManager =
        context.read<ChartDashboardManager>();
    return TextButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          // NOTE: selectedType validator asserts not null before this
          final List<GraphConfiguration> configurations =
              <GraphConfiguration>[];
          // TODO: Allow user to add more than one configuration per dashboard
          configurations.add(
            GraphConfiguration(
              type: _selectedType!,
              // NOTE: DropdownMenuItem validators assert not null for each
              ids: _selectedTagIds.cast<int>(),
            ),
          );
          dashboardManager.addDashboard(
            ChartDashboardData(
              title: _nameController.text,
              icon: Icons.shield_moon,
              configurations: configurations,
            ),
          );
          Navigator.of(context).pop(true);
        }
      },
      child: Text(AppLocalizations.of(context).saveTag),
    );
  }
}
