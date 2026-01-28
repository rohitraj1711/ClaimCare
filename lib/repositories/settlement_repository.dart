import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/functions_service.dart';

/// Repository for managing claim settlements.
/// Handles settlement operations through Cloud Functions.
class SettlementRepository {
  final FunctionsService _functionsService;

  SettlementRepository({required FunctionsService functionsService})
      : _functionsService = functionsService;

  /// Submit a claim for review
  Future<SettlementResult> submitClaim(String claimId) async {
    final result = await _functionsService.submitClaim(claimId);
    if (result.isSuccess) {
      return SettlementResult.success(
        message: 'Claim submitted successfully for review.',
      );
    } else {
      return SettlementResult.failure(error: result.error!);
    }
  }

  /// Approve a claim with specified amount
  Future<SettlementResult> approveClaim({
    required String claimId,
    required double approvedAmount,
  }) async {
    final result = await _functionsService.approveClaim(
      claimId: claimId,
      approvedAmount: approvedAmount,
    );
    if (result.isSuccess) {
      return SettlementResult.success(
        message: 'Claim approved successfully.',
      );
    } else {
      return SettlementResult.failure(error: result.error!);
    }
  }

  /// Reject a claim with reason
  Future<SettlementResult> rejectClaim({
    required String claimId,
    required String reason,
  }) async {
    final result = await _functionsService.rejectClaim(
      claimId: claimId,
      reason: reason,
    );
    if (result.isSuccess) {
      return SettlementResult.success(
        message: 'Claim rejected.',
      );
    } else {
      return SettlementResult.failure(error: result.error!);
    }
  }

  /// Process a settlement payment
  Future<SettlementResult> processSettlement({
    required String claimId,
    required double settlementAmount,
  }) async {
    final result = await _functionsService.settleClaim(
      claimId: claimId,
      settlementAmount: settlementAmount,
    );
    if (result.isSuccess) {
      return SettlementResult.success(
        message: 'Settlement processed successfully.',
      );
    } else {
      return SettlementResult.failure(error: result.error!);
    }
  }
}

/// Result wrapper for settlement operations
class SettlementResult {
  final bool isSuccess;
  final String? message;
  final String? error;

  SettlementResult._({
    required this.isSuccess,
    this.message,
    this.error,
  });

  factory SettlementResult.success({String? message}) {
    return SettlementResult._(isSuccess: true, message: message);
  }

  factory SettlementResult.failure({required String error}) {
    return SettlementResult._(isSuccess: false, error: error);
  }
}

/// Provider for SettlementRepository
final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  final functionsService = ref.watch(functionsServiceProvider);
  return SettlementRepository(functionsService: functionsService);
});
