import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';
import '../../presentation/blocs/profile/profile_bloc.dart';
import '../../presentation/blocs/profile/profile_event.dart';
import '../../presentation/blocs/profile/profile_state.dart';
import '../../widgets/common/loading_widget.dart';

/// Vista de edición del perfil del usuario
class EditProfileView extends StatefulWidget {
  final UserProfile profile;

  const EditProfileView({super.key, required this.profile});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controladores de texto
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;
  late final TextEditingController _institutionController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _morningTimeController;
  late final TextEditingController _eveningTimeController;

  // Variables de estado
  String? _selectedImagePath;
  List<String> _selectedRiskFactors = [];
  bool _autoSuggestionsEnabled = false;
  
  // Variables para controlar el guardado
  bool _isSaving = false;
  bool _hasNavigated = false;

  // Opciones de factores de riesgo
  final List<String> _riskFactorOptions = [
    'Come fuera frecuentemente',
    'Consume café en ayunas',
    'Fuma',
    'Consume alcohol frecuentemente',
    'Vida sedentaria',
    'Estrés crónico',
    'Poco descanso',
    'Dieta alta en azúcar',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(
      text: widget.profile.firstName,
    );
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _emailController = TextEditingController(text: widget.profile.email);
    _ageController = TextEditingController(
      text: widget.profile.age?.toString() ?? '',
    );
    _institutionController = TextEditingController(
      text: widget.profile.institution ?? '',
    );
    _heightController = TextEditingController(
      text: widget.profile.heightCm != null 
          ? (widget.profile.heightCm! / 100).toStringAsFixed(2)
          : '',
    );
    _weightController = TextEditingController(
      text: widget.profile.weightKg?.toString() ?? '',
    );
    _morningTimeController = TextEditingController(
      text: widget.profile.morningReminderTime ?? '8:00',
    );
    _eveningTimeController = TextEditingController(
      text: widget.profile.eveningReminderTime ?? '21:30',
    );

    _selectedRiskFactors = List.from(widget.profile.riskFactors);
    _autoSuggestionsEnabled = widget.profile.autoSuggestionsEnabled;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _institutionController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _morningTimeController.dispose();
    _eveningTimeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          print('EditProfileView - Estado recibido: ${state.runtimeType}');
          
          // Evitar múltiples navegaciones
          if (_hasNavigated) return;
          
          if (state is ProfileUpdated) {
            print('EditProfileView - ProfileUpdated: ${state.message}');
            // Solo mostrar mensaje y cerrar si no hay imagen pendiente por subir
            if (_selectedImagePath == null) {
              _showSuccessAndClose(state.message);
            } else {
              print('EditProfileView - Perfil actualizado, esperando imagen...');
            }
          } else if (state is ProfileImageUpdated) {
            print('EditProfileView - ProfileImageUpdated');
            _showSuccessAndClose('Perfil e imagen actualizados exitosamente');
          } else if (state is ProfileError) {
            print('EditProfileView - ProfileError: ${state.message}');
            setState(() {
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFF44336),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = _isSaving || state is ProfileUpdating || state is ProfileImageUploading;
          print('EditProfileView - Builder ejecutado, isLoading: $isLoading, estado: ${state.runtimeType}');
          
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: const Text(
                'Editar perfil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF2E2E2E)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: isLoading ? null : () => _onWillPop().then((shouldPop) {
                  if (shouldPop) Navigator.pop(context);
                }),
              ),
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto de perfil
                    _buildProfileImageSection(),
                    const SizedBox(height: 32),

                    // Información personal
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),

                    // Datos de salud
                    _buildHealthDataSection(),
                    const SizedBox(height: 24),

                    // Factores de riesgo
                    _buildRiskFactorsSection(),
                    const SizedBox(height: 24),

