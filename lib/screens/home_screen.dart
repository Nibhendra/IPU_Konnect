import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../database/mongo_db_service.dart';
import '../dhundo/constants.dart'; // Import constants
import 'profile_screen.dart';
import 'pdf_viewer_screen.dart';
import 'admin/admin_dashboard.dart';
import '../dhundo/screens/dhundo_splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> notices = [];
  bool isLoading = true;
  String userCollege = "";
  String userName = "";
  String userEmail = "";

  // Removed local admin constant in favor of kAdminEmails from constants.dart

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? "Student";
      userCollege = prefs.getString('college') ?? "University";
      userEmail = prefs.getString('email') ?? "";
    });

    var data = await (kAdminEmails.contains(userEmail)
        ? MongoDatabase.getAllNotices()
        : MongoDatabase.getFilteredNotices(userCollege));

    if (mounted) {
      setState(() {
        notices = data;
        isLoading = false;
      });
    }
  }

  void _confirmDelete(dynamic id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Notice?"),
        content: Text("Are you sure you want to delete '$title'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              bool success = await MongoDatabase.deleteNotice(id);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notice Deleted")),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final titleEdit = TextEditingController(text: item['title']);
    final contentEdit = TextEditingController(text: item['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Notice"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleEdit,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: contentEdit,
              decoration: const InputDecoration(labelText: "Content"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              bool success = await MongoDatabase.updateNotice(
                item['_id'],
                titleEdit.text,
                contentEdit.text,
                item['source'],
              );
              if (mounted) {
                Navigator.pop(context);
                if (success) _loadData();
              }
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  String? _getLogoPath(String source) {
    final s = source.toLowerCase();
    if (s.contains('university') || s.contains('ggsipu')) {
      return 'assets/ipu_logo.png';
    } else if (s.contains('bpit')) {
      return 'assets/bpit_logo.png';
    } else if (s.contains('vips')) {
      return 'assets/vips_logo.png';
    }
    return null;
  }

  void _openPdfViewer(
    BuildContext context,
    String base64String,
    String? title,
  ) async {
    try {
      final bytes = base64Decode(base64String);
      final output = await getTemporaryDirectory();
      final safeFileName =
          "notice_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$safeFileName");
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PdfViewerScreen(file: file, title: title ?? "Document"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error opening PDF: $e")));
    }
  }

  void _showNoticeDetails(String title, String content, String source) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSourceBadge(source),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    bool isUni = source == 'University';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUni ? Colors.deepPurple.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUni ? Colors.deepPurple.shade100 : Colors.orange.shade100,
        ),
      ),
      child: Text(
        source,
        style: TextStyle(
          color: isUni ? Colors.deepPurple : Colors.orange.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dhundo_portal',
        backgroundColor: Colors.white,
        elevation: 5,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DhundoSplashScreen(userEmail: userEmail, userName: userName),
            ),
          );
        },
        icon: ClipOval(
          child: Image.asset(
            'assets/dhundo_icon.png',
            height: 32,
            width: 32,
            fit: BoxFit.cover,
            errorBuilder: (c, o, s) =>
                const Icon(Icons.search, color: Colors.orange),
          ),
        ),
        label: Text(
          "Open Dhundo",
          style: TextStyle(
            color: Colors.deepPurple[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $userName 👋",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userCollege,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "My Profile",
                  icon: const Icon(
                    Icons.account_circle,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ProfileScreen(
                          currentName: userName,
                          currentEmail: userEmail,
                          currentCollege: userCollege,
                        ),
                      ),
                    );
                    _loadData(); // Refresh data on return (in case name/college changed)
                  },
                ),
                if (kAdminEmails.contains(userEmail))
                  IconButton(
                    tooltip: "Admin Dashboard",
                    icon: const Icon(
                      Icons.dashboard_customize,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const AdminDashboardScreen(),
                        ),
                      );
                      _loadData();
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadData(),
                    child: notices.isEmpty
                        ? const Center(
                            child: Text("All caught up! No notices."),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: notices.length,
                            itemBuilder: (context, index) =>
                                _buildNoticeCard(notices[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> item) {
    String source = item['source'] ?? "General";
    String? logoPath = _getLogoPath(source);
    bool hasPdf =
        item['pdf_data'] != null && item['pdf_data'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showNoticeDetails(
            item['title'] ?? "Notice",
            item['content'] ?? "No details.",
            source,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                    image: logoPath != null
                        ? DecorationImage(
                            image: AssetImage(logoPath),
                            fit: BoxFit.contain,
                          )
                        : null,
                  ),
                  child: logoPath == null
                      ? Icon(
                          source == 'University'
                              ? Icons.account_balance
                              : Icons.school,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: _buildSourceBadge(source)),
                          Row(
                            children: [
                              if (hasPdf)
                                GestureDetector(
                                  onTap: () => _openPdfViewer(
                                    context,
                                    item['pdf_data'],
                                    item['title'],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          size: 12,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "PDF",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // --- ADMIN MENU ICON ---
                              if (kAdminEmails.contains(userEmail))
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showEditDialog(item);
                                    }
                                    if (val == 'delete') {
                                      _confirmDelete(
                                        item['_id'],
                                        item['title'] ?? "Notice",
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text("Edit"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['title'] ?? "Important Notice",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['content'] ?? "Tap to read more...",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
