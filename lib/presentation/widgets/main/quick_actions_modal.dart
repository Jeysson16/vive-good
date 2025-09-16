import 'package:flutter/material.dart';

class QuickActionsModal {
  static void show(
    BuildContext context, {
    required Function(String) onActionSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickActionsContent(
        onActionSelected: onActionSelected,
      ),
    );
  }
}

class _QuickActionsContent extends StatelessWidget {
  final Function(String) onActionSelected;

  const _QuickActionsContent({
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.flash_on,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Acciones rápidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF6B7280),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ActionButton(
                  icon: Icons.check_circle,
                  iconColor: const Color(0xFF10B981),
                  title: 'Marcar como hecho',
                  subtitle: 'Marca un hábito como completado',
                  onTap: () {
                    Navigator.of(context).pop();
                    onActionSelected('mark_done');
                  },
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: Icons.lightbulb,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Sugerencia IA',
                  subtitle: 'Obtén consejos personalizados',
                  onTap: () {
                    Navigator.of(context).pop();
                    onActionSelected('ai_suggestion');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9CA3AF),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}