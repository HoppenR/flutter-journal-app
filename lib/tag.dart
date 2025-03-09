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
Map<DateTime, List<AppliedTagData>> appliedTags =
    <DateTime, List<AppliedTagData>>{};

enum TagType {
  list,
  toggle,
  multi,
}

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
    if (tagData.type == TagType.list) {
      return AppliedTagData.list(tagData, json['listOption']);
    } else if (tagData.type == TagType.toggle) {
      return AppliedTagData.toggle(tagData, json['toggleOption']);
    } else if (tagData.type == TagType.multi) {
      return AppliedTagData.multi(tagData, json['listOption']);
    } else {
      throw UnimplementedError();
    }
  }

  String get name => tagData.name;
  TagType get type => tagData.type;

  final TagData tagData;

  int? listOption;
  List<int>? multiOptions;
  bool? toggleOption;
}
