import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/claims/screens/claim_form_screen.dart';
import '../features/claims/screens/claim_detail_screen.dart';
import 'constants/app_colors.dart';
import 'utils/responsive.dart';
import 'widgets/app_drawer.dart';

/// Application router configuration using GoRouter.
/// Includes authentication guard and deep linking support.

/// Provider for the GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login page, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveAppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: '/claims/create',
            name: 'createClaim',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ClaimFormScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: '/claims/:id',
            name: 'claimDetail',
            pageBuilder: (context, state) {
              final claimId = state.pathParameters['id']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: ClaimDetailScreen(claimId: claimId),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/claims/:id/edit',
            name: 'editClaim',
            pageBuilder: (context, state) {
              final claimId = state.pathParameters['id']!;
              return CustomTransitionPage(
                key: state.pageKey,
                child: ClaimFormScreen(claimId: claimId),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.home_rounded, size: 20),
                label: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

/// Responsive app shell that switches between sidebar (desktop) and drawer (mobile)
class ResponsiveAppShell extends StatefulWidget {
  final Widget child;

  const ResponsiveAppShell({super.key, required this.child});

  /// Opens the drawer from anywhere in the widget tree
  static void openDrawer(BuildContext context) {
    final state = context.findAncestorStateOfType<_ResponsiveAppShellState>();
    state?._scaffoldKey.currentState?.openDrawer();
  }

  /// Check if we're in mobile mode (drawer available)
  static bool isMobileMode(BuildContext context) {
    return !Responsive.showSidebar(context);
  }

  @override
  State<ResponsiveAppShell> createState() => _ResponsiveAppShellState();
}

class _ResponsiveAppShellState extends State<ResponsiveAppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final showSidebar = Responsive.showSidebar(context);

    if (showSidebar) {
      // Desktop/Tablet: Show sidebar
      return Scaffold(
        body: Row(
          children: [
            const DesktopSidebar(),
            Expanded(child: widget.child),
          ],
        ),
      );
    } else {
      // Mobile: Use drawer with GlobalKey
      return Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: widget.child,
      );
    }
  }
}

/// Desktop sidebar navigation
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(currentUserProvider);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Brand
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'ClaimCare',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Navigation items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _SidebarNavItem(
                    icon: Icons.space_dashboard_outlined,
                    selectedIcon: Icons.space_dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: currentLocation == '/dashboard',
                    onTap: () => context.go('/dashboard'),
                  ),
                  _SidebarNavItem(
                    icon: Icons.add_box_outlined,
                    selectedIcon: Icons.add_box_rounded,
                    label: 'New Claim',
                    isSelected: currentLocation == '/claims/create',
                    onTap: () => context.go('/claims/create'),
                  ),
                ],
              ),
            ),
          ),
          
          // User section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
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
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : _isHovered
                    ? AppColors.surfaceVariant.withValues(alpha: 0.7)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Icon(
                      widget.isSelected ? widget.selectedIcon : widget.icon,
                      size: 22,
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: widget.isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
