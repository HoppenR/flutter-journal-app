import 'package:flutter/material.dart';

final Map<int, IconData> availableIcons = <int, IconData>{
  Icons.favorite.codePoint: Icons.favorite,

  // ICONS
  Icons.add_task.codePoint: Icons.add_task,
  Icons.alarm.codePoint: Icons.alarm,
  Icons.bloodtype.codePoint: Icons.bloodtype,
  Icons.bloodtype_outlined.codePoint: Icons.bloodtype_outlined,
  Icons.brightness_5.codePoint: Icons.brightness_5,
  Icons.bubble_chart.codePoint: Icons.bubble_chart,
  Icons.calendar_today.codePoint: Icons.calendar_today,
  Icons.check.codePoint: Icons.check,
  Icons.cloud.codePoint: Icons.cloud,
  Icons.coffee.codePoint: Icons.coffee,
  Icons.emoji_emotions.codePoint: Icons.emoji_emotions,
  Icons.energy_savings_leaf.codePoint: Icons.energy_savings_leaf,
  Icons.fastfood.codePoint: Icons.fastfood,
  Icons.fitness_center.codePoint: Icons.fitness_center,
  Icons.healing.codePoint: Icons.healing,
  Icons.home.codePoint: Icons.home,
  Icons.icecream.codePoint: Icons.icecream,
  Icons.local_cafe.codePoint: Icons.local_cafe,
  Icons.local_florist.codePoint: Icons.local_florist,
  Icons.local_hospital.codePoint: Icons.local_hospital,
  Icons.local_pizza.codePoint: Icons.local_pizza,
  Icons.medical_services.codePoint: Icons.medical_services,
  Icons.medication_rounded.codePoint: Icons.medication_rounded,
  Icons.mood.codePoint: Icons.mood,
  Icons.nature_people.codePoint: Icons.nature_people,
  Icons.nightlight.codePoint: Icons.nightlight,
  Icons.notes.codePoint: Icons.notes,
  Icons.opacity.codePoint: Icons.opacity,
  Icons.palette_outlined.codePoint: Icons.palette_outlined,
  Icons.pets.codePoint: Icons.pets,
  Icons.phone.codePoint: Icons.phone,
  Icons.phone_android.codePoint: Icons.phone_android,
  Icons.phone_iphone.codePoint: Icons.phone_iphone,
  Icons.phone_paused.codePoint: Icons.phone_paused,
  Icons.school.codePoint: Icons.school,
  Icons.self_improvement.codePoint: Icons.self_improvement,
  Icons.sentiment_dissatisfied.codePoint: Icons.sentiment_dissatisfied,
  Icons.sentiment_neutral.codePoint: Icons.sentiment_neutral,
  Icons.sentiment_satisfied_alt.codePoint: Icons.sentiment_satisfied_alt,
  Icons.sentiment_very_dissatisfied.codePoint:
      Icons.sentiment_very_dissatisfied,
  Icons.sentiment_very_satisfied.codePoint: Icons.sentiment_very_satisfied,
  Icons.sentiment_very_satisfied.codePoint: Icons.sentiment_very_satisfied,
  Icons.shield_moon.codePoint: Icons.shield_moon,
  Icons.shopping_cart.codePoint: Icons.shopping_cart,
  Icons.sick.codePoint: Icons.sick,
  Icons.sports_soccer.codePoint: Icons.sports_soccer,
  Icons.star.codePoint: Icons.star,
  Icons.star_border.codePoint: Icons.star_border,
  Icons.thermostat.codePoint: Icons.thermostat,
  Icons.today.codePoint: Icons.today,
  Icons.tune.codePoint: Icons.tune,
  Icons.warning.codePoint: Icons.warning,
  Icons.water_drop.codePoint: Icons.water_drop,
  Icons.woman.codePoint: Icons.woman,
  Icons.work.codePoint: Icons.work,
};

// --- TAGMANAGER ---
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

// --- HELPER TYPES ---
typedef TagFactory<T extends Tag> = T Function(
  int id,
  String name,
  IconData icon,
  int order, {
  required List<String> list,
  int? category,
});

enum TagTypes {
  list,
  multi,
  toggle,
}

// --- TAG ---
sealed class Tag {
  Tag(this.id, this.name, this.icon, this.order, {this.category})
      : key = ValueKey<int>(id);

