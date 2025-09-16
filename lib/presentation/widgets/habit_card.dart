import 'package:flutter/material.dart';
import 'package:vive_good_app/domain/entities/habit.dart';
import 'package:vive_good_app/domain/entities/user_habit.dart';

class HabitCard extends StatelessWidget {
  final UserHabit habit;
  final IconData iconData;
  final Color iconColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitCard({
    Key? key,
    required this.habit,
    required this.iconData,
    required this.iconColor,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(iconData, color: iconColor, size: 40.0),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.habit?.name ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    habit.habit?.description ?? 'No Description',
                    style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
