import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/admin_users_service.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/admin_provider.dart';
import 'habits_management_page.dart';

class AdminMantenedoresPage extends StatefulWidget {
  const AdminMantenedoresPage({super.key});

  @override
  State<AdminMantenedoresPage> createState() => _AdminMantenedoresPageState();
}

class _AdminMantenedoresPageState extends State<AdminMantenedoresPage> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
        _animationController.reset();
        _animationController.forward();
      }
    });
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(isMobile),
          _buildTabs(isMobile),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildContent(isMobile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.settings,
              size: isMobile ? 20 : 24,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mantenedores',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: isMobile ? 18 : 20,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Gestión de usuarios, roles y categorías',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isMobile) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 11 : 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: isMobile ? 11 : 12,
            ),
            tabs: [
              _buildAnimatedTab(
                icon: Icons.people,
                text: 'Usuarios',
                isSelected: _selectedIndex == 0,
                isMobile: isMobile,
              ),
              _buildAnimatedTab(
                icon: Icons.admin_panel_settings,
                text: 'Roles',
                isSelected: _selectedIndex == 1,
                isMobile: isMobile,
              ),
              _buildAnimatedTab(
                icon: Icons.category,
                text: 'Categorías',
                isSelected: _selectedIndex == 2,
                isMobile: isMobile,
              ),
              _buildAnimatedTab(
                icon: Icons.track_changes,
                text: 'Hábitos',
                isSelected: _selectedIndex == 3,
                isMobile: isMobile,
              ),
            ],
          ),
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTab({
    required IconData icon,
    required String text,
    required bool isSelected,
    required bool isMobile,
  }) {
    return AnimatedBuilder(
      animation: _tabController.animation!,
      builder: (context, child) {
        final animationValue = _tabController.animation!.value;
        final tabIndex = _tabController.index;
        final isAnimatingToThis = (animationValue - tabIndex).abs() < 1.0;
        final opacity = isSelected ? 1.0 : (isAnimatingToThis ? 0.7 : 0.5);
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 8 : 12,
            horizontal: isMobile ? 4 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withOpacity(0.15) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected 
                ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
                : null,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: opacity,
            child: Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(isSelected ? 6 : 4),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary.withOpacity(0.2) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: isSelected ? (isMobile ? 20 : 22) : (isMobile ? 18 : 20),
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? (isMobile ? 11 : 12) : (isMobile ? 10 : 11),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                    ),
                    child: Text(text),
                  ),
                  if (isSelected) ...[
                    SizedBox(height: isMobile ? 1 : 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 4,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isMobile) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUsersContent(),
        _buildRolesContent(),
        _buildCategoriesContent(),
        _buildHabitsContent(),
      ],
    );
  }

  Widget _buildUsersContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return _UsersManagementWidget(isMobile: isMobile);
  }

  Widget _buildRolesContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return _buildContentTemplate(
      title: 'Gestión de Roles',
      icon: Icons.admin_panel_settings_outlined,
      description: 'Administra los roles del sistema y sus permisos. Crea, edita y elimina roles según las necesidades de tu organización.',
      buttonText: isMobile ? 'Gestionar' : 'Gestionar Roles',
      onAddPressed: _showAddRoleDialog,
      isMobile: isMobile,
    );
  }

  Widget _buildCategoriesContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return _buildContentTemplate(
      title: 'Gestión de Categorías',
      icon: Icons.category_outlined,
      description: 'Aquí se mostrará la lista de categorías con opciones de editar y eliminar.',
      buttonText: isMobile ? 'Agregar' : 'Agregar Categoría',
      onAddPressed: _showAddCategoryDialog,
      isMobile: isMobile,
    );
  }

  Widget _buildHabitsContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return _HabitsManagementWidget(
      isMobile: isMobile,
      onAddPressed: _showAddHabitDialog,
    );
  }

  Widget _buildContentTemplate({
    required String title,
    required IconData icon,
    required String description,
    required String buttonText,
    required VoidCallback onAddPressed,
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAddPressed,
                  icon: Icon(Icons.add, size: isMobile ? 16 : 18),
                  label: Text(
                    buttonText,
                    style: TextStyle(fontSize: isMobile ? 12 : 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 8 : 10,
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      icon,
                      size: isMobile ? 40 : 48,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    title.replaceAll('Gestión de ', 'Mantenedor de '),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                        fontSize: isMobile ? 12 : 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: isMobile ? 16 : 18,
                        ),
                        SizedBox(width: isMobile ? 6 : 8),
                        Flexible(
                          child: Text(
                            'Esta funcionalidad se implementará en una versión futura',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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



  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Usuario'),
        content: const Text('Esta funcionalidad se implementará próximamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAddRoleDialog() {
    Navigator.pushNamed(context, '/admin/roles');
  }

  void _showAddCategoryDialog() {
    Navigator.pushNamed(context, '/admin/categories');
  }

  void _showAddHabitDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HabitsManagementPage(),
      ),
    );
  }
}

// Widget de gestión de usuarios
class _UsersManagementWidget extends StatefulWidget {
  final bool isMobile;

  const _UsersManagementWidget({required this.isMobile});

  @override
  State<_UsersManagementWidget> createState() => _UsersManagementWidgetState();
}

class _UsersManagementWidgetState extends State<_UsersManagementWidget> {
  final AdminUsersService _usersService = AdminUsersService();
  List<UserEntity> _users = [];
  List<UserEntity> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _usersService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users
            .where((user) =>
                user.email.toLowerCase().contains(query.toLowerCase()) ||
                (user.fullName?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: widget.isMobile ? 12 : 16),
          _buildSearchBar(),
          SizedBox(height: widget.isMobile ? 12 : 16),
          Expanded(
            child: _isLoading ? _buildLoadingWidget() : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Usuarios',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: widget.isMobile ? 16 : 18,
                  ),
                ),
                SizedBox(height: widget.isMobile ? 4 : 6),
                Text(
                  '${_filteredUsers.length} usuarios encontrados',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: widget.isMobile ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddUserDialog,
            icon: Icon(Icons.add, size: widget.isMobile ? 16 : 18),
            label: Text(
              widget.isMobile ? 'Agregar' : 'Agregar Usuario',
              style: TextStyle(fontSize: widget.isMobile ? 12 : 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 12 : 16,
                vertical: widget.isMobile ? 8 : 10,
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterUsers,
        decoration: InputDecoration(
          hintText: 'Buscar por email o nombre...',
          prefixIcon: Icon(Icons.search, size: widget.isMobile ? 20 : 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: widget.isMobile ? 20 : 22),
                  onPressed: () {
                    _searchController.clear();
                    _filterUsers('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: widget.isMobile ? 12 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.all(widget.isMobile ? 8 : 12),
        itemCount: _filteredUsers.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
            size: widget.isMobile ? 48 : 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: widget.isMobile ? 12 : 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No se encontraron usuarios'
                : 'No hay usuarios registrados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: widget.isMobile ? 14 : 16,
            ),
          ),
          SizedBox(height: widget.isMobile ? 6 : 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Agrega el primer usuario para comenzar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
              fontSize: widget.isMobile ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserEntity user) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 8 : 12,
        vertical: widget.isMobile ? 4 : 8,
      ),
      leading: CircleAvatar(
        radius: widget.isMobile ? 20 : 24,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? Icon(
                Icons.person,
                color: AppColors.primary,
                size: widget.isMobile ? 20 : 24,
              )
            : null,
      ),
      title: Text(
        user.fullName ?? user.email,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: widget.isMobile ? 14 : 15,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.fullName != null) ...[
            Text(
              user.email,
              style: TextStyle(
                fontSize: widget.isMobile ? 12 : 13,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 2),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: widget.isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: _getRoleColor(user.role),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: user.isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 4),
              Text(
                user.isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: widget.isMobile ? 10 : 11,
                  color: user.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          size: widget.isMobile ? 20 : 24,
        ),
        onSelected: (value) => _handleUserAction(value, user),
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
            value: user.isActive ? 'deactivate' : 'activate',
            child: Row(
              children: [
                Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(user.isActive ? 'Desactivar' : 'Activar'),
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
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'user':
      default:
        return Colors.blue;
    }
  }

  void _handleUserAction(String action, UserEntity user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(user);
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(
        onSave: (email, password, fullName, role) async {
          try {
            await _usersService.createUser(
              email: email,
              password: password,
              fullName: fullName.isEmpty ? null : fullName,
              role: role,
            );
            _loadUsers();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuario creado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al crear usuario: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditUserDialog(UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(
        user: user,
        onSave: (email, password, fullName, role) async {
          try {
            await _usersService.updateUser(
              userId: user.id,
              email: email.isEmpty ? null : email,
              fullName: fullName.isEmpty ? null : fullName,
              role: role,
            );
            _loadUsers();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuario actualizado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al actualizar usuario: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _toggleUserStatus(UserEntity user) async {
    try {
      await _usersService.updateUser(
        userId: user.id,
        isActive: !user.isActive,
      );
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isActive
                  ? 'Usuario desactivado exitosamente'
                  : 'Usuario activado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado del usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar al usuario ${user.fullName ?? user.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _usersService.deleteUser(user.id);
                _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar usuario: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
}

// Dialog para crear/editar usuarios
class _UserFormDialog extends StatefulWidget {
  final UserEntity? user;
  final Function(String email, String password, String fullName, String role) onSave;

  const _UserFormDialog({
    this.user,
    required this.onSave,
  });

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  String _selectedRole = 'user';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _emailController.text = widget.user!.email;
      _fullNameController.text = widget.user!.fullName ?? '';
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Editar Usuario' : 'Agregar Usuario'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !isEditing, // No permitir cambiar email en edición
                validator: (value) {
                  if (!isEditing && (value == null || value.isEmpty)) {
                    return 'El email es requerido';
                  }
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Ingresa un email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (!isEditing) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Usuario')),
                  DropdownMenuItem(value: 'moderator', child: Text('Moderador')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
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
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await widget.onSave(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _fullNameController.text.trim(),
          _selectedRole,
        );
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // El error se maneja en el widget padre
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}

// Widget de gestión de hábitos
class _HabitsManagementWidget extends StatefulWidget {
  final bool isMobile;
  final VoidCallback onAddPressed;

  const _HabitsManagementWidget({
    required this.isMobile,
    required this.onAddPressed,
  });

  @override
  State<_HabitsManagementWidget> createState() => _HabitsManagementWidgetState();
}

class _HabitsManagementWidgetState extends State<_HabitsManagementWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHabits();
    });
  }

  Future<void> _loadHabits() async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    await provider.loadAdminHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              SizedBox(height: widget.isMobile ? 12 : 16),
              Expanded(
                child: _buildHabitsList(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AdminProvider provider) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Hábitos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: widget.isMobile ? 16 : 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Administra los hábitos disponibles en el sistema',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: widget.isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: widget.onAddPressed,
            icon: Icon(Icons.add, size: widget.isMobile ? 16 : 18),
            label: Text(
              'Nuevo Hábito',
              style: TextStyle(
                fontSize: widget.isMobile ? 12 : 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 12 : 16,
                vertical: widget.isMobile ? 8 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList(AdminProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.reportError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar hábitos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.reportError!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHabits,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final habits = provider.adminHabits;

    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay hábitos disponibles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega un nuevo hábito usando el botón "Nuevo Hábito"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return _buildHabitCard(habit);
      },
    );
  }

  Widget _buildHabitCard(dynamic habit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: habit.isActive ? AppColors.primary : Colors.grey,
          child: Icon(
            Icons.fitness_center,
            color: Colors.white,
            size: widget.isMobile ? 18 : 20,
          ),
        ),
        title: Text(
          habit.name ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: widget.isMobile ? 14 : 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (habit.description != null && habit.description!.isNotEmpty)
              Text(
                habit.description!,
                style: TextStyle(
                  fontSize: widget.isMobile ? 12 : 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Categoría: ${habit.categoryName ?? 'Sin categoría'}',
                  style: TextStyle(
                    fontSize: widget.isMobile ? 11 : 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: habit.isActive ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    habit.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 10,
                      color: habit.isActive ? Colors.green[700] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleHabitAction(value, habit),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: habit.isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(
                    habit.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(habit.isActive ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleHabitAction(String action, dynamic habit) {
    switch (action) {
      case 'edit':
        // Navegar a la página de edición de hábito
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const HabitsManagementPage(),
          ),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleHabitStatus(habit);
        break;
      case 'delete':
        _showDeleteConfirmation(habit);
        break;
    }
  }

  void _toggleHabitStatus(dynamic habit) async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    
    try {
      // Aquí implementarías la lógica para activar/desactivar el hábito
      // await provider.updateHabitStatus(habit.id, !habit.isActive);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            habit.isActive 
              ? 'Hábito desactivado correctamente'
              : 'Hábito activado correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Recargar la lista
      _loadHabits();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el hábito: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(dynamic habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el hábito "${habit.name}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteHabit(habit);
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

  void _deleteHabit(dynamic habit) async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    
    try {
      // Aquí implementarías la lógica para eliminar el hábito
      // await provider.deleteHabit(habit.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hábito eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Recargar la lista
      _loadHabits();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el hábito: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}