import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _penguinController;
  late AnimationController _fadeController;

  late Animation<double> _penguinBounce;
  late Animation<double> _penguinScale;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _cardsFade;
  late Animation<Offset> _cardsSlide;
  late Animation<double> _buttonFade;
  late Animation<double> _buttonScale;

  int _currentStep = 0;

  final _steps = [
    _StepData(
      icon: Icons.pets,
      title: 'Anonymous Matching',
      description:
          'Get matched with someone anonymous. Chat, vibe, and if you click — reveal your real profiles after 10 messages!',
    ),
    _StepData(
      icon: Icons.chat_bubble_rounded,
      title: 'Real Conversations',
      description:
          'Send texts, photos, voice messages and even make calls. Express yourself freely!',
    ),
    _StepData(
      icon: Icons.people_rounded,
      title: 'Build Connections',
      description:
          'After 10 messages, decide together if you want to reveal your real profiles and become friends.',
    ),
    _StepData(
      icon: Icons.shield_rounded,
      title: 'Safe & Private',
      description:
          'Block anyone, control your privacy settings, and stay anonymous until you choose otherwise.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _penguinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _penguinBounce = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _penguinController, curve: Curves.elasticOut),
    );
    _penguinScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _penguinController, curve: Curves.elasticOut),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _cardsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    _penguinController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _penguinController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Penguin logo — clean, no glow
              AnimatedBuilder(
                animation: _penguinController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _penguinBounce.value),
                    child: Transform.scale(
                      scale: _penguinScale.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF7C3AED),
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset('assets/images/usethis1.png', width: 60, height: 60, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title — solid purple text, no shader mask
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: Column(
                    children: [
                      const Text(
                        'Welcome to Penguin!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C3AED),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your anonymous social playground',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Feature cards
              Expanded(
                child: SlideTransition(
                  position: _cardsSlide,
                  child: FadeTransition(
                    opacity: _cardsFade,
                    child: PageView.builder(
                      itemCount: _steps.length,
                      onPageChanged: (i) =>
                          setState(() => _currentStep = i),
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildFeatureCard(step),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Page indicator dots
              FadeTransition(
                opacity: _cardsFade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentStep == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentStep == i
                            ? const Color(0xFF7C3AED)
                            : Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Get started button — solid purple, no glow
              FadeTransition(
                opacity: _buttonFade,
                child: ScaleTransition(
                  scale: _buttonScale,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        "Let's Go!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
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
    );
  }

  Widget _buildFeatureCard(_StepData step) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(step.icon, color: const Color(0xFF7C3AED), size: 36),
          ),
          const SizedBox(height: 28),
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String description;

  _StepData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
