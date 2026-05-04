import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flick/core/constants/app_constants.dart';
import 'package:flick/features/settings/screens/equalizer_screen.dart';
import 'package:flick/features/settings/screens/uac2_settings_screen.dart';
import 'package:flick/features/settings/widgets/settings_widgets.dart';

class AudioSettingsScreen extends StatelessWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Audio',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader('Audio'),
          SettingsCard(
            children: [
              NavigationSetting(
                icon: LucideIcons.usb,
                title: 'USB Audio (UAC2)',
                subtitle: 'Configure USB DAC/AMP devices',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Uac2SettingsScreen(),
                    ),
                  );
                },
              ),
              const SettingsDivider(),
              NavigationSetting(
                icon: LucideIcons.slidersHorizontal,
                title: 'Equalizer',
                subtitle: 'Adjust audio frequencies',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EqualizerScreen(),
                    ),
                  );
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
