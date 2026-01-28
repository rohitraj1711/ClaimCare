import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
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
        return _buildClaimDetailScaffold(claim);
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

  Widget _buildClaimDetailScaffold(Claim claim) {
    return LoadingOverlay(
      isLoading: _isProcessing,
      message: 'Processing...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Claim #${claim.id.substring(0, 8)}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
          actions: [
            if (claim.isEditable)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/claims/${claim.id}/edit'),
                tooltip: 'Edit claim',
              ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Bills'),
              Tab(text: 'Financial'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Status and actions bar
            _buildStatusActionsBar(claim),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(claim),
                  _buildBillsTab(claim),
                  _buildFinancialTab(claim),
                  _buildHistoryTab(claim),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActionsBar(Claim claim) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          StatusBadge(status: claim.status, large: true),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _getStatusMessage(claim),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Action buttons based on status
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
        ElevatedButton.icon(
          onPressed: () => _showSubmitDialog(claim),
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Submit'),
        ),
      );
    }

    if (claim.canApproveOrReject) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _showRejectDialog(claim),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Reject'),
        ),
      );
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        ElevatedButton.icon(
          onPressed: () => _showApproveDialog(claim),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusApproved,
          ),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Approve'),
        ),
      );
    }

    if (claim.canSettle) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () => _showSettleDialog(claim),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
          ),
          icon: const Icon(Icons.payments, size: 18),
          label: const Text('Settle'),
        ),
      );
    }

    return buttons;
  }

  Widget _buildOverviewTab(Claim claim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Information
          _buildInfoCard(
            title: 'Patient Information',
            icon: Icons.person_outline,
            children: [
              _buildInfoRow('Patient Name', claim.patientName),
              _buildInfoRow('Policy Number', claim.policyNumber),
            ],
          ),
          const SizedBox(height: 20),
          // Hospital Information
          _buildInfoCard(
            title: 'Hospital Information',
            icon: Icons.local_hospital_outlined,
            children: [
              _buildInfoRow('Hospital Name', claim.hospitalName),
            ],
          ),
          const SizedBox(height: 20),
          // Treatment Dates
          _buildInfoCard(
            title: 'Treatment Dates',
            icon: Icons.calendar_today_outlined,
            children: [
              _buildInfoRow('Admission Date', Formatters.formatDate(claim.admissionDate)),
              _buildInfoRow(
                'Discharge Date',
                claim.dischargeDate != null
                    ? Formatters.formatDate(claim.dischargeDate!)
                    : 'Not discharged',
              ),
              if (claim.dischargeDate != null)
                _buildInfoRow(
                  'Duration',
                  '${claim.dischargeDate!.difference(claim.admissionDate).inDays} days',
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Additional Info
          _buildInfoCard(
            title: 'Additional Information',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow('Claim ID', claim.id),
              _buildInfoRow('Created', Formatters.formatDateTime(claim.createdAt)),
              _buildInfoRow('Last Updated', Formatters.formatDateTime(claim.updatedAt)),
              if (claim.notes != null && claim.notes!.isNotEmpty)
                _buildInfoRow('Notes', claim.notes!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillsTab(Claim claim) {
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
            // Bills list header
            if (claim.isEditable)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAddBillDialog(claim),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Bill'),
                    ),
                  ],
                ),
              ),
            // Bills list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  return _buildBillCard(claim, bill);
                },
              ),
            ),
            // Total bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Bill Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(claim.totalBillAmount),
                    style: const TextStyle(
                      fontSize: 20,
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

  Widget _buildBillCard(Claim claim, Bill bill) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Bill type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getBillTypeIcon(bill.type),
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            // Bill details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.typeLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (bill.description != null && bill.description!.isNotEmpty)
                    Text(
                      bill.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // Amount
            Text(
              Formatters.formatCurrency(bill.amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Actions
            if (claim.isEditable) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showEditBillDialog(claim, bill),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                onPressed: () => _showDeleteBillDialog(claim, bill),
                tooltip: 'Delete',
                color: AppColors.error,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getBillTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ROOM':
        return Icons.hotel;
      case 'MEDICINE':
        return Icons.medication;
      case 'SURGERY':
        return Icons.health_and_safety;
      case 'DIAGNOSTIC':
        return Icons.biotech;
      default:
        return Icons.receipt;
    }
  }

  Widget _buildFinancialTab(Claim claim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Financial Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildFinancialRow(
                    'Total Bill Amount',
                    claim.totalBillAmount,
                    AppColors.primary,
                  ),
                  const Divider(height: 32),
                  _buildFinancialRow(
                    'Advance Paid',
                    claim.advancePaid,
                    AppColors.textSecondary,
                    prefix: '(-) ',
                  ),
                  const SizedBox(height: 16),
                  _buildFinancialRow(
                    'Approved Amount',
                    claim.approvedAmount,
                    claim.approvedAmount > 0 ? AppColors.statusApproved : AppColors.textSecondary,
                  ),
                  const Divider(height: 32),
                  _buildFinancialRow(
                    'Settled Amount',
                    claim.settledAmount,
                    AppColors.secondary,
                    showProgress: true,
                    progressValue: claim.approvedAmount > 0
                        ? claim.settledAmount / claim.approvedAmount
                        : 0,
                  ),
                  const SizedBox(height: 16),
                  _buildFinancialRow(
                    'Pending Amount',
                    claim.pendingAmount,
                    claim.pendingAmount > 0 ? AppColors.statusPartiallySettled : AppColors.textSecondary,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Settlement Progress
          if (claim.approvedAmount > 0)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settlement Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: claim.settledAmount / claim.approvedAmount,
                      backgroundColor: AppColors.border,
                      color: AppColors.secondary,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${Formatters.formatPercentage(Formatters.calculatePercentage(claim.settledAmount, claim.approvedAmount))} Settled',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${Formatters.formatCurrency(claim.settledAmount)} / ${Formatters.formatCurrency(claim.approvedAmount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    double amount,
    Color color, {
    String prefix = '',
    bool isBold = false,
    bool showProgress = false,
    double progressValue = 0,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '$prefix${Formatters.formatCurrency(amount)}',
          style: TextStyle(
            fontSize: isBold ? 20 : 16,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
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
          padding: const EdgeInsets.all(16),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst ? AppColors.primary : AppColors.border,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Log content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          log.actionLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          Formatters.formatRelativeTime(log.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (log.details != null && log.details!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        log.details!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'by ${log.performedByEmail ?? log.performedBy}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
                  SnackBar(content: Text(result.message!), backgroundColor: AppColors.success),
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
                  SnackBar(content: Text(result.message!), backgroundColor: AppColors.success),
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
                  SnackBar(content: Text(result.message!), backgroundColor: AppColors.success),
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
                  SnackBar(content: Text(result.message!), backgroundColor: AppColors.success),
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
        title: const Text('Delete Bill'),
        content: Text(
          'Are you sure you want to delete this ${bill.typeLabel} bill of ${Formatters.formatCurrency(bill.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(billRepositoryProvider).deleteBill(
                claimId: claim.id,
                billId: bill.id,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bill deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
