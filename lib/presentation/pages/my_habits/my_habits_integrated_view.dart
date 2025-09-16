import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/core/constants/app_strings.dart';
import 'package:vive_good_app/core/constants/app_constants.dart';
import 'package:vive_good_app/domain/entities/habit.dart';
import 'package:vive_good_app/presentation/blocs/habit/habit_bloc.dart';
import 'package:vive_good_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:vive_good_app/presentation/blocs/auth/auth_state.dart';
import 'package:vive_good_app/presentation/blocs/habit/habit_state.dart';
import 'package:vive_good_app/presentation/widgets/custom_text_field.dart';
import 'package:vive_good_app/presentation/blocs/habit/habit_event.dart';
import 'package:vive_good_app/presentation/widgets/habit_card.dart';

class MyHabitsIntegratedView extends StatefulWidget {
  const MyHabitsIntegratedView({super.key});

  @override
  State<MyHabitsIntegratedView> createState() => _MyHabitsIntegratedViewState();
}

class _MyHabitsIntegratedViewState extends State<MyHabitsIntegratedView> {
  final TextEditingController _habitNameController = TextEditingController();
  final TextEditingController _habitDescriptionController =
      TextEditingController();
  String? _selectedCategory;
  String? _selectedFrequency;
  DateTime? _selectedReminderTime;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<HabitBloc>().add(
        LoadDashboardHabits(userId: authState.user.id, date: DateTime.now()),
      );
    }
  }

  @override
  void dispose() {
    _habitNameController.dispose();
    _habitDescriptionController.dispose();
    super.dispose();
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.filterHabits,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: AppStrings.category,
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items: AppConstants.habitCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: AppStrings.frequency,
                  border: OutlineInputBorder(),
                ),
                value: _selectedFrequency,
                items: AppConstants.habitFrequencies
                    .map(
                      (frequency) => DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  context.read<HabitBloc>().add(
                    FilterHabitsByCategory(_selectedCategory),
                  );
                  Navigator.pop(context);
                },
                child: const Text(AppStrings.applyFilters),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddHabitModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.addNewHabit,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextField(
                    controller: _habitNameController,
                    hintText: AppStrings.enterHabitName,
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextField(
                    controller: _habitDescriptionController,
                    hintText: AppStrings.enterHabitDescription,
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: AppStrings.category,
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategory,
                    items: AppConstants.habitCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: AppStrings.frequency,
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedFrequency,
                    items: AppConstants.habitFrequencies
                        .map(
                          (frequency) => DropdownMenuItem(
                            value: frequency,
                            child: Text(frequency),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ListTile(
                    title: Text(
                      _selectedReminderTime == null
                          ? AppStrings.selectReminderTime
                          : '${_selectedReminderTime!.hour.toString().padLeft(2, '0')}:${_selectedReminderTime!.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedReminderTime = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            picked.hour,
                            picked.minute,
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_habitNameController.text.isNotEmpty &&
                          _selectedCategory != null &&
                          _selectedFrequency != null) {
                        final newHabit = Habit(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _habitNameController.text,
                          description: _habitDescriptionController.text,
                          categoryId: _selectedCategory!,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        context.read<HabitBloc>().add(AddHabit(newHabit));
                        Navigator.pop(context);
                        _habitNameController.clear();
                        _habitDescriptionController.clear();
                        setState(() {
                          _selectedCategory = null;
                          _selectedFrequency = null;
                          _selectedReminderTime = null;
                        });
                      }
                    },
                    child: const Text(AppStrings.saveHabit),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'Salud':
        return Icons.favorite;
      case 'Ejercicio':
        return Icons.fitness_center;
      case 'Estudio':
        return Icons.book;
      case 'Trabajo':
        return Icons.work;
      case 'Finanzas':
        return Icons.account_balance_wallet;
      case 'Hogar':
        return Icons.home;
      case 'Desarrollo Personal':
        return Icons.self_improvement;
      case 'Social':
        return Icons.people;
      case 'Creatividad':
        return Icons.lightbulb;
      case 'Relajación':
        return Icons.spa;
      default:
        return Icons.category; // Default icon
    }
  }

  Color _getIconColor(String? colorName) {
    try {
      if (colorName != null && colorName.startsWith('0x')) {
        return Color(int.parse(colorName));
      }
    } catch (e) {
      // Fallback to default colors
    }
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'brown':
        return Colors.brown;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'amber':
        return Colors.amber;
      case 'lightBlue':
        return Colors.lightBlue;
      default:
        return Colors.grey; // Default color
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myHabits),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddHabitModal,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFiltersModal,
          ),
        ],
      ),
      body: BlocBuilder<HabitBloc, HabitState>(
        builder: (context, state) {
          if (state is HabitLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HabitLoaded) {
            if (state.userHabits.isEmpty) {
              return Center(
                child: Text(
                  AppStrings.noHabitsYet,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              );
            }
            return ListView.builder(
              itemCount: state.userHabits.length,
              itemBuilder: (context, index) {
                final habit = state.userHabits[index];
                return HabitCard(
                  habit: habit,
                  iconData: _getIconData(habit.habit!.categoryId),
                  iconColor: _getIconColor(habit.habit!.categoryId),
                  onEdit: () {
                    // Implement edit functionality
                  },
                  onDelete: () {
                    context.read<HabitBloc>().add(DeleteHabit(habit.id));
                  },
                );
              },
            );
          } else if (state is HabitError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text(AppStrings.somethingWentWrong));
        },
      ),
    );
  }
}
