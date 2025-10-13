import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejar conexiones en tiempo real de Supabase con renovación automática de tokens
class SupabaseRealtimeService {
  static final SupabaseRealtimeService _instance = SupabaseRealtimeService._internal();
  factory SupabaseRealtimeService() => _instance;
  SupabaseRealtimeService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  Timer? _tokenRefreshTimer;
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  
  /// Duración antes de la expiración para renovar el token (5 minutos antes)
  static const Duration _refreshBeforeExpiry = Duration(minutes: 5);
  


  /// Inicializa el servicio y configura la renovación automática de tokens
  Future<void> initialize() async {
    try {
      developer.log('Inicializando SupabaseRealtimeService', name: 'SupabaseRealtimeService');
      
      // Configurar listener para cambios de autenticación
      _client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final session = data.session;
        
        developer.log('Auth state changed: $event', name: 'SupabaseRealtimeService');
        
        if (event == AuthChangeEvent.signedIn && session != null) {
          _setupTokenRefresh(session);
        } else if (event == AuthChangeEvent.signedOut) {
          _cancelTokenRefresh();
          _closeAllSubscriptions();
        } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
          developer.log('Token refreshed successfully', name: 'SupabaseRealtimeService');
          _setupTokenRefresh(session);
        }
      });

      // Si ya hay una sesión activa, configurar renovación
      final currentSession = _client.auth.currentSession;
      if (currentSession != null) {
        _setupTokenRefresh(currentSession);
      }
      
    } catch (e, stackTrace) {
      developer.log(
        'Error inicializando SupabaseRealtimeService: $e',
        name: 'SupabaseRealtimeService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Configura el timer para renovación automática de tokens
  void _setupTokenRefresh(Session session) {
    _cancelTokenRefresh();
    
    try {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      final refreshAt = expiresAt.subtract(_refreshBeforeExpiry);
      final now = DateTime.now();
      
      if (refreshAt.isAfter(now)) {
        final duration = refreshAt.difference(now);
        developer.log(
          'Token refresh programado en ${duration.inMinutes} minutos',
          name: 'SupabaseRealtimeService',
        );
        
        _tokenRefreshTimer = Timer(duration, () async {
          await _refreshToken();
        });
      } else {
        // Si el token ya debería haberse renovado, hacerlo inmediatamente
        developer.log('Token necesita renovación inmediata', name: 'SupabaseRealtimeService');
        _refreshToken();
      }
    } catch (e) {
      developer.log(
        'Error configurando renovación de token: $e',
        name: 'SupabaseRealtimeService',
        error: e,
      );
    }
  }

  /// Renueva el token de autenticación
  Future<void> _refreshToken() async {
    try {
      developer.log('Renovando token JWT...', name: 'SupabaseRealtimeService');
      
      final response = await _client.auth.refreshSession();
      if (response.session != null) {
        developer.log('Token renovado exitosamente', name: 'SupabaseRealtimeService');
      } else {
        developer.log('Error renovando token', name: 'SupabaseRealtimeService');
      }
    } catch (e) {
      developer.log(
        'Error renovando token: $e',
        name: 'SupabaseRealtimeService',
        error: e,
      );
    }
  }

  /// Cancela el timer de renovación de tokens
  void _cancelTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }



  /// Método simplificado para manejar errores de token en streams
  void handleStreamError(dynamic error, String context) {
    developer.log('Error en $context: $error', name: 'SupabaseRealtimeService');
    
    // Si es un error de token expirado, intentar renovar
    if (error.toString().contains('InvalidJWTToken') || 
        error.toString().contains('Token has expired')) {
      developer.log('Token expirado detectado en $context, forzando renovación...', name: 'SupabaseRealtimeService');
      forceTokenRefresh();
    }
  }


  /// Cierra todas las suscripciones activas
  void _closeAllSubscriptions() {
    developer.log('Cerrando todas las suscripciones', name: 'SupabaseRealtimeService');
    
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
  }

  /// Verifica si hay una sesión activa y válida
  bool get hasValidSession {
    final session = _client.auth.currentSession;
    if (session == null) return false;
    
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return DateTime.now().isBefore(expiresAt);
  }

  /// Obtiene el número de suscripciones activas
  int get activeSubscriptionsCount => _activeSubscriptions.length;

  /// Fuerza la renovación del token
  Future<void> forceTokenRefresh() async {
    await _refreshToken();
  }

  /// Limpia recursos al destruir el servicio
  void dispose() {
    _cancelTokenRefresh();
    _closeAllSubscriptions();
  }
}