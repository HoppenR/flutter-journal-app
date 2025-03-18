import 'package:flutter/material.dart';
// TODO(Christoffer): More tag types
//                    - [x] free-text fields
//                    - [x] on/off
//                    - [x] multi-selections
//                    - [ ] levels (emojis?)
//                    - [ ] Tag colors (emoji allows for red/white/brown)

Map<String, TagData> tagData = <String, TagData>{};
Map<DateTime, List<AppliedTagData>> appliedTags =
    <DateTime, List<AppliedTagData>>{};

enum TagType {
  list,
  toggle,
  multi,
}

final Map<int, IconData> availableIcons = <int, IconData>{
  Icons.favorite.codePoint: Icons.favorite,

  // ICONS
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
  Icons.pets.codePoint: Icons.pets,
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
  TagData.list(this.name, this.listData, this.icon) : type = TagType.list;
  TagData.toggle(this.name, this.icon) : type = TagType.toggle;
  TagData.multi(this.name, this.listData, this.icon) : type = TagType.multi;

  List<String> get list {
    return listData ?? (throw ArgumentError('called list on non-list type'));
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'icon': icon.codePoint,
      'listData': listData,
      'name': name,
      'type': type.toString().split('.').last,
    };
  }

  static TagData fromJson(Map<String, dynamic> json) {
    final int codePoint = json['icon'];
    final IconData icon = availableIcons[codePoint]!;
    if (json['type'] == 'list') {
      return TagData.list(
        json['name'],
        List<String>.from(json['listData']),
        icon,
      );
    } else if (json['type'] == 'toggle') {
      return TagData.toggle(
        json['name'],
        icon,
      );
    } else if (json['type'] == 'multi') {
      return TagData.multi(
        json['name'],
        List<String>.from(json['listData']),
        icon,
      );
    } else {
      throw AssertionError('invalid type in json');
    }
  }

  final String name;
  final TagType type;
  final IconData icon;

  List<String>? listData;
}

class AppliedTagData {
  AppliedTagData.list(this.tagData, this.listOption);
  AppliedTagData.toggle(this.tagData, this.toggleOption);
  AppliedTagData.multi(this.tagData, this.multiOptions);

  String get string {
    switch (tagData.type) {
      case TagType.list:
        return tagData.list[listOption!];
      case TagType.toggle:
        return tagData.name;
      case TagType.multi:
        return multiOptions!
            .map((int index) => tagData.listData![index])
            .join();
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tagData': tagData.toJson(),
      'listOption': listOption,
      'multiOptions': multiOptions,
      'toggleOption': toggleOption,
    };
  }

  static AppliedTagData fromJson(Map<String, dynamic> json) {
    final TagData tagData = TagData.fromJson(json['tagData']);
    switch (tagData.type) {
      case TagType.list:
        return AppliedTagData.list(tagData, json['listOption']);
      case TagType.toggle:
        return AppliedTagData.toggle(tagData, json['toggleOption']);
      case TagType.multi:
        return AppliedTagData.multi(
          tagData,
          List<int>.from(json['multiOptions']),
        );
    }
  }

  String get name => tagData.name;
  TagType get type => tagData.type;

  final TagData tagData;

  int? listOption;
  List<int>? multiOptions;
  bool? toggleOption;
}
