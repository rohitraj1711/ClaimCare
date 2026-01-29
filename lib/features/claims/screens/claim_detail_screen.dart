import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/claim.dart';
import '../../../models/bill.dart';
import '../../../models/audit_log.dart';
import '../../../repositories/claim_repository.dart';
import '../../../repositories/bill_repository.dart';
import '../../../repositories/audit_log_repository.dart';
import '../../../repositories/settlement_repository.dart';
import '../widgets/status_action_dialogs.dart';
import '../../bills/widgets/bill_form_dialog.dart';

/// Screen for displaying claim details with tabs.
class ClaimDetailScreen extends ConsumerStatefulWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  ConsumerState<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends ConsumerState<ClaimDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claimAsync = ref.watch(claimStreamProvider(widget.claimId));
    final isMobile = Responsive.isMobile(context);
    final showSidebar = Responsive.showSidebar(context);

    return claimAsync.when(
      data: (claim) {
        if (claim == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Claim Not Found')),
            body: NotFoundWidget(
              itemName: 'Claim',
              onGoBack: () => context.go('/dashboard'),
            ),
          );
        }
        return _buildClaimDetailScaffold(claim, isMobile, showSidebar);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const LoadingIndicator(message: 'Loading claim details...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(claimStreamProvider(widget.claimId)),
        ),
      ),
    );
  }

  Widget _buildClaimDetailScaffold(Claim claim, bool isMobile, bool showSidebar) {
    return LoadingOverlay(
      isLoading: _isProcessing,
      message: 'Processing...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/dashboard'),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMobile ? 'Claim Details' : claim.patientName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              if (!isMobile)
                Text(
                  'ID: ${claim.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          actions: [
            if (claim.isEditable)
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.go('/claims/${claim.id}/edit'),
                tooltip: 'Edit claim',
              ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: isMobile ? 'Info' : 'Overview'),
              const Tab(text: 'Bills'),
              Tab(text: isMobile ? 'Money' : 'Financial'),
              const Tab(text: 'History'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Status and actions bar
            _buildStatusActionsBar(claim, isMobile),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(claim, isMobile),
                  _buildBillsTab(claim, isMobile),
                  _buildFinancialTab(claim, isMobile),
                  _buildHistoryTab(claim),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActionsBar(Claim claim, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(status: claim.status, large: true),
                    const Spacer(),
                    ..._buildCompactActionButtons(claim),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _getStatusMessage(claim),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                StatusBadge(status: claim.status, large: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _getStatusMessage(claim),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                ..._buildActionButtons(claim),
              ],
            ),
    );
  }

  String _getStatusMessage(Claim claim) {
    switch (claim.claimStatus) {
      case ClaimStatus.draft:
        return 'Add bills and submit for review when ready.';
      case ClaimStatus.submitted:
        return 'Claim is pending approval.';
      case ClaimStatus.approved:
        return 'Ready for settlement. Pending: ${Formatters.formatCurrency(claim.pendingAmount)}';
      case ClaimStatus.rejected:
        return claim.rejectionReason ?? 'Claim has been rejected.';
      case ClaimStatus.partiallySettled:
        return 'Partially settled. Remaining: ${Formatters.formatCurrency(claim.remainingToSettle)}';
    }
  }

  List<Widget> _buildActionButtons(Claim claim) {
    final buttons = <Widget>[];

    if (claim.canSubmit) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _showSubmitDialog(claim),
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Submit'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      );
    }

    if (claim.canApproveOrReject) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _showRejectDialog(claim),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text('Reject'),
        ),
      );
      buttons.add(const SizedBox(width: 10));
      buttons.add(
        FilledButton.icon(
          onPressed: () => _showApproveDialog(claim),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.statusApproved,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Approve'),
        ),
      );
    }

    if (claim.canSettle) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _showSettleDialog(claim),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
          label: const Text('Settle'),
        ),
      );
    }

    return buttons;
  }

  List<Widget> _buildCompactActionButtons(Claim claim) {
    final buttons = <Widget>[];

    if (claim.canSubmit) {
      buttons.add(_buildIconActionButton(
        Icons.send_rounded,
        AppColors.primary,
        () => _showSubmitDialog(claim),
      ));
    }

    if (claim.canApproveOrReject) {
      buttons.add(_buildIconActionButton(
        Icons.close_rounded,
        AppColors.error,
        () => _showRejectDialog(claim),
      ));
      buttons.add(const SizedBox(width: 8));
      buttons.add(_buildIconActionButton(
        Icons.check_rounded,
        AppColors.statusApproved,
        () => _showApproveDialog(claim),
      ));
    }

    if (claim.canSettle) {
      buttons.add(_buildIconActionButton(
        Icons.payments_rounded,
        AppColors.secondary,
        () => _showSettleDialog(claim),
      ));
    }

    return buttons;
  }

  Widget _buildIconActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Claim claim, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main claim info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Claim ID
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fingerprint, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'CLAIM ID',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  claim.id,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.9),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                
                // Two column layout for desktop, single for mobile
                if (isMobile) ..._buildMobileInfoRows(claim) else ..._buildDesktopInfoGrid(claim),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMobileInfoRows(Claim claim) {
    return [
      _buildDetailRow('Patient Name', claim.patientName, Icons.person_outline),
      _buildDetailRow('Policy Number', claim.policyNumber, Icons.credit_card),
      _buildDetailRow('Hospital', claim.hospitalName, Icons.local_hospital_outlined),
      _buildDetailRow('Admission Date', Formatters.formatDate(claim.admissionDate), Icons.calendar_today_outlined),
      if (claim.dischargeDate != null)
        _buildDetailRow('Discharge Date', Formatters.formatDate(claim.dischargeDate!), Icons.event_available_outlined),
      if (claim.dischargeDate != null)
        _buildDetailRow('Duration', '${claim.dischargeDate!.difference(claim.admissionDate).inDays} days', Icons.timelapse_outlined),
      _buildDetailRow('Created', Formatters.formatDateTime(claim.createdAt), Icons.access_time_outlined),
      if (claim.notes != null && claim.notes!.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _buildNotesSection(claim.notes!),
      ],
    ];
  }

  List<Widget> _buildDesktopInfoGrid(Claim claim) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildDetailRow('Patient Name', claim.patientName, Icons.person_outline)),
          const SizedBox(width: 32),
          Expanded(child: _buildDetailRow('Policy Number', claim.policyNumber, Icons.credit_card)),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildDetailRow('Hospital', claim.hospitalName, Icons.local_hospital_outlined)),
          const SizedBox(width: 32),
          Expanded(child: _buildDetailRow('Created', Formatters.formatDateTime(claim.createdAt), Icons.access_time_outlined)),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildDetailRow('Admission Date', Formatters.formatDate(claim.admissionDate), Icons.calendar_today_outlined)),
          const SizedBox(width: 32),
          Expanded(
            child: claim.dischargeDate != null
                ? _buildDetailRow('Discharge Date', Formatters.formatDate(claim.dischargeDate!), Icons.event_available_outlined)
                : _buildDetailRow('Discharge Date', 'Not discharged', Icons.event_busy_outlined),
          ),
        ],
      ),
      if (claim.dischargeDate != null)
        Row(
          children: [
            Expanded(child: _buildDetailRow('Duration', '${claim.dischargeDate!.difference(claim.admissionDate).inDays} days', Icons.timelapse_outlined)),
            const SizedBox(width: 32),
            const Expanded(child: SizedBox()),
          ],
        ),
      if (claim.notes != null && claim.notes!.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _buildNotesSection(claim.notes!),
      ],
    ];
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes_outlined, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.zero,
          ),
          child: Text(
            notes,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillsTab(Claim claim, bool isMobile) {
    final billsAsync = ref.watch(billsStreamProvider(widget.claimId));

    return billsAsync.when(
      data: (bills) {
        if (bills.isEmpty) {
          return BillsEmptyState(
            canEdit: claim.isEditable,
            onAddBill: claim.isEditable ? () => _showAddBillDialog(claim) : null,
          );
        }
        return Column(
          children: [
            if (claim.isEditable)
              Padding(
                padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _showAddBillDialog(claim),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Bill'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                ),
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  return _buildBillCard(claim, bill, isMobile);
                },
              ),
            ),
            // Total bar
            Container(
              padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    Formatters.formatCurrency(claim.totalBillAmount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading bills...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(billsStreamProvider(widget.claimId)),
      ),
    );
  }

  Widget _buildBillCard(Claim claim, Bill bill, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              _getBillTypeIcon(bill.type),
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.typeLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (bill.description != null && bill.description!.isNotEmpty)
                  Text(
                    bill.description!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            Formatters.formatCurrency(bill.amount),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (claim.isEditable) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.edit_rounded, size: 16, color: AppColors.textSecondary),
              onPressed: () => _showEditBillDialog(claim, bill),
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, size: 16),
              onPressed: () => _showDeleteBillDialog(claim, bill),
              tooltip: 'Delete',
              color: AppColors.error,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getBillTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ROOM':
        return Icons.hotel_rounded;
      case 'MEDICINE':
        return Icons.medication_rounded;
      case 'SURGERY':
        return Icons.health_and_safety_rounded;
      case 'DIAGNOSTIC':
        return Icons.biotech_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  Widget _buildFinancialTab(Claim claim, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Financial Summary',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFinancialRow('Total Bill', claim.totalBillAmount, AppColors.primary),
                const Divider(height: 20),
                _buildFinancialRow('Advance Paid', claim.advancePaid, AppColors.textSecondary,
                    prefix: '(-) '),
                const SizedBox(height: 10),
                _buildFinancialRow(
                  'Approved',
                  claim.approvedAmount,
                  claim.approvedAmount > 0 ? AppColors.statusApproved : AppColors.textSecondary,
                ),
                const Divider(height: 20),
                _buildFinancialRow('Settled', claim.settledAmount, AppColors.secondary),
                const SizedBox(height: 10),
                _buildFinancialRow(
                  'Pending',
                  claim.pendingAmount,
                  claim.pendingAmount > 0 ? AppColors.statusPartiallySettled : AppColors.textSecondary,
                  isBold: true,
                ),
              ],
            ),
          ),
          if (claim.approvedAmount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settlement Progress',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (claim.settledAmount + claim.advancePaid) /
                          claim.approvedAmount,
                      backgroundColor: AppColors.border.withValues(alpha: 0.3),
                      color: AppColors.secondary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${Formatters.formatPercentage(Formatters.calculatePercentage(claim.settledAmount + claim.advancePaid, claim.approvedAmount))} Complete',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${Formatters.formatCurrency(claim.settledAmount + claim.advancePaid)} / ${Formatters.formatCurrency(claim.approvedAmount)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, double amount, Color color,
      {String prefix = '', bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '$prefix${Formatters.formatCurrency(amount)}',
            style: TextStyle(
              fontSize: isBold ? 18 : 15,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(Claim claim) {
    final auditLogsAsync = ref.watch(auditLogsStreamProvider(widget.claimId));

    return auditLogsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const AuditLogsEmptyState();
        }
        return ListView.builder(
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildAuditLogItem(log, isFirst: index == 0, isLast: index == logs.length - 1);
          },
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading history...'),
      error: (e, _) => AppErrorWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(auditLogsStreamProvider(widget.claimId)),
      ),
    );
  }

  Widget _buildAuditLogItem(AuditLog log, {bool isFirst = false, bool isLast = false}) {
    final actionColor = _getAuditActionColor(log.auditAction);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: actionColor, width: 2),
              ),
              child: isFirst
                  ? Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: actionColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 52,
                color: AppColors.border.withValues(alpha: 0.25),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          log.actionLabel,
                          style: TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.w600,
                            color: actionColor,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.formatRelativeTime(log.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (log.details != null && log.details!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      log.details!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'by ${log.performedByEmail ?? log.performedBy}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getAuditActionColor(AuditAction action) {
    switch (action) {
      case AuditAction.created:
        return AppColors.info;
      case AuditAction.updated:
        return AppColors.textSecondary;
      case AuditAction.submitted:
        return Colors.orange; // Custom for visibility
      case AuditAction.approved:
        return AppColors.statusApproved;
      case AuditAction.rejected:
        return AppColors.error;
      case AuditAction.settled:
        return AppColors.secondary;
      case AuditAction.billAdded:
      case AuditAction.billUpdated:
      case AuditAction.billDeleted:
        return Colors.blueGrey;
    }
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero, // Flat rectangular
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.zero, // Square
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog handlers
  void _showSubmitDialog(Claim claim) {
    showDialog(
      context: context,
      builder: (context) => SubmitClaimDialog(
        claim: claim,
        onConfirm: () async {
          setState(() => _isProcessing = true);
          try {
            final result = await ref.read(settlementRepositoryProvider).submitClaim(claim.id);
            if (mounted) {
              if (result.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message!),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.error!), backgroundColor: AppColors.error),
                );
              }
            }
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },
      ),
    );
  }

  void _showApproveDialog(Claim claim) {
    showDialog(
      context: context,
      builder: (context) => ApproveClaimDialog(
        claim: claim,
        onConfirm: (amount) async {
          setState(() => _isProcessing = true);
          try {
            final result = await ref.read(settlementRepositoryProvider).approveClaim(
                  claimId: claim.id,
                  approvedAmount: amount,
                );
            if (mounted) {
              if (result.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message!),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.error!), backgroundColor: AppColors.error),
                );
              }
            }
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },
      ),
    );
  }

  void _showRejectDialog(Claim claim) {
    showDialog(
      context: context,
      builder: (context) => RejectClaimDialog(
        claim: claim,
        onConfirm: (reason) async {
          setState(() => _isProcessing = true);
          try {
            final result = await ref.read(settlementRepositoryProvider).rejectClaim(
                  claimId: claim.id,
                  reason: reason,
                );
            if (mounted) {
              if (result.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message!),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.error!), backgroundColor: AppColors.error),
                );
              }
            }
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },
      ),
    );
  }

  void _showSettleDialog(Claim claim) {
    showDialog(
      context: context,
      builder: (context) => SettleClaimDialog(
        claim: claim,
        onConfirm: (amount) async {
          setState(() => _isProcessing = true);
          try {
            final result = await ref.read(settlementRepositoryProvider).processSettlement(
                  claimId: claim.id,
                  settlementAmount: amount,
                );
            if (mounted) {
              if (result.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message!),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.error!), backgroundColor: AppColors.error),
                );
              }
            }
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },
      ),
    );
  }

  void _showAddBillDialog(Claim claim) {
    showDialog(
      context: context,
      builder: (context) => BillFormDialog(
        claimId: claim.id,
        onSave: (type, amount, description) async {
          await ref.read(billRepositoryProvider).addBill(
                claimId: claim.id,
                type: type,
                amount: amount,
                description: description,
              );
        },
      ),
    );
  }

  void _showEditBillDialog(Claim claim, Bill bill) {
    showDialog(
      context: context,
      builder: (context) => BillFormDialog(
        claimId: claim.id,
        bill: bill,
        onSave: (type, amount, description) async {
          await ref.read(billRepositoryProvider).updateBill(
                claimId: claim.id,
                billId: bill.id,
                type: type,
                amount: amount,
                description: description,
              );
        },
      ),
    );
  }

  void _showDeleteBillDialog(Claim claim, Bill bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Bill', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text(
          'Delete ${bill.typeLabel} bill of ${Formatters.formatCurrency(bill.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(billRepositoryProvider).deleteBill(
                    claimId: claim.id,
                    billId: bill.id,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Bill deleted'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
