import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utility functions for formatting values.
class Formatters {
  Formatters._();

  /// Currency formatter for Indian Rupees
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  /// Compact currency formatter for large amounts
  static final NumberFormat _compactCurrencyFormatter = NumberFormat.compactCurrency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 1,
  );

  /// Date formatter
  static final DateFormat _dateFormatter = DateFormat(AppConstants.dateFormat);

  /// Short date formatter
  static final DateFormat _shortDateFormatter = DateFormat(AppConstants.shortDateFormat);

  /// DateTime formatter
  static final DateFormat _dateTimeFormatter = DateFormat(AppConstants.dateTimeFormat);

  /// Format amount as currency
  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format large amount as compact currency (e.g., ₹1.5L)
  static String formatCompactCurrency(double amount) {
    if (amount >= 10000000) {
      return '${AppConstants.currencySymbol}${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${AppConstants.currencySymbol}${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(2)} K';
    }
    return formatCurrency(amount);
  }

  /// Format date
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Format date in short format (dd/MM/yyyy)
  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  /// Format date range
  static String formatDateRange(DateTime start, DateTime? end) {
    final startFormatted = formatDate(start);
    if (end == null) {
      return '$startFormatted - Present';
    }
    return '$startFormatted - ${formatDate(end)}';
  }

  /// Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Format policy number with masking
  static String formatPolicyNumber(String policyNumber, {bool mask = false}) {
    if (mask && policyNumber.length > 4) {
      return '${'*' * (policyNumber.length - 4)}${policyNumber.substring(policyNumber.length - 4)}';
    }
    return policyNumber;
  }

  /// Format percentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Calculate percentage
  static double calculatePercentage(double part, double total) {
    if (total == 0) return 0;
    return (part / total) * 100;
  }
}
