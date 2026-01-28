import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../models/claim.dart';
import '../../../repositories/claim_repository.dart';

/// Screen for creating or editing an insurance claim.
class ClaimFormScreen extends ConsumerStatefulWidget {
  final String? claimId;

  const ClaimFormScreen({super.key, this.claimId});

  @override
  ConsumerState<ClaimFormScreen> createState() => _ClaimFormScreenState();
}

class _ClaimFormScreenState extends ConsumerState<ClaimFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _policyNumberController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _advancePaidController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  DateTime _admissionDate = DateTime.now();
  DateTime? _dischargeDate;
  bool _isLoading = false;
  bool _isSaving = false;
  Claim? _existingClaim;

  bool get isEditing => widget.claimId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadClaim();
    }
  }

  Future<void> _loadClaim() async {
    setState(() => _isLoading = true);
    try {
      final claim = await ref.read(claimRepositoryProvider).getClaimById(widget.claimId!);
      if (claim != null && mounted) {
        setState(() {
          _existingClaim = claim;
          _patientNameController.text = claim.patientName;
          _policyNumberController.text = claim.policyNumber;
          _hospitalNameController.text = claim.hospitalName;
          _advancePaidController.text = claim.advancePaid.toString();
          _notesController.text = claim.notes ?? '';
          _admissionDate = claim.admissionDate;
          _dischargeDate = claim.dischargeDate;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading claim: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _policyNumberController.dispose();
    _hospitalNameController.dispose();
    _advancePaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(claimRepositoryProvider);

      if (isEditing) {
        await repository.updateClaim(
          claimId: widget.claimId!,
          patientName: _patientNameController.text.trim(),
          policyNumber: _policyNumberController.text.trim(),
          hospitalName: _hospitalNameController.text.trim(),
          admissionDate: _admissionDate,
          dischargeDate: _dischargeDate,
          advancePaid: double.tryParse(_advancePaidController.text) ?? 0,
          notes: _notesController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Claim updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/claims/${widget.claimId}');
        }
      } else {
        final claimId = await repository.createClaim(
          patientName: _patientNameController.text.trim(),
          policyNumber: _policyNumberController.text.trim(),
          hospitalName: _hospitalNameController.text.trim(),
          admissionDate: _admissionDate,
          dischargeDate: _dischargeDate,
          advancePaid: double.tryParse(_advancePaidController.text) ?? 0,
          notes: _notesController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Claim created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/claims/$claimId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving claim: $e'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Claim' : 'New Claim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isEditing) {
              context.go('/claims/${widget.claimId}');
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          if (isEditing && _existingClaim != null && !_existingClaim!.isEditable)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Read-only',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Loading claim...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Information Card
                    _buildSectionCard(
                      title: 'Patient Information',
                      icon: Icons.person_outline,
                      children: [
                        TextFormField(
                          controller: _patientNameController,
                          validator: Validators.validatePatientName,
                          enabled: !isEditing || (_existingClaim?.isEditable ?? true),
                          decoration: const InputDecoration(
                            labelText: 'Patient Name *',
                            hintText: 'Enter patient\'s full name',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _policyNumberController,
                          validator: Validators.validatePolicyNumber,
                          enabled: !isEditing || (_existingClaim?.isEditable ?? true),
                          decoration: const InputDecoration(
                            labelText: 'Policy Number *',
                            hintText: 'Enter insurance policy number',
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Hospital Information Card
                    _buildSectionCard(
                      title: 'Hospital Information',
                      icon: Icons.local_hospital_outlined,
                      children: [
                        TextFormField(
                          controller: _hospitalNameController,
                          validator: Validators.validateHospitalName,
                          enabled: !isEditing || (_existingClaim?.isEditable ?? true),
                          decoration: const InputDecoration(
                            labelText: 'Hospital Name *',
                            hintText: 'Enter hospital name',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Dates Card
                    _buildSectionCard(
                      title: 'Treatment Dates',
                      icon: Icons.calendar_today_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                label: 'Admission Date *',
                                value: _admissionDate,
                                enabled: !isEditing || (_existingClaim?.isEditable ?? true),
                                onSelect: (date) {
                                  setState(() {
                                    _admissionDate = date;
                                    // Reset discharge date if it's before admission
                                    if (_dischargeDate != null &&
                                        _dischargeDate!.isBefore(date)) {
                                      _dischargeDate = null;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildDateField(
                                label: 'Discharge Date',
                                value: _dischargeDate,
                                enabled: !isEditing || (_existingClaim?.isEditable ?? true),
                                hint: 'Select date',
                                firstDate: _admissionDate,
                                onSelect: (date) {
                                  setState(() => _dischargeDate = date);
                                },
                                onClear: () {
                                  setState(() => _dischargeDate = null);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Financial Information Card
                    _buildSectionCard(
                      title: 'Financial Information',
                      icon: Icons.payments_outlined,
                      children: [
                        TextFormField(
                          controller: _advancePaidController,
                          validator: (value) => Validators.validateAmount(value, min: 0),
                          enabled: !isEditing || (_existingClaim?.isEditable ?? true),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Advance Paid (₹)',
                            hintText: '0',
                            prefixText: '₹ ',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Additional Notes Card
                    _buildSectionCard(
                      title: 'Additional Notes',
                      icon: Icons.notes_outlined,
                      children: [
                        TextFormField(
                          controller: _notesController,
                          enabled: !isEditing || (_existingClaim?.isEditable ?? true),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            hintText: 'Add any additional information...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    if (!isEditing || (_existingClaim?.isEditable ?? true))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    if (isEditing) {
                                      context.go('/claims/${widget.claimId}');
                                    } else {
                                      context.go('/dashboard');
                                    }
                                  },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveClaim,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _isSaving
                                  ? 'Saving...'
                                  : (isEditing ? 'Update Claim' : 'Create Claim'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
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
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required bool enabled,
    required Function(DateTime) onSelect,
    String? hint,
    DateTime? firstDate,
    VoidCallback? onClear,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return InkWell(
      onTap: enabled
          ? () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                onSelect(date);
              }
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null && onClear != null && enabled
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today, size: 18),
          enabled: enabled,
        ),
        child: Text(
          value != null ? dateFormat.format(value) : (hint ?? 'Select date'),
          style: TextStyle(
            color: value != null
                ? AppColors.textPrimary
                : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
