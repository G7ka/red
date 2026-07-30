import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/fcm_service.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (for FCM push notifications only)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase (primary backend)
  await Supabase.initialize(
    url: 'https://yeydspjcnjvpxivgodmy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlleWRzcGpjbmp2cHhpdmdvZG15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMDUzOTUsImV4cCI6MjA4MjU4MTM5NX0.jCgC7HKOLWRO9QypMqaLVn73QQ5Dd_9bSVk4MOo9MNE',
  );

  await FCMService.instance.initialize();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Track online status
  _setupOnlineStatusTracking();

  runApp(const PenguinApp());
}

void _setupOnlineStatusTracking() {
  final supabase = Supabase.instance.client;
  final chatService = ChatService.instance;

  supabase.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    if (session != null) {
      chatService.updateOnlineStatus(true);
    } else {
      chatService.updateOnlineStatus(false);
    }
  });

  if (supabase.auth.currentUser != null) {
    chatService.updateOnlineStatus(true);
  }
}

class PenguinApp extends StatefulWidget {
  const PenguinApp({super.key});

  @override
  State<PenguinApp> createState() => _PenguinAppState();
}

class _PenguinAppState extends State<PenguinApp> with WidgetsBindingObserver {
  final _chatService = ChatService.instance;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (state == AppLifecycleState.resumed) {
      _chatService.updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _chatService.updateOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final session = _supabase.auth.currentSession;

    return MaterialApp(
      title: 'Penguin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
      ),
      home: session != null && AuthService.instance.isEmailVerified
          ? HomeScreen(key: homeScreenKey)
          : const WelcomeScreen(),
    );
  }
}
