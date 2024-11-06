Map<String, TagData> tagNames = <String, TagData>{};
Map<DateTime, List<AppliedTagData>>
  appliedTags = <DateTime, List<AppliedTagData>>{};

enum TagType {
  list,
  strikethrough,
}

class TagData {
  TagData.list(this.listData) : type = TagType.list;
  TagData.strikethrough(this.strikethroughData) : type = TagType.strikethrough;

  final TagType type;

  List<String>? listData;
  String? strikethroughData;

  List<String> get list {
    return listData ?? (throw ArgumentError('Expected List<String> data'));
  }
  String get strikethrough {
    return strikethroughData ?? (throw ArgumentError('Expected String data'));
  }
}

class AppliedTagData {
  AppliedTagData.list(this.tagData, this.listOption);
  AppliedTagData.strikethrough(this.tagData);

  String get string {
    switch (tagData.type) {
      case TagType.list:
        return tagData.list[listOption!];
      case TagType.strikethrough:
        return tagData.strikethroughData!;
    }
  }

  TagType get type => tagData.type;

  final TagData tagData;

  int? listOption;
}
