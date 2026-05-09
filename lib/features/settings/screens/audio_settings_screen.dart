import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flick/core/constants/app_constants.dart';
import 'package:flick/core/theme/app_colors.dart';
import 'package:flick/core/theme/adaptive_color_provider.dart';
import 'package:flick/core/utils/app_haptics.dart';
import 'package:flick/features/settings/screens/equalizer_screen.dart';
import 'package:flick/features/settings/screens/uac2_settings_screen.dart';
import 'package:flick/features/settings/widgets/settings_widgets.dart';
import 'package:flick/providers/app_preferences_provider.dart';
import 'package:flick/services/rust_audio_service.dart';
import 'package:flick/src/rust/api/audio_api.dart' as rust_audio;

class AudioSettingsScreen extends ConsumerStatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  ConsumerState<AudioSettingsScreen> createState() =>
      _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends ConsumerState<AudioSettingsScreen> {
  final _rustAudioService = RustAudioService();

  static const _curveLabels = <String>[
    'Equal Power',
    'Linear',
    'Square Root',
    'S-Curve',
  ];

  static const _curveValues = <rust_audio.CrossfadeCurveType>[
    rust_audio.CrossfadeCurveType.equalPower,
    rust_audio.CrossfadeCurveType.linear,
    rust_audio.CrossfadeCurveType.squareRoot,
    rust_audio.CrossfadeCurveType.sCurve,
  ];

  Future<void> _applyCrossfade() async {
    final prefs = ref.read(appPreferencesProvider);
    await _rustAudioService.setCrossfade(
      enabled: prefs.crossfadeEnabled,
      durationSecs: prefs.crossfadeDurationSecs,
    );
    final curve = _curveValues[prefs.crossfadeCurveIndex.clamp(
      0,
      _curveValues.length - 1,
    )];
    await _rustAudioService.setCrossfadeCurve(curve);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(appPreferencesProvider);

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
          const SettingsSectionHeader('Crossfade'),
          SettingsCard(
            children: [
              ToggleSetting(
                icon: LucideIcons.blend,
                title: 'Crossfade',
                subtitle: 'Smoothly blend between tracks',
                value: prefs.crossfadeEnabled,
                onChanged: (value) async {
                  await ref
                      .read(appPreferencesProvider.notifier)
                      .setCrossfadeEnabled(value);
                  await _applyCrossfade();
                },
              ),
              if (prefs.crossfadeEnabled) ...[
                const SettingsDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingLg,
                    vertical: AppConstants.spacingSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duration',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: context.adaptiveTextPrimary,
                                ),
                          ),
                          Text(
                            '${prefs.crossfadeDurationSecs.toStringAsFixed(1)} s',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: context.adaptiveTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      Slider(
                        value: prefs.crossfadeDurationSecs,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        activeColor: context.adaptiveTextPrimary,
                        inactiveColor: AppColors.glassBorder,
                        onChanged: (value) async {
                          await ref
                              .read(appPreferencesProvider.notifier)
                              .setCrossfadeDurationSecs(value);
                        },
                        onChangeEnd: (_) => _applyCrossfade(),
                      ),
                    ],
                  ),
                ),
                const SettingsDivider(),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppConstants.spacingLg,
                    right: AppConstants.spacingLg,
                    top: AppConstants.spacingSm,
                    bottom: AppConstants.spacingMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curve',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: context.adaptiveTextPrimary),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      Wrap(
                        spacing: AppConstants.spacingSm,
                        children: List.generate(_curveLabels.length, (index) {
                          final selected =
                              prefs.crossfadeCurveIndex == index;
                          return ChoiceChip(
                            label: Text(_curveLabels[index]),
                            selected: selected,
                            onSelected: (_) async {
                              AppHaptics.tap();
                              await ref
                                  .read(appPreferencesProvider.notifier)
                                  .setCrossfadeCurveIndex(index);
                              await _applyCrossfade();
                            },
                            backgroundColor: AppColors.glassBackgroundStrong,
                            selectedColor:
                                context.adaptiveTextPrimary.withValues(
                              alpha: 0.15,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? context.adaptiveTextPrimary
                                  : AppColors.glassBorder,
                              width: 1,
                            ),
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: selected
                                      ? context.adaptiveTextPrimary
                                      : context.adaptiveTextSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          const SizedBox(height: AppConstants.navBarHeight + 40),
        ],
      ),
    );
  }
}
