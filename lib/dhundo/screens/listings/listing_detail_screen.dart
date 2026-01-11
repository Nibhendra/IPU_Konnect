import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/listing_item.dart';
import '../../../database/mongo_db_service.dart';
import '../../theme/app_theme.dart';
import 'add_listing_screen.dart';
import 'package:ipukonnect/dhundo/screens/full_screen_image_viewer.dart';
import '../chat/chat_screen.dart';
import '../../constants.dart';

class ListingDetailScreen extends StatelessWidget {
  final ListingItem listing;
  final String currentUserEmail;

  const ListingDetailScreen({
    super.key,
    required this.listing,
    required this.currentUserEmail,
  });

  void _deleteListing(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: const Text('Are you sure you want to remove this item?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await MongoDatabase.deleteListing(listing.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Listing deleted')));
        Navigator.pop(context); // Return to home
      }
    }
  }

  void _markAsSold(BuildContext context) async {
    await MongoDatabase.markListingAsSold(listing.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item marked as sold!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check permissions
    final isOwner = currentUserEmail == listing.sellerEmail;
    final isAdmin = kAdminEmails.contains(currentUserEmail);
    final hasDeletePermission = isOwner || isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: isAdmin
            ? Colors.red[800]
            : AppTheme.primaryPurple, // Theme Color
        foregroundColor: Colors.white,
        actions: [
          if (hasDeletePermission)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteListing(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: listing.imageUrl != null
                  ? _buildListingImage(listing.imageUrl!, context)
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
            ),

            // Details Container with rounded top
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '₹${listing.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryPurple, // Theme Color
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tags
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildTag('Category', listing.category),
                        _buildTag('Branch', listing.branch),
                        _buildTag('Semester', listing.semester),
                        _buildTag('Condition', listing.condition),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.description.isEmpty
                          ? 'No description provided'
                          : listing.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meetup Spot
                    const Text(
                      'Meetup Spot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.05),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryPurple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              listing.meetupSpot,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // === DYNAMIC ACTION SECTION ===
                    if (isOwner)
                      // VIEW FOR OWNER
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[800]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'This is your listing.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (listing.status == 'active')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 40,
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _markAsSold(context),
                                                icon: const Icon(
                                                  Icons.check_circle,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  'Mark Sold',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.green[600],
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: SizedBox(
                                              height: 40,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  // NAVIGATE TO EDIT SCREEN
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (ctx) =>
                                                          AddListingScreen(
                                                            currentUserEmail:
                                                                currentUserEmail,
                                                            listingToEdit:
                                                                listing,
                                                          ),
                                                    ),
                                                  ).then((_) {
                                                    Navigator.pop(context);
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue[600],
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // VIEW FOR BUYER (AND ADMIN who is not owner)
                      Column(
                        children: [
                          if (isAdmin)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Admin View: You can contact the seller.",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                // 1. Create/Get Conversation
                                final conversation =
                                    await MongoDatabase.createOrGetConversation(
                                      currentUserEmail,
                                      listing.sellerEmail,
                                      listing.title,
                                    );

                                if (conversation != null && context.mounted) {
                                  // 2. Navigate
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        conversationId:
                                            MongoDatabase.objectIdToHexString(
                                              conversation['_id'],
                                            ),
                                        currentUserId: currentUserEmail,
                                        otherUserName: listing.sellerEmail,
                                        listingTitle: listing.title,
                                      ),
                                    ),
                                  );
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not start chat. Try again.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAdmin ? 'Contact Seller' : 'Chat to Buy',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    // === END DYNAMIC SECTION ===
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryPurple,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingImage(String imageUrl, BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(imageUrl: imageUrl),
              ),
            );
          },
          child: Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      } catch (e) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    } else {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageViewer(imageUrl: imageUrl),
            ),
          );
        },
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    }
  }
}
