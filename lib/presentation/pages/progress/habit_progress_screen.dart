import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:vive_good_app/core/theme/app_text_styles.dart';
import '../../../domain/entities/user_habit.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_event.dart';
import '../../blocs/habit/habit_state.dart';
import 'dart:math' as math;

class HabitProgressScreen extends StatefulWidget {
  final UserHabit userHabit;
  final String userId;

  const HabitProgressScreen({
    super.key,
    required this.userHabit,
    required this.userId,
  });

  @override
  State<HabitProgressScreen> createState() => _HabitProgressScreenState();
}

class _HabitProgressScreenState extends State<HabitProgressScreen> {
  bool _isLoading = true;
  List<bool> _weeklyProgress = List<bool>.filled(7, false);
  double _completionPercentage = 0.0;
  int _currentStreak = 0;
  List<double> _weeklyChart = List<double>.filled(4, 0.0);

  @override
  void initState() {
    super.initState();
    _loadHabitProgress();
  }
  
  void _loadHabitProgress() {
    _refreshFromRemote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Progreso del hábito',
          style: AppTextStyles.headingMedium.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Cargando progreso...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressHeader(),
                  const SizedBox(height: 24),
                  _buildWeeklyCalendar(),
                  const SizedBox(height: 24),
                  _buildProgressChart(),
                  const SizedBox(height: 24),
                  _buildMotivationalMessage(),
                  const SizedBox(height: 24),
                  _buildChangeFrequencyButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressHeader() {
    final habitName = widget.userHabit.habit?.name ?? 
                     widget.userHabit.customName ?? 
                     'Hábito';
    final frequency = widget.userHabit.frequency ?? 'Diario';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(_completionPercentage * _expectedDaysThisWeek()).round()}/${_expectedDaysThisWeek()} días',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Días completados\nesta semana',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      habitName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      maxLines: 2,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Último día\nmarcado',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _lastCompletedDateLabel(),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                frequency,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isCompleted = _weeklyProgress[index];
        final isToday = index == DateTime.now().weekday - 1;
        
        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? const Color(0xFF4CAF50) 
                    : (isToday ? Colors.red : Colors.transparent),
                shape: BoxShape.circle,
                border: !isCompleted && !isToday 
                    ? Border.all(color: Colors.grey[300]!, width: 1)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : (isToday
                        ? const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          )
                        : null),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: AppTextStyles.bodySmall.copyWith(
                color: isCompleted 
                    ? const Color(0xFF4CAF50)
                    : (isToday ? Colors.red : Colors.grey[600]),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProgressChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '100 %',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(_completionPercentage * 100).round()}%',
              style: AppTextStyles.headingMedium.copyWith(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '50 %',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '0 %',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Chart bars
        SizedBox(
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_weeklyChart.length, (index) {
              final progress = _weeklyChart[index];
              final isCurrentWeek = index == _weeklyChart.length - 1;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 40,
                    height: progress * 150,
                    decoration: BoxDecoration(
                      color: isCurrentWeek 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        
        // Chart labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_weeklyChart.length, (index) {
            return Text(
              'Sem ${index + 1}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        
        Center(
          child: Text(
            'Últimas 4 semanas',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Has mantenido este hábito por $_currentStreak días seguidos. ¡Buen trabajo! ¿Quieres agregar un recordatorio para mejorar tu constancia?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeFrequencyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement change frequency functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionalidad de cambiar frecuencia próximamente'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Cambiar frecuencia',
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _lastCompletedDateLabel() {
    final date = widget.userHabit.lastCompletedAt;
    if (date == null) return 'Sin registros';
    final formatter = DateFormat('EEEE, d MMMM', 'es_ES');
    return formatter.format(date);
  }
  Future<void> _refreshFromRemote() async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Fetch logs for current week for this user_habit
      final logsWeek = await supabase
          .from('user_habit_logs')
          .select('user_habit_id, completed_at, status')
          .eq('user_habit_id', widget.userHabit.id)
          .eq('status', 'completed')
          .gte('completed_at', startOfWeek.toIso8601String().split('T')[0])
          .lte('completed_at', endOfWeek.toIso8601String().split('T')[0]);

      // Map of day index (0=Mon .. 6=Sun) to completion
      final dayCompleted = List<bool>.filled(7, false);
      for (final log in logsWeek) {
        final completedAt = DateTime.parse(log['completed_at'] as String);
        final idx = (completedAt.weekday - 1).clamp(0, 6);
        dayCompleted[idx] = true;
      }

      // Expected days this week based on frequency
      final expectedDays = _expectedDaysThisWeek();
      final completedDays = dayCompleted.where((e) => e).length;
      final completionPct = expectedDays > 0 ? completedDays / expectedDays : 0.0;

      // Compute 4-week chart for this habit
      final chart = <double>[];
      for (int i = 3; i >= 0; i--) {
        final start = startOfWeek.subtract(Duration(days: i * 7));
        final end = start.add(const Duration(days: 6));
        final logs = await supabase
            .from('user_habit_logs')
            .select('completed_at, status')
            .eq('user_habit_id', widget.userHabit.id)
            .eq('status', 'completed')
            .gte('completed_at', start.toIso8601String().split('T')[0])
            .lte('completed_at', end.toIso8601String().split('T')[0]);

        final completedInWeek = (logs as List).map((e) => DateTime.parse(e['completed_at'] as String).toIso8601String().split('T')[0]).toSet().length;
        final weekExpected = _expectedDaysThisWeek();
        chart.add(weekExpected > 0 ? (completedInWeek / weekExpected).clamp(0.0, 1.0) : 0.0);
      }

      // Streak from UserHabit if available
      final streak = widget.userHabit.streakCount;

      if (mounted) {
        setState(() {
          _weeklyProgress = dayCompleted;
          _completionPercentage = completionPct;
          _weeklyChart = chart;
          _currentStreak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _expectedDaysThisWeek() {
    final freq = widget.userHabit.frequency.toLowerCase();
    if (freq == 'daily' || freq == 'diario') return 7;
    if (freq == 'weekly' || freq == 'semanal') {
      final days = widget.userHabit.frequencyDetails?['days_of_week'] as List<dynamic>?;
      if (days == null) return 0;
      return days.length;
    }
    return 0;
  }
}
