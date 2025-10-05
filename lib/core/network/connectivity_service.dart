import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vive_good_app/core/network/network_info.dart';

class ConnectivityService extends ChangeNotifier {
  final NetworkInfo _networkInfo;
  late StreamSubscription _connectionSubscription;
  
  ConnectionStatus _status = ConnectionStatus.unknown;
  bool _hasBeenOffline = false;
  DateTime? _lastOnlineTime;
  DateTime? _lastOfflineTime;

  ConnectivityService(this._networkInfo);

  // Getters
  ConnectionStatus get status => _status;
  bool get isOnline => _status == ConnectionStatus.online;
  bool get isOffline => _status == ConnectionStatus.offline;
  bool get hasBeenOffline => _hasBeenOffline;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  DateTime? get lastOfflineTime => _lastOfflineTime;

  // Stream para escuchar cambios de conectividad
  Stream<ConnectionStatus> get connectionStream => _networkInfo.connectionStream;

  Future<void> initialize() async {
    await _networkInfo.initialize();
    _status = _networkInfo.currentStatus;
    
    if (_status == ConnectionStatus.online) {
      _lastOnlineTime = DateTime.now();
    } else {
      _lastOfflineTime = DateTime.now();
      _hasBeenOffline = true;
    }

    _connectionSubscription = _networkInfo.connectionStream.listen(_onConnectionChanged);
    notifyListeners();
  }

  void _onConnectionChanged(ConnectionStatus newStatus) {
    final previousStatus = _status;
    _status = newStatus;

    if (newStatus == ConnectionStatus.online) {
      _lastOnlineTime = DateTime.now();
      if (previousStatus == ConnectionStatus.offline) {
        _onReconnected();
      }
    } else if (newStatus == ConnectionStatus.offline) {
      _lastOfflineTime = DateTime.now();
      _hasBeenOffline = true;
      _onDisconnected();
    }

    notifyListeners();
  }

  void _onReconnected() {
    debugPrint('🌐 Conectividad restaurada - iniciando sincronización');
    // Aquí se puede disparar eventos para sincronización
    _triggerSyncEvent();
  }

  void _onDisconnected() {
    debugPrint('🔌 Conexión perdida - modo offline activado');
  }

  void _triggerSyncEvent() {
    // Emitir evento para que los repositorios inicien sincronización
    // Esto se puede hacer a través de un EventBus o similar
  }

  Duration? getOfflineDuration() {
    if (_lastOfflineTime == null) return null;
    if (_status == ConnectionStatus.online && _lastOnlineTime != null) {
      return _lastOnlineTime!.difference(_lastOfflineTime!);
    }
    return DateTime.now().difference(_lastOfflineTime!);
  }

  Future<bool> checkConnection() async {
    return await _networkInfo.isConnected;
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    _networkInfo.dispose();
    super.dispose();
  }
}