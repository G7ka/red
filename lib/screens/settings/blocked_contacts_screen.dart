import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockedContactsScreen extends StatefulWidget {
  const BlockedContactsScreen({super.key});

  @override
  State<BlockedContactsScreen> createState() => _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends State<BlockedContactsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('blocked_users')
          .select('blocked_user_id, users!blocked_users_blocked_user_id_fkey(display_name, profile_images)')
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          _blockedUsers = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      // Table might not exist - show empty
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblockUser(String blockedUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('blocked_users')
          .delete()
          .eq('user_id', user.id)
          .eq('blocked_user_id', blockedUserId);

      setState(() {
        _blockedUsers.removeWhere(
            (u) => u['blocked_user_id'] == blockedUserId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unblocked'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unblocking user: $e')),
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
        title: const Text('Blocked Contacts',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : _blockedUsers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) {
                    final blocked = _blockedUsers[index];
                    final userData = blocked['users'] as Map<String, dynamic>?;
                    final name =
                        userData?['display_name'] as String? ?? 'Unknown User';
                    final images = List<String>.from(
                        userData?['profile_images'] ?? []);
                    final avatar =
                        images.isNotEmpty ? images.first : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF2A2A3E),
                          backgroundImage:
                              avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? const Icon(Icons.person,
                                  color: Colors.white30, size: 24)
                              : null,
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        trailing: TextButton(
                          onPressed: () => _unblockUser(
                              blocked['blocked_user_id'] as String),
                          child: const Text('Unblock',
                              style: TextStyle(color: Color(0xFF7C3AED))),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, color: Colors.white.withOpacity(0.15), size: 80),
          const SizedBox(height: 20),
          Text(
            'No blocked contacts',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Blocked users will appear here.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
