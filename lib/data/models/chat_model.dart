class ChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;
  final Map<String, dynamic>? chat;

  ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.chat,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? '',
      title: json['title'] ?? 'New Chat',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updated_at'] ?? 0) * 1000,
      ),
      chat: json['chat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
      'chat': chat,
    };
  }
}

class Message {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? timestamp;

  Message({
    required this.role,
    required this.content,
    this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      if (timestamp != null) 'timestamp': timestamp!.millisecondsSinceEpoch ~/ 1000,
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
