import 'package:flutter/material.dart';

/// Widget del botón para regenerar la última respuesta del asistente
class RegenerateButtonWidget extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const RegenerateButtonWidget({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<RegenerateButtonWidget> createState() => _RegenerateButtonWidgetState();
}

class _RegenerateButtonWidgetState extends State<RegenerateButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(RegenerateButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isLoading ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: _isHovered && !widget.isLoading
                  ? const Color(0xFF45A049)
                  : const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (_isHovered && !widget.isLoading)
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de regenerar
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 18,
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: 8),
                
                // Texto
                Text(
                  widget.isLoading ? 'Regenerando...' : 'Regenerar respuesta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget alternativo más simple para el botón de regenerar
class SimpleRegenerateButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const SimpleRegenerateButtonWidget({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.refresh,
                size: 18,
              ),
        label: Text(
          isLoading ? 'Regenerando...' : 'Regenerar respuesta',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

/// Widget de botón flotante para regenerar
class FloatingRegenerateButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isVisible;

  const FloatingRegenerateButtonWidget({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: FloatingActionButton.extended(
            onPressed: isLoading ? null : onPressed,
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(
              isLoading ? 'Regenerando...' : 'Regenerar',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de botón inline para regenerar (aparece después del último mensaje)
class InlineRegenerateButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const InlineRegenerateButtonWidget({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44), // Alineado con los mensajes del asistente
      child: Row(
        children: [
          TextButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  )
                : const Icon(
                    Icons.refresh,
                    size: 16,
                    color: Color(0xFF4CAF50),
                  ),
            label: Text(
              isLoading ? 'Regenerando...' : 'Regenerar',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFF4CAF50),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}