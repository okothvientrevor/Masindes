import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_widgets/stat_card.dart';
import 'dashboard_widgets/section_header.dart';
import 'dashboard_widgets/recent_contributions_list.dart';
import 'dashboard_widgets/quick_actions_grid.dart';
import 'dashboard_widgets/chart_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final double targetAmount = 500000; // Monthly target in UGX
  double currentAmount = 0;
  int totalContributors = 0;
  double thisMonthAmount = 0;
  List<Map<String, dynamic>> recentContributions = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // Fetch contributors count
    final contributorsSnapshot = await FirebaseFirestore.instance
        .collection('family_members')
        .get();
    if (mounted) {
      setState(() {
        totalContributors = contributorsSnapshot.size;
      });
    }
    // Fetch this month's amount and current amount
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();
    double monthTotal = 0.0;
    for (var doc in paymentsSnapshot.docs) {
      monthTotal += doc['amount']?.toDouble() ?? 0.0;
    }
    if (mounted) {
      setState(() {
        thisMonthAmount = monthTotal;
        currentAmount = monthTotal;
      });
    }
    // Fetch recent contributions
    final recentSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .orderBy('date', descending: true)
        .limit(4)
        .get();
    if (mounted) {
      setState(() {
        recentContributions = recentSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': data['memberName'] ?? '',
            'amount': data['amount']?.toDouble() ?? 0.0,
            'date': (data['date'] as Timestamp).toDate().toString().substring(
              0,
              10,
            ),
          };
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage = targetAmount == 0
        ? 0
        : (currentAmount / targetAmount) * 100;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Masinde Contributions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Managing contributions for Grandparents',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.family_restroom,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Progress Overview Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Target Progress',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'UGX ${formatAmount(currentAmount)}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      'of UGX ${formatAmount(targetAmount)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                      value: progressPercentage / 100,
                                      backgroundColor: Colors.grey[200],
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.green,
                                          ),
                                      minHeight: 8,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${progressPercentage.toStringAsFixed(1)}% Complete',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Pie Chart with Syncfusion
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: SfCircularChart(
                                  margin: EdgeInsets.zero,
                                  series: <CircularSeries>[
                                    DoughnutSeries<ChartData, String>(
                                      dataSource: [
                                        ChartData(
                                          'Contributed',
                                          currentAmount,
                                          Colors.green,
                                        ),
                                        ChartData(
                                          'Remaining',
                                          targetAmount - currentAmount,
                                          Colors.grey[300]!,
                                        ),
                                      ],
                                      xValueMapper: (ChartData data, _) =>
                                          data.category,
                                      yValueMapper: (ChartData data, _) =>
                                          data.value,
                                      pointColorMapper: (ChartData data, _) =>
                                          data.color,
                                      innerRadius: '70%',
                                      radius: '100%',
                                      strokeWidth: 0,
                                      dataLabelSettings:
                                          const DataLabelSettings(
                                            isVisible: false,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Contributors',
                              value: totalContributors.toString(),
                              icon: Icons.people,
                              color: Colors.blue,
                              trend: '+2 this month',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              title: 'This Month',
                              value: 'UGX ${formatAmount(thisMonthAmount)}',
                              icon: Icons.calendar_today,
                              color: Colors.orange,
                              trend: '+8.2%',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SectionHeader(
                        title: 'Recent Contributions',
                        action: 'View All',
                        onAction: () {},
                      ),
                      const SizedBox(height: 16),
                      RecentContributionsList(
                        recentContributions: recentContributions,
                        formatAmount: formatAmount,
                      ),
                      const SizedBox(height: 32),
                      SectionHeader(title: 'Quick Actions', action: ''),
                      const SizedBox(height: 16),
                      QuickActionsGrid(
                        actions: [
                          {
                            'title': 'Add Payment',
                            'icon': Icons.add,
                            'color': Colors.blue,
                          },
                          {
                            'title': 'Family Members',
                            'icon': Icons.people,
                            'color': Colors.purple,
                          },
                          {
                            'title': 'Disbursements',
                            'icon': Icons.account_balance,
                            'color': Colors.orange,
                          },
                          {
                            'title': 'Export Report',
                            'icon': Icons.file_download,
                            'color': Colors.green,
                          },
                        ],
                        onTap: (index) {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Data model for chart
class ChartData {
  ChartData(this.category, this.value, this.color);
  final String category;
  final double value;
  final Color color;
}
