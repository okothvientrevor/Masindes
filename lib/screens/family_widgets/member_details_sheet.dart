import 'package:flutter/material.dart';

void showMemberDetailsSheet(BuildContext context, Map<String, dynamic> member) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Member Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Name', member['name'] ?? ''),
          _buildDetailRow('Contact', member['contact'] ?? ''),
          if ((member['country'] ?? '').isNotEmpty)
            _buildDetailRow('Country', member['country'] ?? ''),
          if ((member['email'] ?? '').isNotEmpty)
            _buildDetailRow('Email', member['email'] ?? ''),
          _buildDetailRow('Join Date', member['joinDate'] ?? ''),
          _buildDetailRow(
            'Total Contributed',
            'UGX ${(member['totalContributed'] ?? 0.0).toStringAsFixed(0)}',
          ),
        ],
      ),
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
