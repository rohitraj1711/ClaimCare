import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Empty state widget with guidance text and optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state presets for common scenarios
class ClaimsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateClaim;

  const ClaimsEmptyState({super.key, this.onCreateClaim});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.description_outlined,
      title: 'No Claims Found',
      message: 'You haven\'t created any claims yet. Start by creating your first insurance claim.',
      actionLabel: 'Create Claim',
      onAction: onCreateClaim,
    );
  }
}

class BillsEmptyState extends StatelessWidget {
  final VoidCallback? onAddBill;
  final bool canEdit;

  const BillsEmptyState({
    super.key,
    this.onAddBill,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No Bills Added',
      message: canEdit
          ? 'Add bills to calculate the total claim amount.'
          : 'No bills have been added to this claim.',
      actionLabel: canEdit ? 'Add Bill' : null,
      onAction: canEdit ? onAddBill : null,
    );
  }
}

class AuditLogsEmptyState extends StatelessWidget {
  const AuditLogsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.history,
      title: 'No History',
      message: 'Status changes and updates will appear here.',
    );
  }
}

class SearchEmptyState extends StatelessWidget {
  final String query;

  const SearchEmptyState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'No claims match your search for "$query". Try a different search term.',
    );
  }
}

class FilterEmptyState extends StatelessWidget {
  final String filterName;
  final VoidCallback? onClearFilter;

  const FilterEmptyState({
    super.key,
    required this.filterName,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.filter_alt_off,
      title: 'No $filterName Claims',
      message: 'There are no claims with "$filterName" status.',
      actionLabel: 'Clear Filter',
      onAction: onClearFilter,
    );
  }
}
