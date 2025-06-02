import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymnex_find/features/auth/login.dart';
import 'package:gymnex_find/features/auth/register.dart';
import 'package:gymnex_find/features/homePage.dart';
import 'package:gymnex_find/utility/app_colors.dart';
import 'package:gymnex_find/utility/app_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _progressAnimation;

  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _statusMessage = 'Welcome to Gymnex';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSplashSequence() async {
    try {
      // Start logo animation
      _logoController.forward();

      // Wait a bit then start text animation
      await Future.delayed(const Duration(milliseconds: 500));
      _textController.forward();

      // Start progress animation
      await Future.delayed(const Duration(milliseconds: 300));
      _progressController.forward();

      // Check authentication status
      await _checkAuthenticationStatus();
    } catch (e) {
      _handleError('Initialization failed: ${e.toString()}');
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      _updateStatus('Checking authentication...');
      await Future.delayed(const Duration(milliseconds: 800));

      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        _updateStatus('Welcome! Please sign in');
        await Future.delayed(const Duration(milliseconds: 1000));
        _navigateToLogin();
        return;
      }

      _updateStatus(
        'Welcome back, ${currentUser.displayName?.split(' ').first ?? 'User'}!',
      );

      // Check if user profile is complete
      await _checkUserProfile(currentUser);
    } catch (e) {
      _handleError('Authentication check failed: ${e.toString()}');
    }
  }

  Future<void> _checkUserProfile(User user) async {
    try {
      _updateStatus('Loading your profile...');
      await Future.delayed(const Duration(milliseconds: 800));

      // Check if user document exists in customers collection
      final userDoc =
          await _firestore.collection('customers').doc(user.uid).get();

      if (!userDoc.exists) {
        _updateStatus('Setting up your profile...');
        await Future.delayed(const Duration(milliseconds: 1000));
        _navigateToRegistration(user.email);
        return;
      }

      final userData = userDoc.data()!;
      final isProfileComplete = userData['profileCompleted'] ?? false;

      if (!isProfileComplete) {
        _updateStatus('Completing your profile...');
        await Future.delayed(const Duration(milliseconds: 1000));
        _navigateToRegistration(user.email);
        return;
      }

      // Profile is complete, go to home
      _updateStatus('Getting everything ready...');
      await Future.delayed(const Duration(milliseconds: 1000));
      _navigateToHome();
    } catch (e) {
      print('Profile check error: $e');
      // If there's an error checking profile, assume it needs completion
      _updateStatus('Setting up your profile...');
      await Future.delayed(const Duration(milliseconds: 1000));
      _navigateToRegistration(user.email);
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _handleError(String error) {
    print('Splash Screen Error: $error');
    if (mounted) {
      setState(() {
        _statusMessage = 'Something went wrong. Please try again.';
        _hasError = true;
      });

      // Wait a bit then navigate to login
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _navigateToLogin();
        }
      });
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _navigateToRegistration(String? email) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  RegistrationPage(email: email),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style for full screen experience
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Opacity(
                            opacity: _logoOpacityAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset("assets/logo.png"),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // App Name and Tagline
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _textSlideAnimation,
                          child: Opacity(
                            opacity: _textOpacityAnimation.value,
                            child: Column(
                              children: [
                                Text(
                                  'GYMNEX',
                                  style: AppTypography.headlineLarge.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Find Your Perfect Gym',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // Progress Section
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _progressAnimation.value,
                          child: Column(
                            children: [
                              // Status Message
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: AppColors.borderPrimary,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!_hasError) ...[
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.primary,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ] else ...[
                                      Icon(
                                        Icons.error_outline,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Text(
                                      _statusMessage,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color:
                                            _hasError
                                                ? AppColors.error
                                                : AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Progress Bar
                              Container(
                                width: 200,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.borderPrimary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: AnimatedBuilder(
                                  animation: _progressAnimation,
                                  builder: (context, child) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: 200 * _progressAnimation.value,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primary.withOpacity(
                                                0.7,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Version Info (Optional)
              Text(
                'Version 1.0.0',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
