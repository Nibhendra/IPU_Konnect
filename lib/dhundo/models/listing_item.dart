class ListingItem {
  final dynamic id; // ObjectId from Mongo
  final String sellerEmail;
  final String title;
  final double price;
  final String category;
  final String branch;
  final String semester;
  final String condition;
  final String description;
  final String meetupSpot;
  final String? imageUrl;
  final String status; // 'active' or 'sold'
  final DateTime createdAt;
  final Map<String, dynamic>? seller;

  ListingItem({
    required this.id,
    required this.sellerEmail,
    required this.title,
    required this.price,
    required this.category,
    required this.branch,
    required this.semester,
    required this.condition,
    required this.description,
    required this.meetupSpot,
    this.imageUrl,
    this.status = 'active',
    required this.createdAt,
    this.seller,
  });

  factory ListingItem.fromMap(Map<String, dynamic> map) {
    return ListingItem(
      id: map['_id'], // MongoDB uses _id
      sellerEmail: map['seller_email'] as String? ?? '',
      title: map['title'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? '',
      branch: map['branch'] as String? ?? '',
      semester: map['semester'] as String? ?? '',
      condition: map['condition'] as String? ?? '',
      description: map['description'] as String? ?? '',
      meetupSpot: map['meetupSpot'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      seller: map['seller'] as Map<String, dynamic>?,
    );
  }
}
