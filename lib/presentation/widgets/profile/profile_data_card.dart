import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_profile.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../domain/entities/category.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_state.dart';

/// Widget que muestra la tarjeta de datos del perfil
/// Ahora con altura dinámica y datos reales
class ProfileDataCard extends StatelessWidget {
  final UserProfile profile;

  const ProfileDataCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileExporting) {
          // Mostrar indicador de carga
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text('Exportando historial...'),
                  ],
                ),
              );
            },
          );
        } else if (state is ProfileExported) {
          // Cerrar diálogo de carga si está abierto
          Navigator.of(context).pop();
          
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Historial exportado exitosamente en: ${state.filePath}'),
              backgroundColor: const Color(0xFF219540),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is ProfileError) {
          // Cerrar diálogo de carga si está abierto
          Navigator.of(context).pop();
          
          // Mostrar mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al exportar: ${state.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Container(
        width: 333,
        // ✅ ALTURA REMOVIDA - Ahora es dinámico
        margin: const EdgeInsets.only(top: 7, left: 21),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // ✅ ALTURA DINÁMICA
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos de salud
              _buildHealthDataSection(),
              
              const SizedBox(height: 16),
              
              // Hábitos activos - ✅ AHORA CON DATOS REALES
              BlocBuilder<HabitBloc, HabitState>(
                builder: (context, habitState) {
                  return _buildActiveHabitsSection(habitState);
                },
              ),
              
              const SizedBox(height: 16),
              
              // Configuraciones inteligentes
              _buildSmartConfigSection(),
              
              const SizedBox(height: 16),
              
              // Botones de acción
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos de salud',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF090D3A),
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 12),
        
        // Altura
        _buildHealthItem(
          icon: Icons.straighten,
          text: 'Altura: ${profile.formattedHeight}',
        ),
        
        const SizedBox(height: 6),
        
        // Peso
        _buildHealthItem(
          icon: Icons.monitor_weight,
          text: 'Peso: ${profile.formattedWeight}',
        ),
        
        const SizedBox(height: 12),
        
        // Factores de riesgo
        const Text(
          'Factores de riesgo:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF090D3A),
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 8),
        
        // Lista de factores de riesgo - ✅ SOLO DATOS REALES
        ...profile.riskFactors.isNotEmpty 
            ? profile.riskFactors.map((factor) => _buildRiskFactor(factor, true))
            : [
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'No hay factores de riesgo registrados',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Roboto',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
      ],
    );
  }

  Widget _buildHealthItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF219540),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF090D3A),
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }

  Widget _buildRiskFactor(String factor, bool isGood) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isGood ? const Color(0xFF219540) : const Color(0xFFE5E7EB),
          ),
          const SizedBox(width: 8),
          Text(
            factor,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF090D3A),
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVA FUNCIÓN: Construye la sección de hábitos activos con datos reales
  Widget _buildActiveHabitsSection(HabitState habitState) {
    // Calcular estadísticas reales de hábitos por categoría
    Map<String, int> habitStats = _calculateHabitStats(habitState);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hábitos activos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF090D3A),
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 12),
        
        // Hidratación - datos reales
        _buildHabitItem(
          icon: Icons.water_drop,
          text: 'Hidratación: ${habitStats['hydration'] ?? 0} hábitos activos',
        ),
        
        const SizedBox(height: 8),
        
        // Sueño - datos reales
        _buildHabitItem(
          icon: Icons.bedtime,
          text: 'Sueño: ${habitStats['sleep'] ?? 0} hábitos activos',
        ),
        
        const SizedBox(height: 8),
        
        // Actividad - datos reales
        _buildHabitItem(
          icon: Icons.directions_run,
          text: 'Actividad: ${habitStats['activity'] ?? 0} hábitos activos',
        ),
        
        // Mostrar total de hábitos si no hay datos específicos
        if (habitStats['hydration'] == 0 && habitStats['sleep'] == 0 && habitStats['activity'] == 0 && habitState is HabitLoaded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Total de hábitos activos: ${habitState.userHabits.where((h) => h.isActive).length}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Roboto',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  /// ✅ FUNCIÓN MEJORADA: Calcula estadísticas de hábitos por categoría
  Map<String, int> _calculateHabitStats(HabitState habitState) {
    Map<String, int> stats = {
      'hydration': 0,
      'sleep': 0,
      'activity': 0,
    };

    if (habitState is HabitLoaded) {
      // Mapear categorías por nombre a nuestras claves
      Map<String, String> categoryMapping = {};
      
      for (Category category in habitState.categories) {
        String categoryName = category.name.toLowerCase();
        if (categoryName.contains('hidrat') || 
            categoryName.contains('agua') || 
            categoryName.contains('beber') ||
            categoryName.contains('líquido')) {
          categoryMapping[category.id] = 'hydration';
        } else if (categoryName.contains('sueño') || 
                   categoryName.contains('dormir') || 
                   categoryName.contains('descanso') ||
                   categoryName.contains('sleep')) {
          categoryMapping[category.id] = 'sleep';
        } else if (categoryName.contains('actividad') || 
                   categoryName.contains('ejercicio') || 
                   categoryName.contains('deporte') ||
                   categoryName.contains('físic') ||
                   categoryName.contains('caminar') ||
                   categoryName.contains('correr')) {
          categoryMapping[category.id] = 'activity';
        }
      }

      // Contar hábitos activos por categoría
      for (UserHabit userHabit in habitState.userHabits) {
        // Solo contar hábitos activos
        if (userHabit.isActive) {
          String? categoryId = userHabit.habit?.categoryId;
          if (categoryId != null) {
            String? statKey = categoryMapping[categoryId];
            if (statKey != null) {
              stats[statKey] = (stats[statKey] ?? 0) + 1;
            }
          }
        }
      }
    }

    return stats;
  }

  /// ✅ FUNCIÓN ORIGINAL ELIMINADA - ahora se usa la nueva con datos reales
  // Widget _buildActiveHabitsSection() { ... }

  Widget _buildHabitItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF219540),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF090D3A),
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }

  Widget _buildSmartConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuraciones inteligentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF090D3A),
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 10),
        
        // Sugerencias automáticas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sugerencias automáticas',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF090D3A),
                fontFamily: 'Roboto',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: profile.autoSuggestionsEnabled 
                    ? const Color(0xFF219540) 
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profile.autoSuggestionsEnabled ? 'Activadas' : 'Desactivadas',
                style: TextStyle(
                  fontSize: 12,
                  color: profile.autoSuggestionsEnabled 
                      ? Colors.white 
                      : const Color(0xFF6B7280),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Recordatorios diarios
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recordatorios diarios',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF090D3A),
                fontFamily: 'Roboto',
              ),
            ),
            Text(
              '${profile.formattedMorningTime}, ${profile.formattedEveningTime}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Botón Editar perfil
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              print('ProfileDataCard - Navegando a editar perfil');
              // ✅ NAVEGACIÓN IMPLEMENTADA con GoRouter
              final result = await context.push('/edit-profile', extra: profile);
              
              // Si se guardaron cambios, forzar recarga del perfil
              if (result == true) {
                print('ProfileDataCard - Perfil editado, forzando recarga');
                if (context.mounted) {
                  context.read<ProfileBloc>().add(LoadUserProfile());
                }
              }
            },
            icon: const Icon(
              Icons.edit,
              size: 18,
              color: Color(0xFF090D3A),
            ),
            label: const Text(
              'Editar perfil',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF090D3A),
                fontFamily: 'Roboto',
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Botón Exportar historial
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // ✅ FUNCIONALIDAD IMPLEMENTADA
              _exportUserHistory(context);
            },
            icon: const Icon(
              Icons.download,
              size: 18,
              color: Color(0xFF090D3A),
            ),
            label: const Text(
              'Exportar historial',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF090D3A),
                fontFamily: 'Roboto',
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Función para exportar el historial del usuario
  void _exportUserHistory(BuildContext context) {
    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exportar historial'),
          content: const Text(
            '¿Deseas exportar tu historial de hábitos y datos de salud?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // ✅ USAR PROFILEBLOC PARA EXPORTAR
                context.read<ProfileBloc>().add(const ExportUserHistory());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF219540),
              ),
              child: const Text(
                'Exportar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }


}