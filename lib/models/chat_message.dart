class ChatMessage {
  final String id;
  final String role; // 'user' or 'model'
  final String text;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.metadata,
  });

  bool get isUser => role == 'user';
  bool get isModel => role == 'model';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      text: json['text']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'createdAt': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    DateTime parsedTime = DateTime.now();
    if (data['timestamp'] is num) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch((data['timestamp'] as num).toInt());
    } else if (data['createdAt'] != null) {
      parsedTime = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
    }

    return ChatMessage(
      id: data['id']?.toString() ?? '',
      role: data['role']?.toString() ?? 'model',
      text: data['text']?.toString() ?? '',
      timestamp: parsedTime,
      metadata: data['metadata'] is Map ? Map<String, dynamic>.from(data['metadata'] as Map) : null,
    );
  }
}
