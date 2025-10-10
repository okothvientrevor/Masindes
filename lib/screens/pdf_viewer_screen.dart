import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';

class PDFViewerScreen extends StatefulWidget {
  final File pdfFile;
  final String fileName;
  final Uint8List pdfBytes;

  const PDFViewerScreen({
    super.key,
    required this.pdfFile,
    required this.fileName,
    required this.pdfBytes,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareFile,
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
          ),
          IconButton(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in External App',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'copy_path',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 8),
                    Text('Copy File Path'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'show_location',
                child: Row(
                  children: [
                    Icon(Icons.folder_open, size: 20),
                    SizedBox(width: 8),
                    Text('Show File Location'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'file_info',
                child: Row(
                  children: [
                    Icon(Icons.info, size: 20),
                    SizedBox(width: 8),
                    Text('File Information'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: Column(
          children: [
            // PDF Info Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border(bottom: BorderSide(color: Colors.red[200]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF Report Generated Successfully',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'File: ${widget.fileName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                          ),
                        ),
                        Text(
                          'Size: ${_formatFileSize(widget.pdfBytes.length)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // PDF Content Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      // PDF Viewer Placeholder
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                size: 80,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'PDF Report Ready',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your contributions report has been generated successfully.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _openExternally,
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Open in PDF Viewer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton.icon(
                                    onPressed: _shareFile,
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red[600],
                                      side: BorderSide(color: Colors.red[600]!),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareFile() async {
    try {
      // Copy file path to clipboard as a fallback sharing method
      await Clipboard.setData(ClipboardData(text: widget.pdfFile.path));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'File path copied to clipboard! You can share it manually.',
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: _openExternally,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _openExternally() async {
    try {
      String command;
      List<String> args;

      // Determine the platform and use appropriate command to open PDF
      if (Platform.isMacOS) {
        command = 'open';
        args = [widget.pdfFile.path];
      } else if (Platform.isWindows) {
        command = 'cmd';
        args = ['/c', 'start', '', widget.pdfFile.path];
      } else if (Platform.isLinux) {
        command = 'xdg-open';
        args = [widget.pdfFile.path];
      } else {
        // For mobile platforms, show file path and suggest using share
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF saved! Use the Share button to open it.'),
            backgroundColor: Colors.blue,
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: _shareFile,
            ),
          ),
        );
        return;
      }

      final result = await Process.run(command, args);
      if (result.exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF opened successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Fallback to showing share option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open PDF. Try sharing it instead.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: _shareFile,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error opening PDF. Try sharing it instead.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: _shareFile,
          ),
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_path':
        _copyFilePath();
        break;
      case 'show_location':
        _showFileLocation();
        break;
      case 'file_info':
        _showFileInfo();
        break;
    }
  }

  void _copyFilePath() async {
    await Clipboard.setData(ClipboardData(text: widget.pdfFile.path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File path copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showFileLocation() async {
    try {
      String command;
      List<String> args;

      // Determine the platform and use appropriate command to open folder
      if (Platform.isMacOS) {
        command = 'open';
        args = [widget.pdfFile.parent.path];
      } else if (Platform.isWindows) {
        command = 'explorer';
        args = [widget.pdfFile.parent.path];
      } else if (Platform.isLinux) {
        command = 'xdg-open';
        args = [widget.pdfFile.parent.path];
      } else {
        // For mobile platforms, just show the path
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File location: ${widget.pdfFile.parent.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final result = await Process.run(command, args);
      if (result.exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File location opened'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File location: ${widget.pdfFile.parent.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File location: ${widget.pdfFile.parent.path}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showFileInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('File Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('File Name', widget.fileName),
              const SizedBox(height: 8),
              _buildInfoRow('Location', widget.pdfFile.parent.path),
              const SizedBox(height: 8),
              _buildInfoRow('Size', _formatFileSize(widget.pdfBytes.length)),
              const SizedBox(height: 8),
              _buildInfoRow('Type', 'PDF Document'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[700])),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
