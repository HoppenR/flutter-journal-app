import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'generated/l10n/app_localizations.dart';
import 'graph.dart';
import 'tag.dart';
import 'utility.dart';

enum OverviewItemType { tag, header }

class OverviewItem {
  OverviewItem.tag(TagData this.tag)
      : type = OverviewItemType.tag,
        headerCategoryId = null;
  OverviewItem.header(int this.headerCategoryId)
      : type = OverviewItemType.header,
        tag = null;

  final OverviewItemType type;
  final int? headerCategoryId;
  final TagData? tag;
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
        final TagData oldIndexItem = orderedItems[oldIndex].tag!;
        final OverviewItem newIndexItem = orderedItems[newIndex];
        final TagManager tagManager = context.read<TagManager>();

        // Calculate the new category and order for the moved tag
        final int? categoryId;
        final int newIndexOrd;
        switch (newIndexItem.type) {
          case OverviewItemType.tag:
            // When moving downward we need to use the order of the item above
            // plus one. When moving upward we can simply take the order of the
            // other tag. This is because we increase the order of all tags
            // below, but do not decrease the order of all tags above.
            // This allows us to make the assumption that moving a tag downward
            // to a header we can simply set the order to 0.
            categoryId = newIndexItem.tag!.categoryId;
            newIndexOrd = newIndexItem.tag!.order + (direction == -1 ? 1 : 0);
          case OverviewItemType.header:
            if (direction == -1) {
              categoryId = newIndexItem.headerCategoryId;
              newIndexOrd = 0;
            } else if (newIndex == 0) {
              categoryId = null;
              newIndexOrd = 0;
            } else {
              final OverviewItem above = orderedItems[newIndex - 1];
              switch (above.type) {
                case OverviewItemType.tag:
                  categoryId = above.tag!.categoryId;
                  newIndexOrd = above.tag!.order + 1;
                case OverviewItemType.header:
                  categoryId = above.headerCategoryId;
                  newIndexOrd = 0;
              }
            }
        }

