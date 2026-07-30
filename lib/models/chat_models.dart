class Chat {
  final String id;
  final List<String> participants; // 2 uids
  final String type; // 'anonymous' or 'friends'
  final bool isAnonymousActive;

  Chat({
    required this.id,
    required this.participants,
    required this.type,
    required this.isAnonymousActive,
  });

  factory Chat.fromMap(String id, Map<String, dynamic> data) {
    return Chat(
      id: id,
      participants: (data['participants'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      type: data['type'] as String? ?? 'anonymous',
      isAnonymousActive: data['is_anonymous_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'type': type,
      'is_anonymous_active': isAnonymousActive,
    };
  }
}

class Message {
  final String id;
  final String fromUid;
  final String toUid;
  final String text;
  final bool isAnonymous;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.text,
    required this.isAnonymous,
    required this.createdAt,
  });
}




