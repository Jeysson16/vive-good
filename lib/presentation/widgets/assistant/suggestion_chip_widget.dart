import 'package:flutter/material.dart';

class SuggestionChipWidget extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const SuggestionChipWidget({
    super.key,
    required this.text,
    required this.onTap,
    this.isSelected = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = isSelected
        ? Colors.white.withOpacity(0.9)
        : Colors.white.withOpacity(0.15);
    final defaultTextColor = isSelected
        ? const Color(0xFF1B5E20)
        : const Color(0xFF1B5E20);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF1B5E20).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: textColor ?? defaultTextColor,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor ?? defaultTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 1,
                        offset: const Offset(0, 0.5),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated suggestion chip with hover effects
class AnimatedSuggestionChip extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final Duration animationDuration;

  const AnimatedSuggestionChip({
    super.key,
    required this.text,
    required this.onTap,
    this.isSelected = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedSuggestionChip> createState() => _AnimatedSuggestionChipState();
}

class _AnimatedSuggestionChipState extends State<AnimatedSuggestionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = widget.isSelected
        ? theme.primaryColor
        : (_isHovered ? Colors.grey[200] : Colors.grey[100]);
    final defaultTextColor = widget.isSelected
        ? Colors.white
        : Colors.black87;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            elevation: _elevationAnimation.value,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: widget.onTap,
              onHover: _onHoverChanged,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: widget.animationDuration,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? defaultBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isSelected
                        ? theme.primaryColor
                        : (_isHovered ? Colors.grey[400]! : Colors.grey[300]!),
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 16,
                        color: widget.textColor ?? defaultTextColor,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.textColor ?? defaultTextColor,
                          fontSize: 14,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Suggestion chip with category grouping
class CategorizedSuggestionChips extends StatelessWidget {
  final Map<String, List<String>> suggestions;
  final Function(String) onSuggestionTap;
  final String? selectedCategory;
  final String? selectedSuggestion;

  const CategorizedSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    this.selectedCategory,
    this.selectedSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions.entries.map((entry) {
        final category = entry.key;
        final items = entry.value;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final suggestion = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SuggestionChipWidget(
                      text: suggestion,
                      isSelected: selectedSuggestion == suggestion,
                      onTap: () => onSuggestionTap(suggestion),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}