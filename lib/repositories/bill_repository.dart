import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/bill.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'claim_repository.dart';

/// Repository for managing bills within claims.
/// Bills are stored as a subcollection under each claim.
class BillRepository {
  final FirestoreService _firestoreService;
  final ClaimRepository _claimRepository;
  final String? _currentUserId;

  BillRepository({
    required FirestoreService firestoreService,
    required ClaimRepository claimRepository,
    String? currentUserId,
  })  : _firestoreService = firestoreService,
        _claimRepository = claimRepository,
        _currentUserId = currentUserId;

  /// Get all bills for a claim
  Future<List<Bill>> getBillsForClaim(String claimId) async {
    final snapshot = await _firestoreService.getSubcollection(
      parentCollection: AppConstants.claimsCollection,
      parentId: claimId,
      subcollection: AppConstants.billsSubcollection,
      queryBuilder: (query) => query.orderBy('createdAt', descending: true),
    );
    return snapshot.docs.map((doc) => Bill.fromFirestore(doc, claimId)).toList();
  }

  /// Stream all bills for a claim (real-time updates)
  Stream<List<Bill>> streamBillsForClaim(String claimId) {
    return _firestoreService
        .streamSubcollection(
          parentCollection: AppConstants.claimsCollection,
          parentId: claimId,
          subcollection: AppConstants.billsSubcollection,
          queryBuilder: (query) => query.orderBy('createdAt', descending: true),
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => Bill.fromFirestore(doc, claimId)).toList());
  }

  /// Add a new bill to a claim
  Future<String> addBill({
    required String claimId,
    required String type,
    required double amount,
    String? description,
  }) async {
    final now = DateTime.now();
    final data = {
      'type': type,
      'amount': amount,
      'description': description,
      'createdAt': Timestamp.fromDate(now),
      'createdBy': _currentUserId,
    };

    final docRef = await _firestoreService.addToSubcollection(
      parentCollection: AppConstants.claimsCollection,
      parentId: claimId,
      subcollection: AppConstants.billsSubcollection,
      data: data,
    );

    // Update total bill amount on the claim
    await _updateClaimTotal(claimId);

    return docRef.id;
  }

  /// Update an existing bill
  Future<void> updateBill({
    required String claimId,
    required String billId,
    String? type,
    double? amount,
    String? description,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (type != null) data['type'] = type;
    if (amount != null) data['amount'] = amount;
    if (description != null) data['description'] = description;

    await _firestoreService.updateSubcollectionDoc(
      parentCollection: AppConstants.claimsCollection,
      parentId: claimId,
      subcollection: AppConstants.billsSubcollection,
      documentId: billId,
      data: data,
    );

    // Update total bill amount on the claim
    await _updateClaimTotal(claimId);
  }

  /// Delete a bill from a claim
  Future<void> deleteBill({
    required String claimId,
    required String billId,
  }) async {
    await _firestoreService.deleteFromSubcollection(
      parentCollection: AppConstants.claimsCollection,
      parentId: claimId,
      subcollection: AppConstants.billsSubcollection,
      documentId: billId,
    );

    // Update total bill amount on the claim
    await _updateClaimTotal(claimId);
  }

  /// Calculate and update the total bill amount on the claim
  Future<void> _updateClaimTotal(String claimId) async {
    final bills = await getBillsForClaim(claimId);
    final total = bills.fold<double>(0, (sum, bill) => sum + bill.amount);
    await _claimRepository.updateTotalBillAmount(claimId, total);
  }

  /// Get total amount for bills of a specific type
  Future<double> getTotalByType(String claimId, String type) async {
    final bills = await getBillsForClaim(claimId);
    return bills
        .where((bill) => bill.type == type)
        .fold<double>(0, (sum, bill) => sum + bill.amount);
  }

  /// Get bill breakdown by type
  Future<Map<String, double>> getBillBreakdown(String claimId) async {
    final bills = await getBillsForClaim(claimId);
    final breakdown = <String, double>{};

    for (final bill in bills) {
      breakdown[bill.type] = (breakdown[bill.type] ?? 0) + bill.amount;
    }

    return breakdown;
  }
}

/// Provider for BillRepository
final billRepositoryProvider = Provider<BillRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final claimRepository = ref.watch(claimRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return BillRepository(
    firestoreService: firestoreService,
    claimRepository: claimRepository,
    currentUserId: currentUser?.uid,
  );
});

/// Provider for streaming bills of a specific claim
final billsStreamProvider = StreamProvider.family<List<Bill>, String>((ref, claimId) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.streamBillsForClaim(claimId);
});

/// Provider for bill breakdown by type
final billBreakdownProvider = FutureProvider.family<Map<String, double>, String>((ref, claimId) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.getBillBreakdown(claimId);
});
