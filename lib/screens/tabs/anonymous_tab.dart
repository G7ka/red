import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/matching_service.dart';
import '../../services/notification_service.dart';
import '../chat/anonymous_chat_screen.dart';
import '../notifications_screen.dart';

class AnonymousTab extends StatefulWidget {
  const AnonymousTab({super.key});

  @override
  State<AnonymousTab> createState() => _AnonymousTabState();
}

class _AnonymousTabState extends State<AnonymousTab>
    with TickerProviderStateMixin {
  bool _searching = false;
  String? _error;
  RangeValues _ageRange = const RangeValues(18, 30);
  bool _isCancelled = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('preferred_age_min, preferred_age_max')
          .eq('id', user.id)
          .maybeSingle();
      if (data != null && mounted) {
        final minAge = (data['preferred_age_min'] as int?)?.toDouble() ?? 18.0;
        final maxAge = (data['preferred_age_max'] as int?)?.toDouble() ?? 80.0;
        setState(() {
          _ageRange = RangeValues(minAge, maxAge);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startSearch() async {
    _isCancelled = false;
    setState(() {
      _searching = true;
      _error = null;
    });
    _pulseController.repeat(reverse: true);

    final chatId = await MatchingService.instance.startAnonymousSearch(
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
    );

    if (!mounted) return;

    _pulseController.stop();

    if (chatId == null) {
      if (_isCancelled) return;
      setState(() {
        _searching = false;
        _error = 'No match found yet. Try again in a moment.';
      });
      return;
    }

    setState(() => _searching = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnonymousChatScreen(chatId: chatId),
      ),
    );
  }

  Future<void> _stopSearch() async {
    _isCancelled = true;
    await MatchingService.instance.stopSearching();
    _pulseController.stop();
    if (mounted) {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            floating: false,
            centerTitle: false,
            titleSpacing: 24,
            backgroundColor: const Color(0xFF0A0A0F),
            elevation: 0,
            title: const Text(
              'Anonymous',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            actions: [
              _buildNotificationButton(),
              const SizedBox(width: 12),
            ],
          ),

          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  _searching ? _buildSearchingState() : _buildIdleState(),
                  const Spacer(flex: 1),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<int>(
      stream: NotificationService.instance.getUnreadCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Stack(
              children: [
                Icon(Icons.notifications_outlined,
                    color: Colors.white.withOpacity(0.7), size: 22),
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        // Penguin icon
        SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A104E).withOpacity(0.90), // Matches settings frosted style
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset('assets/images/usethis1.png', width: 60, height: 60, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Find Your Penguin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect anonymously with someone new',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),

        // Error message
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF7C3AED), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Start button — solid purple, no glow
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _startSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start Searching',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchingState() {
    return Column(
      children: [
        // Clean pulsing concentric circles with penguin icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse = _pulseController.value;
            return SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 200 * (0.85 + pulse * 0.15),
                    height: 200 * (0.85 + pulse * 0.15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7C3AED)
                            .withOpacity(0.08 + pulse * 0.07),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Middle ring
                  Container(
                    width: 150 * (0.9 + pulse * 0.1),
                    height: 150 * (0.9 + pulse * 0.1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7C3AED)
                            .withOpacity(0.12 + pulse * 0.08),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Center circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: ClipOval(
                        child: Image.asset('assets/images/usethis1.png', width: 60, height: 60, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Searching for penguins...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hang tight, finding your match',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _stopSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cancel Search',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
