import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum NavBarButton {
  menu(0, 'Menu', LucideIcons.layoutGrid),
  songs(1, 'Songs', LucideIcons.music),
  settings(2, 'Settings', LucideIcons.settings),
  albums(3, 'Albums', LucideIcons.disc),
  artists(4, 'Artists', LucideIcons.users),
  folders(5, 'Folders', LucideIcons.folder),
  playlists(6, 'Playlists', LucideIcons.listMusic),
  favorites(7, 'Favorites', LucideIcons.heart),
  search(8, 'Search', LucideIcons.search);

  const NavBarButton(this.pageIndex, this.label, this.icon);

  final int pageIndex;
  final String label;
  final IconData icon;
}

class NavBarConfig {
  final Set<NavBarButton> enabledButtons;
  final double barSizeFactor;
  final double buttonSpacingFactor;
  final double iconSizeFactor;
  final bool showLabels;

  static const allButtons = {
    NavBarButton.menu,
    NavBarButton.songs,
    NavBarButton.settings,
  };

  const NavBarConfig({
    this.enabledButtons = allButtons,
    this.barSizeFactor = 1.0,
    this.buttonSpacingFactor = 1.0,
    this.iconSizeFactor = 1.0,
    this.showLabels = true,
  });

  static const defaultConfig = NavBarConfig();

  /// Ordered list of enabled buttons in their natural [pageIndex] order.
  List<NavBarButton> get orderedButtons {
    final sorted = enabledButtons.toList()..sort((a, b) => a.pageIndex.compareTo(b.pageIndex));
    return sorted;
  }

  bool get hasAllEssential =>
      enabledButtons.contains(NavBarButton.menu) &&
      enabledButtons.contains(NavBarButton.songs) &&
      enabledButtons.contains(NavBarButton.settings);

  List<NavBarButton> get missingEssentials {
    const essential = {NavBarButton.menu, NavBarButton.songs, NavBarButton.settings};
    return essential.where((b) => !enabledButtons.contains(b)).toList()
      ..sort((a, b) => a.pageIndex.compareTo(b.pageIndex));
  }

  NavBarConfig copyWith({
    Set<NavBarButton>? enabledButtons,
    double? barSizeFactor,
    double? buttonSpacingFactor,
    double? iconSizeFactor,
    bool? showLabels,
  }) {
    return NavBarConfig(
      enabledButtons: enabledButtons ?? this.enabledButtons,
      barSizeFactor: barSizeFactor ?? this.barSizeFactor,
      buttonSpacingFactor: buttonSpacingFactor ?? this.buttonSpacingFactor,
      iconSizeFactor: iconSizeFactor ?? this.iconSizeFactor,
      showLabels: showLabels ?? this.showLabels,
    );
  }
}
