import 'package:permission_handler/permission_handler.dart';
import 'package:device_calendar/device_calendar.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  /// Solicita todos los permisos necesarios para la aplicación
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    // Solicitar permisos de notificación
    results['notification'] = await requestNotificationPermissions();
    
    // Solicitar permisos de calendario
    results['calendar'] = await requestCalendarPermissions();
    
    return results;
  }

  /// Solicita permisos de notificación
  Future<bool> requestNotificationPermissions() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      print('Error solicitando permisos de notificación: $e');
      return false;
    }
  }

  /// Solicita permisos de calendario
  Future<bool> requestCalendarPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      return permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
    } catch (e) {
      print('Error solicitando permisos de calendario: $e');
      return false;
    }
  }

  /// Verifica si los permisos de notificación están concedidos
  Future<bool> hasNotificationPermissions() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      print('Error verificando permisos de notificación: $e');
      return false;
    }
  }

  /// Verifica si los permisos de calendario están concedidos
  Future<bool> hasCalendarPermissions() async {
    try {
      final permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      return permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
    } catch (e) {
      print('Error verificando permisos de calendario: $e');
      return false;
    }
  }

  /// Abre la configuración de la aplicación para que el usuario pueda conceder permisos manualmente
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      print('Error abriendo configuración de la aplicación: $e');
      return false;
    }
  }

  /// Verifica el estado de todos los permisos
  Future<Map<String, bool>> checkAllPermissions() async {
    final results = <String, bool>{};

    results['notification'] = await hasNotificationPermissions();
    results['calendar'] = await hasCalendarPermissions();

    return results;
  }
}