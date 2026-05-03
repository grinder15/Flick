import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flick/core/theme/app_colors.dart';
import 'package:flick/core/constants/app_constants.dart';
import 'package:flick/core/utils/responsive.dart';
import 'package:flick/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 5;
  static const List<_StepData> _steps = [
    _StepData(
      icon: LucideIcons.zap,
      title: 'Welcome to\nFlick Player',
      description:
          'A beautiful, fast music player\nbuilt for your local library.\nNo ads. No tracking. Just music.',
    ),
    _StepData(
      icon: LucideIcons.folderOpen,
      title: 'Build Your\nLibrary',
      description:
          'Head to Settings and tap\nMusic Folders to scan your\ndevice. Supports MP3, FLAC,\nAAC, WAV, and more.',
    ),
    _StepData(
      icon: LucideIcons.layoutGrid,
      title: 'Browse\nYour Music',
      description:
          'Swipe between tabs to explore\nSongs, Artists, Albums, and\nPlaylists. Sort and search\nyour entire collection.',
    ),
    _StepData(
      icon: LucideIcons.music,
      title: 'Rich\nPlayback',
      description:
          'Tap any song for the full player\nwith waveform seek bar,\nequalizer, lyrics, and ambient\nalbum art visuals.',
    ),
    _StepData(
      icon: LucideIcons.headphones,
      title: "You're\nAll Set",
      description:
          'Start exploring your music.\nSit back, relax, and enjoy\nthe sound of Flick Player.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: AppConstants.animationNormal,
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _skip() {
    _complete();
  }

  void _complete() {
    ref.read(onboardingCompletedProvider.notifier).complete();
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _OnboardingBackdrop()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: _steps.map((step) {
                      return AnimatedSwitcher(
                        duration: AppConstants.animationNormal,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _StepContent(
                          key: ValueKey(step.title),
                          data: step,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPage < _totalPages - 1)
            TextButton(
              onPressed: _skip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingXs,
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: AppConstants.fontSizeMd,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isLastPage = _currentPage == _totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingXl,
        AppConstants.spacingMd,
        AppConstants.spacingXl,
        AppConstants.spacingXl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDots(),
          _buildActionButton(isLastPage: isLastPage),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_totalPages, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: AppConstants.animationFast,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFEDF6FF), Color(0xFF8AB7FF)],
                  )
                : null,
            color: isActive ? null : AppColors.inactiveState,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF8AB7FF).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildActionButton({required bool isLastPage}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F7FF), Color(0xFF9CC4FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8AB7FF).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _goToNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF0A111A),
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg + 4,
            vertical: AppConstants.spacingSm + 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLastPage ? 'Get Started' : 'Next',
              style: const TextStyle(
                fontFamily: 'ProductSans',
                fontSize: AppConstants.fontSizeMd,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (!isLastPage) ...[
              const SizedBox(width: 6),
              const Icon(LucideIcons.chevronRight, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF040608), Color(0xFF0A0A0A)],
              ),
            ),
          ),
          Positioned(
            top: -140,
            left: -60,
            child: _GlowOrb(
              size: 340,
              colors: const [Color(0xFF1B3258), Color(0x001B3258)],
            ),
          ),
          Positioned(
            top: context.screenHeight * 0.32,
            right: -100,
            child: _GlowOrb(
              size: 300,
              colors: const [Color(0xFF4A2A1F), Color(0x004A2A1F)],
            ),
          ),
          Positioned(
            bottom: -80,
            left: 20,
            child: _GlowOrb(
              size: 240,
              colors: const [Color(0xFF1A2D44), Color(0x001A2D44)],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  final _StepData data;

  const _StepContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x26FFFFFF), Color(0x08FFFFFF)],
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusXl),
              border: Border.all(
                color: const Color(0x33FFFFFF),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8AB7FF).withValues(alpha: 0.08),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(data.icon, size: 48, color: AppColors.accent),
          ),
          const Spacer(flex: 1),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 0.92,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'ProductSans',
              fontSize: AppConstants.fontSizeMd,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String description;

  const _StepData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

