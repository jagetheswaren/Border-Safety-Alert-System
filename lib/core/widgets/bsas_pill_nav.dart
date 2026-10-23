import 'package:flutter/material.dart';
import '../theme/app_motion.dart';
import '../theme/bsas_colors.dart';

/// Flutter-native adaptation of the React Bits PillNav.
///
/// Segmented pill navigation that slides a glowing accent pill
/// behind the currently active category.
class BSASPillNav extends StatelessWidget {
  const BSASPillNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 40.0,
    this.activeColor = BsasColors.primaryBlue,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: BsasColors.darkSurface,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: BsasColors.darkBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth) / items.length;
          final isReduced = AppMotion.isReducedMotion(context);

          return Stack(
            children: [
              // Sliding active pill
              AnimatedPositioned(
                duration: isReduced ? Duration.zero : AppMotion.normal,
                curve: AppMotion.easeOut,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Segment labels
              Row(
                children: List.generate(items.length, (index) {
                  final isSelected = index == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(index),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: AppMotion.fast,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : BsasColors.textLightSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12.5,
                            letterSpacing: 0.3,
                          ),
                          child: Text(
                            items[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
