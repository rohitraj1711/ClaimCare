/**
 * Validation utilities for Cloud Functions
 */

import * as admin from 'firebase-admin';

// Claim status types
export type ClaimStatus = 'DRAFT' | 'SUBMITTED' | 'APPROVED' | 'REJECTED' | 'PARTIALLY_SETTLED';

// Audit action types
export type AuditAction =
    | 'CLAIM_CREATED'
    | 'CLAIM_UPDATED'
    | 'CLAIM_SUBMITTED'
    | 'CLAIM_APPROVED'
    | 'CLAIM_REJECTED'
    | 'SETTLEMENT_PROCESSED'
    | 'BILL_ADDED'
    | 'BILL_UPDATED'
    | 'BILL_DELETED';

// Claim data interface
export interface ClaimData {
    id: string;
    patientName: string;
    policyNumber: string;
    hospitalName: string;
    admissionDate: admin.firestore.Timestamp;
    dischargeDate?: admin.firestore.Timestamp;
    status: ClaimStatus;
    totalBillAmount: number;
    approvedAmount: number;
    advancePaid: number;
    settledAmount: number;
    pendingAmount: number;
    rejectionReason?: string;
    notes?: string;
    createdAt: admin.firestore.Timestamp;
    updatedAt: admin.firestore.Timestamp;
}

// Validation result
export interface ValidationResult {
    isValid: boolean;
    error?: string;
}

/**
 * Validate status transition
 */
export function validateStatusTransition(
    currentStatus: ClaimStatus,
    newStatus: ClaimStatus
): ValidationResult {
    const validTransitions: Record<ClaimStatus, ClaimStatus[]> = {
        'DRAFT': ['SUBMITTED'],
        'SUBMITTED': ['APPROVED', 'REJECTED'],
        'APPROVED': ['PARTIALLY_SETTLED'],
        'REJECTED': [], // Cannot transition from rejected
        'PARTIALLY_SETTLED': ['PARTIALLY_SETTLED'], // Can have multiple settlements
    };

    const allowedTransitions = validTransitions[currentStatus] || [];

    if (!allowedTransitions.includes(newStatus)) {
        return {
            isValid: false,
            error: `Invalid status transition from ${currentStatus} to ${newStatus}`,
        };
    }

    return { isValid: true };
}

/**
 * Validate approved amount
 */
export function validateApprovedAmount(
    amount: number,
    totalBillAmount: number
): ValidationResult {
    if (amount <= 0) {
        return {
            isValid: false,
            error: 'Approved amount must be greater than 0',
        };
    }

    if (amount > totalBillAmount) {
        return {
            isValid: false,
            error: `Approved amount (${amount}) cannot exceed total bill amount (${totalBillAmount})`,
        };
    }

    return { isValid: true };
}

/**
 * Validate settlement amount
 */
export function validateSettlementAmount(
    amount: number,
    approvedAmount: number,
    currentSettledAmount: number
): ValidationResult {
    if (amount <= 0) {
        return {
            isValid: false,
            error: 'Settlement amount must be greater than 0',
        };
    }

    const remainingAmount = approvedAmount - currentSettledAmount;

    if (amount > remainingAmount) {
        return {
            isValid: false,
            error: `Settlement amount (${amount}) cannot exceed remaining amount (${remainingAmount})`,
        };
    }

    return { isValid: true };
}

/**
 * Calculate pending amount
 */
export function calculatePendingAmount(
    approvedAmount: number,
    settledAmount: number
): number {
    return Math.max(0, approvedAmount - settledAmount);
}

/**
 * Create audit log entry
 */
export async function createAuditLog(
    db: admin.firestore.Firestore,
    claimId: string,
    action: AuditAction,
    performedBy: string,
    performedByEmail: string,
    details?: string
): Promise<void> {
    const auditLogRef = db
        .collection('claims')
        .doc(claimId)
        .collection('audit_logs')
        .doc();

    await auditLogRef.set({
        id: auditLogRef.id,
        action,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        performedBy,
        performedByEmail,
        details,
    });
}

/**
 * Recalculate total bill amount from bills subcollection
 */
export async function recalculateTotalBillAmount(
    db: admin.firestore.Firestore,
    claimId: string
): Promise<number> {
    const billsSnapshot = await db
        .collection('claims')
        .doc(claimId)
        .collection('bills')
        .get();

    let total = 0;
    billsSnapshot.forEach((doc) => {
        const data = doc.data();
        total += data.amount || 0;
    });

    return total;
}

/**
 * Format currency for display in messages
 */
export function formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-IN', {
        style: 'currency',
        currency: 'INR',
        minimumFractionDigits: 2,
    }).format(amount);
}

/**
 * Get action label for audit log
 */
export function getActionLabel(action: AuditAction): string {
    const labels: Record<AuditAction, string> = {
        'CLAIM_CREATED': 'Claim Created',
        'CLAIM_UPDATED': 'Claim Updated',
        'CLAIM_SUBMITTED': 'Claim Submitted',
        'CLAIM_APPROVED': 'Claim Approved',
        'CLAIM_REJECTED': 'Claim Rejected',
        'SETTLEMENT_PROCESSED': 'Settlement Processed',
        'BILL_ADDED': 'Bill Added',
        'BILL_UPDATED': 'Bill Updated',
        'BILL_DELETED': 'Bill Deleted',
    };
    return labels[action] || action;
}
