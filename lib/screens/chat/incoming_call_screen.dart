import 'package:flutter/material.dart';
import '../../services/call_service.dart';
import '../../services/chat_service.dart'; // To maybe get user info if needed
import 'voice_call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final Map<String, dynamic> callData;

  const IncomingCallScreen({super.key, required this.callData});

  @override
  Widget build(BuildContext context) {
    final callerName = callData['caller_name'] ?? 'Unknown';
    final roomId = callData['id'];
    final callerId = callData['caller_id'];
    
    // Safety check
    if (roomId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
      return const Scaffold();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF7C3AED),
              child: Text(
                callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Incoming Voice Call...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reject Button
                FloatingActionButton.large(
                  heroTag: 'reject',
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    await CallService.instance.rejectCall(roomId);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
                const SizedBox(width: 48),
                // Accept Button
                FloatingActionButton.large(
                  heroTag: 'accept',
                  backgroundColor: Colors.green,
                  onPressed: () async {
                    await CallService.instance.acceptCall(roomId);
                    
                    // Fetch usage info before starting
                    final usage = await CallService.instance.getUsageInfo();
                    
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VoiceCallScreen(
                            chatId: 'call_$roomId', // Temp chat ID or fetch logic if needed
                            channelId: roomId,
                            otherUserId: callerId,
                            otherUserName: callerName,
                            initialUsedSeconds: usage['usedSeconds'] ?? 0,
                            initialRemainingSeconds: usage['remainingSeconds'] ?? 900,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.call, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
