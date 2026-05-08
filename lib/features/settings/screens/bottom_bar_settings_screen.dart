import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flick/core/theme/app_colors.dart';
import 'package:flick/core/constants/app_constants.dart';
import 'package:flick/models/nav_bar_config.dart';
import 'package:flick/providers/providers.dart';
import 'package:flick/features/settings/widgets/settings_widgets.dart';
import 'package:flick/widgets/navigation/flick_nav_bar.dart';

class BottomBarSettingsScreen extends ConsumerWidget {
  const BottomBarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(navBarConfigProvider);
    final enabled = config.enabledButtons;
    final enabledCount = enabled.length;

    return SettingsScaffold(
      title: 'Bottom Bar',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader('Buttons'),
          SettingsCard(
            children: NavBarButton.values.map((button) {
              final isLast = enabledCount == 1 && enabled.contains(button);
              return Column(
                children: [
                  if (button != NavBarButton.values.first)
                    const SettingsDivider(),
                  ToggleSetting(
                    icon: button.icon,
                    title: button.label,
                    subtitle: 'Show the ${button.label} tab in the bottom bar',
                    value: enabled.contains(button),
                    onChanged: isLast
                        ? (_) {}
                        : (_) {
                            ref
                                .read(navBarConfigProvider.notifier)
                                .toggleButton(button);
                          },
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          const SettingsSectionHeader('Appearance'),
          SettingsCard(
            children: [
              SliderSetting(
                icon: LucideIcons.ruler,
                title: 'Bar Height',
                subtitle: 'Adjust the size of the bottom bar',
                value: config.barSizeFactor,
                displayValue: '${config.barSizeFactor.toStringAsFixed(1)}x',
                min: 0.6,
                max: 1.4,
                divisions: 8,
                onChanged: (value) {
                  ref
                      .read(navBarConfigProvider.notifier)
                      .setBarSizeFactor(value);
                },
              ),
              const SettingsDivider(),
              SliderSetting(
                icon: LucideIcons.space,
                title: 'Button Spacing',
                subtitle: 'Adjust spacing between buttons',
                value: config.buttonSpacingFactor,
                displayValue: '${config.buttonSpacingFactor.toStringAsFixed(1)}x',
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) {
                  ref
                      .read(navBarConfigProvider.notifier)
                      .setButtonSpacingFactor(value);
                },
              ),
              const SettingsDivider(),
              SliderSetting(
                icon: LucideIcons.maximize,
                title: 'Icon Size',
                subtitle: 'Adjust the size of the icons',
                value: config.iconSizeFactor,
                displayValue: '${config.iconSizeFactor.toStringAsFixed(1)}x',
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) {
                  ref
                      .read(navBarConfigProvider.notifier)
                      .setIconSizeFactor(value);
                },
              ),
              const SettingsDivider(),
              ToggleSetting(
                icon: LucideIcons.type,
                title: 'Show Labels',
                subtitle: 'Display text labels below icons',
                value: config.showLabels,
                onChanged: (value) {
                  ref
                      .read(navBarConfigProvider.notifier)
                      .setShowLabels(value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          const SettingsSectionHeader('Preview'),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            child: Container(
              color: AppColors.surface.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AbsorbPointer(
                child: FlickNavBar(
                  currentIndex: config.orderedButtons.first.pageIndex,
                  config: config,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.navBarHeight + 40),
        ],
      ),
    );
  }

}