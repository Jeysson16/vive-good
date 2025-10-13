import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_button.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

/// Página de registro mejorada con datos de salud y factores de riesgo
class EnhancedRegisterPage extends StatefulWidget {
  const EnhancedRegisterPage({super.key});

  @override
  State<EnhancedRegisterPage> createState() => _EnhancedRegisterPageState();
}

class _EnhancedRegisterPageState extends State<EnhancedRegisterPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Controladores para datos básicos
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _institutionController = TextEditingController();

  // Controladores para datos de salud
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Variables de estado
  bool _isPasswordVisible = false;
  List<String> _selectedRiskFactors = [];

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
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _institutionController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isStep1Valid() {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _ageController.text.isNotEmpty;
  }

  bool _isStep2Valid() {
    return _heightController.text.isNotEmpty &&
        _weightController.text.isNotEmpty;
  }

  void _submitRegistration() {
    // Crear mapa con todos los datos
    final registrationData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'institution': _institutionController.text.trim(),
      'height': double.tryParse(_heightController.text) ?? 0.0,
      'weight': double.tryParse(_weightController.text) ?? 0.0,
      'riskFactors': _selectedRiskFactors,
    };

    // Enviar evento de registro con datos completos
    context.read<AuthBloc>().add(
      AuthSignUpRequested(
        email: registrationData['email'] as String,
        password: registrationData['password'] as String,
        firstName: registrationData['firstName'] as String,
        lastName: registrationData['lastName'] as String,
        additionalData: registrationData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header con progreso
            _buildHeader(isSmallScreen),
            
            // Contenido de los pasos
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(isSmallScreen),
                  _buildStep2(isSmallScreen),
                  _buildStep3(isSmallScreen),
                ],
              ),
            ),
            
            // Botones de navegación
            _buildNavigationButtons(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        children: [
          // Botón de retroceso
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_currentStep > 0) {
                    _previousStep();
                  } else {
                    context.pop();
                  }
                },
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF090D3A),
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Indicador de progreso
          Row(
            children: List.generate(_totalSteps, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= _currentStep 
                        ? const Color(0xFF219540) 
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 20),
          
          // Título del paso
          Text(
            _getStepTitle(),
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF090D3A),
              fontFamily: 'Poppins',
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _getStepSubtitle(),
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: const Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Información Personal';
      case 1:
        return 'Datos de Salud';
      case 2:
        return 'Factores de Riesgo';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Ingresa tus datos básicos para crear tu cuenta';
      case 1:
        return 'Ayúdanos a personalizar tu experiencia';
      case 2:
        return 'Identifica factores que pueden afectar tu salud';
      default:
        return '';
    }
  }

  Widget _buildStep1(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _firstNameController,
            hintText: 'Nombres',
            prefixIcon: Icons.person_outline,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          CustomTextField(
            controller: _lastNameController,
            hintText: 'Apellidos',
            prefixIcon: Icons.person_outline,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          CustomTextField(
            controller: _emailController,
            hintText: 'Correo electrónico',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          CustomTextField(
            controller: _passwordController,
            hintText: 'Contraseña',
            prefixIcon: Icons.lock_outline,
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          CustomTextField(
            controller: _ageController,
            hintText: 'Edad',
            prefixIcon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          CustomTextField(
            controller: _institutionController,
            hintText: 'Institución (opcional)',
            prefixIcon: Icons.school_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          CustomTextField(
            controller: _heightController,
            hintText: 'Altura (cm)',
            prefixIcon: Icons.straighten,
            keyboardType: TextInputType.number,
            suffixText: 'cm',
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          CustomTextField(
            controller: _weightController,
            hintText: 'Peso (kg)',
            prefixIcon: Icons.monitor_weight,
            keyboardType: TextInputType.number,
            suffixText: 'kg',
          ),
          
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0F2FE)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estos datos nos ayudan a personalizar tus recomendaciones de salud y hábitos.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: const Color(0xFF0284C7),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'Selecciona los factores que aplican a tu estilo de vida:',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: const Color(0xFF374151),
              fontFamily: 'Poppins',
            ),
          ),
          
          const SizedBox(height: 20),
          
          ...List.generate(_riskFactorOptions.length, (index) {
            final factor = _riskFactorOptions[index];
            final isSelected = _selectedRiskFactors.contains(factor);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedRiskFactors.remove(factor);
                    } else {
                      _selectedRiskFactors.add(factor);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFFF0FDF4) 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF219540) 
                          : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected 
                            ? Icons.check_circle 
                            : Icons.radio_button_unchecked,
                        color: isSelected 
                            ? const Color(0xFF219540) 
                            : const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          factor,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: const Color(0xFF374151),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Puedes modificar estos factores más tarde en tu perfil.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: const Color(0xFFD97706),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        children: [
          // Botón principal
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                context.go('/main');
              } else if (state is AuthSignUpSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
                context.go('/login');
              } else if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            child: CustomButton(
              text: _currentStep == _totalSteps - 1 ? 'Crear Cuenta' : 'Continuar',
              onPressed: _getButtonEnabled() ? () {
                if (_currentStep == _totalSteps - 1) {
                  _submitRegistration();
                } else {
                  _nextStep();
                }
              } : null,
              isEnabled: _getButtonEnabled(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Link para iniciar sesión
          Center(
            child: RichText(
              text: TextSpan(
                text: '¿Ya tienes una cuenta? ',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: isSmallScreen ? 13 : 14,
                  fontFamily: 'Poppins',
                ),
                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Inicia Sesión',
                        style: TextStyle(
                          color: const Color(0xFF090D3A),
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          decoration: TextDecoration.underline,
                        ),
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

  bool _getButtonEnabled() {
    switch (_currentStep) {
      case 0:
        return _isStep1Valid();
      case 1:
        return _isStep2Valid();
      case 2:
        return true; // Los factores de riesgo son opcionales
      default:
        return false;
    }
  }
}