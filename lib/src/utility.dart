import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'graph.dart';
import 'graph/dashboard.dart';
import 'settings.dart';
import 'tag.dart';

// Used to return data from loadUserPrefs in a structured way
// tagData and appliedTags are cached in tags.dart
// locale should be stored elsewhere, such as in MaterialApp(locale: ...)
class UserPrefs {
  const UserPrefs({
    required this.locale,
    required this.theme,
    required this.tagData,
    required this.appliedTags,
    required this.dashboards,
    required this.categories,
    required this.nextTagId,
    required this.nextCategoryId,
  });

  final Locale? locale;
  final Color? theme;
  final Map<int, TagData> tagData;
  final Map<DateTime, List<AppliedTagData>> appliedTags;
  final List<ChartDashboardData> dashboards;
  final Map<int, TagCategory> categories;
  final int nextTagId;
  final int nextCategoryId;
}

Future<void> saveLocale(Locale locale) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString('locale', locale.languageCode);
}

Future<void> saveTheme(String theme) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString('theme', theme);
}

/// NOTE: If saving new tags probably want to call saveNextTagId after this
Future<void> saveTagData(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!context.mounted) {
    throw AssertionError();
  }
  final TagManager tagManager = context.read<TagManager>();
  final List<Map<String, dynamic>> tagDataJson = tagManager.tags.values
      .map((TagData tagData) => tagData.toJson())
      .toList();

  await prefs.setString('tagData', json.encode(tagDataJson));
}

Future<void> saveAppliedTags(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!context.mounted) {
    throw AssertionError();
  }
  final TagManager tagManager = context.read<TagManager>();
  final Map<String, List<Map<String, dynamic>>> appliedTagsJson =
      tagManager.appliedTags.map(
    (DateTime key, List<AppliedTagData> value) {
      return MapEntry<String, List<Map<String, dynamic>>>(
        DateFormat('yyyy-MM-dd').format(key),
        value.map((AppliedTagData tag) => tag.toJson()).toList(growable: false),
      );
    },
  );

  await prefs.setString('appliedTags', json.encode(appliedTagsJson));
}

Future<void> saveNextTagId(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!context.mounted) {
    throw AssertionError();
  }
  final TagManager tagManager = context.read<TagManager>();
  final int initialTagId = tagManager.nextTagId;
  prefs.setInt('nextTagId', initialTagId);
}

Future<void> saveChartDashboardData(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!context.mounted) {
    throw AssertionError();
  }

  final ChartDashboardManager dashboardManager =
      context.read<ChartDashboardManager>();

  final List<dynamic> dashboardsJson = dashboardManager.dashboards
      .map((ChartDashboardData dashboard) => dashboard.toJson())
      .toList(growable: false);

  prefs.setString('dashboards', json.encode(dashboardsJson));
}

Future<void> saveCategories(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!context.mounted) {
    throw AssertionError();
  }
  final TagManager tagManager = context.read<TagManager>();
  final List<Map<String, dynamic>> tagDataJson = tagManager.categories.values
      .map((TagCategory category) => category.toJson())
      .toList();

  await prefs.setString('categories', json.encode(tagDataJson));
}

Future<void> saveNextCategoryId(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!context.mounted) {
    throw AssertionError();
  }
  final TagManager tagManager = context.read<TagManager>();
  final int initialTagId = tagManager.nextCategoryId;
  prefs.setInt('nextCategoryId', initialTagId);
}

Future<Locale?> loadLocale() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? localeCode = prefs.getString('locale');
  return localeCode != null ? Locale(localeCode) : null;
}

Future<Color?> loadTheme() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? theme = prefs.getString('theme');
  return theme != null ? SettingsPage.themes[theme] : null;
}

Future<Map<int, TagData>> loadTagData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedData = prefs.getString('tagData');

  if (savedData == null) {
    return <int, TagData>{};
  }

  return Map<int, TagData>.fromEntries(
    (json.decode(savedData) as List<dynamic>).map(
      (dynamic value) {
        final TagData tagData = TagData.fromJson(value);
        return MapEntry<int, TagData>(tagData.id, tagData);
      },
    ),
  );
}

Future<Map<DateTime, List<AppliedTagData>>> loadAppliedTags(
  Map<int, TagData> tags,
) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedData = prefs.getString('appliedTags');

  if (savedData == null) {
    return <DateTime, List<AppliedTagData>>{};
  }

  return (json.decode(savedData) as Map<String, dynamic>).map(
    (String key, dynamic value) {
      return MapEntry<DateTime, List<AppliedTagData>>(
        DateTime.parse(key),
        (value as List<dynamic>).map((dynamic item) {
          return AppliedTagData.fromJson(item as Map<String, dynamic>, tags);
        }).toList(growable: true),
      );
    },
  );
}

Future<int> loadNextTagId() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final int initialTagId = prefs.getInt('nextTagId') ?? 0;
  return initialTagId;
}

Future<List<ChartDashboardData>> loadChartDashboardData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedData = prefs.getString('dashboards');

  if (savedData == null) {
    return <ChartDashboardData>[];
  }

  return (json.decode(savedData) as List<dynamic>)
      .map((dynamic value) => ChartDashboardData.fromJson(value))
      .toList(growable: true);
}

Future<Map<int, TagCategory>> loadCategories() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedData = prefs.getString('categories');

  if (savedData == null) {
    return <int, TagCategory>{};
  }

  return Map<int, TagCategory>.fromEntries(
    (json.decode(savedData) as List<dynamic>).map(
      (dynamic value) {
        final TagCategory category = TagCategory.fromJson(value);
        return MapEntry<int, TagCategory>(category.id, category);
      },
    ),
  );
}

Future<int> loadNextCategoryId() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final int initialCategoryId = prefs.getInt('nextCategoryId') ?? 0;
  return initialCategoryId;
}

Future<UserPrefs> loadUserPrefs(BuildContext context) {
  final Future<Locale?> localeFuture = loadLocale();
  final Future<Color?> themeFuture = loadTheme();
  final Future<Map<int, TagData>> tagDataFuture = loadTagData();
  final Future<List<ChartDashboardData>> dashboardsFuture =
      loadChartDashboardData();
  final Future<Map<int, TagCategory>> categoriesFuture = loadCategories();

  final Future<int> nextTagIdFuture = loadNextTagId();
  final Future<int> nextCategoryIdFuture = loadNextCategoryId();

  return tagDataFuture.then((Map<int, TagData> tagData) {
    return loadAppliedTags(tagData)
        .then((Map<DateTime, List<AppliedTagData>> appliedTags) {
      return Future.wait(
        <Future<dynamic>>[
          localeFuture,
          themeFuture,
          dashboardsFuture,
          categoriesFuture,
          nextTagIdFuture,
          nextCategoryIdFuture
        ],
      ).then((List<dynamic> values) {
        return UserPrefs(
          locale: values[0] as Locale?,
          theme: values[1] as Color?,
          tagData: tagData,
          appliedTags: appliedTags,
          dashboards: values[2] as List<ChartDashboardData>,
          categories: values[3] as Map<int, TagCategory>,
          nextTagId: values[4] as int,
          nextCategoryId: values[5] as int,
        );
      });
    });
  });
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
