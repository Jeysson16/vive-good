import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/habit_model.dart';
import '../../../domain/entities/category.dart' as entities;
import '../../../domain/entities/habit.dart';
import '../../../data/datasources/gemini_ai_datasource.dart';
import '../../../data/datasources/calendar_remote_datasource.dart';
import '../../../data/datasources/calendar_service.dart';
import '../../../data/datasources/notification_service.dart';
import '../../../data/datasources/ai_advice_remote_datasource.dart';
import '../../../data/models/ai_advice_model.dart';
import '../../../domain/entities/user_habit.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/habit/habit_bloc.dart';
import '../../blocs/habit/habit_event.dart';
import '../../../data/services/notification_service.dart' as notification_service;

class NewHabitScreen extends StatefulWidget {
  final String? prefilledHabitName;
  final String? prefilledCategoryId;
  final String? prefilledDescription;
  final String? habitId; // ID del hábito a editar
  final bool isEditMode; // Indica si está en modo edición
  final UserHabit? userHabitToEdit; // Datos del hábito a editar

  const NewHabitScreen({
    super.key,
    this.prefilledHabitName,
    this.prefilledCategoryId,
    this.prefilledDescription,
    this.habitId,
    this.isEditMode = false,
    this.userHabitToEdit,
  });

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
  List<bool> _selectedDays = List.generate(
    7,
    (index) => true,
  ); // Días de la semana seleccionados
  final TextEditingController _customDurationController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool _isLoading = false;
  bool _isDescriptionEditable = true;
  bool _isLoadingHabitData = false; // Para mostrar overlay de carga
  String? _editingHabitId; // ID del hábito que se está editando

  // Gemini AI variables
  late final GeminiAIDataSource _geminiDataSource;
  late final AIAdviceRemoteDataSource _aiAdviceDataSource;
  Map<String, dynamic>? _geminiSuggestionData;
  bool _isLoadingGeminiSuggestions = false;
  bool _isGeneratingSuggestions = false;
  String? _geminiError;

  // Calendar integration with notifications
  CalendarService? _calendarService;
  bool _isInitializingCalendarService = false;

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
    
    // Si está en modo edición, cargar los datos del hábito
    if (widget.isEditMode && widget.userHabitToEdit != null) {
      _editingHabitId = widget.userHabitToEdit!.id;
      _loadHabitDataFromUserHabit(widget.userHabitToEdit!);
    } else if (widget.isEditMode && widget.habitId != null) {
      _editingHabitId = widget.habitId;
      _loadHabitForEditing(widget.habitId!);
    } else {
      _setupPrefilledData();
    }
    
    // Establecer fecha de inicio por defecto a hoy si no está definida
    if (_startDate == null) {
      final today = DateTime.now();
      _startDate = DateTime(today.year, today.month, today.day);
      _startDateController.text = _formatDate(_startDate!);
    }

