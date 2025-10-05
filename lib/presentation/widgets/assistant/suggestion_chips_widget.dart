import 'package:flutter/material.dart';

class SuggestionChipsWidget extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;
  final EdgeInsetsGeometry? padding;
  final double? spacing;
  final Color? chipColor;
  final Color? textColor;
  final Color? borderColor;

  const SuggestionChipsWidget({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    this.padding,
    this.spacing,
    this.chipColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final defaultChipColor = chipColor ?? Colors.white;
    final defaultTextColor = textColor ?? const Color(0xFF2D3748);
    final defaultBorderColor = borderColor ?? const Color(0xFFE2E8F0);

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : (spacing ?? 8),
              ),
              child: _buildSuggestionChip(
                context,
                suggestion,
                defaultChipColor,
                defaultTextColor,
                defaultBorderColor,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(
    BuildContext context,
    String suggestion,
    Color chipColor,
    Color textColor,
    Color borderColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSuggestionTap(suggestion),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícono opcional basado en el contenido
              if (_getIconForSuggestion(suggestion) != null) ...[
                Icon(
                  _getIconForSuggestion(suggestion),
                  size: 16,
                  color: textColor.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
              ],
              
              // Texto de la sugerencia
              Flexible(
                child: Text(
                  suggestion,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData? _getIconForSuggestion(String suggestion) {
    final lowerSuggestion = suggestion.toLowerCase();
    
    // Mapear sugerencias a íconos relevantes
    if (lowerSuggestion.contains('almuerzo') || lowerSuggestion.contains('comida')) {
      return Icons.restaurant;
    } else if (lowerSuggestion.contains('cambiar') || lowerSuggestion.contains('cambia')) {
      return Icons.swap_horiz;
    } else if (lowerSuggestion.contains('reprogramar') || lowerSuggestion.contains('reprograma')) {
      return Icons.schedule;
    } else if (lowerSuggestion.contains('recordar') || lowerSuggestion.contains('recordatorio')) {
      return Icons.notifications;
    } else if (lowerSuggestion.contains('ejercicio') || lowerSuggestion.contains('actividad')) {
      return Icons.fitness_center;
    } else if (lowerSuggestion.contains('agua') || lowerSuggestion.contains('hidratación')) {
      return Icons.local_drink;
    } else if (lowerSuggestion.contains('medicamento') || lowerSuggestion.contains('medicina')) {
      return Icons.medication;
    } else if (lowerSuggestion.contains('síntoma') || lowerSuggestion.contains('dolor')) {
      return Icons.healing;
    } else if (lowerSuggestion.contains('análisis') || lowerSuggestion.contains('reporte')) {
      return Icons.analytics;
    } else if (lowerSuggestion.contains('consejo') || lowerSuggestion.contains('tip')) {
      return Icons.lightbulb_outline;
    }
    
    return null;
  }
}

// Widget especializado para sugerencias predefinidas
class PredefinedSuggestionsWidget extends StatelessWidget {
  final Function(String) onSuggestionTap;
  final bool showHealthSuggestions;
  final bool showScheduleSuggestions;
  final bool showGeneralSuggestions;

  const PredefinedSuggestionsWidget({
    super.key,
    required this.onSuggestionTap,
    this.showHealthSuggestions = true,
    this.showScheduleSuggestions = true,
    this.showGeneralSuggestions = true,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = _getPredefinedSuggestions();
    
    return SuggestionChipsWidget(
      suggestions: suggestions,
      onSuggestionTap: onSuggestionTap,
    );
  }

  List<String> _getPredefinedSuggestions() {
    List<String> suggestions = [];
    
    if (showScheduleSuggestions) {
      suggestions.addAll([
        'Reprograma el almuerzo',
        'Cambia mi rutina',
      ]);
    }
    
    if (showHealthSuggestions) {
      suggestions.addAll([
        'Analiza mis síntomas',
        'Consejos para gastritis',
        'Recordar medicamento',
      ]);
    }
    
    if (showGeneralSuggestions) {
      suggestions.addAll([
        '¿Cómo estoy hoy?',
        'Planificar comidas',
        'Ejercicios recomendados',
      ]);
    }
    
    return suggestions;
  }
}

// Widget para sugerencias contextuales basadas en el historial
class ContextualSuggestionsWidget extends StatelessWidget {
  final List<String> recentTopics;
  final List<String> userPreferences;
  final Function(String) onSuggestionTap;
  final int maxSuggestions;

  const ContextualSuggestionsWidget({
    super.key,
    required this.recentTopics,
    required this.userPreferences,
    required this.onSuggestionTap,
    this.maxSuggestions = 5,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = _generateContextualSuggestions();
    
    return SuggestionChipsWidget(
      suggestions: suggestions.take(maxSuggestions).toList(),
      onSuggestionTap: onSuggestionTap,
    );
  }

  List<String> _generateContextualSuggestions() {
    List<String> suggestions = [];
    
    // Sugerencias basadas en temas recientes
    for (final topic in recentTopics) {
      if (topic.toLowerCase().contains('dolor')) {
        suggestions.add('¿Cómo aliviar el dolor?');
      } else if (topic.toLowerCase().contains('comida')) {
        suggestions.add('Alimentos recomendados');
      } else if (topic.toLowerCase().contains('ejercicio')) {
        suggestions.add('Rutina de ejercicios');
      }
    }
    
    // Sugerencias basadas en preferencias del usuario
    for (final preference in userPreferences) {
      if (preference == 'vegetarian') {
        suggestions.add('Recetas vegetarianas');
      } else if (preference == 'fitness') {
        suggestions.add('Plan de ejercicios');
      } else if (preference == 'meditation') {
        suggestions.add('Ejercicios de relajación');
      }
    }
    
    // Eliminar duplicados y retornar
    return suggestions.toSet().toList();
  }
}