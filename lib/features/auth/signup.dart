import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gymnex_find/features/auth/register.dart';
import 'package:gymnex_find/features/auth/login.dart';
import 'package:gymnex_find/utility/app_colors.dart';
import 'package:gymnex_find/utility/app_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firebaseAuth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      _showSnackBar(
        'Please accept the terms and conditions to continue.',
        AppColors.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email and password
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential.user != null) {
        // Update display name immediately
        await credential.user!.updateDisplayName(
          _fullNameController.text.trim(),
        );

        // Send email verification
        await credential.user!.sendEmailVerification();

        if (mounted) {
          _showSnackBar(
            'Account created successfully! Please check your email for verification.',
            AppColors.success,
          );

          // Navigate to registration page with user info
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RegistrationPage(
                    email: credential.user!.email,
                    uid: credential.user!.uid,
                  ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showSnackBar(
        'An unexpected error occurred. Please try again.',
        AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        // Check if this is a new user
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          if (mounted) {
            _showSnackBar(
              'Google account created successfully!',
              AppColors.success,
            );

            // Navigate to registration page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => RegistrationPage(
                      email: userCredential.user!.email,
                      uid: userCredential.user!.uid,
                    ),
              ),
            );
          }
        } else {
          // Existing user, go to login page
          if (mounted) {
            _showSnackBar(
              'Account already exists. Please sign in instead.',
              AppColors.warning,
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showSnackBar(
        'Google sign-up failed. Please try again.',
        AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'invalid-email':
        message = 'Invalid email address format.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Please try again later.';
        break;
      default:
        message = 'Sign up failed: ${e.message}';
    }
    _showSnackBar(message, AppColors.error);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleBackToLogin() {
    Navigator.pop(context);
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Terms & Conditions', style: AppTypography.titleLarge),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'By creating an account with Gymnex Go, you agree to:',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTermItem(
                    'Use the app for personal fitness purposes only',
                  ),
                  _buildTermItem('Provide accurate and truthful information'),
                  _buildTermItem(
                    'Respect gym facilities, staff, and other users',
                  ),
                  _buildTermItem(
                    'Keep your account credentials secure and confidential',
                  ),
                  _buildTermItem(
                    'Follow all community guidelines and local laws',
                  ),
                  _buildTermItem(
                    'Not share or misuse other users\' personal information',
                  ),
                  _buildTermItem(
                    'Report any suspicious or inappropriate behavior',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Privacy Policy Summary:',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTermItem(
                    'We collect data to provide and improve our services',
                  ),
                  _buildTermItem(
                    'Your personal information is securely stored and protected',
                  ),
                  _buildTermItem('We do not sell your data to third parties'),
                  _buildTermItem('You can request data deletion at any time'),
                  const SizedBox(height: 12),
                  Text(
                    'Full terms and conditions and privacy policy are available in the app settings after registration.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Full name must be less than 50 characters';
    }
    // Check for valid name format (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-\'\.]+$").hasMatch(value.trim())) {
      return 'Please enter a valid name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase and number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: _isLoading ? null : _handleBackToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo and App Name
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.fitness_center,
                            size: 50,
                            color: AppColors.white,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Join Gymnex Go',
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to start your fitness journey',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // SignUp Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name Field
                    TextFormField(
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      validator: _validateFullName,
                      enabled: !_isLoading,
                      style: AppTypography.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: AppColors.textSecondary,
                        ),
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderPrimary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      enabled: !_isLoading,
                      style: AppTypography.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email address',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.textSecondary,
                        ),
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderPrimary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      validator: _validatePassword,
                      enabled: !_isLoading,
                      style: AppTypography.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Create a strong password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed:
                              _isLoading ? null : _togglePasswordVisibility,
                        ),
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderPrimary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      validator: _validateConfirmPassword,
                      enabled: !_isLoading,
                      style: AppTypography.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed:
                              _isLoading
                                  ? null
                                  : _toggleConfirmPasswordVisibility,
                        ),
                        labelStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderPrimary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password Requirements
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderPrimary,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password Requirements:',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPasswordRequirement(
                            'At least 8 characters',
                            _hasMinLength,
                          ),
                          _buildPasswordRequirement(
                            'One uppercase letter',
                            _hasUppercase,
                          ),
                          _buildPasswordRequirement(
                            'One lowercase letter',
                            _hasLowercase,
                          ),
                          _buildPasswordRequirement('One number', _hasNumber),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Terms and Conditions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged:
                              _isLoading
                                  ? null
                                  : (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                _isLoading
                                    ? null
                                    : () {
                                      setState(() {
                                        _acceptTerms = !_acceptTerms;
                                      });
                                    },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: TextSpan(
                                  style: AppTypography.bodyMedium.copyWith(
                                    color:
                                        _isLoading
                                            ? AppColors.textDisabled
                                            : AppColors.textSecondary,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap:
                                            _isLoading
                                                ? null
                                                : _showTermsAndConditions,
                                        child: Text(
                                          'Terms & Conditions',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                color:
                                                    _isLoading
                                                        ? AppColors.textDisabled
                                                        : AppColors.primary,
                                                fontWeight:
                                                    AppTypography.medium,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor:
                                                    _isLoading
                                                        ? AppColors.textDisabled
                                                        : AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap:
                                            _isLoading
                                                ? null
                                                : _showTermsAndConditions,
                                        child: Text(
                                          'Privacy Policy',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                color:
                                                    _isLoading
                                                        ? AppColors.textDisabled
                                                        : AppColors.primary,
                                                fontWeight:
                                                    AppTypography.medium,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor:
                                                    _isLoading
                                                        ? AppColors.textDisabled
                                                        : AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.textDisabled,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.3),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  'Create Account',
                                  style: AppTypography.buttonLarge,
                                ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.borderPrimary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.borderPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignUp,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          disabledForegroundColor: AppColors.textDisabled,
                          side: BorderSide(
                            color:
                                _isLoading
                                    ? AppColors.textDisabled
                                    : AppColors.borderPrimary,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.g_mobiledata,
                            color: AppColors.black,
                            size: 20,
                          ),
                        ),
                        label: Text(
                          'Continue with Google',
                          style: AppTypography.buttonMedium.copyWith(
                            color:
                                _isLoading
                                    ? AppColors.textDisabled
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _handleBackToLogin,
                    child: Text(
                      'Sign In',
                      style: AppTypography.bodyMedium.copyWith(
                        color:
                            _isLoading
                                ? AppColors.textDisabled
                                : AppColors.primary,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.check_circle_outline,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: AppTypography.bodySmall.copyWith(
              color: isMet ? AppColors.success : AppColors.textTertiary,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
