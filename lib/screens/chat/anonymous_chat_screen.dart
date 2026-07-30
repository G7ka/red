import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/chat_service.dart';
import '../../services/friend_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/full_screen_media_viewer.dart';
import '../../widgets/thanos_snap_widget.dart';

class AnonymousChatScreen extends StatefulWidget {
  final String chatId;

  const AnonymousChatScreen({super.key, required this.chatId});

  @override
  State<AnonymousChatScreen> createState() => _AnonymousChatScreenState();
}

class _AnonymousChatScreenState extends State<AnonymousChatScreen> {
  final _supabase = Supabase.instance.client;
  final _textController = TextEditingController();
  final _chatService = ChatService.instance;
  final _snapKey = GlobalKey<ThanosSnapWidgetState>();
  final _imagePicker = ImagePicker();
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  bool _sending = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  bool _hasText = false;
  int _messageCount = 0;
  String? _otherUid;
  String? _otherName;

  // Mutual Add System
  bool _hasReachedThreshold = false;
  bool? _myAddRequest;
  bool? _otherAddRequest;
  bool _isFriendChat = false;

  // Listeners
  StreamSubscription? _chatSubscription;
  bool _isExiting = false;

  // Audio playback
  String? _playingUrl;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    NotificationService.instance.markChatNotificationsAsRead(widget.chatId);
    _loadChatInfo();
    _checkMessageCount();
    _setupChatListener();
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _chatSubscription?.cancel();
    _recordTimer?.cancel();
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _setupChatListener() {
    _chatSubscription =
        _chatService.getChatStream(widget.chatId).listen((chat) {
      if (!mounted || _isExiting) return;
      if (chat.isEmpty) return;

      final isActive = chat['is_anonymous_active'] as bool? ?? true;
      final type = chat['type'] as String? ?? 'anonymous';

      if (type == 'friend') {
        setState(() {
          _isFriendChat = true;
          _hasReachedThreshold = true;
        });
      }

      if (!isActive && type == 'anonymous') {
        _isExiting = true;
        _snapKey.currentState?.snap();
      }

      final addRequests =
          Map<String, dynamic>.from(chat['add_requests'] ?? {});
      final myId = _supabase.auth.currentUser?.id;
      if (myId != null) {
        setState(() {
          _myAddRequest = addRequests[myId] as bool?;
          if (_otherUid != null) {
            _otherAddRequest = addRequests[_otherUid!] as bool?;
          }
        });

        if (_myAddRequest == true &&
            _otherAddRequest == true &&
            !_isFriendChat) {
          _chatService.convertToFriendChat(widget.chatId);
          _chatService.sendSystemMessage(widget.chatId,
              '🎉 You are now friends! Real profiles are visible.');
        }
      }
    });
  }

  Future<void> _loadChatInfo() async {
    try {
      final chatData = await _supabase
          .from('chats')
          .select('participants, type')
          .eq('id', widget.chatId)
          .single();

      final participants = List<String>.from(chatData['participants'] ?? []);
      final currentUid = _supabase.auth.currentUser?.id;
      _otherUid = participants.firstWhere((id) => id != currentUid,
          orElse: () => '');
      _isFriendChat = chatData['type'] == 'friend';

      if (_otherUid != null && _otherUid!.isNotEmpty) {
        final userRes = await _supabase
            .from('users')
            .select('first_name, display_name')
            .eq('id', _otherUid!)
            .single();
        _otherName = _isFriendChat
            ? (userRes['display_name'] as String? ?? 'Someone')
            : (userRes['first_name'] as String? ?? 'Anonymous Penguin');
      }

      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading chat info: $e');
    }
  }

  Future<void> _checkMessageCount() async {
    final count = await _chatService.getMessageCount(widget.chatId);
    if (mounted) {
      setState(() {
        _messageCount = count;
        _hasReachedThreshold = count >= 10 || _isFriendChat;
      });
    }
  }

  // ============ SEND TEXT ============

  Future<void> _sendMessage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    if (_otherUid == null || _otherUid!.isEmpty) await _loadChatInfo();
    if (_otherUid == null || _otherUid!.isEmpty) {
      if (mounted) setState(() => _sending = false);
      return;
    }

