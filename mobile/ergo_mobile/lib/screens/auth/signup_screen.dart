import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';
import '../landlord/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final errorMessage = await _authService.signUp(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (errorMessage == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please log in.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to login page using GoRouter
      context.go('/login');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to create account. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Landlord Registration',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join a network of sophisticated property owners leveraging Ergo\'s automated asset management suite.',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 40),

                    Text(
                      'Full Name',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'e.g. John Doe',
                        hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerHigh,
                        prefixIcon: const Icon(Icons.person_outline, color: AppTheme.outlineVariant),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Email Address',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      validator: (value) => value!.isEmpty || !value.contains('@') ? 'Please enter a valid email' : null,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'e.g. name@example.com.ng',
                        hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerHigh,
                        prefixIcon: const Icon(Icons.mail_outline, color: AppTheme.outlineVariant),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Phone Number',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'e.g. 08012345678',
                        hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerHigh,
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.outlineVariant),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Password',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      validator: (value) => value!.length < 6 ? 'Password is too short' : null,
                      obscureText: true,
                      style: const TextStyle(color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerHigh,
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.outlineVariant),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign In',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
