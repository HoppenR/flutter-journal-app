// Vim: set shiftwidth=2 :
import 'package:flutter/material.dart';

enum TagType { boolean, list }

class FullScreenTagForm extends StatefulWidget {
  const FullScreenTagForm({super.key, required this.tagNames});

  final Map<String, List<String>> tagNames;

  @override
  FullScreenTagFormState createState() => FullScreenTagFormState();
}

class FullScreenTagFormState extends State<FullScreenTagForm> {
  final TextEditingController tagController = TextEditingController();
  final List<TextEditingController> optionControllers = <TextEditingController>[
    TextEditingController(),
  ];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TagType? selectedType;

  @override void dispose() {
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
                if (selectedType == TagType.list) {
                  widget.tagNames[tagController.text] = optionControllers
                    .map((TextEditingController controller) => controller.text)
                    .where((String text) => text.isNotEmpty)
                    .toList();
                } else if(selectedType == TagType.boolean) {
                  // TODO(Hop): Think through this, rather have small text +
                  //            strikethrough when checked?
                  //            Need to rethink the entire boolean type
                  widget.tagNames[tagController.text] = <String>['✅', '❎'];
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
                validator: (String? value) => value == null || value.isEmpty
                  ? 'Tag is required'
                  : null,
                autofocus: true,
              ),
              DropdownButtonFormField<TagType>(
                value: selectedType,
                hint: const Text('Select tag type'),
                items: const <DropdownMenuItem<TagType>>[
                  DropdownMenuItem<TagType>(
                    value: TagType.boolean,
                    child: Text('Checkmark'),
                  ),
                  DropdownMenuItem<TagType>(
                    value: TagType.list,
                    child: Text('Options'),
                  ),
                ],
                onChanged: (TagType? value) => setState(() {
                  selectedType = value;
                }),
                validator: (TagType? value) => value == null
                  ? 'Tag type is required'
                  : null,
              ),
              if (selectedType == TagType.list)
                ..._buildOptionFields(),
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
                validator: (String? value) => value == null || value.isEmpty ?
                  'Option is required'
                  : null,
                onChanged: (String? value) => setState(() {}),
              ),
            ),
            if (entry.key > 0) IconButton(
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
}
