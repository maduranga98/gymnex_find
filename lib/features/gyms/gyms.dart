import 'package:flutter/material.dart';

class Gyms extends StatefulWidget {
  const Gyms({super.key});

  @override
  State<Gyms> createState() => _GymsState();
}

class _GymsState extends State<Gyms> {
  // Sample gym data - replace with your Firebase data
  final List<GymModel> gyms = [
    GymModel(
      id: '1',
      name: 'FitZone Premium',
      address: '123 Fitness Street, Downtown',
      rating: 4.8,
      distance: '0.5 km',
      imageUrl:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
      amenities: ['Pool', 'Sauna', 'Personal Training'],
      isOpen: true,
      membershipPrice: '\$49/month',
    ),
    GymModel(
      id: '2',
      name: 'Iron Paradise',
      address: '456 Strength Ave, Midtown',
      rating: 4.6,
      distance: '1.2 km',
      imageUrl:
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
      amenities: ['Free Weights', 'CrossFit', 'Nutrition Coaching'],
      isOpen: true,
      membershipPrice: '\$39/month',
    ),
    GymModel(
      id: '3',
      name: 'Zen Fitness Studio',
      address: '789 Wellness Blvd, Uptown',
      rating: 4.9,
      distance: '2.1 km',
      imageUrl:
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400',
      amenities: ['Yoga', 'Pilates', 'Meditation'],
      isOpen: false,
      membershipPrice: '\$55/month',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Nearby Gyms',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Add filter functionality
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search gyms...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),

          // Gym List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: gyms.length,
              itemBuilder: (context, index) {
                final gym = gyms[index];
                return GymCard(
                  gym: gym,
                  onTap: () => _navigateToGymProfile(gym),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToGymProfile(GymModel gym) {
    // Navigate to gym profile page
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => GymProfilePage(gym: gym),
    //   ),
    // );

    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${gym.name} profile...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class GymCard extends StatelessWidget {
  final GymModel gym;
  final VoidCallback onTap;

  const GymCard({super.key, required this.gym, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Gym Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Image.network(
                      gym.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.fitness_center,
                          color: Colors.grey[400],
                          size: 32,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Gym Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              gym.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  gym.isOpen
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              gym.isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                color:
                                    gym.isOpen
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Address
                      Text(
                        gym.address,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Rating, Distance, Price
                      Row(
                        children: [
                          // Rating
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                gym.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 16),

                          // Distance
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                gym.distance,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Price
                          Text(
                            gym.membershipPrice,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Amenities
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children:
                            gym.amenities.take(3).map((amenity) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  amenity,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Gym Model
class GymModel {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String distance;
  final String imageUrl;
  final List<String> amenities;
  final bool isOpen;
  final String membershipPrice;

  GymModel({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.distance,
    required this.imageUrl,
    required this.amenities,
    required this.isOpen,
    required this.membershipPrice,
  });
}
