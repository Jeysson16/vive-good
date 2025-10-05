import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';

class MainHeader extends StatelessWidget {
  final String userName;

  const MainHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $userName!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A47),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '¿Cómo te sientes hoy?',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          // Calendar button only - sync and connectivity work automatically in background
          IconButton(
            onPressed: () {
              context.go(AppRoutes.calendar);
            },
            icon: const Icon(
              Icons.calendar_today,
              color: Color(0xFF4CAF50),
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF0F9FF),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
