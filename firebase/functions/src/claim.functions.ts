/**
 * Claim-related Cloud Functions
 * 
 * These functions enforce business rules for:
 * - Status transitions
 * - Financial validations (approved amount, settlement amount)
 * - Audit trail generation
 * 
 * All status changes and financial updates MUST go through these functions.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
    validateStatusTransition,
    validateApprovedAmount,
    validateSettlementAmount,
    calculatePendingAmount,
    createAuditLog,
    recalculateTotalBillAmount,
    formatCurrency,
    ClaimData,
} from './validators';

const db = admin.firestore();

// Response interface
interface FunctionResponse {
    success: boolean;
    message?: string;
    error?: string;
    data?: Record<string, unknown>;
}

/**
 * Submit a claim for review
 * Transitions status from DRAFT to SUBMITTED
 */
export const submitClaim = functions.https.onCall(
    async (data, context): Promise<FunctionResponse> => {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated to submit a claim'
            );
        }

        const { claimId } = data;

        if (!claimId || typeof claimId !== 'string') {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'claimId is required and must be a string'
            );
        }

        const claimRef = db.collection('claims').doc(claimId);

        try {
            const result = await db.runTransaction(async (transaction) => {
                const claimDoc = await transaction.get(claimRef);

                if (!claimDoc.exists) {
                    throw new functions.https.HttpsError('not-found', 'Claim not found');
                }

                const claimData = claimDoc.data() as ClaimData;

                // Validate status transition
                const validation = validateStatusTransition(claimData.status, 'SUBMITTED');
                if (!validation.isValid) {
                    throw new functions.https.HttpsError('failed-precondition', validation.error!);
                }

                // Recalculate total bill amount
                const totalBillAmount = await recalculateTotalBillAmount(db, claimId);

                if (totalBillAmount <= 0) {
                    throw new functions.https.HttpsError(
                        'failed-precondition',
                        'Cannot submit claim with no bills. Please add at least one bill.'
                    );
                }

                // Update claim
                transaction.update(claimRef, {
                    status: 'SUBMITTED',
                    totalBillAmount,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                return { totalBillAmount };
            });

            // Create audit log (outside transaction)
            await createAuditLog(
                db,
                claimId,
                'CLAIM_SUBMITTED',
                context.auth.uid,
                context.auth.token.email || 'Unknown',
                `Claim submitted with total amount ${formatCurrency(result.totalBillAmount)}`
            );

            return {
                success: true,
                message: 'Claim submitted successfully',
                data: { totalBillAmount: result.totalBillAmount },
            };
        } catch (error) {
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            console.error('Error submitting claim:', error);
            throw new functions.https.HttpsError('internal', 'Failed to submit claim');
        }
    }
);

/**
 * Approve a claim
 * Transitions status from SUBMITTED to APPROVED
 */
export const approveClaim = functions.https.onCall(
    async (data, context): Promise<FunctionResponse> => {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated to approve a claim'
            );
        }

        const { claimId, approvedAmount } = data;

        if (!claimId || typeof claimId !== 'string') {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'claimId is required and must be a string'
            );
        }

        if (typeof approvedAmount !== 'number' || approvedAmount <= 0) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'approvedAmount must be a positive number'
            );
        }

        const claimRef = db.collection('claims').doc(claimId);

        try {
            await db.runTransaction(async (transaction) => {
                const claimDoc = await transaction.get(claimRef);

                if (!claimDoc.exists) {
                    throw new functions.https.HttpsError('not-found', 'Claim not found');
                }

                const claimData = claimDoc.data() as ClaimData;

                // Validate status transition
                const statusValidation = validateStatusTransition(claimData.status, 'APPROVED');
                if (!statusValidation.isValid) {
                    throw new functions.https.HttpsError('failed-precondition', statusValidation.error!);
                }

                // Validate approved amount
                const amountValidation = validateApprovedAmount(
                    approvedAmount,
                    claimData.totalBillAmount
                );
                if (!amountValidation.isValid) {
                    throw new functions.https.HttpsError('invalid-argument', amountValidation.error!);
                }

                // Calculate pending amount
                const pendingAmount = calculatePendingAmount(approvedAmount, 0);

                // Update claim
                transaction.update(claimRef, {
                    status: 'APPROVED',
                    approvedAmount,
                    pendingAmount,
                    rejectionReason: admin.firestore.FieldValue.delete(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });

            // Create audit log (outside transaction)
            await createAuditLog(
                db,
                claimId,
                'CLAIM_APPROVED',
                context.auth.uid,
                context.auth.token.email || 'Unknown',
                `Claim approved with amount ${formatCurrency(approvedAmount)}`
            );

            return {
                success: true,
                message: `Claim approved for ${formatCurrency(approvedAmount)}`,
                data: { approvedAmount },
            };
        } catch (error) {
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            console.error('Error approving claim:', error);
            throw new functions.https.HttpsError('internal', 'Failed to approve claim');
        }
    }
);

/**
 * Reject a claim
 * Transitions status from SUBMITTED to REJECTED
 */
export const rejectClaim = functions.https.onCall(
    async (data, context): Promise<FunctionResponse> => {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated to reject a claim'
            );
        }

        const { claimId, reason } = data;

        if (!claimId || typeof claimId !== 'string') {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'claimId is required and must be a string'
            );
        }

        if (!reason || typeof reason !== 'string' || reason.trim().length < 10) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Rejection reason is required and must be at least 10 characters'
            );
        }

        const claimRef = db.collection('claims').doc(claimId);

        try {
            await db.runTransaction(async (transaction) => {
                const claimDoc = await transaction.get(claimRef);

                if (!claimDoc.exists) {
                    throw new functions.https.HttpsError('not-found', 'Claim not found');
                }

                const claimData = claimDoc.data() as ClaimData;

                // Validate status transition
                const validation = validateStatusTransition(claimData.status, 'REJECTED');
                if (!validation.isValid) {
                    throw new functions.https.HttpsError('failed-precondition', validation.error!);
                }

                // Update claim - reset financial fields
                transaction.update(claimRef, {
                    status: 'REJECTED',
                    rejectionReason: reason.trim(),
                    approvedAmount: 0,
                    settledAmount: 0,
                    pendingAmount: 0,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            });

            // Create audit log (outside transaction)
            await createAuditLog(
                db,
                claimId,
                'CLAIM_REJECTED',
                context.auth.uid,
                context.auth.token.email || 'Unknown',
                `Claim rejected. Reason: ${reason.trim()}`
            );

            return {
                success: true,
                message: 'Claim rejected',
            };
        } catch (error) {
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            console.error('Error rejecting claim:', error);
            throw new functions.https.HttpsError('internal', 'Failed to reject claim');
        }
    }
);