    try {
      await _chatService.sendTextMessage(
        chatId: widget.chatId,
        toUid: _otherUid!,
        text: text,
        isAnonymous: !_isFriendChat,
      );
      _textController.clear();
      if (mounted) _checkMessageCount();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ============ SEND IMAGE ============

  Future<void> _pickAndSendImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (_otherUid == null || _otherUid!.isEmpty) await _loadChatInfo();
    if (_otherUid == null || _otherUid!.isEmpty) return;

    setState(() => _sending = true);
    try {
      await _chatService.sendImageMessage(
        chatId: widget.chatId,
        toUid: _otherUid!,
        imageFile: File(picked.path),
        isAnonymous: !_isFriendChat,
      );
      if (mounted) _checkMessageCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send image: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _takeAndSendPhoto() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    if (_otherUid == null || _otherUid!.isEmpty) await _loadChatInfo();
    if (_otherUid == null || _otherUid!.isEmpty) return;

    setState(() => _sending = true);
    try {
      await _chatService.sendImageMessage(
        chatId: widget.chatId,
        toUid: _otherUid!,
        imageFile: File(picked.path),
        isAnonymous: !_isFriendChat,
      );
      if (mounted) _checkMessageCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ============ VOICE RECORDING ============

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
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
      setState(() => _recordSeconds++);
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
          const SnackBar(content: Text('Hold longer to record')),
        );
      }
      return;
    }

    if (_otherUid == null || _otherUid!.isEmpty) await _loadChatInfo();
    if (_otherUid == null || _otherUid!.isEmpty) return;

