import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../../domain/entities/admin/admin_habit.dart';
import '../../../domain/entities/admin/admin_category.dart';

class HabitsManagementPage extends StatefulWidget {
  const HabitsManagementPage({super.key});

  @override
  State<HabitsManagementPage> createState() => _HabitsManagementPageState();
}

class _HabitsManagementPageState extends State<HabitsManagementPage> {
  String? _selectedCategoryFilter;
  bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    await Future.wait([
      provider.loadAdminHabits(),
      provider.loadAdminCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Hábitos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.reportError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.reportError}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildFilters(provider),
              Expanded(
                child: _buildHabitsList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitForm(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters(AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por categoría',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ...provider.adminCategories.map((category) =>
                      DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryFilter = value;
                    });
                    _applyFilters(provider);
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                child: CheckboxListTile(
                  title: const Text('Solo activos'),
                  value: _showActiveOnly,
                  onChanged: (value) {
                    setState(() {
                      _showActiveOnly = value ?? true;
                    });
                    _applyFilters(provider);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyFilters(AdminProvider provider) {
    // Aquí podrías implementar filtros locales o recargar con filtros
    // Por ahora, simplemente recargamos los datos
    provider.loadAdminHabits();
  }

  Widget _buildHabitsList(AdminProvider provider) {
    final habits = provider.adminHabits.where((habit) {
      if (_selectedCategoryFilter != null && habit.categoryId != _selectedCategoryFilter) {
        return false;
      }
      if (_showActiveOnly && !habit.isActive) {
        return false;
      }
      return true;
    }).toList();

    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay hábitos disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega un nuevo hábito usando el botón +',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return _buildHabitCard(habit, provider);
      },
    );
  }

  Widget _buildHabitCard(AdminHabit habit, AdminProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(habit.colorCode) ?? Colors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _parseIcon(habit.iconName),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        habit.categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showHabitForm(context, habit: habit),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(context, habit, provider),
                    ),
                  ],
                ),
              ],
            ),
            if (habit.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                habit.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.people,
                  label: '${habit.userCount} usuarios',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.trending_up,
                  label: '${(habit.averageCompletion * 100).toStringAsFixed(1)}% completado',
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: habit.isActive ? Icons.check_circle : Icons.pause_circle,
                  label: habit.isActive ? 'Activo' : 'Inactivo',
                  color: habit.isActive ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showHabitForm(BuildContext context, {AdminHabit? habit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HabitFormPage(habit: habit),
      ),
    ).then((_) => _loadData());
  }

  void _showDeleteConfirmation(BuildContext context, AdminHabit habit, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el hábito "${habit.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await provider.deleteHabit(habit.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                          ? 'Hábito eliminado exitosamente'
                          : 'Error al eliminar el hábito: ${provider.reportError}',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  IconData _parseIcon(String? iconName) {
    if (iconName == null) return Icons.fitness_center;
    
    switch (iconName.toLowerCase()) {
      case 'fitness_center': return Icons.fitness_center;
      case 'restaurant': return Icons.restaurant;
      case 'local_drink': return Icons.local_drink;
      case 'bedtime': return Icons.bedtime;
      case 'psychology': return Icons.psychology;
      case 'favorite': return Icons.favorite;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'sports': return Icons.sports;
      case 'music_note': return Icons.music_note;
      case 'book': return Icons.book;
      case 'nature': return Icons.nature;
      default: return Icons.fitness_center;
    }
  }

  Color? _parseColor(String? colorCode) {
    if (colorCode == null) return null;
    
    try {
      if (colorCode.startsWith('#')) {
        return Color(int.parse(colorCode.substring(1), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(colorCode, radix: 16) + 0xFF000000);
    } catch (e) {
      return null;
    }
  }
}

class HabitFormPage extends StatefulWidget {
  final AdminHabit? habit;

  const HabitFormPage({super.key, this.habit});

  @override
  State<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends State<HabitFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedIcon;
  String? _selectedColor;
  String? _selectedDifficulty;
  bool _isActive = true;

  final Map<String, IconData> _availableIcons = {
    'fitness_center': Icons.fitness_center,
    'restaurant': Icons.restaurant,
    'local_drink': Icons.local_drink,
    'bedtime': Icons.bedtime,
    'psychology': Icons.psychology,
    'favorite': Icons.favorite,
    'work': Icons.work,
    'school': Icons.school,
    'sports': Icons.sports,
    'music_note': Icons.music_note,
    'book': Icons.book,
    'nature': Icons.nature,
  };

  final Map<String, Color> _availableColors = {
    'Rojo': Colors.red,
    'Verde': Colors.green,
    'Azul': Colors.blue,
    'Naranja': Colors.orange,
    'Púrpura': Colors.purple,
    'Teal': Colors.teal,
    'Índigo': Colors.indigo,
    'Rosa': Colors.pink,
  };

  final List<String> _difficultyLevels = [
    'Fácil',
    'Medio',
    'Difícil',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _nameController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.description ?? '';
      _selectedCategoryId = widget.habit!.categoryId;
      _selectedIcon = widget.habit!.iconName;
      _selectedColor = widget.habit!.colorCode;
      _isActive = widget.habit!.isActive;
      // Nota: difficultyLevel y estimatedDuration no están en AdminHabit actualmente
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _estimatedDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? 'Crear Hábito' : 'Editar Hábito'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoSection(provider),
                  const SizedBox(height: 24),
                  _buildAppearanceSection(),
                  const SizedBox(height: 24),
                  _buildAdvancedSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoSection(AdminProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Básica',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del hábito *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categoría *',
                border: OutlineInputBorder(),
              ),
              items: provider.adminCategories.map((category) =>
                DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                ),
              ).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La categoría es requerida';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apariencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Icono:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.entries.map((entry) {
                final isSelected = _selectedIcon == entry.key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = entry.key;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.teal : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Color:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedColor,
              decoration: const InputDecoration(
                labelText: 'Seleccionar color',
                border: OutlineInputBorder(),
              ),
              items: _availableColors.entries.map((entry) =>
                DropdownMenuItem<String>(
                  value: entry.value.value.toRadixString(16),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: entry.value,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key),
                    ],
                  ),
                ),
              ).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedColor = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración Avanzada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Nivel de dificultad',
                border: OutlineInputBorder(),
              ),
              items: _difficultyLevels.map((difficulty) =>
                DropdownMenuItem<String>(
                  value: difficulty,
                  child: Text(difficulty),
                ),
              ).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estimatedDurationController,
              decoration: const InputDecoration(
                labelText: 'Duración estimada (minutos)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Ingresa un número válido mayor a 0';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (widget.habit != null)
              SwitchListTile(
                title: const Text('Hábito activo'),
                subtitle: const Text('Los hábitos inactivos no aparecen para los usuarios'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AdminProvider provider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : () => _saveHabit(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.habit == null ? 'Crear' : 'Actualizar'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveHabit(AdminProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final estimatedDuration = _estimatedDurationController.text.isNotEmpty
        ? int.tryParse(_estimatedDurationController.text)
        : null;

    bool success;
    if (widget.habit == null) {
      // Crear nuevo hábito
      success = await provider.createHabit(
        name: name,
        categoryId: _selectedCategoryId!,
        description: description.isNotEmpty ? description : null,
        iconName: _selectedIcon,
        colorCode: _selectedColor,
        difficultyLevel: _selectedDifficulty,
        estimatedDuration: estimatedDuration,
      );
    } else {
      // Actualizar hábito existente
      success = await provider.updateHabit(
        habitId: widget.habit!.id,
        name: name,
        description: description.isNotEmpty ? description : null,
        categoryId: _selectedCategoryId,
        iconName: _selectedIcon,
        colorCode: _selectedColor,
        difficultyLevel: _selectedDifficulty,
        estimatedDuration: estimatedDuration,
        isActive: _isActive,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.habit == null
                  ? 'Hábito creado exitosamente'
                  : 'Hábito actualizado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${provider.reportError}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}