                    // Configuraciones inteligentes
                    _buildSmartSettingsSection(),
                    const SizedBox(height: 100), // Espacio para el botón flotante
                  ],
                ),
              ),
            ),
            floatingActionButton: _buildFloatingActionButton(isLoading),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4CAF50), width: 3),
                ),
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: const Color(0xFFF5F5F5),
                  backgroundImage: _selectedImagePath != null
                      ? AssetImage(_selectedImagePath!) // Para imagen local
                      : (widget.profile.profileImageUrl != null
                                ? NetworkImage(widget.profile.profileImageUrl!)
                                : null)
                            as ImageProvider?,
                  child:
                      _selectedImagePath == null &&
                          widget.profile.profileImageUrl == null
                      ? Text(
                          widget.profile.firstName.isNotEmpty
                              ? widget.profile.firstName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF666666),
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Toca para cambiar foto',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Información personal',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                label: 'Nombre',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _lastNameController,
                label: 'Apellido',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El apellido es obligatorio';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Correo electrónico',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          enabled: false, // Email no editable
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _ageController,
                label: 'Edad',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Edad inválida';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _institutionController,
                label: 'Institución',
                icon: Icons.school,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthDataSection() {
    return _buildSection(
      title: 'Datos de salud',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _heightController,
                label: 'Altura (m)',
                icon: Icons.height,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final height = double.tryParse(value);
                    if (height == null || height < 0.5 || height > 3.0) {
                      return 'Altura inválida';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _weightController,
                label: 'Peso (kg)',
                icon: Icons.monitor_weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final weight = double.tryParse(value);
                    if (weight == null || weight < 20 || weight > 300) {
                      return 'Peso inválido';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskFactorsSection() {
    return _buildSection(
      title: 'Factores de riesgo',
      children: [
        const Text(
          'Selecciona los factores que apliquen a tu estilo de vida:',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _riskFactorOptions.map((factor) {
            final isSelected = _selectedRiskFactors.contains(factor);
            return FilterChip(
              label: Text(
                factor,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedRiskFactors.add(factor);
                  } else {
                    _selectedRiskFactors.remove(factor);
                  }
                });
              },
              selectedColor: _getRiskFactorColor(factor),
              backgroundColor: Colors.grey[200],
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSmartSettingsSection() {
    return _buildSection(
      title: 'Configuraciones inteligentes',
      children: [
        // Sugerencias automáticas
        SwitchListTile(
          title: const Text(
            'Sugerencias automáticas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E2E2E),
            ),
          ),
          subtitle: const Text(
            'Recibe recomendaciones personalizadas',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          value: _autoSuggestionsEnabled,
          onChanged: (value) {
            setState(() {
              _autoSuggestionsEnabled = value;
            });
          },
          activeColor: const Color(0xFF4CAF50),
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 16),

        // Recordatorios
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
              child: _buildTimeField(
                controller: _morningTimeController,
                label: 'Recordatorio matutino',
                icon: Icons.wb_sunny,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeField(
                controller: _eveningTimeController,
                label: 'Recordatorio nocturno',
                icon: Icons.nightlight_round,
                color: const Color(0xFF3F51B5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _selectTime(controller),
      borderRadius: BorderRadius.circular(12),
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            color: color.withOpacity(0.05),
          ),
          child: TextFormField(
            controller: controller,
            enabled: false,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: color),
              suffixIcon: Icon(Icons.access_time, color: color),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImagePath = image.path;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImagePath = image.path;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final formattedTime =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges()) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Descartar cambios?'),
          content: const Text(
            'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir sin guardar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF44336),
              ),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  bool _hasUnsavedChanges() {
    return _firstNameController.text.trim() != widget.profile.firstName ||
        _lastNameController.text.trim() != widget.profile.lastName ||
        _ageController.text != (widget.profile.age?.toString() ?? '') ||
        _institutionController.text.trim() != (widget.profile.institution ?? '') ||
        _heightController.text != (widget.profile.heightCm != null 
            ? (widget.profile.heightCm! / 100).toStringAsFixed(2)
            : '') ||
        _weightController.text != (widget.profile.weightKg?.toString() ?? '') ||
        !_listEquals(_selectedRiskFactors, widget.profile.riskFactors) ||
        _autoSuggestionsEnabled != widget.profile.autoSuggestionsEnabled ||
        _morningTimeController.text != (widget.profile.morningReminderTime ?? '8:00') ||
        _eveningTimeController.text != (widget.profile.eveningReminderTime ?? '21:30') ||
        _selectedImagePath != null;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _buildFloatingActionButton(bool isLoading) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: isLoading ? null : _saveProfile,
        backgroundColor: isLoading 
            ? const Color(0xFFE0E0E0) 
            : const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(
          isLoading ? 'Guardando...' : 'Guardar cambios',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showSuccessAndClose(String message) {
    if (_hasNavigated) return;
    
    setState(() {
      _hasNavigated = true;
      _isSaving = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
    
    print('EditProfileView - Cerrando pantalla');
    
    // Cerrar después de mostrar el mensaje
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, true); // Retornar true para indicar que se guardó
      }
    });
  }

  void _saveProfile() {
    // Evitar múltiples ejecuciones
    if (_isSaving) {
      print('EditProfileView - Guardado ya en progreso, ignorando');
      return;
    }
    
    if (_formKey.currentState?.validate() == true) {
      setState(() {
        _isSaving = true;
      });
      
      print('EditProfileView - Iniciando guardado de perfil');
      print('EditProfileView - Imagen seleccionada: ${_selectedImagePath != null}');
      
      // Crear perfil actualizado
      final updatedProfile = widget.profile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: _ageController.text.isNotEmpty
            ? int.tryParse(_ageController.text)
            : null,
        institution: _institutionController.text.trim().isNotEmpty
            ? _institutionController.text.trim()
            : null,
        heightCm: _heightController.text.isNotEmpty
            ? (double.tryParse(_heightController.text) ?? 0) * 100
            : null,
        weightKg: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        riskFactors: _selectedRiskFactors,
        autoSuggestionsEnabled: _autoSuggestionsEnabled,
        morningReminderTime: _morningTimeController.text,
        eveningReminderTime: _eveningTimeController.text,
        updatedAt: DateTime.now(),
      );

      // Actualizar perfil primero
      print('EditProfileView - Actualizando perfil');
      context.read<ProfileBloc>().add(UpdateUserProfile(updatedProfile));
      
      // Si hay imagen seleccionada, actualizar imagen después
      if (_selectedImagePath != null) {
        print('EditProfileView - Actualizando imagen después del perfil');
        // Esperar un poco para que se complete la actualización del perfil
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_hasNavigated) {
            context.read<ProfileBloc>().add(
              UpdateProfileImage(_selectedImagePath!),
            );
          }
        });
      }
    } else {
      print('EditProfileView - Formulario no válido');
      // Scroll al primer error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Color _getRiskFactorColor(String factor) {
    switch (factor) {
      case 'Come fuera frecuentemente':
        return const Color(0xFFFF9800);
      case 'Consume café en ayunas':
        return const Color(0xFF795548);
      case 'Fuma':
        return const Color(0xFFF44336);
      case 'Consume alcohol frecuentemente':
        return const Color(0xFF9C27B0);
      case 'Vida sedentaria':
        return const Color(0xFF607D8B);
      case 'Estrés crónico':
        return const Color(0xFFE91E63);
      case 'Poco descanso':
        return const Color(0xFF3F51B5);
      case 'Dieta alta en azúcar':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF666666);
    }
  }
}
