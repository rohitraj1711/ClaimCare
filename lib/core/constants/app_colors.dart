import 'package:flutter/material.dart';

/// Application color palette for the Insurance Claim Management System.
/// Healthcare-focused colors with trust colors: blue and green.
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);

  // Secondary colors
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryLight = Color(0xFF81C784);
  static const Color secondaryDark = Color(0xFF388E3C);

  // Background colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors - Claim status mapping
  static const Color statusDraft = Color(0xFF9E9E9E);       // Grey
  static const Color statusSubmitted = Color(0xFF1976D2);   // Blue
  static const Color statusApproved = Color(0xFF4CAF50);    // Green
  static const Color statusRejected = Color(0xFFF44336);    // Red
  static const Color statusPartiallySettled = Color(0xFFFF9800); // Orange

  // Status background colors (lighter variants)
  static const Color statusDraftBg = Color(0xFFEEEEEE);
  static const Color statusSubmittedBg = Color(0xFFE3F2FD);
  static const Color statusApprovedBg = Color(0xFFE8F5E9);
  static const Color statusRejectedBg = Color(0xFFFFEBEE);
  static const Color statusPartiallySettledBg = Color(0xFFFFF3E0);

  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFE0E0E0);

  // Error and success
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFCDD2);
  static const Color success = Color(0xFF388E3C);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFBBDEFB);

  // Card and shadow
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x1A000000);

  // Financial specific colors
  static const Color moneyPositive = Color(0xFF2E7D32);
  static const Color moneyNegative = Color(0xFFD32F2F);
  static const Color moneyPending = Color(0xFFFF9800);

  /// Get status color based on claim status string
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return statusDraft;
      case 'SUBMITTED':
        return statusSubmitted;
      case 'APPROVED':
        return statusApproved;
      case 'REJECTED':
        return statusRejected;
      case 'PARTIALLY_SETTLED':
        return statusPartiallySettled;
      default:
        return statusDraft;
    }
  }

  /// Get status background color based on claim status string
  static Color getStatusBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return statusDraftBg;
      case 'SUBMITTED':
        return statusSubmittedBg;
      case 'APPROVED':
        return statusApprovedBg;
      case 'REJECTED':
        return statusRejectedBg;
      case 'PARTIALLY_SETTLED':
        return statusPartiallySettledBg;
      default:
        return statusDraftBg;
    }
  }
}
