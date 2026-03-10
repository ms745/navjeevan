import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/route_names.dart';
import '../theme/colors.dart';
import '../../providers/auth_provider.dart';

/// Global logout button with role badge
class LogoutButton extends StatelessWidget {
  final Color? backgroundColor;
  final bool showRoleBadge;

  const LogoutButton({
    super.key,
    this.backgroundColor,
    this.showRoleBadge = true,
  });

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      // Perform logout
      await context.read<AuthProvider>().logout();

      if (context.mounted) {
        // Navigate to role select
        context.go(NavJeevanRoutes.roleSelect);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userRole = auth.userRole?.toUpperCase() ?? 'USER';
    final userEmail = auth.user?.email ?? 'Unknown';

    return PopupMenuButton<void>(
      offset: const Offset(0, 50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: NavJeevanColors.primaryRose, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showRoleBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleBadgeColor(auth.userRole),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  userRole,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (showRoleBadge) const SizedBox(width: 8),
            const Icon(Icons.person, size: 20),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<void>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Role: $userRole',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          onTap: () => _handleLogout(context),
          child: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleBadgeColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'mother':
        return NavJeevanColors.primaryRose;
      case 'parent':
        return Colors.blue.shade600;
      case 'agency':
        return Colors.purple.shade600;
      case 'admin':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}

/// Compact badge-only version for headers
class RoleBadge extends StatelessWidget {
  final String? role;
  final double? fontSize;

  const RoleBadge({super.key, this.role, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final displayRole = role?.toUpperCase() ?? 'USER';
    final bgColor = _getRoleBadgeColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayRole,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRoleBadgeColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'mother':
        return NavJeevanColors.primaryRose;
      case 'parent':
        return Colors.blue.shade600;
      case 'agency':
        return Colors.purple.shade600;
      case 'admin':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
