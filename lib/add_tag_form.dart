// Vim: set shiftwidth=2 :
import 'package:flutter/material.dart';
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

  // TODO(Christoffer): Add menstruation related icons
  final List<IconData> availableIcons = <IconData>[
    Icons.favorite,
    Icons.home,
    Icons.star,
    Icons.work,
    Icons.fitness_center,
    Icons.coffee,
    Icons.shopping_cart,
    Icons.school,
    Icons.pets,
    Icons.sports_soccer,
    Icons.water_drop,
    Icons.brightness_5,
    Icons.nightlight,
    Icons.calendar_today,
    Icons.av_timer,
    Icons.warning,
    Icons.thermostat,
    Icons.sick,
    Icons.cloud,
    Icons.opacity,
    Icons.sentiment_satisfied_alt,
    Icons.sentiment_very_satisfied,
    Icons.sentiment_dissatisfied,
    Icons.energy_savings_leaf,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.icecream,
    Icons.local_pizza,
    Icons.self_improvement,
    Icons.nature_people,
    Icons.local_hospital,
    Icons.notes,
    Icons.star_border,
    Icons.check,
    Icons.bubble_chart,
  ];

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
        title: const Text('Add Tag'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                // NOTE: selectedType validator asserts not null before this
                switch (selectedType!) {
                  case TagType.list:
                    tagNames[tagController.text] = TagData.list(
                      tagController.text,
                      optionControllers
                        .map(
                          (TextEditingController controller) =>
                              controller.text,
                        ).toList(),
                      selectedIcon!,
                    );
                  case TagType.toggle:
                    tagNames[tagController.text] = TagData.toggle(
                      tagController.text,
                      selectedIcon!,
                    );
                }
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save'),
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
                decoration: const InputDecoration(hintText: 'Enter a tag'),
                validator: (String? value) =>
                    value == null || value.isEmpty ? 'Tag is required' : null,
                autofocus: true,
              ),
              DropdownButtonFormField<TagType>(
                value: selectedType,
                hint: const Text('Select tag type'),
                items: const <DropdownMenuItem<TagType>>[
                  DropdownMenuItem<TagType>(
                    value: TagType.list,
                    child: Text('List'),
                  ),
                  DropdownMenuItem<TagType>(
                    value: TagType.toggle,
                    child: Text('Toggle'),
                  ),
                ],
                onChanged: (TagType? value) => setState(() {
                  selectedType = value;
                }),
                validator: (TagType? value) =>
                    value == null ? 'Tag type is required' : null,
              ),
              if (selectedType == TagType.list) ..._buildOptionFields(),
              const Text('Select an Icon'),
              _buildIconSelection(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionFields() {
    return <Widget>[
      const SizedBox(height: 16),
      const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
      ...optionControllers.asMap().entries.map(
            (MapEntry<int, TextEditingController> entry) => Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: const InputDecoration(
                      hintText: 'Enter an option',
                    ),
                    validator: (String? value) =>
                        value == null || value.isEmpty
                            ? 'Option is required'
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
            ),
          ),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => setState(() {
          optionControllers.add(TextEditingController());
        }),
      ),
    ];
  }

  Widget _buildIconSelection() {
    const double iconSize = 40;
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double availableWidth = constraints.maxWidth;
          final int maxIconsInRow = (availableWidth / (iconSize + 16)).floor();

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: maxIconsInRow,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (BuildContext context, int index) {
              final IconData icon = availableIcons[index];
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
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: iconSize),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
