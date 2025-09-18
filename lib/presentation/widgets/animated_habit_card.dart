import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_habit.dart';
import '../blocs/habit/habit_bloc.dart';
import 'particle_celebration.dart';
import '../blocs/habit/habit_state.dart';
import 'common/responsive_dimensions.dart';

class AnimatedHabitCard extends StatefulWidget {
  final UserHabit userHabit;
  final int index;
  final Animation<double>? animation;
  final VoidCallback? onEdit;
  final Function(bool)? onToggle;

  const AnimatedHabitCard({
    Key? key,
    required this.userHabit,
    required this.index,
    this.animation,
    this.onEdit,
    this.onToggle,
  }) : super(key: key);

  @override
  State<AnimatedHabitCard> createState() => _AnimatedHabitCardState();
}

class _AnimatedHabitCardState extends State<AnimatedHabitCard>
    with TickerProviderStateMixin {
  bool _isCompleted = false;
  bool _showParticles = false;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _completionController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _completionAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntryAnimation();
  }

  void _initializeAnimations() {
    // Optimización: Usar duraciones más cortas para mejor performance
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 50)), // Reducido
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0.3, 0.0), // Reducido para menos movimiento
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOutQuart, // Curva más eficiente
          ),
        );

    // Scale animation optimizada
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100), // Más rápido
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98, // Menos escala para mejor performance
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    // Completion animation optimizada
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 250), // Más rápido
      vsync: this,
    );

    _completionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completionController,
        curve: Curves.easeOutBack, // Curva más eficiente
      ),
    );

    // Color animation optimizada
    _colorAnimation =
        ColorTween(begin: Colors.white, end: const Color(0xFFF0FDF4)).animate(
          CurvedAnimation(parent: _completionController, curve: Curves.easeOut),
        );

    // Pulse animation optimizada
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300), // Más rápido
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05, // Menos pulso para mejor performance
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // Bounce animation optimizada
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200), // Más rápido
      vsync: this,
    );

    _bounceAnimation =
        Tween<double>(
          begin: 1.0,
          end: 1.15, // Menos bounce
        ).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack),
        );
  }

  void _startEntryAnimation() {
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  void _handleTap() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    widget.onEdit?.call();
  }

  void _handleToggle() {
    setState(() {
      _isCompleted = !_isCompleted;
    });

    // Trigger pulse animation for immediate feedback
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });

    // Trigger bounce animation for completion button
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    if (_isCompleted) {
      _completionController.forward();
      // Add haptic feedback for completion
      _triggerSuccessFeedback();
    } else {
      _completionController.reverse();
    }

    widget.onToggle?.call(_isCompleted);
  }

  void _triggerSuccessFeedback() {
    // Visual feedback with a brief celebration effect
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showCompletionParticles();
      }
    });
  }

  void _showCompletionParticles() {
    setState(() {
      _showParticles = true;
    });

    // Hide particles after animation completes
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showParticles = false;
        });
      }
    });

    // Also trigger scale animation for additional feedback
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _completionController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HabitBloc, HabitState>(
      listener: (context, state) {
        if (state is HabitLoaded) {
          // Listen for animation triggers from BLoC
          if (state.animationState == AnimationState.habitToggled &&
              state.animatedHabitId == widget.userHabit.id) {
            _handleToggle();
          }
        }
      },
      child: Stack(
        children: [
          SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: AnimatedBuilder(
                      animation: _colorAnimation,
                      builder: (context, child) {
                        return Container(
                          margin: ResponsiveDimensions.getCardMargin(context),
                          constraints: BoxConstraints(
                            minHeight: ResponsiveDimensions.getCardMinHeight(
                              context,
                            ),
                          ),
                          child: Material(
                            elevation: _isCompleted ? 8 : 2,
                            borderRadius: BorderRadius.circular(
                              ResponsiveDimensions.getBorderRadius(context),
                            ),
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: EdgeInsets.all(
                                ResponsiveDimensions.getCardPadding(context),
                              ),
                              decoration: BoxDecoration(
                                color: _colorAnimation.value,
                                borderRadius: BorderRadius.circular(
                                  ResponsiveDimensions.getBorderRadius(context),
                                ),
                                border: Border.all(
                                  color: _isCompleted
                                      ? const Color(0xFF22C55E).withOpacity(0.3)
                                      : const Color(0xFFE5E7EB),
                                  width: _isCompleted ? 2 : 1,
                                ),
                                gradient: _isCompleted
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFFF0FDF4),
                                          const Color(0xFFDCFCE7),
                                        ],
                                      )
                                    : null,
                              ),
                              child: InkWell(
                                onTap: _handleTap,
                                borderRadius: BorderRadius.circular(
                                  ResponsiveDimensions.getBorderRadius(context),
                                ),
                                child: Row(
                                  children: [
                                    _buildHabitIcon(),
                                    SizedBox(
                                      width:
                                          ResponsiveDimensions.getHorizontalSpacing(
                                            context,
                                          ),
                                    ),
                                    Expanded(child: _buildHabitInfo()),
                                    _buildCompletionButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          // Particle celebration overlay
          ParticleCelebration(
            isVisible: _showParticles,
            onComplete: () {
              setState(() {
                _showParticles = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHabitIcon() {
    final iconContainerSize = ResponsiveDimensions.getIconContainerSize(
      context,
    );
    final iconSize = ResponsiveDimensions.getIconSize(context);
    final borderRadius = ResponsiveDimensions.getBorderRadius(context);
    final iconColor = _getIconColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: iconContainerSize,
      height: iconContainerSize,
      decoration: BoxDecoration(
        color: _isCompleted
            ? iconColor.withOpacity(0.2)
            : iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          _isCompleted ? Icons.check_circle : _getCategoryIcon(),
          key: ValueKey(_isCompleted),
          color: _isCompleted ? iconColor : iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  Color _getIconColor() {
    if (widget.userHabit.habit?.iconColor != null) {
      try {
        // Convertir string hexadecimal a int
        String colorString = widget.userHabit.habit!.iconColor!;
        // Si no tiene el prefijo 0x, agregarlo
        if (!colorString.startsWith('0x')) {
          colorString = '0x$colorString';
        }
        return Color(int.parse(colorString));
      } catch (e) {
        // Si hay error en la conversión, usar color por defecto
        return const Color(0xFF6B7280);
      }
    }
    return const Color(0xFF6B7280);
  }

  IconData _getCategoryIcon() {
    if (widget.userHabit.habit?.iconName == null) return Icons.star;

    // Map icon names to Flutter icons
    switch (widget.userHabit.habit!.iconName!.toLowerCase()) {
      // Iconos de las categorías de la base de datos
      case 'utensils':
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'activity':
      case 'fitness_center':
      case 'exercise':
        return Icons.fitness_center;
      case 'moon':
      case 'bed':
      case 'sleep':
        return Icons.bedtime;
      case 'droplet':
      case 'water_drop':
      case 'water':
        return Icons.water_drop;
      case 'brain':
      case 'psychology':
      case 'mental':
        return Icons.psychology;
      case 'target':
      case 'track_changes':
      case 'productivity':
        return Icons.track_changes;
      // Iconos adicionales
      case 'favorite':
      case 'heart':
        return Icons.favorite;
      case 'work':
      case 'business':
        return Icons.work;
      case 'school':
      case 'education':
        return Icons.school;
      case 'person':
      case 'personal':
        return Icons.person;
      case 'home':
      case 'house':
        return Icons.home;
      case 'people':
      case 'social':
        return Icons.people;
      case 'palette':
      case 'creative':
        return Icons.palette;
      case 'self_improvement':
      case 'spiritual':
        return Icons.self_improvement;
      case 'movie':
      case 'entertainment':
        return Icons.movie;
      case 'attach_money':
      case 'money':
      case 'finance':
        return Icons.attach_money;
      case 'general':
        return Icons.track_changes;
      default:
        return Icons.star;
    }
  }

  Widget _buildHabitInfo() {
    final titleFontSize = ResponsiveDimensions.getFontSize(
      context,
      type: 'title',
    );
    final subtitleFontSize = ResponsiveDimensions.getFontSize(
      context,
      type: 'subtitle',
    );
    final captionFontSize = ResponsiveDimensions.getFontSize(
      context,
      type: 'caption',
    );
    final verticalSpacing = ResponsiveDimensions.getVerticalSpacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: _isCompleted
                ? const Color(0xFF059669)
                : const Color(0xFF1F2937),
            decoration: _isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
          child: Text('Hábito ${widget.userHabit.habitId}'),
        ),
        SizedBox(height: verticalSpacing),
        Text(
          'Frecuencia: ${widget.userHabit.frequency}',
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: _isCompleted
                ? const Color(0xFF059669).withOpacity(0.7)
                : const Color(0xFF6B7280),
          ),
        ),
        if (widget.userHabit.scheduledTime != null) ...[
          SizedBox(height: verticalSpacing / 2),
          Text(
            'Hora: ${widget.userHabit.scheduledTime}',
            style: TextStyle(
              fontSize: captionFontSize,
              color: _isCompleted
                  ? const Color(0xFF059669).withOpacity(0.6)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth < 360
        ? 28.0
        : screenWidth < 600
        ? 32.0
        : 36.0;
    final iconSize = screenWidth < 360
        ? 16.0
        : screenWidth < 600
        ? 20.0
        : 24.0;
    final borderRadius = ResponsiveDimensions.getBorderRadius(context) / 2;

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: _isCompleted
                  ? const Color(0xFF22C55E)
                  : Colors.transparent,
              border: Border.all(
                color: _isCompleted
                    ? const Color(0xFF22C55E)
                    : Colors.grey.shade400,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: _isCompleted
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: _isCompleted
                ? Icon(Icons.check, color: Colors.white, size: iconSize)
                : null,
          ),
        );
      },
    );
  }
}
