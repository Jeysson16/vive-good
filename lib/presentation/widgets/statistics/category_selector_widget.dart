import 'package:flutter/material.dart';
import 'package:vive_good_app/domain/entities/category_evolution.dart';

class CategorySelectorWidget extends StatelessWidget {
  final List<CategoryEvolution> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const CategorySelectorWidget({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1, // +1 para "Todas"
        itemBuilder: (context, index) {
          if (index == 0) {
            // Opción "Todas las categorías"
            return _buildCategoryChip(
              id: null,
              name: 'Todas',
              color: Colors.grey.shade600,
              icon: Icons.apps,
              isSelected: selectedCategoryId == null,
            );
          }
          
          final category = categories[index - 1];
          return _buildCategoryChip(
            id: category.categoryId,
            name: category.categoryName,
            color: Color(int.parse(category.categoryColor.replaceFirst('#', '0xFF'))),
            icon: _getIconFromString(category.categoryIcon),
            isSelected: selectedCategoryId == category.categoryId,
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String? id,
    required String name,
    required Color color,
    required IconData icon,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) {
          onCategorySelected(selected ? id : null);
        },
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        selectedColor: color,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: color,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  IconData _getIconFromString(String iconString) {
    // Mapeo básico de strings a iconos
    switch (iconString.toLowerCase()) {
      case 'fitness_center':
      case 'exercise':
      case 'gym':
        return Icons.fitness_center;
      case 'book':
      case 'read':
      case 'reading':
        return Icons.book;
      case 'water_drop':
      case 'water':
        return Icons.water_drop;
      case 'bedtime':
      case 'sleep':
        return Icons.bedtime;
      case 'restaurant':
      case 'food':
      case 'eat':
        return Icons.restaurant;
      case 'work':
      case 'business':
        return Icons.work;
      case 'school':
      case 'education':
        return Icons.school;
      case 'favorite':
      case 'health':
      case 'heart':
        return Icons.favorite;
      case 'psychology':
      case 'mind':
      case 'mental':
        return Icons.psychology;
      case 'nature':
      case 'eco':
        return Icons.nature;
      case 'music_note':
      case 'music':
        return Icons.music_note;
      case 'palette':
      case 'art':
        return Icons.palette;
      case 'sports':
      case 'sport':
        return Icons.sports;
      case 'family':
      case 'people':
        return Icons.family_restroom;
      case 'savings':
      case 'money':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }
}