import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Audit log model for tracking claim actions.
class AuditLog {
  final String id;
  final String claimId;
  final String action;
  final DateTime timestamp;
  final String performedBy;
  final String? performedByEmail;
  final String? details;

  const AuditLog({
    required this.id,
    required this.claimId,
    required this.action,
    required this.timestamp,
    required this.performedBy,
    this.performedByEmail,
    this.details,
  });

  /// Create an AuditLog from Firestore document
  factory AuditLog.fromFirestore(DocumentSnapshot doc, String claimId) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      claimId: claimId,
      action: data['action'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      performedBy: data['performedBy'] ?? '',
      performedByEmail: data['performedByEmail'],
      details: data['details'],
    );
  }

  /// Get AuditAction enum from action string
  AuditAction get auditAction => AuditAction.fromString(action);

  /// Get action display label
  String get actionLabel => auditAction.label;

  /// CopyWith method for immutability
  AuditLog copyWith({
    String? id,
    String? claimId,
    String? action,
    DateTime? timestamp,
    String? performedBy,
    String? performedByEmail,
    String? details,
  }) {
    return AuditLog(
      id: id ?? this.id,
      claimId: claimId ?? this.claimId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      performedBy: performedBy ?? this.performedBy,
      performedByEmail: performedByEmail ?? this.performedByEmail,
      details: details ?? this.details,
    );
  }
}
