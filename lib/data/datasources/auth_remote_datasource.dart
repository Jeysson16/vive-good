import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_result_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResultModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AuthResultModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Future<void> resetPassword(String email);

  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<AuthResultModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Obtener el perfil del usuario con roles
        final profile = await _getUserProfile(response.user!.id);
        final userModel = UserModel.fromSupabaseUser(response.user!, profile: profile);
        return AuthResultModel.success(
          user: userModel,
          accessToken: response.session?.accessToken,
          refreshToken: response.session?.refreshToken,
        );
      } else {
        return AuthResultModel.failure('Error al iniciar sesión');
      }
    } on AuthException catch (e) {
      return AuthResultModel.failure(e.message);
    } catch (e) {
      return AuthResultModel.failure('Error inesperado: ${e.toString()}');
    }
  }

  @override
  Future<AuthResultModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      if (response.user != null) {
        
        // Esperar un momento para que el trigger procese
        await Future.delayed(Duration(milliseconds: 500));
        
        // Obtener el perfil completo con roles
        final profile = await _getUserProfile(response.user!.id);
        final userModel = UserModel.fromSupabaseUser(response.user!, profile: profile);
        
        
        return AuthResultModel.success(
          user: userModel,
          accessToken: response.session?.accessToken,
          refreshToken: response.session?.refreshToken,
        );
      } else {
        return AuthResultModel.failure('Error al crear usuario');
      }
    } on AuthException catch (e) {
      return AuthResultModel.failure(e.message);
    } catch (e) {
      return AuthResultModel.failure('Error inesperado al registrar usuario');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user != null) {
        final profile = await _getUserProfile(user.id);
        return UserModel.fromSupabaseUser(user, profile: profile);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario actual: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user != null) {
        final profile = await _getUserProfile(user.id);
        return UserModel.fromSupabaseUser(user, profile: profile);
      }
      return null;
    });
  }

  Future<void> _createUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      
      // Crear perfil
      await supabaseClient.from('profiles').insert({
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      });
      
      // Obtener rol de usuario por defecto
      final roleResponse = await supabaseClient
          .from('roles')
          .select('id')
          .eq('name', 'user')
          .single();
      
      // Asignar rol por defecto
      await supabaseClient.from('user_roles').insert({
        'user_id': userId,
        'role_id': roleResponse['id'],
      });
          
    } catch (e) {
      throw Exception('Error al crear perfil del usuario: $e');
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      
      // Primero obtener el perfil básico
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      
      if (profileResponse == null) {
        return null;
      }
      
      // Luego obtener los roles del usuario
      final rolesResponse = await supabaseClient
          .from('user_roles')
          .select('''
            roles!inner(
              id,
              name,
              description
            )
          ''')
          .eq('user_id', userId);
      
      // Combinar la información del perfil con los roles
      final response = Map<String, dynamic>.from(profileResponse);
      response['user_roles'] = rolesResponse;

          
      return response;
    } catch (e) {
      throw Exception('Error al obtener perfil del usuario: $e');
    }
  }
}