        if (categoryId != oldIndexItem.categoryId) {
          // Make sure tags in the new category update order
          // update categoryId
          if (direction == -1) {
            // no need to increase order of the replaced item, moving downward
            newIndex += 1;
          }
          for (int i = newIndex; i < orderedItems.length; i++) {
            if (orderedItems[i].type == OverviewItemType.header) {
              break;
            }
            final TagData tag = orderedItems[i].tag!;
            tagManager.changeOrder(tag, tag.order + 1);
          }
          oldIndexItem.categoryId = categoryId;
        } else {
          // We are in the same category as the target, onl order is relevant
          // and we only have to inc/dec order of relevant items
          for (int i = newIndex; i != oldIndex; i = i + direction) {
            final TagData tag = orderedItems[i].tag!;
            tagManager.changeOrder(tag, tag.order + direction);
          }
        }
        tagManager.changeOrder(oldIndexItem, newIndexOrd);
        _debounceSave(context);
      },
      itemBuilder: (BuildContext context, int index) {
        final OverviewItem item = orderedItems[index];
        switch (item.type) {
          case OverviewItemType.tag:
            return ReorderableDragStartListener(
              index: index,
              key: item.tag!.key,
              child: ListTile(
                title: _buildReorderTagRow(context, item),
                trailing: const Icon(Icons.drag_handle),
              ),
            );
          case OverviewItemType.header:
            return Container(
              key: ValueKey<int?>(item.headerCategoryId),
              child: Text(
                context
                    .watch<TagManager>()
                    .categories[item.headerCategoryId!]!
                    .name,
                style: const TextStyle(fontSize: 25.0),
              ),
            );
        }
      },
    );
  }

  Widget _buildReorderTagRow(BuildContext context, OverviewItem entry) {
    final TagManager tagManager = context.watch<TagManager>();
    final AppliedTagData? appliedTagData = tagManager.appliedTags[widget.day]
        ?.firstWhereOrNull((AppliedTagData tag) => tag.id == entry.tag?.id);
    return _buildTagRow(context, entry.tag!, appliedTagData);
  }

  Widget _buildDismissibleTagList(BuildContext context) {
    final TagManager tagManager = context.watch<TagManager>();
    final List<OverviewItem> orderedItems = orderItems();
    return Column(
      children: orderedItems.map((OverviewItem entry) {
        switch (entry.type) {
          case OverviewItemType.tag:
            return _buildDismissibleTagRow(
              context,
              entry.tag!,
            );
          case OverviewItemType.header:
            return Text(
              tagManager.categories[entry.headerCategoryId!]!.name,
              style: const TextStyle(fontSize: 25.0),
            );
        }
      }).toList(growable: false),
    );
  }

  Widget _buildDismissibleTagRow(BuildContext context, TagData tagData) {
    final TagManager tagManager = context.watch<TagManager>();
    final AppliedTagData? appliedTagData = tagManager.appliedTags[widget.day]
        ?.firstWhereOrNull((AppliedTagData tag) => tag.id == tagData.id);

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

  List<Widget> _buildTagOptions(BuildContext context, TagData tagData) {
    final TagManager tagManager = context.watch<TagManager>();
    return List<Widget>.generate(
      tagData.list.length,
      (int index) {
        final bool isSelected = tagManager.appliedTags[widget.day]?.any(
              (AppliedTagData tag) {
                if (tag.id != tagData.id) {
                  return false;
                }
                switch (tag.type) {
                  case TagTypes.list:
                    return tag.listOption == index;
                  case TagTypes.multi:
                    return tag.multiOptions?.contains(index) ?? false;
                  case TagTypes.toggle:
                    throw ArgumentError.value(
                      tag.type,
                      'tag.type',
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

  void _handleTagSelection(BuildContext context, TagData tagData, int index) {
    final TagManager tagManager = context.watch<TagManager>();
    final int tagIndex = tagManager.appliedTags[widget.day]
            ?.indexWhere((AppliedTagData tag) => tag.id == tagData.id) ??
        -1;

    switch (tagData.type) {
      case TagTypes.list:
        if (tagIndex != -1) {
          final AppliedTagData appliedTag =
              tagManager.appliedTags[widget.day]![tagIndex];
          tagManager.changeListOption(appliedTag, index);
        } else {
          tagManager.applyTag(
            AppliedTagData.list(tagData.id, index, tagData),
            widget.day,
          );
        }
      case TagTypes.toggle:
        throw ArgumentError.value(
          tagData.type,
          'tagData.type',
          'argument does not have tag options',
        );
      case TagTypes.multi:
        if (tagIndex != -1) {
          final AppliedTagData appliedTag =
              tagManager.appliedTags[widget.day]![tagIndex];
          tagManager.toggleMultiOption(appliedTag, index);
        } else {
          tagManager.applyTag(
            AppliedTagData.multi(tagData.id, <int>[index], tagData),
            widget.day,
          );
        }
    }
    _debounceSave(context);
  }

  void _handleToggleChange(BuildContext context, TagData tagData, bool value) {
    // HERE<++>
    final TagManager tagManager = context.read<TagManager>();
    final int tagIndex = tagManager.appliedTags[widget.day]
            ?.indexWhere((AppliedTagData tag) => tag.id == tagData.id) ??
        -1;

    if (tagIndex != -1) {
      final AppliedTagData appliedTag =
          tagManager.appliedTags[widget.day]![tagIndex];
      tagManager.toggleTo(appliedTag, value);
    } else {
      final AppliedTagData newTag = AppliedTagData.toggle(
        tagData.id,
        value,
        tagData,
      );
      tagManager.applyTag(newTag, widget.day);
    }
    _debounceSave(context);
  }

  Widget _buildTagRow(
    BuildContext context,
    TagData tagData,
    AppliedTagData? appliedTagData,
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
    TagData tagData,
    AppliedTagData? appliedTagData,
  ) {
    switch (tagData.type) {
      case TagTypes.list:
        return _buildTagOptions(context, tagData);
      case TagTypes.toggle:
        return <Widget>[
          Switch(
            value: appliedTagData?.toggleOption ?? false,
            onChanged: !_editMode
                ? (bool value) {
                    _handleToggleChange(context, tagData, value);
                  }
                : null,
          ),
        ];
      case TagTypes.multi:
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
    final Map<int, List<TagData>> tagsByCategory = <int, List<TagData>>{
      for (final int key in tagManager.categories.keys) key: <TagData>[]
    };
    final List<OverviewItem> ret = <OverviewItem>[];

    for (final TagData tag in tagManager.tags.values) {
      if (tag.categoryId != null) {
        tagsByCategory[tag.categoryId!]!.add(tag);
      } else {
        ret.add(OverviewItem.tag(tag));
      }
    }
    ret.sortBy<num>((OverviewItem item) => item.tag!.order);

    for (final List<TagData> category in tagsByCategory.values) {
      category.sortBy<num>((TagData tag) => tag.order);
    }

    for (final MapEntry<int, List<TagData>> entry in tagsByCategory.entries) {
      ret.add(OverviewItem.header(entry.key));
      ret.addAll(
        entry.value.map(
          (TagData tag) => OverviewItem.tag(tag),
        ),
      );
    }
    return ret;
  }
}
