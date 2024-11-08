Map<String, TagData> tagNames = <String, TagData>{};
Map<DateTime, List<AppliedTagData>>
  appliedTags = <DateTime, List<AppliedTagData>>{};

enum TagType {
  list,
  strikethrough,
}

class TagData {
  TagData.list(this.name, this.listData) : type = TagType.list;
  TagData.strikethrough(this.name) : type = TagType.strikethrough;

  List<String> get list {
    return listData ?? (throw ArgumentError('called list on non-list type'));
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'type': type.toString().split('.').last,
      'listData': listData,
    };
  }

  static TagData fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'list') {
      return TagData.list(json['name'], List<String>.from(json['listData']));
    } else if (json['type'] == 'strikethrough') {
      return TagData.strikethrough(json['name']);
    } else {
      throw AssertionError('invalid type in json');
    }
  }

  final String name;
  final TagType type;

  List<String>? listData;
}

class AppliedTagData {
  AppliedTagData.list(this.tagData, this.listOption);
  AppliedTagData.strikethrough(this.tagData);

  String get string {
    switch (tagData.type) {
      case TagType.list:
        return tagData.list[listOption!];
      case TagType.strikethrough:
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
      return AppliedTagData.strikethrough(tagData);
    }
  }

  String get name => tagData.name;
  TagType get type => tagData.type;

  final TagData tagData;

  int? listOption;
}
