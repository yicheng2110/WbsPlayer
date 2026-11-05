import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';

class ServerNavigationPill extends StatelessWidget {
  const ServerNavigationPill({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 88,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.7,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8FD),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: AppColors.navy.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _NavigationItem(
                        icon: Icons.video_library_outlined,
                        label: context.l10n.serversTitle,
                        selected: selectedIndex == 0,
                        onTap: () => onSelected(0),
                      ),
                      _NavigationItem(
                        icon: Icons.all_inclusive_rounded,
                        label: context.l10n.aggregationTab,
                        selected: false,
                        onTap: () => onSelected(1),
                      ),
                      _NavigationItem(
                        icon: Icons.settings_outlined,
                        label: context.l10n.settingsTitle,
                        selected: selectedIndex == 2,
                        onTap: () => onSelected(2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(35),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(35),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 29,
                  color: selected ? AppColors.navy : const Color(0xFF414149),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: selected ? AppColors.navy : const Color(0xFF414149),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
