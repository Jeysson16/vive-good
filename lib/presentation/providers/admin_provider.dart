import 'package:flutter/foundation.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/entities/admin/admin_dashboard_stats.dart';
import '../../domain/entities/admin/user_evaluation.dart';
import '../../domain/entities/admin/tech_acceptance_indicators.dart';
import '../../domain/entities/admin/knowledge_symptoms_indicators.dart';
import '../../domain/entities/admin/risk_habits_indicators.dart';
import '../../domain/entities/admin/admin_user.dart';
import '../../domain/entities/admin/admin_category.dart';
import '../../domain/entities/admin/admin_habit.dart';
import '../../domain/entities/admin/consolidated_report.dart';
import '../../domain/usecases/admin/get_admin_dashboard_stats_usecase.dart';
import '../../domain/usecases/admin/get_user_evaluations_usecase.dart';
import '../../domain/usecases/admin/get_tech_acceptance_indicators_usecase.dart';
import '../../domain/usecases/admin/get_consolidated_report_usecase.dart';
import '../../domain/usecases/admin/check_admin_permissions_usecase.dart';
import '../../domain/usecases/admin/export_to_excel_usecase.dart';
import '../../domain/repositories/admin_repository.dart';

enum AdminLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class AdminProvider extends ChangeNotifier {
  final GetAdminDashboardStatsUseCase getDashboardStatsUseCase;
  final GetUserEvaluationsUseCase getUserEvaluationsUseCase;
  final GetTechAcceptanceIndicatorsUseCase getTechAcceptanceIndicatorsUseCase;
  final GetConsolidatedReportUseCase getConsolidatedReportUseCase;
  final CheckAdminPermissionsUseCase checkAdminPermissionsUseCase;
  final ExportToExcelUseCase exportToExcelUseCase;
  final AdminRepository _adminRepository;

  AdminProvider({
    required this.getDashboardStatsUseCase,
    required this.getUserEvaluationsUseCase,
    required this.getTechAcceptanceIndicatorsUseCase,
    required this.getConsolidatedReportUseCase,
    required this.checkAdminPermissionsUseCase,
    required this.exportToExcelUseCase,
    required AdminRepository adminRepository,
  }) : _adminRepository = adminRepository;

  // Estados de carga
  AdminLoadingState _dashboardState = AdminLoadingState.initial;
  AdminLoadingState _evaluationsState = AdminLoadingState.initial;
  AdminLoadingState _indicatorsState = AdminLoadingState.initial;
  AdminLoadingState _reportState = AdminLoadingState.initial;
  final AdminLoadingState _exportState = AdminLoadingState.initial;
  bool _isLoading = false;

  // Datos
  AdminDashboardStats? _dashboardStats;
  List<UserEvaluation> _userEvaluations = [];
  List<TechAcceptanceIndicators> _techAcceptanceIndicators = [];
  final List<KnowledgeSymptomsIndicators> _knowledgeSymptomsIndicators = [];
  final List<RiskHabitsIndicators> _riskHabitsIndicators = [];
  final List<AdminUser> _adminUsers = [];
  List<AdminCategory> _adminCategories = [];
  List<AdminHabit> _adminHabits = [];
  List<ConsolidatedReport> _consolidatedReport = [];

  // Errores
  String? _dashboardError;
  String? _evaluationsError;
  String? _indicatorsError;
  String? _reportError;
  String? _exportError;

  // Filtros
  String? _selectedRole;
  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 0;
  final int _itemsPerPage = 20;

  // Permisos
  bool _isAdmin = false;
  bool _permissionsChecked = false;

  // Getters
  AdminLoadingState get dashboardState => _dashboardState;
  AdminLoadingState get evaluationsState => _evaluationsState;
  AdminLoadingState get indicatorsState => _indicatorsState;
  AdminLoadingState get reportState => _reportState;
  AdminLoadingState get exportState => _exportState;
  bool get isLoading => _isLoading;

  AdminDashboardStats? get dashboardStats => _dashboardStats;
  List<UserEvaluation> get userEvaluations => _userEvaluations;
  List<TechAcceptanceIndicators> get techAcceptanceIndicators => _techAcceptanceIndicators;
  List<KnowledgeSymptomsIndicators> get knowledgeSymptomsIndicators => _knowledgeSymptomsIndicators;
  List<RiskHabitsIndicators> get riskHabitsIndicators => _riskHabitsIndicators;
  List<AdminUser> get adminUsers => _adminUsers;
  List<AdminCategory> get adminCategories => _adminCategories;
  List<AdminHabit> get adminHabits => _adminHabits;
  List<ConsolidatedReport> get consolidatedReport => _consolidatedReport;

  String? get dashboardError => _dashboardError;
  String? get evaluationsError => _evaluationsError;
  String? get indicatorsError => _indicatorsError;
  String? get reportError => _reportError;
  String? get exportError => _exportError;

  String? get selectedRole => _selectedRole;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;

  bool get isAdmin => _isAdmin;
  bool get permissionsChecked => _permissionsChecked;

