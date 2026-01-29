import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
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
    final isMobile = Responsive.isMobile(context);
    final showSidebar = Responsive.showSidebar(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isMobile, showSidebar),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/claims/create'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Claim'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(claimsSummaryProvider);
          ref.invalidate(claimsStreamProvider(_selectedStatus));
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Summary cards
                  summaryAsync.when(
                    data: (summary) => _buildSummarySection(summary),
                    loading: () => _buildLoadingSummaryCards(),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  // Claims section header
                  _buildClaimsSectionHeader(isMobile),
                  const SizedBox(height: 16),
                  // Filters and search
                  _buildFiltersRow(isMobile),
                  const SizedBox(height: 20),
                  // Claims list
                  claimsAsync.when(
                    data: (claims) => _buildClaimsList(claims, isMobile),
                    loading: () => const LoadingIndicator(message: 'Loading claims...'),
                    error: (e, _) => _buildErrorCard(e.toString()),
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile, bool showSidebar) {
    return AppBar(
      automaticallyImplyLeading: !showSidebar,
      leading: !showSidebar
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => ResponsiveAppShell.openDrawer(context),
              ),
            )
          : null,
      title: Text(
        'Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 20 : 22,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            ref.invalidate(claimsSummaryProvider);
            ref.invalidate(claimsStreamProvider(_selectedStatus));
          },
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSummarySection(ClaimsSummary summary) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    if (isMobile) {
      // Mobile: Horizontal scrollable cards
      return SizedBox(
        height: 125,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildCompactSummaryCard(
              'Total Claims',
              summary.totalClaims.toString(),
              Icons.description_outlined,
              AppColors.primary,
            ),
            const SizedBox(width: 12),
            _buildCompactSummaryCard(
              'Approved',
              Formatters.formatCompactCurrency(summary.totalApprovedAmount),
              Icons.check_circle_outline,
              AppColors.statusApproved,
            ),
            const SizedBox(width: 12),
            _buildCompactSummaryCard(
              'Settled',
              Formatters.formatCompactCurrency(summary.totalSettledAmount),
              Icons.payments_outlined,
              AppColors.secondary,
            ),
            const SizedBox(width: 12),
            _buildCompactSummaryCard(
              'Pending',
              Formatters.formatCompactCurrency(summary.totalPendingAmount),
              Icons.pending_outlined,
              AppColors.statusPartiallySettled,
            ),
          ],
        ),
      );
    }

    // Tablet/Desktop: Grid layout
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
          width: isTablet ? null : 280,
        ),
        SummaryCard(
          title: 'Approved Amount',
          value: Formatters.formatCompactCurrency(summary.totalApprovedAmount),
          icon: Icons.check_circle_outline,
          color: AppColors.statusApproved,
          subtitle: 'Total approved value',
          width: isTablet ? null : 280,
        ),
        SummaryCard(
          title: 'Settled Amount',
          value: Formatters.formatCompactCurrency(summary.totalSettledAmount),
          icon: Icons.payments_outlined,
          color: AppColors.secondary,
          subtitle: 'Total settlements made',
          width: isTablet ? null : 280,
        ),
        SummaryCard(
          title: 'Pending Amount',
          value: Formatters.formatCompactCurrency(summary.totalPendingAmount),
          icon: Icons.pending_outlined,
          color: AppColors.statusPartiallySettled,
          subtitle: 'Awaiting settlement',
          width: isTablet ? null : 280,
        ),
      ],
    );
  }

  Widget _buildCompactSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return SizedBox(
        height: 125,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: List.generate(
            4,
            (index) => Padding(
              padding: EdgeInsets.only(right: index < 3 ? 12 : 0),
              child: Container(
                width: 150,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error: $message',
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimsSectionHeader(bool isMobile) {
    return Row(
      children: [
        Text(
          'Claims',
          style: TextStyle(
            fontSize: isMobile ? 17 : 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (!isMobile)
          FilledButton.icon(
            onPressed: () => context.go('/claims/create'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Claim'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFiltersRow(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          // Search field - full width
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search claims...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, 'All'),
                const SizedBox(width: 8),
                ...ClaimStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(status.value, status.label),
                    )),
              ],
            ),
          ),
        ],
      );
    }

    // Desktop layout
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
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
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

  Widget _buildFilterChip(String? value, String label) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : null;
        });
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildClaimsList(List<Claim> claims, bool isMobile) {
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

    if (isMobile) {
      return _buildMobileClaimsList(filteredClaims);
    }

    return _buildDesktopClaimsTable(filteredClaims);
  }

  Widget _buildMobileClaimsList(List<Claim> claims) {
    return Column(
      children: claims
          .map((claim) => _buildMobileClaimCard(claim))
          .toList(),
    );
  }

  Widget _buildMobileClaimCard(Claim claim) {
    return GestureDetector(
      onTap: () => context.go('/claims/${claim.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Patient name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    claim.patientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: claim.status),
              ],
            ),
            const SizedBox(height: 8),
            // Policy and hospital
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  size: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 5),
                Text(
                  claim.policyNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.local_hospital_outlined,
                  size: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    claim.hospitalName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom row: Amount and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatCurrency(claim.totalBillAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  Formatters.formatShortDate(claim.admissionDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopClaimsTable(List<Claim> claims) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                _buildTableHeader('Patient', flex: 2),
                _buildTableHeader('Policy No.', flex: 2),
                _buildTableHeader('Hospital', flex: 2),
                _buildTableHeader('Admission', flex: 1),
                _buildTableHeader('Amount', flex: 1, align: TextAlign.right),
                _buildTableHeader('Status', flex: 1, align: TextAlign.center),
                const SizedBox(width: 40),
              ],
            ),
          ),
          // Table rows
          ...claims.map((claim) => _buildClaimRow(claim)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary.withValues(alpha: 0.75),
          letterSpacing: 0.2,
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
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
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
                    'ID: ${claim.id.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
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
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
