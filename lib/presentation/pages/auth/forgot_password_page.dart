import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_button.dart';
import '../../../core/routes/app_routes.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _emailController.text.isNotEmpty &&
          _emailController.text.contains('@');
    });
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthResetPasswordRequested(
          email: _emailController.text.trim(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isLargeScreen = screenSize.width > 600;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF1A1D29),
            size: isSmallScreen ? 18 : 20,
          ),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se ha enviado un enlace de recuperación a tu email'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back to login
            context.go(AppRoutes.login);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: isLargeScreen ? 48.0 : (isSmallScreen ? 16.0 : 24.0),
              right: isLargeScreen ? 48.0 : (isSmallScreen ? 16.0 : 24.0),
              bottom: keyboardHeight > 0 ? 16.0 : 0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenSize.height - 
                    MediaQuery.of(context).padding.top - 
                    kToolbarHeight - 
                    keyboardHeight,
                maxWidth: isLargeScreen ? 400 : double.infinity,
              ),
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmallScreen ? 16 : 32),
                      // Title
                      Text(
                        'Recuperar\nContraseña',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28 : (isLargeScreen ? 36 : 32),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D29),
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      // Description
                      Text(
                        'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 48),
                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Correo electrónico',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isEmpty: _emailController.text.isEmpty,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu email';
                          }
                          if (!value.contains('@')) {
                            return 'Por favor ingresa un email válido';
                          }
                          return null;
                        },
                      ),
                      const Spacer(),
                      // Reset Password Button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return CustomButton(
                            text: 'Enviar Enlace',
                            onPressed: _isFormValid ? _resetPassword : null,
                            isLoading: state is AuthLoading,
                            isEnabled: _isFormValid,
                          );
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      // Back to Login Link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '¿Recordaste tu contraseña? ',
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(44, 44),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 12,
                                vertical: isSmallScreen ? 4 : 8,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Inicia Sesión',
                              style: TextStyle(
                                color: const Color(0xFF3B82F6),
                                fontSize: isSmallScreen ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}