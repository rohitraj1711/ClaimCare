import '../constants/app_constants.dart';

/// Utility class for input validation.
class Validators {
  Validators._();

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate patient name
  static String? validatePatientName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Patient name is required';
    }
    if (value.length < AppConstants.minPatientNameLength) {
      return 'Name must be at least ${AppConstants.minPatientNameLength} characters';
    }
    if (value.length > AppConstants.maxPatientNameLength) {
      return 'Name must be less than ${AppConstants.maxPatientNameLength} characters';
    }
    return null;
  }

  /// Validate policy number
  static String? validatePolicyNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Policy number is required';
    }
    // Allow alphanumeric policy numbers
    final policyRegex = RegExp(r'^[A-Za-z0-9-]+$');
    if (!policyRegex.hasMatch(value)) {
      return 'Policy number can only contain letters, numbers, and hyphens';
    }
    return null;
  }

  /// Validate hospital name
  static String? validateHospitalName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Hospital name is required';
    }
    if (value.length < 2) {
      return 'Hospital name is too short';
    }
    return null;
  }

  /// Validate amount
  static String? validateAmount(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount < (min ?? AppConstants.minBillAmount)) {
      return 'Amount must be at least ${min ?? AppConstants.minBillAmount}';
    }
    if (amount > (max ?? AppConstants.maxBillAmount)) {
      return 'Amount exceeds maximum allowed value';
    }
    return null;
  }

  /// Validate date is not in future
  static String? validatePastDate(DateTime? value, [String fieldName = 'Date']) {
    if (value == null) {
      return '$fieldName is required';
    }
    if (value.isAfter(DateTime.now())) {
      return '$fieldName cannot be in the future';
    }
    return null;
  }

  /// Validate discharge date is after admission date
  static String? validateDischargeDate(DateTime? discharge, DateTime? admission) {
    if (discharge == null) {
      return null; // Discharge date is optional
    }
    if (admission == null) {
      return 'Please set admission date first';
    }
    if (discharge.isBefore(admission)) {
      return 'Discharge date must be after admission date';
    }
    return null;
  }

  /// Validate settlement amount
  static String? validateSettlementAmount(String? value, double maxAmount) {
    final baseValidation = validateAmount(value, min: 0.01, max: maxAmount);
    if (baseValidation != null) return baseValidation;
    
    final amount = double.parse(value!.replaceAll(',', ''));
    if (amount > maxAmount) {
      return 'Settlement cannot exceed pending amount';
    }
    return null;
  }

  /// Validate approval amount
  static String? validateApprovalAmount(String? value, double totalBillAmount) {
    final baseValidation = validateAmount(value, min: 0.01);
    if (baseValidation != null) return baseValidation;
    
    final amount = double.parse(value!.replaceAll(',', ''));
    if (amount > totalBillAmount) {
      return 'Approved amount cannot exceed total bill amount';
    }
    return null;
  }

  /// Validate rejection reason
  static String? validateRejectionReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a reason for rejection';
    }
    if (value.length < 10) {
      return 'Please provide a more detailed reason';
    }
    return null;
  }
}
