import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/claim.dart';
import '../../../repositories/claim_repository.dart';
import '../widgets/summary_card.dart';

/// Dashboard screen showing claims overview and list.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _selectedStatus;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(claimsStreamProvider(_selectedStatus));
    final summaryAsync = ref.watch(claimsSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(claimsSummaryProvider);
                  ref.invalidate(claimsStreamProvider(_selectedStatus));
                },
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary cards
                summaryAsync.when(
                  data: (summary) => _buildSummaryCards(summary),
                  loading: () => _buildLoadingSummaryCards(),
                  error: (e, _) => _buildErrorCard(e.toString()),
                ),
                const SizedBox(height: 32),
                // Claims section header
                _buildClaimsSectionHeader(),
                const SizedBox(height: 16),
                // Filters and search
                _buildFiltersRow(),
                const SizedBox(height: 16),
                // Claims list
                claimsAsync.when(
                  data: (claims) => _buildClaimsList(claims),
                  loading: () => const LoadingIndicator(message: 'Loading claims...'),
                  error: (e, _) => _buildErrorCard(e.toString()),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ClaimsSummary summary) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SummaryCard(
          title: 'Total Claims',
          value: summary.totalClaims.toString(),
          icon: Icons.description_outlined,
          color: AppColors.primary,
          subtitle: _getStatusBreakdown(summary),
        ),
        SummaryCard(
          title: 'Approved Amount',
          value: Formatters.formatCompactCurrency(summary.totalApprovedAmount),
          icon: Icons.check_circle_outline,
          color: AppColors.statusApproved,
          subtitle: 'Total approved value',
        ),
        SummaryCard(
          title: 'Settled Amount',
          value: Formatters.formatCompactCurrency(summary.totalSettledAmount),
          icon: Icons.payments_outlined,
          color: AppColors.secondary,
          subtitle: 'Total settlements made',
        ),
        SummaryCard(
          title: 'Pending Amount',
          value: Formatters.formatCompactCurrency(summary.totalPendingAmount),
          icon: Icons.pending_outlined,
          color: AppColors.statusPartiallySettled,
          subtitle: 'Awaiting settlement',
        ),
      ],
    );
  }

  String _getStatusBreakdown(ClaimsSummary summary) {
    final parts = <String>[];
    if (summary.draftCount > 0) parts.add('${summary.draftCount} draft');
    if (summary.submittedCount > 0) parts.add('${summary.submittedCount} submitted');
    if (summary.approvedCount > 0) parts.add('${summary.approvedCount} approved');
    return parts.isEmpty ? 'No claims yet' : parts.join(', ');
  }

  Widget _buildLoadingSummaryCards() {
    return const Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SummaryCardSkeleton(),
        SummaryCardSkeleton(),
        SummaryCardSkeleton(),
        SummaryCardSkeleton(),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: AppColors.errorLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error: $message',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimsSectionHeader() {
    return Row(
      children: [
        const Text(
          'Claims',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => context.go('/claims/create'),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('New Claim'),
        ),
      ],
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        // Search field
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by patient name, policy number...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Status filter
        Expanded(
          child: DropdownButtonFormField<String?>(
            isExpanded: true,
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Statuses'),
              ),
              ...ClaimStatus.values.map(
                (status) => DropdownMenuItem(
                  value: status.value,
                  child: Text(status.label),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClaimsList(List<Claim> claims) {
    // Filter claims by search query
    final filteredClaims = claims.where((claim) {
      if (_searchQuery.isEmpty) return true;
      return claim.patientName.toLowerCase().contains(_searchQuery) ||
          claim.policyNumber.toLowerCase().contains(_searchQuery) ||
          claim.hospitalName.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredClaims.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return SearchEmptyState(query: _searchQuery);
      }
      if (_selectedStatus != null) {
        return FilterEmptyState(
          filterName: ClaimStatus.fromString(_selectedStatus!).label,
          onClearFilter: () {
            setState(() {
              _selectedStatus = null;
            });
          },
        );
      }
      return ClaimsEmptyState(
        onCreateClaim: () => context.go('/claims/create'),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _buildTableHeader('Patient', flex: 2),
                _buildTableHeader('Policy No.', flex: 2),
                _buildTableHeader('Hospital', flex: 2),
                _buildTableHeader('Admission', flex: 1),
                _buildTableHeader('Amount', flex: 1, align: TextAlign.right),
                _buildTableHeader('Status', flex: 1, align: TextAlign.center),
                const SizedBox(width: 48), // Actions column
              ],
            ),
          ),
          // Table rows
          ...filteredClaims.map((claim) => _buildClaimRow(claim)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        textAlign: align,
      ),
    );
  }

  Widget _buildClaimRow(Claim claim) {
    return InkWell(
      onTap: () => context.go('/claims/${claim.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claim.patientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'ID: ${claim.id.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                claim.policyNumber,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                claim.hospitalName,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                Formatters.formatShortDate(claim.admissionDate),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                Formatters.formatCurrency(claim.totalBillAmount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Center(
                child: StatusBadge(status: claim.status),
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () => context.go('/claims/${claim.id}'),
                tooltip: 'View details',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
