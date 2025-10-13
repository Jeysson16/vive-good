import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'auth_remote_datasource.dart';
import '../models/auth_result_model.dart';
import '../models/user_model.dart';
import '../adapters/auth_adapter.dart';

class AuthCustomRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client httpClient;
  final String baseUrl;

  AuthCustomRemoteDataSourceImpl({
    required this.httpClient,
    required this.baseUrl,
  });

  @override
  Future<AuthResultModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final url = '$baseUrl/auth/login';
      
      developer.log(
        '🔐 [CUSTOM AUTH] Iniciando login...',
        name: 'AuthCustomRemoteDataSource',
      );
      
      developer.log(
        '🔐 [CUSTOM AUTH] URL: $url',
        name: 'AuthCustomRemoteDataSource',
      );

      final requestBody = {
        'email': email,
        'password': password,
      };

      developer.log(
        '🔐 [CUSTOM AUTH] Request body: ${jsonEncode(requestBody)}',
        name: 'AuthCustomRemoteDataSource',
      );

      final response = await httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      developer.log(
        '🔐 [CUSTOM AUTH] Response status: ${response.statusCode}',
        name: 'AuthCustomRemoteDataSource',
      );
      
      developer.log(
        '🔐 [CUSTOM AUTH] Response body: ${response.body}',
        name: 'AuthCustomRemoteDataSource',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extraer datos del usuario de la respuesta
        final userData = responseData['user'];
        final sessionData = responseData['session'];
        final mensaje = responseData['mensaje'];

        // Crear UserModel desde la respuesta del backend
        final userMetadata = userData['user_metadata'] ?? {};
        final firstName = userMetadata['first_name'] ?? '';
        final lastName = userMetadata['last_name'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        
        final userModel = UserModel(
          id: userData['id'],
          name: fullName.isNotEmpty ? fullName : userData['email'],
          email: userData['email'],
          firstName: firstName,
          lastName: lastName,
          isFirstTime: false, // Usuario ya registrado
          hasCompletedOnboarding: true, // Asumir que ya completó onboarding
        );

        developer.log(
          '✅ [CUSTOM AUTH] Login exitoso para email: ${userModel.email}',
          name: 'AuthCustomRemoteDataSource',
        );

        return AuthResultModel.success(
          user: userModel,
          accessToken: sessionData['access_token'],
          refreshToken: sessionData['refresh_token'],
        );
      } else {
        final errorMessage = 'Error en login: ${response.statusCode} - ${response.body}';
        developer.log(
          '❌ [CUSTOM AUTH] $errorMessage',
          name: 'AuthCustomRemoteDataSource',
        );
        return AuthResultModel.failure(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Error de conexión en login: $e';
      developer.log(
        '💥 [CUSTOM AUTH] $errorMessage',
        name: 'AuthCustomRemoteDataSource',
      );
      return AuthResultModel.failure(errorMessage);
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
      final url = '$baseUrl/auth/register';
      
      developer.log(
        '📝 [CUSTOM AUTH] Iniciando registro...',
        name: 'AuthCustomRemoteDataSource',
      );
      
      developer.log(
        '📝 [CUSTOM AUTH] URL: $url',
        name: 'AuthCustomRemoteDataSource',
      );

      // Usar el adapter para convertir nomenclatura frontend a backend
      final requestBody = AuthAdapter.frontendToBackendRegister(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      developer.log(
        '📝 [CUSTOM AUTH] Request body (frontend -> backend): ${jsonEncode(requestBody)}',
        name: 'AuthCustomRemoteDataSource',
      );

      final response = await httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      developer.log(
        '📝 [CUSTOM AUTH] Response status: ${response.statusCode}',
        name: 'AuthCustomRemoteDataSource',
      );
      
      developer.log(
        '📝 [CUSTOM AUTH] Response body: ${response.body}',
        name: 'AuthCustomRemoteDataSource',
      );

      // Usar el adapter para manejar la respuesta del backend
      final adaptedResponse = AuthAdapter.backendToFrontendResponse(
        statusCode: response.statusCode,
        responseBody: response.body,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );

      if (adaptedResponse['success'] == true) {
        // Extraer datos del usuario de la respuesta adaptada
        final userData = adaptedResponse['user'];
        final sessionData = adaptedResponse['session'];
        final mensaje = adaptedResponse['mensaje'];

        // Crear UserModel desde la respuesta adaptada
        final userMetadata = userData['user_metadata'] ?? {};
        final userFirstName = userMetadata['first_name'] ?? firstName;
        final userLastName = userMetadata['last_name'] ?? lastName;
        final fullName = '$userFirstName $userLastName'.trim();
        
        final userModel = UserModel(
          id: userData['id'],
          name: fullName.isNotEmpty ? fullName : userData['email'],
          email: userData['email'],
          firstName: userFirstName,
          lastName: userLastName,
          isFirstTime: true, // Usuario recién registrado
          hasCompletedOnboarding: false, // Necesita completar onboarding
        );

        developer.log(
          '✅ [CUSTOM AUTH] Registro exitoso para email: ${userModel.email}',
          name: 'AuthCustomRemoteDataSource',
        );

        developer.log(
          '✅ [CUSTOM AUTH] Mensaje del servidor: $mensaje',
          name: 'AuthCustomRemoteDataSource',
        );

        return AuthResultModel.success(
          user: userModel,
          accessToken: sessionData['access_token'],
          refreshToken: sessionData['refresh_token'],
        );
      } else {
        final errorMessage = adaptedResponse['error'] ?? 'Error desconocido en registro';
        developer.log(
          '❌ [CUSTOM AUTH] $errorMessage',
          name: 'AuthCustomRemoteDataSource',
        );
        return AuthResultModel.failure(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Error de conexión en registro: $e';
      developer.log(
        '💥 [CUSTOM AUTH] $errorMessage',
        name: 'AuthCustomRemoteDataSource',
      );
      return AuthResultModel.failure(errorMessage);
    }
  }

  @override
  Future<void> signOut() async {
    // Implementar logout si es necesario
    developer.log(
      '🔐 [CUSTOM AUTH] Cerrando sesión...',
      name: 'AuthCustomRemoteDataSource',
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // Implementar obtener usuario actual si es necesario
    return null;
  }

  @override
  Future<void> resetPassword(String email) async {
    // Implementar reset de contraseña si es necesario
    throw Exception('Reset de contraseña no implementado para backend personalizado');
  }

  @override
  Stream<UserModel?> get authStateChanges {
    // Para el backend personalizado, podríamos implementar un stream
    // que verifique periódicamente el estado del token
    return Stream.value(null);
  }
}