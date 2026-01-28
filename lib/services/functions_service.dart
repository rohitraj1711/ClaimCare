import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

/// Service for calling Firebase Cloud Functions.
/// Handles all business logic operations that require backend validation.
class FunctionsService {
  final FirebaseFunctions _functions;

  FunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Submit a claim for review
  /// Transitions claim from DRAFT to SUBMITTED status
  Future<FunctionResult> submitClaim(String claimId) async {
    try {
      final callable = _functions.httpsCallable(AppConstants.submitClaimFunction);
      final result = await callable.call<Map<String, dynamic>>({
        'claimId': claimId,
      });
      return FunctionResult.success(result.data);
    } on FirebaseFunctionsException catch (e) {
      return FunctionResult.error(_handleFunctionException(e));
    } catch (e) {
      return FunctionResult.error('Failed to submit claim. Please try again.');
    }
  }

  /// Approve a claim with specified amount
  /// Transitions claim from SUBMITTED to APPROVED status
  Future<FunctionResult> approveClaim({
    required String claimId,
    required double approvedAmount,
  }) async {
    try {
      final callable = _functions.httpsCallable(AppConstants.approveClaimFunction);
      final result = await callable.call<Map<String, dynamic>>({
        'claimId': claimId,
        'approvedAmount': approvedAmount,
      });
      return FunctionResult.success(result.data);
    } on FirebaseFunctionsException catch (e) {
      return FunctionResult.error(_handleFunctionException(e));
    } catch (e) {
      return FunctionResult.error('Failed to approve claim. Please try again.');
    }
  }

  /// Reject a claim with reason
  /// Transitions claim from SUBMITTED to REJECTED status
  Future<FunctionResult> rejectClaim({
    required String claimId,
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable(AppConstants.rejectClaimFunction);
      final result = await callable.call<Map<String, dynamic>>({
        'claimId': claimId,
        'reason': reason,
      });
      return FunctionResult.success(result.data);
    } on FirebaseFunctionsException catch (e) {
      return FunctionResult.error(_handleFunctionException(e));
    } catch (e) {
      return FunctionResult.error('Failed to reject claim. Please try again.');
    }
  }

  /// Settle a claim with specified amount
  /// Updates settlement amount and may transition to PARTIALLY_SETTLED
  Future<FunctionResult> settleClaim({
    required String claimId,
    required double settlementAmount,
  }) async {
    try {
      final callable = _functions.httpsCallable(AppConstants.settleClaimFunction);
      final result = await callable.call<Map<String, dynamic>>({
        'claimId': claimId,
        'settlementAmount': settlementAmount,
      });
      return FunctionResult.success(result.data);
    } on FirebaseFunctionsException catch (e) {
      return FunctionResult.error(_handleFunctionException(e));
    } catch (e) {
      return FunctionResult.error('Failed to process settlement. Please try again.');
    }
  }

  /// Handle Cloud Function exceptions
  String _handleFunctionException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'invalid-argument':
        return e.message ?? 'Invalid data provided.';
      case 'failed-precondition':
        return e.message ?? 'Operation cannot be performed in current state.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'not-found':
        return 'The requested resource was not found.';
      case 'already-exists':
        return 'The resource already exists.';
      case 'unauthenticated':
        return 'You must be logged in to perform this action.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}

/// Result wrapper for Cloud Function calls
class FunctionResult {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;

  FunctionResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  factory FunctionResult.success(Map<String, dynamic>? data) {
    return FunctionResult._(isSuccess: true, data: data);
  }

  factory FunctionResult.error(String message) {
    return FunctionResult._(isSuccess: false, error: message);
  }
}

/// Provider for FunctionsService
final functionsServiceProvider = Provider<FunctionsService>((ref) {
  return FunctionsService();
});
