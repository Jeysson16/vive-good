import '../../../data/datasources/auth/deep_learning_auth_datasource.dart';

abstract class DeepLearningAuthRepository {
  /// Realiza el login con las credenciales del usuario
  /// [email] - Email del usuario que se ingresa en la interfaz de login
  /// [password] - Contraseña del usuario que se ingresa en la interfaz de login
  Future<LoginResponse> login(String email, String password);
  
  /// Obtiene el perfil del usuario autenticado
  Future<UserProfile> getUserProfile();
  
  /// Refresca el token de acceso
  Future<RefreshTokenResponse> refreshToken();
  
  /// Obtiene el token almacenado localmente
  Future<String?> getStoredToken();
  
  /// Cierra la sesión del usuario
  Future<void> logout();
  
  /// Verifica si el usuario está autenticado
  Future<bool> isAuthenticated();
  
  /// Obtiene un token válido (refresca automáticamente si es necesario)
  Future<String?> getValidToken();
}