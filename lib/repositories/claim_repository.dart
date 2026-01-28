import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/claim.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

/// Repository for managing insurance claims.
/// Provides API-style abstraction for claim CRUD operations.
class ClaimRepository {
  final FirestoreService _firestoreService;
  final String? _currentUserId;

  ClaimRepository({
    required FirestoreService firestoreService,
    String? currentUserId,
  })  : _firestoreService = firestoreService,
        _currentUserId = currentUserId;

  /// Get all claims
  Future<List<Claim>> getAllClaims() async {
    final snapshot = await _firestoreService.getAll(
      collectionPath: AppConstants.claimsCollection,
      queryBuilder: (query) => query.orderBy('createdAt', descending: true),
    );
    return snapshot.docs.map((doc) => Claim.fromFirestore(doc)).toList();
  }

  /// Get claims filtered by status
  Future<List<Claim>> getClaimsByStatus(String status) async {
    final snapshot = await _firestoreService.getAll(
      collectionPath: AppConstants.claimsCollection,
      queryBuilder: (query) => query
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true),
    );
    return snapshot.docs.map((doc) => Claim.fromFirestore(doc)).toList();
  }

  /// Get a single claim by ID
  Future<Claim?> getClaimById(String claimId) async {
    final doc = await _firestoreService.get(
      collectionPath: AppConstants.claimsCollection,
      documentId: claimId,
    );
    if (!doc.exists) return null;
    return Claim.fromFirestore(doc);
  }

  /// Stream a single claim for real-time updates
  Stream<Claim?> streamClaim(String claimId) {
    return _firestoreService
        .streamDocument(
          collectionPath: AppConstants.claimsCollection,
          documentId: claimId,
        )
        .map((doc) => doc.exists ? Claim.fromFirestore(doc) : null);
  }

  /// Stream all claims for real-time updates
  Stream<List<Claim>> streamClaims({String? statusFilter}) {
    return _firestoreService
        .streamCollection(
          collectionPath: AppConstants.claimsCollection,
          queryBuilder: (query) {
            Query<Map<String, dynamic>> q = query;
            if (statusFilter != null && statusFilter.isNotEmpty) {
              q = q.where('status', isEqualTo: statusFilter);
            }
            return q.orderBy('createdAt', descending: true);
          },
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => Claim.fromFirestore(doc)).toList());
  }

  /// Create a new claim
  Future<String> createClaim({
    required String patientName,
    required String policyNumber,
    required String hospitalName,
    required DateTime admissionDate,
    DateTime? dischargeDate,
    double advancePaid = 0,
    String? notes,
  }) async {
    final now = DateTime.now();
    final data = {
      'patientName': patientName,
      'policyNumber': policyNumber,
      'hospitalName': hospitalName,
      'admissionDate': Timestamp.fromDate(admissionDate),
      'dischargeDate':
          dischargeDate != null ? Timestamp.fromDate(dischargeDate) : null,
      'status': ClaimStatus.draft.value,
      'totalBillAmount': 0.0,
      'approvedAmount': 0.0,
      'advancePaid': advancePaid,
      'settledAmount': 0.0,
      'pendingAmount': 0.0,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'createdBy': _currentUserId,
      'updatedBy': _currentUserId,
      'notes': notes,
    };

    final docRef = await _firestoreService.create(
      collectionPath: AppConstants.claimsCollection,
      data: data,
    );

    // Create audit log entry
    await _createAuditLog(
      claimId: docRef.id,
      action: AuditAction.created.value,
      details: 'Claim created for patient: $patientName',
    );

    return docRef.id;
  }

  /// Update a claim (only allowed for DRAFT status)
  Future<void> updateClaim({
    required String claimId,
    String? patientName,
    String? policyNumber,
    String? hospitalName,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    double? advancePaid,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updatedBy': _currentUserId,
    };

    if (patientName != null) data['patientName'] = patientName;
    if (policyNumber != null) data['policyNumber'] = policyNumber;
    if (hospitalName != null) data['hospitalName'] = hospitalName;
    if (admissionDate != null) {
      data['admissionDate'] = Timestamp.fromDate(admissionDate);
    }
    if (dischargeDate != null) {
      data['dischargeDate'] = Timestamp.fromDate(dischargeDate);
    }
    if (advancePaid != null) data['advancePaid'] = advancePaid;
    if (notes != null) data['notes'] = notes;

    await _firestoreService.update(
      collectionPath: AppConstants.claimsCollection,
      documentId: claimId,
      data: data,
    );

    await _createAuditLog(
      claimId: claimId,
      action: AuditAction.updated.value,
      details: 'Claim details updated',
    );
  }

  /// Update total bill amount (called when bills are added/removed)
  Future<void> updateTotalBillAmount(String claimId, double amount) async {
    await _firestoreService.update(
      collectionPath: AppConstants.claimsCollection,
      documentId: claimId,
      data: {
        'totalBillAmount': amount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
    );
  }

  /// Delete a claim (only allowed for DRAFT status)
  Future<void> deleteClaim(String claimId) async {
    // Delete all bills first
    final billsSnapshot = await _firestoreService.getSubcollection(
      parentCollection: AppConstants.claimsCollection,
      parentId: claimId,
      subcollection: AppConstants.billsSubcollection,
    );

    for (final doc in billsSnapshot.docs) {
      await _firestoreService.deleteFromSubcollection(
        parentCollection: AppConstants.claimsCollection,
        parentId: claimId,
        subcollection: AppConstants.billsSubcollection,
        documentId: doc.id,
      );
    }

    // Delete the claim
    await _firestoreService.delete(
      collectionPath: AppConstants.claimsCollection,
      documentId: claimId,
    );
  }

  /// Get dashboard summary statistics
  Future<ClaimsSummary> getClaimsSummary() async {
    final claims = await getAllClaims();

    double totalApproved = 0;
    double totalSettled = 0;
    double totalPending = 0;
    int draftCount = 0;
    int submittedCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;
    int partiallySettledCount = 0;

    for (final claim in claims) {
      totalApproved += claim.approvedAmount;
      totalSettled += claim.settledAmount;
      totalPending += claim.pendingAmount;

      switch (claim.status.toUpperCase()) {
        case 'DRAFT':
          draftCount++;
          break;
        case 'SUBMITTED':
          submittedCount++;
          break;
        case 'APPROVED':
          approvedCount++;
          break;
        case 'REJECTED':
          rejectedCount++;
          break;
        case 'PARTIALLY_SETTLED':
          partiallySettledCount++;
          break;
      }
    }

    return ClaimsSummary(
      totalClaims: claims.length,
      totalApprovedAmount: totalApproved,
      totalSettledAmount: totalSettled,
      totalPendingAmount: totalPending,
      draftCount: draftCount,
      submittedCount: submittedCount,
      approvedCount: approvedCount,
      rejectedCount: rejectedCount,
      partiallySettledCount: partiallySettledCount,
    );
  }

  /// Create an audit log entry
  Future<void> _createAuditLog({
    required String claimId,
    required String action,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    await _firestoreService.addToSubcollection(
      parentCollection: AppConstants.claimsCollection,
      parentId: claimId,
      subcollection: AppConstants.auditLogsSubcollection,
      data: {
        'action': action,
        'details': details,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'performedBy': _currentUserId ?? 'system',
      },
    );
  }
}

/// Summary statistics for claims dashboard
class ClaimsSummary {
  final int totalClaims;
  final double totalApprovedAmount;
  final double totalSettledAmount;
  final double totalPendingAmount;
  final int draftCount;
  final int submittedCount;
  final int approvedCount;
  final int rejectedCount;
  final int partiallySettledCount;

  ClaimsSummary({
    required this.totalClaims,
    required this.totalApprovedAmount,
    required this.totalSettledAmount,
    required this.totalPendingAmount,
    required this.draftCount,
    required this.submittedCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.partiallySettledCount,
  });
}

/// Provider for ClaimRepository
final claimRepositoryProvider = Provider<ClaimRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  return ClaimRepository(
    firestoreService: firestoreService,
    currentUserId: currentUser?.uid,
  );
});

/// Provider for streaming all claims
final claimsStreamProvider = StreamProvider.family<List<Claim>, String?>((ref, statusFilter) {
  final repository = ref.watch(claimRepositoryProvider);
  return repository.streamClaims(statusFilter: statusFilter);
});

/// Provider for streaming a single claim
final claimStreamProvider = StreamProvider.family<Claim?, String>((ref, claimId) {
  final repository = ref.watch(claimRepositoryProvider);
  return repository.streamClaim(claimId);
});

/// Provider for claims summary
final claimsSummaryProvider = FutureProvider<ClaimsSummary>((ref) {
  final repository = ref.watch(claimRepositoryProvider);
  return repository.getClaimsSummary();
});
