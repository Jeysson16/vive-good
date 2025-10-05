import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/profile_image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../presentation/blocs/profile/profile_bloc.dart';
import '../../presentation/blocs/profile/profile_event.dart';
import '../../presentation/blocs/profile/profile_state.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../services/storage_service.dart';
import '../../services/settings_service.dart';
import '../../data/services/notification_service.dart';
import '../../providers/theme_provider.dart';
import '../../presentation/widgets/connectivity_indicator.dart';

/// Vista principal del perfil del usuario
/// Sigue el diseño Figma Profile (2070_589)
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();
  final SettingsService _settingsService = SettingsService();
  final NotificationService _notificationService = NotificationService();
  final ProfileImageService _profileImageService = ProfileImageService();
  bool _isUploadingImage = false;
  bool _isExporting = false;
  
  // Variables de estado para configuraciones
  bool _notificationsEnabled = true;
  bool _alarmsEnabled = true;
  String _currentLanguage = 'es';
  
  // Getter para el tema oscuro


  @override
  void initState() {
    super.initState();
    // Cargar el perfil del usuario al inicializar
    context.read<ProfileBloc>().add(LoadUserProfile());
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getUserSettings();
      if (settings != null && mounted) {
        setState(() {
           _currentLanguage = settings['language'] ?? 'es';
           _notificationsEnabled = settings['notifications_enabled'] ?? true;
           _alarmsEnabled = settings['alarms_enabled'] ?? true;
         });
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;
        final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
        
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
            children: [
              // Offline banner at the top
              const OfflineBanner(),
              // Main content
              Expanded(
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    if (state is ProfileLoading) {
                      return const LoadingWidget();
                    } else if (state is ProfileError) {
                      return CustomErrorWidget(
                        message: state.message,
                        onRetry: () => context.read<ProfileBloc>().add(LoadUserProfile()),
                      );
                    } else if (state is ProfileLoaded) {
                      return _buildFullScreenScrollableProfile(context, state.profile);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullScreenScrollableProfile(BuildContext context, UserProfile userProfile) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header con foto de perfil
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Provider.of<ThemeProvider>(context, listen: false).isDarkMode 
                    ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                    : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                ),
              ),
              child: Column(
                children: [
                  _buildProfilePicture(userProfile),
                  const SizedBox(height: 16),
                  _buildUserName(userProfile),
                  const SizedBox(height: 8),
                  Text(
                    userProfile.email ?? 'Sin email',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido scrollable
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSettingsSection(cardColor, textColor),
                const SizedBox(height: 16),
                _buildHealthDataSection(cardColor, textColor),
                const SizedBox(height: 16),
                _buildActionsSection(cardColor, textColor),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(UserProfile profile) {
    return GestureDetector(
      onTap: _isUploadingImage ? null : _selectProfileImage,
      child: Container(
        width: 153,
        height: 153,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF219540),
            width: 3,
          ),
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // Imagen de perfil o avatar por defecto
              profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                  ? Image.network(
                      profile.profileImageUrl!,
                      fit: BoxFit.cover,
                      width: 153,
                      height: 153,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(profile);
                      },
                    )
                  : _buildDefaultAvatar(profile),
              
              // Indicador de carga cuando se está subiendo
              if (_isUploadingImage)
                Container(
                  width: 153,
                  height: 153,
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(UserProfile profile) {
    return Container(
      width: 153,
      height: 153,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE0E0E0),
      ),
      child: Icon(
        Icons.person,
        size: 80,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildUserName(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: SizedBox(
        width: 343,
        child: Text(
          profile.fullName.isNotEmpty ? profile.fullName : 'Usuario',
          textAlign: TextAlign.center,
          style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.4,
                    fontFamily: 'Roboto',
                  ),
        ),
      ),
     );
   }



  Widget _buildSettingsSection(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuraciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingToggle(
            icon: Icons.dark_mode,
            title: 'Tema Oscuro',
            subtitle: 'Cambiar entre tema claro y oscuro',
            value: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
            onChanged: (value) async {
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              await themeProvider.setTheme(value);
              await _settingsService.saveDarkTheme(value);
            },
          ),
          const SizedBox(height: 16),
          _buildSettingToggle(
            icon: Icons.notifications,
            title: 'Notificaciones',
            subtitle: 'Recibir notificaciones de la app',
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() {
                _notificationsEnabled = value;
              });
              await _settingsService.setNotifications(value);
              
              if (value) {
                await _notificationService.requestPermissions();
              }
            },
          ),
          const SizedBox(height: 16),
          _buildSettingToggle(
            icon: Icons.alarm,
            title: 'Alarmas',
            subtitle: 'Recordatorios y alarmas',
            value: _alarmsEnabled,
            onChanged: (value) async {
              setState(() {
                _alarmsEnabled = value;
              });
              await _settingsService.setAlarms(value);
            },
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.language,
            title: 'Idioma',
            subtitle: _currentLanguage == 'es' ? 'Español' : 'English',
            textColor: textColor,
            onTap: () => _showLanguageSelector(),
          ),
          const SizedBox(height: 12),
          _buildSettingItem(
            icon: Icons.info,
            title: 'Acerca de',
            subtitle: 'Información de la aplicación',
            textColor: textColor,
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textColor.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4CAF50),
            activeTrackColor: const Color(0xFF4CAF50).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Acerca de ViveGood',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF090D3A),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ViveGood App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF219540),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Versión 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Una aplicación para mejorar tu bienestar y crear hábitos saludables.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF090D3A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 ViveGood. Todos los derechos reservados.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Color(0xFF219540),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDataSection(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos de Salud',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHealthMetric(
                  'Peso',
                  '70 kg',
                  Icons.monitor_weight,
                  const Color(0xFF2196F3),
                  textColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHealthMetric(
                  'Altura',
                  '175 cm',
                  Icons.height,
                  const Color(0xFF4CAF50),
                  textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHealthMetric(
                  'IMC',
                  '22.9',
                  Icons.analytics,
                  const Color(0xFFFF9800),
                  textColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHealthMetric(
                  'Edad',
                  '28 años',
                  Icons.cake,
                  const Color(0xFF9C27B0),
                  textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Editar perfil
          _buildActionButton(
            icon: Icons.edit,
            title: 'Editar perfil',
            onTap: () {
              context.push('/edit-profile');
            },
          ),
          
          const Divider(),
          
          // Exportar historial
          _buildActionButton(
            icon: Icons.download,
            title: 'Exportar historial',
            onTap: _exportData,
          ),
          
          const Divider(),
          
          // Cerrar sesión
          _buildActionButton(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: textColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectProfileImage() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });
      
      // Mostrar opciones de selección
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) {
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }
      
      // Cambiar imagen de perfil usando el servicio
      final String? imageUrl = await _profileImageService.changeProfileImage(source: source);
      
      setState(() {
        _isUploadingImage = false;
      });
      
      if (imageUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen de perfil actualizada exitosamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        
        // Refrescar el perfil para mostrar la nueva imagen
        context.read<ProfileBloc>().add(const LoadUserProfile());
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar la imagen de perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: const Text('¿Desde dónde quieres seleccionar la imagen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Cámara'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Galería'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
  
  void _showLanguageSelector() {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccionar idioma',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption('es', 'Español', '🇪🇸'),
              _buildLanguageOption('en', 'English', '🇺🇸'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildLanguageOption(String code, String name, String flag) {
    final isSelected = _currentLanguage == code;
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return InkWell(
      onTap: () async {
        setState(() {
          _currentLanguage = code;
        });
        await _settingsService.setLanguage(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? const Color(0xFF4CAF50)
              : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _exportData() async {
    try {
      setState(() {
        _isExporting = true;
      });
      
      // Obtener datos del usuario
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Recopilar datos del perfil
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      // Recopilar datos de salud
      final healthData = await Supabase.instance.client
          .from('health_records')
          .select()
          .eq('user_id', user.id);
      
      // Recopilar configuraciones
      final settingsData = await _settingsService.getUserSettings();
      
      // Crear estructura de datos para exportar
      final exportData = {
        'user_info': {
          'email': user.email,
          'created_at': user.createdAt,
        },
        'profile': profileData,
        'health_records': healthData,
        'settings': settingsData,
        'export_date': DateTime.now().toIso8601String(),
      };
      
      // Convertir a JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Simular descarga (en una app real, usarías file_picker o similar)
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isExporting = false;
      });
      
      if (mounted) {
        // Mostrar diálogo con opción de compartir
        _showExportSuccessDialog(jsonString);
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showExportSuccessDialog(String jsonData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Datos Exportados'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tus datos han sido exportados exitosamente.'),
              const SizedBox(height: 16),
              const Text('Vista previa:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonData,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                // En una app real, aquí implementarías la funcionalidad de guardar/compartir
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad de guardado disponible en versión completa'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _logout() async {
    try {
      // Mostrar diálogo de confirmación
      final bool? shouldLogout = await _showLogoutConfirmationDialog();
      if (shouldLogout != true) return;
      
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cerrando sesión...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Cerrar sesión en Supabase
      await Supabase.instance.client.auth.signOut();
      
      // Limpiar datos locales
      await _settingsService.clearAllSettings();
      
      // Navegar a la pantalla de login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<bool?> _showLogoutConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  Color _getRiskFactorColor(String factor) {
    switch (factor) {
      case 'Come fuera frecuentemente':
        return const Color(0xFFFF9800);
      case 'Consume café en ayunas':
        return const Color(0xFF795548);
      case 'Fuma':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF666666);
    }
  }
}
