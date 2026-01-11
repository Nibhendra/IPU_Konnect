import 'package:flutter/material.dart';
import 'dart:convert';
import '../../dhundo/theme/app_theme.dart';
import '../admin_upload_screen.dart'; // Existing upload screen
import '../../dhundo/models/listing_item.dart';
import '../../database/mongo_db_service.dart';
import '../../dhundo/screens/listings/listing_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Campus Updates'),
            Tab(icon: Icon(Icons.storefront), text: 'Dhundo Ops'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Reuse existing Upload Screen logic
          // We wrap it to ensure it fits the tab view
          AdminUploadScreen(isEmbedded: true),

          // Tab 2: New Marketplace Ops
          DhundoManagementTab(),
        ],
      ),
    );
  }
}

class DhundoManagementTab extends StatefulWidget {
  const DhundoManagementTab({super.key});

  @override
  State<DhundoManagementTab> createState() => _DhundoManagementTabState();
}

class _DhundoManagementTabState extends State<DhundoManagementTab> {
  List<ListingItem> listings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  void _loadListings() async {
    setState(() => isLoading = true);
    final data = await MongoDatabase.getAllListings();
    if (mounted) {
      setState(() {
        listings = data.map((l) => ListingItem.fromMap(l)).toList();
        isLoading = false;
      });
    }
  }

  void _deleteListing(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Delete'),
        content: const Text('Remove this listing strictly?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await MongoDatabase.deleteListing(id);
      _loadListings(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing removed by Admin')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (listings.isEmpty) {
      return const Center(child: Text("No active listings found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final item = listings[index];
        return Card(
          elevation: 4,
          shadowColor: Colors.black12,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    // Simple reused logic for base64/url
                    child: item.imageUrl!.startsWith('data')
                        ? Image.memory(
                            base64Decode(item.imageUrl!.split(',').last),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            item.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.image),
                          ),
                  )
                : const Icon(Icons.image_not_supported),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Price: ₹${item.price.toStringAsFixed(0)} • Seller: ${item.sellerEmail}",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteListing(item.id),
            ),
            onTap: () {
              // Open Detail View in Admin Mode
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListingDetailScreen(
                    listing: item,
                    currentUserEmail: 'admin@dhundo.com',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
