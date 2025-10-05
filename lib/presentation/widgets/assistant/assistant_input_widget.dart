import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'voice_animation_widget.dart';

class AssistantInputWidget extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback? onSendMessage;
  final VoidCallback? onStartVoiceRecording;
  final VoidCallback? onStopVoiceRecording;
  final VoidCallback? onAttachFile;
  final VoidCallback? onOpenSettings;
  final bool isRecording;
  final bool isLoading;
  final bool isConnected;
  final String? placeholder;
  final double? recordingAmplitude;
  final bool showVoiceAnimation;
  final Function(String)? onTextChanged;
  final bool enableVoiceInput;
  final bool enableFileAttachment;
  final bool enableSettings;
  final int? maxLines;
  final int? maxLength;

  const AssistantInputWidget({
    super.key,
    required this.textController,
    this.onSendMessage,
    this.onStartVoiceRecording,
    this.onStopVoiceRecording,
    this.onAttachFile,
    this.onOpenSettings,
    this.isRecording = false,
    this.isLoading = false,
    this.isConnected = true,
    this.placeholder,
    this.recordingAmplitude,
    this.showVoiceAnimation = true,
    this.onTextChanged,
    this.enableVoiceInput = true,
    this.enableFileAttachment = true,
    this.enableSettings = true,
    this.maxLines = 4,
    this.maxLength = 1000,
  });

  @override
  State<AssistantInputWidget> createState() => _AssistantInputWidgetState();
}

class _AssistantInputWidgetState extends State<AssistantInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _hasText = false;
  FocusNode? _textFocusNode;
  
  @override
  void initState() {
    super.initState();
    
    _textFocusNode = FocusNode();
    _hasText = widget.textController.text.isNotEmpty;
    
    // Controlador para el efecto de pulso del botón de grabación
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Controlador para el efecto de escala
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    // Escuchar cambios en el texto
    widget.textController.addListener(_onTextChanged);
    
    // Iniciar animación de pulso si está grabando
    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(AssistantInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Actualizar animación de grabación
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _textFocusNode?.dispose();
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }
  
  void _onTextChanged() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onTextChanged?.call(widget.textController.text);
  }
  
  void _handleVoiceButtonPress() {
    if (widget.isRecording) {
      widget.onStopVoiceRecording?.call();
    } else {
      widget.onStartVoiceRecording?.call();
    }
    
    // Feedback háptico
    HapticFeedback.mediumImpact();
  }
  
  void _handleSendMessage() {
    if (_hasText && !widget.isLoading) {
      widget.onSendMessage?.call();
      // Feedback háptico
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de conexión
            if (!widget.isConnected)
              _buildConnectionIndicator(),
            
            // Área de entrada principal
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Botón de adjuntar archivo
                if (widget.enableFileAttachment)
                  _buildActionButton(
                    icon: Icons.attach_file,
                    onPressed: widget.onAttachFile,
                    tooltip: 'Adjuntar archivo',
                  ),
                
                if (widget.enableFileAttachment)
                  const SizedBox(width: 8),
                
                // Campo de texto expandible
                Expanded(
                  child: _buildTextInput(),
                ),
                
                const SizedBox(width: 8),
                
                // Botón de enviar o micrófono
                _buildMainActionButton(),
                
                const SizedBox(width: 8),
                
                // Botón de configuración
                if (widget.enableSettings)
                  _buildActionButton(
                    icon: Icons.settings,
                    onPressed: widget.onOpenSettings,
                    tooltip: 'Configuración',
                  ),
              ],
            ),
            
            // Animación de ondas de voz (cuando está grabando)
            if (widget.isRecording && widget.showVoiceAnimation)
              _buildVoiceAnimationArea(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectionIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: Colors.red[700],
          ),
          const SizedBox(width: 6),
          Text(
            'Sin conexión',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 48,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _textFocusNode?.hasFocus == true
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: widget.textController,
        focusNode: _textFocusNode,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        enabled: !widget.isLoading,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.placeholder ?? '¿En qué puedo ayudarte?',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[500],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          counterText: '', // Ocultar contador de caracteres
        ),
        onSubmitted: (_) => _handleSendMessage(),
      ),
    );
  }
  
  Widget _buildMainActionButton() {
    final isVoiceMode = !_hasText && widget.enableVoiceInput;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRecording ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) => _scaleController.reverse(),
            onTapCancel: () => _scaleController.reverse(),
            onTap: isVoiceMode ? _handleVoiceButtonPress : _handleSendMessage,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.isRecording
                          ? const Color(0xFF4CAF50)
                          : (_hasText
                              ? Theme.of(context).primaryColor
                              : const Color(0xFF10B981)),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isRecording
                                  ? const Color(0xFF4CAF50)
                                  : (_hasText
                                      ? Theme.of(context).primaryColor
                                      : const Color(0xFF10B981)))
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isRecording
                          ? Icons.stop
                          : (_hasText ? Icons.send : Icons.mic),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildVoiceAnimationArea() {
    return Container(
      margin: const EdgeInsets.only(top: 8), // Reducido de 16 a 8
      height: 40, // Reducido de 80 a 40
      child: VoiceAnimationWidget(
        controller: _pulseController,
        amplitude: widget.recordingAmplitude ?? 0.0,
        color: const Color(0xFF4CAF50),
      ),
    );
  }
}

// Widget para mostrar sugerencias rápidas
class QuickSuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final Function(String)? onSuggestionTap;
  final bool isVisible;

  const QuickSuggestionsWidget({
    super.key,
    required this.suggestions,
    this.onSuggestionTap,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          
          return Container(
            margin: EdgeInsets.only(right: index < suggestions.length - 1 ? 8 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSuggestionTap?.call(suggestion),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}