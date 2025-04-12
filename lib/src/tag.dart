import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A TagManager class for storing and interacting with tags
// with functionality for propagating updates to watchers
class TagManager extends ChangeNotifier {
  TagManager({
    required this.tags,
    required this.appliedTags,
    required this.categories,
    required this.nextTagId,
    required this.nextCategoryId,
  });

  int addTagList(String name, List<String> listData, IconData icon) {
    final int tagId = nextTagId++;
    final TagData tag = TagData.list(tagId, name, listData, icon, tagId);
    tags[tagId] = tag;
    notifyListeners();
    return tagId;
  }

  int addTagToggle(String name, IconData icon) {
    final int tagId = nextTagId++;
    final TagData tag = TagData.toggle(tagId, name, icon, tagId);
    tags[tagId] = tag;
    notifyListeners();
    return tagId;
  }

  int addTagMulti(String name, List<String> listData, IconData icon) {
    final int tagId = nextTagId++;
    final TagData tag = TagData.multi(tagId, name, listData, icon, tagId);
    tags[tagId] = tag;
    notifyListeners();
    return tagId;
  }

  void applyTag(AppliedTagData appliedTag, DateTime day) {
    appliedTags.putIfAbsent(day, () => <AppliedTagData>[]).add(appliedTag);
    notifyListeners();
  }

  int addCategory(String name) {
    final int categoryId = nextCategoryId++;
    categories[categoryId] = TagCategory(
      name: name,
      id: categoryId,
    );
    notifyListeners();
    return categoryId;
  }

  void removeTag(int id) {
    tags.remove(id);

    appliedTags.removeWhere((_, List<AppliedTagData> tagList) {
      tagList.removeWhere((AppliedTagData tag) => tag.id == id);
      return tagList.isEmpty;
    });
    notifyListeners();
  }

  void unapplyTag(AppliedTagData appliedTag, DateTime day) {
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
    for (final TagData tag in tags.values) {
      if (tag.categoryId == id) {
        tag.categoryId = null;
      }
    }
    categories.remove(id);
    notifyListeners();
  }

  void toggleTo(AppliedTagData appliedTag, bool value) {
    assert(appliedTag.type == TagTypes.toggle);
    appliedTag.toggleOption = value;
    notifyListeners();
  }

  void changeListOption(AppliedTagData appliedTag, int index) {
    assert(appliedTag.type == TagTypes.list);
    appliedTag.listOption = index;
    notifyListeners();
  }

  void toggleMultiOption(AppliedTagData appliedTag, int index) {
    assert(appliedTag.type == TagTypes.multi);
    final List<int> multiOptions = appliedTag.multiOptions!;
    if (multiOptions.contains(index)) {
      multiOptions.remove(index);
    } else {
      multiOptions.add(index);
    }
    notifyListeners();
  }

  void clear() {
    tags.clear();
    appliedTags.clear();
    categories.clear();
    nextTagId = 0;
    nextCategoryId = 0;
    notifyListeners();
  }

  void changeOrder(TagData tagData, int index) {
    tagData.order = index;
    notifyListeners();
  }

  // NOTE: These are set as side effects in loadUserPrefs upon startup
  Map<int, TagData> tags;
  Map<DateTime, List<AppliedTagData>> appliedTags;
  Map<int, TagCategory> categories;
  int nextTagId;
  int nextCategoryId;
}

enum TagTypes {
  list,
  toggle,
  multi,
}

extension TagType on TagTypes {
  static TagTypes fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'list') {
      return TagTypes.list;
    } else if (json['type'] == 'toggle') {
      return TagTypes.toggle;
    } else if (json['type'] == 'multi') {
      return TagTypes.multi;
    } else {
      throw AssertionError('invalid type in json');
    }
  }

  String toJson() {
    return toString().split('.').last;
  }
}

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

class TagData {
  TagData.list(
    this.id,
    this.name,
    List<String> this.listData,
    this.icon,
    this.order, [
    this.categoryId,
  ]) : type = TagTypes.list;
  TagData.toggle(
    this.id,
    this.name,
    this.icon,
    this.order, [
    this.categoryId,
  ])  : type = TagTypes.toggle,
        listData = null;
  TagData.multi(
    this.id,
    this.name,
    List<String> this.listData,
    this.icon,
    this.order, [
    this.categoryId,
  ]) : type = TagTypes.multi;

  factory TagData.fromJson(Map<String, dynamic> json) {
    final int codePoint = json['icon'];
    final TagTypes type = TagType.fromJson(json);
    switch (type) {
      case TagTypes.list:
        return TagData.list(
          json['id'],
          json['name'],
          List<String>.from(json['listData']),
          availableIcons[codePoint]!,
          json['order'],
          json['category'],
        );
      case TagTypes.toggle:
        return TagData.toggle(
          json['id'],
          json['name'],
          availableIcons[codePoint]!,
          json['order'],
          json['category'],
        );
      case TagTypes.multi:
        return TagData.multi(
          json['id'],
          json['name'],
          List<String>.from(json['listData']),
          availableIcons[codePoint]!,
          json['order'],
          json['category'],
        );
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.toJson(),
      'icon': icon.codePoint,
      'order': order,
      'category': categoryId,
      if (listData != null) 'listData': listData,
    };
  }

  List<String> get list {
    if (listData != null) {
      return listData!;
    }
    throw UnsupportedError('called list on non-list type');
  }

  final String name;
  final TagTypes type;
  final IconData icon;
  final int id;

  int order;
  int? categoryId;
  final List<String>? listData;

  final Key key = UniqueKey();
}

class AppliedTagData {
  AppliedTagData.list(this.id, int this.listOption, this.tag);

  AppliedTagData.toggle(this.id, bool this.toggleOption, this.tag);

  AppliedTagData.multi(this.id, List<int> this.multiOptions, this.tag);

  factory AppliedTagData.fromJson(
    Map<String, dynamic> json,
    Map<int, TagData> tags,
  ) {
    final int id = json['id'];
    switch (tags[id]?.type) {
      case null:
        throw StateError(
          'tag does not exist while creating its AppliedTagData',
        );
      case TagTypes.list:
        return AppliedTagData.list(id, json['listOption'], tags[id]!);
      case TagTypes.toggle:
        return AppliedTagData.toggle(id, json['toggleOption'], tags[id]!);
      case TagTypes.multi:
        return AppliedTagData.multi(
          id,
          List<int>.from(json['multiOptions']),
          tags[id]!,
        );
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (listOption != null) 'listOption': listOption,
      if (toggleOption != null) 'toggleOption': toggleOption,
      if (multiOptions != null) 'multiOptions': multiOptions,
    };
  }

  String string(BuildContext context) {
    final TagManager tagManager = context.watch<TagManager>();
    final TagData tag = tagManager.tags[id]!;
    switch (tag.type) {
      case TagTypes.list:
        return tag.list[listOption!];
      case TagTypes.toggle:
        return tag.name;
      case TagTypes.multi:
        return multiOptions!.map((int index) => tag.listData![index]).join();
    }
  }

  String get name => tag.name;
  TagTypes get type => tag.type;
  IconData get icon => tag.icon;
  int? get categoryId => tag.categoryId;

  final int id;
  final TagData tag;

  int? listOption;
  bool? toggleOption;
  List<int>? multiOptions;
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
