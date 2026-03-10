import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class MotherProfileScreen extends StatefulWidget {
  const MotherProfileScreen({super.key});

  @override
  State<MotherProfileScreen> createState() => _MotherProfileScreenState();
}

class _MotherProfileScreenState extends State<MotherProfileScreen> {
  bool _notifications = true;
  bool _anonymousDefault = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NavJeevanColors.borderColor),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: NavJeevanColors.blush,
                    child: Icon(
                      Icons.person,
                      color: NavJeevanColors.primaryRose,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anita Sharma',
                        style: NavJeevanTextStyles.titleLarge,
                      ),
                      Text(
                        'Mother ID: MTH-2041',
                        style: NavJeevanTextStyles.bodySmall,
                      ),
                      Text(
                        'Hadapsar, Pune',
                        style: NavJeevanTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Past Counseling', style: NavJeevanTextStyles.headlineMedium),
            const SizedBox(height: 10),
            _sessionTile(
              'Dr. Sarah Miller',
              'Video Session',
              'Completed • 06 Mar 2026',
            ),
            _sessionTile(
              'Maya Thompson',
              'Audio Follow-up',
              'Completed • 01 Mar 2026',
            ),
            const SizedBox(height: 20),
            Text('Settings', style: NavJeevanTextStyles.headlineMedium),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('App notifications'),
              value: _notifications,
              onChanged: (value) => setState(() => _notifications = value),
              activeColor: NavJeevanColors.primaryRose,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Anonymous mode by default'),
              value: _anonymousDefault,
              onChanged: (value) => setState(() => _anonymousDefault = value),
              activeColor: NavJeevanColors.primaryRose,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go(NavJeevanRoutes.roleSelect);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionTile(String counselor, String type, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NavJeevanColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            counselor,
            style: NavJeevanTextStyles.titleLarge.copyWith(fontSize: 16),
          ),
          Text(type, style: NavJeevanTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            status,
            style: NavJeevanTextStyles.bodySmall.copyWith(
              color: NavJeevanColors.primaryRose,
            ),
          ),
        ],
      ),
    );
  }
}
