import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/formatters.dart';

/// Widget for displaying formatted currency values.
class CurrencyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool compact;
  final bool showSign;
  final bool colorCoded;

  const CurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.compact = false,
    this.showSign = false,
    this.colorCoded = false,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    if (compact) {
      text = Formatters.formatCompactCurrency(amount);
    } else {
      text = Formatters.formatCurrency(amount);
    }

    if (showSign && amount > 0) {
      text = '+$text';
    }

    Color? textColor;
    if (colorCoded) {
      if (amount > 0) {
        textColor = AppColors.moneyPositive;
      } else if (amount < 0) {
        textColor = AppColors.moneyNegative;
      }
    }

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        color: textColor ?? style?.color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Large currency display for dashboard cards
class LargeCurrencyDisplay extends StatelessWidget {
  final double amount;
  final String label;
  final Color? color;

  const LargeCurrencyDisplay({
    super.key,
    required this.amount,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
