import 'package:flutter/material.dart';
import '../../../services/symptoms_service.dart';

class RegisterSymptomDialog extends StatefulWidget {
  const RegisterSymptomDialog({super.key});

  @override
  State<RegisterSymptomDialog> createState() => _RegisterSymptomDialogState();
}

class _RegisterSymptomDialogState extends State<RegisterSymptomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _symptomNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedSeverity = 'leve';
  String? _selectedBodyPart;
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;

  final List<String> _severityOptions = ['leve', 'moderado', 'severo'];
  final List<String> _bodyPartOptions = [
    'Estómago',
    'Abdomen superior',
    'Abdomen inferior',
    'Pecho',
    'Garganta',
    'Esófago',
    'Intestino',
    'Otro'
  ];

  @override
  void dispose() {
    _symptomNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _registerSymptom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SymptomsService.registerSymptom(
        symptomName: _symptomNameController.text.trim(),
        severity: _selectedSeverity,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        bodyPart: _selectedBodyPart,
        occurredAt: _selectedDateTime,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Retorna true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Síntoma registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar síntoma: ${e.toString()}'),
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

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
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
                    Icons.monitor_heart,
                    color: Color(0xFF4CAF50),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Registrar Síntoma',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nombre del síntoma
              TextFormField(
                controller: _symptomNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del síntoma *',
                  hintText: 'Ej: Dolor de estómago, acidez, náuseas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el nombre del síntoma';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Severidad
              DropdownButtonFormField<String>(
                initialValue: _selectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'Severidad *',
                  border: OutlineInputBorder(),
                ),
                items: _severityOptions.map((severity) {
                  return DropdownMenuItem(
                    value: severity,
                    child: Text(severity.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSeverity = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Parte del cuerpo
              DropdownButtonFormField<String>(
                initialValue: _selectedBodyPart,
                decoration: const InputDecoration(
                  labelText: 'Parte del cuerpo',
                  border: OutlineInputBorder(),
                ),
                items: _bodyPartOptions.map((bodyPart) {
                  return DropdownMenuItem(
                    value: bodyPart,
                    child: Text(bodyPart),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBodyPart = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Fecha y hora
              InkWell(
                onTap: _selectDateTime,
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
                            'Fecha y hora del síntoma',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} '
                            '${_selectedDateTime.hour.toString().padLeft(2, '0')}:'
                            '${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Descripción adicional
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción adicional (opcional)',
                  hintText: 'Describe más detalles sobre el síntoma',
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
                    onPressed: _isLoading ? null : _registerSymptom,
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