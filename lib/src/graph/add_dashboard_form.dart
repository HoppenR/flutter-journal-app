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
  final List<int?> _selectedIds = <int?>[null];
  final TextEditingController _nameController = TextEditingController();

  GraphTypes? _selectedType;
  GraphTimespans? _selectedTimespan;
  final List<GraphConfiguration> _configurations = <GraphConfiguration>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context).addDashboard),
        actions: <Widget>[
          _buildTagFormAddMoreButton(context),
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
            _buildDashboardTimespan(context),
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
        while (_selectedIds.length < (value?.minimumItemAmt ?? 0)) {
          _selectedIds.add(null);
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
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            _selectedIds.add(null);
          });
        },
      ),
    ];
  }

  List<Row> _buildOptionInputs(BuildContext context) {
    return List<Row>.generate(
      _selectedIds.length,
      (int index) {
        return Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedIds[index],
                items: _selectedTimespan != GraphTimespans.year
                    ? _buildTagSelectDropdowns(context, index)
                    : _buildCategorySelectDropdowns(context, index),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedIds[index] = newValue;
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
            if (index >= (_selectedType?.minimumItemAmt ?? 1))
              IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: () {
                  setState(() {
                    _selectedIds.removeAt(index);
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
          _configurations.add(
            GraphConfiguration(
              type: _selectedType!,
              // NOTE: DropdownMenuItem validators assert not null for each
              ids: _selectedIds.cast<int>(),
              timeSpan: _selectedTimespan!,
            ),
          );
          dashboardManager.addDashboard(
            ChartDashboardData(
              title: _nameController.text,
              icon: Icons.shield_moon,
              configurations: _configurations,
            ),
          );
          Navigator.of(context).pop(true);
        }
      },
      child: Text(AppLocalizations.of(context).saveTag),
    );
  }

  Widget _buildTagFormAddMoreButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          _configurations.add(
            GraphConfiguration(
              type: _selectedType!,
              ids: List<int>.from(_selectedIds),
              timeSpan: _selectedTimespan!,
            ),
          );
          setState(() {
            _selectedType = null;
            _selectedIds.clear();
            _selectedTimespan = null;
          });
        }
      },
      // TODO: Localize
      child: const Text('add another graph to dashboard'),
    );
  }

  Widget _buildDashboardTimespan(BuildContext context) {
    return DropdownButtonFormField<GraphTimespans>(
      value: _selectedTimespan,
      hint: const Text('timespan experimental! (only month supported for now)'),
      items: const <DropdownMenuItem<GraphTimespans>>[
        DropdownMenuItem<GraphTimespans>(
          value: GraphTimespans.year,
          child: Text('current year'),
        ),
        DropdownMenuItem<GraphTimespans>(
          value: GraphTimespans.month,
          child: Text('current month'),
        ),
      ],
      onChanged: (GraphTimespans? value) {
        setState(() {
          _selectedTimespan = value;
          _selectedIds.clear();
          while (_selectedIds.length < (_selectedType?.minimumItemAmt ?? 0)) {
            _selectedIds.add(null);
          }
        });
      },
      validator: (GraphTimespans? value) {
        if (value == null) {
          // TODO: localize
          return 'timespan required';
        }
        return null;
      },
    );
  }

  List<DropdownMenuItem<int>> _buildTagSelectDropdowns(
    BuildContext context,
    int index,
  ) {
    final TagManager tagManager = context.watch<TagManager>();
    return tagManager.tags.entries.where(
      (MapEntry<int, TagData> val) {
        // Must include its own selection as a possible value
        return val.key == _selectedIds[index] ||
            !_selectedIds.contains(val.key);
      },
    ).map(
      (MapEntry<int, TagData> entry) {
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Text(entry.value.name),
        );
      },
    ).toList(growable: false);
  }

  List<DropdownMenuItem<int>> _buildCategorySelectDropdowns(
    BuildContext context,
    int index,
  ) {
    final TagManager tagManager = context.watch<TagManager>();
    return tagManager.categories.entries.where(
      (MapEntry<int, TagCategory> val) {
        // Must include its own selection as a possible value
        return val.key == _selectedIds[index] ||
            !_selectedIds.contains(val.key);
      },
    ).map(
      (MapEntry<int, TagCategory> entry) {
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Text(entry.value.name),
        );
      },
    ).toList(growable: false);
  }
}
