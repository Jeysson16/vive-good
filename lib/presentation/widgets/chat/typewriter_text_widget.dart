import 'package:flutter/material.dart';
import 'dart:async';

/// Widget que muestra texto con efecto de escritura progresiva (typewriter)
class TypewriterTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final VoidCallback? onComplete;
  final bool autoStart;
  final Widget? cursor;
  final bool showCursor;

  const TypewriterTextWidget({
    super.key,
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 50),
    this.onComplete,
    this.autoStart = true,
    this.cursor,
    this.showCursor = true,
  });

  @override
  State<TypewriterTextWidget> createState() => _TypewriterTextWidgetState();
}

class _TypewriterTextWidgetState extends State<TypewriterTextWidget>
    with TickerProviderStateMixin {
  String _displayedText = '';
  Timer? _timer;
  int _currentIndex = 0;
  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    
    // Configurar animación del cursor
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cursorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cursorController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar animación del cursor
    _cursorController.repeat(reverse: true);
    
    if (widget.autoStart) {
      _startTypewriter();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TypewriterTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Si el texto cambió, reiniciar la animación
    if (oldWidget.text != widget.text) {
      _resetTypewriter();
      if (widget.autoStart) {
        _startTypewriter();
      }
    }
  }

  void _startTypewriter() {
    _timer?.cancel();
    _currentIndex = 0;
    _displayedText = '';
    _isComplete = false;
    
    final Characters allChars = widget.text.characters;
    final int totalChars = allChars.length;

    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < totalChars) {
        setState(() {
          _displayedText = allChars.take(_currentIndex + 1).toString();
          _currentIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isComplete = true;
        });
        
        // Detener animación del cursor cuando termine
        _cursorController.stop();
        _cursorController.value = 1.0;
        
        widget.onComplete?.call();
      }
    });
  }

  void _resetTypewriter() {
    _timer?.cancel();
    setState(() {
      _displayedText = '';
      _currentIndex = 0;
      _isComplete = false;
    });
    
    // Reiniciar animación del cursor
    _cursorController.repeat(reverse: true);
  }

  /// Método público para iniciar la animación manualmente
  void start() {
    _startTypewriter();
  }

  /// Método público para pausar la animación
  void pause() {
    _timer?.cancel();
  }

  /// Método público para resetear la animación
  void reset() {
    _resetTypewriter();
  }

  /// Método público para completar instantáneamente
  void complete() {
    _timer?.cancel();
    setState(() {
      _displayedText = widget.text.characters.toString();
      _currentIndex = widget.text.characters.length;
      _isComplete = true;
    });
    
    _cursorController.stop();
    _cursorController.value = 1.0;
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: _displayedText,
            style: widget.style ?? DefaultTextStyle.of(context).style,
          ),
          if (widget.showCursor && !_isComplete)
            WidgetSpan(
              child: AnimatedBuilder(
                animation: _cursorAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _cursorAnimation.value,
                    child: widget.cursor ??
                        Container(
                          width: 2,
                          height: (widget.style?.fontSize ?? 16) * 1.2,
                          color: widget.style?.color ?? Colors.black,
                          margin: const EdgeInsets.only(left: 1),
                        ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget especializado para mensajes del asistente con efecto typewriter
class AssistantTypewriterWidget extends StatefulWidget {
  final String text;
  final TextStyle? baseStyle;
  final Duration speed;
  final VoidCallback? onComplete;
  final bool autoStart;
  final bool enableFormatting;

  const AssistantTypewriterWidget({
    super.key,
    required this.text,
    this.baseStyle,
    this.speed = const Duration(milliseconds: 30),
    this.onComplete,
    this.autoStart = true,
    this.enableFormatting = true,
  });

  @override
  State<AssistantTypewriterWidget> createState() => _AssistantTypewriterWidgetState();
}

class _AssistantTypewriterWidgetState extends State<AssistantTypewriterWidget> {
  final GlobalKey<_TypewriterTextWidgetState> _typewriterKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypewriterTextWidget(
          key: _typewriterKey,
          text: widget.text,
          style: widget.baseStyle ?? const TextStyle(
            fontSize: 16,
            color: Color(0xFF333333),
            height: 1.4,
          ),
          speed: widget.speed,
          onComplete: widget.onComplete,
          autoStart: widget.autoStart,
        ),
      ],
    );
  }

  /// Método público para controlar la animación
  void start() => _typewriterKey.currentState?.start();
  void pause() => _typewriterKey.currentState?.pause();
  void reset() => _typewriterKey.currentState?.reset();
  void complete() => _typewriterKey.currentState?.complete();
}