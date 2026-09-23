import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/bsas_colors.dart';
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
      icon: Icons.radar,
      title: 'Real-Time Perimeter Safety',
      subtitle: 'Deterministic GNSS Geofencing',
      description:
          'BSAS continuously evaluates your physical coordinates against authorized border security polygons using point-in-polygon math. No fixed or simulated coordinates.',
    ),
    OnboardingSlide(
      icon: Icons.offline_bolt_outlined,
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
          'When boundary escalation occurs, BSAS triggers acoustic sirens, calibrated vibration pulses, native Android TTS, and read-only local Qwen3 advisory guidance.',
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
    return Scaffold(
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('SKIP', style: TextStyle(color: BsasColors.radarCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const BsasLogo(size: 80, animated: true),
            const SizedBox(height: 12),
            const Text(
              'BORDER SAFETY ALERT SYSTEM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  final slide = _slides[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BsasColors.darkSurface,
                            border: Border.all(color: BsasColors.radarCyan, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: BsasColors.radarCyan.withValues(alpha: 0.25),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(slide.icon, size: 44, color: BsasColors.radarCyan),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          style: BsasTypography.headline.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slide.subtitle,
                          style: BsasTypography.caption.copyWith(
                            color: BsasColors.safeGreen,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          style: BsasTypography.body.copyWith(
                            color: Colors.white70,
                            fontSize: 15,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i ? BsasColors.radarCyan : Colors.white24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BsasColors.safeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    _currentPage == _slides.length - 1 ? 'GET STARTED' : 'CONTINUE',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
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