    _habitNameController.addListener(_onHabitNameChanged);
  }

  Future<void> _initializeCalendarService() async {
    setState(() {
      _isInitializingCalendarService = true;
    });
    
    try {
      print('DEBUG: Inicializando CalendarService...');
      
      final calendarDataSource = CalendarRemoteDataSourceImpl();
      final notificationService = NotificationServiceImpl();

      _calendarService = CalendarServiceImpl(
        calendarDataSource: calendarDataSource,
        notificationService: notificationService,
      );

      await _calendarService!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout al inicializar el servicio de calendario');
        },
      );
      
      print('DEBUG: CalendarService inicializado correctamente');
    } catch (e) {
      print('DEBUG: Error al inicializar CalendarService: $e');
      _calendarService = null; // Asegurar que quede como null si falla
      
      // No lanzar el error para no interrumpir la carga de la pantalla
      // El usuario verá que las funciones de IA están deshabilitadas
    } finally {
      setState(() {
        _isInitializingCalendarService = false;
      });
    }
  }

  /// Verifica si el CalendarService está disponible y listo para usar
  bool _isCalendarServiceAvailable() {
    try {
      // Verificar que el servicio no sea null
      if (_calendarService == null) {
        print('DEBUG: CalendarService es null');
        return false;
      }

      // Verificar que el usuario esté autenticado (requisito para el servicio)
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('DEBUG: Usuario no autenticado - CalendarService no disponible');
        return false;
      }

      print('DEBUG: CalendarService disponible y usuario autenticado');
      return true;
    } catch (e) {
      print('DEBUG: Error al verificar CalendarService: $e');
      return false;
    }
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

  Future<void> _loadHabitForEditing(String habitId) async {
    setState(() {
      _isLoadingHabitData = true;
    });

    try {
      // Cargar datos del hábito específico desde user_habits
      final response = await Supabase.instance.client
          .from('user_habits')
          .select('''
            *,
            habits!inner(*),
            categories!inner(*)
          ''')
          .eq('id', habitId)
          .single();

      final habitData = response['habits'];
      final categoryData = response['categories'];
      
      // Poblar los campos con los datos del hábito
      setState(() {
        _habitNameController.text = habitData['name'] ?? '';
        _descriptionController.text = habitData['description'] ?? '';
        _selectedCategoryId = habitData['category_id'];
        _selectedFrequency = response['frequency'] ?? 'Diario';
        _selectedDifficulty = habitData['difficulty'] ?? 'Fácil';
        _estimatedDuration = response['duration_minutes'] ?? 15;
        _isPublic = habitData['is_public'] ?? false;
        
        // Configurar fechas si existen
        if (response['start_date'] != null) {
          _startDate = DateTime.parse(response['start_date']);
          _startDateController.text = '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}';
        }
        if (response['end_date'] != null) {
          _endDate = DateTime.parse(response['end_date']);
          _endDateController.text = '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
        }
        
        // Configurar hora de recordatorio si existe
        if (response['reminder_time'] != null) {
          final timeString = response['reminder_time'] as String;
          final timeParts = timeString.split(':');
          if (timeParts.length >= 2) {
            _selectedTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        }
        
        // Configurar días de la semana si existen
        if (response['selected_days'] != null) {
          final daysData = response['selected_days'] as List<dynamic>;
          _selectedDays = List.generate(7, (index) => daysData.contains(index));
        }
      });
        } catch (e) {
      _showErrorSnackBar('Error al cargar datos del hábito: $e');
    } finally {
      setState(() {
        _isLoadingHabitData = false;
      });
    }
  }

  void _loadHabitDataFromUserHabit(UserHabit userHabit) {
    setState(() {
      _isLoadingHabitData = true;
    });

    try {
      // Poblar los campos con los datos del UserHabit
      setState(() {
        _habitNameController.text = userHabit.habit?.name ?? userHabit.customName ?? '';
        _descriptionController.text = userHabit.habit?.description ?? '';
        _selectedCategoryId = userHabit.habit?.categoryId;
        _selectedFrequency = userHabit.frequency;
        _selectedDifficulty = 'Fácil'; // Valor por defecto
        _estimatedDuration = 15; // Valor por defecto
        _isPublic = userHabit.habit?.isPublic ?? false;
        
        // Configurar fechas
        _startDate = userHabit.startDate;
        _startDateController.text = '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}';
        
        if (userHabit.endDate != null) {
          _endDate = userHabit.endDate;
          _endDateController.text = '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
        }
        
        // Configurar hora de recordatorio si existe
        if (userHabit.scheduledTime != null) {
          final timeString = userHabit.scheduledTime!;
          final timeParts = timeString.split(':');
          if (timeParts.length >= 2) {
            _selectedTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        }
        
        // Para días de la semana, usar configuración por defecto basada en frecuencia
        if (_selectedFrequency == 'Diario') {
          _selectedDays = List.generate(7, (index) => true);
        } else {
          _selectedDays = List.generate(7, (index) => false);
        }
      });
    } catch (e) {
      _showErrorSnackBar('Error al cargar datos del hábito: $e');
    } finally {
      setState(() {
        _isLoadingHabitData = false;
      });
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

  Future<String> _getOptimizedCalendarData() async {
    try {
      // Validación más robusta del servicio de calendario
      if (_calendarService == null) {
        print('DEBUG: CalendarService es null');
        return 'Calendario no disponible. Servicio no inicializado.';
      }

      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 7)); // Próximos 7 días

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('DEBUG: Usuario no autenticado en _getOptimizedCalendarData');
        return 'Usuario no autenticado.';
      }

      print('DEBUG: Obteniendo eventos del calendario para usuario: ${user.id}');
      final events = await _calendarService!.getCalendarEvents(
        user.id,
        startDate: now,
        endDate: endDate,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al obtener eventos del calendario');
        },
      );
      
      print('DEBUG: Eventos obtenidos: ${events.length}');

      if (events.isEmpty) {
        return 'Calendario disponible: Sin eventos programados en los próximos 7 días.';
      }

      // Agrupar eventos por día y crear resumen
      final Map<String, List<String>> dailyBusyTimes = {};

      for (final event in events) {
        // Solo procesar eventos que tengan horario definido
        if (event.startTime == null) continue;

        final dayKey = '${event.startTime!.day}/${event.startTime!.month}';
        String timeSlot;

        if (event.endTime != null) {
          timeSlot =
              '${event.startTime!.hour.toString().padLeft(2, '0')}:${event.startTime!.minute.toString().padLeft(2, '0')}-${event.endTime!.hour.toString().padLeft(2, '0')}:${event.endTime!.minute.toString().padLeft(2, '0')}';
        } else {
          timeSlot =
              '${event.startTime!.hour.toString().padLeft(2, '0')}:${event.startTime!.minute.toString().padLeft(2, '0')}';
        }

        if (!dailyBusyTimes.containsKey(dayKey)) {
          dailyBusyTimes[dayKey] = [];
        }
        dailyBusyTimes[dayKey]!.add(timeSlot);
      }

      // Crear resumen optimizado
      final summary = StringBuffer('Horarios ocupados: ');
      dailyBusyTimes.forEach((day, times) {
        summary.write('$day: ${times.join(", ")}; ');
      });

      // Limitar longitud del resumen
      final result = summary.toString();
      return result.length > 200 ? '${result.substring(0, 200)}...' : result;
    } catch (e) {
      print('DEBUG: Error en _getOptimizedCalendarData: $e');
      
      // Manejo específico de diferentes tipos de errores
      if (e.toString().contains('Timeout')) {
        return 'Calendario no disponible. Tiempo de espera agotado.';
      } else if (e.toString().contains('permission')) {
        return 'Calendario no disponible. Sin permisos de acceso.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        return 'Calendario no disponible. Problema de conexión.';
      } else {
        return 'Calendario no disponible. Error: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e.toString()}';
      }
    }
  }

  Future<void> _generateGeminiSuggestionsWithValidation() async {
    print('DEBUG: Iniciando validaciones para sugerencias de IA');
    
    // Validaciones completas antes de generar sugerencias
    if (_habitNameController.text.trim().isEmpty) {
      print('DEBUG: Validación fallida - nombre del hábito vacío');
      setState(() {
        _geminiError = 'Por favor ingresa un nombre para el hábito antes de generar sugerencias';
        // No desactivar el switch automáticamente, solo mostrar el error
      });
      return;
    }

    if (_startDate == null) {
      print('DEBUG: Validación fallida - fecha de inicio no seleccionada');
      setState(() {
        _geminiError = 'Por favor selecciona una fecha de inicio antes de generar sugerencias';
        // No desactivar el switch automáticamente, solo mostrar el error
      });
      return;
    }

    if (!_isCalendarServiceAvailable()) {
      print('DEBUG: Validación fallida - CalendarService no disponible');
      setState(() {
        _geminiError = 'Servicio de calendario no disponible. Intenta reiniciar la aplicación';
        // No desactivar el switch automáticamente, solo mostrar el error
      });
      return;
    }

    print('DEBUG: Todas las validaciones pasaron, generando sugerencias...');
    // Limpiar errores previos antes de generar sugerencias
    setState(() {
      _geminiError = null;
    });
    
    // Si todas las validaciones pasan, generar sugerencias
    await _generateGeminiSuggestions();
  }

  Future<void> _generateGeminiSuggestions() async {
    print('DEBUG: Iniciando _generateGeminiSuggestions');
    if (_habitNameController.text.isEmpty) {
      print('DEBUG: Nombre del hábito vacío, saliendo de _generateGeminiSuggestions');
      return;
    }

    print('DEBUG: Configurando estado de carga para sugerencias');
    setState(() {
      _isLoadingGeminiSuggestions = true;
      _isGeneratingSuggestions = true;
      _geminiError = null;
    });

    try {
      print('DEBUG: Obteniendo categoría seleccionada');
      final categoryName = _selectedCategoryId != null
          ? _categories.where((c) => c.id == _selectedCategoryId).isNotEmpty
                ? _categories
                      .firstWhere((c) => c.id == _selectedCategoryId)
                      .name
                : null
          : null;
      print('DEBUG: Categoría: $categoryName');

      // Obtener datos optimizados del calendario
      print('DEBUG: Obteniendo datos del calendario...');
      final calendarData = await _getOptimizedCalendarData();
      print('DEBUG: Datos del calendario obtenidos: ${calendarData.length} caracteres');

      // Incluir información del calendario en la descripción para la IA
      final enhancedDescription = _descriptionController.text.isNotEmpty
          ? '${_descriptionController.text}. $calendarData'
          : calendarData;
      print('DEBUG: Descripción mejorada preparada');

      print('DEBUG: Llamando a Gemini AI para generar sugerencias...');
      final suggestions = await _geminiDataSource.generateHabitSuggestions(
        habitName: _habitNameController.text,
        category: categoryName,
        description: enhancedDescription,
        userGoals:
            'Mejorar bienestar y crear hábitos saludables considerando horarios disponibles',
      );
      print('DEBUG: Sugerencias recibidas de Gemini AI');

      print('DEBUG: Aplicando sugerencias a los campos del formulario...');
      setState(() {
        _geminiSuggestionData = suggestions;
        _isLoadingGeminiSuggestions = false;
        _isGeneratingSuggestions = false;

        // Aplicar sugerencias automáticamente a los campos del formulario

        // 1. Nombre optimizado del hábito
        if (suggestions['optimizedName'] != null &&
            suggestions['optimizedName'].toString().isNotEmpty) {
          _habitNameController.text = suggestions['optimizedName'].toString();
        }

        // 2. Duración sugerida
        if (suggestions['suggestedDuration'] != null) {
          final duration = int.tryParse(
            suggestions['suggestedDuration'].toString(),
          );
          if (duration != null) {
            _estimatedDuration = duration;
            _customDurationController.text = duration.toString();
          }
        }

        // 3. Dificultad
        if (suggestions['difficulty'] != null) {
          final difficulty = suggestions['difficulty'].toString();
          if ([
            'fácil',
            'medio',
            'difícil',
          ].contains(difficulty.toLowerCase())) {
            _selectedDifficulty = difficulty.toLowerCase() == 'fácil'
                ? 'Fácil'
                : difficulty.toLowerCase() == 'medio'
                ? 'Medio'
                : 'Difícil';
          }
        }

        // 4. Frecuencia (si está disponible)
        if (suggestions['frequency'] != null) {
          final frequency = suggestions['frequency'].toString().toLowerCase();
          if (frequency.contains('diario') || frequency.contains('daily')) {
            // Activar todos los días de la semana
            _selectedDays = List.generate(7, (index) => true);
          } else if (frequency.contains('semanal') ||
              frequency.contains('weekly')) {
            // Activar solo algunos días
            _selectedDays = [true, false, true, false, true, false, false];
          }
        }

        // 5. Horario sugerido (si está disponible)
        if (suggestions['bestTimes'] != null &&
            suggestions['bestTimes'] is List) {
          final bestTimes = suggestions['bestTimes'] as List;
          if (bestTimes.isNotEmpty) {
            final timeString = bestTimes.first.toString();
            // Intentar parsear el horario (formato HH:MM)
            final timeMatch = RegExp(
              r'(\d{1,2}):(\d{2})',
            ).firstMatch(timeString);
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
        if (_descriptionController.text.isEmpty &&
            suggestions['motivation'] != null) {
          _descriptionController.text = suggestions['motivation'].toString();
        }
      });

      // Guardar el consejo en la base de datos
      print('DEBUG: Guardando consejo en la base de datos...');
      await _saveAdviceToDatabase(suggestions);
      print('DEBUG: Sugerencias aplicadas exitosamente');
    } catch (e) {
      print('DEBUG: Error en _generateGeminiSuggestions: $e');
      setState(() {
        // Formatear el error de manera más amigable para el usuario
        String errorMessage = 'Error al generar sugerencias';

        if (e.toString().contains('GenerativeAIException')) {
          errorMessage = 'Servicio de IA temporalmente no disponible';
        } else if (e.toString().contains('Server Error [503]')) {
          errorMessage =
              'El modelo de IA está sobrecargado. Intenta de nuevo en unos minutos';
        } else if (e.toString().contains('UNAVAILABLE')) {
          errorMessage = 'Servicio de IA no disponible temporalmente';
        } else if (e.toString().contains('overloaded')) {
          errorMessage =
              'El servicio está ocupado. Por favor intenta más tarde';
        } else if (e.toString().contains('JSON')) {
          errorMessage = 'Error al procesar la respuesta de la IA';
        } else {
          errorMessage =
              'Error de conexión. Verifica tu internet e intenta de nuevo';
        }

        _geminiError = errorMessage;
        _isLoadingGeminiSuggestions = false;
        _isGeneratingSuggestions = false;
      });

      // Log del error completo para debugging (solo en desarrollo)
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
    }
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showErrorSnackBar('Usuario no autenticado');
        return;
      }

      if (widget.isEditMode && _editingHabitId != null) {
        await _updateExistingHabit(user.id);
      } else {
        await _createNewHabit(user.id);
      }
    } catch (e) {
      _handleSaveError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateExistingHabit(String userId) async {
    // Actualizar el user_habit existente
    final userHabitData = {
      'frequency': _selectedFrequency.toLowerCase(),
      'frequency_details': _buildFrequencyDetails(),
      'scheduled_time': _selectedTime != null
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
      'custom_reminder': _customReminderController.text.isNotEmpty
          ? _customReminderController.text
          : null,
    };

    await Supabase.instance.client
        .from('user_habits')
        .update(userHabitData)
        .eq('id', _editingHabitId!);

    // Actualizar el hábito base si es necesario
    final habitData = {
      'name': _habitNameController.text,
      'description': _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      'category_id': _selectedCategoryId,
      'difficulty_level': _selectedDifficulty.toLowerCase(),
      'estimated_duration': _estimatedDuration,
    };

    // Obtener el habit_id del user_habit
    final userHabitResponse = await Supabase.instance.client
        .from('user_habits')
        .select('habit_id')
        .eq('id', _editingHabitId!)
        .single();

    final habitId = userHabitResponse['habit_id'] as String;

    await Supabase.instance.client
        .from('habits')
        .update(habitData)
        .eq('id', habitId);

    // Reprogramar notificaciones para el hábito actualizado
    print('🔔 [UPDATE_HABIT] Reprogramando notificaciones para userHabitId: $_editingHabitId');
    await _scheduleHabitNotifications(_editingHabitId!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hábito y notificaciones actualizados exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _createNewHabit(String userId) async {

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

        // Verificar si el usuario ya tiene este hábito
        final existingUserHabit = await Supabase.instance.client
            .from('user_habits')
            .select('id')
            .eq('user_id', userId)
            .eq('habit_id', habitId)
            .eq('is_active', true)
            .maybeSingle();

        if (existingUserHabit != null) {
          _showErrorSnackBar(
            'Ya tienes este hábito en tu lista. No puedes agregar hábitos duplicados.',
          );
          return;
        }
      } else {
        // Verificar si el usuario ya tiene un hábito con el mismo nombre
        final existingUserHabitByName = await Supabase.instance.client
            .from('user_habits')
            .select('id, habit_id, habits!inner(name)')
            .eq('user_id', userId)
            .eq('is_active', true)
            .eq('habits.name', _habitNameController.text)
            .maybeSingle();

        if (existingUserHabitByName != null) {
          _showErrorSnackBar(
            'Ya tienes un hábito con este nombre. Elige un nombre diferente.',
          );
          return;
        }

        // Crear nuevo hábito custom en la tabla habits
        final habitData = {
          'name': _habitNameController.text,
          'description': _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          'category_id': _selectedCategoryId,
          'created_by': userId, // Marcar quién creó este hábito
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
        'user_id': userId,
        'habit_id': habitId,
        'frequency': _selectedFrequency.toLowerCase(),
        'frequency_details': _buildFrequencyDetails(),
        'scheduled_time': _selectedTime != null
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

      // NOTA: Ya no creamos múltiples eventos en calendar_events
      // Los eventos se generan dinámicamente desde user_habits usando la frecuencia
      // await _createCalendarEvents(habitId, userHabitId, userId);

      // Programar notificaciones para el hábito recién creado
      print('🔔 [CREATE_HABIT] Programando notificaciones para userHabitId: $userHabitId');
      await _scheduleHabitNotifications(userHabitId);

      if (mounted) {
        // Actualizar el dashboard después de crear el hábito
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<DashboardBloc>().add(
            RefreshDashboardData(
              userId: authState.user.id,
              date: DateTime.now(),
            ),
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hábito y notificaciones configurados exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Retorna true para indicar éxito
      }
  }

  void _handleSaveError(dynamic e) {
    // Manejo específico para errores de duplicación
    if (e.toString().contains(
          'duplicate key value violates unique constraint',
        ) ||
        e.toString().contains('user_habits_user_id_habit_id_key')) {
      _showErrorSnackBar(
        'Ya tienes este hábito en tu lista. No puedes agregar hábitos duplicados.',
      );
    } else if (e.toString().contains('PostgrestException')) {
      _showErrorSnackBar(
        'Error de base de datos. Por favor, intenta nuevamente.',
      );
    } else {
      _showErrorSnackBar(
        'Error al guardar hábito. Por favor, verifica tu conexión e intenta nuevamente.',
      );
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

  Future<void> _createCalendarEvents(
    String habitId,
    String userHabitId,
    String userId,
  ) async {
    print('DEBUG: Iniciando _createCalendarEvents con habitId: $habitId, userHabitId: $userHabitId, userId: $userId');
    
    if (_startDate == null) {
      print('DEBUG: _startDate es null, saliendo de _createCalendarEvents');
      return;
    }

    print('DEBUG: _startDate: $_startDate, _endDate: $_endDate, _selectedFrequency: $_selectedFrequency');
    print('DEBUG: _calendarService disponible: ${_calendarService != null}');

    try {
      final endDate =
          _endDate ??
          _startDate!.add(
            const Duration(days: 30),
          ); // Default 30 days if no end date
      final currentDate = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      final finalDate = DateTime(endDate.year, endDate.month, endDate.day);

      final events = <Map<String, dynamic>>[];

      // Generate events based on frequency
      DateTime iterDate = currentDate;
      while (iterDate.isBefore(finalDate) ||
          iterDate.isAtSameMomentAs(finalDate)) {
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
          // Create proper DateTime objects for start and end times
          final startDateTime = _selectedTime != null
              ? DateTime(
                  iterDate.year,
                  iterDate.month,
                  iterDate.day,
                  _selectedTime!.hour,
                  _selectedTime!.minute,
                )
              : DateTime(
                  iterDate.year,
                  iterDate.month,
                  iterDate.day,
                  9,
                  0,
                );
          
          final endDateTime = _selectedTime != null
              ? _calculateEndTimeAsDateTime(iterDate, _selectedTime!, _estimatedDuration)
              : _calculateEndTimeAsDateTime(
                  iterDate,
                  const TimeOfDay(hour: 9, minute: 0),
                  _estimatedDuration,
                );

          final eventData = {
            'user_id': userId,
            'habit_id': habitId,
            'title': _habitNameController.text,
            'description': _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            'start_date': iterDate.toIso8601String().split('T')[0], // Only date part
            'start_time': startDateTime.toIso8601String(), // Full datetime
            'end_time': endDateTime.toIso8601String(), // Full datetime
            'event_type': 'habit',
            'recurrence_type': _mapFrequencyToRecurrenceType(
              _selectedFrequency,
            ),
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
            iterDate = iterDate.add(const Duration(days: 7));
            break;
          case 'mensual':
            iterDate = DateTime(
              iterDate.year,
              iterDate.month + 1,
              iterDate.day,
            );
            break;
          default:
            iterDate = iterDate.add(const Duration(days: 1));
        }
      }

      print('DEBUG: Eventos generados: ${events.length}');
      
      // Create events with notifications using the calendar service
      if (events.isNotEmpty && _calendarService != null) {
        print('DEBUG: Creando ${events.length} eventos en el calendario');
        for (int i = 0; i < events.length; i++) {
          final eventData = events[i];
          try {
            print('DEBUG: Creando evento ${i + 1}/${events.length}: ${eventData['title']} - ${eventData['start_date']}');
            await _calendarService!.createCalendarEventWithNotification(
              eventData,
            );
            print('DEBUG: Evento ${i + 1} creado exitosamente');
          } catch (e) {
            print('DEBUG: Error al crear evento ${i + 1}: $e');
            // Continue with other events even if one fails
          }
        }
        print('DEBUG: Proceso de creación de eventos completado');
      } else {
        if (events.isEmpty) {
          print('DEBUG: No se generaron eventos para crear');
        }
        if (_calendarService == null) {
          print('DEBUG: CalendarService no está disponible');
        }
      }
    } catch (e) {
      print('DEBUG: Error en _createCalendarEvents: $e');
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

  DateTime _calculateEndTimeAsDateTime(DateTime date, TimeOfDay startTime, int durationMinutes) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = startMinutes + durationMinutes;
    final endHour = (endMinutes ~/ 60) % 24;
    final endMinute = endMinutes % 60;
    return DateTime(
      date.year,
      date.month,
      date.day,
      endHour,
      endMinute,
    );
  }

  String _mapFrequencyToRecurrenceType(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'diario':
        return 'daily';
      case 'semanal':
        return 'weekly';
      case 'mensual':
        return 'monthly';
      case 'anual':
        return 'yearly';
      default:
        return 'none';
    }
  }

  /// Mapea la frecuencia seleccionada a días de la semana para las notificaciones
  /// Retorna una lista de enteros donde 1=Lunes, 2=Martes, ..., 7=Domingo
  List<int> _mapFrequencyToDaysOfWeek(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'diario':
        return [1, 2, 3, 4, 5, 6, 7]; // Todos los días
      case 'semanal':
        return [1, 2, 3, 4, 5]; // Lunes a viernes (días laborables)
      case 'mensual':
        return [1]; // Solo lunes (primer día de la semana laboral)
      default:
        return [1, 2, 3, 4, 5, 6, 7]; // Por defecto todos los días
    }
  }

  /// Programa las notificaciones para un hábito
  Future<void> _scheduleHabitNotifications(String userHabitId) async {
    try {
      print('🔔 [NOTIFICATIONS] Iniciando programación de notificaciones para userHabitId: $userHabitId');
      
      // Verificar permisos de notificación
      final notificationServiceInstance = notification_service.NotificationService();
      final hasPermissions = await notificationServiceInstance.checkPermissions();
      if (!hasPermissions) {
        print('⚠️ [NOTIFICATIONS] No hay permisos de notificación, solicitando...');
        final granted = await notificationServiceInstance.requestPermissions();
        if (!granted) {
          print('❌ [NOTIFICATIONS] Permisos de notificación denegados');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se necesitan permisos de notificación para los recordatorios'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;
        }
      }

      // Obtener días de la semana basados en la frecuencia
      final daysOfWeek = _mapFrequencyToDaysOfWeek(_selectedFrequency);
      print('📅 [NOTIFICATIONS] Días de la semana para $_selectedFrequency: $daysOfWeek');

      // Usar la hora seleccionada o una por defecto (9:00 AM)
      final now = DateTime.now();
      final reminderTime = _selectedTime != null 
          ? DateTime(now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute)
          : DateTime(now.year, now.month, now.day, 9, 0); // 9:00 AM por defecto

      print('⏰ [NOTIFICATIONS] Hora de recordatorio: ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');

      // Programar las notificaciones usando el HabitBloc
      if (mounted) {
        context.read<HabitBloc>().add(
          SetupHabitNotifications(
            userHabitId: userHabitId,
            daysOfWeek: daysOfWeek,
            reminderTime: reminderTime,
          ),
        );
        print('✅ [NOTIFICATIONS] Evento SetupHabitNotifications enviado al HabitBloc');
      }

    } catch (e) {
      print('❌ [NOTIFICATIONS] Error al programar notificaciones: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al programar notificaciones: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
          widget.isEditMode ? 'Editar Hábito' : 'Nuevo Hábito',
          style: AppTextStyles.headingMedium.copyWith(color: Colors.black),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () {
              context.go(AppRoutes.calendar);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
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
              if (!_suggestedSchedule) _buildFrequencySection(),
              if (!_suggestedSchedule) const SizedBox(height: 24),
              if (!_suggestedSchedule) _buildCalendarButton(),
              if (!_suggestedSchedule) const SizedBox(height: 24),
              _buildScheduleToggle(),
              const SizedBox(height: 24),
              _buildAISuggestionsSection(),
              const SizedBox(height: 24),
              if (!_suggestedSchedule) _buildTimePickerField(),
              const SizedBox(height: 20),
              if (!_suggestedSchedule) _buildDurationField(),
              if (!_suggestedSchedule) const SizedBox(height: 24),
              _buildDifficultySection(),
              const SizedBox(height: 20),
              _buildCustomReminderField(),
              const SizedBox(height: 28),
              _buildSaveButton(),
            ],
              ),
            ),
          ),
          // Overlay de carga
          if (_isLoadingHabitData)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando datos del hábito...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
            // Sincronizar con nuestro controlador después del build
            if (controller.text != _habitNameController.text) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (controller.text != _habitNameController.text) {
                  controller.text = _habitNameController.text;
                }
              });
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
            if (selection.description.isNotEmpty == true) {
              _descriptionController.text = selection.description;
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
          initialValue: validSelectedId,
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
    final bool canEnableAI = _startDate != null && 
                            _habitNameController.text.trim().isNotEmpty && 
                            _isCalendarServiceAvailable();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Horario sugerido',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: canEnableAI ? Colors.grey[600] : Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isInitializingCalendarService) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isInitializingCalendarService
                    ? 'Inicializando servicio de calendario...'
                    : canEnableAI
                        ? 'Sugerir horarios y duración automáticamente'
                        : 'Selecciona una fecha de inicio para habilitar la sugerencia automática',
                style: AppTextStyles.bodySmall.copyWith(
                  color: canEnableAI ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _suggestedSchedule && canEnableAI,
          onChanged: canEnableAI && !_isInitializingCalendarService
              ? (value) {
                  print('DEBUG: Switch horario sugerido cambiado a: $value');
                  print('DEBUG: canEnableAI: $canEnableAI');
                  print('DEBUG: _startDate: $_startDate');
                  print('DEBUG: habitName: ${_habitNameController.text.trim()}');
                  print('DEBUG: calendarService disponible: ${_isCalendarServiceAvailable()}');
                  
                  setState(() {
                    _suggestedSchedule = value;
                    if (value) {
                      print('DEBUG: Activando horario sugerido y sugerencias IA');
                      // Si se activa horario sugerido, también activar sugerencias IA
                      _geminiSuggestions = true;
                      // Validar condiciones antes de generar sugerencias
                      _generateGeminiSuggestionsWithValidation();
                    } else {
                      print('DEBUG: Desactivando horario sugerido');
                      // Limpiar errores previos al desactivar
                      _geminiError = null;
                    }
                  });
                }
              : null,
          activeThumbColor: AppColors.primary,
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
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
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
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
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
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
          Icon(icon, size: 16, color: AppColors.primary),
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
            Icon(Icons.event, color: AppColors.primary, size: 20),
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
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme
                                  .copyWith(primary: AppColors.primary),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          _startDateController.text =
                              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: InputDecoration(
                          hintText: 'Seleccionar fecha',
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                          ),
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                          ),
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
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (_startDate == null) {
                            return 'Selecciona la fecha de inicio';
                          }
                          return null;
                        },
                      ),
                    ),
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
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _endDate ??
                            (_startDate?.add(const Duration(days: 30)) ??
                                DateTime.now().add(const Duration(days: 30))),
                        firstDate: _startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme
                                  .copyWith(primary: AppColors.primary),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _endDate = picked;
                          _endDateController.text =
                              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _endDateController,
                        decoration: InputDecoration(
                          hintText: 'Seleccionar fecha (opcional)',
                          prefixIcon: Icon(
                            Icons.event,
                            color: AppColors.primary,
                          ),
                          suffixIcon: _endDate != null
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _endDate = null;
                                      _endDateController.clear();
                                    });
                                  },
                                )
                              : Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
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
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (_endDate != null &&
                              _startDate != null &&
                              _endDate!.isBefore(_startDate!)) {
                            return 'Debe ser posterior a la fecha de inicio';
                          }
                          return null;
                        },
                      ),
                    ),
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
    final bool isDisabled = _isLoading || _isGeneratingSuggestions;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _saveHabit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey[400] : AppColors.primary,
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
            : _isGeneratingSuggestions
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generando sugerencias...',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                widget.isEditMode ? 'Actualizar hábito' : 'Guardar hábito',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
