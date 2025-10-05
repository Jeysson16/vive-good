import 'dart:async';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum ConnectionStatus {
  online,
  offline,
  unknown,
}

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<ConnectionStatus> get connectionStream;
  ConnectionStatus get currentStatus;
  Future<void> initialize();
  void dispose();
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;
  late StreamController<ConnectionStatus> _connectionController;
  late StreamSubscription _connectionSubscription;
  ConnectionStatus _currentStatus = ConnectionStatus.unknown;

  NetworkInfoImpl(this.connectionChecker) {
    _connectionController = StreamController<ConnectionStatus>.broadcast();
  }

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;

  @override
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  Future<void> initialize() async {
    // Verificar estado inicial
    final initialConnection = await isConnected;
    _currentStatus = initialConnection ? ConnectionStatus.online : ConnectionStatus.offline;
    _connectionController.add(_currentStatus);

    // Escuchar cambios de conectividad
    _connectionSubscription = connectionChecker.onStatusChange.listen(
      (InternetConnectionStatus status) {
        final newStatus = status == InternetConnectionStatus.connected
            ? ConnectionStatus.online
            : ConnectionStatus.offline;
        
        if (newStatus != _currentStatus) {
          _currentStatus = newStatus;
          _connectionController.add(_currentStatus);
        }
      },
    );
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    _connectionController.close();
  }
}