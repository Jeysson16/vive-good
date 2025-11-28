import 'package:flutter/material.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/usecases/roles/create_role_usecase.dart';
import '../../domain/usecases/roles/delete_role_usecase.dart';
import '../../domain/usecases/roles/get_all_roles_usecase.dart';
import '../../domain/usecases/roles/update_role_usecase.dart';

class RolesProvider extends ChangeNotifier {
  final GetAllRolesUseCase getAllRolesUseCase;
  final CreateRoleUseCase createRoleUseCase;
  final UpdateRoleUseCase updateRoleUseCase;
  final DeleteRoleUseCase deleteRoleUseCase;

  RolesProvider({
    required this.getAllRolesUseCase,
    required this.createRoleUseCase,
    required this.updateRoleUseCase,
    required this.deleteRoleUseCase,
  });

  List<RoleEntity> _roles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RoleEntity> get roles => _roles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRoles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await getAllRolesUseCase(NoParams());
    
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (roles) {
        _roles = roles;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> createRole({
    required String name,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await createRoleUseCase(
      CreateRoleParams(name: name, description: description),
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (role) {
        _roles.add(role);
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> updateRole({
    required String id,
    String? name,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await updateRoleUseCase(
      UpdateRoleParams(id: id, name: name, description: description),
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (updatedRole) {
        final index = _roles.indexWhere((role) => role.id == id);
        if (index != -1) {
          _roles[index] = updatedRole;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> deleteRole(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await deleteRoleUseCase(DeleteRoleParams(id: id));

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        _roles.removeWhere((role) => role.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}