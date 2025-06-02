import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymnex_find/features/homePage.dart';
import 'package:gymnex_find/features/auth/login.dart';
import 'package:gymnex_find/utility/app_colors.dart';
import 'package:gymnex_find/utility/app_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

class RegistrationPage extends StatefulWidget {
  final String? email; // Optional: pre-filled email from signup
  final String? uid; // Optional: user UID if already created

  const RegistrationPage({super.key, this.email, this.uid});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final PageController _pageController = PageController();
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int _currentStep = 0;

  // BMI calculation variables
  double _bmi = 0.0;
  String _bmiCategory = '';

  // Selected country for address
  Country? _selectedCountry;

  // Form data storage
  Map<String, dynamic> _formData = {};

  bool _isLoading = false;
  bool _isCalculatingBMI = false;

  // Fitness options
  final List<String> _fitnessLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Professional',
  ];

  final List<String> _fitnessGoals = [
    'Weight Loss',
    'Weight Gain',
    'Muscle Building',
    'Cardio Fitness',
    'Strength Training',
    'Flexibility',
    'Sports Training',
    'General Health',
  ];

  final List<String> _healthConditions = [
    'None',
    'Diabetes',
    'High Blood Pressure',
    'Heart Condition',
    'Asthma',
    'Joint Problems',
    'Back Problems',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill email if provided
    if (widget.email != null) {
      _formData['email'] = widget.email;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _calculateBMI({bool instant = false}) {
    if (!instant) {
      setState(() {
        _isCalculatingBMI = true;
      });
    }

    // Use immediate calculation or delayed for better UX
    final delay = instant ? Duration.zero : const Duration(milliseconds: 500);

    Future.delayed(delay, () {
      final formState = _formKey.currentState;
      if (formState != null) {
        formState.save();
        final values = formState.value;

        final height = values['height'];
        final weight = values['weight'];

        if (height != null && weight != null && height > 0 && weight > 0) {
          // Convert height from cm to meters
          double heightInMeters = height / 100;
          _bmi = weight / (heightInMeters * heightInMeters);

          // Determine BMI category
          if (_bmi < 18.5) {
            _bmiCategory = 'Underweight';
          } else if (_bmi < 25) {
            _bmiCategory = 'Normal weight';
          } else if (_bmi < 30) {
            _bmiCategory = 'Overweight';
          } else {
            _bmiCategory = 'Obese';
          }
        }
      }

      if (mounted) {
        setState(() {
          _isCalculatingBMI = false;
        });
      }
    });
  }

  Color _getBMIColor() {
    if (_bmi < 18.5) return AppColors.info;
    if (_bmi < 25) return AppColors.success;
    if (_bmi < 30) return AppColors.warning;
    return AppColors.error;
  }

  String _getBMIAdvice() {
    if (_bmi < 18.5) {
      return 'Consider consulting with a nutritionist to develop a healthy weight gain plan.';
    } else if (_bmi < 25) {
      return 'Great! You have a healthy weight. Maintain your current lifestyle.';
    } else if (_bmi < 30) {
      return 'Consider a balanced diet and regular exercise to achieve a healthier weight.';
    } else {
      return 'We recommend consulting with a healthcare professional for a personalized plan.';
    }
  }

  Widget _buildBMIReference(String category, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            category,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            range,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      // Validate current step before proceeding
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    final currentState = _formKey.currentState;
    if (currentState == null) return false;

    switch (_currentStep) {
      case 0:
        return _validatePersonalInfo();
      case 1:
        return _validatePhysicalInfo();
      case 2:
        return _validateAddressInfo();
      case 3:
        return _validateFitnessInfo();
      default:
        return false;
    }
  }

  bool _validatePersonalInfo() {
    final isValid = _formKey.currentState!.saveAndValidate(
      focusOnInvalid: true,
      autoScrollWhenFocusOnInvalid: true,
    );

    // Additional check for phone number
    if (isValid) {
      final formData = _formKey.currentState!.value;
      if (formData['phone'] == null || formData['phone'].isEmpty) {
        _showSnackBar('Please enter a valid phone number', AppColors.error);
        return false;
      }
    }

    return isValid;
  }

  bool _validatePhysicalInfo() {
    if (!_formKey.currentState!.saveAndValidate()) return false;

    final values = _formKey.currentState!.value;
    if (values['height'] == null || values['weight'] == null) {
      _showSnackBar(
        'Please enter both height and weight to calculate BMI',
        AppColors.warning,
      );
      return false;
    }

    // BMI should already be calculated from real-time input
    // But trigger once more to ensure it's calculated
    if (_bmi == 0.0) {
      _calculateBMI(instant: true);
    }

    return true;
  }

  bool _validateAddressInfo() {
    if (!_formKey.currentState!.saveAndValidate()) return false;

    if (_selectedCountry == null) {
      _showSnackBar('Please select your country', AppColors.warning);
      return false;
    }
    return true;
  }

  bool _validateFitnessInfo() {
    final values = _formKey.currentState!.value;

    if (values['fitness_level'] == null || values['fitness_level'].isEmpty) {
      _showValidationError('Please select your fitness level');
      return false;
    }

    if (values['fitness_goals'] == null || values['fitness_goals'].isEmpty) {
      _showValidationError('Please select at least one fitness goal');
      return false;
    }

    if (values['health_conditions'] == null ||
        values['health_conditions'].isEmpty) {
      _showValidationError('Please select your health conditions');
      return false;
    }

    return _formKey.currentState!.saveAndValidate();
  }

  void _showValidationError(String message) {
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get all form data
      final formData = _formKey.currentState!.value;

      // Get current user
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Debug: Print user info
      print('Current User UID: ${currentUser.uid}');
      print('Current User Email: ${currentUser.email}');
      print('User Email Verified: ${currentUser.emailVerified}');

      // Validate required fields
      if (formData['first_name'] == null || formData['first_name'].isEmpty) {
        throw Exception('First name is required');
      }
      if (formData['last_name'] == null || formData['last_name'].isEmpty) {
        throw Exception('Last name is required');
      }
      if (formData['phone'] == null || formData['phone'].isEmpty) {
        throw Exception('Phone number is required');
      }
      if (formData['fitness_level'] == null ||
          formData['fitness_level'].isEmpty) {
        throw Exception('Fitness level is required');
      }
      if (formData['fitness_goals'] == null ||
          (formData['fitness_goals'] as List).isEmpty) {
        throw Exception('At least one fitness goal must be selected');
      }
      if (formData['health_conditions'] == null ||
          (formData['health_conditions'] as List).isEmpty) {
        throw Exception(
          'Health conditions must be specified (select "None" if applicable)',
        );
      }

      // Prepare user profile data
      final userProfileData = <String, dynamic>{
        'uid': currentUser.uid,
        'email': currentUser.email ?? '',
        'firstName': formData['first_name']?.toString() ?? '',
        'lastName': formData['last_name']?.toString() ?? '',
        'phone': {
          'complete': formData['phone']?.toString() ?? '',
          'countryCode': _formData['phone_country_code']?.toString() ?? '',
          'number': _formData['phone_number']?.toString() ?? '',
          'isoCode': _formData['phone_iso_code']?.toString() ?? '',
        },
        'dateOfBirth': formData['date_of_birth']?.toIso8601String(),
        'gender': formData['gender']?.toString() ?? '',
        'height': formData['height'] ?? 0,
        'weight': formData['weight'] ?? 0.0,
        'bmi': _bmi,
        'bmiCategory': _bmiCategory,
        'address': {
          'line1': formData['address_line1']?.toString() ?? '',
          'line2': formData['address_line2']?.toString() ?? '',
          'city': formData['city']?.toString() ?? '',
          'state': formData['state']?.toString() ?? '',
          'zipCode': formData['zip_code']?.toString() ?? '',
          'country': _selectedCountry?.name ?? '',
          'countryCode': _selectedCountry?.countryCode ?? '',
        },
        'fitnessProfile': {
          'level': formData['fitness_level']?.toString() ?? '',
          'goals': List<String>.from(formData['fitness_goals'] ?? []),
          'healthConditions': List<String>.from(
            formData['health_conditions'] ?? [],
          ),
          'additionalNotes': formData['additional_notes']?.toString() ?? '',
        },
        'emergencyContact': {
          'name': formData['emergency_contact_name']?.toString() ?? '',
          'phone': formData['emergency_contact_phone']?.toString() ?? '',
        },
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Debug: Print data being saved
      print('Attempting to save data to customers/${currentUser.uid}');
      print('Data keys: ${userProfileData.keys.toList()}');
      print('Phone data: ${userProfileData['phone']}');
      print('Fitness goals: ${userProfileData['fitnessProfile']['goals']}');
      print(
        'Health conditions: ${userProfileData['fitnessProfile']['healthConditions']}',
      );
      print(
        'Additional notes: ${userProfileData['fitnessProfile']['additionalNotes']}',
      );

      // Try to initialize Firestore connection with settings
      try {
        print('Initializing Firestore with persistence settings...');

        // Enable offline persistence (this can help with connection issues)
        await _firestore.enablePersistence();
        print('Firestore persistence enabled');
      } catch (e) {
        print('Firestore persistence already enabled or not supported: $e');
        // This is not a critical error, continue
      }

      // Save to Firestore with extended timeout
      print('Saving user profile data...');

      await _firestore
          .collection('customers')
          .doc(currentUser.uid)
          .set(userProfileData, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Save operation timed out. Please check your connection and try again.',
              );
            },
          );

      print('Data saved successfully to Firestore');

      // Update display name
      try {
        final fullName = '${formData['first_name']} ${formData['last_name']}';
        await currentUser.updateDisplayName(fullName);
        print('Display name updated successfully');
      } catch (e) {
        print('Failed to update display name: $e');
        // Don't throw here, profile save was successful
      }

      // Send email verification if not verified
      try {
        if (!currentUser.emailVerified) {
          await currentUser.sendEmailVerification();
          print('Email verification sent');
        }
      } catch (e) {
        print('Failed to send email verification: $e');
        // Don't throw here, profile save was successful
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseException catch (e) {
      print('FirebaseException: ${e.code} - ${e.message}');
      _handleFirebaseError(e);
    } catch (e) {
      print('General Exception: $e');

      // Show more helpful error messages
      String errorMessage = e.toString();
      if (errorMessage.contains('channel')) {
        errorMessage =
            'Connection to Firebase failed. This usually means:\n\n'
            '1. Check your internet connection\n'
            '2. Restart the app and try again\n'
            '3. If using emulator, try on a real device\n'
            '4. Contact support if the issue persists';
      }

      _showSnackBar(errorMessage, AppColors.error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleFirebaseError(FirebaseException e) {
    String message;
    print('Firebase Error Code: ${e.code}');
    print('Firebase Error Message: ${e.message}');

    switch (e.code) {
      case 'permission-denied':
        message =
            'Permission denied. Please ensure you are logged in and try again.';
        break;
      case 'unavailable':
        message = 'Service temporarily unavailable. Please try again later.';
        break;
      case 'network-request-failed':
        message =
            'Network error. Please check your internet connection and try again.';
        break;
      case 'deadline-exceeded':
        message =
            'Request timed out. Please check your connection and try again.';
        break;
      case 'resource-exhausted':
        message = 'Too many requests. Please wait a moment and try again.';
        break;
      case 'unauthenticated':
        message = 'Authentication required. Please log in again.';
        break;
      case 'invalid-argument':
        message =
            'Invalid data provided. Please check your information and try again.';
        break;
      case 'not-found':
        message = 'Database collection not found. Please contact support.';
        break;
      case 'already-exists':
        message = 'Profile already exists. Updating existing profile.';
        break;
      case 'failed-precondition':
        message =
            'Database rules prevented the operation. Please contact support.';
        break;
      case 'out-of-range':
        message =
            'Some data values are out of acceptable range. Please check your input.';
        break;
      case 'data-loss':
        message = 'Data corruption detected. Please try again.';
        break;
      case 'internal':
        message = 'Internal server error. Please try again later.';
        break;
      case 'cancelled':
        message = 'Operation was cancelled. Please try again.';
        break;
      default:
        message =
            'Failed to save profile. Error: ${e.code} - ${e.message ?? "Unknown error"}';
    }

    _showSnackBar(message, AppColors.error);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Registration Complete!',
                  style: AppTypography.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome to Gymnex Go! Your profile has been created successfully.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (_firebaseAuth.currentUser?.emailVerified == false)
                  Text(
                    'Please check your email for verification link.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: AppTypography.buttonMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Complete Registration', style: AppTypography.titleMedium),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              // Sign out and go to login
              await _firebaseAuth.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
            child: Text(
              'Sign Out',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          index <= _currentStep
                              ? AppColors.primary
                              : AppColors.borderPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Step Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _getStepTitle(),
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Form Content
          Expanded(
            child: FormBuilder(
              key: _formKey,
              onChanged: () {
                _formData = _formKey.currentState?.value ?? {};

                // Auto-calculate BMI when height and weight change
                if (_currentStep == 1) {
                  final values = _formKey.currentState?.value;
                  if (values != null &&
                      values['height'] != null &&
                      values['weight'] != null &&
                      values['height'] > 0 &&
                      values['weight'] > 0) {
                    _calculateBMI();
                  }
                }
              },
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildPersonalInfoStep(),
                  _buildPhysicalInfoStep(),
                  _buildAddressInfoStep(),
                  _buildFitnessInfoStep(),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _previousStep,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              _isLoading
                                  ? AppColors.textDisabled
                                  : AppColors.borderPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Previous',
                        style: AppTypography.buttonMedium.copyWith(
                          color:
                              _isLoading
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                if (_currentStep > 0) const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.textDisabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                            : Text(
                              _currentStep == 3 ? 'Complete' : 'Next',
                              style: AppTypography.buttonMedium,
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

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'Physical Information';
      case 2:
        return 'Address Details';
      case 3:
        return 'Fitness Profile';
      default:
        return '';
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // First Name
          FormBuilderTextField(
            name: 'first_name',
            initialValue: _formData['first_name'],
            decoration: InputDecoration(
              labelText: 'First Name',
              hintText: 'Enter your first name',
              prefixIcon: Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            textCapitalization: TextCapitalization.words,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(2),
              FormBuilderValidators.maxLength(50),
            ]),
            style: AppTypography.bodyLarge,
          ),

          const SizedBox(height: 20),

          // Last Name
          FormBuilderTextField(
            name: 'last_name',
            initialValue: _formData['last_name'],
            decoration: InputDecoration(
              labelText: 'Last Name',
              hintText: 'Enter your last name',
              prefixIcon: Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            textCapitalization: TextCapitalization.words,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(2),
              FormBuilderValidators.maxLength(50),
            ]),
            style: AppTypography.bodyLarge,
          ),

          const SizedBox(height: 20),

          // Phone Number with Country Code
          FormBuilderField<String>(
            name: 'phone',
            initialValue: _formData['phone'],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              return null;
            },
            builder: (FormFieldState<String> field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IntlPhoneField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderPrimary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderPrimary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                    ),
                    style: AppTypography.bodyLarge,
                    dropdownTextStyle: AppTypography.bodyMedium,
                    initialValue: field.value,
                    onChanged: (phone) {
                      final completeNumber = phone.completeNumber;
                      field.didChange(completeNumber);
                      _formData['phone'] = completeNumber;

                      // Store additional phone data
                      _formData['phone_country_code'] = phone.countryCode;
                      _formData['phone_number'] = phone.number;
                      _formData['phone_iso_code'] = phone.countryISOCode;

                      print('Phone updated: $completeNumber');
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return 'Phone number is required';
                      }
                      if (phone.number.length < 7) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        field.errorText!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Date of Birth
          FormBuilderDateTimePicker(
            name: 'date_of_birth',
            inputType: InputType.date,
            format: DateFormat('dd/MM/yyyy'),
            initialValue: _formData['date_of_birth'],
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              hintText: 'Select your date of birth',
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: AppColors.textSecondary,
              ),
              suffixIcon: Icon(
                Icons.arrow_drop_down,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            firstDate: DateTime(1950),
            lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
            validator: FormBuilderValidators.required(),
            style: AppTypography.bodyLarge,
          ),

          const SizedBox(height: 20),

          // Gender Selection
          FormBuilderRadioGroup(
            name: 'gender',
            initialValue: _formData['gender'],
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: InputBorder.none,
            ),
            validator: FormBuilderValidators.required(),
            options: [
              FormBuilderFieldOption(
                value: 'male',
                child: _buildGenderOption('Male', Icons.male),
              ),
              FormBuilderFieldOption(
                value: 'female',
                child: _buildGenderOption('Female', Icons.female),
              ),
              FormBuilderFieldOption(
                value: 'other',
                child: _buildGenderOption('Other', Icons.person),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(gender, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildPhysicalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Height
          FormBuilderTextField(
            name: 'height',
            initialValue: _formData['height']?.toString(),
            decoration: InputDecoration(
              labelText: 'Height (cm)',
              hintText: 'Enter your height in centimeters',
              prefixIcon: Icon(Icons.height, color: AppColors.textSecondary),
              suffixText: 'cm',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.numeric(),
              FormBuilderValidators.min(100),
              FormBuilderValidators.max(250),
            ]),
            style: AppTypography.bodyLarge,
            valueTransformer:
                (text) => text != null ? int.tryParse(text) : null,
            onChanged: (value) {
              // Trigger immediate BMI calculation when height changes
              if (value != null && value.isNotEmpty) {
                final heightValue = int.tryParse(value);
                final weightValue = _formKey.currentState?.value['weight'];

                if (heightValue != null &&
                    weightValue != null &&
                    heightValue > 0 &&
                    weightValue > 0) {
                  print(
                    'Triggering BMI calculation: Height=$heightValue, Weight=$weightValue',
                  );
                  _calculateBMI(instant: true);
                }
              }
            },
          ),

          const SizedBox(height: 20),

          // Weight
          FormBuilderTextField(
            name: 'weight',
            initialValue: _formData['weight']?.toString(),
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'Enter your weight in kilograms',
              prefixIcon: Icon(
                Icons.monitor_weight_outlined,
                color: AppColors.textSecondary,
              ),
              suffixText: 'kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.numeric(),
              FormBuilderValidators.min(20),
              FormBuilderValidators.max(300),
            ]),
            style: AppTypography.bodyLarge,
            valueTransformer:
                (text) => text != null ? double.tryParse(text) : null,
            onChanged: (value) {
              // Trigger immediate BMI calculation when weight changes
              if (value != null && value.isNotEmpty) {
                final weightValue = double.tryParse(value);
                final heightValue = _formKey.currentState?.value['height'];

                if (weightValue != null &&
                    heightValue != null &&
                    weightValue > 0 &&
                    heightValue > 0) {
                  print(
                    'Triggering BMI calculation: Height=$heightValue, Weight=$weightValue',
                  );
                  _calculateBMI(instant: true);
                }
              }
            },
          ),

          const SizedBox(height: 32),

          // BMI Display Section
          if (_bmi > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your BMI Result',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // BMI Value and Category
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getBMIColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getBMIColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BMI Index',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _bmi.toStringAsFixed(1),
                              style: AppTypography.headlineMedium.copyWith(
                                color: _getBMIColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Category',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getBMIColor(),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _bmiCategory,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BMI Advice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getBMIAdvice(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BMI Reference Chart
                  Text(
                    'BMI Categories',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBMIReference('Underweight', '< 18.5', AppColors.info),
                  _buildBMIReference(
                    'Normal',
                    '18.5 - 24.9',
                    AppColors.success,
                  ),
                  _buildBMIReference(
                    'Overweight',
                    '25.0 - 29.9',
                    AppColors.warning,
                  ),
                  _buildBMIReference('Obese', '≥ 30.0', AppColors.error),
                ],
              ),
            ),
          ] else if (_isCalculatingBMI) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calculating your BMI...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAddressInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Address Line 1
          FormBuilderTextField(
            name: 'address_line1',
            initialValue: _formData['address_line1'],
            decoration: InputDecoration(
              labelText: 'Address Line 1',
              hintText: 'Street address, building number',
              prefixIcon: Icon(
                Icons.home_outlined,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            textCapitalization: TextCapitalization.words,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(5),
              FormBuilderValidators.maxLength(100),
            ]),
            style: AppTypography.bodyLarge,
          ),

          const SizedBox(height: 20),

          // Address Line 2 (Optional)
          FormBuilderTextField(
            name: 'address_line2',
            initialValue: _formData['address_line2'],
            decoration: InputDecoration(
              labelText: 'Address Line 2 (Optional)',
              hintText: 'Apartment, suite, unit, etc.',
              prefixIcon: Icon(
                Icons.apartment_outlined,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            textCapitalization: TextCapitalization.words,
            validator: FormBuilderValidators.maxLength(100),
            style: AppTypography.bodyLarge,
          ),

          const SizedBox(height: 20),

          // City
          FormBuilderTextField(
            name: 'city',
            initialValue: _formData['city'],
            decoration: InputDecoration(
              labelText: 'City',
              hintText: 'Enter your city',
              prefixIcon: Icon(
                Icons.location_city_outlined,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            textCapitalization: TextCapitalization.words,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(2),
              FormBuilderValidators.maxLength(50),
            ]),
            style: AppTypography.bodyLarge,
          ),

          const SizedBox(height: 20),

          // State/Province
          FormBuilderTextField(
            name: 'state',
            initialValue: _formData['state'],
            decoration: InputDecoration(
              labelText: 'State/Province',
              hintText: 'Enter your state or province',
              prefixIcon: Icon(
                Icons.map_outlined,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            textCapitalization: TextCapitalization.words,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(2),
              FormBuilderValidators.maxLength(50),
            ]),
            style: AppTypography.bodyLarge,
          ),

          const SizedBox(height: 20),

          // ZIP Code
          FormBuilderTextField(
            name: 'zip_code',
            initialValue: _formData['zip_code'],
            decoration: InputDecoration(
              labelText: 'ZIP/Postal Code',
              hintText: 'Enter your ZIP or postal code',
              prefixIcon: Icon(
                Icons.local_post_office_outlined,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            textCapitalization: TextCapitalization.characters,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.minLength(3),
              FormBuilderValidators.maxLength(10),
            ]),
            style: AppTypography.bodyLarge,
          ),

          const SizedBox(height: 20),

          // Country Selector
          GestureDetector(
            onTap: () {
              showCountryPicker(
                context: context,
                countryListTheme: CountryListThemeData(
                  borderRadius: BorderRadius.circular(12),
                  inputDecoration: InputDecoration(
                    labelText: 'Search Country',
                    hintText: 'Search by name or code',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.borderPrimary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                  ),
                  searchTextStyle: AppTypography.bodyMedium,
                  textStyle: AppTypography.bodyMedium,
                ),
                onSelect: (Country country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                },
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderPrimary),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surfaceVariant,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCountry?.name ?? 'Select your country',
                      style:
                          _selectedCountry != null
                              ? AppTypography.bodyLarge
                              : AppTypography.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                    ),
                  ),
                  if (_selectedCountry != null) ...[
                    Text(
                      _selectedCountry!.flagEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ] else
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Emergency Contact Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emergency_outlined,
                      color: AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Emergency Contact',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Emergency Contact Name
                FormBuilderTextField(
                  name: 'emergency_contact_name',
                  initialValue: _formData['emergency_contact_name'],
                  decoration: InputDecoration(
                    labelText: 'Contact Name',
                    hintText: 'Enter emergency contact name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.borderPrimary,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.borderPrimary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(2),
                    FormBuilderValidators.maxLength(50),
                  ]),
                  style: AppTypography.bodyMedium,
                ),

                const SizedBox(height: 12),

                // Emergency Contact Phone
                FormBuilderTextField(
                  name: 'emergency_contact_phone',
                  initialValue: _formData['emergency_contact_phone'],
                  decoration: InputDecoration(
                    labelText: 'Contact Phone',
                    hintText: 'Enter emergency contact phone',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.borderPrimary,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.borderPrimary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(10),
                    FormBuilderValidators.maxLength(20),
                  ]),
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFitnessInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fitness Level
          Text(
            'What is your current fitness level?',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FormBuilderField<String>(
            name: 'fitness_level',
            initialValue: _formData['fitness_level'],
            validator: FormBuilderValidators.required(
              errorText: 'Please select your fitness level',
            ),
            builder: (FormFieldState<String> field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _fitnessLevels.map((level) {
                          final isSelected = field.value == level;
                          return GestureDetector(
                            onTap: () {
                              field.didChange(level);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.borderPrimary,
                                ),
                              ),
                              child: Text(
                                level,
                                style: AppTypography.bodyMedium.copyWith(
                                  color:
                                      isSelected
                                          ? AppColors.white
                                          : AppColors.textPrimary,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        field.errorText!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Fitness Goals
          Text(
            'What are your fitness goals? (Select all that apply)',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FormBuilderCheckboxGroup(
            name: 'fitness_goals',
            initialValue:
                _formData['fitness_goals'] != null
                    ? List<String>.from(_formData['fitness_goals'])
                    : <String>[],
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            options:
                _fitnessGoals
                    .map(
                      (goal) => FormBuilderFieldOption(
                        value: goal,
                        child: _buildCheckboxOption(goal),
                      ),
                    )
                    .toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select at least one fitness goal';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Health Conditions
          Text(
            'Do you have any health conditions we should know about?',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FormBuilderCheckboxGroup(
            name: 'health_conditions',
            initialValue:
                _formData['health_conditions'] != null
                    ? List<String>.from(_formData['health_conditions'])
                    : <String>[],
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            options:
                _healthConditions
                    .map(
                      (condition) => FormBuilderFieldOption(
                        value: condition,
                        child: _buildCheckboxOption(condition),
                      ),
                    )
                    .toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your health conditions (or "None")';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Additional Notes (Optional)
          Text(
            'Additional Notes (Optional)',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'additional_notes',
            initialValue: _formData['additional_notes'],
            decoration: InputDecoration(
              hintText:
                  'Any additional information about your fitness journey, preferences, or medical conditions...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            validator: FormBuilderValidators.maxLength(500),
            style: AppTypography.bodyMedium,
          ),

          const SizedBox(height: 32),

          // Privacy Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your health and fitness information is kept private and secure. This data helps us provide personalized recommendations and ensure your safety during workouts.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCheckboxOption(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: AppTypography.bodyMedium),
    );
  }
}
