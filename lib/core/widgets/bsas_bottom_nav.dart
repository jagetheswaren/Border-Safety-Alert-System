import 'package:flutter/material.dart';
import '../theme/app_motion.dart';
import '../theme/bsas_colors.dart';

class BSASNavItem {
  const BSASNavItem({
    required this.icon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final int? badgeCount;
}

/// Flutter-native adaptation of the React Bits Dock / PillNav for mobile navigation.
///
/// Features:
/// - Floating elevated dock with glassmorphism surface
/// - Animated pill indicator sliding behind the active destination
/// - Subtle vertical icon translation on selection
/// - Zero reload across tab switches
class BSASBottomNav extends StatelessWidget {
  const BSASBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<BSASNavItem> destinations;

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);

    return Container(
      key: const Key('bottom-nav'),
      decoration: BoxDecoration(
        color: BsasColors.darkBackground.withValues(alpha: 0.94),
        border: const Border(
          top: BorderSide(color: BsasColors.darkBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / destinations.length;

              return Stack(
                children: [
                  // Animated sliding pill indicator under the selected tab
                  AnimatedPositioned(
                    duration: isReduced ? Duration.zero : AppMotion.normal,
                    curve: AppMotion.easeOut,
                    left: selectedIndex * tabWidth + (tabWidth * 0.1),
                    top: 6,
                    bottom: 6,
                    width: tabWidth * 0.8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: BsasColors.primaryBlue.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: BsasColors.primaryBlueLight.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Row of interactive tabs
                  Row(
                    children: List.generate(destinations.length, (index) {
                      final item = destinations[index];
                      final isSelected = index == selectedIndex;

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onDestinationSelected(index),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: isReduced ? Duration.zero : AppMotion.fast,
                                transform: Matrix4.translationValues(
                                  0,
                                  isSelected ? -2.0 : 0.0,
                                  0,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: 20,
                                      color: isSelected
                                          ? BsasColors.primaryBlueLight
                                          : BsasColors.textLightMuted,
                                    ),
                                    if (item.badgeCount != null && item.badgeCount! > 0)
                                      Positioned(
                                        right: -6,
                                        top: -4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: BsasColors.criticalRed,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 14,
                                            minHeight: 14,
                                          ),
                                          child: Text(
                                            '${item.badgeCount}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? BsasColors.primaryBlueLight
                                      : BsasColors.textLightMuted,
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
