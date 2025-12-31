import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/admin/admin_category.dart';
import '../../providers/admin_provider.dart';

class CategoriesManagementPage extends StatefulWidget {
  const CategoriesManagementPage({super.key});

  @override
  State<CategoriesManagementPage> createState() => _CategoriesManagementPageState();
}

class _CategoriesManagementPageState extends State<CategoriesManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AdminCategory> _categories = [];
  List<AdminCategory> _filteredCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredCategories = _categories.where((category) {
        return category.name.toLowerCase().contains(_searchQuery) ||
               (category.description.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.loadAdminCategories();
      
      _categories = adminProvider.adminCategories;
      _filteredCategories = List.from(_categories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar categorías: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(isMobile),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCategoriesList(isMobile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                color: AppColors.primary,
                size: isMobile ? 20 : 24,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Categorías de Hábitos',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredCategories.length} categorías',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 12 : 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar categorías...',
              prefixIcon: const Icon(Icons.search),
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
                borderSide: BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(bool isMobile) {
    if (_filteredCategories.isEmpty) {
      return _buildEmptyState(isMobile);
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return _buildCategoryCard(category, isMobile);
      },
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: isMobile ? 64 : 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Text(
            _searchQuery.isEmpty 
                ? 'No hay categorías disponibles'
                : 'No se encontraron categorías',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            _searchQuery.isEmpty
                ? 'Agrega la primera categoría para comenzar'
                : 'Intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(AdminCategory category, bool isMobile) {
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          children: [
            Container(
              width: isMobile ? 48 : 56,
              height: isMobile ? 48 : 56,
              decoration: BoxDecoration(
                color: _parseColor(category.colorCode).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconData(category.iconName),
                color: _parseColor(category.colorCode),
                size: isMobile ? 24 : 28,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  ...[
                  SizedBox(height: isMobile ? 4 : 6),
                  Text(
                    category.description,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                  SizedBox(height: isMobile ? 6 : 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${category.habitCount} hábitos',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: category.isActive ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category.isActive ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: category.isActive ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleCategoryAction(value, category),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: category.isActive ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        category.isActive ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(category.isActive ? 'Desactivar' : 'Activar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleCategoryAction(String action, AdminCategory category) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'activate':
      case 'deactivate':
        _toggleCategoryStatus(category);
        break;
      case 'delete':
        _showDeleteConfirmation(category);
        break;
    }
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(AdminCategory category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({AdminCategory? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');
    String selectedIcon = category?.iconName ?? 'category';
    String selectedColor = category?.colorCode ?? '#4CAF50';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la categoría',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Icono'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedIcon,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _getIconOptions(),
                            onChanged: (value) {
                              setState(() {
                                selectedIcon = value!;
                              });
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
                          const Text('Color'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: selectedColor,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _getColorOptions(),
                            onChanged: (value) {
                              setState(() {
                                selectedColor = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre de la categoría es requerido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                _saveCategory(
                  isEditing: isEditing,
                  categoryId: category?.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty 
                      ? null 
                      : descriptionController.text.trim(),
                  iconName: selectedIcon,
                  colorCode: selectedColor,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCategoryStatus(AdminCategory category) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    final success = await adminProvider.updateCategory(
      categoryId: category.id,
      name: category.name,
      description: category.description,
      iconName: category.iconName,
      colorCode: category.colorCode,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category.isActive 
              ? 'Categoría desactivada' 
              : 'Categoría activada'
          ),
        ),
      );
      _loadCategories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar la categoría'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteCategory(AdminCategory category) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    final success = await adminProvider.deleteCategory(category.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCategories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar la categoría'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveCategory({
    required bool isEditing,
    String? categoryId,
    required String name,
    String? description,
    required String iconName,
    required String colorCode,
  }) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    bool success;
    if (isEditing && categoryId != null) {
      success = await adminProvider.updateCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        iconName: iconName,
        colorCode: colorCode,
      );
    } else {
      success = await adminProvider.createCategory(
        name: name,
        description: description,
        iconName: iconName,
        colorCode: colorCode,
      );
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing 
              ? 'Categoría actualizada exitosamente'
              : 'Categoría creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCategories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing 
              ? 'Error al actualizar la categoría'
              : 'Error al crear la categoría'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(AdminCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar la categoría "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getIconOptions() {
    final icons = {
      'category': 'Categoría',
      'restaurant': 'Alimentación',
      'fitness_center': 'Ejercicio',
      'bedtime': 'Sueño',
      'water_drop': 'Hidratación',
      'psychology': 'Bienestar Mental',
      'track_changes': 'Productividad',
      'favorite': 'Favorito',
      'star': 'Estrella',
      'lightbulb': 'Idea',
    };

    return icons.entries.map((entry) => DropdownMenuItem(
      value: entry.key,
      child: Row(
        children: [
          Icon(_getIconData(entry.key), size: 20),
          const SizedBox(width: 8),
          Text(entry.value),
        ],
      ),
    )).toList();
  }

  List<DropdownMenuItem<String>> _getColorOptions() {
    final colors = {
      '#4CAF50': 'Verde',
      '#2196F3': 'Azul',
      '#9C27B0': 'Morado',
      '#FF9800': 'Naranja',
      '#F44336': 'Rojo',
      '#795548': 'Marrón',
      '#607D8B': 'Gris Azul',
      '#E91E63': 'Rosa',
    };

    return colors.entries.map((entry) => DropdownMenuItem(
      value: entry.key,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _parseColor(entry.key),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(entry.value),
        ],
      ),
    )).toList();
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'bedtime':
        return Icons.bedtime;
      case 'water_drop':
        return Icons.water_drop;
      case 'psychology':
        return Icons.psychology;
      case 'track_changes':
        return Icons.track_changes;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.category;
    }
  }

  Color _parseColor(String? colorCode) {
    if (colorCode == null) return AppColors.primary;
    try {
      return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}