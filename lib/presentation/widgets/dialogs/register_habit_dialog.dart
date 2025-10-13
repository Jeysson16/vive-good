import 'package:flutter/material.dart';
import '../../../services/habits_service.dart';

class RegisterHabitDialog extends StatefulWidget {
  const RegisterHabitDialog({super.key});

  @override
  State<RegisterHabitDialog> createState() => _RegisterHabitDialogState();
}

class _RegisterHabitDialogState extends State<RegisterHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _habitNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedFrequency = 'daily';
  TimeOfDay? _selectedTime;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  final List<Map<String, String>> _frequencyOptions = [
    {'value': 'daily', 'label': 'Diario'},
    {'value': 'weekly', 'label': 'Semanal'},
    {'value': 'monthly', 'label': 'Mensual'},
  ];

  @override
  void dispose() {
    _habitNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _registerHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? scheduledTime;
      if (_selectedTime != null) {
        scheduledTime = '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
                      '${_selectedTime!.minute.toString().padLeft(2, '0')}:00';
      }

      await HabitsService.createCustomHabit(
        habitName: _habitNameController.text.trim(),
        frequency: _selectedFrequency,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        scheduledTime: scheduledTime,
        startDate: _startDate,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Retorna true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hábito registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar hábito: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF4CAF50),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Registrar Nuevo Hábito',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nombre del hábito
              TextFormField(
                controller: _habitNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del hábito *',
                  hintText: 'Ej: Beber 8 vasos de agua, Caminar 30 min',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el nombre del hábito';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Frecuencia
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia *',
                  border: OutlineInputBorder(),
                ),
                items: _frequencyOptions.map((frequency) {
                  return DropdownMenuItem(
                    value: frequency['value'],
                    child: Text(frequency['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Hora programada
              InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.grey),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hora programada (opcional)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _selectedTime != null
                                ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
                                  '${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                : 'Seleccionar hora',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedTime != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha de inicio
              InkWell(
                onTap: _selectStartDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fecha de inicio',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Describe más detalles sobre el hábito',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _registerHabit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Registrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}