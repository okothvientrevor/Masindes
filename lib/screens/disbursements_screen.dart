import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String formatAmount(double amount) {
  return amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

class DisbursementsScreen extends StatefulWidget {
  const DisbursementsScreen({super.key});

  @override
  State<DisbursementsScreen> createState() => _DisbursementsScreenState();
}

class _DisbursementsScreenState extends State<DisbursementsScreen> {
  String selectedFilter = 'All';
  String selectedSort = 'Date (Latest)';

  List<Map<String, dynamic>> disbursements = [];
  double totalDisbursed = 0.0;
  double currentBalance = 0.0;
  int thisMonthDisbursements = 0;

  @override
  void initState() {
    super.initState();
    _fetchDisbursements();
  }

  Future<void> _fetchDisbursements() async {
    // Fetch disbursements from Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('disbursements')
        .get();
    final now = DateTime.now();
    final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    double disbursed = 0.0;
    int monthCount = 0;
    List<Map<String, dynamic>> list = snapshot.docs.map((doc) {
      final data = doc.data();
      if (data['status'] == 'Completed') {
        disbursed += data['amount']?.toDouble() ?? 0.0;
      }
      if ((data['date'] ?? '').toString().startsWith(thisMonth)) {
        monthCount++;
      }
      return data;
    }).toList();
    // Fetch total contributions for balance
    final membersSnapshot = await FirebaseFirestore.instance
        .collection('family_members')
        .get();
    double totalContributed = 0.0;
    for (var doc in membersSnapshot.docs) {
      totalContributed += doc['totalContributed']?.toDouble() ?? 0.0;
    }
    setState(() {
      disbursements = list;
      totalDisbursed = disbursed;
      currentBalance = totalContributed - disbursed;
      thisMonthDisbursements = monthCount;
    });
  }

  List<Map<String, dynamic>> get filteredDisbursements {
    List<Map<String, dynamic>> filtered = disbursements;
    if (selectedFilter != 'All') {
      filtered = filtered.where((d) => d['status'] == selectedFilter).toList();
    }
    switch (selectedSort) {
      case 'Date (Latest)':
        filtered.sort((a, b) => b['date'].compareTo(a['date']));
        break;
      case 'Date (Oldest)':
        filtered.sort((a, b) => a['date'].compareTo(b['date']));
        break;
      case 'Amount (Highest)':
        filtered.sort((a, b) => b['amount'].compareTo(a['amount']));
        break;
      case 'Amount (Lowest)':
        filtered.sort((a, b) => a['amount'].compareTo(b['amount']));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Disbursements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showAddDisbursementDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Disbursement Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: () => _showAddDisbursementDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Send Money to Grandparents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          // Summary Cards
          Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Disbursed',
                        'UGX ${formatAmount(totalDisbursed)}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Current Balance',
                        'UGX ${formatAmount(currentBalance)}',
                        Icons.account_balance_wallet,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  'This Month Disbursements',
                  '$thisMonthDisbursements transactions',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Filters and Sort
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildFilterDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildSortDropdown()),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Disbursements List
          Expanded(
            child: filteredDisbursements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No disbursements found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDisbursements.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final disbursement = filteredDisbursements[index];
                      return _buildDisbursementCard(disbursement);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedFilter,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: ['All', 'Completed', 'Pending'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedFilter = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSort,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items:
              [
                'Date (Latest)',
                'Date (Oldest)',
                'Amount (Highest)',
                'Amount (Lowest)',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedSort = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDisbursementCard(Map<String, dynamic> disbursement) {
    final bool isCompleted = disbursement['status'] == 'Completed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDisbursementDetails(disbursement),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.pending,
                        color: isCompleted ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disbursement['recipient'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            disbursement['purpose'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'UGX ${formatAmount(disbursement['amount']?.toDouble() ?? 0.0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            disbursement['status'],
                            style: TextStyle(
                              color: isCompleted ? Colors.green : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _getDisbursementIcon(disbursement['method']),
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      disbursement['method'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      disbursement['date'],
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDisbursementIcon(String method) {
    switch (method.toLowerCase()) {
      case 'bank transfer':
        return Icons.account_balance;
      case 'mobile money':
        return Icons.phone_android;
      case 'cash delivery':
        return Icons.local_shipping;
      default:
        return Icons.payment;
    }
  }

  void _showDisbursementDetails(Map<String, dynamic> disbursement) {
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
                  'Disbursement Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Recipient', disbursement['recipient']),
            _buildDetailRow(
              'Amount',
              'UGX ${formatAmount(disbursement['amount']?.toDouble() ?? 0.0)}',
            ),
            _buildDetailRow('Purpose', disbursement['purpose']),
            _buildDetailRow('Date', disbursement['date']),
            _buildDetailRow('Method', disbursement['method']),
            _buildDetailRow('Reference', disbursement['reference']),
            _buildDetailRow('Status', disbursement['status']),
            if ((disbursement['notes'] ?? '').isNotEmpty)
              _buildDetailRow('Notes', disbursement['notes']),
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
            width: 80,
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

  void _showAddDisbursementDialog() {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedRecipient = 'Grandmother Mary';
    String selectedPurpose = 'Monthly Support';
    String selectedMethod = 'Bank Transfer';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text(
            'Send Money to Grandparents',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recipient
                  DropdownButtonFormField<String>(
                    value: selectedRecipient,
                    decoration: InputDecoration(
                      labelText: 'Recipient',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    items:
                        [
                          'Grandmother Mary',
                          'Grandfather Andrew',
                          'Both Grandparents',
                        ].map((String recipient) {
                          return DropdownMenuItem<String>(
                            value: recipient,
                            child: Text(recipient),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setStateDialog(() {
                        selectedRecipient = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (\$)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Amount is required';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Purpose
                  DropdownButtonFormField<String>(
                    value: selectedPurpose,
                    decoration: InputDecoration(
                      labelText: 'Purpose',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    items:
                        [
                          'Monthly Support',
                          'Medical Bills',
                          'Groceries',
                          'House Repairs',
                          'Medication',
                          'Emergency',
                          'Other',
                        ].map((String purpose) {
                          return DropdownMenuItem<String>(
                            value: purpose,
                            child: Text(purpose),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setStateDialog(() {
                        selectedPurpose = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Method
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.payment),
                    ),
                    items: ['Bank Transfer', 'Mobile Money', 'Cash Delivery']
                        .map((String method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        })
                        .toList(),
                    onChanged: (String? newValue) {
                      setStateDialog(() {
                        selectedMethod = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newDisbursement = {
                    'amount': double.parse(amountController.text),
                    'date': selectedDate.toString().substring(0, 10),
                    'recipient': selectedRecipient,
                    'purpose': selectedPurpose,
                    'status': 'Completed',
                    'method': selectedMethod,
                    'reference': 'DISB${DateTime.now().millisecondsSinceEpoch}',
                    'notes': notesController.text,
                  };
                  await FirebaseFirestore.instance
                      .collection('disbursements')
                      .add(newDisbursement);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Disbursement added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _fetchDisbursements();
                }
              },
              child: const Text('Send Money'),
            ),
          ],
        ),
      ),
    );
  }
}
