import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../../database/mongo_db_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserEmail;

  const ChatListScreen({super.key, required this.currentUserEmail});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // Refresh every 5 seconds to check for new messages/unread counts
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _loadConversations(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadConversations({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    final data = await MongoDatabase.getUserConversations(
      widget.currentUserEmail,
    );
    if (mounted) {
      setState(() {
        conversations = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final chat = conversations[index];
                final otherUser = (chat['participants'] as List).firstWhere(
                  (p) => p != widget.currentUserEmail,
                  orElse: () => 'Unknown User',
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ChatScreen(
                            conversationId: MongoDatabase.objectIdToHexString(
                              chat['_id'],
                            ),
                            currentUserId: widget.currentUserEmail,
                            otherUserName: otherUser,
                            listingTitle: chat['listingTitle'] ?? 'Item',
                          ),
                        ),
                      );
                      _loadConversations(); // Refresh on return
                    },
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.secondaryPurple.withOpacity(
                        0.2,
                      ),
                      child: Text(
                        otherUser[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      otherUser,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat['listingTitle'] ?? 'Listing Inquiry',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          chat['lastMessage'] ?? '...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(chat['lastMessageTime']),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if ((chat['unreadCounts'] != null) &&
                            (chat['unreadCounts'][widget.currentUserEmail] ??
                                    0) >
                                0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              (chat['unreadCounts'][widget.currentUserEmail] ??
                                      0)
                                  .toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse listings and start chatting!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.parse(iso).toLocal();
    return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
