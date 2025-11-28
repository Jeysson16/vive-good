import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AdminSidebarToggleButton extends StatelessWidget {
  final bool isSidebarVisible;
  final VoidCallback onToggle;
  final bool isFloating;

  const AdminSidebarToggleButton({
    super.key,
    required this.isSidebarVisible,
    required this.onToggle,
    this.isFloating = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    final buttonWidget = Material(
      elevation: isFloating ? 8 : 0,
      borderRadius: BorderRadius.circular(16),
      shadowColor: isFloating ? Colors.black.withOpacity(0.3) : Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: AnimatedRotation(
              turns: isSidebarVisible ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isSidebarVisible ? Icons.close : Icons.menu,
                color: AppColors.primary,
                size: isMobile ? 20 : 24,
              ),
            ),
          ),
        ),
      ),
    );

    if (isFloating) {
      return Positioned(
        top: isMobile ? 16 : 24,
        left: isMobile ? 16 : 24,
        child: buttonWidget,
      );
    } else {
      return buttonWidget;
    }
  }
}