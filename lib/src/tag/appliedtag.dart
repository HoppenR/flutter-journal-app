import 'tag.dart';

sealed class AppliedTag {
  const AppliedTag(this.id);

  factory AppliedTag.fromJson(Map<String, dynamic> json, Map<int, Tag> tags) {
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
        return <String, dynamic>{'id': id, 'listOption': list.option};
      case final AppliedMulti multi:
        return <String, dynamic>{'id': id, 'multiOptions': multi.options};
      case final AppliedToggle toggle:
        return <String, dynamic>{'id': id, 'toggleOption': toggle.option};
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
