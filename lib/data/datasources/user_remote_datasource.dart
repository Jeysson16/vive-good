import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../core/error/exceptions.dart';

abstract class UserRemoteDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> saveUser(UserModel user);
  Future<UserModel> updateUser(String userId, Map<String, dynamic> updates);
  Future<void> deleteUser(String userId);
  Future<List<UserModel>> getUsersNeedingSync();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient _supabaseClient;

  UserRemoteDataSourceImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) return null;

      // Obtener perfil del usuario
      final profile = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromSupabaseUser(user, profile: profile);
    } catch (e) {
      throw ServerException('Error al obtener usuario actual: $e');
    }
  }

  @override
  Future<UserModel> saveUser(UserModel user) async {
    try {
      // Actualizar perfil en Supabase
      final response = await _supabaseClient
          .from('profiles')
          .upsert({
            'id': user.id,
            'first_name': user.firstName,
            'last_name': user.lastName,
            'email': user.email,
            'avatar_url': user.avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw ServerException('Error al guardar usuario: $e');
    }
  }

  @override
  Future<UserModel> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw ServerException('Error al actualizar usuario: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _supabaseClient
          .from('profiles')
          .delete()
          .eq('id', userId);
    } catch (e) {
      throw ServerException('Error al eliminar usuario: $e');
    }
  }

  @override
  Future<List<UserModel>> getUsersNeedingSync() async {
    try {
      // En el contexto remoto, esto podría no ser necesario
      // pero lo implementamos para mantener la interfaz
      return [];
    } catch (e) {
      throw ServerException('Error al obtener usuarios que necesitan sincronización: $e');
    }
  }
}