import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../../models/penguin_user.dart';
import '../../services/auth_service.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _supabase = Supabase.instance.client;

  String? _gender;
  DateTime? _dob;
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // 3-photo system: index 0 = main photo, 1 & 2 = additional
  final List<File?> _photos = [null, null, null];

  List<String> _selectedInterests = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const List<String> _availableInterests = [
    '🎵 Music', '⚽ Sports', '🎮 Gaming', '🎬 Movies', '📚 Reading',
    '✈️ Travel', '🍕 Food', '🎨 Art', '📸 Photography', '💪 Fitness',
    '💃 Dancing', '🍳 Cooking', '💻 Technology', '👗 Fashion', '🌿 Nature',
    '🐾 Animals', '😂 Comedy', '📝 Writing', '🧘 Yoga', '📖 Learning',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 17),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              surface: Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickPhoto(int index) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _photos[index] = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _gender == null ||
        _dob == null ||
        _selectedInterests.isEmpty) {
      setState(() {
        _error =
            'Please fill all required fields and select at least one interest.';
      });
      return;
    }

    if (_photos[0] == null || _photos[1] == null || _photos[2] == null) {
      setState(() => _error = 'Please add exactly 3 photos.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cleanInterests = _selectedInterests
          .map((i) => i.replaceAll(RegExp(r'^[^\w]+\s*'), ''))
          .toList();

      final profile = PenguinUser(
        id: 'temp',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
        displayName: _firstNameController.text.trim(),
        gender: _gender!,
        dob: _dob!,
        interests: cleanInterests,
        friends: const [],
      );

      final user = await AuthService.instance.signUpWithEmailOTP(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        profile: profile,
      );

      if (user == null) throw Exception('Failed to create account');

      // Upload all photos
      List<String> photoUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        if (_photos[i] != null) {
          final fileName =
              '${user.id}_photo${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storagePath = 'profile_images/$fileName';

          await _supabase.storage
              .from('profile-images')
              .upload(storagePath, _photos[i]!);
          final imageUrl =
              _supabase.storage.from('profile-images').getPublicUrl(storagePath);
          photoUrls.add(imageUrl);
        }
      }

      // Update profile with all photos
      if (photoUrls.isNotEmpty) {
        await AuthService.instance
            .updateProfileImages(user.id, photoUrls);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            profile: profile,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Sign up failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon:
          Icon(icon, color: const Color(0xFF7C3AED).withOpacity(0.7), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF1A1A2E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
    );
  }

  // ─── Photo Grid (3 photos) ───
  Widget _buildPhotoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_outlined,
                color: const Color(0xFF7C3AED).withOpacity(0.7), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Your Photos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Required',
                style: TextStyle(color: Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 1: Main photo (big) + 2 side photos
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildPhotoSlot(0, isMain: true, height: 180),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildPhotoSlot(1, height: 85),
                  const SizedBox(height: 8),
                  _buildPhotoSlot(2, height: 85),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSlot(int index, {bool isMain = false, required double height}) {
    final photo = _photos[index];
    return GestureDetector(
      onTap: () => _pickPhoto(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: photo != null
                ? const Color(0xFF7C3AED).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isMain && photo == null ? 2 : 1,
          ),
          gradient: photo == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isMain
                      ? [
                          const Color(0xFF7C3AED).withOpacity(0.08),
                          const Color(0xFFDB2777).withOpacity(0.08),
                        ]
                      : [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF1A1A2E),
                        ],
                )
              : null,
          image: photo != null
              ? DecorationImage(
                  image: FileImage(photo),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: photo != null
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: photo == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isMain ? Icons.add_a_photo : Icons.add,
                    color: isMain
                        ? const Color(0xFF7C3AED)
                        : Colors.white.withOpacity(0.3),
                    size: isMain ? 28 : 20,
                  ),
                  if (isMain) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Main Photo',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: isMain
                      ? const Icon(Icons.star, color: Color(0xFFFFD700), size: 14)
                      : const Icon(Icons.edit, color: Colors.white, size: 12),
                ),
              ),
      ),
    );
  }

  // ─── Premium Gender Selector ───
  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline,
                color: const Color(0xFF7C3AED).withOpacity(0.7), size: 20),
            const SizedBox(width: 8),
            const Text(
              'I am',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenderCard('male', Icons.male, 'Male')),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderCard('female', Icons.female, 'Female')),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(String value, IconData icon, String label) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: value == 'male'
                      ? [const Color(0xFF3B82F6), const Color(0xFF7C3AED)]
                      : [const Color(0xFFDB2777), const Color(0xFF7C3AED)],
                )
              : null,
          color: isSelected ? null : const Color(0xFF1A1A2E),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFF7C3AED).withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (value == 'male'
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFDB2777))
                        .withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF7C3AED).withOpacity(0.08),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[500],
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[500],
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF0F0A1A),
              Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // Error
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red[300], size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                          color: Colors.red[300], fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ─── 3-Photo Grid ───
                          _buildPhotoGrid(),
                          const SizedBox(height: 24),

                          // Name fields
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                  decoration: _inputDecoration(
                                    label: 'First name',
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                  decoration: _inputDecoration(
                                    label: 'Last name',
                                    icon: Icons.person_outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ─── Premium Gender Selector ───
                          _buildGenderSelector(),
                          const SizedBox(height: 20),

                          // DOB
                          GestureDetector(
                            onTap: _pickDob,
                            child: AbsorbPointer(
                              child: TextFormField(
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                                decoration: _inputDecoration(
                                  label: 'Date of birth',
                                  icon: Icons.cake_outlined,
                                ),
                                controller: TextEditingController(
                                  text: _dob == null
                                      ? ''
                                      : '${_dob!.day.toString().padLeft(2, '0')} / ${_dob!.month.toString().padLeft(2, '0')} / ${_dob!.year}',
                                ),
                                validator: (v) => _dob == null
                                    ? 'Select date of birth'
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Interests
                          Row(
                            children: [
                              Icon(Icons.favorite_outline,
                                  color: const Color(0xFF7C3AED)
                                      .withOpacity(0.7),
                                  size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Interests',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(pick at least 1)',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _availableInterests.map((interest) {
                              final isSelected =
                                  _selectedInterests.contains(interest);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedInterests.remove(interest);
                                    } else {
                                      _selectedInterests.add(interest);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
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
                                    color: isSelected
                                        ? null
                                        : const Color(0xFF1A1A2E),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : const Color(0xFF7C3AED)
                                              .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    interest,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[400],
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: _inputDecoration(
                              label: 'Email',
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: _inputDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Min 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: _inputDecoration(
                              label: 'Confirm password',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Submit
                          SizedBox(
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFFDB2777)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED)
                                        .withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
