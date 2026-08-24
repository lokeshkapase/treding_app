import 'dart:async';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/stock_quote.dart';

/// Single source of truth for live market prices across the entire app.
class MarketDataService extends ChangeNotifier {
  MarketDataService({int? tickIntervalMs})
      : _tickIntervalMs = tickIntervalMs ?? kDefaultTickIntervalMs {
    _quotes = _buildInitialQuotes();
  }

  final _random = Random();
  Timer? _timer;
  late Map<String, StockQuote> _quotes;
  int _tickIntervalMs;

  int get tickIntervalMs => _tickIntervalMs;

  /// Ticks per second per stock (approximate).
  double get ticksPerSecondPerStock => 1000 / _tickIntervalMs;

  Map<String, StockQuote> get quotes => Map.unmodifiable(_quotes);

  StockQuote quoteFor(String symbol) => _quotes[symbol]!;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: _tickIntervalMs),
      (_) => _emitTick(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void setTickInterval(int milliseconds) {
    if (milliseconds < 50) milliseconds = 50;
    _tickIntervalMs = milliseconds;
    if (_timer != null) {
      start();
    }
    notifyListeners();
  }

  void _emitTick() {
    final symbol = kStockSymbols[_random.nextInt(kStockSymbols.length)];
    _updateSymbol(symbol);
    notifyListeners();
  }

  void _updateSymbol(String symbol) {
    final current = _quotes[symbol]!;
    final delta = (_random.nextDouble() - 0.48) * current.ltp.toDouble() * 0.002;
    final newLtp = Decimal.parse(
      (current.ltp.toDouble() + delta).clamp(1.0, double.infinity).toStringAsFixed(2),
    );
    final direction = newLtp > current.ltp
        ? PriceDirection.up
        : newLtp < current.ltp
            ? PriceDirection.down
            : PriceDirection.flat;
    _quotes[symbol] = current.copyWith(ltp: newLtp, lastDirection: direction);
  }

  Map<String, StockQuote> _buildInitialQuotes() {
    final quotes = <String, StockQuote>{};
    for (final symbol in kStockSymbols) {
      final price = Decimal.parse(kStartingPrices[symbol]!);
      quotes[symbol] = StockQuote(
        symbol: symbol,
        ltp: price,
        previousClose: price,
        lastDirection: PriceDirection.flat,
      );
    }
    return quotes;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
