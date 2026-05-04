import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flick/core/constants/app_constants.dart';
import 'package:flick/models/song_view_mode.dart';
import 'package:flick/providers/providers.dart';
import 'package:flick/features/settings/widgets/settings_widgets.dart';

class PlaybackDisplaySettingsScreen extends ConsumerWidget {
  const PlaybackDisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsViewMode = ref.watch(songsViewModeProvider);
    final navBarAlwaysVisible = ref.watch(navBarAlwaysVisibleProvider);
    final ambientBackgroundEnabled = ref.watch(
      ambientBackgroundEnabledProvider,
    );

    return SettingsScaffold(
      title: 'Playback & Display',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader('Playback'),
          SettingsCard(
            children: [
              // Gapless playback is currently local state only.
              _GaplessPlaybackTile(),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          const SettingsSectionHeader('Display'),
          SettingsCard(
            children: [
              SelectionSetting(
                icon: LucideIcons.disc,
                title: 'Song View: Orbital',
                subtitle: 'Use the orbital songs browser',
                selected: songsViewMode == SongViewMode.orbit,
                onTap: () {
                  ref
                      .read(songsViewModeProvider.notifier)
                      .setMode(SongViewMode.orbit);
                },
              ),
              const SettingsDivider(),
              SelectionSetting(
                icon: LucideIcons.list,
                title: 'Song View: List',
                subtitle: 'Use the list songs browser',
                selected: songsViewMode == SongViewMode.list,
                onTap: () {
                  ref
                      .read(songsViewModeProvider.notifier)
                      .setMode(SongViewMode.list);
                },
              ),
              const SettingsDivider(),
              ToggleSetting(
                icon: LucideIcons.panelBottom,
                title: 'Bottom Bar Always Visible',
                subtitle: 'Keep mini player and nav visible',
                value: navBarAlwaysVisible,
                onChanged: (value) {
                  ref
                      .read(navBarAlwaysVisibleProvider.notifier)
                      .setAlwaysVisible(value);
                },
              ),
              const SettingsDivider(),
              ToggleSetting(
                icon: LucideIcons.sparkles,
                title: 'Ambient Background',
                subtitle: 'Use album art as the blurred app background',
                value: ambientBackgroundEnabled,
                onChanged: (value) {
                  ref
                      .read(ambientBackgroundEnabledProvider.notifier)
                      .setEnabled(value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          // Bottom padding for nav bar
          const SizedBox(height: AppConstants.navBarHeight + 40),
        ],
      ),
    );
  }
}

class _GaplessPlaybackTile extends StatefulWidget {
  @override
  State<_GaplessPlaybackTile> createState() => _GaplessPlaybackTileState();
}

class _GaplessPlaybackTileState extends State<_GaplessPlaybackTile> {
  bool _gaplessPlayback = true;

  @override
  Widget build(BuildContext context) {
    return ToggleSetting(
      icon: LucideIcons.repeat,
      title: 'Gapless Playback',
      subtitle: 'Seamless transition between tracks',
      value: _gaplessPlayback,
      onChanged: (value) => setState(() => _gaplessPlayback = value),
    );
  }
}
