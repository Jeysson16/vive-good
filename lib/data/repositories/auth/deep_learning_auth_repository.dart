import 'dart:developer' as developer;
import '../../datasources/auth/deep_learning_auth_datasource.dart';
import '../../../domain/repositories/auth/deep_learning_auth_repository.dart';

class DeepLearningAuthRepositoryImpl implements DeepLearningAuthRepository {
  final DeepLearningAuthDatasource datasource;

  DeepLearningAuthRepositoryImpl({required this.datasource});

  @override
  Future<LoginResponse> login(String email, String password) async {
    try {
      developer.log(
        '🏛️ [DL AUTH REPO] Iniciando login para email: $email',
        name: 'DeepLearningAuthRepository',
      );

      final request = LoginRequest(
        email: email,
        password: password,
      );

      final response = await datasource.login(request);

      developer.log(
        '✅ [DL AUTH REPO] Login exitoso para: ${response.userData.email}',
        name: 'DeepLearningAuthRepository',
      );

      return response;
    } catch (e) {
      developer.log(
        '❌ [DL AUTH REPO] Error en login: $e',
        name: 'DeepLearningAuthRepository',
      );
      rethrow;
    }
  }

  @override
  Future<UserProfile> getUserProfile() async {
    try {
      developer.log(
        '🏛️ [DL AUTH REPO] Obteniendo perfil de usuario...',
        name: 'DeepLearningAuthRepository',
      );

      final profile = await datasource.getMe();

      developer.log(
        '✅ [DL AUTH REPO] Perfil obtenido: ${profile.codigoUsuario}',
        name: 'DeepLearningAuthRepository',
      );

      return profile;
    } catch (e) {
      developer.log(
        '❌ [DL AUTH REPO] Error obteniendo perfil: $e',
        name: 'DeepLearningAuthRepository',
      );
      rethrow;
    }
  }

  @override
  Future<RefreshTokenResponse> refreshToken() async {
    try {
      developer.log(
        '🏛️ [DL AUTH REPO] Refrescando token...',
        name: 'DeepLearningAuthRepository',
      );

      final response = await datasource.refreshToken();

      developer.log(
        '✅ [DL AUTH REPO] Token refrescado exitosamente',
        name: 'DeepLearningAuthRepository',
      );

      return response;
    } catch (e) {
      developer.log(
        '❌ [DL AUTH REPO] Error refrescando token: $e',
        name: 'DeepLearningAuthRepository',
      );
      rethrow;
    }
  }

  @override
  Future<String?> getStoredToken() async {
    try {
      final token = await datasource.getStoredToken();
      
      developer.log(
        '🏛️ [DL AUTH REPO] Token obtenido: ${token != null ? "✅ Disponible" : "❌ No disponible"}',
        name: 'DeepLearningAuthRepository',
      );

      return token;
    } catch (e) {
      developer.log(
        '❌ [DL AUTH REPO] Error obteniendo token: $e',
        name: 'DeepLearningAuthRepository',
      );
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      developer.log(
        '🏛️ [DL AUTH REPO] Cerrando sesión...',
        name: 'DeepLearningAuthRepository',
      );

      await datasource.clearToken();

      developer.log(
        '✅ [DL AUTH REPO] Sesión cerrada exitosamente',
        name: 'DeepLearningAuthRepository',
      );
    } catch (e) {
      developer.log(
        '❌ [DL AUTH REPO] Error cerrando sesión: $e',
        name: 'DeepLearningAuthRepository',
      );
      rethrow;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final isValid = await datasource.isTokenValid();
      
      developer.log(
        '🏛️ [DL AUTH REPO] Estado de autenticación: ${isValid ? "✅ Autenticado" : "❌ No autenticado"}',
        name: 'DeepLearningAuthRepository',
      );

      return isValid;
    } catch (e) {
      developer.log(
        '❌ [DL AUTH REPO] Error verificando autenticación: $e',
        name: 'DeepLearningAuthRepository',
      );
      return false;
    }
  }

  @override
  Future<String?> getValidToken() async {
    try {
      // Verificar si el token actual es válido
      final isValid = await datasource.isTokenValid();
      
      if (isValid) {
        final token = await datasource.getStoredToken();
        developer.log(
          '✅ [DL AUTH REPO] Token válido obtenido',
          name: 'DeepLearningAuthRepository',
        );
        return token;
      } else {
        developer.log(
          '🔄 [DL AUTH REPO] Token expirado, intentando refresh...',
          name: 'DeepLearningAuthRepository',
        );
        
        // Intentar refresh del token
        try {
          await datasource.refreshToken();
          final newToken = await datasource.getStoredToken();
          
          developer.log(
            '✅ [DL AUTH REPO] Token refrescado y obtenido',
            name: 'DeepLearningAuthRepository',
          );
          
          return newToken;
        } catch (refreshError) {
          developer.log(
            '❌ [DL AUTH REPO] Error en refresh, token no disponible: $refreshError',
            name: 'DeepLearningAuthRepository',
          );
          return null;
        }
      }
    } catch (e) {
      developer.log(
        '❌ [DL AUTH REPO] Error obteniendo token válido: $e',
        name: 'DeepLearningAuthRepository',
      );
      return null;
    }
  }
}