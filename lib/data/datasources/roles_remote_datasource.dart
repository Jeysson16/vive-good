import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/exceptions.dart';
import '../models/role_model.dart';

abstract class RolesRemoteDataSource {
  Future<List<RoleModel>> getAllRoles();
  Future<RoleModel> getRoleById(String id);
  Future<RoleModel> createRole({required String name, String? description});
  Future<RoleModel> updateRole({required String id, String? name, String? description});
  Future<void> deleteRole(String id);
  Future<void> assignRoleToUser({required String userId, required String roleId});
  Future<void> removeRoleFromUser({required String userId, required String roleId});
  Future<List<RoleModel>> getUserRoles(String userId);
}

class RolesRemoteDataSourceImpl implements RolesRemoteDataSource {
  final SupabaseClient supabaseClient;

  RolesRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<RoleModel>> getAllRoles() async {
    try {
      final response = await supabaseClient
          .from('roles')
          .select('*')
          .order('name');

      return (response as List)
          .map((json) => RoleModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get roles: ${e.toString()}');
    }
  }

  @override
  Future<RoleModel> getRoleById(String id) async {
    try {
      final response = await supabaseClient
          .from('roles')
          .select('*')
          .eq('id', id)
          .single();

      return RoleModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to get role: ${e.toString()}');
    }
  }

  @override
  Future<RoleModel> createRole({required String name, String? description}) async {
    try {
      final response = await supabaseClient
          .from('roles')
          .insert({
            'name': name,
            'description': description,
          })
          .select()
          .single();

      return RoleModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create role: ${e.toString()}');
    }
  }

  @override
  Future<RoleModel> updateRole({required String id, String? name, String? description}) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;

      final response = await supabaseClient
          .from('roles')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return RoleModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update role: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteRole(String id) async {
    try {
      await supabaseClient
          .from('roles')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete role: ${e.toString()}');
    }
  }

  @override
  Future<void> assignRoleToUser({required String userId, required String roleId}) async {
    try {
      await supabaseClient
          .from('user_roles')
          .insert({
            'user_id': userId,
            'role_id': roleId,
          });
    } catch (e) {
      throw ServerException('Failed to assign role to user: ${e.toString()}');
    }
  }

  @override
  Future<void> removeRoleFromUser({required String userId, required String roleId}) async {
    try {
      await supabaseClient
          .from('user_roles')
          .delete()
          .eq('user_id', userId)
          .eq('role_id', roleId);
    } catch (e) {
      throw ServerException('Failed to remove role from user: ${e.toString()}');
    }
  }

  @override
  Future<List<RoleModel>> getUserRoles(String userId) async {
    try {
      final response = await supabaseClient
          .from('user_roles')
          .select('roles(*)')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => RoleModel.fromJson(item['roles']))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get user roles: ${e.toString()}');
    }
  }
}