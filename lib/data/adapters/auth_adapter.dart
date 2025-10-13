/// Adapter para convertir entre nomenclatura del frontend (inglés) 
/// y nomenclatura del backend (español/personalizada)
class AuthAdapter {
  /// Convierte los datos de registro del frontend al formato del backend
  static Map<String, dynamic> frontendToBackendRegister({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    // Combinar firstName y lastName para el campo 'nombre'
    final fullName = '$firstName $lastName'.trim();
    
    return {
      'cPerCodigo': email,      // Código de persona = email
      'email': email,           // Email se mantiene igual
      'password': password,     // Password se mantiene igual
      'nombre': fullName.isNotEmpty ? fullName : email, // Nombre completo o email como fallback
      'username': email,        // Username = email
    };
  }

  /// Convierte los datos de login del frontend al formato del backend
  static Map<String, dynamic> frontendToBackendLogin({
    required String email,
    required String password,
  }) {
    return {
      'email': email,
      'password': password,
    };
  }

  /// Convierte la respuesta del backend al formato del frontend
  /// Maneja el caso donde el backend no retorna datos
  static Map<String, dynamic> backendToFrontendResponse({
    required int statusCode,
    required String responseBody,
    required String email,
    required String firstName,
    required String lastName,
  }) {
    // Si el backend retorna 200/201 pero sin datos, crear respuesta exitosa
    if (statusCode >= 200 && statusCode < 300) {
      // Intentar parsear la respuesta si existe
      Map<String, dynamic>? parsedResponse;
      try {
        if (responseBody.isNotEmpty) {
          parsedResponse = Map<String, dynamic>.from(
            // Aquí podrías usar jsonDecode si el backend retorna JSON
            {'message': responseBody}
          );
        }
      } catch (e) {
        // Si no se puede parsear, ignorar
      }

      // Crear respuesta exitosa con datos del usuario
      return {
        'success': true,
        'user': {
          'id': _generateTempUserId(email), // ID temporal basado en email
          'email': email,
          'user_metadata': {
            'first_name': firstName,
            'last_name': lastName,
          },
        },
        'session': {
          'access_token': _generateTempToken(email), // Token temporal
          'refresh_token': _generateTempRefreshToken(email), // Refresh token temporal
        },
        'mensaje': parsedResponse?['message'] ?? 'Registro exitoso',
        'backend_response': parsedResponse,
      };
    } else {
      // Error del backend
      return {
        'success': false,
        'error': 'Error del servidor: $statusCode - $responseBody',
      };
    }
  }

  /// Genera un ID temporal para el usuario basado en el email
  static String _generateTempUserId(String email) {
    // Crear un ID único basado en el email
    return 'user_${email.hashCode.abs()}';
  }

  /// Genera un token temporal para la sesión
  static String _generateTempToken(String email) {
    // En un caso real, esto vendría del backend
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'temp_token_${email.hashCode.abs()}_$timestamp';
  }

  /// Genera un refresh token temporal
  static String _generateTempRefreshToken(String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'temp_refresh_${email.hashCode.abs()}_$timestamp';
  }
}