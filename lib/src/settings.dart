import 'package:flutter/material.dart';

import 'generated/l10n/app_localizations.dart';
import 'journal.dart';
import 'tag.dart';
import 'utility.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context).settingsTitle),
      ),
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              AppLocalizations.of(context).appTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Stack(
              children: <Widget>[
                Text(
                  // Book
                  String.fromCharCode(0x1F4D6),
                  style: TextStyle(
                    fontSize: 126.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text(
                    // Moon
                    String.fromCharCode(0x1F319),
                    style: TextStyle(
                      fontSize: 126.0,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
              ],
            ),
            DropdownMenu<String>(
              width: 152.0,
              requestFocusOnTap: false,
              initialSelection: Localizations.localeOf(context).languageCode,
              leadingIcon: const Icon(Icons.language),
              dropdownMenuEntries:
                  AppLocalizations.supportedLocales.map((Locale locale) {
                return DropdownMenuEntry<String>(
                  value: locale.languageCode,
                  label: locale.languageCode,
                );
              }).toList(growable: false),
              onSelected: (String? newValue) {
                if (newValue != null) {
                  JournalApp.setLocale(context, Locale(newValue));
                }
              },
            ),
            const SizedBox(height: 8.0),
            TextButton.icon(
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
            ),
            const SizedBox(height: 16.0),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearPreferencesWindow(BuildContext context) async {
    final bool? result = await showDialog(
      context: context,
      builder: _buildClearPreferencesDialog,
    );

    if (result ?? false) {
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Widget _buildClearPreferencesDialog(BuildContext context) {
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
            tagData.clear();
            appliedTags.clear();
            showSnackBar(context, AppLocalizations.of(context).clearDataDone);
            Navigator.of(context).pop(true);
          },
          child: Text(AppLocalizations.of(context).promptAffirmative),
        ),
      ],
    );
  }
}
