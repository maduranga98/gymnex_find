import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymnex_find/utility/app_colors.dart';
import 'package:gymnex_find/utility/app_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

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

      print('Loading user data for UID: ${currentUser.uid}');

      final userDoc =
          await _firestore.collection('customers').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        print('User data loaded: ${userData.keys.toList()}');
        print(
          'Height: ${userData['height']} (${userData['height'].runtimeType})',
        );
        print(
          'Weight: ${userData['weight']} (${userData['weight'].runtimeType})',
        );
        print('BMI: ${userData['bmi']} (${userData['bmi'].runtimeType})');

        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'User profile not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _error = 'Failed to load user data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getFirstName() {
    if (_userData == null) return 'User';
    return _userData!['firstName'] ?? 'User';
  }

  // FIXED: Safe type conversion for height
  int _getHeight() {
    if (_userData == null) return 0;
    final heightData = _userData!['height'];

    // Handle different data types safely
    if (heightData is int) return heightData;
    if (heightData is double) return heightData.toInt();
    if (heightData is String) {
      return int.tryParse(heightData) ?? 0;
    }
    return 0;
  }

  // FIXED: Safe type conversion for weight
  double _getWeight() {
    if (_userData == null) return 0.0;
    final weightData = _userData!['weight'];

    // Handle different data types safely
    if (weightData is double) return weightData;
    if (weightData is int) return weightData.toDouble();
    if (weightData is String) {
      return double.tryParse(weightData) ?? 0.0;
    }
    return 0.0;
  }

  // FIXED: Safe type conversion for BMI
  double _getBMI() {
    if (_userData == null) return 0.0;
    final bmiData = _userData!['bmi'];

    // Handle different data types safely
    if (bmiData is double) return bmiData;
    if (bmiData is int) return bmiData.toDouble();
    if (bmiData is String) {
      return double.tryParse(bmiData) ?? 0.0;
    }
    return 0.0;
  }

  String _getBMICategory() {
    if (_userData == null) return 'Unknown';
    return _userData!['bmiCategory'] ?? 'Unknown';
  }

  Color _getBMIColor() {
    final bmi = _getBMI();
    if (bmi < 18.5) return AppColors.info;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildUserInfoCard() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Unable to load profile',
              style: AppTypography.titleMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Retry', style: AppTypography.buttonMedium),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting and Name
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFirstName(),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile Picture Placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(Icons.person, color: AppColors.white, size: 30),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Health Stats
            Row(
              children: [
                // Height & Weight
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.height,
                    label: 'Height',
                    value: _getHeight() > 0 ? '${_getHeight()} cm' : 'Not set',
                    isWhiteBackground: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    value:
                        _getWeight() > 0
                            ? '${_getWeight().toStringAsFixed(1)} kg'
                            : 'Not set',
                    isWhiteBackground: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // BMI Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getBMIColor(),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI Score',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _getBMI() > 0
                                  ? _getBMI().toStringAsFixed(1)
                                  : '--',
                              style: AppTypography.headlineSmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getBMIColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getBMICategory(),
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
                  // BMI Trend Icon (Optional)
                  Icon(
                    Icons.trending_up,
                    color: AppColors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    bool isWhiteBackground = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isWhiteBackground
                ? AppColors.white.withOpacity(0.15)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isWhiteBackground
                  ? AppColors.white.withOpacity(0.2)
                  : AppColors.borderPrimary,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isWhiteBackground ? AppColors.white : AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color:
                  isWhiteBackground
                      ? AppColors.white.withOpacity(0.8)
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color:
                  isWhiteBackground ? AppColors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Navigation Pages
  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // User Info Header
          _buildUserInfoCard(),

          // Rest of home page content
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Quick Actions Section
                Container(
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
                        'Quick Actions',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.search,
                              label: 'Find Gyms',
                              onTap: () {
                                setState(() {
                                  _currentIndex = 2; // Navigate to Explore
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.calendar_today,
                              label: 'Schedule',
                              onTap: () {
                                setState(() {
                                  _currentIndex = 1; // Navigate to Schedule
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.article_outlined,
                              label: 'Tips & Blog',
                              onTap: () {
                                setState(() {
                                  _currentIndex = 3; // Navigate to Blog
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.person_outline,
                              label: 'Profile',
                              onTap: () {
                                setState(() {
                                  _currentIndex = 4; // Navigate to Profile
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Recent Activity
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
                      Text(
                        'Recent Activity',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity to show.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Extra padding for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'My Schedule',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your workout schedule and gym sessions',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Today's Schedule
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.today, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Schedule',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildScheduleItem(
                  time: '7:00 AM',
                  title: 'Morning Cardio',
                  subtitle: 'Fitness Zone Gym',
                  isCompleted: false,
                ),
                const SizedBox(height: 12),
                _buildScheduleItem(
                  time: '6:00 PM',
                  title: 'Strength Training',
                  subtitle: 'PowerHouse Gym',
                  isCompleted: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Weekly Schedule
          Text(
            'This Week',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                _buildWeeklyScheduleCard('Monday', [
                  {
                    'time': '7:00 AM',
                    'activity': 'Cardio',
                    'gym': 'Fitness Zone',
                  },
                  {
                    'time': '6:00 PM',
                    'activity': 'Strength',
                    'gym': 'PowerHouse',
                  },
                ]),
                _buildWeeklyScheduleCard('Tuesday', [
                  {
                    'time': '6:30 PM',
                    'activity': 'Yoga',
                    'gym': 'ZenFit Studio',
                  },
                ]),
                _buildWeeklyScheduleCard('Wednesday', [
                  {
                    'time': '7:00 AM',
                    'activity': 'HIIT',
                    'gym': 'Fitness Zone',
                  },
                ]),
                _buildWeeklyScheduleCard('Thursday', [
                  {
                    'time': '6:00 PM',
                    'activity': 'Swimming',
                    'gym': 'AquaFit Center',
                  },
                ]),
                _buildWeeklyScheduleCard('Friday', [
                  {
                    'time': '7:00 AM',
                    'activity': 'Strength',
                    'gym': 'PowerHouse',
                  },
                  {
                    'time': '7:00 PM',
                    'activity': 'CrossFit',
                    'gym': 'Elite Box',
                  },
                ]),
                const SizedBox(height: 100), // Extra padding for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String time,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCompleted
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.borderPrimary,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScheduleCard(
    String day,
    List<Map<String, String>> activities,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...activities
              .map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activity['time']!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '${activity['activity']} at ${activity['gym']}',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildExplorePage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Explore Gyms',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover gyms near you and find your perfect workout spot',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search gyms near you...',
                      border: InputBorder.none,
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Nearby Gyms
          Text(
            'Nearby Gyms',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                _buildGymCard(
                  name: 'Fitness Zone',
                  address: '123 Main Street, Colombo',
                  rating: 4.5,
                  distance: '0.5 km',
                  imageIcon: Icons.fitness_center,
                ),
                _buildGymCard(
                  name: 'PowerHouse Gym',
                  address: '456 Union Place, Colombo',
                  rating: 4.7,
                  distance: '1.2 km',
                  imageIcon: Icons.sports_gymnastics,
                ),
                _buildGymCard(
                  name: 'ZenFit Studio',
                  address: '789 Galle Road, Colombo',
                  rating: 4.3,
                  distance: '2.1 km',
                  imageIcon: Icons.self_improvement,
                ),
                const SizedBox(height: 100), // Extra padding for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGymCard({
    required String name,
    required String address,
    required double rating,
    required String distance,
    required IconData imageIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(imageIcon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Blog & Tips',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Read fitness tips, workout guides, and health articles',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Profile',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Manage your profile, settings, and preferences',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildSchedulePage();
      case 2:
        return _buildExplorePage();
      case 3:
        return _buildBlogPage();
      case 4:
        return _buildProfilePage();
      default:
        return _buildHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _getCurrentPage()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTypography.bodySmall,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Blog',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
