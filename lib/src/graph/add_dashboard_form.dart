import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/l10n/app_localizations.dart';
import '../tag/appliedtag.dart';
import '../tag/icons.dart';
import '../tag/manager.dart';
import '../tag/tag.dart';
import 'configuration.dart';
import 'dashboard.dart';

class AddDashboardForm extends StatefulWidget {
  const AddDashboardForm({super.key});

  @override
  AddDashboardFormState createState() => AddDashboardFormState();
}

// TODO: Create an empty dashboard here, and allow adding charts one by one
// instead, remove tagFormNumber and instead find the first available offset
// with an empty space of 1.
class AddDashboardFormState extends State<AddDashboardForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<int?> _selectedIds = <int?>[null];
  final TextEditingController _nameController = TextEditingController();

  GraphTypes? _selectedType;
  IconData _selectedIcon = Icons.favorite;
  GraphTimespans? _selectedTimespan;
  final List<GraphConfiguration> _configurations = <GraphConfiguration>[];
  int tagFormNumber = 0;

  static const double _iconSize = 40.0;

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
            Text(AppLocalizations.of(context).tagSelectIcon),
            _buildIconSelection(context),
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
        _selectedIds.clear();
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
      if (_selectedIds.length < (_selectedType?.maximumItemAmt ?? 9))
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
                items: _selectedTimespan == GraphTimespans.year &&
                        _selectedType == GraphTypes.radar
                    ? _buildCategorySelectDropdowns(context, index)
                    : _buildTagSelectDropdowns(context, index),
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
              offset: Offset(tagFormNumber.toDouble(), 0.0),
            ),
          );
          dashboardManager.addDashboard(
            ChartDashboardData(
              title: _nameController.text,
              icon: _selectedIcon,
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
    return IconButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          _configurations.add(
            GraphConfiguration(
              type: _selectedType!,
              ids: List<int>.from(_selectedIds),
              timeSpan: _selectedTimespan!,
              offset: Offset((tagFormNumber++).toDouble(), 0.0),
            ),
          );
          setState(() {
            _selectedType = null;
            _selectedIds.clear();
            _selectedTimespan = null;
          });
        }
      },
      tooltip: AppLocalizations.of(context).addGraph,
      icon: const Icon(Icons.addchart),
    );
  }

  Widget _buildDashboardTimespan(BuildContext context) {
    return DropdownButtonFormField<GraphTimespans>(
      value: _selectedTimespan,
      // TODO: Localize
      hint: const Text('timespan(month works fully)'),
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
          return AppLocalizations.of(context).chartTimespanMissing;
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
      (MapEntry<int, Tag> val) {
        // Must include its own selection as a possible value
        return val.key == _selectedIds[index] ||
            !_selectedIds.contains(val.key);
      },
    ).map(
      (MapEntry<int, Tag> entry) {
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
