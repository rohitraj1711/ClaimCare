import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../../services/auth_service.dart';

/// Mobile-friendly navigation drawer with clean, flat design.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ClaimCare',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Claims Management',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 8),
            
            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _DrawerNavItem(
                    icon: Icons.space_dashboard_outlined,
                    selectedIcon: Icons.space_dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: currentLocation == '/dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/dashboard');
                    },
                  ),
                  _DrawerNavItem(
                    icon: Icons.add_box_outlined,
                    selectedIcon: Icons.add_box_rounded,
                    label: 'New Claim',
                    isSelected: currentLocation == '/claims/create',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/claims/create');
                    },
                  ),
                ],
              ),
            ),
            
            // User section
            const Divider(height: 1, indent: 24, endIndent: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        (user?.email?.substring(0, 1) ?? 'U').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Admin',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    tooltip: 'Sign out',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
