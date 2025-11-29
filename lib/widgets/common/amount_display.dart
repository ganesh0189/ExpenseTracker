import 'package:flutter/material.dart';
import '../../config/themes.dart';
import '../../utils/formatters.dart';

/// Modern amount display widget
class AmountDisplay extends StatelessWidget {
  final double amount;
  final String currencySymbol;
  final AmountSize size;
  final AmountStyle style;
  final bool showSign;
  final Color? color;
  final TextAlign? textAlign;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.currencySymbol = '₹',
    this.size = AmountSize.medium,
    this.style = AmountStyle.normal,
    this.showSign = false,
    this.color,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? _getColor();
    final fontSize = _getFontSize();
    final formattedAmount = formatCurrency(amount.abs(), symbol: currencySymbol);
    final sign = showSign ? (amount >= 0 ? '+' : '-') : '';

    if (style == AmountStyle.gradient) {
      return ShaderMask(
        shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
        child: Text(
          '$sign$formattedAmount',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: textAlign,
        ),
      );
    }

    return Text(
      '$sign$formattedAmount',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: displayColor,
      ),
      textAlign: textAlign,
    );
  }

  Color _getColor() {
    switch (style) {
      case AmountStyle.income:
        return AppColors.income;
      case AmountStyle.expense:
        return AppColors.expense;
      case AmountStyle.colored:
        return amount >= 0 ? AppColors.income : AppColors.expense;
      default:
        return AppColors.textLight;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AmountSize.small:
        return 14;
      case AmountSize.medium:
        return 20;
      case AmountSize.large:
        return 28;
      case AmountSize.xlarge:
        return 36;
      case AmountSize.hero:
        return 48;
    }
  }
}

enum AmountSize { small, medium, large, xlarge, hero }

enum AmountStyle { normal, income, expense, colored, gradient }

/// Amount with label
class LabeledAmount extends StatelessWidget {
  final String label;
  final double amount;
  final String currencySymbol;
  final AmountStyle style;
  final bool compact;

  const LabeledAmount({
    super.key,
    required this.label,
    required this.amount,
    this.currencySymbol = '₹',
    this.style = AmountStyle.normal,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textLightSecondary,
              fontSize: 14,
            ),
          ),
          AmountDisplay(
            amount: amount,
            currencySymbol: currencySymbol,
            size: AmountSize.small,
            style: style,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textLightSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        AmountDisplay(
          amount: amount,
          currencySymbol: currencySymbol,
          size: AmountSize.medium,
          style: style,
        ),
      ],
    );
  }
}

/// Balance card showing income vs expense
class BalanceDisplay extends StatelessWidget {
  final double income;
  final double expense;
  final String currencySymbol;

  const BalanceDisplay({
    super.key,
    required this.income,
    required this.expense,
    this.currencySymbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;

    return Column(
      children: [
        // Balance
        Text(
          'Balance',
          style: TextStyle(
            color: AppColors.textLightSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        AmountDisplay(
          amount: balance,
          currencySymbol: currencySymbol,
          size: AmountSize.hero,
          style: AmountStyle.gradient,
        ),
        const SizedBox(height: 24),
        // Income and Expense row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryItem(
              icon: Icons.arrow_downward,
              label: 'Income',
              amount: income,
              color: AppColors.income,
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.glassBorder,
            ),
            _buildSummaryItem(
              icon: Icons.arrow_upward,
              label: 'Expense',
              amount: expense,
              color: AppColors.expense,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textLightSecondary,
                fontSize: 12,
              ),
            ),
            AmountDisplay(
              amount: amount,
              size: AmountSize.medium,
              color: color,
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact amount change indicator
class AmountChange extends StatelessWidget {
  final double amount;
  final double? previousAmount;
  final String currencySymbol;

  const AmountChange({
    super.key,
    required this.amount,
    this.previousAmount,
    this.currencySymbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    if (previousAmount == null) {
      return AmountDisplay(
        amount: amount,
        currencySymbol: currencySymbol,
        size: AmountSize.medium,
      );
    }

    final change = amount - previousAmount!;
    final percentChange = previousAmount != 0
        ? ((change / previousAmount!) * 100).abs()
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AmountDisplay(
          amount: amount,
          currencySymbol: currencySymbol,
          size: AmountSize.medium,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              change >= 0 ? Icons.trending_up : Icons.trending_down,
              color: change >= 0 ? AppColors.income : AppColors.expense,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '${change >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
              style: TextStyle(
                color: change >= 0 ? AppColors.income : AppColors.expense,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
