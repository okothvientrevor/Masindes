import 'package:flutter/material.dart';
import 'package:masindes2/screens/add_payment_form.dart';
import 'package:masindes2/screens/reports_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final void Function(int index)? onTap;

  const QuickActionsGrid({super.key, required this.actions, this.onTap});

  @override
  Widget build(BuildContext context) {
    final filteredActions = actions
        .where(
          (action) =>
              action['title'] == 'Add Payment' ||
              action['title'] == 'Export Report',
        )
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: filteredActions.length,
      itemBuilder: (context, index) {
        final action = filteredActions[index];
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
              onTap: () async {
                if (action['title'] == 'Add Payment') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPaymentForm(),
                    ),
                  );
                } else if (action['title'] == 'Export Report') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  );
                } else {
                  onTap?.call(index);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      action['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
