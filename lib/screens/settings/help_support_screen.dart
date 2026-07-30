import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Help & Support',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ section
          _buildSectionHeader('Frequently Asked Questions'),
          const SizedBox(height: 8),
          _buildFAQ(
            'How does anonymous matching work?',
            'When you tap "Start Searching", we match you with another user based on your preferences (gender and age range). '
                'The chat is fully anonymous until both users choose to reveal their profiles.',
          ),
          _buildFAQ(
            'How do voice calls work?',
            'You get 15 minutes of free voice calls per day. To start a call, open a friend chat and tap the phone icon. '
                'The other person will receive a notification.',
          ),
          _buildFAQ(
            'What is Incognito Mode?',
            'Incognito Mode hides your online status from other users. They won\'t see the green dot next to your name, '
                'and your "last seen" time will be hidden.',
          ),
          _buildFAQ(
            'How do I block someone?',
            'Open the chat with the person, tap the three dots menu, and select "Block User". '
                'You can manage blocked contacts from Settings > Blocked Contacts.',
          ),
          _buildFAQ(
            'Can I delete my account?',
            'Yes, go to Settings > Delete Account. This action is permanent and will remove all your data, photos, '
                'and messages.',
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Contact Us'),
          const SizedBox(height: 8),
          _buildContactTile(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@penguinapp.com',
            iconColor: const Color(0xFF0EA5E9),
            onTap: () => launchUrl(Uri.parse('mailto:support@penguinapp.com')),
          ),
          _buildContactTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Let us know about any issues',
            iconColor: const Color(0xFFEF4444),
            onTap: () => launchUrl(Uri.parse('mailto:support@penguinapp.com?subject=Bug Report')),
          ),
          _buildContactTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Help us improve Penguin',
            iconColor: const Color(0xFF10B981),
            onTap: () => launchUrl(Uri.parse('mailto:support@penguinapp.com?subject=Feedback')),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Penguin v1.0.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
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

  Widget _buildFAQ(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        iconColor: const Color(0xFF7C3AED),
        collapsedIconColor: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final bgColor = iconColor ?? const Color(0xFF7C3AED);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 12)),
        trailing: Icon(Icons.chevron_right,
            color: Colors.white.withOpacity(0.2), size: 20),
      ),
      ),
    );
  }
}
