import 'package:cloud_firestore/cloud_firestore.dart';
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.type = MessageType.text,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      type: MessageType.values.firstWhere(
            (e) => e.toString() == 'MessageType.${data['type'] ?? 'text'}',
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'type': type.toString().split('.').last,
    };
  }
}

enum MessageType { text, image, system }