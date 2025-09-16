import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/habit_model.dart';
import '../../../domain/entities/category.dart' as entities;
import '../../../domain/entities/habit.dart';
import '../../../data/datasources/gemini_ai_datasource.dart';
import '../../../data/datasources/calendar_remote_datasource.dart';
import '../../../data/models/calendar_event_model.dart';
import '../../../data/datasources/calendar_service.dart';
import '../../../data/datasources/notification_service.dart';
import '../../../data/datasources/ai_advice_remote_datasource.dart';
import '../../../data/models/ai_advice_model.dart';
import '../../../domain/entities/ai_advice.dart';

class NewHabitScreen extends StatefulWidget {
  final String? prefilledHabitName;
  final String? prefilledCategoryId;
  final String? prefilledDescription;

  const NewHabitScreen({
    Key? key,
    this.prefilledHabitName,
    this.prefilledCategoryId,
    this.prefilledDescription,
  }) : super(key: key);

  @override
  State<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends State<NewHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _habitNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notificationController = TextEditingController(
    text: 'Recordatorio personalizado',
  );
  final _customReminderController = TextEditingController();

  List<Habit> _availableHabits = [];
  List<entities.Category> _categories = [];
  List<Habit> _filteredHabits = [];

  String? _selectedCategoryId;
  String _selectedFrequency = 'Diario';
  String _selectedDifficulty = 'Fácil';
  TimeOfDay? _selectedTime;
  int _estimatedDuration = 15; // en minutos
  bool _suggestedSchedule = false;
  bool _geminiSuggestions = true;
  bool _isPublic = false; // Siempre privado por defecto
  DateTime? _startDate;
  DateTime? _endDate;
  List<bool> _selectedDays = List.generate(7, (index) => true); // Días de la semana seleccionados
  final TextEditingController _customDurationController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool _isLoading = false;
  bool _isDescriptionEditable = true;
  
  // Gemini AI variables
  late final GeminiAIDataSource _geminiDataSource;
  late final AIAdviceRemoteDataSource _aiAdviceDataSource;
  Map<String, dynamic>? _geminiSuggestionData;
  bool _isLoadingGeminiSuggestions = false;
  String? _geminiError;
  
  // Calendar integration with notifications
  CalendarService? _calendarService;

  final List<String> _frequencyOptions = [
    'Diario',
    'Semanal',
    'Mensual',
    'Personalizado',
  ];

  final List<String> _difficultyOptions = ['Fácil', 'Medio', 'Difícil'];

  final List<int> _durationOptions = [5, 10, 15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _geminiDataSource = GeminiAIDataSourceImpl();
    _aiAdviceDataSource = AIAdviceRemoteDataSourceImpl(
      supabaseClient: Supabase.instance.client,
    );
    _initializeCalendarService();
    _loadData();
    _setupPrefilledData();
    _habitNameController.addListener(_onHabitNameChanged);
  }
  
  Future<void> _initializeCalendarService() async {
    final calendarDataSource = CalendarRemoteDataSourceImpl();
    final notificationService = NotificationServiceImpl();
    
    _calendarService = CalendarServiceImpl(
      calendarDataSource: calendarDataSource,
      notificationService: notificationService,
    );
    
    await _calendarService!.initialize();
  }

