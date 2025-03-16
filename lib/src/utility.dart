// Vim: set shiftwidth=2 :
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tag.dart';

// Used to return data from loadUserPrefs in a structured way
// tagData and appliedTags are cached in tags.dart
// locale should be stored elsewhere, such as in MaterialApp(locale: ...)
class UserPrefs {
  const UserPrefs({
    this.locale,
    required this.tagData,
    required this.appliedTags,
  });

  final Locale? locale;
  final Map<String, dynamic> tagData;
  final Map<DateTime, dynamic> appliedTags;
}

Future<void> saveLocale(Locale locale) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString('locale', locale.languageCode);
}

Future<void> saveTagData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final Map<String, Map<String, dynamic>> tagDataJson = tagData.map(
    (String key, TagData value) {
      return MapEntry<String, Map<String, dynamic>>(key, value.toJson());
    },
  );

  await prefs.setString('tagData', json.encode(tagDataJson));
}

Future<void> saveAppliedTags() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final Map<String, List<Map<String, dynamic>>> appliedTagsJson =
      appliedTags.map(
    (DateTime key, List<AppliedTagData> value) {
      return MapEntry<String, List<Map<String, dynamic>>>(
        key.toIso8601String(),
        value.map((AppliedTagData tag) => tag.toJson()).toList(),
      );
    },
  );

  await prefs.setString('appliedTags', json.encode(appliedTagsJson));
}

Future<Locale?> loadLocale() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? localeCode = prefs.getString('locale');
  return localeCode != null ? Locale(localeCode) : null;
}

Future<Map<String, dynamic>> loadTagData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedData = prefs.getString('tagData');
  if (savedData == null) {
    return <String, dynamic>{};
  }

  tagData = (json.decode(savedData) as Map<String, dynamic>).map(
    (String key, dynamic value) {
      return MapEntry<String, TagData>(
        key,
        TagData.fromJson(value),
      );
    },
  );

  return tagData;
}

Future<Map<DateTime, dynamic>> loadAppliedTags() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedData = prefs.getString('appliedTags');

  if (savedData == null) {
    return <DateTime, dynamic>{};
  }

  appliedTags = (json.decode(savedData) as Map<String, dynamic>).map(
    (String key, dynamic value) {
      return MapEntry<DateTime, List<AppliedTagData>>(
        DateTime.parse(key),
        (value as List<dynamic>).map((dynamic item) {
          return AppliedTagData.fromJson(item as Map<String, dynamic>);
        }).toList(),
      );
    },
  );

  return appliedTags;
}

Future<UserPrefs> loadUserPrefs() async {
  final Future<Locale?> localeFuture = loadLocale();
  final Future<Map<String, dynamic>> tagDataFuture = loadTagData();
  final Future<Map<DateTime, dynamic>> appliedTagsFuture = loadAppliedTags();

  return UserPrefs(
    locale: await localeFuture,
    tagData: await tagDataFuture,
    appliedTags: await appliedTagsFuture,
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