  // Métodos para verificar permisos
  Future<void> checkAdminPermissions(String userId) async {
    try {
      final result = await checkAdminPermissionsUseCase(
        CheckAdminPermissionsParams(userId: userId),
      );
      
      result.fold(
        (failure) {
          _isAdmin = false;
          _permissionsChecked = true;
        },
        (hasPermissions) {
          _isAdmin = hasPermissions;
          _permissionsChecked = true;
        },
      );
      
      notifyListeners();
    } catch (e) {
      _isAdmin = false;
      _permissionsChecked = true;
      notifyListeners();
    }
  }

  // Métodos para cargar datos del dashboard
  Future<void> loadDashboardStats() async {
    _dashboardState = AdminLoadingState.loading;
    _dashboardError = null;
    notifyListeners();

    try {
      final result = await getDashboardStatsUseCase(NoParams());
      
      result.fold(
        (failure) {
          _dashboardState = AdminLoadingState.error;
          _dashboardError = failure.toString();
        },
        (stats) {
          _dashboardState = AdminLoadingState.loaded;
          _dashboardStats = stats;
        },
      );
    } catch (e) {
      _dashboardState = AdminLoadingState.error;
      _dashboardError = 'Error inesperado: ${e.toString()}';
    }
    
    notifyListeners();
  }

  // Métodos para cargar evaluaciones de usuarios
  Future<void> loadUserEvaluations({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _userEvaluations.clear();
    }

    _evaluationsState = AdminLoadingState.loading;
    _evaluationsError = null;
    notifyListeners();

    try {
      final result = await getUserEvaluationsUseCase(
        GetUserEvaluationsParams(
          roleFilter: _selectedRole,
          startDate: _startDate,
          endDate: _endDate,
          limit: _itemsPerPage,
          offset: _currentPage * _itemsPerPage,
        ),
      );
      
      result.fold(
        (failure) {
          _evaluationsState = AdminLoadingState.error;
          _evaluationsError = failure.toString();
        },
        (evaluations) {
          _evaluationsState = AdminLoadingState.loaded;
          if (refresh) {
            _userEvaluations = evaluations;
          } else {
            _userEvaluations.addAll(evaluations);
          }
        },
      );
    } catch (e) {
      _evaluationsState = AdminLoadingState.error;
      _evaluationsError = 'Error inesperado: ${e.toString()}';
    }
    
    notifyListeners();
  }

