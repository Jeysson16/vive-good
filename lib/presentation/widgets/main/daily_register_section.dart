import 'package:flutter/material.dart';

class DailyRegisterSection extends StatefulWidget {
  final String date;
  final int pendingCount;

  const DailyRegisterSection({
    super.key,
    required this.date,
    required this.pendingCount,
  });

  @override
  State<DailyRegisterSection> createState() => _DailyRegisterSectionState();
}

class _DailyRegisterSectionState extends State<DailyRegisterSection>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  int? _previousCount;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: const Color(0xFF3B82F6),
      end: const Color(0xFF10B981),
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
    
    _previousCount = widget.pendingCount;
  }

  @override
  void didUpdateWidget(DailyRegisterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.pendingCount != widget.pendingCount) {
      _animateCountChange();
      _previousCount = widget.pendingCount;
    }
  }
  
  void _animateCountChange() async {
    // Scale animation
    await _scaleController.forward();
    await _scaleController.reverse();
    
    // Color animation for emphasis
    await _colorController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _colorController.reverse();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: 8,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.date,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registro diario',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E3A47),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_scaleAnimation, _colorAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey<int>(widget.pendingCount),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (_colorController.value > 0)
                              ? _colorAnimation.value?.withOpacity(0.1)
                              : const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: (_colorController.value > 0)
                              ? Border.all(
                                  color: _colorAnimation.value ?? const Color(0xFF3B82F6),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Text(
                          '${widget.pendingCount}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: (_colorController.value > 0)
                                ? _colorAnimation.value
                                : const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Expanded(
                child: Text(
                  'Actividades\npendientes',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: const Color(0xFF6B7280),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
