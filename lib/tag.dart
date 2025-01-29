// Vim: set shiftwidth=2 :
import 'package:flutter/material.dart';
// TODO(Christoffer): More tag types
//                    - [x] free-text fields
//                    - [x] on/off
//                    - [ ] multi-selections (emoji+)
//                    - [ ] levels
//                    - [ ] color picker
//                    - [ ] Blood-levels
//                    - [ ] Tag colors

Map<String, TagData> tagNames = <String, TagData>{};
Map<DateTime, List<AppliedTagData>>
  appliedTags = <DateTime, List<AppliedTagData>>{};

enum TagType {
  list,
  toggle,
}

class TagData {
  TagData.list(this.name, this.listData, this.icon) : type = TagType.list;
  TagData.toggle(this.name, this.icon) : type = TagType.toggle;

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
    final IconData icon = IconData(json['icon'], fontFamily: 'MaterialIcons');
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
  AppliedTagData.toggle(this.tagData);

  String get string {
    switch (tagData.type) {
      case TagType.list:
        return tagData.list[listOption!];
      case TagType.toggle:
        return tagData.name;
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tagData': tagData.toJson(),
      'listOption': listOption,
    };
  }

  static AppliedTagData fromJson(Map<String, dynamic> json) {
    final TagData tagData = TagData.fromJson(json['tagData']);
    if (tagData.type == TagType.list) {
      return AppliedTagData.list(tagData, json['listOption']);
    } else {
      return AppliedTagData.toggle(tagData);
    }
  }

  String get name => tagData.name;
  TagType get type => tagData.type;

  final TagData tagData;

  int? listOption;
  bool? toggleOption;
}
