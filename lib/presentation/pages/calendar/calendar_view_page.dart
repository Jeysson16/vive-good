import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/calendar/calendar_bloc.dart';
import '../../../domain/entities/calendar_event.dart' as entity;
import '../../widgets/calendar/calendar_event_card.dart';
import '../../widgets/calendar/add_event_dialog.dart';
import '../../../core/theme/app_colors.dart';

class CalendarViewPage extends StatefulWidget {
  const CalendarViewPage({super.key});

  @override
  State<CalendarViewPage> createState() => _CalendarViewPageState();
}

class _CalendarViewPageState extends State<CalendarViewPage> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _selectedDateController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  
  String _currentView = 'day'; // day, week, month
  
  @override
  void initState() {
    super.initState();
    _initializeDateControllers();
    _loadEvents();
  }
  
  void _initializeDateControllers() {
    _selectedDateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
    _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate);
  }
  
  void _loadEvents() {
    context.read<CalendarBloc>().add(
      LoadCalendarEvents(
        userId: '550e8400-e29b-41d4-a716-446655440000', // TODO: Get from auth
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }
  
  Future<void> _selectDate(TextEditingController controller, DateTime initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
        
        if (controller == _selectedDateController) {
          _selectedDate = picked;
          context.read<CalendarBloc>().add(SelectCalendarDate(selectedDate: picked));
        } else if (controller == _startDateController) {
          _startDate = picked;
        } else if (controller == _endDateController) {
          _endDate = picked;
        }
      });
      
      if (controller != _selectedDateController) {
        _loadEvents();
      }
    }
  }
  
  void _parseAndSetDate(TextEditingController controller, String value) {
    try {
      final DateTime parsed = DateFormat('dd/MM/yyyy').parse(value);
      setState(() {
        if (controller == _selectedDateController) {
          _selectedDate = parsed;
          context.read<CalendarBloc>().add(SelectCalendarDate(selectedDate: parsed));
        } else if (controller == _startDateController) {
          _startDate = parsed;
        } else if (controller == _endDateController) {
          _endDate = parsed;
        }
      });
      
      if (controller != _selectedDateController) {
        _loadEvents();
      }
    } catch (e) {
      // Mostrar error de formato de fecha
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Formato de fecha inválido. Use dd/MM/yyyy'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(
              child: BlocBuilder<CalendarBloc, CalendarState>(
                builder: (context, state) {
                  if (state is CalendarLoading) {
                    return _buildLoadingState();
                  }
                  
                  if (state is CalendarError) {
                    return _buildErrorState(state.message);
                  }
                  
                  if (state is CalendarLoaded) {
                    return _buildCalendarView(state);
                  }
                  
                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    context.go('/main');
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 16),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendario',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubtitleText(),
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Add task button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAddEventDialog(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Agregar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDateSelector(),
          const SizedBox(height: 20),
          _buildViewTabs(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Previous day button
          _buildDateNavButton(
            icon: Icons.chevron_left,
            onPressed: () => _changeDate(-1),
          ),
          // Date display
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE', 'es_ES').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy', 'es_ES').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Next day button
          _buildDateNavButton(
            icon: Icons.chevron_right,
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 20,
        ),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildViewTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildViewTab('day', 'Día'),
          _buildViewTab('week', 'Semana'),
          _buildViewTab('month', 'Mes'),
        ],
      ),
    );
  }

  Widget _buildViewTab(String view, String label) {
    final isSelected = _currentView == view;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _currentView = view),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando eventos...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Algo salió mal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Comienza a organizar tu día',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona un rango de fechas para ver tus eventos',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(CalendarLoaded state) {
    switch (_currentView) {
      case 'week':
        return _buildWeekView(state);
      case 'month':
        return _buildMonthView(state);
      default:
        return _buildDayView(state);
    }
  }

  Widget _buildDayView(CalendarLoaded state) {
    final eventsForDay = state.getEventsForDate(_selectedDate);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tareas de hoy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (eventsForDay.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${eventsForDay.length} ${eventsForDay.length == 1 ? 'tarea' : 'tareas'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: eventsForDay.isEmpty
                ? _buildEmptyDayState()
                : ListView.builder(
                    itemCount: eventsForDay.length,
                    itemBuilder: (context, index) {
                      return CalendarEventCard(
                        event: eventsForDay[index],
                        onTap: () => _showEventDetails(eventsForDay[index]),
                        onComplete: () => _markEventCompleted(eventsForDay[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay tareas para hoy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Perfecto! Tienes el día libre o puedes agregar nuevas tareas.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEventDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar tarea'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(CalendarLoaded state) {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista semanal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                final day = weekDays[index];
                final eventsForDay = state.getEventsForDate(day);
                final isToday = DateFormat('yyyy-MM-dd').format(day) == 
                               DateFormat('yyyy-MM-dd').format(DateTime.now());
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.primary : AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, dd MMM', 'es_ES').format(day),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isToday ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${eventsForDay.length} ${eventsForDay.length == 1 ? 'evento' : 'eventos'}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    children: eventsForDay.map((event) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CalendarEventCard(
                          event: event,
                          onTap: () => _showEventDetails(event),
                          onComplete: () => _markEventCompleted(event),
                        ),
                      ),
                    ).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(CalendarLoaded state) {
    final monthEvents = state.getEventsForMonth(_selectedDate);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy', 'es_ES').format(_selectedDate),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: monthEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_busy,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No hay eventos este mes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Comienza a planificar tu mes agregando nuevos eventos.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: monthEvents.length,
                    itemBuilder: (context, index) {
                      return CalendarEventCard(
                        event: monthEvents[index],
                        onTap: () => _showEventDetails(monthEvents[index]),
                        onComplete: () => _markEventCompleted(monthEvents[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _selectedDateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    });
    context.read<CalendarBloc>().add(SelectCalendarDate(selectedDate: _selectedDate));
  }

  String _getSubtitleText() {
    final now = DateTime.now();
    if (DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(now)) {
      return 'Hoy • ${DateFormat('dd MMM yyyy', 'es_ES').format(_selectedDate)}';
    } else {
      return DateFormat('dd MMM yyyy', 'es_ES').format(_selectedDate);
    }
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        selectedDate: _selectedDate,
        onEventCreated: (event) {
          context.read<CalendarBloc>().add(
            CreateCalendarEventEvent(calendarEvent: event),
          );
        },
      ),
    );
  }

  void _showEventDetails(entity.CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildEventDetailRow(
                      icon: Icons.access_time,
                      label: 'Hora',
                      value: _formatEventTime(context, event),
                    ),
                    if (event.location != null) ...[
                      const SizedBox(height: 16),
                      _buildEventDetailRow(
                        icon: Icons.location_on,
                        label: 'Ubicación',
                        value: event.location!,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildEventDetailRow(
                      icon: Icons.category,
                      label: 'Tipo',
                      value: _getEventTypeLabel(event.eventType),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatEventTime(BuildContext context, entity.CalendarEvent event) {
    if (event.startTime != null && event.endTime != null) {
      final startTime = TimeOfDay.fromDateTime(event.startTime!).format(context);
      final endTime = TimeOfDay.fromDateTime(event.endTime!).format(context);
      return '$startTime - $endTime';
    } else if (event.startTime != null) {
      return TimeOfDay.fromDateTime(event.startTime!).format(context);
    } else {
      return 'Todo el día';
    }
  }

  String _getEventTypeLabel(String eventType) {
    switch (eventType) {
      case 'work':
        return 'Trabajo';
      case 'personal':
        return 'Personal';
      case 'health':
        return 'Salud';
      case 'social':
        return 'Social';
      case 'education':
        return 'Educación';
      default:
        return 'Evento';
    }
  }

  void _markEventCompleted(entity.CalendarEvent event) {
    context.read<CalendarBloc>().add(
      MarkCalendarEventCompleted(eventId: event.id),
    );
  }
  
  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _selectedDateController.dispose();
    super.dispose();
  }
}