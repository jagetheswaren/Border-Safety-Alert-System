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
      subtitle: 'DETERMINISTIC GNSS GEOFENCING',
      description:
          'BSAS continuously evaluates your physical coordinates against authorized border security polygons using point-in-polygon math. No fixed or simulated coordinates.',
    ),
    OnboardingSlide(
      icon: Icons.cloud_off_outlined,
      title: '100% Offline-First Architecture',
      subtitle: 'ZERO CLOUD DEPENDENCY',
      description:
          'Boundary evaluation, on-device LSTM & Random Forest machine learning, offline vector/satellite maps, and SQLite persistence operate reliably with zero network connectivity.',
    ),
    OnboardingSlide(
      icon: Icons.shield_outlined,
      title: 'Multi-Modal Emergency Alerts',
      subtitle: 'AUDIO, HAPTICS, TTS & LOCAL AI',
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
      backgroundColor: BsasColors.background(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(
              'SKIP', 
              style: BsasTypography.monospace.copyWith(
                fontWeight: FontWeight.w700,
                color: BsasColors.textSec(isDark),
              ),
            ),
          ),
          const SizedBox(width: BsasSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: BsasSpacing.md),
            const BsasLogo(size: 72, animated: true),
            const SizedBox(height: BsasSpacing.md),
            Text(
              'BORDER SAFETY ALERT SYSTEM',
              style: BsasTypography.monospace.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                fontSize: 11,
                color: BsasColors.text(isDark),
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
                    padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(BsasSpacing.xxl),
                          decoration: BoxDecoration(
                            color: (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue).withValues(alpha: 0.3)),
                          ),
                          child: Icon(slide.icon, size: 56, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue),
                        ),
                        const SizedBox(height: BsasSpacing.xxl),
                        Text(
                          slide.title,
                          style: BsasTypography.heading.copyWith(
                            fontSize: 22,
                            color: BsasColors.text(isDark),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: BsasSpacing.md),
                        Text(
                          slide.subtitle,
                          style: BsasTypography.monospace.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: BsasSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(BsasSpacing.lg),
                          decoration: BoxDecoration(
                            color: BsasColors.card(isDark),
                            borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                            border: Border.all(color: BsasColors.border(isDark)),
                          ),
                          child: Text(
                            slide.description,
                            style: BsasTypography.body.copyWith(
                              color: BsasColors.textSec(isDark),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
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
                        ? (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue)
                        : BsasColors.border(isDark),
                    borderRadius: BorderRadius.circular(BsasSpacing.pillRadius),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BsasSpacing.xxl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.xxl),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: BsasSpacing.lg),
                    backgroundColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                    ),
                  ),
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
                    style: BsasTypography.monospace.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: BsasSpacing.xxxl),
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
