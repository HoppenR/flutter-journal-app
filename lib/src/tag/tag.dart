import 'package:flutter/material.dart';

import 'icons.dart';

enum TagTypes { list, multi, toggle }

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
  });
}

class TagCategory {
  TagCategory({required this.name, required this.id});

  factory TagCategory.fromJson(Map<String, dynamic> json) {
    return TagCategory(name: json['name'], id: json['id']);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'name': name, 'id': id};
  }

  final String name;
  final int id;
}
