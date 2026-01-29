import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'illustrations.dart';

/// Empty state widget with illustration and optional action.
class EmptyState extends StatelessWidget {
  final Widget? illustration;
  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.illustration,
    this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration or icon
            if (illustration != null)
              illustration!
            else if (icon != null)
              Container(
                width: 88,
                height: 88,
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
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for claims list
class ClaimsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateClaim;

  const ClaimsEmptyState({super.key, this.onCreateClaim});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      illustration: const EmptyClaimsIllustration(size: 180),
      title: 'No Claims Yet',
      message: 'Start managing your insurance claims by creating your first one.',
      actionLabel: 'Create Claim',
      onAction: onCreateClaim,
    );
  }
}

/// Empty state for bills
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
      illustration: const EmptyBillsIllustration(size: 180),
      title: 'No Bills Added',
      message: canEdit
          ? 'Add itemized bills to calculate the total claim amount.'
          : 'No bills have been added to this claim.',
      actionLabel: canEdit ? 'Add Bill' : null,
      onAction: canEdit ? onAddBill : null,
    );
  }
}

/// Empty state for audit logs
class AuditLogsEmptyState extends StatelessWidget {
  const AuditLogsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      illustration: EmptyHistoryIllustration(size: 180),
      title: 'No Activity',
      message: 'Status changes and updates will appear here as you work on this claim.',
    );
  }
}

/// Empty state for search results
class SearchEmptyState extends StatelessWidget {
  final String query;

  const SearchEmptyState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      illustration: const NoResultsIllustration(size: 180),
      title: 'No Results',
      message: 'We couldn\'t find any claims matching "$query".',
    );
  }
}

/// Empty state for filtered results
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
      illustration: const NoResultsIllustration(size: 180),
      title: 'No $filterName Claims',
      message: 'There are no claims with "$filterName" status at the moment.',
      actionLabel: 'Clear Filter',
      onAction: onClearFilter,
    );
  }
}
