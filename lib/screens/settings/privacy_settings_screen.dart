import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _supabase = Supabase.instance.client;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _showReadReceipts = true;
  bool _allowProfileViewing = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('users')
          .select(
              'show_online_status, show_last_seen, show_read_receipts, allow_profile_viewing')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _showOnlineStatus = data['show_online_status'] as bool? ?? true;
          _showLastSeen = data['show_last_seen'] as bool? ?? true;
          _showReadReceipts = data['show_read_receipts'] as bool? ?? true;
          _allowProfileViewing =
              data['allow_profile_viewing'] as bool? ?? true;
        });
      }
    } catch (_) {
      // Columns might not exist, use defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateSetting(String key, bool value) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('users').update({key: value}).eq('id', user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save setting: $e')),
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
        title: const Text('Privacy Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Visibility'),
                const SizedBox(height: 8),
                _buildToggle(
                  icon: Icons.circle,
                  iconColor: const Color(0xFF10B981),
                  title: 'Show Online Status',
                  subtitle:
                      'Let others see when you\'re online',
                  value: _showOnlineStatus,
                  onChanged: (v) {
                    setState(() => _showOnlineStatus = v);
                    _updateSetting('show_online_status', v);
                  },
                ),
                _buildToggle(
                  icon: Icons.access_time,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Show Last Seen',
                  subtitle: 'Let others see when you were last active',
                  value: _showLastSeen,
                  onChanged: (v) {
                    setState(() => _showLastSeen = v);
                    _updateSetting('show_last_seen', v);
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Messaging'),
                const SizedBox(height: 8),
                _buildToggle(
                  icon: Icons.done_all,
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Read Receipts',
                  subtitle: 'Let others know when you\'ve read their messages',
                  value: _showReadReceipts,
                  onChanged: (v) {
                    setState(() => _showReadReceipts = v);
                    _updateSetting('show_read_receipts', v);
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Profile'),
                const SizedBox(height: 8),
                _buildToggle(
                  icon: Icons.person_search,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Allow Profile Viewing',
                  subtitle:
                      'Let others view your full profile from chats',
                  value: _allowProfileViewing,
                  onChanged: (v) {
                    setState(() => _allowProfileViewing = v);
                    _updateSetting('allow_profile_viewing', v);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final bgColor = iconColor ?? const Color(0xFF7C3AED);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: value ? bgColor : bgColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: value
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF7C3AED),
        inactiveThumbColor: Colors.white.withOpacity(0.3),
        inactiveTrackColor: Colors.white.withOpacity(0.08),
      ),
    );
  }
}
