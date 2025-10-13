import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_button.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isSmallScreen ? 20 : 40,
              ),
              child: Form(
                key: _formKey,
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
                'Inicia\nSesión',
                style: TextStyle(
                  fontSize: isSmallScreen ? 28 : 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF090D3A),
                  fontFamily: 'Poppins',
                  height: 1.2,
                ),
              ),
              SizedBox(height: isSmallScreen ? 40 : 60),
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
              const SizedBox(height: 20),
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Implement forgot password
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),
              // Login button
              BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    context.go('/main');
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return CustomButton(
                      text: 'Iniciar Sesión',
                      onPressed: _isFormValid && !isLoading
                          ? () {
                              if (_formKey.currentState?.validate() == true) {
                                context.read<AuthBloc>().add(
                                      AuthSignInRequested(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      ),
                                    );
                              }
                            }
                          : null,
                      isEnabled: _isFormValid && !isLoading,
                      isLoading: isLoading,
                    );
                  },
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              // Register link
              Center(
                child: RichText(
                  text: TextSpan(
                    text: '¿Todavía no tienes una cuenta? ',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: isSmallScreen ? 13 : 14,
                      fontFamily: 'Poppins',
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text(
                            'Regístrate',
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
            // Loading overlay
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF090D3A)),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}