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

  GraphType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Add dashboard'),
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
      decoration: const InputDecoration(
        hintText: 'Enter a dashboard name',
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) {
          return 'Name is required';
        }
        return null;
      },
      autofocus: true,
    );
  }

  Widget _buildDashboardOptionType(BuildContext context) {
    return DropdownButtonFormField<GraphType>(
      value: _selectedType,
      hint: const Text('Select chart type'),
      items: const <DropdownMenuItem<GraphType>>[
        DropdownMenuItem<GraphType>(
          value: GraphType.lineChart,
          child: Text('lineChart'),
        ),
        DropdownMenuItem<GraphType>(
          value: GraphType.weekdayBarChart,
          child: Text('weekdayBarChart'),
        ),
        DropdownMenuItem<GraphType>(
          value: GraphType.heatmap,
          child: Text('heatmap'),
        ),
        DropdownMenuItem<GraphType>(
          value: GraphType.radar,
          child: Text('radar'),
        ),
      ],
      onChanged: (GraphType? value) {
        if (value == GraphType.radar) {
          while (_selectedTagIds.length < 3) {
            _selectedTagIds.add(null);
          }
        }
        setState(() {
          _selectedType = value;
        });
      },
      validator: (GraphType? value) {
        if (value == null) {
          return 'Chart type is required';
        }
        return null;
      },
    );
  }

  List<Widget> _buildOptionFields(BuildContext context) {
    return <Widget>[
      const SizedBox(height: 16.0),
      const Text(
        'Tags',
        style: TextStyle(fontWeight: FontWeight.bold),
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
                hint: const Text('select tag'),
                items: tagManager.tags.entries.map(
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
                    return 'id is required';
                  }
                  return null;
                },
              ),
            ),
            if (_selectedType != GraphType.radar && index > 0 ||
                _selectedType == GraphType.radar && index > 2)
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
              graphType: _selectedType!,
              // NOTE: This is resizable because a TagData might be removed
              ids: _selectedTagIds.nonNulls.toList(growable: true),
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
