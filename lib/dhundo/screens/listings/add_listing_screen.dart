import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../database/mongo_db_service.dart';
import '../../theme/app_theme.dart';
import '../../models/listing_item.dart';

class AddListingScreen extends StatefulWidget {
  final String currentUserEmail;
  final ListingItem? listingToEdit; // If not null, we are in EDIT mode

  const AddListingScreen({
    super.key,
    required this.currentUserEmail,
    this.listingToEdit,
  });

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final meetupSpotController = TextEditingController();

  String selectedCategory = 'Drawing Tools';
  String selectedBranch = 'CSE';
  String selectedSemester = 'Sem 1';
  String selectedCondition = 'Like New';
  bool isLoading = false;
  File? selectedImage;
  String? existingImageUrl;

  final categories = [
    'Drawing Tools',
    'Scales',
    'Stationery',
    'Tools',
    'Papers',
  ];
  final branches = ['CSE', 'IT', 'ECE', 'ME', 'EE'];
  final semesters = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
  final conditions = ['Like New', 'Good', 'Fair', 'Poor'];

  @override
  void initState() {
    super.initState();
    if (widget.listingToEdit != null) {
      _prefillData();
    }
  }

  void _prefillData() {
    final item = widget.listingToEdit!;
    titleController.text = item.title;
    priceController.text = item.price.toStringAsFixed(0);
    descriptionController.text = item.description;
    meetupSpotController.text = item.meetupSpot;
    if (categories.contains(item.category)) selectedCategory = item.category;
    if (branches.contains(item.branch)) selectedBranch = item.branch;
    if (semesters.contains(item.semester)) selectedSemester = item.semester;
    if (conditions.contains(item.condition)) selectedCondition = item.condition;
    existingImageUrl = item.imageUrl;
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    meetupSpotController.dispose();
    super.dispose();
  }

  void _submitListing() async {
    if (titleController.text.isEmpty ||
        priceController.text.isEmpty ||
        meetupSpotController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Convert image to Base64 string if selected
      String? imageBase64;
      if (selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        imageBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
      } else {
        // Keep existing image if not processing a new one
        imageBase64 = existingImageUrl;
      }

      final data = {
        'seller_email': widget.currentUserEmail,
        'title': titleController.text,
        'price': double.parse(priceController.text),
        'category': selectedCategory,
        'branch': selectedBranch,
        'semester': selectedSemester,
        'condition': selectedCondition,
        'description': descriptionController.text,
        'meetupSpot': meetupSpotController.text,
        'imageUrl': imageBase64,
      };

      bool success;
      if (widget.listingToEdit != null) {
        // UPDATE MODE
        success = await MongoDatabase.updateListing(
          widget.listingToEdit!.id,
          data,
        );
      } else {
        // CREATE MODE
        success = await MongoDatabase.addListing(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (widget.listingToEdit != null
                        ? 'Listing updated!'
                        : 'Listing posted!')
                  : 'Operation failed',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.listingToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Listing' : 'Add New Listing'),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: AppTheme.primaryPurple.withOpacity(0.05),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Details'),
            _buildTextField(
              'Item Title',
              titleController,
              'e.g., Engineering Graphics Tools',
            ),
            _buildTextField(
              'Price (₹)',
              priceController,
              'e.g., 500',
              inputType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Category',
                    selectedCategory,
                    categories,
                    (v) => setState(() => selectedCategory = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Branch',
                    selectedBranch,
                    branches,
                    (v) => setState(() => selectedBranch = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Semester',
                    selectedSemester,
                    semesters,
                    (v) => setState(() => selectedSemester = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    'Condition',
                    selectedCondition,
                    conditions,
                    (v) => setState(() => selectedCondition = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionHeader('Description'),
            _buildTextField(
              'Description',
              descriptionController,
              'Describe condition, brand, and usage...',
              maxLines: 4,
            ),

            _buildSectionHeader('Meetup'),
            _buildTextField(
              'Meetup Spot',
              meetupSpotController,
              'e.g., Canteen, Library',
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? 'Update Listing' : 'Post Listing',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(selectedImage!, fit: BoxFit.cover),
      );
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      if (existingImageUrl!.startsWith('data:')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            base64Decode(existingImageUrl!.split(',').last),
            fit: BoxFit.cover,
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(existingImageUrl!, fit: BoxFit.cover),
        );
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          size: 50,
          color: AppTheme.primaryPurple.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Add Item Photo',
          style: TextStyle(
            color: AppTheme.primaryPurple.withOpacity(0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
