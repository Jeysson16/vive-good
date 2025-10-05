import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_button.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isLargeScreen = screenSize.width > 600;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: isLargeScreen ? 48.0 : (isSmallScreen ? 16.0 : 24.0),
            right: isLargeScreen ? 48.0 : (isSmallScreen ? 16.0 : 24.0),
            bottom: keyboardHeight > 0 ? 16.0 : 0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenSize.height -
                  MediaQuery.of(context).padding.top -
                  (keyboardHeight > 0 ? 16.0 : 0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Back button
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/welcome');
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF090D3A),
                    size: 24,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 40),
                // Title
                Text(
                  'Crea tu\nCuenta',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : (isLargeScreen ? 36 : 32),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF090D3A),
                    fontFamily: 'Poppins',
                    height: 1.2,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 40 : 60),
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // First Name field
                      CustomTextField(
                        controller: _firstNameController,
                        hintText: 'Nombres',
                        prefixIcon: Icons.person_outline,
                        isEmpty: _firstNameController.text.isEmpty,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      // Last Name field
                      CustomTextField(
                        controller: _lastNameController,
                        hintText: 'Apellidos',
                        prefixIcon: Icons.person_outline,
                        isEmpty: _lastNameController.text.isEmpty,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      // Email field
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Correo electrónico',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isEmpty: _emailController.text.isEmpty,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      // Password field
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
                        isEmpty: _passwordController.text.isEmpty,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 30),
                // Register button
                BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthAuthenticated) {
                      context.go('/home');
                    } else if (state is AuthSignUpSuccess) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.message)));
                      context.go('/login');
                    } else if (state is AuthError) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.message)));
                    }
                  },
                  child: CustomButton(
                    text: 'Registrar',
                    onPressed: _isFormValid
                        ? () {
                            if (_formKey.currentState?.validate() == true) {
                              context.read<AuthBloc>().add(
                                AuthSignUpRequested(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  firstName: _firstNameController.text.trim(),
                                  lastName: _lastNameController.text.trim(),
                                ),
                              );
                            }
                          }
                        : null,
                    isEnabled: _isFormValid,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                // Login link
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
                SizedBox(height: isSmallScreen ? 30 : 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
