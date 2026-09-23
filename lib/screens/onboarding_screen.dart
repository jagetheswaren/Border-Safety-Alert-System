import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  static const String prefKeyCompleted = 'bsas_onboarding_completed';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      icon: Icons.radar_outlined,
      title: 'Real-Time Perimeter Safety',
      subtitle: 'Deterministic GNSS Geofencing',
      description:
          'BSAS continuously evaluates your physical coordinates against authorized border security polygons using point-in-polygon math. No fixed or simulated coordinates.',
    ),
    OnboardingSlide(
      icon: Icons.cloud_off_outlined,
      title: '100% Offline-First Architecture',
      subtitle: 'Zero Cloud Dependency in the Field',
      description:
          'Boundary evaluation, on-device LSTM & Random Forest machine learning, offline vector/satellite maps, and SQLite persistence operate reliably with zero network connectivity.',
    ),
    OnboardingSlide(
      icon: Icons.shield_outlined,
      title: 'Multi-Modal Emergency Alerts',
      subtitle: 'Audio, Haptics, TTS & Local AI',
      description:
          'When boundary escalation occurs, BSAS triggers acoustic sirens, calibrated vibration pulses, native Android TTS voice alerts, and read-only local AI guidance.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.prefKeyCompleted, true);
    if (mounted) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? BsasColors.darkBackground : BsasColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('SKIP', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: BsasSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: BsasSpacing.md),
            const BsasLogo(size: 72, animated: true),
            const SizedBox(height: BsasSpacing.sm),
            Text(
              'BORDER SAFETY ALERT SYSTEM',
              style: BsasTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
              ),
            ),
            const SizedBox(height: BsasSpacing.lg),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  final slide = _slides[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.xxxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(BsasSpacing.xl),
                          decoration: BoxDecoration(
                            color: BsasColors.primaryBlue.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 48, color: BsasColors.primaryBlue),
                        ),
                        const SizedBox(height: BsasSpacing.xl),
                        Text(
                          slide.title,
                          style: BsasTypography.display.copyWith(
                            fontSize: 20,
                            color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: BsasSpacing.xs),
                        Text(
                          slide.subtitle,
                          style: BsasTypography.sectionHeading.copyWith(
                            fontSize: 12,
                            color: BsasColors.primaryBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: BsasSpacing.md),
                        Text(
                          slide.description,
                          style: BsasTypography.body.copyWith(
                            color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page Indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (idx) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: BsasSpacing.xs),
                  width: _currentPage == idx ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == idx
                        ? BsasColors.primaryBlue
                        : (isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
                    borderRadius: BorderRadius.circular(BsasSpacing.pillRadius),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BsasSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.xxxl),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  child: Text(
                    _currentPage < _slides.length - 1 ? 'CONTINUE' : 'START MONITORING',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BsasSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide {
  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
}
