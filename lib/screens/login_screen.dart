import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/services/auth_service.dart';
import '../core/services/audit_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSetupMode = false; // true = first time admin setup
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _checkFirstTimeSetup();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _checkFirstTimeSetup() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final hasUsers = await auth.hasAnyUsers();
    if (mounted) {
      setState(() {
        _isSetupMode = !hasUsers;
      });
    }
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final error = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (error != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      } else {
        // Log the login action
        final audit = Provider.of<AuditService>(context, listen: false);
        await audit.log(
          action: 'login',
          details: '${auth.currentUserName} logged in as ${auth.currentUserRole}',
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleAdminSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.createAdminAccount(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      pin: _pinController.text.trim().isNotEmpty ? _pinController.text.trim() : null,
    );

    if (mounted) {
      if (!success) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to create admin account. Try again.';
        });
      } else {
        final audit = Provider.of<AuditService>(context, listen: false);
        await audit.log(
          action: 'login',
          details: 'Admin account created and logged in',
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Brand
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "LEDGERFLOW",
                    style: AppTheme.headlineXl.copyWith(
                      color: Colors.white,
                      letterSpacing: 3.0,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _isSetupMode
                        ? "Create your admin account to get started"
                        : "Sign in to continue",
                    style: AppTheme.bodyMd.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isSetupMode) ...[
                            Text(
                              "ADMIN SETUP",
                              style: AppTheme.labelBold.copyWith(
                                color: AppTheme.primary,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name field
                            _buildTextField(
                              controller: _nameController,
                              label: "Full Name",
                              icon: Icons.person_outline,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Name is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          _buildTextField(
                            controller: _emailController,
                            label: "Email",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white38,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 4) return 'At least 4 characters';
                              return null;
                            },
                          ),

                          if (_isSetupMode) ...[
                            const SizedBox(height: 16),
                            // PIN field (optional)
                            _buildTextField(
                              controller: _pinController,
                              label: "Quick-Switch PIN (optional, 4 digits)",
                              icon: Icons.pin_outlined,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              validator: (v) {
                                if (v != null && v.isNotEmpty && v.length != 4) {
                                  return 'PIN must be exactly 4 digits';
                                }
                                return null;
                              },
                            ),
                          ],

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTheme.labelSm.copyWith(color: AppTheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Login / Setup button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (_isSetupMode ? _handleAdminSetup : _handleLogin),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSetupMode ? "CREATE ADMIN ACCOUNT" : "SIGN IN",
                                      style: AppTheme.labelBold.copyWith(
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Toggle between setup and login
                  if (_isSetupMode)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSetupMode = false;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        "Already have an account? Sign in",
                        style: AppTheme.labelSm.copyWith(color: Colors.white38),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () {
                        _checkFirstTimeSetup();
                      },
                      child: Text(
                        "First time? Set up admin account",
                        style: AppTheme.labelSm.copyWith(color: Colors.white38),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      style: AppTheme.bodyMd.copyWith(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.labelSm.copyWith(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
