import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_pill.dart';

/// Single source of truth for the learner's TARGET language options — the
/// language being *studied*. The UI locale itself is locked to English; this is
/// a separate dimension. Only Chinese is active today; the rest render as
/// coming-soon placeholders. Used by both the Profile and Settings screens so
/// the two pickers can never drift apart.
const Map<String, String> kActiveTargetLanguages = {'zh': 'Chinese (中文)'};

const Map<String, String> kComingSoonTargetLanguages = {
  'ms': 'Malay (Bahasa Melayu)',
  'es': 'Spanish (Español)',
  'fr': 'French (Français)',
  'ja': 'Japanese (日本語)',
};

/// The display label for the currently selected target language.
String targetLanguageLabel(String code) =>
    kActiveTargetLanguages[code] ?? kActiveTargetLanguages['zh']!;

/// Opens the target-language chooser: active languages are selectable; the rest
/// render disabled with a "Coming Soon" pill.
void showTargetLanguageSheet(
  BuildContext context, {
  required String targetLanguage,
  required ValueChanged<String> onChanged,
}) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in kActiveTargetLanguages.entries)
            ListTile(
              leading: Icon(
                entry.key == targetLanguage
                    ? AppIcons.radioButtonChecked
                    : AppIcons.radioButtonUnchecked,
                color: Theme.of(ctx).colorScheme.primary,
              ),
              title: Text(entry.value),
              selected: entry.key == targetLanguage,
              onTap: () {
                Navigator.pop(ctx);
                onChanged(entry.key);
              },
            ),
          for (final entry in kComingSoonTargetLanguages.entries)
            Opacity(
              opacity: 0.6,
              child: ListTile(
                enabled: false,
                leading: const Icon(AppIcons.radioButtonUnchecked),
                title: Text(entry.value),
                trailing: const AppPill(
                  label: 'Coming Soon',
                  variant: PillVariant.neutral,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
