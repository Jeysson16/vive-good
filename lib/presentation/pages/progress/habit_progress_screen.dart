import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  List<bool> _weeklyProgress = [true, true, false, false, false, true, true]; // Mock data
  double _completionPercentage = 0.66; // Mock data
  int _currentStreak = 5; // Mock data
  List<double> _weeklyChart = [0.4, 0.6, 1.0, 0.5, 0.8]; // Mock data for 4 weeks

  @override
  void initState() {
    super.initState();
    _loadHabitProgress();
  }

  void _loadHabitProgress() {
    // Load habit progress data immediately - no artificial delay needed
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(_completionPercentage * 7).round()}/7 días',
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
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    habitName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Miércoles, 10 julio',
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
        final isToday = index == 3; // Wednesday as today for demo
        
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
        Container(
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
}