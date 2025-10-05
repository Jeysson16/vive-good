import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/user_habit.dart';
import '../common/responsive_dimensions.dart';

class HabitItem extends StatefulWidget {
  final UserHabit userHabit;
  final Habit habit;
  final Category? category;
  final bool isCompleted;
  final bool isSelected;
  final bool isHighlighted;
  final bool isFirstInCategory;
  final bool isBeingAnimated;
  final String? animationState; // 'AnimationState.categoryChanged' | 'AnimationState.habitToggled' | others
  final bool exitToLeft; // Controla dirección del desvanecimiento/salida
  final VoidCallback? onTap;
  final Function(String, bool)? onSelectionChanged;
  final VoidCallback? onHighlightComplete;
  final Function(UserHabit)? onEdit;
  final Function(UserHabit)? onViewProgress;
  final Function(UserHabit)? onDelete;
  final VoidCallback? onAnimationError;

  const HabitItem({
    super.key,
    required this.userHabit,
    required this.habit,
    required this.category,
    required this.isCompleted,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isFirstInCategory = false,
    this.isBeingAnimated = false,
    this.animationState,
    this.exitToLeft = false,
    this.onTap,
    this.onSelectionChanged,
    this.onHighlightComplete,
    this.onEdit,
    this.onViewProgress,
    this.onDelete,
    this.onAnimationError,
  });

  @override
  State<HabitItem> createState() => _HabitItemState();
}

class _HabitItemState extends State<HabitItem> with TickerProviderStateMixin {
  bool _showTemporaryHighlight = false;
  Timer? _highlightTimer;

  // Animation controllers for completion effect
  late AnimationController _completionController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late AnimationController _checkBounceController;
  late AnimationController
  _alreadyCompletedController; // NEW: For already completed feedback
  late AnimationController
  _categoryHighlightController; // NEW: For category highlight green shadow

  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _exitSlideAnimation; // Desplazamiento lateral atado al fade
  late Animation<double> _checkScaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _checkBounceAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<double>
  _alreadyCompletedPulseAnimation; // NEW: Pulse animation for already completed
  late Animation<double>
  _categoryHighlightAnimation; // NEW: Green shadow animation for category highlight

