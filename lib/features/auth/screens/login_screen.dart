import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/auth_service.dart';

/// Authentication screen for the ClaimCare application.
/// Fully responsive design for mobile, tablet, and desktop.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignUpMode = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUpMode) {
        await authService.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
        );
      } else {
        await authService.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (mounted) {
        context.go('/dashboard');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();

      if (result != null && mounted) {
        context.go('/dashboard');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: isDesktop
              ? _buildDesktopLayout()
              : isMobile
                  ? _buildMobileLayout()
                  : _buildTabletLayout(),
        ),
      ),
    );
  }

  /// Desktop: Two-column layout with branding on left
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel - branding
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: -100,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'ClaimCare',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Streamline your insurance claims\nwith our modern management solution.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildFeatureItem(Icons.speed_rounded, 'Fast Processing'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.security_rounded, 'Secure & Compliant'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.insights_rounded, 'Real-time Tracking'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right panel - auth form
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildAuthForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Tablet: Centered form with header
  Widget _buildTabletLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCompactHeader(),
            const SizedBox(height: 48),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _buildAuthForm(),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile: Scrollable single-column layout
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMobileHeader(),
            const SizedBox(height: 40),
            _buildAuthForm(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ClaimCare',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Claims Management',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'ClaimCare',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Insurance Claims Management',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm({bool compact = false}) {
    final isMobile = compact;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            _isSignUpMode ? 'Create Account' : 'Welcome Back',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSignUpMode
                ? 'Sign up to start managing claims'
                : 'Sign in to continue',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 32),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Name field (sign up only)
          if (_isSignUpMode) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your name',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 18),
          ],

          // Email field
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 18),

          // Password field
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: _isSignUpMode ? 'Create a password' : 'Enter password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction:
                _isSignUpMode ? TextInputAction.next : TextInputAction.done,
            validator: Validators.validatePassword,
            onFieldSubmitted: _isSignUpMode ? null : (_) => _handleSubmit(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          // Confirm password field (sign up only)
          if (_isSignUpMode) ...[
            const SizedBox(height: 18),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleSubmit(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
          ],

          // Forgot password (login only)
          if (!_isSignUpMode) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Submit button
          FilledButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isSignUpMode ? 'Create Account' : 'Sign In',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
            ],
          ),

          const SizedBox(height: 24),

          // Google Sign-In
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.g_mobiledata, size: 20),
            ),
            label: Text(_isSignUpMode ? 'Sign up with Google' : 'Sign in with Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 28),

          // Toggle mode
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUpMode
                    ? 'Already have an account?'
                    : "Don't have an account?",
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: _toggleMode,
                child: Text(
                  _isSignUpMode ? 'Sign In' : 'Sign Up',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          // Demo credentials (login only)
          if (!_isSignUpMode) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Demo Account',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildCredentialRow('Email', 'demo@claimcare.com'),
                  const SizedBox(height: 4),
                  _buildCredentialRow('Password', 'Demo@123'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your email and we\'ll send you a reset link.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ref.read(authServiceProvider).sendPasswordResetEmail(
                        emailController.text,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Reset link sent to your email'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                } on AuthException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }
}
