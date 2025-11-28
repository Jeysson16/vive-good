import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/risk_habits_service.dart';

class RiskHabitsWidget extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool showInProfile;
  
  const RiskHabitsWidget({
    super.key,
    this.onCompleted,
    this.showInProfile = false,
  });

  @override
  State<RiskHabitsWidget> createState() => _RiskHabitsWidgetState();
}

class _RiskHabitsWidgetState extends State<RiskHabitsWidget> {
  bool _hasCompleted = false;
  bool _isLoading = true;
  int _totalRisk = 0;

  @override
  void initState() {
    super.initState();
    _checkIfCompleted();
  }

  Future<void> _checkIfCompleted() async {
    try {
      final hasCompleted = await RiskHabitsService.hasCompletedAssessment();
      final riskData = await RiskHabitsService.getUserRiskHabits();

      setState(() {
        _hasCompleted = hasCompleted;
        _totalRisk = riskData?['total_risk'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRiskHabitsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RiskHabitsDialog(
        onSaved: () {
          _checkIfCompleted(); // Refresh the state
          widget.onCompleted?.call();
        },
      ),
    );
  }

  String get _subtitleText {
    if (_isLoading) return 'Cargando...';
    if (!_hasCompleted) return 'Evalúa tus hábitos alimenticios de riesgo';
    if (widget.showInProfile) return 'Toca para editar tu evaluación';
    return 'Hábitos de riesgo identificados: $_totalRisk';
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
        onTap: _showRiskHabitsDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.showInProfile 
                          ? 'Hábitos Alimenticios de Riesgo'
                          : 'Evaluar hábitos de riesgo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleText,
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

class _RiskHabitsDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _RiskHabitsDialog({
    required this.onSaved,
  });

  @override
  State<_RiskHabitsDialog> createState() => _RiskHabitsDialogState();
}

class _RiskHabitsDialogState extends State<_RiskHabitsDialog> {
  bool _isLoading = false;
  List<String> _selectedHabits = [];

  // Get predefined list of risky eating habits from service
  final List<String> _riskHabits = RiskHabitsService.getPredefinedRiskHabits();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final riskData = await RiskHabitsService.getUserRiskHabits();
      
      if (riskData != null && riskData['habits'] != null) {
        setState(() {
          _selectedHabits = List<String>.from(riskData['habits']);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveAssessment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await RiskHabitsService.saveRiskHabits(
        selectedHabits: _selectedHabits,
      );

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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          const Text(
            'Hábitos Alimenticios de Riesgo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          const Text(
            'Selecciona los hábitos que aplican a tu rutina alimentaria:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          
          // Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Hábitos seleccionados: ${_selectedHabits.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Habits list
          Expanded(
            child: ListView.builder(
              itemCount: _riskHabits.length,
              itemBuilder: (context, index) {
                final habit = _riskHabits[index];
                final isSelected = _selectedHabits.contains(habit);
                
                return CheckboxListTile(
                  title: Text(
                    habit,
                    style: const TextStyle(fontSize: 16),
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedHabits.add(habit);
                      } else {
                        _selectedHabits.remove(habit);
                      }
                    });
                  },
                  activeColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveAssessment,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(CupertinoIcons.checkmark),
                  label: Text(_isLoading ? 'Guardando...' : 'Guardar Evaluación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}