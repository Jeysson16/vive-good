import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Modelos de datos para la autenticación
class LoginRequest {
  /// Email del usuario que se ingresa en la interfaz de login (viene de DL_EMAIL en .env)
  final String email;
  /// Contraseña del usuario que se ingresa en la interfaz de login (viene de DL_PASSWORD en .env)
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final UserData userData;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.userData,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken: json['access_token'] ?? '',
    tokenType: json['token_type'] ?? 'bearer',
    expiresIn: json['expires_in'] ?? 86400,
    userData: UserData.fromJson(json['user_data'] ?? {}),
  );
}

class UserData {
  final String id;
  final String codigoUsuario;
  final String email;
  final String nombre;

  UserData({
    required this.id,
    required this.codigoUsuario,
    required this.email,
    required this.nombre,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: json['id'] ?? '',
    codigoUsuario: json['codigo_usuario'] ?? '',
    email: json['email'] ?? '',
    nombre: json['nombre'] ?? '',
  );
}

class UserProfile {
  final String id;
  final String codigoUsuario;
  final String email;
  final String nombre;
  final String fechaRegistro;
  final bool activo;

  UserProfile({
    required this.id,
    required this.codigoUsuario,
    required this.email,
    required this.nombre,
    required this.fechaRegistro,
    required this.activo,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] ?? '',
    codigoUsuario: json['codigo_usuario'] ?? '',
    email: json['email'] ?? '',
    nombre: json['nombre'] ?? '',
    fechaRegistro: json['fecha_registro'] ?? '',
    activo: json['activo'] ?? false,
  );
}

class RefreshTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  RefreshTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) => RefreshTokenResponse(
    accessToken: json['access_token'] ?? '',
    tokenType: json['token_type'] ?? 'bearer',
    expiresIn: json['expires_in'] ?? 86400,
  );
}

// Datasource abstracto
abstract class DeepLearningAuthDatasource {
  Future<LoginResponse> login(LoginRequest request);
  Future<UserProfile> getMe();
  Future<RefreshTokenResponse> refreshToken();
  Future<String?> getStoredToken();
  Future<void> storeToken(String token);
  Future<void> clearToken();
  Future<bool> isTokenValid();
}

// Implementación del datasource
class DeepLearningAuthDatasourceImpl implements DeepLearningAuthDatasource {
  final http.Client client;
  final String baseUrl;
  final SharedPreferences prefs;
  
  static const String _tokenKey = 'dl_access_token';
  static const String _tokenExpiryKey = 'dl_token_expiry';

  DeepLearningAuthDatasourceImpl({
    required this.client,
    required this.baseUrl,
    required this.prefs,
  });

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final url = '$baseUrl/auth/login';
    
    developer.log(
      '🔐 [DL AUTH] Iniciando login...',
      name: 'DeepLearningAuth',
    );
    
    developer.log(
      '🔐 [DL AUTH] URL: $url',
      name: 'DeepLearningAuth',
    );
    
    developer.log(
      '🔐 [DL AUTH] Request body: ${jsonEncode(request.toJson())}',
      name: 'DeepLearningAuth',
    );

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      developer.log(
        '🔐 [DL AUTH] Response status: ${response.statusCode}',
        name: 'DeepLearningAuth',
      );
      
