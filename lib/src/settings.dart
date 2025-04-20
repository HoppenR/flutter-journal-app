import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'generated/l10n/app_localizations.dart';
import 'graph/dashboard.dart';
import 'journal.dart';
import 'tag.dart';
import 'utility.dart';

@immutable
class EmojiSymbols {
  static final String moon = String.fromCharCode(0xF518);
  static final String book = String.fromCharCode(0xF186);
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context).settingsTitle),
      ),
      body: _buildSettingsContent(context),
    );
  }

  static const Map<String, Color> themes = <String, Color>{
    'deepPurple': Colors.deepPurple,
    'deepOrange': Colors.deepOrange,
    'pink': Colors.pink,
    'indigoAccent': Colors.indigoAccent,
    'amber': Colors.amber,
    'purpleAccent': Colors.purpleAccent,
    'purple': Colors.purple,
    'cyanAccent': Colors.cyanAccent,
    'cyan': Colors.cyan,
    'green': Colors.green,
    'lightGreen': Colors.lightGreen,
    'teal': Colors.teal,
    'blueGrey': Colors.blueGrey,
    'blue': Colors.blue,
  };

  Widget _buildSettingsContent(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            AppLocalizations.of(context).appTitle,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          _buildLogoIcon(context),
          _buildChangeLocaleDropdown(context),
          const SizedBox(height: 8.0),
          _buildThemepicker(context),
          const SizedBox(height: 24.0),
          _buildClearPreferencesDropdown(context),
          const SizedBox(height: 16.0),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildLogoIcon(BuildContext context) {
    return Stack(
      children: <Widget>[
        Text(
          EmojiSymbols.book,
          style: TextStyle(
            fontSize: 126.0,
            color: Theme.of(context).colorScheme.primary,
            fontFamily: 'JournalApp',
          ),
        ),
        Positioned(
          left: 20.0,
          child: Text(
            EmojiSymbols.moon,
            style: TextStyle(
              fontSize: 126.0,
              color: Theme.of(context).colorScheme.inversePrimary,
              fontFamily: 'JournalApp',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeLocaleDropdown(BuildContext context) {
    return DropdownMenu<String>(
      width: 152.0,
      requestFocusOnTap: false,
      initialSelection: Localizations.localeOf(context).languageCode,
      leadingIcon: const Icon(Icons.language),
      dropdownMenuEntries: AppLocalizations.supportedLocales.map(
        (Locale locale) {
          return DropdownMenuEntry<String>(
            value: locale.languageCode,
            label: locale.languageCode,
          );
        },
      ).toList(growable: false),
      onSelected: (String? newValue) {
        if (newValue != null) {
          JournalApp.setLocale(context, Locale(newValue));
        }
      },
    );
  }

  Widget _buildThemepicker(BuildContext context) {
    return SizedBox(
      width: 270.0,
      height: 60.0,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10.0,
        runSpacing: 10.0,
        children: themes.keys.map((String theme) {
          return GestureDetector(
            onTap: () {
              JournalApp.setTheme(context, theme);
            },
            child: Theme(
              data: ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themes[theme]!,
                ),
              ),
              child: Builder(builder: (BuildContext context) {
                return Transform.rotate(
                  angle: math.pi / 4.0,
                  child: Container(
                    width: 30.0,
                    height: 30.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: <Color>[
                          Theme.of(context).colorScheme.inversePrimary,
                          Theme.of(context).colorScheme.inversePrimary,
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary,
                        ],
                        stops: const <double>[
                          0.0,
                          0.5,
                          0.5,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          AppLocalizations.of(context).aboutTitle,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          width: 256.0,
          child: Text(
            AppLocalizations.of(context).aboutDescription,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        )
      ],
    );
  }

  Widget _buildClearPreferencesDropdown(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onError,
        backgroundColor: Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        fixedSize: const Size(152.0, 48.0),
      ),
      icon: const Icon(Icons.delete),
      onPressed: () => _showClearPreferencesWindow(context),
      label: Text(AppLocalizations.of(context).clearDataTitle),
    );
  }

  Future<void> _showClearPreferencesWindow(BuildContext context) async {
    final bool? didClearData = await showDialog(
      context: context,
      builder: _buildClearPreferencesDialog,
    );

    if (didClearData ?? false) {
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Widget _buildClearPreferencesDialog(BuildContext context) {
    final TagManager tagManager = context.watch<TagManager>();
    final ChartDashboardManager dashboardManager =
        context.read<ChartDashboardManager>();
    return AlertDialog(
      title: Text(AppLocalizations.of(context).clearDataTitle),
      content: Text(AppLocalizations.of(context).clearDataPrompt),
      actions: <Widget>[
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(AppLocalizations.of(context).promptNegative),
        ),
        TextButton(
          onPressed: () {
            clearPreferences(context);
            tagManager.clear();
            dashboardManager.clear();
            showSnackBar(context, AppLocalizations.of(context).clearDataDone);
            Navigator.of(context).pop(true);
          },
          child: Text(AppLocalizations.of(context).promptAffirmative),
        ),
      ],
    );
  }
}
