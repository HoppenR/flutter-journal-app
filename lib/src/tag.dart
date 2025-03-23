import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A TagManager class for storing and interacting with tags
// with functionality for propagating updates to watchers
class TagManager extends ChangeNotifier {
  TagManager({
    required this.tags,
    required this.appliedTags,
    required this.nextTagId,
  });

  void addTagList(String name, List<String> listData, IconData icon) {
    final int tagId = nextTagId++;
    final TagData tag = TagData.list(tagId, name, listData, icon, tagId);
    tags[tagId] = tag;
    notifyListeners();
  }

  void addTagToggle(String name, IconData icon) {
    final int tagId = nextTagId++;
    final TagData tag = TagData.toggle(tagId, name, icon, tagId);
    tags[tagId] = tag;
    notifyListeners();
  }

  void addTagMulti(String name, List<String> listData, IconData icon) {
    final int tagId = nextTagId++;
    final TagData tag = TagData.multi(tagId, name, listData, icon, tagId);
    tags[tagId] = tag;
    notifyListeners();
  }

  void removeTag(int id) {
    tags.remove(id);

    appliedTags.removeWhere((_, List<AppliedTagData> tagList) {
      tagList.removeWhere((AppliedTagData tag) => tag.id == id);
      return tagList.isEmpty;
    });
    notifyListeners();
  }

  void applyTag(AppliedTagData appliedTag, DateTime day) {
    appliedTags.putIfAbsent(day, () => <AppliedTagData>[]).add(appliedTag);
    notifyListeners();
  }

  void unapplyTag(AppliedTagData appliedTag, DateTime day) {
    appliedTags[day]!.remove(appliedTag);
    if (appliedTags[day]!.isEmpty) {
      appliedTags.remove(day);
    }
    notifyListeners();
  }

  void toggleTo(AppliedTagData appliedTag, bool value) {
    assert(tags[appliedTag.id]!.type == TagTypes.toggle);
    appliedTag.toggleOption = value;
    notifyListeners();
  }

  void changeListOption(AppliedTagData appliedTag, int index) {
    assert(tags[appliedTag.id]!.type == TagTypes.list);
    appliedTag.listOption = index;
    notifyListeners();
  }

  void toggleMultiOption(AppliedTagData appliedTag, int index) {
    assert(tags[appliedTag.id]!.type == TagTypes.multi);
    final List<int> multiOptions = appliedTag.multiOptions!;
    if (multiOptions.contains(index)) {
      multiOptions.remove(index);
    } else {
      multiOptions.add(index);
    }
    notifyListeners();
  }

  void changeOrder(TagData tagData, int index) {
    tagData.order = index;
    notifyListeners();
  }

  // NOTE: These are set as side effects in loadUserPrefs upon startup
  Map<int, TagData> tags;
  Map<DateTime, List<AppliedTagData>> appliedTags;
  int nextTagId;
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
    this.order,
  ) : type = TagTypes.list;
  TagData.toggle(
    this.id,
    this.name,
    this.icon,
    this.order,
  ) : type = TagTypes.toggle;
  TagData.multi(
    this.id,
    this.name,
    List<String> this.listData,
    this.icon,
    this.order,
  ) : type = TagTypes.multi;

  List<String> get list {
    if (listData != null) {
      return listData!;
    }
    throw UnsupportedError('called list on non-list type');
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type.toJson(),
      'icon': icon.codePoint,
      'order': order,
      if (listData != null) 'listData': listData,
    };
  }

  static TagData fromJson(Map<String, dynamic> json) {
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
        );
      case TagTypes.toggle:
        return TagData.toggle(
          json['id'],
          json['name'],
          availableIcons[codePoint]!,
          json['order'],
        );
      case TagTypes.multi:
        return TagData.multi(
          json['id'],
          json['name'],
          List<String>.from(json['listData']),
          availableIcons[codePoint]!,
          json['order'],
        );
    }
  }

  final String name;
  final TagTypes type;
  final IconData icon;
  final int id;
  int order;

  List<String>? listData;

  final Key key = UniqueKey();
}

class AppliedTagData {
  AppliedTagData.list(this.id, int this.listOption);

  AppliedTagData.toggle(this.id, bool this.toggleOption);

  AppliedTagData.multi(this.id, List<int> this.multiOptions);

  String string(BuildContext context) {
    final TagManager tagManager = context.read<TagManager>();
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (listOption != null) 'listOption': listOption,
      if (toggleOption != null) 'toggleOption': toggleOption,
      if (multiOptions != null) 'multiOptions': multiOptions,
    };
  }

  static AppliedTagData fromJson(
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
        return AppliedTagData.list(id, json['listOption']);
      case TagTypes.toggle:
        return AppliedTagData.toggle(id, json['toggleOption']);
      case TagTypes.multi:
        return AppliedTagData.multi(id, List<int>.from(json['multiOptions']));
    }
  }

  //String get name => tag.name;
  //TagTypes get type => tag.type;
  //IconData get icon => tag.icon;

  final int id;

  int? listOption;
  bool? toggleOption;
  List<int>? multiOptions;
}