  // Métodos para cargar categorías
  Future<void> loadAdminCategories({bool activeOnly = true}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _adminRepository.getAdminCategories(
        activeOnly: activeOnly,
      );
      
      result.fold(
        (failure) {
          _reportError = failure.toString();
        },
        (categories) {
          _adminCategories = categories;
          _reportError = null;
        },
      );
    } catch (e) {
      _reportError = 'Error inesperado: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para cargar hábitos
  Future<void> loadAdminHabits({
    String? categoryId,
    bool activeOnly = true,
    int? limit,
    int? offset,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _adminRepository.getAdminHabits(
        categoryId: categoryId,
        activeOnly: activeOnly,
        limit: limit,
        offset: offset,
      );
      
      result.fold(
        (failure) {
          _reportError = failure.toString();
        },
        (habits) {
          _adminHabits = habits;
          _reportError = null;
        },
      );
    } catch (e) {
      _reportError = 'Error inesperado: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para cargar indicadores de aceptación tecnológica
  Future<void> loadTechAcceptanceIndicators({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _indicatorsState = AdminLoadingState.loading;
    _indicatorsError = null;
    notifyListeners();

    try {
      final result = await getTechAcceptanceIndicatorsUseCase(
        GetTechAcceptanceIndicatorsParams(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      
      result.fold(
        (failure) {
          _indicatorsState = AdminLoadingState.error;
          _indicatorsError = failure.toString();
        },
        (indicators) {
          _indicatorsState = AdminLoadingState.loaded;
          _techAcceptanceIndicators = indicators;
        },
      );
    } catch (e) {
      _indicatorsState = AdminLoadingState.error;
      _indicatorsError = 'Error inesperado: ${e.toString()}';
    }
    
    notifyListeners();
  }

  // Métodos para cargar reportes consolidados
  Future<void> loadConsolidatedReport({
    String? roleFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _reportState = AdminLoadingState.loading;
    _reportError = null;
    notifyListeners();

    try {
      final result = await getConsolidatedReportUseCase(
        GetConsolidatedReportParams(
          roleFilter: roleFilter,
          startDate: startDate,
          endDate: endDate,
        ),
      );
      
      result.fold(
        (failure) {
          _reportState = AdminLoadingState.error;
          _reportError = failure.toString();
        },
        (report) {
          _reportState = AdminLoadingState.loaded;
          _consolidatedReport = report;
        },
      );
    } catch (e) {
      _reportState = AdminLoadingState.error;
      _reportError = 'Error inesperado: ${e.toString()}';
    }
    
    notifyListeners();
  }

  // Métodos para filtros
  void setRoleFilter(String? role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void clearFilters() {
    _selectedRole = null;
    _startDate = null;
    _endDate = null;
    _currentPage = 0;
    notifyListeners();
  }

  // Métodos para paginación
  void nextPage() {
    _currentPage++;
    notifyListeners();
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  // Métodos para limpiar errores
  void clearDashboardError() {
    _dashboardError = null;
    notifyListeners();
  }

  void clearEvaluationsError() {
    _evaluationsError = null;
    notifyListeners();
  }

  void clearIndicatorsError() {
    _indicatorsError = null;
    notifyListeners();
  }

  void clearReportError() {
    _reportError = null;
    notifyListeners();
  }

  void clearExportError() {
    _exportError = null;
    notifyListeners();
  }

  // Métodos CRUD para categorías
  Future<bool> createCategory({
    required String name,
    String? description,
    String? iconName,
    String? colorCode,
  }) async {
    try {
      final result = await _adminRepository.createAdminCategory(
        name: name,
        description: description,
        iconName: iconName,
        colorCode: colorCode,
      );
      
      return result.fold(
        (failure) {
          _reportError = failure.toString();
          notifyListeners();
          return false;
        },
        (category) {
          _adminCategories.add(category);
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _reportError = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    String? iconName,
    String? colorCode,
  }) async {
    try {
      final result = await _adminRepository.updateAdminCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        iconName: iconName,
        colorCode: colorCode,
      );
      
      return result.fold(
        (failure) {
          _reportError = failure.toString();
          notifyListeners();
          return false;
        },
        (updatedCategory) {
          final index = _adminCategories.indexWhere((cat) => cat.id == categoryId);
          if (index != -1) {
            _adminCategories[index] = updatedCategory;
            notifyListeners();
          }
          return true;
        },
      );
    } catch (e) {
      _reportError = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      final result = await _adminRepository.deleteAdminCategory(categoryId);
      
      return result.fold(
        (failure) {
          _reportError = failure.toString();
          notifyListeners();
          return false;
        },
        (success) {
          if (success) {
            _adminCategories.removeWhere((cat) => cat.id == categoryId);
            notifyListeners();
          }
          return success;
        },
      );
    } catch (e) {
      _reportError = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ==================== MÉTODOS CRUD PARA HÁBITOS ====================

  /// Crea un nuevo hábito
  Future<bool> createHabit({
    required String name,
    required String categoryId,
    String? description,
    String? iconName,
    String? colorCode,
    String? difficultyLevel,
    int? estimatedDuration,
  }) async {
    try {
      _isLoading = true;
      _reportError = null;
      notifyListeners();

      final result = await _adminRepository.createAdminHabit(
        name: name,
        categoryId: categoryId,
        description: description,
        iconName: iconName,
        colorCode: colorCode,
        difficultyLevel: difficultyLevel,
        estimatedDuration: estimatedDuration,
      );
      
      return result.fold(
        (failure) {
          _reportError = failure.toString();
          return false;
        },
        (habit) {
          _adminHabits.add(habit);
          return true;
        },
      );
    } catch (e) {
      _reportError = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza un hábito existente
  Future<bool> updateHabit({
    required String habitId,
    String? name,
    String? description,
    String? categoryId,
    String? iconName,
    String? colorCode,
    String? difficultyLevel,
    int? estimatedDuration,
    bool? isActive,
  }) async {
    try {
      _isLoading = true;
      _reportError = null;
      notifyListeners();

      final result = await _adminRepository.updateAdminHabit(
        habitId: habitId,
        name: name,
        description: description,
        categoryId: categoryId,
        iconName: iconName,
        colorCode: colorCode,
        difficultyLevel: difficultyLevel,
        estimatedDuration: estimatedDuration,
        isActive: isActive,
      );
      
      return result.fold(
        (failure) {
          _reportError = failure.toString();
          return false;
        },
        (updatedHabit) {
          final index = _adminHabits.indexWhere((habit) => habit.id == habitId);
          if (index != -1) {
            _adminHabits[index] = updatedHabit;
          }
          return true;
        },
      );
    } catch (e) {
      _reportError = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina un hábito
  Future<bool> deleteHabit(String habitId) async {
    try {
      _isLoading = true;
      _reportError = null;
      notifyListeners();

      final result = await _adminRepository.deleteAdminHabit(habitId);
      
      return result.fold(
        (failure) {
          _reportError = failure.toString();
          return false;
        },
        (success) {
          if (success) {
            _adminHabits.removeWhere((habit) => habit.id == habitId);
          }
          return success;
        },
      );
    } catch (e) {
      _reportError = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Exporta datos a Excel
  Future<String?> exportToExcel(String reportType, {DateTime? startDate, DateTime? endDate, Map<String, dynamic>? filters}) async {
    try {
      _isLoading = true;
      _reportError = null;
      notifyListeners();

      final params = ExportToExcelParams(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        filters: filters,
      );

      final result = await exportToExcelUseCase.call(params);
      
      return result.fold(
        (failure) {
          _reportError = failure.toString();
          return null;
        },
        (filePath) => filePath,
      );
    } catch (e) {
      _reportError = 'Error al exportar: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresca todos los datos del dashboard
  Future<void> refreshAllData() async {
    await Future.wait([
      loadDashboardStats(),
      loadAdminCategories(),
      loadAdminHabits(),
    ]);
  }
}