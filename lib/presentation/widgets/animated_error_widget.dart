import 'package:flutter/material.dart';
import 'animated_loading_widget.dart';
import 'animated_success_widget.dart';

class AnimatedErrorWidget extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const AnimatedErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  @override
  State<AnimatedErrorWidget> createState() => _AnimatedErrorWidgetState();
}

class _AnimatedErrorWidgetState extends State<AnimatedErrorWidget>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.bounceOut,
    ));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimation() {
    _scaleController.forward().then((_) {
      _shakeController.forward().then((_) {
        _fadeController.forward();
      });
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated error icon
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final shakeValue = _shakeAnimation.value;
                final offset = Offset(
                  10 * (shakeValue < 0.5 
                    ? shakeValue * 2 
                    : (1.0 - shakeValue) * 2) * 
                    (shakeValue < 0.25 || (shakeValue > 0.5 && shakeValue < 0.75) ? 1 : -1),
                  0,
                );
                
                return Transform.translate(
                  offset: offset,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEF4444),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Error message
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.onRetry != null) ...[
                    _buildActionButton(
                      onPressed: widget.onRetry!,
                      label: 'Reintentar',
                      isPrimary: true,
                    ),
                    if (widget.onDismiss != null) const SizedBox(width: 16),
                  ],
                  if (widget.onDismiss != null)
                    _buildActionButton(
                      onPressed: widget.onDismiss!,
                      label: 'Cerrar',
                      isPrimary: false,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required bool isPrimary,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
            ? const Color(0xFF3B82F6) 
            : Colors.grey[100],
          foregroundColor: isPrimary 
            ? Colors.white 
            : const Color(0xFF374151),
          elevation: isPrimary ? 2 : 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isPrimary 
              ? BorderSide.none 
              : const BorderSide(color: Color(0xFFD1D5DB)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}





// State transition widget that handles loading, success, and error states
class AnimatedStateWidget extends StatelessWidget {
  final Widget? loadingWidget;
  final Widget? successWidget;
  final Widget? errorWidget;
  final Widget? contentWidget;
  final String state; // 'loading', 'success', 'error', 'content'
  final Duration transitionDuration;

  const AnimatedStateWidget({
    super.key,
    this.loadingWidget,
    this.successWidget,
    this.errorWidget,
    this.contentWidget,
    required this.state,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: transitionDuration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildCurrentStateWidget(),
    );
  }

  Widget _buildCurrentStateWidget() {
    switch (state) {
      case 'loading':
        return loadingWidget ?? 
          const AnimatedLoadingWidget(
            key: ValueKey('loading'),
            message: 'Cargando...',
          );
      case 'success':
        return successWidget ?? 
          const AnimatedSuccessWidget(
            key: ValueKey('success'),
            message: '¡Éxito!',
          );
      case 'error':
        return errorWidget ?? 
          const AnimatedErrorWidget(
            key: ValueKey('error'),
            message: 'Ha ocurrido un error',
          );
      case 'content':
      default:
        return contentWidget ?? 
          const SizedBox(
            key: ValueKey('content'),
          );
    }
  }
}