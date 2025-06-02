import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:gymnex_find/utility/app_colors.dart';
import 'package:gymnex_find/utility/app_fonts.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _error;
  File? _selectedImage;
  String? _profileImageUrl;
  Country? _selectedCountry;

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final userDoc =
          await _firestore.collection('customers').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;

        setState(() {
          _userData = userData;
          _profileImageUrl = userData['profileImageUrl'];

          // Set selected country for address
          final countryCode = userData['address']?['countryCode'];
          if (countryCode != null) {
            try {
              _selectedCountry = Country.tryParse(countryCode);
            } catch (e) {
              print('Error parsing country: $e');
            }
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'User profile not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load user data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder:
            (context) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Profile Photo',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImagePickerOption(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: () => _selectImage(ImageSource.camera),
                      ),
                      _buildImagePickerOption(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onTap: () => _selectImage(ImageSource.gallery),
                      ),
                      if (_profileImageUrl != null)
                        _buildImagePickerOption(
                          icon: Icons.delete,
                          label: 'Remove',
                          onTap: _removeProfileImage,
                          isDestructive: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      );
    } catch (e) {
      _showSnackBar(
        'Error opening image picker: ${e.toString()}',
        AppColors.error,
      );
    }
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  isDestructive
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDestructive ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting image: ${e.toString()}', AppColors.error);
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() {
      _selectedImage = null;
      _profileImageUrl = null;
    });
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return _profileImageUrl;

    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return null;

      final storageRef = _storage
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}.jpg');

      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      _showSnackBar('Failed to upload image: ${e.toString()}', AppColors.error);
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final formData = _formKey.currentState!.value;

      // Upload profile image if selected
      String? imageUrl = await _uploadProfileImage();

      // Calculate BMI
      double bmi = 0.0;
      String bmiCategory = '';
      final height = _parseToInt(formData['height']);
      final weight = _parseToDouble(formData['weight']);

      if (height > 0 && weight > 0) {
        double heightInMeters = height / 100;
        bmi = weight / (heightInMeters * heightInMeters);

        if (bmi < 18.5) {
          bmiCategory = 'Underweight';
        } else if (bmi < 25) {
          bmiCategory = 'Normal weight';
        } else if (bmi < 30) {
          bmiCategory = 'Overweight';
        } else {
          bmiCategory = 'Obese';
        }
      }

      // Prepare updated user data
      final updatedData = <String, dynamic>{
        'firstName': formData['firstName']?.toString() ?? '',
        'lastName': formData['lastName']?.toString() ?? '',
        'phone': {'complete': formData['phone']?.toString() ?? ''},
        'dateOfBirth': formData['dateOfBirth']?.toIso8601String(),
        'gender': formData['gender']?.toString() ?? '',
        'height': height,
        'weight': weight,
        'bmi': bmi,
        'bmiCategory': bmiCategory,
        'address': {
          'line1': formData['addressLine1']?.toString() ?? '',
          'line2': formData['addressLine2']?.toString() ?? '',
          'city': formData['city']?.toString() ?? '',
          'state': formData['state']?.toString() ?? '',
          'zipCode': formData['zipCode']?.toString() ?? '',
          'country': _selectedCountry?.name ?? '',
          'countryCode': _selectedCountry?.countryCode ?? '',
        },
        'fitnessProfile': {
          'level': formData['fitnessLevel']?.toString() ?? '',
          'goals': List<String>.from(formData['fitnessGoals'] ?? []),
          'healthConditions': List<String>.from(
            formData['healthConditions'] ?? [],
          ),
          'additionalNotes': formData['additionalNotes']?.toString() ?? '',
        },
        'emergencyContact': {
          'name': formData['emergencyContactName']?.toString() ?? '',
          'phone': formData['emergencyContactPhone']?.toString() ?? '',
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add profile image URL if available
      if (imageUrl != null) {
        updatedData['profileImageUrl'] = imageUrl;
      }

      // Update Firestore
      await _firestore
          .collection('customers')
          .doc(currentUser.uid)
          .update(updatedData);

      // Update display name
      final fullName = '${formData['firstName']} ${formData['lastName']}';
      await currentUser.updateDisplayName(fullName);

      setState(() {
        _isEditing = false;
        _selectedImage = null;
        if (imageUrl != null) {
          _profileImageUrl = imageUrl;
        }
      });

      _showSnackBar('Profile updated successfully!', AppColors.success);

      // Reload data to reflect changes
      await _loadUserData();
    } catch (e) {
      _showSnackBar('Failed to save profile: ${e.toString()}', AppColors.error);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
        ),
      );
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 4),
                ),
                child: ClipOval(
                  child:
                      _selectedImage != null
                          ? Image.file(
                            _selectedImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                          : _profileImageUrl != null
                          ? Image.network(
                            _profileImageUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 120,
                                height: 120,
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: AppColors.surfaceVariant,
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          )
                          : Container(
                            width: 120,
                            height: 120,
                            color: AppColors.white.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.white,
                            ),
                          ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // User Name
          Text(
            _userData != null
                ? '${_userData!['firstName'] ?? ''} ${_userData!['lastName'] ?? ''}'
                    .trim()
                : 'User Name',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Email
          Text(
            _firebaseAuth.currentUser?.email ?? 'email@example.com',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text('Retry', style: AppTypography.buttonMedium),
              ),
            ],
          ),
        ),
      );
    }

    if (_isEditing) {
      return _buildEditForm();
    } else {
      return _buildViewMode();
    }
  }

  Widget _buildViewMode() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Personal Information Card
          _buildInfoCard(
            title: 'Personal Information',
            children: [
              _buildInfoRow(
                'Full Name',
                '${_userData!['firstName'] ?? ''} ${_userData!['lastName'] ?? ''}'
                    .trim(),
              ),
              _buildInfoRow(
                'Phone',
                _userData!['phone']?['complete'] ?? 'Not set',
              ),
              _buildInfoRow(
                'Date of Birth',
                _userData!['dateOfBirth'] != null
                    ? DateFormat(
                      'dd/MM/yyyy',
                    ).format(DateTime.parse(_userData!['dateOfBirth']))
                    : 'Not set',
              ),
              _buildInfoRow('Gender', _userData!['gender'] ?? 'Not set'),
            ],
          ),

          const SizedBox(height: 16),

          // Physical Information Card
          _buildInfoCard(
            title: 'Physical Information',
            children: [
              _buildInfoRow(
                'Height',
                '${_parseToInt(_userData!['height'])} cm',
              ),
              _buildInfoRow(
                'Weight',
                '${_parseToDouble(_userData!['weight']).toStringAsFixed(1)} kg',
              ),
              _buildInfoRow(
                'BMI',
                '${_parseToDouble(_userData!['bmi']).toStringAsFixed(1)} (${_userData!['bmiCategory'] ?? 'Unknown'})',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Address Information Card
          _buildInfoCard(
            title: 'Address',
            children: [
              _buildInfoRow(
                'Address Line 1',
                _userData!['address']?['line1'] ?? 'Not set',
              ),
              if (_userData!['address']?['line2']?.isNotEmpty == true)
                _buildInfoRow('Address Line 2', _userData!['address']['line2']),
              _buildInfoRow(
                'City',
                _userData!['address']?['city'] ?? 'Not set',
              ),
              _buildInfoRow(
                'State',
                _userData!['address']?['state'] ?? 'Not set',
              ),
              _buildInfoRow(
                'ZIP Code',
                _userData!['address']?['zipCode'] ?? 'Not set',
              ),
              _buildInfoRow(
                'Country',
                _userData!['address']?['country'] ?? 'Not set',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fitness Information Card
          _buildInfoCard(
            title: 'Fitness Profile',
            children: [
              _buildInfoRow(
                'Fitness Level',
                _userData!['fitnessProfile']?['level'] ?? 'Not set',
              ),
              _buildInfoRow(
                'Goals',
                (_userData!['fitnessProfile']?['goals'] as List?)?.join(', ') ??
                    'Not set',
              ),
              _buildInfoRow(
                'Health Conditions',
                (_userData!['fitnessProfile']?['healthConditions'] as List?)
                        ?.join(', ') ??
                    'Not set',
              ),
              if (_userData!['fitnessProfile']?['additionalNotes']
                      ?.isNotEmpty ==
                  true)
                _buildInfoRow(
                  'Additional Notes',
                  _userData!['fitnessProfile']['additionalNotes'],
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Emergency Contact Card
          _buildInfoCard(
            title: 'Emergency Contact',
            children: [
              _buildInfoRow(
                'Name',
                _userData!['emergencyContact']?['name'] ?? 'Not set',
              ),
              _buildInfoRow(
                'Phone',
                _userData!['emergencyContact']?['phone'] ?? 'Not set',
              ),
            ],
          ),

          const SizedBox(height: 100), // Extra space for floating button
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          'firstName': _userData!['firstName'] ?? '',
          'lastName': _userData!['lastName'] ?? '',
          'phone': _userData!['phone']?['complete'] ?? '',
          'dateOfBirth':
              _userData!['dateOfBirth'] != null
                  ? DateTime.parse(_userData!['dateOfBirth'])
                  : null,
          'gender': _userData!['gender'] ?? '',
          'height': _parseToInt(_userData!['height']).toString(),
          'weight': _parseToDouble(_userData!['weight']).toString(),
          'addressLine1': _userData!['address']?['line1'] ?? '',
          'addressLine2': _userData!['address']?['line2'] ?? '',
          'city': _userData!['address']?['city'] ?? '',
          'state': _userData!['address']?['state'] ?? '',
          'zipCode': _userData!['address']?['zipCode'] ?? '',
          'fitnessLevel': _userData!['fitnessProfile']?['level'] ?? '',
          'fitnessGoals': List<String>.from(
            _userData!['fitnessProfile']?['goals'] ?? [],
          ),
          'healthConditions': List<String>.from(
            _userData!['fitnessProfile']?['healthConditions'] ?? [],
          ),
          'additionalNotes':
              _userData!['fitnessProfile']?['additionalNotes'] ?? '',
          'emergencyContactName': _userData!['emergencyContact']?['name'] ?? '',
          'emergencyContactPhone':
              _userData!['emergencyContact']?['phone'] ?? '',
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Personal Information Section
              _buildFormSection(
                title: 'Personal Information',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'firstName',
                          decoration: _buildInputDecoration('First Name'),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(2),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'lastName',
                          decoration: _buildInputDecoration('Last Name'),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(2),
                          ]),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'phone',
                    decoration: _buildInputDecoration('Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: FormBuilderValidators.required(),
                  ),

                  const SizedBox(height: 16),

                  FormBuilderDateTimePicker(
                    name: 'dateOfBirth',
                    inputType: InputType.date,
                    format: DateFormat('dd/MM/yyyy'),
                    decoration: _buildInputDecoration('Date of Birth'),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now().subtract(
                      const Duration(days: 365 * 13),
                    ),
                    validator: FormBuilderValidators.required(),
                  ),

                  const SizedBox(height: 16),

                  FormBuilderDropdown<String>(
                    name: 'gender',
                    decoration: _buildInputDecoration('Gender'),
                    validator: FormBuilderValidators.required(),
                    items:
                        ['Male', 'Female', 'Other']
                            .map(
                              (gender) => DropdownMenuItem(
                                value: gender.toLowerCase(),
                                child: Text(gender),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Physical Information Section
              _buildFormSection(
                title: 'Physical Information',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'height',
                          decoration: _buildInputDecoration('Height (cm)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.numeric(),
                            FormBuilderValidators.min(100),
                            FormBuilderValidators.max(250),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'weight',
                          decoration: _buildInputDecoration('Weight (kg)'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.numeric(),
                            FormBuilderValidators.min(20),
                            FormBuilderValidators.max(300),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Address Section
              _buildFormSection(
                title: 'Address',
                children: [
                  FormBuilderTextField(
                    name: 'addressLine1',
                    decoration: _buildInputDecoration('Address Line 1'),
                    validator: FormBuilderValidators.required(),
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'addressLine2',
                    decoration: _buildInputDecoration(
                      'Address Line 2 (Optional)',
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'city',
                          decoration: _buildInputDecoration('City'),
                          validator: FormBuilderValidators.required(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'state',
                          decoration: _buildInputDecoration('State'),
                          validator: FormBuilderValidators.required(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'zipCode',
                          decoration: _buildInputDecoration('ZIP Code'),
                          validator: FormBuilderValidators.required(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              onSelect: (Country country) {
                                setState(() {
                                  _selectedCountry = country;
                                });
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.borderPrimary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.surfaceVariant,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCountry?.name ?? 'Select Country',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color:
                                          _selectedCountry != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (_selectedCountry != null) ...[
                                  Text(
                                    _selectedCountry!.flagEmoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ] else
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.textSecondary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Fitness Profile Section
              _buildFormSection(
                title: 'Fitness Profile',
                children: [
                  FormBuilderDropdown<String>(
                    name: 'fitnessLevel',
                    decoration: _buildInputDecoration('Fitness Level'),
                    validator: FormBuilderValidators.required(),
                    items:
                        _fitnessLevels
                            .map(
                              (level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ),
                            )
                            .toList(),
                  ),

                  const SizedBox(height: 16),

                  FormBuilderCheckboxGroup<String>(
                    name: 'fitnessGoals',
                    decoration: const InputDecoration(
                      labelText: 'Fitness Goals',
                      border: InputBorder.none,
                    ),
                    options:
                        _fitnessGoals
                            .map(
                              (goal) => FormBuilderFieldOption(
                                value: goal,
                                child: Text(goal),
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

                  const SizedBox(height: 16),

                  FormBuilderCheckboxGroup<String>(
                    name: 'healthConditions',
                    decoration: const InputDecoration(
                      labelText: 'Health Conditions',
                      border: InputBorder.none,
                    ),
                    options:
                        _healthConditions
                            .map(
                              (condition) => FormBuilderFieldOption(
                                value: condition,
                                child: Text(condition),
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

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'additionalNotes',
                    decoration: _buildInputDecoration(
                      'Additional Notes (Optional)',
                      hintText:
                          'Any additional information about your fitness journey...',
                    ),
                    maxLines: 3,
                    validator: FormBuilderValidators.maxLength(500),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Emergency Contact Section
              _buildFormSection(
                title: 'Emergency Contact',
                children: [
                  FormBuilderTextField(
                    name: 'emergencyContactName',
                    decoration: _buildInputDecoration('Contact Name'),
                    validator: FormBuilderValidators.required(),
                  ),

                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'emergencyContactPhone',
                    decoration: _buildInputDecoration('Contact Phone'),
                    keyboardType: TextInputType.phone,
                    validator: FormBuilderValidators.required(),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isSaving
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
                            'Save Changes',
                            style: AppTypography.buttonLarge,
                          ),
                ),
              ),

              const SizedBox(height: 100), // Extra space for floating button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderPrimary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: AppColors.white,
              ),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    _selectedImage = null; // Reset selected image on cancel
                  }
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          _buildProfileHeader(),

          // Content
          Expanded(child: _buildInfoSection()),
        ],
      ),
      floatingActionButton:
          !_isEditing && _userData != null
              ? FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.edit, color: AppColors.white),
                label: Text(
                  'Edit Profile',
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
              )
              : null,
    );
  }
}
