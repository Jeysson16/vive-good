import 'package:flutter/material.dart';

class CategoryTabItem {
  final String id;
  final String name;

  const CategoryTabItem({
    required this.id,
    required this.name,
  });
}

class CategoryTabs extends StatefulWidget {
  final List<CategoryTabItem> categories;
  final Function(String?) onCategorySelected;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            widget.categories.length,
            (index) {
              final isSelected = index == _selectedIndex;
              final category = widget.categories[index];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  widget.onCategorySelected(
                    index == 0 ? null : category.id,
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < widget.categories.length - 1 ? 16 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2E3A47)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2E3A47)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}