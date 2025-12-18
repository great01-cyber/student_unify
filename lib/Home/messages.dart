import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:student_unify_app/Home/widgets/chatpage.dart';
import '../../Models/DonateModel.dart';
import '../../Models/LendPage.dart';
import '../services/AppUser.dart';


// ==================== CHAT PREVIEW MODEL ====================
class ChatPreview {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhoto;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String? itemTitle;
  final String? itemImage;
  final String donorId;
  final String itemId;
  final String? itemType;

  ChatPreview({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.itemTitle,
    this.itemImage,
    required this.donorId,
    required this.itemId,
    this.itemType,
  });
}

// ==================== MESSAGES PAGE ====================
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final String currentUserId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    currentUserId = user?.uid ?? '';
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(child: _buildChatsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewChatDialog();
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Messages',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showOptionsMenu();
          },
        ),
      ],
    );
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.deepPurple,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  // ==================== TAB BAR ====================
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.deepPurple,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.deepPurple,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.chat_bubble),
            text: 'All Chats',
          ),
          Tab(
            icon: Icon(Icons.mark_chat_unread),
            text: 'Unread',
          ),
        ],
      ),
    );
  }

  // ==================== CHATS LIST ====================
  Widget _buildChatsList() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildChatsStream(showUnreadOnly: false),
        _buildChatsStream(showUnreadOnly: true),
      ],
    );
  }

  Widget _buildChatsStream({required bool showUnreadOnly}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final chatDocs = snapshot.data!.docs;

        return FutureBuilder<List<ChatPreview>>(
          future: _buildChatPreviews(chatDocs, showUnreadOnly),
          builder: (context, previewSnapshot) {
            if (previewSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!previewSnapshot.hasData || previewSnapshot.data!.isEmpty) {
              return _buildEmptyState(
                showUnreadOnly ? 'No unread messages' : null,
              );
            }

            final chatPreviews = previewSnapshot.data!;

            // Filter by search query
            final filteredChats = _searchQuery.isEmpty
                ? chatPreviews
                : chatPreviews.where((chat) {
              return chat.otherUserName.toLowerCase().contains(_searchQuery) ||
                  chat.lastMessage.toLowerCase().contains(_searchQuery) ||
                  (chat.itemTitle?.toLowerCase().contains(_searchQuery) ?? false);
            }).toList();

            if (filteredChats.isEmpty) {
              return _buildEmptyState('No results found');
            }

            return ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                return _buildChatListItem(filteredChats[index]);
              },
            );
          },
        );
      },
    );
  }

  // ==================== BUILD CHAT PREVIEWS ====================
  Future<List<ChatPreview>> _buildChatPreviews(
      List<QueryDocumentSnapshot> chatDocs,
      bool showUnreadOnly,
      ) async {
    final List<ChatPreview> previews = [];

    for (var doc in chatDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      final otherUserId = participants.firstWhere(
            (id) => id != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) continue;

      final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[currentUserId] ?? 0;

      if (showUnreadOnly && unreadCount == 0) continue;

      // Get other user's info using AppUser model
      final userDoc = await _firestore.collection('users').doc(otherUserId).get();

      AppUser? otherUser;
      if (userDoc.exists) {
        try {
          otherUser = AppUser.fromMap(userDoc.data()!, uid: otherUserId);
        } catch (e) {
          debugPrint('Error parsing user data: $e');
        }
      }

      final participantNames = data['participantNames'] as Map<String, dynamic>?;

      final preview = ChatPreview(
        chatId: doc.id,
        otherUserId: otherUserId,
        otherUserName: participantNames?[otherUserId] ??
            otherUser?.displayName ??
            'Unknown User',
        otherUserPhoto: otherUser?.photoUrl ?? '',
        lastMessage: data['lastMessage'] ?? '',
        lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        unreadCount: unreadCount,
        isOnline: userDoc.data()?['isOnline'] ?? false,
        itemTitle: data['itemTitle'],
        itemImage: data['itemImage'],
        donorId: data['donorId'] ?? '',
        itemId: data['itemId'] ?? '',
        itemType: data['itemType'],
      );

      previews.add(preview);
    }

    return previews;
  }

  // ==================== CHAT LIST ITEM ====================
  Widget _buildChatListItem(ChatPreview chat) {
    return Dismissible(
      key: Key(chat.chatId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(chat);
      },
      child: InkWell(
        onTap: () async {
          // Mark messages as read when opening chat
          await _markChatAsRead(chat.chatId);

          // Get item info using itemId and itemType
          final item = await _getItemById(chat.itemId, chat.itemType);

          if (mounted) {
            if (item != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    receiverId: chat.otherUserId,
                    receiverName: chat.otherUserName,
                    receiverPhoto: chat.otherUserPhoto,
                    donation: item is Donation ? item : null,
                    lendModel: item is LendModel ? item : null,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item no longer available')),
              );
            }
          }
        },
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ITEM IMAGE as main profile picture with online indicator
              Stack(
                children: [
                  // Use item image instead of user photo
                  chat.itemImage != null && chat.itemImage!.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      chat.itemImage!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(
                          chat.itemType == 'lend'
                              ? Icons.handshake
                              : Icons.volunteer_activism,
                          size: 28,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  )
                      : CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(
                      chat.itemType == 'lend'
                          ? Icons.handshake
                          : Icons.volunteer_activism,
                      size: 28,
                      color: Colors.deepPurple,
                    ),
                  ),
                  // Online indicator for the OTHER USER
                  if (chat.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
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

              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Show ITEM TITLE as main title
                        Expanded(
                          child: Text(
                            chat.itemTitle ?? 'Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTimestamp(chat.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: chat.unreadCount > 0
                                ? Colors.deepPurple
                                : Colors.grey.shade600,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Show OTHER USER NAME as subtitle
                    Row(
                      children: [
                        // Small user avatar
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: chat.otherUserPhoto.isNotEmpty
                              ? NetworkImage(chat.otherUserPhoto)
                              : null,
                          child: chat.otherUserPhoto.isEmpty
                              ? Text(
                            chat.otherUserName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 8),
                          )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            chat.otherUserName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Last message
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: chat.unreadCount > 0
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState([String? message]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with donors!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(timestamp);
    } else {
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }

  Future<void> _markChatAsRead(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$currentUserId': 0,
    }).catchError((error) {
      debugPrint('Error marking chat as read: $error');
    });
  }

  // ==================== GET ITEM BY ID ====================
  Future<dynamic> _getItemById(String itemId, String? itemType) async {
    try {
      final collectionName = (itemType == 'lend') ? 'lendItems' : 'donations';

      final docSnapshot = await _firestore
          .collection(collectionName)
          .doc(itemId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;

        if (itemType == 'lend') {
          return LendModel.fromJson(data);
        } else {
          return Donation.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Error getting item by ID: $e');
    }
    return null;
  }

  Future<bool> _showDeleteConfirmation(ChatPreview chat) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete this conversation about "${chat.itemTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteChat(chat.chatId);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _deleteChat(String chatId, {bool showSnackbar = true}) async {
    try {
      // Delete messages subcollection
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete typing subcollection
      final typingSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .get();

      for (var doc in typingSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete chat document
      await _firestore.collection('chats').doc(chatId).delete();

      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting conversation: $e')),
        );
      }
    }
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Chat'),
        content: const Text(
          'To start a new conversation, browse donations and click "Message" on any item.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
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
              ListTile(
                leading: const Icon(Icons.mark_chat_read),
                title: const Text('Mark all as read'),
                onTap: () {
                  Navigator.pop(context);
                  _markAllChatsAsRead();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Clear all chats'),
                onTap: () {
                  Navigator.pop(context);
                  _showClearAllConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _markAllChatsAsRead() async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in chatsSnapshot.docs) {
        await doc.reference.update({
          'unreadCount.$currentUserId': 0,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All chats marked as read')),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Chats'),
        content: const Text(
          'Are you sure you want to delete all conversations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllChats();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllChats() async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in chatsSnapshot.docs) {
        await _deleteChat(doc.id, showSnackbar: false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All chats cleared')),
        );
      }
    } catch (e) {
      debugPrint('Error clearing all chats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}