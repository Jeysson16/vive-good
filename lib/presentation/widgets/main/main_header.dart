import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';

class MainHeader extends StatelessWidget {
  final String userName;

  const MainHeader({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Calendar button
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
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
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4CAF50),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}