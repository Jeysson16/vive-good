import 'package:flutter/material.dart';

class MainBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onMicPressed;

  const MainBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onMicPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: currentIndex == 0 ? Icons.home : Icons.home_outlined,
            label: 'Inicio',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _buildNavItem(
            icon: currentIndex == 1 ? Icons.track_changes : Icons.track_changes_outlined,
            label: 'Hábitos',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          // Micrófono en el centro
          GestureDetector(
            onTap: onMicPressed,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          _buildNavItem(
            icon: currentIndex == 2 ? Icons.bar_chart : Icons.bar_chart_outlined,
            label: 'Progreso',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _buildNavItem(
            icon: currentIndex == 3 ? Icons.person : Icons.person_outline,
            label: 'Perfil',
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF9CA3AF),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}