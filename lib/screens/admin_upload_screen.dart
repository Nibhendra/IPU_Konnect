import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../database/mongo_db_service.dart';

class AdminUploadScreen extends StatefulWidget {
  final bool isEmbedded;
  const AdminUploadScreen({super.key, this.isEmbedded = false});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  String selectedSource = "University";
  String? pdfBase64;
  String? fileName;
  bool isUploading = false;

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      int sizeInBytes = await file.length();

      if (sizeInBytes > 10 * 1024 * 1024) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File too large! Max 10MB.")),
          );
        return;
      }

      List<int> bytes = await file.readAsBytes();
      setState(() {
        pdfBase64 = base64Encode(bytes);
        fileName = result.files.single.name;
      });
    }
  }

  void _upload() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title is required!")));
      return;
    }

    setState(() => isUploading = true);

    bool success = await MongoDatabase.uploadNoticeWithPdf(
      titleController.text,
      contentController.text,
      selectedSource,
      pdfBase64,
    );

    setState(() => isUploading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Notice Published Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      if (!widget.isEmbedded) Navigator.pop(context, true);
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Upload Failed."),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If embedded, return just the content, otherwise full Scaffold
    if (widget.isEmbedded) {
      return _buildContent();
    }
    return Scaffold(body: _buildContent());
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          if (!widget.isEmbedded) ...[
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Post New Notice",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Spacing for embedded view
            const SizedBox(height: 20),
          ],
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(25),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Notice Title"),
                    _buildTextField(
                      titleController,
                      "e.g. End Term Date Sheet",
                      Icons.title,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Description"),
                    _buildTextField(
                      contentController,
                      "e.g. All students must...",
                      Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("Source"),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSource,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF4A00E0),
                          ),
                          items: ['University', 'BPIT', 'VIPS', 'MAIT']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedSource = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    _buildLabel("Attachment"),
                    // FIXED: Removed DottedBorder to fix your error
                    GestureDetector(
                      onTap: _pickPdf,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        decoration: BoxDecoration(
                          // Using standard border instead of DottedBorder
                          border: Border.all(
                            color: const Color(0xFF4A00E0),
                            width: 1.5,
                          ),
                          color: const Color(
                            0xFF4A00E0,
                          ).withOpacity(0.05), // Fixed opacity deprecation
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              fileName != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload_outlined,
                              size: 40,
                              color: fileName != null
                                  ? Colors.green
                                  : const Color(0xFF4A00E0),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              fileName ?? "Tap to upload PDF",
                              style: TextStyle(
                                color: fileName != null
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: fileName != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isUploading ? null : _upload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A00E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: isUploading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "PUBLISH NOTICE",
                                style: TextStyle(
                                  fontSize: 16,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: maxLines == 1
              ? Icon(icon, color: const Color(0xFF4A00E0))
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }
}
