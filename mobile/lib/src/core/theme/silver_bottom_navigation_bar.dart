import 'package:flutter/material.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';

class SilverBottomNavItem {
  const SilverBottomNavItem({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;
}

class SilverBottomNavigationBar extends StatelessWidget {
  const SilverBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  static const _orange = Color(0xFFFF9412);
  static const _orangeGlow = Color(0xFFFF8D0F);
  static const _barColor = Color(0xFF121F44);

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SilverBottomNavItem> items;

  static const _iconSize = 24.0;
  static const _labelSize = 12.0;
  static const _accentScale = 1.5;

  int? get _accentIndex {
    for (var i = 0; i < items.length; i++) {
      if (items[i].accent) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const accentIconSize = _iconSize * _accentScale;
    const accentLabelSize = _labelSize * _accentScale;
    const accentCircle = 42.0 * _accentScale;
    final accentIndex = _accentIndex;

    return Material(
      color: _barColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 96,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: kBottomNavigationBarHeight,
                child: Row(
                  children: List.generate(items.length, (index) {
                    if (items[index].accent) {
                      return const Expanded(child: SizedBox());
                    }
                    return _sideItem(index);
                  }),
                ),
              ),
              if (accentIndex != null) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: List.generate(items.length, (index) {
                      if (index != accentIndex) {
                        return const Expanded(child: SizedBox());
                      }
                      return Expanded(
                        child: InkWell(
                          onTap: () => onTap(index),
                          child: Column(
                            children: [
                              Container(
                                width: accentCircle,
                                height: accentCircle,
                                decoration: BoxDecoration(
                                  color: _orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF141F46), width: 5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: _orangeGlow,
                                      blurRadius: 16,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  items[accentIndex].icon,
                                  color: Colors.white,
                                  size: accentIconSize,
                                ),
                              ),
                              const SizedBox(height: 4),
                              MetallicSilverText(
                                items[accentIndex].label,
                                style: TextStyle(
                                  fontSize: accentLabelSize,
                                  fontWeight: currentIndex == accentIndex
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideItem(int index) {
    final selected = index == currentIndex;
    final item = items[index];

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: selected ? const Color(0xFFE8ECF0) : const Color(0xFF8A97BF),
              size: _iconSize,
            ),
            const SizedBox(height: 4),
            MetallicSilverText(
              item.label,
              style: TextStyle(
                fontSize: _labelSize,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
