import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tag.dart';

// Used to return data from loadUserPrefs in a structured way
// tagData and appliedTags are cached in tags.dart
// locale should be stored elsewhere, such as in MaterialApp(locale: ...)
class UserPrefs {
  const UserPrefs({
    required this.locale,
    required this.tagData,
    required this.appliedTags,
    required this.nextTagId,
  });

  final Locale? locale;
  final Map<int, dynamic> tagData;
  final Map<DateTime, dynamic> appliedTags;
  final int nextTagId;
}

Future<void> saveLocale(Locale locale) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString('locale', locale.languageCode);
}

/// NOTE: If saving new tags probably want to call saveNextTagId after this
Future<void> saveTagData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final List<Map<String, dynamic>> tagDataJson = TagManager()
      .tags
      .values
      .map(
        (TagData value) => value.toJson(),
      )
      .toList();

  await prefs.setString('tagData', json.encode(tagDataJson));
}

Future<void> saveAppliedTags() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final Map<String, List<Map<String, dynamic>>> appliedTagsJson =
      TagManager().appliedTags.map(
    (DateTime key, List<AppliedTagData> value) {
      return MapEntry<String, List<Map<String, dynamic>>>(
        DateFormat('yyyy-MM-dd').format(key),
        value.map((AppliedTagData tag) => tag.toJson()).toList(growable: false),
      );
    },
  );

  await prefs.setString('appliedTags', json.encode(appliedTagsJson));
}

Future<void> saveNextTagId() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final int initialTagId = TagManager().nextTagId;
  prefs.setInt('nextTagId', initialTagId);
}

Future<Locale?> loadLocale() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? localeCode = prefs.getString('locale');
  return localeCode != null ? Locale(localeCode) : null;
}

Future<Map<int, dynamic>> loadTagData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedData = prefs.getString('tagData');

  if (savedData != null) {
    TagManager().tags = Map<int, TagData>.fromEntries(
        (json.decode(savedData) as List<dynamic>).map(
      (dynamic value) {
        final TagData tagData = TagData.fromJson(value);
        return MapEntry<int, TagData>(tagData.id, tagData);
      },
    ));
  } else {
    TagManager().tags = <int, TagData>{};
  }

  return TagManager().tags;
}

Future<Map<DateTime, dynamic>> loadAppliedTags() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedData = prefs.getString('appliedTags');

  if (savedData != null) {
    TagManager().appliedTags =
        (json.decode(savedData) as Map<String, dynamic>).map(
      (String key, dynamic value) {
        return MapEntry<DateTime, List<AppliedTagData>>(
          DateTime.parse(key),
          (value as List<dynamic>).map((dynamic item) {
            return AppliedTagData.fromJson(item as Map<String, dynamic>);
          }).toList(growable: true),
        );
      },
    );
  } else {
    TagManager().appliedTags = <DateTime, List<AppliedTagData>>{};
  }

  return TagManager().appliedTags;
}

Future<int> loadNextTagId() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final int initialTagId = prefs.getInt('nextTagId') ?? 0;
  TagManager().nextTagId = initialTagId;
  return initialTagId;
}

Future<UserPrefs> loadUserPrefs() async {
  final Future<Locale?> localeFuture = loadLocale();
  final Future<int> nextTagIdFuture = loadNextTagId();
  final Future<Map<int, dynamic>> tagDataFuture = loadTagData();

  // NOTE:
  // TagData needs to be loaded for AppliedTagData constructors to be able to
  // save a reference to the corresponding tag via its ID.
  // Wait for all TagData to be loaded before loading all AppliedTag
  final Map<int, dynamic> tagData = await tagDataFuture;
  final Future<Map<DateTime, dynamic>> appliedTagsFuture = loadAppliedTags();

  return UserPrefs(
    locale: await localeFuture,
    tagData: tagData,
    appliedTags: await appliedTagsFuture,
    nextTagId: await nextTagIdFuture,
  );
}

Future<void> clearPreferences(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

Future<void> showSnackBar(BuildContext context, String message) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