  bool _isAnimatingCompletion = false;
  bool _showCheckIcon = false;
  bool _lastTapWasOnCompletedHabit =
      false; // NEW: Track if last tap was on completed habit

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkBounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // NEW: Controller for already completed feedback
    _alreadyCompletedController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // NEW: Controller for category highlight green shadow
    _categoryHighlightController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Configurar desplazamiento de salida según la columna
    _exitSlideAnimation = Tween<double>(
      begin: 0.0,
      end: widget.exitToLeft ? -40.0 : 40.0,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _checkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completionController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticInOut),
    );

    _cardScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _completionController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _checkBounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkBounceController, curve: Curves.bounceOut),
    );

    _backgroundColorAnimation =
        ColorTween(
          begin: Colors.transparent,
          end: const Color(0xFF4CAF50).withOpacity(0.1),
        ).animate(
          CurvedAnimation(
            parent: _completionController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
          ),
        );

    // NEW: Pulse animation for already completed habits
    _alreadyCompletedPulseAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .animate(
          CurvedAnimation(
            parent: _alreadyCompletedController,
            curve: Curves.elasticOut,
          ),
        );

    // NEW: Green shadow animation for category highlight
    _categoryHighlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _categoryHighlightController,
        curve: Curves.easeInOut,
      ),
    );

    _checkHighlightState();
  }

  @override
  void didUpdateWidget(HabitItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHighlighted != widget.isHighlighted) {
      _checkHighlightState();
    }

    // NEW: Check if this habit became the first in category (category was selected)
    if (!oldWidget.isFirstInCategory && widget.isFirstInCategory) {
      _animateCategoryHighlight();
    }

    // Check if this habit should be animated due to external state change
    // DashboardBloc sets animatedHabitId when a habit is toggled OR when a category is selected.
    // We differentiate by animationState from DashboardBloc.
    if (!oldWidget.isBeingAnimated && widget.isBeingAnimated) {
      final state = widget.animationState ?? '';
      final isCategoryChange = state.contains('categoryChanged');
      final isHabitToggled = state.contains('habitToggled');
      if (isCategoryChange) {
        _animateCategoryHighlight();
      } else if (isHabitToggled) {
        _animateCompletion();
      } else {
        // Fallback: if unknown state but item is marked completed, animate completion; otherwise highlight
        if (widget.isCompleted) {
          _animateCompletion();
        } else {
          _animateCategoryHighlight();
        }
      }
    }

    // Actualizar dirección de salida si cambió la columna
    if (oldWidget.exitToLeft != widget.exitToLeft) {
      _exitSlideAnimation = Tween<double>(
        begin: 0.0,
        end: widget.exitToLeft ? -40.0 : 40.0,
      ).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
      );
    }

    // Check if habit was just completed (without animation state change)
    if (!oldWidget.isCompleted &&
        widget.isCompleted &&
        !widget.isBeingAnimated) {
      _animateCompletion();
    }

    // NEW: Check if user tapped on an already completed habit
    // This happens when the widget rebuilds but the completion status doesn't change
    // We detect this by checking if the habit is completed and we're not currently animating
    if (widget.isCompleted &&
        !widget.isBeingAnimated &&
        !_isAnimatingCompletion) {
      // Check if this is likely a tap on an already completed habit
      // We use a simple heuristic: if the widget updated and the habit is completed
      // but we're not in the middle of a completion animation, it's likely a tap
      if (!_lastTapWasOnCompletedHabit) {
        _lastTapWasOnCompletedHabit = true;
        _animateAlreadyCompleted();
        // Reset the flag after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          _lastTapWasOnCompletedHabit = false;
        });
      }
    }
  }

  void _animateCompletion() async {
    if (_isAnimatingCompletion) return;
    _isAnimatingCompletion = true;

    try {
      // Trigger haptic feedback
      HapticFeedback.mediumImpact();

      // Start the completion animation sequence
      if (!mounted) return;
      setState(() {
        _showCheckIcon = true;
      });

      // Phase 1: Card scale up and rotation with background color change
      if (!mounted) return; // evitar forward tras dispose
      await Future.wait([
        _completionController.forward(),
        _rotationController.forward(),
      ]);

      // Phase 2: Check bounce animation
      if (!mounted) return;
      await _checkBounceController.forward();

      // Phase 3: Scale animation for emphasis
      if (!mounted) return;
      await _scaleController.forward();

      // Hold the animation for a moment
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      // Phase 4: Fade out animation
      if (!mounted) return;
      await _fadeController.forward();

      // Reset all animations after completion
      _completionController.reset();
      _scaleController.reset();
      _rotationController.reset();
      _checkBounceController.reset();
      // Restore opacity for future builds
      _fadeController.reverse();

      if (!mounted) return;
      setState(() {
        _showCheckIcon = false;
        _isAnimatingCompletion = false;
      });
    } catch (e) {
      print('🚨 [ERROR] Animation failed in HabitItem: $e');
      // Reset animation state
      if (mounted) {
        setState(() {
          _showCheckIcon = false;
          _isAnimatingCompletion = false;
        });
      }

      // Reset all controllers
      _completionController.reset();
      _scaleController.reset();
      _rotationController.reset();
      _checkBounceController.reset();
      // Restore opacity for future builds
      _fadeController.reverse();

      // Report animation error to parent
      widget.onAnimationError?.call();
    }
  }

  // NEW: Animation for already completed habits
  void _animateAlreadyCompleted() async {
    // Trigger haptic feedback to let user know they tapped
    HapticFeedback.lightImpact();

    // Quick pulse animation to show the habit is already completed
    await _alreadyCompletedController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _alreadyCompletedController.reverse();
  }

  // NEW: Animation for completion that calls onTap after animation finishes
  Future<void> _animateCompletionThenComplete() async {
    if (_isAnimatingCompletion) return;
    _isAnimatingCompletion = true;

    try {
      // Trigger haptic feedback
      HapticFeedback.mediumImpact();

      // Start the completion animation sequence
      if (!mounted) return;
      setState(() {
        _showCheckIcon = true;
      });

      // Phase 1: Card scale up and rotation with background color change
      if (!mounted) return;
      await Future.wait([
        _completionController.forward(),
        _rotationController.forward(),
      ]);

      // Phase 2: Check bounce animation
      if (!mounted) return;
      await _checkBounceController.forward();

      // Phase 3: Scale animation for emphasis
      if (!mounted) return;
      await _scaleController.forward();

      // Hold the animation for a moment
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      // Phase 4: Fade out animation BEFORE completing to avoid abrupt layout shift
      if (!mounted) return;
      await _fadeController.forward();

      // NOW mark the habit as completed (this will update state in parent)
      if (widget.onTap != null) {
        widget.onTap!();
      }

      // Reset all animations after completion
      _completionController.reset();
      _scaleController.reset();
      _rotationController.reset();
      _checkBounceController.reset();
      // Restore opacity for future builds
      _fadeController.reverse();

      if (!mounted) return;
      setState(() {
        _showCheckIcon = false;
        _isAnimatingCompletion = false;
      });
    } catch (e) {
      print('🚨 [ERROR] Animation failed in HabitItem: $e');
      // Reset animation state
      if (mounted) {
        setState(() {
          _showCheckIcon = false;
          _isAnimatingCompletion = false;
        });
      }

      // Reset all controllers
      _completionController.reset();
      _scaleController.reset();
      _rotationController.reset();
      _checkBounceController.reset();
      // Restore opacity for future builds
      _fadeController.reverse();

      // Still call onTap even if animation failed
      if (widget.onTap != null) {
        widget.onTap!();
      }

      // Report animation error to parent
      widget.onAnimationError?.call();
    }
  }

  // NEW: Animation for category highlight (green shadow effect)
  void _animateCategoryHighlight() async {
    // Start the green shadow animation
    await _categoryHighlightController.forward();

    // Hold the animation for 1 second
    await Future.delayed(const Duration(milliseconds: 1000));

    // Fade out the green shadow
    await _categoryHighlightController.reverse();
  }

  void _checkHighlightState() {
    if (widget.isHighlighted &&
        !widget.isSelected &&
        !widget.isFirstInCategory) {
      setState(() {
        _showTemporaryHighlight = true;
      });

      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showTemporaryHighlight = false;
          });
          widget.onHighlightComplete?.call();
        }
      });
    } else {
      _highlightTimer?.cancel();
      setState(() {
        _showTemporaryHighlight = false;
      });
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _completionController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _rotationController.dispose();
    _checkBounceController.dispose();
    _alreadyCompletedController.dispose(); // NEW: Dispose the new controller
    _categoryHighlightController
        .dispose(); // NEW: Dispose the category highlight controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ResponsiveDimensions uses static methods, no need to instantiate
    final cardHeight = ResponsiveDimensions.getCardMinHeight(context);
    final iconSize = ResponsiveDimensions.getIconSize(context);
    final titleFontSize = ResponsiveDimensions.getFontSize(
      context,
      type: 'title',
    );
    final captionFontSize = ResponsiveDimensions.getFontSize(
      context,
      type: 'caption',
    );
    final padding = ResponsiveDimensions.getCardPadding(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _fadeAnimation,
        _exitSlideAnimation,
        _cardScaleAnimation,
        _rotationAnimation,
        _backgroundColorAnimation,
        _alreadyCompletedPulseAnimation, // NEW: Include pulse animation
      ]),
      builder: (context, child) {
        return Transform.scale(
            scale: _scaleAnimation.value *
                _cardScaleAnimation.value *
                _alreadyCompletedPulseAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                // Fill the grid tile to avoid RenderFlex overflow from height mismatch
                height: double.infinity,
                margin: EdgeInsets.symmetric(
                  horizontal: padding * 0.5,
                  vertical: padding * 0.25,
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isSelected)
                                ? const Color(0xFF4CAF50).withOpacity(0.3)
                                : widget.isCompleted
                                ? const Color(0xFF059669).withOpacity(0.2)
                                : _showTemporaryHighlight
                                ? const Color(0xFF6366F1).withOpacity(0.3)
                                : _categoryHighlightAnimation.value > 0
                                ? Color.lerp(
                                    Colors.black.withOpacity(0.08),
                                    const Color(0xFF10B981).withOpacity(0.4),
                                    _categoryHighlightAnimation.value,
                                  )!
                                : Colors.black.withOpacity(0.08),
                            blurRadius: (widget.isSelected)
                                ? 12
                                : _categoryHighlightAnimation.value > 0
                                ? 8 + (8 * _categoryHighlightAnimation.value)
                                : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: (widget.isSelected)
                            ? Border.all(
                                color: const Color(0xFF4CAF50),
                                width: 2,
                              )
                            : widget.isCompleted
                            ? Border.all(
                                color: const Color(0xFF059669),
                                width: 1.5,
                              )
                            : _showTemporaryHighlight
                            ? Border.all(
                                color: const Color(0xFF6366F1),
                                width: 2,
                              )
                            : _categoryHighlightAnimation.value > 0
                            ? Border.all(
                                color: Color.lerp(
                                  Colors.transparent,
                                  const Color(0xFF10B981),
                                  _categoryHighlightAnimation.value,
                                )!,
                                width: 1.5 * _categoryHighlightAnimation.value,
                              )
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Solo manejar selección, sin animaciones
                            if (widget.onSelectionChanged != null) {
                              widget.onSelectionChanged!(
                                widget.userHabit.id,
                                !widget.isSelected,
                              );
                            }
                          },
                          onLongPress: () {
                            if (widget.onSelectionChanged != null) {
                              widget.onSelectionChanged!(
                                widget.userHabit.id,
                                !widget.isSelected,
                              );
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // Usar max para permitir Expanded y evitar pequeños overflows
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                // Top row with checkbox and completion status
                                Row(
                                  children: [
                                    // Custom checkbox - clickable for completion
                                    GestureDetector(
                                      onTap: () async {
                                        if (widget.onTap != null) {
                                          if (!widget.isCompleted) {
                                            // Para hábitos no completados: animar primero, luego marcar como hecho
                                            await _animateCompletionThenComplete();
                                          } else {
                                            // Para hábitos ya completados: solo animación rápida
                                            _animateAlreadyCompleted();
                                            widget.onTap!();
                                          }
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: (widget.isSelected)
                                              ? const Color(0xFF4CAF50)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: (widget.isSelected)
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFD1D5DB),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: (widget.isSelected)
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 12,
                                              )
                                            : null,
                                      ),
                                    ),

                                    const Spacer(),

                                    // Action menu (three dots)
                                    if (widget.onEdit != null ||
                                        widget.onViewProgress != null ||
                                        widget.onDelete != null)
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: Colors.grey[600],
                                          size: 18,
                                        ),
                                        iconSize: 18,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        onSelected: (String action) {
                                          switch (action) {
                                            case 'edit':
                                              widget.onEdit?.call(
                                                widget.userHabit,
                                              );
                                              break;
                                            case 'progress':
                                              widget.onViewProgress?.call(
                                                widget.userHabit,
                                              );
                                              break;
                                            case 'delete':
                                              widget.onDelete?.call(
                                                widget.userHabit,
                                              );
                                              break;
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          if (widget.onEdit != null)
                                            const PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit,
                                                    size: 18,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text('Editar hábito'),
                                                ],
                                              ),
                                            ),
                                          if (widget.onViewProgress != null)
                                            const PopupMenuItem<String>(
                                              value: 'progress',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.analytics,
                                                    size: 18,
                                                    color: Color(0xFF3B82F6),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text('Ver progreso'),
                                                ],
                                              ),
                                            ),
                                          if (widget.onDelete != null)
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text('Eliminar hábito'),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),

                                    // Completion status
                                    if (widget.isCompleted)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF4CAF50,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF4CAF50),
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),

                                SizedBox(height: padding * 0.4),

                                // Category icon (centered)
                                if (widget.category != null)
                                  Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: iconSize * 2,
                                      height: iconSize * 2,
                                      decoration: BoxDecoration(
                                        color: (widget.isSelected)
                                            ? const Color(
                                                0xFF4CAF50,
                                              ).withOpacity(0.15)
                                            : widget.isCompleted
                                            ? const Color(
                                                0xFF22C55E,
                                              ).withOpacity(0.15)
                                            : _getIconColor().withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: (widget.isSelected)
                                            ? Border.all(
                                                color: const Color(0xFF4CAF50),
                                                width: 2,
                                              )
                                            : widget.isCompleted
                                            ? Border.all(
                                                color: const Color(0xFF22C55E),
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Icon(
                                              _getIconData(
                                                widget.category?.iconName ??
                                                    'star',
                                              ),
                                              color: (widget.isSelected)
                                                  ? const Color(0xFF4CAF50)
                                                  : widget.isCompleted
                                                  ? const Color(0xFF22C55E)
                                                  : _parseColor(
                                                      widget.category?.color ??
                                                          '#6366F1',
                                                    ),
                                              size: iconSize,
                                            ),
                                          ),
                                          if (widget.isCompleted)
                                            Positioned(
                                              top: 2,
                                              right: 2,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF22C55E),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 10,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),

                                SizedBox(height: padding * 0.4),

                                // Habit content (centered)
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(
                                        widget.habit.name,
                                        style: TextStyle(
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: (widget.isSelected)
                                              ? const Color(0xFF4CAF50)
                                              : widget.isCompleted
                                              ? const Color(0xFF059669)
                                              : const Color(0xFF111827),
                                          decoration: widget.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.category?.name != null) ...[
                                        const SizedBox(height: 2),
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (widget.isSelected)
                                                ? const Color(
                                                    0xFF4CAF50,
                                                  ).withOpacity(0.15)
                                                : widget.isCompleted
                                                ? const Color(
                                                    0xFF059669,
                                                  ).withOpacity(0.15)
                                                : _getIconColor().withOpacity(
                                                    0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: (widget.isSelected)
                                                ? Border.all(
                                                    color: const Color(
                                                      0xFF4CAF50,
                                                    ),
                                                    width: 1,
                                                  )
                                                : widget.isCompleted
                                                ? Border.all(
                                                    color: const Color(
                                                      0xFF059669,
                                                    ),
                                                    width: 1,
                                                  )
                                                : null,
                                          ),
                                          child: Text(
                                            widget.category?.name ??
                                                'Sin categoría',
                                            style: TextStyle(
                                              fontSize: captionFontSize,
                                              color: (widget.isSelected)
                                                  ? const Color(0xFF4CAF50)
                                                  : widget.isCompleted
                                                  ? const Color(0xFF059669)
                                                  : _parseColor(
                                                      widget.category?.color ??
                                                          '#6366F1',
                                                    ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Completion animation overlay
                    if (_showCheckIcon)
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _completionController,
                          _checkScaleAnimation,
                          _checkBounceAnimation,
                          _backgroundColorAnimation,
                        ]),
                        builder: (context, child) {
                          if (_completionController.value == 0 &&
                              !_showCheckIcon) {
                            return const SizedBox.shrink();
                          }

                          return Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    _backgroundColorAnimation.value ??
                                    Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50).withOpacity(
                                    0.3 * _completionController.value,
                                  ),
                                  width: 2 * _completionController.value,
                                ),
                              ),
                              child: Center(
                                child: Transform.scale(
                                  scale:
                                      _checkScaleAnimation.value *
                                      _checkBounceAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4CAF50,
                                          ).withOpacity(0.4),
                                          blurRadius:
                                              20 * _completionController.value,
                                          spreadRadius:
                                              4 * _completionController.value,
                                        ),
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4CAF50,
                                          ).withOpacity(0.2),
                                          blurRadius:
                                              40 * _completionController.value,
                                          spreadRadius:
                                              8 * _completionController.value,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size:
                                          36 +
                                          (8 * _checkBounceAnimation.value),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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

  Color _getIconColor() {
    return _parseColor(widget.category?.color ?? '#6B7280');
  }

  IconData _getIconData(String iconName) {
    // Map icon names to Flutter icons
    switch (iconName.toLowerCase()) {
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
      case 'local_drink':
        return Icons.local_drink;
      case 'brain':
      case 'psychology':
      case 'mental':
        return Icons.psychology;
      case 'target':
      case 'track_changes':
      case 'productivity':
        return Icons.track_changes;
      // Iconos específicos de la base de datos
      case 'apple':
        return Icons.apple;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'bedtime':
        return Icons.bedtime;
      case 'phone_iphone':
        return Icons.phone_iphone;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'edit':
        return Icons.edit;
      case 'menu_book':
        return Icons.menu_book;
      case 'event_note':
        return Icons.event_note;
      // Iconos adicionales
      case 'favorite':
        return Icons
            .fitness_center; // Cambiar de corazón a fitness para hábitos generales
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
      case 'spiritual':
        return Icons.self_improvement;
      case 'movie':
      case 'entertainment':
        return Icons.movie;
      case 'attach_money':
      case 'money':
      case 'finance':
        return Icons.attach_money;
      case 'fastfood':
        return Icons.fastfood;
      case 'general':
        return Icons.track_changes;
      default:
        return Icons.star;
    }
  }

  Color _parseColor(String colorString) {
    try {
      String cleanColor = colorString.trim();

      // Remove # if present
      if (cleanColor.startsWith('#')) {
        cleanColor = cleanColor.substring(1);
      }

      // Ensure we have a valid hex color (6 or 8 characters)
      if (cleanColor.length == 6) {
        // Add alpha channel for 6-digit hex
        cleanColor = 'FF$cleanColor';
      } else if (cleanColor.length != 8) {
        // Invalid length, use default
        return const Color(0xFF6366F1);
      }

      // Parse as hex with 0xFF prefix
      final colorValue = int.parse(cleanColor, radix: 16);
      return Color(0xFF000000 | colorValue);
    } catch (e) {
      // Debug: Error parsing color for troubleshooting
      // debugPrint('Error parsing color $colorString: $e');
      return const Color(0xFF6366F1);
    }
  }
}
