import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../models/claim.dart';

/// Dialog for confirming claim submission.
class SubmitClaimDialog extends StatelessWidget {
  final Claim claim;
  final VoidCallback onConfirm;

  const SubmitClaimDialog({
    super.key,
    required this.claim,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.send, color: AppColors.primary),
          SizedBox(width: 12),
          Text('Submit Claim'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to submit this claim for review?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Patient', claim.patientName),
                _buildInfoRow('Policy', claim.policyNumber),
                _buildInfoRow('Total Amount', Formatters.formatCurrency(claim.totalBillAmount)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Once submitted, you cannot edit the claim details.',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Submit Claim'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Dialog for approving a claim with amount input.
class ApproveClaimDialog extends StatefulWidget {
  final Claim claim;
  final Function(double amount) onConfirm;

  const ApproveClaimDialog({
    super.key,
    required this.claim,
    required this.onConfirm,
  });

  @override
  State<ApproveClaimDialog> createState() => _ApproveClaimDialogState();
}

class _ApproveClaimDialogState extends State<ApproveClaimDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.claim.totalBillAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.statusApproved),
          SizedBox(width: 12),
          Text('Approve Claim'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approve claim for ${widget.claim.patientName}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Bill Amount', style: TextStyle(fontSize: 13)),
                  Text(
                    Formatters.formatCurrency(widget.claim.totalBillAmount),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: (value) => Validators.validateApprovalAmount(
                value,
                widget.claim.totalBillAmount,
              ),
              decoration: const InputDecoration(
                labelText: 'Approved Amount (₹) *',
                prefixText: '₹ ',
                helperText: 'Cannot exceed total bill amount',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text.replaceAll(',', ''));
              Navigator.pop(context);
              widget.onConfirm(amount);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusApproved),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}

/// Dialog for rejecting a claim with reason input.
class RejectClaimDialog extends StatefulWidget {
  final Claim claim;
  final Function(String reason) onConfirm;

  const RejectClaimDialog({
    super.key,
    required this.claim,
    required this.onConfirm,
  });

  @override
  State<RejectClaimDialog> createState() => _RejectClaimDialogState();
}

class _RejectClaimDialogState extends State<RejectClaimDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cancel, color: AppColors.error),
          SizedBox(width: 12),
          Text('Reject Claim'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject claim for ${widget.claim.patientName}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action will reset all financial fields.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _reasonController,
              validator: Validators.validateRejectionReason,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'Please provide a detailed reason for rejection...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              widget.onConfirm(_reasonController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Reject Claim'),
        ),
      ],
    );
  }
}

/// Dialog for processing claim settlement.
class SettleClaimDialog extends StatefulWidget {
  final Claim claim;
  final Function(double amount) onConfirm;

  const SettleClaimDialog({
    super.key,
    required this.claim,
    required this.onConfirm,
  });

  @override
  State<SettleClaimDialog> createState() => _SettleClaimDialogState();
}

class _SettleClaimDialogState extends State<SettleClaimDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.claim.remainingToSettle.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.payments, color: AppColors.secondary),
          SizedBox(width: 12),
          Text('Process Settlement'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Process settlement for ${widget.claim.patientName}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Approved Amount', Formatters.formatCurrency(widget.claim.approvedAmount)),
                  _buildInfoRow('Already Settled', Formatters.formatCurrency(widget.claim.settledAmount)),
                  const Divider(height: 16),
                  _buildInfoRow(
                    'Pending Amount',
                    Formatters.formatCurrency(widget.claim.remainingToSettle),
                    valueColor: AppColors.statusPartiallySettled,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: (value) => Validators.validateSettlementAmount(
                value,
                widget.claim.remainingToSettle,
              ),
              decoration: InputDecoration(
                labelText: 'Settlement Amount (₹) *',
                prefixText: '₹ ',
                helperText: 'Max: ${Formatters.formatCurrency(widget.claim.remainingToSettle)}',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text.replaceAll(',', ''));
              Navigator.pop(context);
              widget.onConfirm(amount);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: const Text('Process Settlement'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
