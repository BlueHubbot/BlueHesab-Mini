import 'package:flutter/widgets.dart';

// T-015 (SP-03, TY-05): toy amount card for the text-scale check. Evidence,
// not product: styles come from the caller (built from design_tokens.json in
// the tests), so no raw size lives here (TY-02). The amount is never cut:
// no maxLines and no ellipsis; it wraps instead.

/// A label above an amount, both wrapping freely.
class AmountCard extends StatelessWidget {
  /// Creates the card.
  const AmountCard({
    required this.label,
    required this.amount,
    required this.labelStyle,
    required this.amountStyle,
    super.key,
  });

  /// Label text.
  final String label;

  /// Formatted amount text.
  final String amount;

  /// Style of [label].
  final TextStyle labelStyle;

  /// Style of [amount].
  final TextStyle amountStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: labelStyle, softWrap: true),
        Text(amount, style: amountStyle, softWrap: true),
      ],
    );
  }
}
