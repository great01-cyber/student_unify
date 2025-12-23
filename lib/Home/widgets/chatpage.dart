import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:student_unify_app/Models/LendPage.dart';
import '../../Models/DonateModel.dart';
import '../../Models/messageModel.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverPhoto;
  final Donation? donation;
  final LendModel? lendModel;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhoto,
    this.donation,
    this.lendModel,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String currentUserId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isTyping = false;
  Timer? _typingTimer;
  StreamSubscription? _typingSubscription;
  bool _receiverIsTyping = false;
  bool _isOnline = false;

  // Helper getters to work with both models
  String get itemId => widget.donation?.id ?? widget.lendModel?.id ?? '';
  String get itemTitle => widget.donation?.title ?? widget.lendModel?.title ?? '';
  String get itemCategory => widget.donation?.category ?? widget.lendModel?.category ?? '';
  String get donorId => widget.donation?.donorId ?? widget.lendModel?.donorId ?? '';
  List<String> get itemImages => widget.donation?.imageUrls ?? widget.lendModel?.imageUrls ?? [];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      _setUserOnlineStatus(true);
      _listenToTypingStatus();
      _listenToOnlineStatus();
      _markMessagesAsRead();
    } else {
      currentUserId = "ANONYMOUS_USER";
      debugPrint("Auth Error: Current user is not logged in!");
    }

    _controller.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    // Cancel timers and subscriptions first
    _typingTimer?.cancel();
    _typingSubscription?.cancel();

    // Remove listeners
    _controller.removeListener(_onTypingChanged);

    // Update Firestore directly without calling setState
    _firestore
        .collection('chats')
        .doc(getChatId())
        .collection('typing')
        .doc(currentUserId)
        .set({
      'isTyping': false,
      'timestamp': FieldValue.serverTimestamp(),
    }).catchError((error) {
      debugPrint('Error updating typing status on dispose: $error');
    });

    // Update online status
    _setUserOnlineStatus(false);

    // Dispose controllers
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ==================== CHAT ID (ONE CHAT PER ITEM) ====================
  String getChatId() {
    // Include itemId to make chat unique per item
    final users = [currentUserId, widget.receiverId]..sort();
    return "${users[0]}-${users[1]}-$itemId";
  }

  // ==================== ONLINE STATUS ====================
  void _setUserOnlineStatus(bool isOnline) {
    _firestore
        .collection('users')
        .doc(currentUserId)
        .update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((error) {
      debugPrint('Error updating online status: $error');
    });
  }

  void _listenToOnlineStatus() {
    _firestore
        .collection('users')
        .doc(widget.receiverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _isOnline = snapshot.data()?['isOnline'] ?? false;
        });
      }
    });
  }

  // ==================== TYPING INDICATOR ====================
  void _onTypingChanged() {
    if (_controller.text.isNotEmpty && !_isTyping) {
      _setTypingStatus(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _setTypingStatus(false);
      }
    });
  }

  void _setTypingStatus(bool typing) {
    // Only update state if widget is still mounted
    if (mounted) {
      setState(() => _isTyping = typing);
    }

    _firestore
        .collection('chats')
        .doc(getChatId())
        .collection('typing')
        .doc(currentUserId)
        .set({
      'isTyping': typing,
      'timestamp': FieldValue.serverTimestamp(),
    }).catchError((error) {
      debugPrint('Error updating typing status: $error');
    });
  }

  void _listenToTypingStatus() {
    _typingSubscription = _firestore
        .collection('chats')
        .doc(getChatId())
        .collection('typing')
        .doc(widget.receiverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        final isTyping = data?['isTyping'] ?? false;
        final timestamp = data?['timestamp'] as Timestamp?;

        if (timestamp != null) {
          final timeDiff = DateTime.now().difference(timestamp.toDate()).inSeconds;
          setState(() {
            _receiverIsTyping = isTyping && timeDiff < 3;
          });
        }
      }
    });
  }

  // ==================== READ RECEIPTS ====================
  void _markMessagesAsRead() {
    _firestore
        .collection('chats')
        .doc(getChatId())
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isRead': true});
      }
    });
  }

  // ==================== SEND MESSAGE ====================
  void sendMessage({String? imageUrl}) async {
    final text = _controller.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    try {
      final messageData = {
        'text': text,
        'senderId': currentUserId,
        'receiverId': widget.receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': imageUrl != null ? 'image' : 'text',
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      await _firestore
          .collection('chats')
          .doc(getChatId())
          .collection('messages')
          .add(messageData);

      _controller.clear();
      _setTypingStatus(false);

      // Update chat metadata - includes itemId for one chat per item
      await _firestore.collection('chats').doc(getChatId()).set({
        'lastMessage': imageUrl != null ? '📷 Photo' : text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [currentUserId, widget.receiverId],
        'participantNames': {
          currentUserId: FirebaseAuth.instance.currentUser?.displayName ?? '',
          widget.receiverId: widget.receiverName,
        },
        'donorId': donorId,
        'itemId': itemId,  // Store itemId for unique chat per item
        'itemTitle': itemTitle,
        'itemImage': itemImages.isNotEmpty ? itemImages.first : null,
        'itemType': widget.donation != null ? 'donation' : 'lend',
        'unreadCount': {
          widget.receiverId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));

      _scrollToBottom();

    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ==================== QUICK REPLIES ====================
  void _sendQuickReply(String message) {
    _controller.text = message;
    sendMessage();
  }

  // ==================== UI BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildItemInfoCard(),
          _buildQuickReplies(),
          Expanded(child: _buildMessagesList()),
          if (_receiverIsTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.receiverPhoto.isNotEmpty
                    ? NetworkImage(widget.receiverPhoto)
                    : null,
                child: widget.receiverPhoto.isEmpty
                    ? Text(
                  widget.receiverName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                )
                    : null,
              ),
              if (_isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            _showChatInfo();
          },
        ),
      ],
    );
  }

  // ==================== ITEM INFO CARD (WORKS FOR BOTH) ====================
  Widget _buildItemInfoCard() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.donation != null
                ? Icons.volunteer_activism
                : Icons.handshake,
            color: Colors.deepPurple,
          ),
        ),
        title: Text(
          itemTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Category: $itemCategory',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: itemImages.isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            itemImages.first,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        )
            : null,
      ),
    );
  }

  // ==================== QUICK REPLIES ====================
  Widget _buildQuickReplies() {
    final quickReplies = [
      '👋 Hi there!',
      '✅ Yes, available',
      '📍 Where to meet?',
      '🕐 What time?',
      '👍 Sounds good',
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(
                quickReplies[index],
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.grey.shade100,
              onPressed: () => _sendQuickReply(quickReplies[index]),
            ),
          );
        },
      ),
    );
  }

  // ==================== MESSAGES LIST ====================
  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc(getChatId())
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final message = ChatMessage.fromFirestore(doc);
            final isMe = message.senderId == currentUserId;

            bool showDateSeparator = false;
            if (index == messages.length - 1) {
              showDateSeparator = true;
            } else {
              final nextMessage = ChatMessage.fromFirestore(messages[index + 1]);
              showDateSeparator = !_isSameDay(message.timestamp, nextMessage.timestamp);
            }

            return Column(
              children: [
                if (showDateSeparator) _buildDateSeparator(message.timestamp),
                _buildMessageBubble(message, isMe),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== DATE SEPARATOR ====================
  Widget _buildDateSeparator(DateTime date) {
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ==================== MESSAGE BUBBLE ====================
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade400],
                )
                    : null,
                color: isMe ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.image && message.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.imageUrl!,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue : Colors.grey.shade600,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  // ==================== TYPING INDICATOR ====================
  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: widget.receiverPhoto.isNotEmpty
                ? NetworkImage(widget.receiverPhoto)
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * (0.5 - (value - index * 0.2).abs())),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // ==================== MESSAGE INPUT ====================
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade700),
              onPressed: () {
                _showAttachmentOptions();
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.deepPurple.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ATTACHMENT OPTIONS ====================
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Send',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    Icons.camera_alt,
                    'Camera',
                    Colors.pink,
                        () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Camera feature coming soon!')),
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    Icons.photo_library,
                    'Gallery',
                    Colors.purple,
                        () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gallery feature coming soon!')),
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    Icons.location_on,
                    'Location',
                    Colors.green,
                        () {
                      Navigator.pop(context);
                      _sendQuickReply('📍 Share my location');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ==================== CHAT INFO ====================
  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: widget.receiverPhoto.isNotEmpty
                    ? NetworkImage(widget.receiverPhoto)
                    : null,
                child: widget.receiverPhoto.isEmpty
                    ? Text(
                  widget.receiverName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 32),
                )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.receiverName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}