  void _setupPrefilledData() {
    if (widget.prefilledHabitName != null) {
      _habitNameController.text = widget.prefilledHabitName!;
    }
    if (widget.prefilledCategoryId != null) {
      _selectedCategoryId = widget.prefilledCategoryId;
    }
    if (widget.prefilledDescription != null) {
      _descriptionController.text = widget.prefilledDescription!;
    }
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([_loadHabits(), _loadCategories()]);
    } catch (e) {
      _showErrorSnackBar('Error al cargar datos: $e');
    }
  }

  Future<void> _loadHabits() async {
    final user = Supabase.instance.client.auth.currentUser;

    // Cargar hábitos públicos y los privados del usuario actual
    final response = await Supabase.instance.client
        .from('habits')
        .select('*')
        .eq('is_active', true)
        .or('is_public.eq.true,created_by.eq.${user?.id ?? ""}')
        .order('name');

    setState(() {
      _availableHabits = (response as List)
          .map((json) => HabitModel.fromJson(json))
          .cast<Habit>()
          .toList();
      _filteredHabits = _availableHabits;
    });
  }

  Future<void> _loadCategories() async {
    final response = await Supabase.instance.client
        .from('categories')
        .select('*')
        .order('name');

    setState(() {
      _categories = (response as List).map<entities.Category>((json) {
        final model = CategoryModel.fromJson(json);
        return entities.Category(
          id: model.id,
          name: model.name,
          description: model.description,
          iconName: model.iconName,
          color: model.color,
          createdAt: model.createdAt,
          updatedAt: model.updatedAt,
        );
      }).toList();
    });
  }

  void _onHabitNameChanged() {
    final query = _habitNameController.text.toLowerCase();
    setState(() {
      _filteredHabits = _availableHabits
          .where((habit) => habit.name.toLowerCase().contains(query))
          .toList();
    });

    // Check if habit name matches existing habit
    if (query.isEmpty) {
      setState(() {
        _selectedCategoryId = null;
        _descriptionController.clear();
        _isDescriptionEditable = true;
      });
      return;
    }

    // Buscar hábito que coincida con el nombre
    final matchingHabits = _availableHabits
        .where((habit) => habit.name.toLowerCase() == query)
        .toList();

    if (matchingHabits.isNotEmpty) {
      final matchingHabit = matchingHabits.first;
      setState(() {
        _selectedCategoryId = matchingHabit.categoryId;
        _descriptionController.text = matchingHabit.description ?? '';
        _isDescriptionEditable = false; // No editable si coincide
      });
    } else {
      setState(() {
        _isDescriptionEditable = true; // Editable si no coincide
      });
    }
  }

  Future<void> _generateGeminiSuggestions() async {
    if (_habitNameController.text.isEmpty) return;

    setState(() {
      _isLoadingGeminiSuggestions = true;
      _geminiError = null;
    });

    try {
      final categoryName = _selectedCategoryId != null
          ? _categories.where((c) => c.id == _selectedCategoryId).isNotEmpty
              ? _categories.firstWhere((c) => c.id == _selectedCategoryId).name
              : null
          : null;

      final suggestions = await _geminiDataSource.generateHabitSuggestions(
        habitName: _habitNameController.text,
        category: categoryName,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        userGoals: 'Mejorar bienestar y crear hábitos saludables',
      );

      setState(() {
        _geminiSuggestionData = suggestions;
        _isLoadingGeminiSuggestions = false;
        
        // Aplicar sugerencias automáticamente a los campos del formulario
        
        // 1. Nombre optimizado del hábito
        if (suggestions['optimizedName'] != null && suggestions['optimizedName'].toString().isNotEmpty) {
          _habitNameController.text = suggestions['optimizedName'].toString();
        }
        
        // 2. Duración sugerida
        if (suggestions['suggestedDuration'] != null) {
          final duration = int.tryParse(suggestions['suggestedDuration'].toString());
          if (duration != null) {
            _estimatedDuration = duration;
            _customDurationController.text = duration.toString();
          }
        }
        
        // 3. Dificultad
        if (suggestions['difficulty'] != null) {
          final difficulty = suggestions['difficulty'].toString();
          if (['fácil', 'medio', 'difícil'].contains(difficulty.toLowerCase())) {
            _selectedDifficulty = difficulty.toLowerCase() == 'fácil' ? 'Fácil' :
                                 difficulty.toLowerCase() == 'medio' ? 'Medio' : 'Difícil';
          }
        }
        
        // 4. Frecuencia (si está disponible)
        if (suggestions['frequency'] != null) {
          final frequency = suggestions['frequency'].toString().toLowerCase();
          if (frequency.contains('diario') || frequency.contains('daily')) {
            // Activar todos los días de la semana
            _selectedDays = List.generate(7, (index) => true);
          } else if (frequency.contains('semanal') || frequency.contains('weekly')) {
            // Activar solo algunos días
            _selectedDays = [true, false, true, false, true, false, false];
          }
        }
        
        // 5. Horario sugerido (si está disponible)
        if (suggestions['bestTimes'] != null && suggestions['bestTimes'] is List) {
          final bestTimes = suggestions['bestTimes'] as List;
          if (bestTimes.isNotEmpty) {
            final timeString = bestTimes.first.toString();
            // Intentar parsear el horario (formato HH:MM)
            final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeString);
            if (timeMatch != null) {
              final hour = int.tryParse(timeMatch.group(1)!);
              final minute = int.tryParse(timeMatch.group(2)!);
              if (hour != null && minute != null) {
                _selectedTime = TimeOfDay(hour: hour, minute: minute);
              }
            }
          }
        }
        
        // 6. Mensaje motivacional como descripción (si no hay descripción)
        if (_descriptionController.text.isEmpty && suggestions['motivation'] != null) {
          _descriptionController.text = suggestions['motivation'].toString();
        }
      });

      // Guardar el consejo en la base de datos
      await _saveAdviceToDatabase(suggestions);
      
    } catch (e) {
      setState(() {
        _geminiError = e.toString();
        _isLoadingGeminiSuggestions = false;
      });
    }
  }

  Future<void> _saveAdviceToDatabase(Map<String, dynamic> suggestions) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Extraer el consejo del campo 'advice' de las sugerencias
      final adviceText = suggestions['advice']?.toString();
      if (adviceText == null || adviceText.isEmpty) return;

      final advice = AIAdviceModel(
        id: '', // Se generará automáticamente
        userId: user.id,
        habitName: _habitNameController.text,
        adviceText: adviceText,
        adviceType: 'habit_creation',
        source: 'gemini_ai',
        isApplied: false,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _aiAdviceDataSource.saveAdvice(advice);
    } catch (e) {
      // Error silencioso - no interrumpir el flujo principal
      print('Error al guardar consejo: $e');
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showErrorSnackBar('Usuario no autenticado');
        return;
      }

      // Buscar si el hábito ya existe en la tabla habits
      final matchingHabits = _availableHabits
          .where(
            (h) =>
                h.name.toLowerCase() == _habitNameController.text.toLowerCase(),
          )
          .toList();
      final existingHabit = matchingHabits.isNotEmpty
          ? matchingHabits.first
          : null;

      String habitId;

      if (existingHabit != null) {
        // Usar hábito existente
        habitId = existingHabit.id;
      } else {
        // Crear nuevo hábito custom en la tabla habits
        final habitData = {
          'name': _habitNameController.text,
          'description': _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          'category_id': _selectedCategoryId,
          'created_by': user.id, // Marcar quién creó este hábito
          'is_public': _isPublic, // Si el usuario quiere que sea público
          'difficulty_level': _selectedDifficulty.toLowerCase(),
          'estimated_duration': _estimatedDuration,
          'is_active': true,
        };

        final habitResponse = await Supabase.instance.client
            .from('habits')
            .insert(habitData)
            .select('id')
            .single();

        habitId = habitResponse['id'] as String;
      }

      // Crear el user_habit (relación usuario-hábito)
      final userHabitData = {
        'user_id': user.id,
        'habit_id': habitId,
        'frequency': _selectedFrequency.toLowerCase(),
        'frequency_details': _buildFrequencyDetails(),
        'scheduled_time': _suggestedSchedule && _selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        'notifications_enabled': true,
        'notification_time': _selectedTime != null
            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
            : '09:00:00',
        'start_date':
            _startDate?.toIso8601String().split('T')[0] ??
            DateTime.now().toIso8601String().split('T')[0],
        'end_date': _endDate?.toIso8601String().split('T')[0],
        'is_active': true,
        'custom_reminder': _customReminderController.text.isNotEmpty
            ? _customReminderController.text
            : null,
      };

      final userHabitResponse = await Supabase.instance.client
          .from('user_habits')
          .insert(userHabitData)
          .select('id')
          .single();

      final userHabitId = userHabitResponse['id'] as String;

      // Crear eventos de calendario si se seleccionaron fechas
      await _createCalendarEvents(habitId, userHabitId, user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hábito y calendario guardados exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Retorna true para indicar éxito
      }
    } catch (e) {
      _showErrorSnackBar('Error al guardar hábito: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _buildFrequencyDetails() {
    switch (_selectedFrequency) {
      case 'Semanal':
        return {
          'days_of_week': [1, 2, 3, 4, 5],
        }; // Lunes a Viernes por defecto
      case 'Mensual':
        return {'day_of_month': 1};
      default:
        return {};
    }
  }

  Future<void> _createCalendarEvents(String habitId, String userHabitId, String userId) async {
    if (_startDate == null) return;

    try {
      final endDate = _endDate ?? _startDate!.add(const Duration(days: 30)); // Default 30 days if no end date
      final currentDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final finalDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      final events = <Map<String, dynamic>>[];
      
      // Generate events based on frequency
      DateTime iterDate = currentDate;
      while (iterDate.isBefore(finalDate) || iterDate.isAtSameMomentAs(finalDate)) {
        bool shouldCreateEvent = false;
        
        switch (_selectedFrequency.toLowerCase()) {
          case 'diario':
            shouldCreateEvent = true;
            break;
          case 'semanal':
            // Create event on weekdays (Monday to Friday)
            shouldCreateEvent = iterDate.weekday >= 1 && iterDate.weekday <= 5;
            break;
          case 'mensual':
            // Create event on the same day of each month
            shouldCreateEvent = iterDate.day == _startDate!.day;
            break;
          default:
            shouldCreateEvent = true;
        }
        
        if (shouldCreateEvent) {
          final eventData = {
            'user_id': userId,
            'habit_id': habitId,
            'title': _habitNameController.text,
            'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
            'start_date': iterDate.toIso8601String().split('T')[0],
            'start_time': _selectedTime != null 
                ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
                : '09:00:00',
            'end_time': _selectedTime != null 
                ? _calculateEndTime(_selectedTime!, _estimatedDuration)
                : _calculateEndTime(const TimeOfDay(hour: 9, minute: 0), _estimatedDuration),
            'recurrence_type': _selectedFrequency.toLowerCase(),
            'notification_enabled': true,
            'notification_minutes': 15, // 15 minutes before
            'is_completed': false,
          };
          
          events.add(eventData);
        }
        
        // Move to next date based on frequency
        switch (_selectedFrequency.toLowerCase()) {
          case 'diario':
            iterDate = iterDate.add(const Duration(days: 1));
            break;
          case 'semanal':
            iterDate = iterDate.add(const Duration(days: 1));
            break;
          case 'mensual':
            iterDate = DateTime(iterDate.year, iterDate.month + 1, iterDate.day);
            break;
          default:
            iterDate = iterDate.add(const Duration(days: 1));
        }
      }
      
      // Create events with notifications using the calendar service
      if (events.isNotEmpty && _calendarService != null) {
        for (final eventData in events) {
          try {
            await _calendarService!.createCalendarEventWithNotification(eventData);
          } catch (e) {
            print('Error creating calendar event: $e');
            // Continue with other events even if one fails
          }
        }
      }
      
    } catch (e) {
      print('Error creating calendar events: $e');
      // Don't throw error to avoid breaking the habit creation
    }
  }
  
  String _calculateEndTime(TimeOfDay startTime, int durationMinutes) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = startMinutes + durationMinutes;
    final endHour = (endMinutes ~/ 60) % 24;
    final endMinute = endMinutes % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}:00';
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  DateTime? _parseDate(String dateString) {
    try {
      // Remover espacios y validar formato básico
      dateString = dateString.trim();
      if (!RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(dateString)) {
        return null;
      }

      final parts = dateString.split('/');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;
      if (day < 1 || day > 31) return null;
      if (month < 1 || month > 12) return null;
      if (year < 2024 || year > 2030) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _navigateToCalendar() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _startDateController.text = _formatDate(picked.start);
        _endDateController.text = _formatDate(picked.end);
      });
    }
  }

  @override
  void dispose() {
    _habitNameController.dispose();
    _descriptionController.dispose();
    _notificationController.dispose();
    _customDurationController.dispose();
    _customReminderController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
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
          'Nuevo Hábito',
          style: AppTextStyles.headingMedium.copyWith(color: Colors.black),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHabitNameField(),
              const SizedBox(height: 24),
              _buildCategoryDropdown(),
              const SizedBox(height: 24),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildFrequencySection(),
              const SizedBox(height: 24),
              _buildScheduleToggle(),
              const SizedBox(height: 24),
              _buildAISuggestionsSection(),
              const SizedBox(height: 24),
              if (!_suggestedSchedule) _buildTimePickerField(),
              if (!_suggestedSchedule) const SizedBox(height: 20),
              if (!_suggestedSchedule) _buildDurationField(),
              if (!_suggestedSchedule) const SizedBox(height: 24),
              _buildDifficultySection(),
              const SizedBox(height: 20),
              _buildCustomReminderField(),
              const SizedBox(height: 20),
              _buildCalendarButton(),
              const SizedBox(height: 28),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre del hábito',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<Habit>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Habit>.empty();
            }
            return _filteredHabits.where((habit) {
              return habit.name.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          displayStringForOption: (Habit option) => option.name,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Sincronizar con nuestro controlador
            if (controller.text != _habitNameController.text) {
              controller.text = _habitNameController.text;
            }

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (value) {
                _habitNameController.text = value;
              },
              decoration: InputDecoration(
                hintText: 'Dormir antes de las 10 pm',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre del hábito';
                }
                return null;
              },
            );
          },
          onSelected: (Habit selection) {
            _habitNameController.text = selection.name;
            if (selection.categoryId != null) {
              setState(() {
                _selectedCategoryId = selection.categoryId;
              });
            }
            if (selection.description?.isNotEmpty == true) {
              _descriptionController.text = selection.description!;
            }
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    // Validar que el valor seleccionado exista en la lista de categorías
    final validSelectedId =
        _selectedCategoryId != null &&
            _categories.any((cat) => cat.id == _selectedCategoryId)
        ? _selectedCategoryId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: validSelectedId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          hint: const Text('Sueño'),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor selecciona una categoría';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    // Solo mostrar descripción si es editable (hábito no existe)
    if (!_isDescriptionEditable) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción (opcional)',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          enabled: _isDescriptionEditable,
          decoration: InputDecoration(
            hintText: 'Describe tu hábito...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            fillColor: _isDescriptionEditable ? null : Colors.grey[50],
            filled: !_isDescriptionEditable,
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Frecuencia',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _selectedFrequency,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _frequencyOptions.map((frequency) {
            final isSelected = _selectedFrequency == frequency;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFrequency = frequency;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  frequency,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Horario sugerido por IA',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'La IA sugerirá horarios y duración automáticamente',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _suggestedSchedule,
          onChanged: (value) {
            setState(() {
              _suggestedSchedule = value;
              if (value) {
                // Si se activa horario sugerido, también activar sugerencias IA
                _geminiSuggestions = true;
                // Generar sugerencias automáticamente
                _generateGeminiSuggestions();
              }
            });
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildAISuggestionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sugerencias',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Recomendaciones personalizadas para tu hábito',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingGeminiSuggestions)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generando sugerencias inteligentes...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (_geminiError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error al generar sugerencias',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _geminiError!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _generateGeminiSuggestions,
                    child: Text(
                      'Reintentar',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_geminiSuggestionData != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_geminiSuggestionData!['bestTime'] != null)
                    _buildSuggestionItem(
                      'Mejor horario',
                      _geminiSuggestionData!['bestTime'].toString(),
                      Icons.schedule,
                    ),
                  if (_geminiSuggestionData!['suggestedDuration'] != null)
                    _buildSuggestionItem(
                      'Duración sugerida',
                      '${_geminiSuggestionData!['suggestedDuration']} minutos',
                      Icons.timer,
                    ),
                  if (_geminiSuggestionData!['difficulty'] != null)
                    _buildSuggestionItem(
                      'Dificultad',
                      _geminiSuggestionData!['difficulty'].toString(),
                      Icons.trending_up,
                    ),
                  if (_geminiSuggestionData!['tips'] != null)
                    _buildSuggestionItem(
                      'Consejo',
                      _geminiSuggestionData!['tips'].toString(),
                      Icons.lightbulb_outline,
                    ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.psychology,
                    color: AppColors.primary.withOpacity(0.7),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Obtén sugerencias personalizadas',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Activa las sugerencias para recibir recomendaciones de horarios, duración y consejos basados en tu hábito',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeminiSuggestionsPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sugerencias',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingGeminiSuggestions)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Generando sugerencias...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            )
          else if (_geminiError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: $_geminiError',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_geminiSuggestionData != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_geminiSuggestionData!['bestTime'] != null)
                  _buildSuggestionItem(
                    'Mejor horario',
                    _geminiSuggestionData!['bestTime'].toString(),
                    Icons.schedule,
                  ),
                if (_geminiSuggestionData!['suggestedDuration'] != null)
                  _buildSuggestionItem(
                    'Duración sugerida',
                    '${_geminiSuggestionData!['suggestedDuration']} minutos',
                    Icons.timer,
                  ),
                if (_geminiSuggestionData!['difficulty'] != null)
                  _buildSuggestionItem(
                    'Dificultad',
                    _geminiSuggestionData!['difficulty'].toString(),
                    Icons.trending_up,
                  ),
                if (_geminiSuggestionData!['tips'] != null)
                  _buildSuggestionItem(
                    'Consejo',
                    _geminiSuggestionData!['tips'].toString(),
                    Icons.lightbulb_outline,
                  ),
              ],
            )
          else
            Text(
              'Activa el horario sugerido para obtener recomendaciones personalizadas',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horario',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? TimeOfDay.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedTime = picked;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  _selectedTime?.format(context) ?? 'Seleccionar horario',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _selectedTime != null
                        ? Colors.black
                        : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duración estimada',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _customDurationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Minutos',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final duration = int.tryParse(value);
                    if (duration != null) {
                      setState(() {
                        _estimatedDuration = duration;
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                'O selecciona:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _durationOptions.map((duration) {
            final isSelected = _estimatedDuration == duration;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _estimatedDuration = duration;
                  _customDurationController.text = duration.toString();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${duration}min',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nivel de dificultad',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _difficultyOptions.map((difficulty) {
            final isSelected = _selectedDifficulty == difficulty;
            Color difficultyColor = AppColors.primary;
            if (difficulty == 'Fácil') difficultyColor = Colors.green;
            if (difficulty == 'Medio') difficultyColor = Colors.orange;
            if (difficulty == 'Difícil') difficultyColor = Colors.red;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDifficulty = difficulty;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? difficultyColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? difficultyColor : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  difficulty,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomReminderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recordatorio personalizado',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _customReminderController,
          decoration: InputDecoration(
            hintText: 'Ej: Recuerda beber agua antes de dormir',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Período del hábito',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha de inicio',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      hintText: 'DD/MM/AAAA',
                      prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa la fecha de inicio';
                      }
                      final date = _parseDate(value);
                      if (date == null) {
                        return 'Formato inválido (DD/MM/AAAA)';
                      }
                      if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                        return 'La fecha no puede ser anterior a hoy';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final date = _parseDate(value);
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha de fin (opcional)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _endDateController,
                    decoration: InputDecoration(
                      hintText: 'DD/MM/AAAA',
                      prefixIcon: Icon(Icons.event, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final date = _parseDate(value);
                        if (date == null) {
                          return 'Formato inválido (DD/MM/AAAA)';
                        }
                        if (_startDate != null && date.isBefore(_startDate!)) {
                          return 'Debe ser posterior a la fecha de inicio';
                        }
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final date = _parseDate(value);
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                      } else {
                        setState(() {
                          _endDate = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Formato: DD/MM/AAAA (ej: 25/01/2024). Si no especificas fecha de fin, el hábito durará 30 días.',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveHabit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Guardar hábito',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
