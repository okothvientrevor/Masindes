import 'package:flutter/material.dart';

class ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> payment;

  const ReceiptDialog({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final DateTime paymentDate = (payment['date'] as dynamic).toDate();
    final String formattedDate =
        '${paymentDate.day}/${paymentDate.month}/${paymentDate.year}';
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Receipt',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'FAMILY CONTRIBUTION RECEIPT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  _buildReceiptRow(
                    'Receipt #:',
                    payment['id']?.toString().substring(0, 8) ?? 'N/A',
                  ),
                  _buildReceiptRow('Date:', formattedDate),
                  _buildReceiptRow('Member:', payment['memberName'] ?? ''),
                  _buildReceiptRow(
                    'Amount:',
                    'UGX ${payment['amount']?.toStringAsFixed(0) ?? '0'}',
                  ),
                  _buildReceiptRow('Method:', payment['method'] ?? ''),
                  _buildReceiptRow('Reference:', payment['reference'] ?? 'N/A'),
                  _buildReceiptRow('Status:', payment['status'] ?? 'Pending'),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'Thank you for your contribution!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
