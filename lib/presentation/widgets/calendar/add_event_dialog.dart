import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/calendar_event.dart';

class AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(CalendarEvent) onEventCreated;
  final CalendarEvent? eventToEdit;

  const AddEventDialog({
    super.key,
    required this.selectedDate,
    required this.onEventCreated,
    this.eventToEdit,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _eventType = 'activity';
  String _recurrenceType = 'none';
  DateTime? _recurrenceEndDate;

  final List<String> _eventTypes = [
    'activity',
    'habit',
    'reminder',
    'appointment',
  ];

  final List<String> _recurrenceTypes = [
    'none',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _startDate = event.startDate;
      _endDate = event.endDate;
      _eventType = event.eventType;
      _recurrenceType = event.recurrenceType;
      _recurrenceEndDate = event.recurrenceEndDate;
      _locationController.text = event.location ?? '';
      _notesController.text = event.notes ?? '';

      if (event.startTime != null) {
        final timeOfDay = TimeOfDay.fromDateTime(event.startTime!);
        _startTimeController.text =
            '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
      }
      if (event.endTime != null) {
        final timeOfDay = TimeOfDay.fromDateTime(event.endTime!);
        _endTimeController.text =
            '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
      }
    } else {
      _startDate = widget.selectedDate;
    }

    _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
    if (_endDate != null) {
      _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              widget.eventToEdit != null ? 'Editar Evento' : 'Nuevo Evento',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicFields(),
                      const SizedBox(height: 20),
                      _buildDateTimeFields(),
                      const SizedBox(height: 20),
                      _buildRecurrenceFields(),
                      const SizedBox(height: 20),
                      _buildAdditionalFields(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Básica',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Título *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El título es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _eventType,
          decoration: const InputDecoration(
            labelText: 'Tipo de Evento',
            border: OutlineInputBorder(),
          ),
          items: _eventTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getEventTypeLabel(type)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _eventType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha y Hora',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                controller: _startDateController,
                label: 'Fecha Inicio *',
                onTap: () => _selectDate(true),
                onChanged: (value) => _parseAndSetDate(value, true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField(
                controller: _startTimeController,
                label: 'Hora Inicio',
                onTap: () => _selectTime(true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                controller: _endDateController,
                label: 'Fecha Fin',
                onTap: () => _selectDate(false),
                onChanged: (value) => _parseAndSetDate(value, false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField(
                controller: _endTimeController,
                label: 'Hora Fin',
                onTap: () => _selectTime(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecurrenceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recurrencia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _recurrenceType,
          decoration: const InputDecoration(
            labelText: 'Tipo de Recurrencia',
            border: OutlineInputBorder(),
          ),
          items: _recurrenceTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getRecurrenceLabel(type)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _recurrenceType = value!;
            });
          },
        ),
        if (_recurrenceType != 'none') ...[
          const SizedBox(height: 12),
          _buildDateField(
            controller: TextEditingController(
              text: _recurrenceEndDate != null
                  ? DateFormat('dd/MM/yyyy').format(_recurrenceEndDate!)
                  : '',
            ),
            label: 'Fin de Recurrencia',
            onTap: () => _selectRecurrenceEndDate(),
            onChanged: (value) => _parseRecurrenceEndDate(value),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Adicional',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Ubicación',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notas',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'dd/MM/yyyy',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: onTap,
        ),
      ),
      onChanged: onChanged,
      onTap: onTap,
      readOnly: false,
      validator: label.contains('*')
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'HH:MM',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: onTap,
        ),
      ),
      onTap: onTap,
      readOnly: true,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _saveEvent,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.eventToEdit != null ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStartTime) {
          _startTimeController.text = timeString;
        } else {
          _endTimeController.text = timeString;
        }
      });
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
      });
    }
  }

  void _parseAndSetDate(String value, bool isStartDate) {
    try {
      final DateTime parsed = DateFormat('dd/MM/yyyy').parse(value);
      setState(() {
        if (isStartDate) {
          _startDate = parsed;
        } else {
          _endDate = parsed;
        }
      });
    } catch (e) {
      // Error de formato, se maneja en la validación
    }
  }

  void _parseRecurrenceEndDate(String value) {
    try {
      final DateTime parsed = DateFormat('dd/MM/yyyy').parse(value);
      setState(() {
        _recurrenceEndDate = parsed;
      });
    } catch (e) {
      // Error de formato
    }
  }

  void _saveEvent() {
    if (_formKey.currentState?.validate() == true) {
      final now = DateTime.now();

      final event = CalendarEvent(
        id: widget.eventToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? ''
            : _descriptionController.text.trim(),
        eventType: _eventType,
        startDate: _startDate,
        startTime: _startTimeController.text.trim().isEmpty
            ? null
            : _parseTimeString(_startTimeController.text.trim(), _startDate),
        endDate: _endDate,
        endTime: _endTimeController.text.trim().isEmpty
            ? null
            : _parseTimeString(
                _endTimeController.text.trim(),
                _endDate ?? _startDate,
              ),
        userId: '550e8400-e29b-41d4-a716-446655440000', // TODO: Get from auth
        recurrenceType: _recurrenceType,
        recurrenceEndDate: _recurrenceEndDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.eventToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      widget.onEventCreated(event);
      Navigator.of(context).pop();
    }
  }

  String _getEventTypeLabel(String type) {
    switch (type) {
      case 'habit':
        return 'Hábito';
      case 'activity':
        return 'Actividad';
      case 'reminder':
        return 'Recordatorio';
      case 'appointment':
        return 'Cita';
      default:
        return 'Evento';
    }
  }

  String _getRecurrenceLabel(String type) {
    switch (type) {
      case 'none':
        return 'Sin recurrencia';
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      case 'yearly':
        return 'Anual';
      default:
        return 'Personalizado';
    }
  }

  DateTime _parseTimeString(String timeString, DateTime date) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
