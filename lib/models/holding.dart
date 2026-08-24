import 'package:decimal/decimal.dart';

class Holding {
  const Holding({
    required this.symbol,
    required this.quantity,
    required this.avgCost,
  });

  final String symbol;
  final Decimal quantity;
  final Decimal avgCost;

  Decimal get invested => quantity * avgCost;

  Holding copyWith({
    Decimal? quantity,
    Decimal? avgCost,
  }) {
    return Holding(
      symbol: symbol,
      quantity: quantity ?? this.quantity,
      avgCost: avgCost ?? this.avgCost,
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'quantity': quantity.toString(),
        'avgCost': avgCost.toString(),
      };

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: json['symbol'] as String,
      quantity: Decimal.parse(json['quantity'] as String),
      avgCost: Decimal.parse(json['avgCost'] as String),
    );
  }
}
