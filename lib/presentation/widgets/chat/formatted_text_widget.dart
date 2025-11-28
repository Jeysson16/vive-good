import 'package:flutter/material.dart';

class FormattedTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final double? fontSize;
  final Color? textColor;

  const FormattedTextWidget({
    super.key,
    required this.text,
    this.baseStyle,
    this.fontSize,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = baseStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: fontSize ?? 14,
          color: textColor ?? theme.colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: fontSize ?? 14,
          color: textColor ?? Colors.black87,
        );

    // Limpiar el texto antes de procesarlo
    final cleanText = _cleanTextForDisplay(text);

    return RichText(
      text: _parseFormattedText(cleanText, defaultStyle, theme),
    );
  }

  /// Limpia el texto para visualización eliminando símbolos residuales
  String _cleanTextForDisplay(String text) {
    return text
        // Eliminar símbolos $1, $2, etc. que puedan haber quedado
        .replaceAll(RegExp(r'\$\d+'), '')
        // Limpiar múltiples espacios
        .replaceAll(RegExp(r'\s+'), ' ')
        // Eliminar espacios al inicio y final
        .trim();
  }

  TextSpan _parseFormattedText(String text, TextStyle baseStyle, ThemeData theme) {
    final List<TextSpan> spans = [];
    
    // Procesar línea por línea para manejar listas y formato especial
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Manejar listas con bullets
      if (line.trim().startsWith('•')) {
        spans.add(TextSpan(
          text: i > 0 ? '\n' : '',
          style: baseStyle,
        ));
        
        final bulletContent = line.trim().substring(1).trim();
        spans.add(TextSpan(
           text: '• ',
           style: baseStyle.copyWith(
             color: theme.colorScheme.primary,
             fontWeight: FontWeight.bold,
           ),
         ));
         
         spans.addAll(_parseInlineFormatting(bulletContent, baseStyle, theme).children?.cast<TextSpan>() ?? []);
      } else {
        // Agregar salto de línea si no es la primera línea
        if (i > 0) {
          spans.add(TextSpan(
            text: '\n',
            style: baseStyle,
          ));
        }
        
        spans.addAll(_parseInlineFormatting(line, baseStyle, theme).children?.cast<TextSpan>() ?? []);
      }
    }

    return TextSpan(children: spans);
  }
  
  TextSpan _parseInlineFormatting(String text, TextStyle baseStyle, ThemeData theme) {
    final List<TextSpan> spans = [];
    final RegExp pattern = RegExp(r'\*\*([^*]+)\*\*|\*([^*]+)\*');
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Agregar texto normal antes del match
      if (match.start > lastEnd) {
        final normalText = text.substring(lastEnd, match.start);
        spans.add(TextSpan(
          text: normalText,
          style: baseStyle,
        ));
      }

      // Determinar si es negrita (**texto**) o cursiva (*texto*)
      if (match.group(1) != null) {
        // Texto en negrita (**texto**)
        spans.add(TextSpan(
          text: match.group(1)!,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ));
      } else if (match.group(2) != null) {
        // Texto en cursiva (*texto*)
        spans.add(TextSpan(
          text: match.group(2)!,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Agregar texto restante después del último match
    if (lastEnd < text.length) {
      final remainingText = text.substring(lastEnd);
      spans.add(TextSpan(
        text: remainingText,
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }
}

/// Widget especializado para mensajes del asistente con formato mejorado
class AssistantFormattedTextWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const AssistantFormattedTextWidget({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: FormattedTextWidget(
          text: text,
          baseStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar consejos de salud con formato especial
class HealthAdviceFormattedWidget extends StatelessWidget {
  final String text;
  final List<String>? suggestions;
  final VoidCallback? onSeeMore;

  const HealthAdviceFormattedWidget({
    super.key,
    required this.text,
    this.suggestions,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto principal formateado
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.1),
                theme.colorScheme.secondaryContainer.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: FormattedTextWidget(
            text: text,
            baseStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
        
        // Sugerencias adicionales si existen
        if (suggestions != null && suggestions!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Consejos adicionales:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                ...suggestions!.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
        
        // Botón "Ver más" si está disponible
        if (onSeeMore != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSeeMore,
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                'Ver más consejos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}