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

                return Dismissible(
                  key: Key(MongoDatabase.objectIdToHexString(chat['_id'])),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Chat?'),
                        content: const Text(
                          'This will permanently delete the conversation and its history.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    // Temporarily remove from list for instant feedback
                    final removedChat = chat;
                    setState(() {
                      conversations.removeAt(index);
                    });

                    bool success = await MongoDatabase.deleteConversation(
                      MongoDatabase.objectIdToHexString(chat['_id']),
                    );

                    if (!mounted) return;

                    if (!success) {
                      // Revert if failed
                      setState(() {
                        conversations.insert(index, removedChat);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to delete chat")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Chat deleted")),
                      );
                    }
                  },
                  child: Card(
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
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUser,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(chat['lastMessageTime']),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((chat['unreadCounts'] != null) &&
                              (chat['unreadCounts'][widget.currentUserEmail] ??
                                      0) >
                                  0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                (chat['unreadCounts'][widget
                                            .currentUserEmail] ??
                                        0)
                                    .toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Chat?'),
                                  content: const Text(
                                    'This will permanently delete the conversation.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ).then((confirmed) async {
                                if (confirmed == true) {
                                  final removedChat = chat;
                                  setState(() {
                                    conversations.removeAt(index);
                                  });

                                  bool success =
                                      await MongoDatabase.deleteConversation(
                                        MongoDatabase.objectIdToHexString(
                                          chat['_id'],
                                        ),
                                      );

                                  if (!mounted) return;

                                  if (!success) {
                                    setState(() {
                                      conversations.insert(index, removedChat);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Failed to delete chat"),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Chat deleted"),
                                      ),
                                    );
                                  }
                                }
                              });
                            },
                          ),
                        ],
                      ),
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
