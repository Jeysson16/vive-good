import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_habit.dart';
import '../blocs/habit/habit_bloc.dart';
import 'particle_celebration.dart';
import '../blocs/habit/habit_state.dart';

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
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            elevation: _isCompleted ? 8 : 2,
                            borderRadius: BorderRadius.circular(16),
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _colorAnimation.value,
                                borderRadius: BorderRadius.circular(16),
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
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  children: [
                                    _buildHabitIcon(),
                                    const SizedBox(width: 16),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _isCompleted
            ? const Color(0xFF22C55E).withOpacity(0.2)
            : const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          _isCompleted ? Icons.check_circle : Icons.track_changes,
          key: ValueKey(_isCompleted),
          color: _isCompleted
              ? const Color(0xFF22C55E)
              : const Color(0xFF3B82F6),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildHabitInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: 16,
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
        const SizedBox(height: 4),
        Text(
          'Frecuencia: ${widget.userHabit.frequency}',
          style: TextStyle(
            fontSize: 14,
            color: _isCompleted
                ? const Color(0xFF059669).withOpacity(0.7)
                : const Color(0xFF6B7280),
          ),
        ),
        if (widget.userHabit.scheduledTime != null) ...[
          const SizedBox(height: 2),
          Text(
            'Hora: ${widget.userHabit.scheduledTime}',
            style: TextStyle(
              fontSize: 12,
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
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
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
              borderRadius: BorderRadius.circular(8),
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
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      },
    );
  }
}
