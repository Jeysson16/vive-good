import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

/// Vista principal del perfil del usuario
/// Sigue el diseño Figma Profile (2070_589)
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    // Cargar el perfil del usuario al inicializar
    context.read<ProfileBloc>().add(LoadUserProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const LoadingWidget();
          }

          if (state is ProfileError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: () => context.read<ProfileBloc>().add(LoadUserProfile()),
            );
          }

          if (state is ProfileLoaded) {
            return _buildProfileContent(context, state.profile);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfile profile) {
    return CustomScrollView(
      slivers: [
        // Header con foto de perfil y datos básicos
        _buildProfileHeader(context, profile),

        // Contenido principal
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Datos de salud
                _buildHealthDataSection(profile),
                const SizedBox(height: 24),

                // Hábitos activos
                _buildActiveHabitsSection(profile),
                const SizedBox(height: 24),

                // Configuraciones inteligentes
                _buildSmartSettingsSection(context, profile),
                const SizedBox(height: 24),

                // Acciones
                _buildActionsSection(context, profile),
                const SizedBox(height: 100), // Espacio para bottom navigation
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile profile) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Foto de perfil
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFFF5F5F5),
                    backgroundImage: profile.profileImageUrl != null
                        ? NetworkImage(profile.profileImageUrl!)
                        : null,
                    child: profile.profileImageUrl == null
                        ? Text(
                            profile.firstName.isNotEmpty
                                ? profile.firstName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF666666),
                            ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                // Nombre completo
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                ),

                const SizedBox(height: 8),

                // Información adicional
                Text(
                  '${profile.institution ?? 'UCV'} | ${profile.age ?? 'Sin especificar'} años',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthDataSection(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos de salud',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 16),

          // Altura y Peso
          Row(
            children: [
              Expanded(
                child: _buildHealthMetric(
                  icon: Icons.height,
                  label: 'Altura',
                  value: profile.formattedHeight,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHealthMetric(
                  icon: Icons.monitor_weight,
                  label: 'Peso',
                  value: profile.formattedWeight,
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Factores de riesgo
          const Text(
            'Factores de riesgo:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 12),

          if (profile.riskFactors.isEmpty)
            const Text(
              'Sin factores de riesgo registrados',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...profile.riskFactors.map(
              (factor) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getRiskFactorColor(factor),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        factor,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveHabitsSection(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hábitos activos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 16),

          // Hidratación
          _buildHabitProgress(
            icon: Icons.water_drop,
            label: 'Hidratación',
            progress: profile.formattedHydrationProgress,
            progressValue: profile.hydrationProgress / profile.hydrationGoal,
            color: const Color(0xFF2196F3),
          ),

          const SizedBox(height: 16),

          // Sueño
          _buildHabitProgress(
            icon: Icons.bedtime,
            label: 'Sueño',
            progress: profile.formattedSleepProgress,
            progressValue: profile.sleepProgress / profile.sleepGoal,
            color: const Color(0xFF9C27B0),
          ),

          const SizedBox(height: 16),

          // Actividad
          _buildHabitProgress(
            icon: Icons.directions_run,
            label: 'Actividad',
            progress: profile.formattedActivityProgress,
            progressValue: profile.activityProgress / profile.activityGoal,
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitProgress({
    required IconData icon,
    required String label,
    required String progress,
    required double progressValue,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  Text(
                    progress,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressValue.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartSettingsSection(BuildContext context, UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuraciones inteligentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 16),

          // Sugerencias automáticas
          _buildSettingToggle(
            label: 'Sugerencias automáticas',
            value: profile.autoSuggestionsEnabled,
            onChanged: (value) {
              context.read<ProfileBloc>().add(
                UpdateSmartSettings(autoSuggestionsEnabled: value),
              );
            },
          ),

          const SizedBox(height: 16),

          // Recordatorios diarios
          const Text(
            'Recordatorios diarios',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTimeDisplay(
                  label: 'Mañana',
                  time: profile.formattedMorningTime,
                  icon: Icons.wb_sunny,
                  color: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeDisplay(
                  label: 'Noche',
                  time: profile.formattedEveningTime,
                  icon: Icons.nightlight_round,
                  color: const Color(0xFF3F51B5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E2E2E),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildTimeDisplay({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, UserProfile profile) {
    return Column(
      children: [
        // Editar perfil
        _buildActionButton(
          icon: Icons.edit,
          label: 'Editar perfil',
          color: const Color(0xFF4CAF50),
          onTap: () {
            context.push(AppRoutes.editProfile, extra: profile);
          },
        ),

        const SizedBox(height: 12),

        // Exportar historial
        _buildActionButton(
          icon: Icons.download,
          label: 'Exportar historial',
          color: const Color(0xFF2196F3),
          onTap: () {
            context.read<ProfileBloc>().add(ExportUserHistory());
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
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
