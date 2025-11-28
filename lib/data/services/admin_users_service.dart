import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class AdminUsersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener todos los usuarios
  Future<List<UserEntity>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name, avatar_url, role, is_active, created_at, updated_at')
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => UserEntity(
                id: user['id'] as String,
                email: user['email'] as String? ?? '',
                fullName: user['full_name'] as String?,
                avatarUrl: user['avatar_url'] as String?,
                role: user['role'] as String? ?? 'user',
                isActive: user['is_active'] as bool? ?? true,
                createdAt: DateTime.parse(user['created_at'] as String),
                updatedAt: user['updated_at'] != null 
                    ? DateTime.parse(user['updated_at'] as String)
                    : null,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  // Crear un nuevo usuario
  Future<UserEntity> createUser({
    required String email,
    required String password,
    String? fullName,
    String role = 'user',
  }) async {
    try {
      // Crear usuario en auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Error al crear usuario en auth');
      }

      // Crear perfil en la tabla profiles
      final profileData = {
        'id': authResponse.user!.id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('profiles').insert(profileData);

      return UserEntity(
        id: authResponse.user!.id,
        email: email,
        fullName: fullName,
        avatarUrl: null,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: null,
      );
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  // Actualizar un usuario
  Future<UserEntity> updateUser({
    required String userId,
    String? email,
    String? fullName,
    String? role,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (email != null) updateData['email'] = email;
      if (fullName != null) updateData['full_name'] = fullName;
      if (role != null) updateData['role'] = role;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserEntity(
        id: response['id'] as String,
        email: response['email'] as String,
        fullName: response['full_name'] as String?,
        avatarUrl: response['avatar_url'] as String?,
        role: response['role'] as String,
        isActive: response['is_active'] as bool,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  // Eliminar un usuario (soft delete)
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // Buscar usuarios por email o nombre
  Future<List<UserEntity>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name, avatar_url, role, is_active, created_at, updated_at')
          .or('email.ilike.%$query%,full_name.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => UserEntity(
                id: user['id'] as String,
                email: user['email'] as String? ?? '',
                fullName: user['full_name'] as String?,
                avatarUrl: user['avatar_url'] as String?,
                role: user['role'] as String? ?? 'user',
                isActive: user['is_active'] as bool? ?? true,
                createdAt: DateTime.parse(user['created_at'] as String),
                updatedAt: user['updated_at'] != null 
                    ? DateTime.parse(user['updated_at'] as String)
                    : null,
              ))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios: $e');
    }
  }

  // Obtener roles disponibles
  Future<List<String>> getAvailableRoles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .not('role', 'is', null);

      final roles = (response as List)
          .map((item) => item['role'] as String)
          .toSet()
          .toList();

      // Agregar roles predeterminados si no existen
      final defaultRoles = ['admin', 'user', 'moderator'];
      for (final role in defaultRoles) {
        if (!roles.contains(role)) {
          roles.add(role);
        }
      }

      return roles;
    } catch (e) {
      return ['admin', 'user', 'moderator']; // Roles por defecto en caso de error
    }
  }
}