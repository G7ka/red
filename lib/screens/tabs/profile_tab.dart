import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../widgets/full_screen_media_viewer.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();
  bool _uploadingImage = false;

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
            child: Text('Not logged in',
                style: TextStyle(color: Colors.white70))),
      );
    }

    return Material(
      color: const Color(0xFF0A0A0F),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('users')
            .stream(primaryKey: ['id']).eq('id', user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Error loading profile',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.first;
          return _buildProfileContent(user.id, data);
        },
      ),
    );
  }

  Widget _buildProfileContent(String uid, Map<String, dynamic> data) {
    final displayName = data['display_name'] as String? ?? 'No name';
    final firstName = data['first_name'] as String? ?? '';
    final lastName = data['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final age = _calculateAge(data['dob'] as String?);
    final gender = data['gender'] as String?;
    final interests = List<String>.from(data['interests'] ?? []);
    final profileImages = List<String>.from(data['profile_images'] ?? []);
    final mainImageUrl = data['image_url'] as String?;

    // Fallback to main image if profileImages is empty
    if (profileImages.isEmpty && mainImageUrl != null) {
      profileImages.add(mainImageUrl);
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Fixed ambient purple gradient (never shakes or stutters on scroll)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2D1556),
                    Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Content
          RefreshIndicator(
            color: const Color(0xFF7C3AED),
            backgroundColor: const Color(0xFF1A1A2E),
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 24),
                    child: Column(
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            _buildIconButton(
                              Icons.settings_outlined,
                              onTap: () => Scaffold.of(context).openDrawer(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                    // Main profile image
                    GestureDetector(
                  onTap: () => _addProfilePicture(uid, 0, profileImages),
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF7C3AED),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF7C3AED).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: profileImages.isNotEmpty
                              ? Image.network(
                                  profileImages[0],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1A1A2E),
                                    child: const Icon(Icons.person,
                                        color: Colors.white54, size: 50),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFF1A1A2E),
                                  child: const Icon(Icons.person,
                                      color: Colors.white54, size: 50),
                                ),
                        ),
                      ),
                      if (_uploadingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF7C3AED),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF0A0A0F), width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Name & age
                Text(
                  fullName.isNotEmpty ? fullName : displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (age != null) ...[
                      Icon(Icons.cake_outlined,
                          color: Colors.grey[500], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$age years',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                    if (gender != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        gender == 'male' ? Icons.male : Icons.female,
                        color: Colors.grey[500],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        gender[0].toUpperCase() + gender.substring(1),
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // Additional profile pictures
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildPhotosGrid(uid, profileImages),
          ),
        ),

        // Interests
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: _buildInterestsCard(interests, uid),
          ),
        ),

        // Bottom padding for floating nav
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),

      ],
    ),
  ),
],
),
);
}

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF7C3AED).withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }

  Widget _buildPhotosGrid(String uid, List<String> profileImages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (profileImages.length < 5)
              Text(
                '${5 - profileImages.length} slots open',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(5, (index) {
              final hasImage = index < profileImages.length;
              return Padding(
                padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                child: GestureDetector(
                  onTap: () =>
                      _addProfilePicture(uid, index, profileImages),
                  child: Container(
                    width: 90,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF1A1A2E),
                      border: Border.all(
                        color: hasImage
                            ? Colors.transparent
                            : const Color(0xFF7C3AED).withOpacity(0.2),
                      ),
                      image: hasImage
                          ? DecorationImage(
                              image:
                                  NetworkImage(profileImages[index]),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasImage
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  color: Colors.grey[600], size: 24),
                              const SizedBox(height: 4),
                              Text('Add',
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11)),
                            ],
                          )
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsCard(List<String> interests, String uid) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite,
                  color: Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Interests',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _editInterests(uid, interests),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (interests.isEmpty)
            Text('No interests added yet',
                style: TextStyle(color: Colors.grey[500]))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7C3AED).withOpacity(0.2),
                        const Color(0xFFDB2777).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.2)),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }


  int? _calculateAge(String? dobString) {
    if (dobString == null) return null;
    final dob = DateTime.tryParse(dobString);
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _addProfilePicture(
      String uid, int index, List<String> currentImages) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingImage = true);

    try {
      final imageFile = File(picked.path);
      final fileName =
          '${uid}_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'profile_images/$fileName';

      await _supabase.storage.from('profile-images').upload(storagePath, imageFile);
      final downloadUrl =
          _supabase.storage.from('profile-images').getPublicUrl(storagePath);

      final updatedImages = List<String>.from(currentImages);
      if (index < updatedImages.length) {
        updatedImages[index] = downloadUrl;
      } else {
        updatedImages.add(downloadUrl);
      }

      await _supabase.from('users').update({
        'profile_images': updatedImages,
        if (index == 0) 'image_url': downloadUrl,
      }).eq('id', uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _editInterests(
      String uid, List<String> currentInterests) async {
    final allInterests = [
      'Music', 'Sports', 'Gaming', 'Movies', 'Reading',
      'Travel', 'Food', 'Art', 'Photography', 'Fitness',
      'Dancing', 'Cooking', 'Technology', 'Fashion', 'Nature',
      'Animals', 'Comedy', 'Writing', 'Yoga', 'Learning',
    ];

    List<String> selected = List<String>.from(currentInterests);

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Interests',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allInterests.map((interest) {
                    final isSelected = selected.contains(interest);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            selected.remove(interest);
                          } else {
                            selected.add(interest);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFF6D28D9)
                                  ],
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFF252540),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _supabase.from('users').update(
                          {'interests': selected}).eq('id', uid);
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Save',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showSettingsDialog(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF7C3AED)),
                title: const Text('Edit Name',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _editName(uid);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Account',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAccount();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(String uid) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Edit Name',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'New display name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await _supabase
                  .from('users')
                  .update({'display_name': name}).eq('id', uid);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated')),
                );
              }
            },
            child: const Text('Save',
                style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Account',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
