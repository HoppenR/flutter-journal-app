import 'package:flutter/material.dart';

import 'appliedtag.dart';
import 'tag.dart';

typedef TagFactory<T extends Tag> = T Function(
  int id,
  String name,
  IconData icon,
  int order, {
  required List<String> list,
  int? category,
});

/// A TagManager class for storing and interacting with tags
/// with functionality for propagating updates to watchers
class TagManager with ChangeNotifier {
  TagManager({
    required this.tags,
    required this.appliedTags,
    required this.categories,
    required this.nextTagId,
    required this.nextCategory,
  });

  /// Add a tag by providing minimal data required. The 'list' argument is
  /// ignored for types that do not extend TagWithList but must be supplied to
  /// satisfy the TagFactory type signature
  int addTag<T extends Tag>(
    TagFactory<T> createTag,
    String name,
    IconData icon,
    List<String> list,
  ) {
    final int tagId = nextTagId++;
    final int order = tagId;
    tags[tagId] = createTag(tagId, name, icon, order, list: list);
    notifyListeners();
    return tagId;
  }

  void applyTag<A extends AppliedTag>(A appliedTag, DateTime day) {
    appliedTags.putIfAbsent(day, () => <AppliedTag>[]).add(appliedTag);
    notifyListeners();
  }

  int addCategory(String name) {
    final int category = nextCategory++;
    categories[category] = TagCategory(
      name: name,
      id: category,
    );
    notifyListeners();
    return category;
  }

  void removeTag(int id) {
    tags.remove(id);
    appliedTags.removeWhere((_, List<AppliedTag> tagList) {
      tagList.removeWhere((AppliedTag tag) => tag.id == id);
      return tagList.isEmpty;
    });
    notifyListeners();
  }

  void unapplyTag<A extends AppliedTag>(A appliedTag, DateTime day) {
    appliedTags[day]!.remove(appliedTag);
    if (appliedTags[day]!.isEmpty) {
      appliedTags.remove(day);
    }
    notifyListeners();
  }

  /// NOTE: if this ever gets used, the ordering of orphaned tags has to be
  ///       figured out, best to assign them values after
  ///       max(tags.order.nonNulls) to preserve visual location
  void removeCategory(int id) {
    for (final Tag tag in tags.values) {
      if (tag.category == id) {
        tag.category = null;
      }
    }
    categories.remove(id);
    notifyListeners();
  }

  void toggleTo(AppliedToggle appliedTag, bool value) {
    appliedTag.option = value;
    notifyListeners();
  }

  void changeListOption(AppliedList appliedTag, int index) {
    appliedTag.option = index;
    notifyListeners();
  }

  void toggleMultiOption(AppliedMulti appliedTag, int index) {
    if (appliedTag.options.contains(index)) {
      appliedTag.options.remove(index);
    } else {
      appliedTag.options.add(index);
    }
    notifyListeners();
  }

  void clear() {
    tags.clear();
    appliedTags.clear();
    categories.clear();
    nextTagId = 0;
    nextCategory = 0;
    notifyListeners();
  }

  void changeOrder<T extends Tag>(T tagData, int index) {
    tagData.order = index;
    notifyListeners();
  }

  Map<int, Tag> tags;
  Map<DateTime, List<AppliedTag>> appliedTags;
  Map<int, TagCategory> categories;
  int nextTagId;
  int nextCategory;
}
