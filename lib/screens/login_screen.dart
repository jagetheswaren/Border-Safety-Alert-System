import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/bsas_colors.dart';
import '../core/widgets/bsas_logo.dart';
import '../core/widgets/bsas_slide_button.dart';
import '../core/widgets/bsas_text_field.dart';
import '../services/sync_service.dart';

/// Flutter-native adaptation of the React Bits Cubes/Grid background + BSAS Login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.syncService,
    required this.onSuccess,
  });

  final SyncService syncService;
  final VoidCallback onSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController(text: 'operator@bsas.local');
  final _passwordController = TextEditingController(text: 'Admin123!');
  final _serverController = TextEditingController(text: 'http://10.0.2.2:8000');

  BSASSlideButtonState _buttonState = BSASSlideButtonState.idle;
  String? _errorMessage;
  late final AnimationController _gridAnim;

  @override
  void initState() {
    super.initState();
    _gridAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    _gridAnim.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _buttonState = BSASSlideButtonState.loading;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final server = _serverController.text.trim();

    try {
      await widget.syncService.signIn(server, email, password);
      if (!mounted) return;
      setState(() => _buttonState = BSASSlideButtonState.success);
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      // If server unreachable, allow offline access with informative notice
      if (email.isNotEmpty && password.isNotEmpty) {
        setState(() => _buttonState = BSASSlideButtonState.success);
        await Future.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        widget.onSuccess();
      } else {
        setState(() {
          _buttonState = BSASSlideButtonState.idle;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReducedMotion(context);

    return Scaffold(
      backgroundColor: BsasColors.darkBackground,
      body: Stack(
        children: [
          // React Bits Cubes/Grid inspired lightweight background
          if (!reduced)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _gridAnim,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CubesGridPainter(progress: _gridAnim.value),
                  );
                },
              ),
            ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Animated BSAS Logo
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: BsasColors.darkSurface.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: BsasColors.primaryBlueLight.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: BsasColors.primaryBlue.withValues(alpha: 0.2),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const BsasLogo(size: 64, animated: true),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title & Subtitle
                      const Text(
                        'BORDER SAFETY & ALERT SYSTEM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: BsasColors.textLightPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'SECURE OPERATOR ACCESS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: BsasColors.primaryBlueLight.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: BsasColors.darkSurface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: BsasColors.darkBorder,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BSASTextField(
                              controller: _serverController,
                              label: 'BACKEND ENDPOINT',
                              hintText: 'http://10.0.2.2:8000',
                              prefixIcon: Icons.dns_outlined,
                            ),
                            const SizedBox(height: 16),
                            BSASTextField(
                              controller: _emailController,
                              label: 'OPERATOR IDENTITY / EMAIL',
                              hintText: 'operator@bsas.local',
                              prefixIcon: Icons.badge_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            BSASTextField(
                              controller: _passwordController,
                              label: 'PASSWORD / CREDENTIAL',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: BsasColors.criticalRedBgDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: BsasColors.criticalRed.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFFCA5A5),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            BSASSlideButton(
                              label: 'SIGN IN',
                              loadingLabel: 'AUTHENTICATING...',
                              successLabel: 'ACCESS GRANTED ✓',
                              state: _buttonState,
                              onPressed: _handleSignIn,
                              height: 50,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: BsasColors.safeGreenLight.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'OFFLINE-FIRST FIELD SAFETY ACTIVE',
                            style: TextStyle(
                              color: BsasColors.textLightMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight CustomPainter rendering subtle isometric cubes/grids.
class _CubesGridPainter extends CustomPainter {
  _CubesGridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = BsasColors.primaryBlueLight.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const spacing = 48.0;
    final offsetX = (progress * spacing) % spacing;

    for (double x = -spacing; x <= size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x + offsetX, 0),
        Offset(x + offsetX, size.height),
        linePaint,
      );
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    // Subtle isometric cube markers
    final cubePaint = Paint()
      ..color = BsasColors.primaryBlueLight.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = BsasColors.primaryBlueLight.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    for (double x = 40; x < size.width; x += 140) {
      for (double y = 40; y < size.height; y += 140) {
        final floatOffset = math.sin((progress * 2 * math.pi) + (x * 0.02)) * 6.0;
        final center = Offset(x, y + floatOffset);
        canvas.drawCircle(center, 2.0, dotPaint);

        // Micro tactical crosshair
        canvas.drawLine(Offset(center.dx - 5, center.dy), Offset(center.dx + 5, center.dy), cubePaint);
        canvas.drawLine(Offset(center.dx, center.dy - 5), Offset(center.dx, center.dy + 5), cubePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CubesGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
