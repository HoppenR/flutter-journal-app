import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'generated/l10n/app_localizations.dart';
import 'graph/dashboard.dart';
import 'tag.dart';
import 'utility.dart';

sealed class OverviewItem {}

class OverviewTag extends OverviewItem {
  OverviewTag({required this.tag});

  final Tag tag;
}

class OverviewHeader extends OverviewItem {
  OverviewHeader({required this.category});

  final int category;
}

class TagDayOverview extends StatefulWidget {
  const TagDayOverview({super.key, required this.day});

  final DateTime day;

  @override
  TagDayOverviewState createState() => TagDayOverviewState();
}

class TagDayOverviewState extends State<TagDayOverview> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Timer? _debouncedSaveTimer;
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          return;
        }
        if (_debouncedSaveTimer?.isActive ?? false) {
          _debouncedSaveTimer!.cancel();
          _saveCallback(context);
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(
            AppLocalizations.of(context).tagOverviewTitle(widget.day),
          ),
          actions: <Widget>[
            if (_editMode) ...<Widget>[
              TextButton.icon(
                label: Text(AppLocalizations.of(context).category),
                onPressed: () async {
                  final String? categoryName = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return _buildCategoryNameInput(context);
                    },
                  );

                  if (categoryName != null) {
                    if (context.mounted) {
                      context.read<TagManager>().addCategory(categoryName);
                      _debounceSave(context);
                    }
                  }
                },
                icon: const Icon(Icons.add),
              )
            ],
            Text(AppLocalizations.of(context).editModeToggle),
            Switch(
              value: _editMode,
              onChanged: (bool newValue) {
                setState(() {
                  _editMode = newValue;
                });
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: _editMode
                ? _buildReorderableTagList(context)
                : _buildDismissibleTagList(context),
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableTagList(
    BuildContext context,
  ) {
    final List<OverviewItem> orderedItems = orderItems();
    return ReorderableListView.builder(
      itemCount: orderedItems.length,
      buildDefaultDragHandles: false,
      onReorder: (int oldIndex, int newIndex) {
        // Lots of edge cases in here, but this should be optimized as much as
        // possible now
        final int direction;
        if (oldIndex < newIndex) {
          newIndex -= 1;
          direction = -1;
        } else {
          direction = 1;
        }
        final Tag oldIndexItem = (orderedItems[oldIndex] as OverviewTag).tag;
        final OverviewItem newIndexItem = orderedItems[newIndex];
        final TagManager tagManager = context.read<TagManager>();

        // Calculate the new category and order for the moved tag
        final int? category;
        final int newIndexOrd;
        switch (newIndexItem) {
          case OverviewTag():
            // When moving downward we need to use the order of the item above
            // plus one. When moving upward we can simply take the order of the
            // other tag. This is because we increase the order of all tags
            // below, but do not decrease the order of all tags above.
            // This allows us to make the assumption that moving a tag downward
            // to a header we can simply set the order to 0.
            category = newIndexItem.tag.category;
            newIndexOrd = newIndexItem.tag.order + (direction == -1 ? 1 : 0);
          case OverviewHeader():
            if (direction == -1) {
              category = newIndexItem.category;
              newIndexOrd = 0;
            } else if (newIndex == 0) {
              category = null;
              newIndexOrd = 0;
            } else {
              final OverviewItem above = orderedItems[newIndex - 1];
              switch (above) {
                case OverviewTag():
                  category = above.tag.category;
                  newIndexOrd = above.tag.order + 1;
                case OverviewHeader():
                  category = above.category;
                  newIndexOrd = 0;
              }
            }
        }

        if (category != oldIndexItem.category) {
          if (direction == -1) {
            // no need to increase order of the replaced item, moving downward
            newIndex += 1;
          }
          outer:
          for (int i = newIndex; i < orderedItems.length; i++) {
            final OverviewItem item = orderedItems[i];
            switch (item) {
              case OverviewTag():
                final Tag tag = item.tag;
                tagManager.changeOrder(tag, tag.order + 1);
              case OverviewHeader():
                break outer;
            }
          }
          oldIndexItem.category = category;
        } else {
          // We are in the same category as the target, onl order is relevant
          // and we only have to inc/dec order of relevant items
          for (int i = newIndex; i != oldIndex; i = i + direction) {
            final Tag tag = (orderedItems[i] as OverviewTag).tag;
            tagManager.changeOrder(tag, tag.order + direction);
          }
        }
        tagManager.changeOrder(oldIndexItem, newIndexOrd);
        _debounceSave(context);
      },
      itemBuilder: (BuildContext context, int index) {
        final OverviewItem item = orderedItems[index];
        switch (item) {
          case OverviewTag():
            return ReorderableDragStartListener(
              index: index,
              key: item.tag.key,
              child: ListTile(
                title: _buildReorderTagRow(context, item),
                trailing: const Icon(Icons.drag_handle),
              ),
            );
          case OverviewHeader():
            return Container(
              key: ValueKey<int?>(item.category),
              child: Text(
                context.read<TagManager>().categories[item.category]!.name,
                style: const TextStyle(fontSize: 25.0),
              ),
            );
        }
      },
    );
  }

  Widget _buildReorderTagRow(BuildContext context, OverviewTag entry) {
    final TagManager tagManager = context.watch<TagManager>();
    final AppliedTag? appliedTagData = tagManager.appliedTags[widget.day]
        ?.firstWhereOrNull((AppliedTag tag) => tag.id == entry.tag.id);
    return _buildTagRow(context, entry.tag, appliedTagData);
  }

  Widget _buildDismissibleTagList(BuildContext context) {
    final TagManager tagManager = context.watch<TagManager>();
    final List<OverviewItem> orderedItems = orderItems();
    return Column(
      children: orderedItems.map((OverviewItem entry) {
        switch (entry) {
          case OverviewTag():
            return _buildDismissibleTagRow(
              context,
              entry.tag,
            );
          case OverviewHeader():
            return Text(
              tagManager.categories[entry.category]!.name,
              style: const TextStyle(fontSize: 25.0),
            );
        }
      }).toList(growable: false),
    );
  }

  Widget _buildDismissibleTagRow(BuildContext context, Tag tagData) {
    final TagManager tagManager = context.watch<TagManager>();
    final AppliedTag? appliedTagData = tagManager.appliedTags[widget.day]
        ?.firstWhereOrNull((AppliedTag tag) => tag.id == tagData.id);

    return Dismissible(
      key: tagData.key,
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          return _showDeleteTagWindow(context);
        } else if (direction == DismissDirection.endToStart) {
          if (appliedTagData != null) {
            tagManager.unapplyTag(appliedTagData, widget.day);
          }
          _debounceSave(context);
          return false;
        }
        return true;
      },
      background: Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            Theme.of(context).colorScheme.primary.withAlpha(108),
            Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        child: const Row(
          children: <Widget>[
            SizedBox(width: 10.0),
            Icon(Icons.delete),
            Spacer(),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryFixed,
        ),
        child: const Row(
          children: <Widget>[
            Spacer(),
            Icon(Icons.restore),
            SizedBox(width: 10.0),
          ],
        ),
      ),
      onDismissed: (DismissDirection direction) {
        if (direction == DismissDirection.startToEnd) {
          context
              .read<ChartDashboardManager>()
              .removeTagFromDashboards(tagData.id);
          tagManager.removeTag(tagData.id);
          _debounceSave(context);
        }
      },
      child: _buildTagRow(context, tagData, appliedTagData),
    );
  }

  List<Widget> _buildTagOptions(BuildContext context, TagWithList tagData) {
    final TagManager tagManager = context.watch<TagManager>();
    return List<Widget>.generate(
      tagData.list.length,
      (int index) {
        final bool isSelected = tagManager.appliedTags[widget.day]?.any(
              (AppliedTag tag) {
                if (tag.id != tagData.id) {
                  return false;
                }
                switch (tag) {
                  case AppliedList(:final int option):
                    return option == index;
                  case AppliedMulti(:final List<int> options):
                    return options.contains(index);
                  case AppliedToggle():
                    throw ArgumentError.value(
                      tag,
                      'tag',
                      'argument does not have tag options',
                    );
                }
              },
            ) ??
            false;
        return ChoiceChip(
          label: Text(tagData.list[index]),
          selected: isSelected,
          onSelected: (bool selected) => _handleTagSelection(
            context,
            tagData,
            index,
          ),
        );
      },
      growable: false,
    );
  }

  void _handleTagSelection(
    BuildContext context,
    TagWithList tagData,
    int index,
  ) {
    final TagManager tagManager = context.read<TagManager>();
    final int tagIndex = tagManager.appliedTags[widget.day]
            ?.indexWhere((AppliedTag tag) => tag.id == tagData.id) ??
        -1;

    switch (tagData) {
      case ListTag():
        if (tagIndex != -1) {
          final AppliedList appliedTag =
              tagManager.appliedTags[widget.day]![tagIndex] as AppliedList;
          tagManager.changeListOption(appliedTag, index);
        } else {
          tagManager.applyTag(
            AppliedList(tagData.id, index, tagData),
            widget.day,
          );
        }
      case MultiTag():
        if (tagIndex != -1) {
          final AppliedMulti appliedTag =
              tagManager.appliedTags[widget.day]![tagIndex] as AppliedMulti;
          tagManager.toggleMultiOption(appliedTag, index);
        } else {
          tagManager.applyTag(
            AppliedMulti(tagData.id, <int>[index], tagData),
            widget.day,
          );
        }
    }
    _debounceSave(context);
  }

  void _handleToggleChange(
    BuildContext context,
    ToggleTag tagData,
    bool value,
  ) {
    final TagManager tagManager = context.read<TagManager>();
    final int tagIndex = tagManager.appliedTags[widget.day]
            ?.indexWhere((AppliedTag tag) => tag.id == tagData.id) ??
        -1;

    if (tagIndex != -1) {
      final AppliedToggle appliedTag =
          tagManager.appliedTags[widget.day]![tagIndex] as AppliedToggle;
      tagManager.toggleTo(appliedTag, value);
    } else {
      final AppliedTag newTag = AppliedToggle(tagData.id, value, tagData);
      tagManager.applyTag(newTag, widget.day);
    }
    _debounceSave(context);
  }

  Widget _buildTagRow(
    BuildContext context,
    Tag tagData,
    AppliedTag? appliedTagData,
  ) {
    return Column(
      key: tagData.key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(tagData.icon, size: 40.0),
            Expanded(
              child: Text(
                tagData.name,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Wrap(
          runSpacing: 4.0,
          spacing: 8.0,
          children: _buildTagRowContent(
            context,
            tagData,
            appliedTagData,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTagRowContent(
    BuildContext context,
    Tag tagData,
    AppliedTag? appliedTagData,
  ) {
    switch (tagData) {
      case ListTag():
        return _buildTagOptions(context, tagData);
      case ToggleTag():
        return <Widget>[
          Switch(
            value: (appliedTagData is AppliedToggle) && appliedTagData.option ||
                false,
            onChanged: !_editMode
                ? (bool value) {
                    _handleToggleChange(context, tagData, value);
                  }
                : null,
          ),
        ];
      case MultiTag():
        return _buildTagOptions(context, tagData);
    }
  }

  Widget _buildCategoryNameInput(BuildContext context) {
    String categoryName = '';
    return AlertDialog(
      title: Text(AppLocalizations.of(context).enterCategoryNameTitle),
      content: TextField(
        onChanged: (String value) {
          categoryName = value;
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).enterCategoryNameHint,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).promptNegative),
        ),
        TextButton(
          onPressed: () {
            if (categoryName.isNotEmpty) {
              Navigator.of(context).pop(categoryName);
              return;
            }
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).saveTag),
        ),
      ],
    );
  }

  Future<bool> _showDeleteTagWindow(BuildContext context) async {
    final bool? didDeleteTag = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).clearDataTitle),
          content: Text(AppLocalizations.of(context).clearDataPrompt),
          actions: <Widget>[
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(AppLocalizations.of(context).promptNegative),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(AppLocalizations.of(context).promptAffirmative),
            ),
          ],
        );
      },
    );
    return didDeleteTag ?? false;
  }

  void _debounceSave(BuildContext context) {
    _debouncedSaveTimer?.cancel();
    _debouncedSaveTimer = Timer(
      const Duration(seconds: 3),
      () => _saveCallback(context),
    );
  }

  void _saveCallback(BuildContext context) {
    saveTagData(context);
    saveAppliedTags(context);
    saveCategories(context);
    saveChartDashboardData(context);
    saveNextCategoryId(context);
  }

  List<OverviewItem> orderItems() {
    final TagManager tagManager = context.watch<TagManager>();
    final Map<int, List<Tag>> tagsByCategory = <int, List<Tag>>{
      for (final int key in tagManager.categories.keys) key: <Tag>[]
    };
    final List<OverviewItem> ret = <OverviewItem>[];

    for (final Tag tag in tagManager.tags.values) {
      if (tag.category != null) {
        tagsByCategory[tag.category!]!.add(tag);
      } else {
        ret.add(OverviewTag(tag: tag));
      }
    }
    ret.sortBy<num>((OverviewItem item) => (item as OverviewTag).tag.order);

    for (final List<Tag> category in tagsByCategory.values) {
      category.sortBy<num>((Tag tag) => tag.order);
    }

    for (final MapEntry<int, List<Tag>> entry in tagsByCategory.entries) {
      ret.add(OverviewHeader(category: entry.key));
      ret.addAll(
        entry.value.map((Tag tag) => OverviewTag(tag: tag)),
      );
    }
    return ret;
  }
}
