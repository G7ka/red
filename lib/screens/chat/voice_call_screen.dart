import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/agora_config.dart';
import '../../services/call_service.dart';

class VoiceCallScreen extends StatefulWidget {
  final String chatId;
  final String channelId;
  final String otherUserId;
  final String otherUserName;
  // How many seconds were already used today when this call started.
  final int initialUsedSeconds;
  // How many seconds were remaining today when this call started.
  final int initialRemainingSeconds;

  const VoiceCallScreen({
    super.key,
    required this.chatId,
    required this.channelId,
    required this.otherUserId,
    required this.otherUserName,
    required this.initialUsedSeconds,
    required this.initialRemainingSeconds,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final _supabase = Supabase.instance.client;
  late final RtcEngine _engine;
  bool _joined = false;
  bool _muted = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _remoteJoined = false;
  String? _callMessageId;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await _createCallLogEntry();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _joined = true;
          });
          _startTimer();
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          _remoteJoined = true;
          _updateCallStatus('answered');
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.joinChannel(
      token: '',
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _createCallLogEntry() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final response = await _supabase.from('messages').insert({
      'chat_id': widget.chatId,
      'sender_id': user.id,
      'text': '',
      'type': 'call',
      'call_status': 'calling', // calling | answered | missed
      'call_duration_seconds': 0,
      'read_by': [],
    }).select().single();

    _callMessageId = response['id'] as String?;
  }

  Future<void> _updateCallStatus(String status) async {
    final id = _callMessageId;
    if (id == null) return;
    await _supabase.from('messages').update({
      'call_status': status,
    }).eq('id', id);
  }

  Future<void> _finalizeCallLog() async {
    final id = _callMessageId;
    if (id == null) return;

    final status = _remoteJoined ? 'answered' : 'missed';
    await _supabase.from('messages').update({
      'call_status': status,
      'call_duration_seconds': _elapsedSeconds,
    }).eq('id', id);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });

      // Auto-end the call when the daily remaining seconds are exhausted.
      if (_elapsedSeconds >= widget.initialRemainingSeconds &&
          widget.initialRemainingSeconds > 0) {
        _endCall(showLimitDialog: true);
      }
    });
  }

  Future<void> _endCall({bool showLimitDialog = false}) async {
    _timer?.cancel();
    await CallService.instance.addUsageSeconds(_elapsedSeconds);
    await CallService.instance.endCall(widget.channelId); // End signaling
    await _finalizeCallLog();
    if (!mounted) return;

    if (showLimitDialog) {
      await showDialog<void>(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Daily call limit reached'),
          content: Text(
            'You have reached your 15 minutes of voice calls for today. '
            'Your call has ended and your limit will reset in 24 hours.',
          ),
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;

    final totalUsedToday = widget.initialUsedSeconds + _elapsedSeconds;
    final usedMinutes = totalUsedToday ~/ 60;
    final usedSeconds = totalUsedToday % 60;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF7C3AED),
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _joined ? 'Connected' : 'Calling...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Today: ${usedMinutes.toString().padLeft(2, '0')}:${usedSeconds.toString().padLeft(2, '0')} / 15:00 used',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'mute',
                  backgroundColor: Colors.grey[800],
                  onPressed: () {
                    setState(() {
                      _muted = !_muted;
                    });
                    _engine.muteLocalAudioStream(_muted);
                  },
                  child: Icon(
                    _muted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 32),
                FloatingActionButton(
                  heroTag: 'end',
                  backgroundColor: Colors.red,
                  onPressed: () => _endCall(),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}


