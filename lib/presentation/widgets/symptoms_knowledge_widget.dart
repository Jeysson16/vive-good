import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SymptomsKnowledgeWidget extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool showInProfile;
  
  const SymptomsKnowledgeWidget({
    super.key,
    this.onCompleted,
    this.showInProfile = false,
  });

  @override
  State<SymptomsKnowledgeWidget> createState() => _SymptomsKnowledgeWidgetState();
}

class _SymptomsKnowledgeWidgetState extends State<SymptomsKnowledgeWidget> {
  bool _hasCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfCompleted();
  }

  Future<void> _checkIfCompleted() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('user_symptoms_knowledge')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        _hasCompleted = response != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSymptomsKnowledgeDialog() {
    showDialog(
      context: context,
      builder: (context) => _SymptomsKnowledgeDialog(
        onSaved: () {
          setState(() {
            _hasCompleted = true;
          });
          widget.onCompleted?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    // Only hide if completed AND not showing in profile
    if (_hasCompleted && !widget.showInProfile) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: _showSymptomsKnowledgeDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.book_fill,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.showInProfile && _hasCompleted
                          ? 'Conocimiento de síntomas'
                          : 'Evaluar conocimiento',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.showInProfile && _hasCompleted
                          ? 'Toca para editar tu evaluación'
                          : 'Evalúa tu conocimiento sobre síntomas y factores de riesgo',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomsKnowledgeDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _SymptomsKnowledgeDialog({
    required this.onSaved,
  });

  @override
  State<_SymptomsKnowledgeDialog> createState() => _SymptomsKnowledgeDialogState();
}

class _SymptomsKnowledgeDialogState extends State<_SymptomsKnowledgeDialog> {
  int _knowledgeLevel = 1;
  bool _presentsKnowledge = false;
  bool _isLoading = false;

  // Controladores para los campos de texto
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _riskFactorsController = TextEditingController();
  final TextEditingController _preventionController = TextEditingController();

  // Listas de respuestas correctas para evaluación
  final List<String> _correctSymptoms = [
    'dolor estomacal', 'dolor de estómago', 'dolor abdominal',
    'acidez', 'agruras', 'reflujo', 'ardor',
    'náuseas', 'nausea', 'mareo',
    'vómito', 'vomitar',
    'hinchazón', 'inflamación', 'distensión',
    'pérdida de apetito', 'sin apetito', 'inapetencia',
    'eructos', 'gases', 'flatulencia',
    'sensación de llenura', 'saciedad temprana',
    'diarrea', 'estreñimiento'
  ];

  final List<String> _correctRiskFactors = [
    'helicobacter pylori', 'h. pylori', 'bacteria',
    'alcohol', 'bebidas alcohólicas',
    'tabaco', 'fumar', 'cigarrillo',
    'estrés', 'ansiedad', 'nervios',
    'medicamentos', 'aines', 'antiinflamatorios',
    'aspirina', 'ibuprofeno',
    'comida picante', 'condimentos', 'chile',
    'café', 'cafeína',
    'comida grasosa', 'frituras'
  ];

  final List<String> _correctPrevention = [
    'dieta saludable', 'alimentación balanceada',
    'evitar alcohol', 'no beber',
    'no fumar', 'dejar tabaco',
    'manejo del estrés', 'relajación',
    'ejercicio', 'actividad física',
    'evitar medicamentos', 'no automedicarse',
    'comidas regulares', 'horarios fijos',
    'evitar picante', 'comida suave',
    'probióticos', 'yogurt'
  ];

  // Variables para feedback visual
  List<String> _identifiedSymptoms = [];
  List<String> _identifiedRiskFactors = [];
  List<String> _identifiedPrevention = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('user_symptoms_knowledge')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _knowledgeLevel = response['knowledge_level'] ?? 1;
          _presentsKnowledge = response['presents_knowledge'] ?? false;
          _symptomsController.text = response['symptoms_response'] ?? '';
          _riskFactorsController.text = response['risk_factors_response'] ?? '';
          _preventionController.text = response['prevention_response'] ?? '';
          
          // Load identified items if available
          if (response['identified_symptoms'] != null) {
            _identifiedSymptoms = List<String>.from(response['identified_symptoms']);
          }
          if (response['identified_risk_factors'] != null) {
            _identifiedRiskFactors = List<String>.from(response['identified_risk_factors']);
          }
          if (response['identified_prevention'] != null) {
            _identifiedPrevention = List<String>.from(response['identified_prevention']);
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _riskFactorsController.dispose();
    _preventionController.dispose();
    super.dispose();
  }

  // Método para evaluar automáticamente las respuestas
  void _evaluateResponses() {
    final symptomsText = _symptomsController.text.toLowerCase();
    final riskFactorsText = _riskFactorsController.text.toLowerCase();
    final preventionText = _preventionController.text.toLowerCase();

    // Identificar síntomas mencionados
    _identifiedSymptoms = _correctSymptoms
        .where((symptom) => symptomsText.contains(symptom.toLowerCase()))
        .toList();

    // Identificar factores de riesgo mencionados
    _identifiedRiskFactors = _correctRiskFactors
        .where((factor) => riskFactorsText.contains(factor.toLowerCase()))
        .toList();

    // Identificar medidas de prevención mencionadas
    _identifiedPrevention = _correctPrevention
        .where((prevention) => preventionText.contains(prevention.toLowerCase()))
        .toList();

    // Calcular puntuación basada en criterios
    final totalCorrect = _identifiedSymptoms.length + 
                        _identifiedRiskFactors.length + 
                        _identifiedPrevention.length;

    // Criterios de puntuación:
    // 1: No menciona elementos correctos (0)
    // 2: Menciona 1-2 elementos correctos
    // 3: Menciona 3-4 elementos correctos
    // 4: Menciona 5-7 elementos correctos
    // 5: Menciona 8+ elementos correctos con buena comprensión

    if (totalCorrect == 0) {
      _knowledgeLevel = 1;
    } else if (totalCorrect <= 2) {
      _knowledgeLevel = 2;
    } else if (totalCorrect <= 4) {
      _knowledgeLevel = 3;
    } else if (totalCorrect <= 7) {
      _knowledgeLevel = 4;
    } else {
      _knowledgeLevel = 5;
    }

    // Auto-llenar checkbox basado en puntuación (≥3 = Sí)
    _presentsKnowledge = _knowledgeLevel >= 3;

    setState(() {});
  }

  Future<void> _saveKnowledge() async {
    // Evaluar respuestas antes de guardar
    _evaluateResponses();

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await Supabase.instance.client.from('user_symptoms_knowledge').upsert({
        'user_id': user.id,
        'knowledge_level': _knowledgeLevel,
        'presents_knowledge': _presentsKnowledge,
        'symptoms_response': _symptomsController.text,
        'risk_factors_response': _riskFactorsController.text,
        'prevention_response': _preventionController.text,
        'identified_symptoms': _identifiedSymptoms,
        'identified_risk_factors': _identifiedRiskFactors,
        'identified_prevention': _identifiedPrevention,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Evaluación guardada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
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

  Widget _buildTextFieldWithFeedback({
    required String label,
    required String hint,
    required TextEditingController controller,
    required List<String> identifiedItems,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
          ),
        ),
        if (identifiedItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ Elementos identificados correctamente:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: identifiedItems.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Evaluación de Conocimiento sobre Gastritis',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Responde las siguientes preguntas para evaluar tu conocimiento sobre gastritis:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              
              // Campo de síntomas
              _buildTextFieldWithFeedback(
                label: '1. ¿Qué síntomas de gastritis conoces?',
                hint: 'Escribe todos los síntomas que sepas (ej: dolor estomacal, acidez, náuseas...)',
                controller: _symptomsController,
                identifiedItems: _identifiedSymptoms,
                onChanged: _evaluateResponses,
              ),
              const SizedBox(height: 20),
              
              // Campo de factores de riesgo
              _buildTextFieldWithFeedback(
                label: '2. ¿Qué factores de riesgo para gastritis puedes mencionar?',
                hint: 'Menciona los factores que pueden causar gastritis (ej: H. pylori, alcohol, estrés...)',
                controller: _riskFactorsController,
                identifiedItems: _identifiedRiskFactors,
                onChanged: _evaluateResponses,
              ),
              const SizedBox(height: 20),
              
              // Campo de prevención
              _buildTextFieldWithFeedback(
                label: '3. ¿Cómo crees que se puede prevenir la gastritis?',
                hint: 'Describe medidas preventivas (ej: dieta saludable, evitar alcohol...)',
                controller: _preventionController,
                identifiedItems: _identifiedPrevention,
                onChanged: _evaluateResponses,
              ),
              const SizedBox(height: 20),
              
              // Puntuación automática
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _knowledgeLevel >= 3 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _knowledgeLevel >= 3 ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puntuación automática: $_knowledgeLevel/5',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _knowledgeLevel >= 3 ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getScoreDescription(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _knowledgeLevel >= 3 ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Checkbox automático
              Row(
                children: [
                  Checkbox(
                    value: _presentsKnowledge,
                    onChanged: null, // Deshabilitado porque se auto-llena
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¿Presenta conocimiento? (Auto-evaluado: ${_presentsKnowledge ? "Sí" : "No"})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveKnowledge,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(CupertinoIcons.checkmark),
          label: const Text('Guardar Evaluación'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  String _getScoreDescription() {
    switch (_knowledgeLevel) {
      case 1:
        return 'No se identificaron elementos correctos. Necesitas aprender más sobre gastritis.';
      case 2:
        return 'Conocimiento básico. Mencionaste algunos elementos correctos.';
      case 3:
        return 'Conocimiento moderado. Tienes una comprensión general de la gastritis.';
      case 4:
        return 'Buen conocimiento. Demuestras una comprensión sólida del tema.';
      case 5:
        return 'Excelente conocimiento. Tienes una comprensión integral de la gastritis.';
      default:
        return '';
    }
  }
}