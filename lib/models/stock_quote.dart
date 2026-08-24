import 'package:decimal/decimal.dart';

import '../core/money.dart';

enum PriceDirection { up, down, flat }

class StockQuote {
  const StockQuote({
    required this.symbol,
    required this.ltp,
    required this.previousClose,
    required this.lastDirection,
  });

  final String symbol;
  final Decimal ltp;
  final Decimal previousClose;
  final PriceDirection lastDirection;

  Decimal get change => ltp - previousClose;

  Decimal get changePercent => Money.percentChange(change, previousClose);

  StockQuote copyWith({
    Decimal? ltp,
    PriceDirection? lastDirection,
  }) {
    return StockQuote(
      symbol: symbol,
      ltp: ltp ?? this.ltp,
      previousClose: previousClose,
      lastDirection: lastDirection ?? this.lastDirection,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockQuote &&
          symbol == other.symbol &&
          ltp == other.ltp &&
          lastDirection == other.lastDirection;

  @override
  int get hashCode => Object.hash(symbol, ltp, lastDirection);
}
