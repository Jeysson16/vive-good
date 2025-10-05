import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityType {
  wifi,
  mobile,
  ethernet,
  none,
}

class ConnectivityStatus {
  final ConnectivityType type;
  final bool isOnline;
  final DateTime lastChecked;
  final String? networkName;

  const ConnectivityStatus({
    required this.type,
    required this.isOnline,
    required this.lastChecked,
    this.networkName,
  });

  bool get isOffline => !isOnline;

  ConnectivityStatus copyWith({
    ConnectivityType? type,
    bool? isOnline,
    DateTime? lastChecked,
    String? networkName,
  }) {
    return ConnectivityStatus(
      type: type ?? this.type,
      isOnline: isOnline ?? this.isOnline,
      lastChecked: lastChecked ?? this.lastChecked,
      networkName: networkName ?? this.networkName,
    );
  }

  @override
  String toString() {
    return 'ConnectivityStatus(type: $type, isOnline: $isOnline, lastChecked: $lastChecked, networkName: $networkName)';
  }
}

class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance ??= ConnectivityService._();
  
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _connectivityController = 
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus(
    type: ConnectivityType.none,
    isOnline: false,
    lastChecked: DateTime.now(),
  );

  Timer? _pingTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters
  Stream<ConnectivityStatus> get connectivityStream => _connectivityController.stream;
  ConnectivityStatus get currentStatus => _currentStatus;
  bool get isOnline => _currentStatus.isOnline;
  bool get isOffline => !_currentStatus.isOnline;

  /// Inicializa el servicio de conectividad
  Future<void> initialize() async {
    // Verificar estado inicial
    await _checkConnectivity();
    
    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        print('Error en conectividad: $error');
      },
    );

    // Verificar conectividad real cada 30 segundos
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkRealConnectivity();
    });
  }

  /// Obtiene el estado actual de conectividad
  Future<ConnectivityStatus> getCurrentConnectivityStatus() async {
    await _checkConnectivity();
    return _currentStatus;
  }

  /// Verifica si hay conexión real a internet
  Future<bool> hasInternetConnection() async {
    try {
      print('   - Attempting DNS lookup to google.com...');
      final result = await InternetAddress.lookup('google.com');
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      print('   - DNS lookup result: ${result.length} addresses found');
      if (result.isNotEmpty) {
        print('   - First address: ${result[0].address}');
      }
      return hasConnection;
    } catch (e) {
      print('   - DNS lookup failed: $e');
      return false;
    }
  }

  /// Maneja cambios en la conectividad
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _checkConnectivity();
  }

  /// Verifica el estado de conectividad
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final type = _mapConnectivityResult(connectivityResult.first);
      
      print('🌐 [DEBUG] ConnectivityService - Checking connectivity...');
      print('   - Network type: $type');
      
      // Si hay conexión de red, verificar conexión real a internet
      bool hasInternet = false;
      if (type != ConnectivityType.none) {
        print('   - Network detected, checking internet access...');
        hasInternet = await hasInternetConnection();
        print('   - Internet access: $hasInternet');
      } else {
        print('   - No network detected');
      }

      final newStatus = ConnectivityStatus(
        type: type,
        isOnline: hasInternet,
        lastChecked: DateTime.now(),
        networkName: await _getNetworkName(connectivityResult.first),
      );

      print('   - Final status: ${newStatus.isOnline ? "ONLINE" : "OFFLINE"}');
      _updateStatus(newStatus);
    } catch (e) {
      print('❌ [DEBUG] ConnectivityService - Error checking connectivity: $e');
      _updateStatus(ConnectivityStatus(
        type: ConnectivityType.none,
        isOnline: false,
        lastChecked: DateTime.now(),
      ));
    }
  }

  /// Verifica conectividad real periódicamente
  Future<void> _checkRealConnectivity() async {
    if (_currentStatus.type != ConnectivityType.none) {
      final hasInternet = await hasInternetConnection();
      if (hasInternet != _currentStatus.isOnline) {
        final newStatus = _currentStatus.copyWith(
          isOnline: hasInternet,
          lastChecked: DateTime.now(),
        );
        _updateStatus(newStatus);
      }
    }
  }

  /// Actualiza el estado y notifica a los listeners
  void _updateStatus(ConnectivityStatus newStatus) {
    final wasOnline = _currentStatus.isOnline;
    _currentStatus = newStatus;
    
    // Notificar cambio
    _connectivityController.add(_currentStatus);
    
    // Log de cambios importantes
    if (wasOnline != newStatus.isOnline) {
      print('Conectividad cambió: ${wasOnline ? 'Online' : 'Offline'} -> ${newStatus.isOnline ? 'Online' : 'Offline'}');
    }
  }

  /// Mapea el resultado de conectividad a nuestro enum
  ConnectivityType _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectivityType.wifi;
      case ConnectivityResult.mobile:
        return ConnectivityType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectivityType.ethernet;
      case ConnectivityResult.none:
      default:
        return ConnectivityType.none;
    }
  }

  /// Obtiene el nombre de la red (si está disponible)
  Future<String?> _getNetworkName(ConnectivityResult result) async {
    try {
      if (result == ConnectivityResult.wifi) {
        // En una implementación real, podrías obtener el SSID de la WiFi
        return 'WiFi Network';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fuerza una verificación de conectividad
  Future<void> forceCheck() async {
    await _checkConnectivity();
  }

  /// Libera recursos
  void dispose() {
    _pingTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}