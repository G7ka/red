import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tabs/anonymous_tab.dart';
import '../tabs/chats_tab.dart';
import '../tabs/profile_tab.dart';
import '../../services/call_service.dart';
import '../../services/auth_service.dart';
import '../chat/incoming_call_screen.dart';
import '../auth/login_screen.dart';
import '../settings/matching_preferences_screen.dart';
import '../settings/blocked_contacts_screen.dart';
import '../settings/privacy_settings_screen.dart';
import '../settings/help_support_screen.dart';

final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _setupCallListener();
  }

  void _setupCallListener() {
    CallService.instance.listenForIncomingCalls().listen((callData) {
      if (mounted && callData.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => IncomingCallScreen(callData: callData),
          ),
        );
      }
    });
  }

  final _pages = const [
    AnonymousTab(),
    ChatsTab(),
    ProfileTab(),
  ];

  void switchTab(int index) {
    setState(() {
      _index = index;
    });
  }

  Future<void> _handleLogout() async {
    Navigator.of(context).pop(); // Close drawer
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    Navigator.of(context).pop(); // Close drawer
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'This action is permanent and cannot be undone. All your data, photos, and messages will be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Forever',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await AuthService.instance.deleteAccount();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }

  Widget _buildSettingsDrawer() {
    final user = Supabase.instance.client.auth.currentUser;
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: const Color(0xFF2A104E).withOpacity(0.90), // Very dark frosted purple
            child: SafeArea(
              child: Column(
                children: [
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/penguin_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Penguin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Colors.white.withOpacity(0.06), height: 1),
                    const SizedBox(height: 16),

                    // General Menu
                    _DrawerItem(
                      icon: Icons.tune,
                      label: 'Matching Preferences',
                      subtitle: 'Age, Gender, Location',
                      iconBgColor: const Color(0xFF7C3AED),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const MatchingPreferencesScreen(),
                          ),
                        );
                      },
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 8),
                      child: Text(
                        'PRIVACY & SECURITY',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                    _DrawerItem(
                      icon: Icons.block,
                      label: 'Blocked Contacts',
                      subtitle: 'Manage blocked users',
                      iconBgColor: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BlockedContactsScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.shield_outlined,
                      label: 'Privacy Settings',
                      subtitle: 'Online, Last Seen, Read Receipts',
                      iconBgColor: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacySettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      subtitle: 'FAQ, Contact Us',
                      iconBgColor: const Color(0xFF0EA5E9),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            const SizedBox(height: 8),

            // Logout
            _DrawerItem(
              icon: Icons.logout,
              label: 'Sign Out',
              iconBgColor: const Color(0xFF7C3AED),
              onTap: _handleLogout,
            ),

            // Delete Account
            _DrawerItem(
              icon: Icons.delete_forever_outlined,
              label: 'Delete Account',
              iconBgColor: Colors.red.withOpacity(0.7),
              onTap: _handleDeleteAccount,
            ),
            const SizedBox(height: 20),

            // Version
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: const Color(0xFF0A0A0F),
      drawer: _buildSettingsDrawer(),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withOpacity(0.65),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.bolt_outlined,
                    activeIcon: Icons.bolt,
                    label: 'Anonymous',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    label: 'Chats',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _index == index;
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? const Color(0xFF7C3AED)
                  : Colors.white.withOpacity(0.45),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF7C3AED)
                    : Colors.white.withOpacity(0.35),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconBgColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = iconBgColor ?? const Color(0xFF7C3AED);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
              ),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.white.withOpacity(0.03),
    );
  }
}
