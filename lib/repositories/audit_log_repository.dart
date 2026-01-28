import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/audit_log.dart';
import '../services/firestore_service.dart';

/// Repository for managing audit logs.
/// Provides read-only access to claim audit history.
class AuditLogRepository {
  final FirestoreService _firestoreService;

  AuditLogRepository({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Get all audit logs for a claim
  Future<List<AuditLog>> getAuditLogsForClaim(String claimId) async {
    final snapshot = await _firestoreService.getSubcollection(
      parentCollection: AppConstants.claimsCollection,
      parentId: claimId,
      subcollection: AppConstants.auditLogsSubcollection,
      queryBuilder: (query) => query.orderBy('timestamp', descending: true),
    );
    return snapshot.docs
        .map((doc) => AuditLog.fromFirestore(doc, claimId))
        .toList();
  }

  /// Stream audit logs for a claim (real-time updates)
  Stream<List<AuditLog>> streamAuditLogsForClaim(String claimId) {
    return _firestoreService
        .streamSubcollection(
          parentCollection: AppConstants.claimsCollection,
          parentId: claimId,
          subcollection: AppConstants.auditLogsSubcollection,
          queryBuilder: (query) => query.orderBy('timestamp', descending: true),
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLog.fromFirestore(doc, claimId))
            .toList());
  }

  /// Get the most recent audit log for a claim
  Future<AuditLog?> getLatestAuditLog(String claimId) async {
    final snapshot = await _firestoreService.getSubcollection(
      parentCollection: AppConstants.claimsCollection,
      parentId: claimId,
      subcollection: AppConstants.auditLogsSubcollection,
      queryBuilder: (query) =>
          query.orderBy('timestamp', descending: true).limit(1),
    );
    if (snapshot.docs.isEmpty) return null;
    return AuditLog.fromFirestore(snapshot.docs.first, claimId);
  }
}

/// Provider for AuditLogRepository
final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AuditLogRepository(firestoreService: firestoreService);
});

/// Provider for streaming audit logs of a specific claim
final auditLogsStreamProvider =
    StreamProvider.family<List<AuditLog>, String>((ref, claimId) {
  final repository = ref.watch(auditLogRepositoryProvider);
  return repository.streamAuditLogsForClaim(claimId);
});
