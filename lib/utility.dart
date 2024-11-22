// Vim: set shiftwidth=2 :
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tag.dart';

Future<void> saveTags() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final Map<String, Map<String, dynamic>> tagNamesJson = tagNames.map(
    (String key, TagData value) {
      return MapEntry<String, Map<String, dynamic>>(
        key,
        value.toJson(),
      );
    },
  );

  final Map<String, List<Map<String, dynamic>>>
    appliedTagsJson = appliedTags.map(
      (DateTime key, List<AppliedTagData> value) {
        return MapEntry<String, List<Map<String, dynamic>>>(
          key.toIso8601String(),
          value.map((AppliedTagData tag) => tag.toJson()).toList(),
        );
      },
  );

  final String dataToSave = json.encode(<String, dynamic>{
    'tagNames': tagNamesJson,
    'appliedTags': appliedTagsJson,
  });

  await prefs.setString('tags', dataToSave);
}

Future<void> loadTags() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedData = prefs.getString('tags');

  if (savedData == null) {
    return;
  }

  final Map<String, dynamic> decodedData = json.decode(savedData);

  tagNames = (decodedData['tagNames'] as Map<String, dynamic>).map(
    (String key, dynamic value) {
      return MapEntry<String, TagData>(
        key,
        TagData.fromJson(value),
      );
    },
  );

  appliedTags = (decodedData['appliedTags'] as Map<String, dynamic>).map(
    (String key, dynamic value) {
      return MapEntry<DateTime, List<AppliedTagData>>(
        DateTime.parse(key),
        (value as List<dynamic>).map((dynamic item) {
          return AppliedTagData.fromJson(item as Map<String, dynamic>);
        }).toList(),
      );
    },
  );
}

Future<void> clearPreferences(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
