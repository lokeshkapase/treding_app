import 'package:decimal/decimal.dart';

enum OrderSide { buy, sell }

class TradeOrder {
  const TradeOrder({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.executedAt,
  });

  final String id;
  final String symbol;
  final OrderSide side;
  final Decimal quantity;
  final Decimal price;
  final DateTime executedAt;

  Decimal get orderValue => quantity * price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side.name,
        'quantity': quantity.toString(),
        'price': price.toString(),
        'executedAt': executedAt.toIso8601String(),
      };

  factory TradeOrder.fromJson(Map<String, dynamic> json) {
    return TradeOrder(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      side: OrderSide.values.byName(json['side'] as String),
      quantity: Decimal.parse(json['quantity'] as String),
      price: Decimal.parse(json['price'] as String),
      executedAt: DateTime.parse(json['executedAt'] as String),
    );
  }
}
