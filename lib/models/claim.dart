import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Claim model representing an insurance claim in the system.
class Claim {
  final String id;
  final String patientName;
  final String policyNumber;
  final String hospitalName;
  final DateTime admissionDate;
  final DateTime? dischargeDate;
  final String status;
  final double totalBillAmount;
  final double approvedAmount;
  final double advancePaid;
  final double settledAmount;
  final double pendingAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? rejectionReason;
  final String? notes;

  const Claim({
    required this.id,
    required this.patientName,
    required this.policyNumber,
    required this.hospitalName,
    required this.admissionDate,
    this.dischargeDate,
    this.status = 'DRAFT',
    this.totalBillAmount = 0.0,
    this.approvedAmount = 0.0,
    this.advancePaid = 0.0,
    this.settledAmount = 0.0,
    this.pendingAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.rejectionReason,
    this.notes,
  });

  /// Create a Claim from Firestore document
  factory Claim.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Claim(
      id: doc.id,
      patientName: data['patientName'] ?? '',
      policyNumber: data['policyNumber'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      admissionDate: (data['admissionDate'] as Timestamp).toDate(),
      dischargeDate: data['dischargeDate'] != null 
          ? (data['dischargeDate'] as Timestamp).toDate() 
          : null,
      status: data['status'] ?? 'DRAFT',
      totalBillAmount: (data['totalBillAmount'] ?? 0).toDouble(),
      approvedAmount: (data['approvedAmount'] ?? 0).toDouble(),
      advancePaid: (data['advancePaid'] ?? 0).toDouble(),
      settledAmount: (data['settledAmount'] ?? 0).toDouble(),
      pendingAmount: (data['pendingAmount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      updatedBy: data['updatedBy'],
      rejectionReason: data['rejectionReason'],
      notes: data['notes'],
    );
  }

  /// Convert Claim to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'patientName': patientName,
      'policyNumber': policyNumber,
      'hospitalName': hospitalName,
      'admissionDate': Timestamp.fromDate(admissionDate),
      'dischargeDate': dischargeDate != null 
          ? Timestamp.fromDate(dischargeDate!) 
          : null,
      'status': status,
      'totalBillAmount': totalBillAmount,
      'approvedAmount': approvedAmount,
      'advancePaid': advancePaid,
      'settledAmount': settledAmount,
      'pendingAmount': pendingAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'rejectionReason': rejectionReason,
      'notes': notes,
    };
  }

  /// Get ClaimStatus enum from status string
  ClaimStatus get claimStatus => ClaimStatus.fromString(status);

  /// Check if the claim can be edited (only in DRAFT status)
  bool get isEditable => claimStatus.isEditable;

  /// Check if the claim can be submitted
  bool get canSubmit => claimStatus.canSubmit && totalBillAmount > 0;

  /// Check if the claim can be approved or rejected
  bool get canApproveOrReject => claimStatus.canApproveOrReject;

  /// Check if the claim can be settled
  bool get canSettle => claimStatus.canSettle && pendingAmount > 0;

  /// Get remaining amount to settle
  double get remainingToSettle => approvedAmount - settledAmount;

  /// Get status display label
  String get statusLabel => claimStatus.label;

  /// CopyWith method for immutability
  Claim copyWith({
    String? id,
    String? patientName,
    String? policyNumber,
    String? hospitalName,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    String? status,
    double? totalBillAmount,
    double? approvedAmount,
    double? advancePaid,
    double? settledAmount,
    double? pendingAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? rejectionReason,
    String? notes,
  }) {
    return Claim(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      policyNumber: policyNumber ?? this.policyNumber,
      hospitalName: hospitalName ?? this.hospitalName,
      admissionDate: admissionDate ?? this.admissionDate,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      status: status ?? this.status,
      totalBillAmount: totalBillAmount ?? this.totalBillAmount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      advancePaid: advancePaid ?? this.advancePaid,
      settledAmount: settledAmount ?? this.settledAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
    );
  }
}

/// Empty claim for initialization
Claim emptyClaim() => Claim(
  id: '',
  patientName: '',
  policyNumber: '',
  hospitalName: '',
  admissionDate: DateTime.now(),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
