import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // Add this import
import 'dart:io';

import 'pdf_viewer_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _selectedRange;
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = false;
  double _totalAmount = 0;
  Map<String, double> _methodTotals = {};
  bool _showPdfPreview = false; // Add this flag
  pw.Document? _pdfDocument; // Store the generated PDF document

  @override
  void initState() {
    super.initState();
    _selectedRange = _getCurrentMonthRange();
    _loadPayments();
  }

  DateTimeRange _getCurrentMonthRange() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    return DateTimeRange(start: firstDay, end: lastDay);
  }

  Future<void> _loadPayments() async {
    if (_selectedRange == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedRange!.start),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(_selectedRange!.end),
          )
          .get();

      final payments = paymentsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by date descending
      payments.sort((a, b) {
        final dateA = a['date'] as Timestamp?;
        final dateB = b['date'] as Timestamp?;
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      // Calculate totals
      double totalAmount = 0;
      Map<String, double> methodTotals = {};
      for (var payment in payments) {
        final amount =
            double.tryParse(payment['amount']?.toString() ?? '0') ?? 0;
        totalAmount += amount;

        final method = payment['method']?.toString() ?? 'Unknown';
        methodTotals[method] = (methodTotals[method] ?? 0) + amount;
      }

      setState(() {
        _payments = payments;
        _totalAmount = totalAmount;
        _methodTotals = methodTotals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading payments: $e')));
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _selectedRange != null &&
                  _selectedRange!.end.isBefore(DateTime.now()) ||
              _selectedRange!.end.isAtSameMomentAs(DateTime.now())
          ? _selectedRange
          : null,
    );

    if (picked != null && picked != _selectedRange) {
      setState(() {
        _selectedRange = picked;
        _showPdfPreview = false; // Hide preview when date range changes
        _pdfDocument = null; // Clear previous PDF
      });
      _loadPayments();
    }
  }

  // Modified method to generate PDF and show preview
  Future<void> _generatePdfPreview() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating PDF preview...'),
          ],
        ),
      ),
    );

    try {
      final pdf = pw.Document();

      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Contributions Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Period: ${DateFormat('MMM dd, yyyy').format(_selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedRange!.end)}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Summary section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'Total Records',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('${_payments.length}'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Total Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('${_totalAmount.toStringAsFixed(2)} UGX'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Payment method breakdown
              if (_methodTotals.isNotEmpty) ...[
                pw.Text(
                  'Payment Method Breakdown:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                ..._methodTotals.entries.map(
                  (entry) => pw.Text(
                    '• ${entry.key}: ${entry.value.toStringAsFixed(2)} UGX',
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Data table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount (UGX)',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Method',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Reference',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Notes',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ..._payments.map(
                    (payment) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            payment['memberName']?.toString() ?? '',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(payment['amount']?.toString() ?? '0'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(payment['method']?.toString() ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            payment['date'] is Timestamp
                                ? DateFormat('MMM dd, yyyy').format(
                                    (payment['date'] as Timestamp).toDate(),
                                  )
                                : payment['date']?.toString() ?? '',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            payment['reference']?.toString() ?? '',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(payment['notes']?.toString() ?? ''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Store the PDF document and show preview
      setState(() {
        _pdfDocument = pdf;
        _showPdfPreview = true;
      });
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF preview: $e')),
      );
    }
  }

  // Method to save PDF to file
  Future<void> _savePdfToFile() async {
    if (_pdfDocument == null) return;

    try {
      final pdfBytes = await _pdfDocument!.save();
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'contributions_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Navigate to PDF viewer screen or show success dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(
            pdfFile: file,
            fileName: fileName,
            pdfBytes: pdfBytes,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
    }
  }

  Future<void> _exportToExcel() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating Excel report...'),
          ],
        ),
      ),
    );

    try {
      final excelWorkbook = excel.Excel.createExcel();
      final sheet = excelWorkbook['Contributions Report'];
      excelWorkbook.delete('Sheet1');

      // Add headers
      final headers = [
        'Name',
        'Amount (UGX)',
        'Method',
        'Date',
        'Reference',
        'Notes',
      ];
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = excel.TextCellValue(
          headers[i],
        );
      }

      // Add data
      for (int i = 0; i < _payments.length; i++) {
        final payment = _payments[i];
        final row = [
          payment['memberName']?.toString() ?? '',
          payment['amount']?.toString() ?? '',
          payment['method']?.toString() ?? '',
          payment['date'] is Timestamp
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format((payment['date'] as Timestamp).toDate())
              : payment['date']?.toString() ?? '',
          payment['reference']?.toString() ?? '',
          payment['notes']?.toString() ?? '',
        ];

        for (int j = 0; j < row.length; j++) {
          sheet
              .cell(
                excel.CellIndex.indexByColumnRow(
                  columnIndex: j,
                  rowIndex: i + 1,
                ),
              )
              .value = excel.TextCellValue(
            row[j],
          );
        }
      }

      final excelBytes = excelWorkbook.encode()!;
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'contributions_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(excelBytes);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel report saved to: ${file.path}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting to Excel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _generatePdfPreview,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Preview PDF',
          ),
          IconButton(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export to Excel',
          ),
          // Add close preview button when showing PDF
          if (_showPdfPreview)
            IconButton(
              onPressed: () {
                setState(() {
                  _showPdfPreview = false;
                  _pdfDocument = null;
                });
              },
              icon: const Icon(Icons.close),
              tooltip: 'Close Preview',
            ),
        ],
      ),
      body: _showPdfPreview && _pdfDocument != null
          ? Column(
              children: [
                // Preview header with actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'PDF Preview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _savePdfToFile,
                        icon: const Icon(Icons.download),
                        label: const Text('Save PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // PDF Preview
                Expanded(
                  child: PdfPreview(
                    build: (format) => _pdfDocument!.save(),
                    allowSharing: true,
                    allowPrinting: true,
                    canChangePageFormat: false,
                    canDebug: false,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                // Header section with date range and summary
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[800]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Date range selector
                      Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _selectDateRange,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    color: Colors.blue[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Report Period',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedRange != null
                                              ? '${DateFormat('MMM dd, yyyy').format(_selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedRange!.end)}'
                                              : 'Select date range',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Summary cards
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'Total Records',
                                value: '${_payments.length}',
                                icon: Icons.list_alt,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'Total Amount',
                                value: '${_totalAmount.toStringAsFixed(0)} UGX',
                                icon: Icons.attach_money,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Payment method breakdown (if available)
                if (_methodTotals.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._methodTotals.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '${entry.value.toStringAsFixed(2)} UGX',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Payments list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _payments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No payments found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try selecting a different date range',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final payment = _payments[index];
                            return _buildPaymentCard(payment);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final date = payment['date'] is Timestamp
        ? (payment['date'] as Timestamp).toDate()
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    payment['memberName']?.toString() ?? 'Unknown Member',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${payment['amount']?.toString() ?? '0'} UGX',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment details
            Row(
              children: [
                Expanded(
                  child: _buildPaymentDetail(
                    icon: Icons.payment,
                    label: 'Method',
                    value: payment['method']?.toString() ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildPaymentDetail(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: DateFormat('MMM dd, yyyy').format(date),
                  ),
                ),
              ],
            ),

            if (payment['reference'] != null &&
                payment['reference'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPaymentDetail(
                icon: Icons.receipt_long,
                label: 'Reference',
                value: payment['reference'].toString(),
              ),
            ],

            if (payment['notes'] != null &&
                payment['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPaymentDetail(
                icon: Icons.note,
                label: 'Notes',
                value: payment['notes'].toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
