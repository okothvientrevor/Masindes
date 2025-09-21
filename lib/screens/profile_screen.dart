import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userProfile = {};
  Map<String, dynamic> appStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Fetch user profile
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    // Fetch app stats
    final membersSnapshot = await FirebaseFirestore.instance
        .collection('family_members')
        .get();
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .get();
    final disbursementsSnapshot = await FirebaseFirestore.instance
        .collection('disbursements')
        .get();
    double totalContributions = 0.0;
    double totalDisbursements = 0.0;
    for (var doc in paymentsSnapshot.docs) {
      if (doc['memberId'] == user.uid) {
        totalContributions += doc['amount']?.toDouble() ?? 0.0;
      }
    }
    for (var doc in disbursementsSnapshot.docs) {
      totalDisbursements += doc['amount']?.toDouble() ?? 0.0;
    }
    if (mounted) {
      setState(() {
        userProfile = userDoc.data() ?? {};
        appStats = {
          'totalContributions': totalContributions,
          'totalDisbursements': totalDisbursements,
          'familyMembers': membersSnapshot.size,
          'monthsActive': _getMonthsActive(userProfile['joinDate']),
        };
        isLoading = false;
      });
    }
  }

  int _getMonthsActive(String? joinDate) {
    if (joinDate == null) return 0;
    final join = DateTime.tryParse(joinDate);
    if (join == null) return 0;
    final now = DateTime.now();
    return (now.year - join.year) * 12 + (now.month - join.month) + 1;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Profile Info
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: userProfile['profileImage'] == null
                              ? Text(
                                  userProfile['name']
                                      .toString()
                                      .split(' ')
                                      .map((e) => e[0])
                                      .join(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userProfile['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userProfile['role'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showEditProfileDialog(),
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
            ],
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Card
                  _buildSectionCard(
                    title: 'Personal Information',
                    icon: Icons.person,
                    children: [
                      _buildInfoTile(
                        Icons.email,
                        'Email',
                        userProfile['email'] ?? '',
                      ),
                      _buildInfoTile(
                        Icons.phone,
                        'Phone',
                        userProfile['phone'] ?? '',
                      ),
                      _buildInfoTile(
                        Icons.location_on,
                        'Location',
                        userProfile['location'] ?? '',
                      ),
                      _buildInfoTile(
                        Icons.calendar_today,
                        'Member Since',
                        userProfile['joinDate'] ?? '',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Statistics Card
                  _buildSectionCard(
                    title: 'Your Contributions',
                    icon: Icons.bar_chart,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Total Contributed',
                              '\$${appStats['totalContributions'].toStringAsFixed(0)}',
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Total Disbursed',
                              '\$${appStats['totalDisbursements'].toStringAsFixed(0)}',
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Family Members',
                              appStats['familyMembers'].toString(),
                              Colors.purple,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Months Active',
                              appStats['monthsActive'].toString(),
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Settings Card
                  _buildSectionCard(
                    title: 'Settings',
                    icon: Icons.settings,
                    children: [
                      _buildSettingsTile(
                        Icons.notifications,
                        'Notifications',
                        'Manage notification preferences',
                        () => _showNotificationSettings(),
                      ),
                      _buildSettingsTile(
                        Icons.security,
                        'Privacy & Security',
                        'Update password and security settings',
                        () => _showSecuritySettings(),
                      ),
                      _buildSettingsTile(
                        Icons.language,
                        'Language',
                        'Change app language',
                        () => _showLanguageSettings(),
                      ),
                      _buildSettingsTile(
                        Icons.help,
                        'Help & Support',
                        'Get help and contact support',
                        () => _showHelpSupport(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // App Information Card
                  _buildSectionCard(
                    title: 'App Information',
                    icon: Icons.info,
                    children: [
                      _buildInfoTile(Icons.app_shortcut, 'Version', '1.0.0'),
                      _buildInfoTile(
                        Icons.update,
                        'Last Updated',
                        '2024-06-15',
                      ),
                      _buildSettingsTile(
                        Icons.privacy_tip,
                        'Privacy Policy',
                        'Read our privacy policy',
                        () => _showPrivacyPolicy(),
                      ),
                      _buildSettingsTile(
                        Icons.description,
                        'Terms of Service',
                        'Read terms and conditions',
                        () => _showTermsOfService(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: userProfile['name'] ?? '',
    );
    final emailController = TextEditingController(
      text: userProfile['email'] ?? '',
    );
    final phoneController = TextEditingController(
      text: userProfile['phone'] ?? '',
    );
    final locationController = TextEditingController(
      text: userProfile['location'] ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
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
              if (formKey.currentState?.validate() ?? false) {
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'location': locationController.text.trim(),
                      });
                  setState(() {
                    userProfile['name'] = nameController.text.trim();
                    userProfile['email'] = emailController.text.trim();
                    userProfile['phone'] = phoneController.text.trim();
                    userProfile['location'] = locationController.text.trim();
                  });
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    // Navigate to notification settings screen
  }

  void _showSecuritySettings() {
    // Navigate to security settings screen
  }

  void _showLanguageSettings() {
    // Navigate to language settings screen
  }

  void _showHelpSupport() {
    // Navigate to help and support screen
  }

  void _showPrivacyPolicy() {
    // Show privacy policy
  }

  void _showTermsOfService() {
    // Show terms of service
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform logout action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