      developer.log(
        '🔐 [DL AUTH] Response body: ${response.body}',
        name: 'DeepLearningAuth',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(responseData);
        
        // Almacenar token y tiempo de expiración
        await storeToken(loginResponse.accessToken);
        final expiryTime = DateTime.now().add(Duration(seconds: loginResponse.expiresIn));
        await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
        
        developer.log(
          '✅ [DL AUTH] Login exitoso para email: ${loginResponse.userData.email}',
          name: 'DeepLearningAuth',
        );
        
        return loginResponse;
      } else {
        developer.log(
          '❌ [DL AUTH] Error en login: ${response.statusCode} - ${response.body}',
          name: 'DeepLearningAuth',
        );
        throw Exception('Error en login: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log(
        '💥 [DL AUTH] Excepción en login: $e',
        name: 'DeepLearningAuth',
      );
      throw Exception('Error de conexión en login: $e');
    }
  }

  @override
  Future<UserProfile> getMe() async {
    final token = await getStoredToken();
    if (token == null) {
      throw Exception('No hay token de acceso disponible');
    }

    final url = '$baseUrl/auth/me';
    
    developer.log(
      '👤 [DL AUTH] Obteniendo perfil de usuario...',
      name: 'DeepLearningAuth',
    );
    
    developer.log(
      '👤 [DL AUTH] URL: $url',
      name: 'DeepLearningAuth',
    );

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        '👤 [DL AUTH] Response status: ${response.statusCode}',
        name: 'DeepLearningAuth',
      );
      
      developer.log(
        '👤 [DL AUTH] Response body: ${response.body}',
        name: 'DeepLearningAuth',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userProfile = UserProfile.fromJson(responseData);
        
        developer.log(
          '✅ [DL AUTH] Perfil obtenido para: ${userProfile.codigoUsuario}',
          name: 'DeepLearningAuth',
        );
        
        return userProfile;
      } else if (response.statusCode == 401) {
        developer.log(
          '🔄 [DL AUTH] Token expirado, intentando refresh...',
          name: 'DeepLearningAuth',
        );
        // Token expirado, intentar refresh
        await refreshToken();
        // Reintentar la petición
        return getMe();
      } else {
        developer.log(
          '❌ [DL AUTH] Error obteniendo perfil: ${response.statusCode} - ${response.body}',
          name: 'DeepLearningAuth',
        );
        throw Exception('Error obteniendo perfil: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log(
        '💥 [DL AUTH] Excepción obteniendo perfil: $e',
        name: 'DeepLearningAuth',
      );
      throw Exception('Error de conexión obteniendo perfil: $e');
    }
  }

  @override
  Future<RefreshTokenResponse> refreshToken() async {
    final token = await getStoredToken();
    if (token == null) {
      throw Exception('No hay token para refresh');
    }

    final url = '$baseUrl/auth/refresh';
    
    developer.log(
      '🔄 [DL AUTH] Refrescando token...',
      name: 'DeepLearningAuth',
    );
    
    developer.log(
      '🔄 [DL AUTH] URL: $url',
      name: 'DeepLearningAuth',
    );

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        '🔄 [DL AUTH] Response status: ${response.statusCode}',
        name: 'DeepLearningAuth',
      );
      
      developer.log(
        '🔄 [DL AUTH] Response body: ${response.body}',
        name: 'DeepLearningAuth',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final refreshResponse = RefreshTokenResponse.fromJson(responseData);
        
        // Almacenar nuevo token y tiempo de expiración
        await storeToken(refreshResponse.accessToken);
        final expiryTime = DateTime.now().add(Duration(seconds: refreshResponse.expiresIn));
        await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
        
        developer.log(
          '✅ [DL AUTH] Token refrescado exitosamente',
          name: 'DeepLearningAuth',
        );
        
        return refreshResponse;
      } else {
        developer.log(
          '❌ [DL AUTH] Error refrescando token: ${response.statusCode} - ${response.body}',
          name: 'DeepLearningAuth',
        );
        // Si el refresh falla, limpiar tokens
        await clearToken();
        throw Exception('Error refrescando token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log(
        '💥 [DL AUTH] Excepción refrescando token: $e',
        name: 'DeepLearningAuth',
      );
      await clearToken();
      throw Exception('Error de conexión refrescando token: $e');
    }
  }

  @override
  Future<String?> getStoredToken() async {
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> storeToken(String token) async {
    await prefs.setString(_tokenKey, token);
    developer.log(
      '💾 [DL AUTH] Token almacenado',
      name: 'DeepLearningAuth',
    );
  }

  @override
  Future<void> clearToken() async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
    developer.log(
      '🗑️ [DL AUTH] Tokens eliminados',
      name: 'DeepLearningAuth',
    );
  }

  @override
  Future<bool> isTokenValid() async {
    final token = await getStoredToken();
    if (token == null) return false;

    final expiryString = prefs.getString(_tokenExpiryKey);
    if (expiryString == null) return false;

    final expiryTime = DateTime.parse(expiryString);
    final isValid = DateTime.now().isBefore(expiryTime);
    
    developer.log(
      '⏰ [DL AUTH] Token válido: $isValid (expira: $expiryTime)',
      name: 'DeepLearningAuth',
    );
    
    return isValid;
  }
}