  factory Tag.fromJson(Map<String, dynamic> json) {
    final int codePoint = json['icon'];
    final String type = json['type'];
    switch (type) {
      case 'list':
        return ListTag(
          json['id'],
          json['name'],
          availableIcons[codePoint]!,
          json['order'],
          list: List<String>.from(json['list']),
          category: json['category'],
        );
      case 'multi':
        return MultiTag(
          json['id'],
          json['name'],
          availableIcons[codePoint]!,
          json['order'],
          list: List<String>.from(json['list']),
          category: json['category'],
        );
      case 'toggle':
        return ToggleTag(
          json['id'],
          json['name'],
          availableIcons[codePoint]!,
          json['order'],
          category: json['category'],
        );
      default:
        throw AssertionError('invalid type in json');
    }
  }

  Map<String, dynamic> toJson() {
    switch (this) {
      case final MultiTag multi:
        return <String, dynamic>{
          'id': id,
          'name': name,
          'type': 'multi',
          'icon': icon.codePoint,
          'order': order,
          'list': multi.list,
          'category': category,
        };
      case final ListTag list:
        return <String, dynamic>{
          'id': id,
          'name': name,
          'type': 'list',
          'icon': icon.codePoint,
          'order': order,
          'list': list.list,
          'category': category,
        };
      case ToggleTag():
        return <String, dynamic>{
          'id': id,
          'name': name,
          'type': 'toggle',
          'icon': icon.codePoint,
          'order': order,
          'category': category,
        };
    }
  }

  final IconData icon;
  final Key key;
  final String name;
  final int id;

  int order;
  int? category;
}

// Interface class
sealed class TagWithList extends Tag {
  TagWithList(
    super.id,
    super.name,
    super.icon,
    super.order, {
    required this.list,
    super.category,
  });

  final List<String> list;
}

class ListTag extends TagWithList {
  ListTag(
    super.id,
    super.name,
    super.icon,
    super.order, {
    required super.list,
    super.category,
  });
}

class MultiTag extends TagWithList {
  MultiTag(
    super.id,
    super.name,
    super.icon,
    super.order, {
    required super.list,
    super.category,
  });
}

class ToggleTag extends Tag {
  ToggleTag(
    super.id,
    super.name,
    super.icon,
    super.order, {
    // This is used match TagFactory signature, do not use
    // ignore: avoid_unused_constructor_parameters
    List<String>? list,
    super.category,
  }) : assert(list == null || list.isEmpty);
}

// --- APPLIED TAG ---
sealed class AppliedTag {
  const AppliedTag(this.id);

  factory AppliedTag.fromJson(
    Map<String, dynamic> json,
    Map<int, Tag> tags,
  ) {
    final int id = json['id'];
    final Tag tag = tags[id]!;
    switch (tag) {
      case ListTag():
        return AppliedList(id, json['listOption'], tag);
      case MultiTag():
        return AppliedMulti(id, List<int>.from(json['multiOptions']), tag);
      case ToggleTag():
        return AppliedToggle(id, json['toggleOption'], tag);
    }
  }

  Map<String, dynamic> toJson() {
    switch (this) {
      case final AppliedList list:
        return <String, dynamic>{
          'id': id,
          'listOption': list.option,
        };
      case final AppliedMulti multi:
        return <String, dynamic>{
          'id': id,
          'multiOptions': multi.options,
        };
      case final AppliedToggle toggle:
        return <String, dynamic>{
          'id': id,
          'toggleOption': toggle.option,
        };
    }
  }

  String string() {
    switch (this) {
      case final AppliedList list:
        return list.tag.list[list.option];
      case final AppliedMulti multi:
        return multi.options
            .map((int index) => multi.tag.list[index])
            .join(',');
      case final AppliedToggle toggle:
        return toggle.tag.name;
    }
  }

  final int id;
}

class AppliedList extends AppliedTag {
  AppliedList(super.id, this.option, this.tag);

  int option;
  final ListTag tag;
}

class AppliedMulti extends AppliedTag {
  AppliedMulti(super.id, this.options, this.tag);

  List<int> options;
  final MultiTag tag;
}

class AppliedToggle extends AppliedTag {
  AppliedToggle(super.id, this.option, this.tag);

  bool option;
  final ToggleTag tag;
}

class TagCategory {
  TagCategory({required this.name, required this.id});

  factory TagCategory.fromJson(Map<String, dynamic> json) {
    return TagCategory(
      name: json['name'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'id': id,
    };
  }

  final String name;
  final int id;
}