/**
 * Process a settlement
 * Transitions status to PARTIALLY_SETTLED or keeps it if already partially settled
 */
export const settleClaim = functions.https.onCall(
    async (data, context): Promise<FunctionResponse> => {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated to process a settlement'
            );
        }

        const { claimId, settlementAmount } = data;

        if (!claimId || typeof claimId !== 'string') {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'claimId is required and must be a string'
            );
        }

        if (typeof settlementAmount !== 'number' || settlementAmount <= 0) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'settlementAmount must be a positive number'
            );
        }

        const claimRef = db.collection('claims').doc(claimId);

        try {
            const result = await db.runTransaction(async (transaction) => {
                const claimDoc = await transaction.get(claimRef);

                if (!claimDoc.exists) {
                    throw new functions.https.HttpsError('not-found', 'Claim not found');
                }

                const claimData = claimDoc.data() as ClaimData;

                // Check if claim can be settled
                if (claimData.status !== 'APPROVED' && claimData.status !== 'PARTIALLY_SETTLED') {
                    throw new functions.https.HttpsError(
                        'failed-precondition',
                        'Only approved or partially settled claims can be settled'
                    );
                }

                // Validate settlement amount
                const validation = validateSettlementAmount(
                    settlementAmount,
                    claimData.approvedAmount,
                    claimData.settledAmount
                );
                if (!validation.isValid) {
                    throw new functions.https.HttpsError('invalid-argument', validation.error!);
                }

                // Calculate new amounts
                const newSettledAmount = claimData.settledAmount + settlementAmount;
                const newPendingAmount = calculatePendingAmount(
                    claimData.approvedAmount,
                    newSettledAmount
                );

                // Update claim
                transaction.update(claimRef, {
                    status: 'PARTIALLY_SETTLED',
                    settledAmount: newSettledAmount,
                    pendingAmount: newPendingAmount,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                return {
                    settlementAmount,
                    newSettledAmount,
                    newPendingAmount,
                    isFullySettled: newPendingAmount === 0,
                };
            });

            // Create audit log (outside transaction)
            const details = result.isFullySettled
                ? `Full settlement of ${formatCurrency(result.settlementAmount)}. Claim fully settled.`
                : `Partial settlement of ${formatCurrency(result.settlementAmount)}. Total settled: ${formatCurrency(result.newSettledAmount)}. Pending: ${formatCurrency(result.newPendingAmount)}`;

            await createAuditLog(
                db,
                claimId,
                'SETTLEMENT_PROCESSED',
                context.auth.uid,
                context.auth.token.email || 'Unknown',
                details
            );

            return {
                success: true,
                message: result.isFullySettled
                    ? 'Claim fully settled!'
                    : `Settlement of ${formatCurrency(result.settlementAmount)} processed`,
                data: result,
            };
        } catch (error) {
            if (error instanceof functions.https.HttpsError) {
                throw error;
            }
            console.error('Error processing settlement:', error);
            throw new functions.https.HttpsError('internal', 'Failed to process settlement');
        }
    }
);
