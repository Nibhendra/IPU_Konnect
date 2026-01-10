import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static Db? db;
  static DbCollection? userCollection;
  static DbCollection? noticeCollection;
  static DbCollection? listingCollection;

  static String get mongoUrl => dotenv.env['MONGO_URL'] ?? "";

  static Future<void> connect() async {
    try {
      db ??= await Db.create(mongoUrl);

      if (db?.isConnected != true) {
        await db?.open();
        if (kDebugMode) print("✅ Connected/Reconnected to MongoDB Atlas!");
      }

      userCollection = db?.collection("users");
      noticeCollection = db?.collection("notices");
      listingCollection = db?.collection("listings");
    } catch (e) {
      if (kDebugMode) print("❌ Connection Error: $e");
    }
  }

  static Future<void> _ensureConnected() async {
    if (db == null || db?.isConnected != true) {
      if (kDebugMode) print("⚠️ Connection lost. Attempting reconnect...");
      await connect();
    }
  }

  static String objectIdToHexString(dynamic id) {
    if (id is ObjectId) {
      // ignore: deprecated_member_use
      return id.toHexString();
    }
    return id.toString(); // Fallback
  }

  static Future<bool> addListing(Map<String, dynamic> listingData) async {
    try {
      await _ensureConnected();

      listingData['createdAt'] = DateTime.now().toIso8601String();
      listingData['status'] = 'active';
      await listingCollection?.insertOne(listingData);
      return true;
    } catch (e) {
      if (kDebugMode) print("Add Listing Error: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllListings() async {
    try {
      await _ensureConnected();
      final list = await listingCollection
          ?.find(
            where.eq('status', 'active').sortBy('createdAt', descending: true),
          )
          .toList();
      return list ?? [];
    } catch (e) {
      if (kDebugMode) print("Get Listings Error: $e");
      return [];
    }
  }

  static Future<bool> deleteListing(dynamic id) async {
    try {
      await _ensureConnected();
      await listingCollection?.remove(where.id(id));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> markListingAsSold(dynamic id) async {
    try {
      await _ensureConnected();
      await listingCollection?.update(
        where.id(id),
        modify.set('status', 'sold'),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateListing(
    dynamic id,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _ensureConnected();
      final modifier = modify;
      updateData.forEach((key, value) {
        modifier.set(key, value);
      });
      await listingCollection?.update(where.id(id), modifier);
      return true;
    } catch (e) {
      if (kDebugMode) print("Update Listing Error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> createOrGetConversation(
    String user1,
    String user2,
    String listingTitle,
  ) async {
    try {
      await _ensureConnected();
      final conversations = db?.collection('conversations');
      final query = where
          .eq('participants', user1)
          .eq('participants', user2)
          .eq('listingTitle', listingTitle);

      var existing = await conversations?.findOne(query);
      if (existing != null) return existing;

      final doc = {
        'participants': [user1, user2],
        'listingTitle': listingTitle,
        'lastMessage': 'Chat started',
        'lastMessageTime': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'unreadCounts': {user1: 0, user2: 0}, // Initialize unread counts
      };
      await conversations?.insertOne(doc);
      return await conversations?.findOne(query);
    } catch (e) {
      if (kDebugMode) print("Create Chat Error: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserConversations(
    String email,
  ) async {
    try {
      await _ensureConnected();
      final conversations = db?.collection('conversations');
      final list = await conversations
          ?.find(
            where
                .eq('participants', email)
                .sortBy('lastMessageTime', descending: true),
          )
          .toList();
      return list ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId,
  ) async {
    try {
      await _ensureConnected();
      final messages = db?.collection('messages');

      final list = await messages
          ?.find(
            where
                .eq('conversationId', conversationId)
                .sortBy('timestamp', descending: false),
          )
          .toList();
      return list ?? [];
    } catch (e) {
      if (kDebugMode) print("Get Messages Error: $e");
      return [];
    }
  }

  static Future<bool> sendMessage(
    String conversationId,
    String sender,
    String content,
    String? imageUrl,
  ) async {
    try {
      await _ensureConnected();
      final messages = db?.collection('messages');
      final conversations = db?.collection('conversations');

      await messages?.insertOne({
        'conversationId': conversationId,
        'sender': sender,
        'content': content,
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Get the current conversation to find the other participant
      final conv = await conversations?.findOne(
        where.id(ObjectId.parse(conversationId)),
      );
      String? otherUser;
      if (conv != null) {
        final participants = conv['participants'] as List;
        otherUser = participants.firstWhere(
          (p) => p != sender,
          orElse: () => null,
        );
      }

      final updateModifier = modify
          .set('lastMessage', imageUrl != null ? '📷 Image' : content)
          .set('lastMessageTime', DateTime.now().toIso8601String());

      // Increment unread count for the receiver if found
      if (otherUser != null) {
        updateModifier.inc('unreadCounts.$otherUser', 1);
      }

      await conversations?.update(
        where.id(ObjectId.parse(conversationId)),
        updateModifier,
      );
      return true;
    } catch (e) {
      if (kDebugMode) print("Send Message Error: $e");
      return false;
    }
  }

  static Future<bool> markMessagesAsRead(
    String conversationId,
    String userEmail,
  ) async {
    try {
      await _ensureConnected();
      final conversations = db?.collection('conversations');
      await conversations?.update(
        where.id(ObjectId.parse(conversationId)),
        modify.set('unreadCounts.$userEmail', 0),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<int> getTotalUnreadCount(String email) async {
    try {
      await _ensureConnected();
      final conversations = db?.collection('conversations');
      final list = await conversations
          ?.find(where.eq('participants', email))
          .toList();

      int total = 0;
      if (list != null) {
        for (var chat in list) {
          if (chat['unreadCounts'] != null &&
              chat['unreadCounts'][email] != null) {
            total += (chat['unreadCounts'][email] as num).toInt();
          }
        }
      }
      return total;
    } catch (e) {
      if (kDebugMode) print("Get Unread Count Error: $e");
      return 0;
    }
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      await _ensureConnected();
      return await userCollection?.findOne(
        where.eq('email', email).eq('password', password),
      );
    } catch (e) {
      if (kDebugMode) print("Login Error: $e");
      return null;
    }
  }

  static Future<bool> register(
    String name,
    String email,
    String password,
    String college,
  ) async {
    try {
      await _ensureConnected();
      final existingUser = await userCollection?.findOne(
        where.eq('email', email),
      );
      if (existingUser != null) return false;

      await userCollection?.insertOne({
        "name": name,
        "email": email,
        "password": password,
        "college": college,
        "joined_date": DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) print("Register Error: $e");
      return false;
    }
  }

  static Future<bool> updateUserProfile(
    String email,
    String newName,
    String newCollege,
  ) async {
    try {
      await _ensureConnected();
      await userCollection?.update(
        where.eq('email', email),
        modify.set('name', newName).set('college', newCollege),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print("Update Profile Error: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getFilteredNotices(
    String college,
  ) async {
    try {
      await _ensureConnected();
      final query = where.oneFrom('source', ['University', college]);
      final list = await noticeCollection?.find(query).toList();
      return list?.reversed.toList() ?? [];
    } catch (e) {
      if (kDebugMode) print("Database Fetch Error: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllNotices() async {
    try {
      await _ensureConnected();
      final list = await noticeCollection?.find().toList();
      return list?.reversed.toList() ?? [];
    } catch (e) {
      if (kDebugMode) print("Database Fetch All Error: $e");
      return [];
    }
  }

  static Future<bool> uploadNoticeWithPdf(
    String title,
    String content,
    String source,
    String? pdfData,
  ) async {
    try {
      await _ensureConnected();
      await noticeCollection?.insertOne({
        "title": title,
        "content": content,
        "source": source,
        "date": DateTime.now().toIso8601String(),
        "pdf_data": pdfData,
      });
      return true;
    } catch (e) {
      if (kDebugMode) print("Upload Error: $e");
      return false;
    }
  }

  static Future<bool> deleteNotice(dynamic id) async {
    try {
      await _ensureConnected();
      await noticeCollection?.remove(where.id(id));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateNotice(
    dynamic id,
    String title,
    String content,
    String source,
  ) async {
    try {
      await _ensureConnected();
      await noticeCollection?.update(
        where.id(id),
        modify
            .set('title', title)
            .set('content', content)
            .set('source', source),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
