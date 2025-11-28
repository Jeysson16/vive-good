import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../presentation/blocs/profile/profile_bloc.dart';
import '../../presentation/blocs/profile/profile_event.dart';
import '../../presentation/blocs/profile/profile_state.dart';
import '../../presentation/blocs/habit/habit_bloc.dart';
import '../../presentation/blocs/habit/habit_event.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_event.dart';
import '../../presentation/blocs/auth/auth_state.dart' as auth_states;
import '../../presentation/widgets/profile/circular_profile_image.dart';
import '../../presentation/widgets/profile/profile_data_card.dart';
import '../../presentation/widgets/tech_acceptance_widget.dart';
import '../../presentation/widgets/symptoms_knowledge_widget.dart';
import '../../presentation/widgets/risk_habits_widget.dart';
import '../../services/profile_image_service.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';

/// Vista principal del perfil del usuario
/// Sigue el diseño Figma Profile (2070_589) exactamente
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileImageService _profileImageService = ProfileImageService();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // Cargar el perfil del usuario al inicializar
    context.read<ProfileBloc>().add(LoadUserProfile());
    // ✅ CARGAR HÁBITOS PARA OBTENER DATOS REALES
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<HabitBloc>().add(LoadUserHabits(userId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, auth_states.AuthState>(
          listener: (context, state) {
            if (state is auth_states.AuthUnauthenticated) {
              // Cerrar overlay de carga si está abierto
              if (_isLoggingOut) {
                setState(() {
                  _isLoggingOut = false;
                });
                Navigator.of(context).pop(); // Cerrar el overlay
              }
              // Navegar a la pantalla de welcome cuando el usuario cierre sesión
              context.go('/welcome');
            }
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            print('ProfileView - Estado recibido: ${state.runtimeType}');
            // Cuando el perfil se actualiza exitosamente, recargar los datos
            if (state is ProfileUpdated) {
              print('ProfileView - ProfileUpdated detectado, recargando perfil...');
              // Recargar el perfil para mostrar los cambios actualizados
              context.read<ProfileBloc>().add(LoadUserProfile());
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF), // Fondo blanco del Figma
        body: Column(
          children: [
            // Main content
            Expanded(
              child: BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  if (state is ProfileLoading) {
                    return const LoadingWidget();
                  } else if (state is ProfileError) {
                    return CustomErrorWidget(
                      message: state.message,
                      onRetry: () =>
                          context.read<ProfileBloc>().add(LoadUserProfile()),
                    );
                  } else if (state is ProfileLoaded) {
                    return _buildFigmaProfileDesign(context, state.profile);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFigmaProfileDesign(BuildContext context, UserProfile profile) {
    return Container(
      width: 375,
      color: const Color(0xFFFFFFFF), // Fondo blanco según Figma
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Padding superior
            const SizedBox(height: 60),

            // Foto de perfil circular editable (153x153px, centrada)
            EditableCircularProfileImage(
              profileImageUrl: profile.profileImageUrl,
              userId: profile.id,
              firstName: profile.firstName,
              lastName: profile.lastName,
              onImageChanged: (newImageUrl) {
                // Actualizar el perfil con la nueva imagen
                if (newImageUrl != null) {
                  context.read<ProfileBloc>().add(
                    UpdateProfilePictureEvent(profilePictureUrl: newImageUrl),
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // Nombre del usuario (centrado, Roboto 20px, peso 500, color #090D3A)
            Text(
              profile.fullName.isNotEmpty ? profile.fullName : 'Usuario',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF090D3A),
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Información adicional del usuario
            Text(
              _buildUserInfoText(profile),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFACADB9),
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Imagen principal con datos del perfil (333x458px)
            ProfileDataCard(profile: profile),

            const SizedBox(height: 24),

            // Sección de evaluaciones
            _buildAssessmentsSection(),

            const SizedBox(height: 24),

            // Botón de cerrar sesión
            _buildLogoutButton(context),

            // Padding inferior para la navegación
            const SizedBox(height: 160),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de evaluaciones
  Widget _buildAssessmentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evaluaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF090D3A),
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 12),
          
          // Tech Acceptance Widget - Always show in profile for editing
          TechAcceptanceWidget(
            showInProfile: true,
            onCompleted: () {
              // Refresh profile data if needed
            },
          ),
          
          const SizedBox(height: 8),
          
          // Symptoms Knowledge Widget - Always show in profile for editing
          SymptomsKnowledgeWidget(
            showInProfile: true,
            onCompleted: () {
              // Refresh profile data if needed
            },
          ),
          
          const SizedBox(height: 8),
          
          // Risk Habits Widget - Always show in profile for editing
          RiskHabitsWidget(
            showInProfile: true,
            onCompleted: () {
              // Refresh profile data if needed
            },
          ),
        ],
      ),
    );
  }

  /// Construye el texto de información del usuario
  String _buildUserInfoText(UserProfile profile) {
    final List<String> infoParts = [];

    // Agregar información disponible
    if (profile.institution != null && profile.institution!.isNotEmpty) {
      infoParts.add('Estudiante ${profile.institution}');
    } else {
      infoParts.add('Estudiante UCV'); // Valor por defecto según Figma
    }

    if (profile.age != null && profile.age! > 0) {
      infoParts.add('${profile.age} años');
    } else {
      infoParts.add('21 años'); // Valor por defecto según Figma
    }

    return infoParts.join(' | ');
  }

  /// Construye el botón de cerrar sesión
  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutConfirmationDialog(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E), // Color rojo para acción destructiva
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFFE53E3E).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra el diálogo de confirmación para cerrar sesión
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF090D3A),
            ),
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Mostrar overlay de carga y disparar el evento de cerrar sesión
                _showLoadingOverlay();
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Muestra el overlay de carga durante el logout
  void _showLoadingOverlay() {
    setState(() {
      _isLoggingOut = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevenir cerrar con botón atrás
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF090D3A),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cerrando sesión...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF090D3A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
