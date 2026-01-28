/**
 * Cloud Functions for Insurance Claim Management System
 * 
 * These functions enforce business rules for claim status transitions
 * and financial calculations. Client-side cannot directly modify
 * protected fields (status, approvedAmount, settledAmount, etc.)
 */

import * as admin from 'firebase-admin';
import { submitClaim, approveClaim, rejectClaim, settleClaim } from './claim.functions';

// Initialize Firebase Admin
admin.initializeApp();

// Export all functions
export {
    submitClaim,
    approveClaim,
    rejectClaim,
    settleClaim,
};
