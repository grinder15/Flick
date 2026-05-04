import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flick/core/constants/app_constants.dart';
import 'package:flick/core/utils/app_haptics.dart';
import 'package:flick/providers/providers.dart';
import 'package:flick/features/settings/widgets/settings_widgets.dart';

class InterfaceSettingsScreen extends ConsumerWidget {
  const InterfaceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appPreferences = ref.watch(appPreferencesProvider);

    return SettingsScaffold(
      title: 'Interface',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader('Interface'),
          SettingsCard(
            children: [
              ToggleSetting(
                icon: LucideIcons.activity,
                title: 'Animations',
                subtitle: 'Enable animated transitions and effects',
                value: appPreferences.animationsEnabled,
                onChanged: (value) {
                  ref
                      .read(appPreferencesProvider.notifier)
                      .setAnimationsEnabled(value);
                  AppConstants.setAnimationsEnabled(value);
                },
              ),
              const SettingsDivider(),
              ToggleSetting(
                icon: LucideIcons.vibrate,
                title: 'Haptic Feedback',
                subtitle: 'Enable vibration on interactions',
                value: appPreferences.hapticsEnabled,
                onChanged: (value) {
                  ref
                      .read(appPreferencesProvider.notifier)
                      .setHapticsEnabled(value);
                  AppHaptics.setEnabled(value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          const SizedBox(height: AppConstants.navBarHeight + 40),
        ],
      ),
    );
  }
}
