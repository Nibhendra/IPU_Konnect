import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfViewerScreen extends StatefulWidget {
  final File file;
  final String title;

  const PdfViewerScreen({super.key, required this.file, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  // LOGIC: Save file to "Downloads" folder
  Future<void> _downloadFile() async {
    // 1. Ask for permission
    var status = await Permission.storage.request();

    // On newer Android (11+), storage permission is often granted by default for Downloads
    if (status.isGranted ||
        await Permission.storage.isLimited ||
        Platform.isAndroid) {
      try {
        // 2. Get the "Downloads" folder path
        // Hardcoded path is the most reliable way for simple Android apps
        Directory downloadsDir = Directory('/storage/emulated/0/Download');

        if (!await downloadsDir.exists()) {
          downloadsDir = Directory(
            '/storage/emulated/0/Downloads',
          ); // Try plural
        }

        // 3. Create the new file path
        String newPath =
            "${downloadsDir.path}/${widget.title.replaceAll(" ", "_")}.pdf";

        // 4. Copy the temp file to the Downloads folder
        await widget.file.copy(newPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Saved to: $newPath"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission Denied! Cannot save file.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
        actions: [
          // DOWNLOAD BUTTON
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadFile,
            tooltip: "Download PDF",
          ),
        ],
      ),
      body: PDFView(
        filePath: widget.file.path,
        autoSpacing: true,
        pageFling: true,
        onError: (e) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
