import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchingPreferencesScreen extends StatefulWidget {
  const MatchingPreferencesScreen({super.key});

  @override
  State<MatchingPreferencesScreen> createState() =>
      _MatchingPreferencesScreenState();
}

class _MatchingPreferencesScreenState extends State<MatchingPreferencesScreen> {
  final _supabase = Supabase.instance.client;
  RangeValues _ageRange = const RangeValues(18, 30);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('users')
          .select('preferred_age_min, preferred_age_max')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          final minAge = (data['preferred_age_min'] as num?)?.toDouble() ?? 18;
          final maxAge = (data['preferred_age_max'] as num?)?.toDouble() ?? 30;
          _ageRange = RangeValues(minAge, maxAge);
        });
      }
    } catch (_) {
      // Columns might not exist yet, use defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _savePreferences() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('users').update({
        'preferred_age_min': _ageRange.start.round(),
        'preferred_age_max': _ageRange.end.round(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved!'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Matching Preferences',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age range section
                  _buildSectionHeader('Age Range', Icons.cake_outlined),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_ageRange.start.round()} – ${_ageRange.end.round()} years',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF7C3AED),
                      inactiveTrackColor: Colors.white.withOpacity(0.08),
                      thumbColor: Colors.white,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 9),
                      trackHeight: 4,
                      overlayColor:
                          const Color(0xFF7C3AED).withOpacity(0.15),
                    ),
                    child: RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 80,
                      divisions: 62,
                      onChanged: (v) => setState(() => _ageRange = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('18',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12)),
                      Text('80',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12)),
                    ],
                  ),
                  const Spacer(),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _savePreferences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save Preferences',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

}
