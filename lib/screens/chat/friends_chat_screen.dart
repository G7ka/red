import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/call_service.dart';
import '../../services/chat_service.dart';
import '../../services/friend_service.dart';
import '../../services/report_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/full_screen_media_viewer.dart';
import 'voice_call_screen.dart';

class FriendsChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const FriendsChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<FriendsChatScreen> createState() => _FriendsChatScreenState();
}

class _FriendsChatScreenState extends State<FriendsChatScreen> {
  final _supabase = Supabase.instance.client;
  final _textController = TextEditingController();
  final _chatService = ChatService.instance;
  final _imagePicker = ImagePicker();
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _sending = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  Timer? _typingTimer;
  bool _isOtherTyping = false;
  bool? _isOtherOnline;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes for mic/send button toggle
    _textController.addListener(_onTextControllerChanged);
    // Mark messages as seen when opening chat
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _chatService.markMessagesAsSeen(widget.chatId, userId);
      NotificationService.instance.markChatNotificationsAsRead(widget.chatId);
    }
    
    // Listen to typing indicator (Realtime Presence)
    _chatService.getTypingStream(widget.chatId).listen((data) {
      if (mounted) {
        setState(() {
          _isOtherTyping = data['is_typing'] as bool? ?? false;
        });
      }
    });
    
    // Listen to online status
    _chatService.getOnlineStatusStream(widget.otherUserId).listen((data) {
      if (mounted) {
        setState(() {
          _isOtherOnline = data['is_online'] as bool?;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextControllerChanged);
    _textController.dispose();
    _recordTimer?.cancel();
    _typingTimer?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    
    // Clean up typing channel and stop typing indicator
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _chatService.setTyping(widget.chatId, userId, false);
      _chatService.leaveTypingChannel(widget.chatId);
    }
    super.dispose();
  }

  void _onTextControllerChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }
  
  void _onTextChanged(String text) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    // Set typing to true
    _chatService.setTyping(widget.chatId, userId, true);
    
    // Cancel existing timer
    _typingTimer?.cancel();
    
    // Set typing to false after 3 seconds of no typing
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _chatService.setTyping(widget.chatId, userId, false);
    });
  }

  Future<void> _sendMessage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    // Stop typing indicator
    _typingTimer?.cancel();
    await _chatService.setTyping(widget.chatId, user.id, false);

    await _chatService.sendTextMessage(
      chatId: widget.chatId,
      toUid: widget.otherUserId,
      text: text,
      isAnonymous: false,
    );

    _textController.clear();
    if (mounted) {
      setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    await _chatService.sendImageMessage(
      chatId: widget.chatId,
      toUid: widget.otherUserId,
      imageFile: File(picked.path),
      isAnonymous: false,
    );
  }

  Future<void> _takeAndSendPhoto() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    await _chatService.sendImageMessage(
      chatId: widget.chatId,
      toUid: widget.otherUserId,
      imageFile: File(picked.path),
      isAnonymous: false,
    );
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required to send voice messages'),
        ),
      );
      return;
    }

    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: path,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordSeconds = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start recording: $e')),
      );
      return;
    }

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      setState(() {
        _recordSeconds++;
      });
      if (_recordSeconds >= 60) {
        await _stopAndSendRecording();
      }
    });
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording) return;
    final duration = _recordSeconds;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }
    _recordTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    if (path == null || duration < 1) {
      if (duration < 1 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hold longer to record a voice message')),
        );
      }
      return;
    }

    setState(() => _sending = true);
    try {
      await _chatService.sendVoiceMessage(
        chatId: widget.chatId,
        toUid: widget.otherUserId,
        audioFile: File(path),
        isAnonymous: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    await _recorder.stop();
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play audio message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;
    // Penguin Theme Colors — Clean Purple
    const bgColor = Color(0xFF0A0A0F);
    const appBarColor = Color(0xFF0A0A0F);
    const myBubbleColor = Color(0xFF7C3AED);
    const otherBubbleColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF7C3AED);
    const textColor = Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: appBarColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.06)),
        ),
        leadingWidth: 70,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back, color: Colors.white),
              const SizedBox(width: 4),
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                  border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.4)),
                ),
                child: const Icon(Icons.person, color: Color(0xFF7C3AED), size: 22),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isOtherOnline != null && _isOtherOnline!)
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _startVoiceCall,
            color: accentColor, // Use WhatsApp green for call
            tooltip: 'Voice call',
          ),
          // No Video Call Icon
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: appBarColor,
            onSelected: (value) {
              if (value == 'block') {
                _showBlockUserDialog();
              } else if (value == 'report') {
                _showReportUserDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('View Contact', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text('Block', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        // WhatsApp Doodle Background Pattern (Optional opacity overlay if asset exists, generic for now)
        decoration: const BoxDecoration(
          color: bgColor, 
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getMessagesStream(widget.chatId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: accentColor));
                  }
                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                           color: appBarColor,
                           borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Messages are end-to-end encrypted.',
                          style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index];
                      final senderId = data['sender_id'] as String?;
                      final isMe = senderId == currentUserId;
                      // ... (Data extraction same as before)
                      final text = data['text'] as String? ?? '';
                      final messageType = data['type'] as String? ?? 'text';
                      final mediaUrl = data['media_url'] as String?;
                      final readBy = List<String>.from(data['read_by'] ?? []);
                      final isSeen = readBy.contains(widget.otherUserId);
                      final callStatus = data['call_status'] as String?;
                      final callDurationSeconds = (data['call_duration_seconds'] as int?) ?? 0;
                      final createdAtStr = data['created_at'] as String?;

                      // Timestamp format
                      String timeText = '';
                      if (createdAtStr != null) {
                        final dt = DateTime.tryParse(createdAtStr)?.toLocal(); // Local time
                        if (dt != null) {
                           timeText = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
                        }
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: messageType == 'image' ? const EdgeInsets.all(2) : const EdgeInsets.all(4), // Tight padding for WhatsApp look
                            decoration: BoxDecoration(
                              color: isMe ? myBubbleColor : otherBubbleColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                              ),
                              boxShadow: const [],
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: messageType == 'image' ? EdgeInsets.zero : const EdgeInsets.fromLTRB(8, 6, 8, 20), // Bottom padding for time
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Content logic (Image/Voice/Text/Call)
                                      if (messageType == 'image' && mediaUrl != null)
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => FullScreenMediaViewer(imageUrl: mediaUrl)
                                            ));
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10), 
                                            child: Image.network(mediaUrl)
                                          ),
                                        )
                                      else if (messageType == 'audio' && mediaUrl != null)
                                        _VoiceMessageBubble(
                                          onPlay: () => _playAudio(mediaUrl),
                                          url: mediaUrl,
                                        )
                                      else if (messageType == 'text')
                                        Text(text, style: TextStyle(color: textColor, fontSize: 15))
                                      else if (messageType == 'call')
                                        Row(children: [
                                          Icon(Icons.call, color: Colors.white70, size: 16), 
                                          SizedBox(width: 8), 
                                          Text(callStatus == 'missed' ? 'Missed call' : 'Voice call', style: TextStyle(color: textColor))
                                        ]),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: messageType == 'image' ? 6 : 4,
                                  right: messageType == 'image' ? 6 : 6,
                                  child: Container(
                                    padding: messageType == 'image' ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : null,
                                    decoration: messageType == 'image' ? BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(10),
                                    ) : null,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeText,
                                          style: TextStyle(color: messageType == 'image' ? Colors.white : Colors.white60, fontSize: 11),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.done_all, // Double check
                                            size: 16,
                                            color: messageType == 'image' ? (isSeen ? const Color(0xFF53BDEB) : Colors.white) : (isSeen ? const Color(0xFF53BDEB) : Colors.white60),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Recording indicator bar
            if (_isRecording)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                    const SizedBox(width: 10),
                    Text(
                      '${(_recordSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16),
                    ),
                    const SizedBox(width: 16),
                    const Spacer(),
                    // Cancel button (Trash icon)
                    GestureDetector(
                      onTap: _cancelRecording,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            // Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: bgColor,
              child: Row(
                children: [
                   Expanded(
                     child: Container(
                       decoration: BoxDecoration(
                         color: const Color(0xFF1A1A2E),
                         borderRadius: BorderRadius.circular(28),
                         border: Border.all(color: Colors.white.withOpacity(0.06)),
                       ),
                       child: Row(
                         children: [
                           Expanded(
                             child: TextField(
                               controller: _textController,
                               onChanged: _onTextChanged,
                               style: const TextStyle(color: Colors.white),
                               decoration: const InputDecoration(
                                 hintText: 'Message',
                                 hintStyle: TextStyle(color: Colors.grey),
                                 border: InputBorder.none,
                                 contentPadding: EdgeInsets.symmetric(horizontal: 16),
                               ),
                             ),
                           ),
                           IconButton(onPressed: _pickAndSendImage, icon: const Icon(Icons.attach_file, color: Colors.grey)),
                           IconButton(onPressed: _takeAndSendPhoto, icon: const Icon(Icons.camera_alt, color: Colors.grey)),
                         ],
                       ),
                     ),
                   ),
                   const SizedBox(width: 8),
                   // Send/Mic Button
                   _hasText
                     ? CircleAvatar(
                         radius: 24,
                         backgroundColor: accentColor,
                         child: IconButton(
                           onPressed: _sendMessage,
                           icon: const Icon(Icons.send, color: Colors.white),
                         ),
                       )
                     : GestureDetector(
                         onLongPressStart: (_) => _startRecording(),
                         onLongPressEnd: (_) => _stopAndSendRecording(),
                         child: AnimatedContainer(
                           duration: const Duration(milliseconds: 200),
                           width: _isRecording ? 64 : 48,
                           height: _isRecording ? 64 : 48,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: _isRecording ? Colors.redAccent : accentColor,
                             boxShadow: _isRecording ? [
                               const BoxShadow(
                                 color: Colors.redAccent,
                                 blurRadius: 8,
                               ),
                             ] : [],
                           ),
                           child: Icon(
                             Icons.mic,
                             color: Colors.white,
                             size: _isRecording ? 32 : 24,
                           ),
                         ),
                       ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBlockUserDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${widget.otherUserName}? '
          'You will no longer receive messages from them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FriendService.instance.blockUser(widget.otherUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.otherUserName} has been blocked'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showReportUserDialog() async {
    String? selectedReason;
    final reasons = [
      'Inappropriate content',
      'Harassment',
      'Spam',
      'Fake profile',
      'Other',
    ];

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you reporting this user?'),
              const SizedBox(height: 16),
              ...reasons.map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedReason = value;
                      });
                    },
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      await ReportService.instance.reportUser(
                        reportedUserId: widget.otherUserId,
                        reason: selectedReason!,
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User reported. Thank you for keeping Penguin safe!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startVoiceCall() async {
    final usage = await CallService.instance.getUsageInfo();
    final used = usage['usedSeconds'] ?? 0;
    final remaining = usage['remainingSeconds'] ?? 0;

    if (!mounted) return;

    if (remaining <= 0) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Daily call limit reached'),
            content: const Text(
              'You have used your 15 minutes of voice calls for today. '
              'Please wait 24 hours for your call time to reset.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final usedMinutes = used ~/ 60;
    final usedSeconds = used % 60;
    final remainingMinutes = remaining ~/ 60;
    final remainingSeconds = remaining % 60;

    // Inform user of their current daily usage before starting the call.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Voice call usage'),
          content: Text(
            'Today you have used '
            '${usedMinutes.toString().padLeft(2, '0')}:${usedSeconds.toString().padLeft(2, '0')} '
            'out of 15:00 minutes.\n\n'
            'Remaining for today: '
            '${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start call'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    
    if (!mounted) return;
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting call...')),
    );

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final callerRes = await _supabase.from('users').select('display_name').eq('id', user.id).single();
      final callerName = callerRes['display_name'] as String? ?? 'A friend';
      
      final roomId = await CallService.instance.startCall(widget.otherUserId, callerName);
      
      if (!mounted) return;
      if (roomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.otherUserName} is offline or unavailable.')),
        );
        return;
      }

      // Navigate to the voice call screen. Use roomId as the channelId so
      // both friends join the same Agora channel.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VoiceCallScreen(
            chatId: widget.chatId,
            channelId: roomId,
            otherUserId: widget.otherUserId,
            otherUserName: widget.otherUserName,
            initialUsedSeconds: used,
            initialRemainingSeconds: remaining,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting call: $e')),
        );
      }
    }
  }
}

class _VoiceMessageBubble extends StatelessWidget {
  final VoidCallback onPlay;
  final bool isPlaying;
  final String url;

  const _VoiceMessageBubble({
    required this.onPlay,
    this.isPlaying = false,
    this.url = '',
  });

  @override
  Widget build(BuildContext context) {
    // Generate deterministic waveform from URL hash
    final rng = Random(url.hashCode);
    final bars = List.generate(24, (_) => 0.2 + rng.nextDouble() * 0.8);

    return GestureDetector(
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: bars.map((h) {
                return Container(
                  width: 3,
                  height: 4 + h * 18,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

