import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../models/bill.dart';

/// Dialog for adding or editing a bill.
class BillFormDialog extends StatefulWidget {
  final String claimId;
  final Bill? bill;
  final Future<void> Function(String type, double amount, String? description) onSave;

  const BillFormDialog({
    super.key,
    required this.claimId,
    this.bill,
    required this.onSave,
  });

  @override
  State<BillFormDialog> createState() => _BillFormDialogState();
}

class _BillFormDialogState extends State<BillFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  bool _isSaving = false;

  bool get isEditing => widget.bill != null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.bill?.type ?? BillType.room.value;
    _amountController = TextEditingController(
      text: widget.bill?.amount.toStringAsFixed(2) ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.bill?.description ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final description = _descriptionController.text.trim();

      await widget.onSave(
        _selectedType,
        amount,
        description.isNotEmpty ? description : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Bill updated' : 'Bill added'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.add_circle,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(isEditing ? 'Edit Bill' : 'Add Bill'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bill type dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Bill Type *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: BillType.values.map((type) {
                  return DropdownMenuItem(
                    value: type.value,
                    child: Row(
                      children: [
                        Icon(_getBillTypeIcon(type.value), size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(type.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: Validators.validateAmount,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 20),
              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'E.g., Room charges for 3 days',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? 'Update' : 'Add Bill'),
        ),
      ],
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
}