    setState(() => _sending = true);
    try {
      await _chatService.sendVoiceMessage(
        chatId: widget.chatId,
        toUid: _otherUid!,
        audioFile: File(path),
        isAnonymous: !_isFriendChat,
      );
      if (mounted) _checkMessageCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice: $e')),
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

  // ============ AUDIO PLAYBACK ============

  Future<void> _playAudio(String url) async {
    try {
      if (_playingUrl == url) {
        await _audioPlayer.stop();
        setState(() => _playingUrl = null);
        return;
      }
      setState(() => _playingUrl = url);
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _playingUrl = null);
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play audio')),
      );
      setState(() => _playingUrl = null);
    }
  }

  // ============ EXIT ============

  Future<void> _exitChat() async {
    if (_hasReachedThreshold) {
      if (mounted) Navigator.of(context).pop();
    } else {
      await _chatService.exitAnonymousChat(widget.chatId);
      await _chatService.sendSystemMessage(
          widget.chatId, 'User left the chat.');
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _respondToAddRequest(bool accepted) {
    _chatService.updateAddRequest(widget.chatId, accepted);
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    return ThanosSnapWidget(
      key: _snapKey,
      onSnapComplete: () {
        if (mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0F),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.white.withOpacity(0.06)),
          ),
          automaticallyImplyLeading: false,
          leadingWidth: 70,
          leading: InkWell(
            onTap: () {
              if (_hasReachedThreshold) {
                Navigator.of(context).pop();
              } else {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Leave Chat?',
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                        'Leaving before 10 messages will end this session.',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.grey)),
                          onPressed: () => Navigator.of(ctx).pop()),
                      TextButton(
                        child: const Text('Leave',
                            style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _exitChat();
                        },
                      ),
                    ],
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(width: 4),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isFriendChat
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF1A1A2E),
                    border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.5)),
                  ),
                  child: Icon(
                      _isFriendChat ? Icons.person : Icons.pets,
                      color: Colors.white,
                      size: 18),
                ),
              ],
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_otherName ?? 'Anonymous Penguin',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              if (_isFriendChat)
                const Text('Friend',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
            ],
          ),
        ),
        body: Column(
          children: [
            if (!_isFriendChat) _buildCounterBar(),

            // Messages
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getMessagesStream(widget.chatId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED)));
                  }
                  final messages = snapshot.data!;

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🐧', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('Say hello to your penguin!',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 15)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _buildMutualAddPrompt();
                      }
                      return _buildMessageBubble(messages[index]);
                    },
                  );
                },
              ),
            ),

            // Recording indicator
            if (_isRecording) _buildRecordingBar(),

            // Input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data) {
    final isMe = data['sender_id'] == _supabase.auth.currentUser?.id;
    final isSystem =
        data['type'] == 'system' || data['sender_id'] == 'system';
    final text = data['text'] as String? ?? '';
    final messageType = data['type'] as String? ?? 'text';
    final mediaUrl = data['media_url'] as String?;
    final createdStr = data['created_at'] as String?;
    String timeText = '';
    if (createdStr != null) {
      final dt = DateTime.tryParse(createdStr)?.toLocal();
      if (dt != null) {
        timeText =
            '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
      }
    }

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: messageType == 'image' ? const EdgeInsets.all(2) : const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF7C3AED) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight:
                  isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: messageType == 'image' ? EdgeInsets.zero : const EdgeInsets.fromLTRB(8, 6, 8, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (messageType == 'image' && mediaUrl != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => FullScreenMediaViewer(imageUrl: mediaUrl)
                          ));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(mediaUrl,
                              loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 150,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF7C3AED))),
                            );
                          }),
                        ),
                      )
                    else if (messageType == 'audio' && mediaUrl != null)
                      _buildVoiceBubble(mediaUrl, isMe)
                    else
                      Text(text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
              Positioned(
                bottom: messageType == 'image' ? 6 : 4,
                right: messageType == 'image' ? 8 : 10,
                child: Container(
                  padding: messageType == 'image' ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : null,
                  decoration: messageType == 'image' ? BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(10),
                  ) : null,
                  child: Text(timeText,
                      style: TextStyle(
                          color: messageType == 'image' ? Colors.white : Colors.white.withOpacity(0.45), fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceBubble(String url, bool isMe) {
    final isPlaying = _playingUrl == url;
    // Generate deterministic waveform bars from the URL hash
    final rng = Random(url.hashCode);
    final bars = List.generate(24, (_) => 0.2 + rng.nextDouble() * 0.8);

    return GestureDetector(
      onTap: () => _playAudio(url),
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
          // Waveform bars
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
    );
  }

  Widget _buildRecordingBar() {
    return Container(
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
            style: const TextStyle(
                color: Colors.white, fontFamily: 'monospace', fontSize: 16),
          ),
          const SizedBox(width: 16),
          const Spacer(),
          // Cancel button
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _stopAndSendRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.3)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: _pickAndSendImage,
                    icon: Icon(Icons.attach_file,
                        color: Colors.white.withOpacity(0.4)),
                  ),
                  IconButton(
                    onPressed: _takeAndSendPhoto,
                    icon: Icon(Icons.camera_alt,
                        color: Colors.white.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send or Mic button
          _hasText
              ? GestureDetector(
                  onTap: _sending ? null : _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 22),
                  ),
                )
              : GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopAndSendRecording(),
                  onTap: () {
                    // Tap to start, tap again to send
                    if (_isRecording) {
                      _stopAndSendRecording();
                    } else {
                      _startRecording();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isRecording ? 56 : 48,
                    height: _isRecording ? 56 : 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.redAccent
                          : const Color(0xFF7C3AED),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: _isRecording ? 28 : 22,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCounterBar() {
    final progress = (_messageCount / 10.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.6),
        border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.04))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _hasReachedThreshold
                    ? '🎉 Threshold reached!'
                    : '💬 $_messageCount / 10 messages',
                style: TextStyle(
                  color: _hasReachedThreshold
                      ? const Color(0xFF7C3AED)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!_hasReachedThreshold)
                Text('10 to reveal',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualAddPrompt() {
    if (!_hasReachedThreshold || _isFriendChat) {
      return const SizedBox.shrink();
    }

    if (_myAddRequest == true) {
      if (_otherAddRequest == false) {
        return _systemBanner('The other penguin declined to reveal.',
            Icons.close, Colors.red);
      }
      return _systemBanner('Waiting for the other penguin to decide...',
          Icons.timer, const Color(0xFF7C3AED));
    }

    if (_myAddRequest == false) {
      return _systemBanner(
          'You declined to reveal.', Icons.close, Colors.red);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          const Text(
            "You've reached 10 messages!",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Add ${_otherName ?? 'this penguin'} and reveal profiles?',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => _respondToAddRequest(false),
                child: const Text('Decline',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _respondToAddRequest(true),
                child: const Text('Add to Chat List'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _systemBanner(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
