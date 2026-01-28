import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

/// Service for handling claim status transitions directly via Firestore.
/// This is used when Cloud Functions are not deployed.
class ClaimStatusService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ClaimStatusService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Submit a claim for review
  /// Transitions claim from DRAFT to SUBMITTED status
  Future<StatusResult> submitClaim(String claimId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return StatusResult.failure(error: 'You must be logged in.');
      }

      final claimRef = _firestore.collection(AppConstants.claimsCollection).doc(claimId);
      final claim = await claimRef.get();
      
      if (!claim.exists) {
        return StatusResult.failure(error: 'Claim not found.');
      }

      final data = claim.data()!;
      if (data['status'] != ClaimStatus.draft.value) {
        return StatusResult.failure(error: 'Only draft claims can be submitted.');
      }

      // Update claim status
      await claimRef.update({
        'status': ClaimStatus.submitted.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create audit log
      await claimRef.collection(AppConstants.auditLogsSubcollection).add({
        'action': AuditAction.submitted.value,
        'performedBy': user.uid,
        'performedByEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'details': 'Claim submitted for review',
      });

      return StatusResult.success(message: 'Claim submitted successfully!');
    } catch (e) {
      return StatusResult.failure(error: 'Failed to submit claim: ${e.toString()}');
    }
  }

  /// Approve a claim with specified amount
  Future<StatusResult> approveClaim({
    required String claimId,
    required double approvedAmount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return StatusResult.failure(error: 'You must be logged in.');
      }

      final claimRef = _firestore.collection(AppConstants.claimsCollection).doc(claimId);
      final claim = await claimRef.get();
      
      if (!claim.exists) {
        return StatusResult.failure(error: 'Claim not found.');
      }

      final data = claim.data()!;
      if (data['status'] != ClaimStatus.submitted.value) {
        return StatusResult.failure(error: 'Only submitted claims can be approved.');
      }

      // Get total bill amount
      final totalBillAmount = (data['totalBillAmount'] ?? 0).toDouble();
      if (approvedAmount > totalBillAmount) {
        return StatusResult.failure(error: 'Approved amount cannot exceed total bill.');
      }

      // Calculate pending amount
      final advancePaid = (data['advancePaid'] ?? 0).toDouble();
      final pendingAmount = approvedAmount - advancePaid;

      // Update claim
      await claimRef.update({
        'status': ClaimStatus.approved.value,
        'approvedAmount': approvedAmount,
        'pendingAmount': pendingAmount > 0 ? pendingAmount : 0,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create audit log
      await claimRef.collection(AppConstants.auditLogsSubcollection).add({
        'action': AuditAction.approved.value,
        'performedBy': user.uid,
        'performedByEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'details': 'Claim approved for ₹${approvedAmount.toStringAsFixed(2)}',
      });

      return StatusResult.success(message: 'Claim approved for ₹${approvedAmount.toStringAsFixed(2)}!');
    } catch (e) {
      return StatusResult.failure(error: 'Failed to approve claim: ${e.toString()}');
    }
  }

  /// Reject a claim with reason
  Future<StatusResult> rejectClaim({
    required String claimId,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return StatusResult.failure(error: 'You must be logged in.');
      }

      final claimRef = _firestore.collection(AppConstants.claimsCollection).doc(claimId);
      final claim = await claimRef.get();
      
      if (!claim.exists) {
        return StatusResult.failure(error: 'Claim not found.');
      }

      final data = claim.data()!;
      if (data['status'] != ClaimStatus.submitted.value) {
        return StatusResult.failure(error: 'Only submitted claims can be rejected.');
      }

      // Update claim
      await claimRef.update({
        'status': ClaimStatus.rejected.value,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': user.uid,
        'approvedAmount': 0,
        'pendingAmount': 0,
        'settledAmount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create audit log
      await claimRef.collection(AppConstants.auditLogsSubcollection).add({
        'action': AuditAction.rejected.value,
        'performedBy': user.uid,
        'performedByEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'details': 'Claim rejected: $reason',
      });

      return StatusResult.success(message: 'Claim rejected.');
    } catch (e) {
      return StatusResult.failure(error: 'Failed to reject claim: ${e.toString()}');
    }
  }

  /// Process a settlement
  Future<StatusResult> processSettlement({
    required String claimId,
    required double settlementAmount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return StatusResult.failure(error: 'You must be logged in.');
      }

      final claimRef = _firestore.collection(AppConstants.claimsCollection).doc(claimId);
      final claim = await claimRef.get();
      
      if (!claim.exists) {
        return StatusResult.failure(error: 'Claim not found.');
      }

      final data = claim.data()!;
      final status = data['status'];
      if (status != ClaimStatus.approved.value && status != ClaimStatus.partiallySettled.value) {
        return StatusResult.failure(error: 'Only approved claims can be settled.');
      }

      final approvedAmount = (data['approvedAmount'] ?? 0).toDouble();
      final advancePaid = (data['advancePaid'] ?? 0).toDouble();
      final currentSettled = (data['settledAmount'] ?? 0).toDouble();
      final maxSettlement = approvedAmount - advancePaid - currentSettled;

      if (settlementAmount > maxSettlement + 0.01) {
        return StatusResult.failure(error: 'Settlement amount exceeds pending amount.');
      }

      final newSettledAmount = currentSettled + settlementAmount;
      final newPendingAmount = approvedAmount - advancePaid - newSettledAmount;
      
      // Determine new status
      String newStatus;
      if (newPendingAmount <= 0.01) {
        newStatus = ClaimStatus.approved.value; // Fully settled but we keep as approved
      } else {
        newStatus = ClaimStatus.partiallySettled.value;
      }

      // Update claim
      await claimRef.update({
        'status': newStatus,
        'settledAmount': newSettledAmount,
        'pendingAmount': newPendingAmount > 0 ? newPendingAmount : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create audit log
      await claimRef.collection(AppConstants.auditLogsSubcollection).add({
        'action': AuditAction.settled.value,
        'performedBy': user.uid,
        'performedByEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'details': 'Settlement of ₹${settlementAmount.toStringAsFixed(2)} processed. New pending: ₹${newPendingAmount.toStringAsFixed(2)}',
      });

      return StatusResult.success(
        message: 'Settlement of ₹${settlementAmount.toStringAsFixed(2)} processed!',
      );
    } catch (e) {
      return StatusResult.failure(error: 'Failed to process settlement: ${e.toString()}');
    }
  }
}

/// Result wrapper for status operations
class StatusResult {
  final bool isSuccess;
  final String? message;
  final String? error;

  StatusResult._({
    required this.isSuccess,
    this.message,
    this.error,
  });

  factory StatusResult.success({String? message}) {
    return StatusResult._(isSuccess: true, message: message);
  }

  factory StatusResult.failure({required String error}) {
    return StatusResult._(isSuccess: false, error: error);
  }
}

/// Provider for ClaimStatusService
final claimStatusServiceProvider = Provider<ClaimStatusService>((ref) {
  return ClaimStatusService();
});
