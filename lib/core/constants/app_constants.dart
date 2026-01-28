/// Application-wide constants for the Insurance Claim Management System.
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'ClaimCare';
  static const String appTagline = 'Insurance Claim Management System';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String claimsCollection = 'claims';
  static const String billsSubcollection = 'bills';
  static const String auditLogsSubcollection = 'audit_logs';
  static const String usersCollection = 'users';

  // Cloud Function names
  static const String submitClaimFunction = 'submitClaim';
  static const String approveClaimFunction = 'approveClaim';
  static const String rejectClaimFunction = 'rejectClaim';
  static const String settleClaimFunction = 'settleClaim';

  // Validation rules
  static const int minPatientNameLength = 2;
  static const int maxPatientNameLength = 100;
  static const int policyNumberLength = 10;
  static const double maxBillAmount = 99999999.99;
  static const double minBillAmount = 0.01;

  // UI constants
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double inputBorderRadius = 8.0;
  static const double dialogBorderRadius = 16.0;
  
  static const double cardElevation = 1.0;
  static const double dialogElevation = 8.0;

  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Date formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, HH:mm';
  static const String shortDateFormat = 'dd/MM/yyyy';

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const String currencyLocale = 'en_IN';
}

/// Claim status enum with display labels
enum ClaimStatus {
  draft('DRAFT', 'Draft'),
  submitted('SUBMITTED', 'Submitted'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected'),
  partiallySettled('PARTIALLY_SETTLED', 'Partially Settled');

  final String value;
  final String label;

  const ClaimStatus(this.value, this.label);

  static ClaimStatus fromString(String value) {
    return ClaimStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => ClaimStatus.draft,
    );
  }

  /// Check if claim can be edited (only in draft status)
  bool get isEditable => this == ClaimStatus.draft;

  /// Check if claim can be submitted
  bool get canSubmit => this == ClaimStatus.draft;

  /// Check if claim can be approved or rejected
  bool get canApproveOrReject => this == ClaimStatus.submitted;

  /// Check if claim can be settled
  bool get canSettle => this == ClaimStatus.approved || this == ClaimStatus.partiallySettled;
}

/// Bill type enum with display labels
enum BillType {
  room('ROOM', 'Room Charges'),
  medicine('MEDICINE', 'Medicine'),
  surgery('SURGERY', 'Surgery'),
  diagnostic('DIAGNOSTIC', 'Diagnostic Tests');

  final String value;
  final String label;

  const BillType(this.value, this.label);

  static BillType fromString(String value) {
    return BillType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => BillType.room,
    );
  }
}

/// Audit action types
enum AuditAction {
  created('CREATED', 'Claim Created'),
  updated('UPDATED', 'Claim Updated'),
  submitted('SUBMITTED', 'Claim Submitted'),
  approved('APPROVED', 'Claim Approved'),
  rejected('REJECTED', 'Claim Rejected'),
  settled('SETTLED', 'Settlement Made'),
  billAdded('BILL_ADDED', 'Bill Added'),
  billUpdated('BILL_UPDATED', 'Bill Updated'),
  billDeleted('BILL_DELETED', 'Bill Deleted');

  final String value;
  final String label;

  const AuditAction(this.value, this.label);

  static AuditAction fromString(String value) {
    return AuditAction.values.firstWhere(
      (action) => action.value == value.toUpperCase(),
      orElse: () => AuditAction.updated,
    );
  }
}
