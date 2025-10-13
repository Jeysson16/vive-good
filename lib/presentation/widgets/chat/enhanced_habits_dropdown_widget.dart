import 'package:flutter/material.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/user_habit.dart';
import '../../pages/habits/new_habit_screen.dart';

class EnhancedHabitsDropdownWidget extends StatefulWidget {
  final List<Habit> suggestedHabits;
  final List<UserHabit> existingUserHabits;
  final Function(Habit) onHabitSelected;
  final Function(Habit, Map<String, dynamic>)? onHabitConfigured;
  final VoidCallback? onHabitsUpdated;
  final bool showReprogrammingOptions;
  
  const EnhancedHabitsDropdownWidget({
    super.key,
    required this.suggestedHabits,
    required this.existingUserHabits,
    required this.onHabitSelected,
    this.onHabitConfigured,
    this.onHabitsUpdated,
    this.showReprogrammingOptions = false,
  });

  @override
  State<EnhancedHabitsDropdownWidget> createState() => _EnhancedHabitsDropdownWidgetState();
}

class _EnhancedHabitsDropdownWidgetState extends State<EnhancedHabitsDropdownWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar hábitos que el usuario ya tiene adoptados
    final filteredHabits = _filterAlreadyAdoptedHabits();
    
    if (filteredHabits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 32,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header clickeable con diseño compacto
          _buildHeader(filteredHabits.length),
          
          // Contenido expandible con scroll
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: _buildExpandedContent(filteredHabits),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int habitsCount) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Icono compacto
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              
              // Información del header compacta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.showReprogrammingOptions 
                          ? 'Hábitos y Reprogramaciones'
                          : 'Hábitos Recomendados',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$habitsCount ${habitsCount == 1 ? 'recomendación' : 'recomendaciones'}',
                      style: TextStyle(
                        color: const Color(0xFF4CAF50).withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Icono de expansión compacto
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(List<Habit> filteredHabits) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lista de hábitos compacta
          ...filteredHabits.asMap().entries.map((entry) {
            final index = entry.key;
            final habit = entry.value;
            return _buildHabitCard(habit, index);
          }),
          
          const SizedBox(height: 8),
          
          // Mensaje informativo compacto
          _buildInfoMessage(),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, int index) {
    final isReprogramming = _isReprogrammingHabit(habit);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isReprogramming 
              ? const Color(0xFFFF9800).withOpacity(0.3)
              : const Color(0xFF4CAF50).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleHabitSelection(habit),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono del hábito compacto
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isReprogramming
                        ? const Color(0xFFFF9800)
                        : _getHabitColor(habit),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getHabitIcon(habit),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Información del hábito
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1B5E20),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          habit.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Indicador de tipo
                if (isReprogramming)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Reprogramar',
                      style: TextStyle(
                        color: const Color(0xFFE65100),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.add_circle_outline,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitMetadata(Habit habit) {
    return Row(
      children: [
        // Categoría
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getHabitColor(habit).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getCategoryName(habit),
            style: TextStyle(
              color: _getHabitColor(habit),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Frecuencia estimada
        Icon(
          Icons.schedule,
          size: 14,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 4),
        Text(
          'Diario',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF4CAF50),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Toca cualquier hábito para agregarlo',
              style: TextStyle(
                color: const Color(0xFF2E7D32),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _fadeController.forward();
      } else {
        _animationController.reverse();
        _fadeController.reverse();
      }
    });
  }

  void _handleHabitSelection(Habit habit) {
    // Navegar a la pantalla de configuración del hábito
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewHabitScreen(
          prefilledHabitName: habit.name,
          prefilledDescription: habit.description,
          prefilledCategoryId: habit.categoryId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        widget.onHabitsUpdated?.call();
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hábito "${habit.name}" agregado exitosamente'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
    
    // También llamar al callback original
    widget.onHabitSelected(habit);
  }

  List<Habit> _filterAlreadyAdoptedHabits() {
    return widget.suggestedHabits.where((suggestedHabit) {
      // Verificar si el usuario ya tiene este hábito adoptado
      final alreadyExists = widget.existingUserHabits.any((userHabit) {
        final userHabitName = userHabit.customName ?? userHabit.habit?.name ?? '';
        return userHabitName.toLowerCase().trim() == 
               suggestedHabit.name.toLowerCase().trim();
      });
      return !alreadyExists;
    }).toList();
  }

  bool _isReprogrammingHabit(Habit habit) {
    // Lógica para determinar si es una reprogramación
    // Por ahora, basado en palabras clave en el nombre o descripción
    final text = '${habit.name} ${habit.description}'.toLowerCase();
    return text.contains('reprogramar') || 
           text.contains('cambiar horario') || 
           text.contains('ajustar') ||
           text.contains('modificar');
  }

  Color _getHabitColor(Habit habit) {
    if (habit.iconColor != null && habit.iconColor!.isNotEmpty) {
      try {
        return Color(int.parse(habit.iconColor!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback color
      }
    }
    return const Color(0xFF4CAF50);
  }

  IconData _getHabitIcon(Habit habit) {
    // Priorizar iconos de categoría para consistencia visual
    switch (habit.iconName?.toLowerCase()) {
      // Iconos de categorías principales
      case 'restaurant':
      case 'utensils':
        return Icons.restaurant;
      case 'fitness_center':
      case 'activity':
        return Icons.fitness_center;
      case 'psychology':
      case 'brain':
        return Icons.psychology;
      case 'water_drop':
      case 'droplet':
      case 'local_drink':
        return Icons.water_drop;
      case 'bed':
      case 'bedtime':
      case 'moon':
        return Icons.bedtime;
      case 'target':
      case 'track_changes':
        return Icons.track_changes;
      // Iconos específicos adicionales
      case 'favorite':
      case 'heart':
        return Icons.favorite;
      case 'book':
        return Icons.book;
      case 'self_improvement':
      case 'meditation':
        return Icons.self_improvement;
      case 'schedule':
        return Icons.schedule;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      default:
        return Icons.track_changes;
    }
  }

  String _getCategoryName(Habit habit) {
    // Mapear categoryId a nombre de categoría
    // Por ahora retornamos un valor por defecto
    return 'Salud';
  }
}