import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/money.dart';
import '../models/holding.dart';
import '../models/order.dart';
import '../models/stock_quote.dart';
import '../models/watchlist.dart';
import '../services/market_data_service.dart';
import '../services/storage_service.dart';

enum HoldingsSort { pnlDesc, symbolAsc, valueDesc }

class PortfolioState extends ChangeNotifier {
  PortfolioState({
    required StorageService storage,
    required MarketDataService marketData,
  })  : _storage = storage,
        _marketData = marketData {
    watchlists = _storage.loadWatchlists();
    holdings = _storage.loadHoldings();
    walletBalance = _storage.loadWalletBalance();
    orders = _storage.loadOrders();
    _marketData.addListener(_onMarketTick);
  }

  final StorageService _storage;
  final MarketDataService _marketData;
  final _uuid = const Uuid();

  late List<Watchlist> watchlists;
  late List<Holding> holdings;
  late Decimal walletBalance;
  late List<TradeOrder> orders;

  HoldingsSort holdingsSort = HoldingsSort.pnlDesc;

  void _onMarketTick() {
    notifyListeners();
  }

  // ── Watchlist operations ──

  Future<void> createWatchlist(String name) async {
    watchlists = [
      ...watchlists,
      Watchlist(id: _uuid.v4(), name: name, symbols: []),
    ];
    await _persistWatchlists();
    notifyListeners();
  }

  Future<void> renameWatchlist(String id, String name) async {
    watchlists = watchlists
        .map((w) => w.id == id ? w.copyWith(name: name) : w)
        .toList();
    await _persistWatchlists();
    notifyListeners();
  }

  Future<void> deleteWatchlist(String id) async {
    watchlists = watchlists.where((w) => w.id != id).toList();
    await _persistWatchlists();
    notifyListeners();
  }

  Future<void> addStockToWatchlist(String watchlistId, String symbol) async {
    watchlists = watchlists.map((w) {
      if (w.id != watchlistId) return w;
      if (w.symbols.contains(symbol)) return w;
      return w.copyWith(symbols: [...w.symbols, symbol]);
    }).toList();
    await _persistWatchlists();
    notifyListeners();
  }

  Future<void> removeStockFromWatchlist(String watchlistId, String symbol) async {
    watchlists = watchlists.map((w) {
      if (w.id != watchlistId) return w;
      return w.copyWith(symbols: w.symbols.where((s) => s != symbol).toList());
    }).toList();
    await _persistWatchlists();
    notifyListeners();
  }

  Future<void> reorderWatchlistStock(
    String watchlistId,
    int oldIndex,
    int newIndex,
  ) async {
    watchlists = watchlists.map((w) {
      if (w.id != watchlistId) return w;
      final symbols = List<String>.from(w.symbols);
      if (newIndex > oldIndex) newIndex -= 1;
      final item = symbols.removeAt(oldIndex);
      symbols.insert(newIndex, item);
      return w.copyWith(symbols: symbols);
    }).toList();
    await _persistWatchlists();
    notifyListeners();
  }

  Watchlist? watchlistById(String id) {
    try {
      return watchlists.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Holdings operations ──

  Holding? holdingFor(String symbol) {
    try {
      return holdings.firstWhere((h) => h.symbol == symbol);
    } catch (_) {
      return null;
    }
  }

  Decimal quantityHeld(String symbol) =>
      holdingFor(symbol)?.quantity ?? Decimal.zero;

  void setHoldingsSort(HoldingsSort sort) {
    holdingsSort = sort;
    notifyListeners();
  }

  List<Holding> sortedHoldings() {
    final list = List<Holding>.from(holdings);
    switch (holdingsSort) {
      case HoldingsSort.pnlDesc:
        list.sort((a, b) {
          final pnlA = _pnlFor(a);
          final pnlB = _pnlFor(b);
          return pnlB.compareTo(pnlA);
        });
      case HoldingsSort.symbolAsc:
        list.sort((a, b) => a.symbol.compareTo(b.symbol));
      case HoldingsSort.valueDesc:
        list.sort((a, b) {
          final valA = _currentValueFor(a);
          final valB = _currentValueFor(b);
          return valB.compareTo(valA);
        });
    }
    return list;
  }

  Decimal _pnlFor(Holding h) {
    final ltp = _marketData.quoteFor(h.symbol).ltp;
    return (ltp - h.avgCost) * h.quantity;
  }

  Decimal _currentValueFor(Holding h) {
    final ltp = _marketData.quoteFor(h.symbol).ltp;
    return ltp * h.quantity;
  }

  ({Decimal invested, Decimal currentValue, Decimal pnl, Decimal pnlPercent})
      portfolioSummary() {
    var invested = Decimal.zero;
    var currentValue = Decimal.zero;
    for (final h in holdings) {
      invested += h.invested;
      currentValue += _currentValueFor(h);
    }
    final pnl = currentValue - invested;
    final pnlPercent = invested == Decimal.zero
        ? Decimal.zero
        : Money.percentChange(pnl, invested);
    return (
      invested: invested,
      currentValue: currentValue,
      pnl: pnl,
      pnlPercent: pnlPercent,
    );
  }

  HoldingMetrics metricsFor(Holding h) {
    final quote = _marketData.quoteFor(h.symbol);
    final currentValue = quote.ltp * h.quantity;
    final invested = h.invested;
    final pnl = currentValue - invested;
    final pnlPercent = invested == Decimal.zero
        ? Decimal.zero
        : Money.percentChange(pnl, invested);
    return HoldingMetrics(
      holding: h,
      quote: quote,
      currentValue: currentValue,
      pnl: pnl,
      pnlPercent: pnlPercent,
    );
  }

  // ── Trading ──

  Future<TradeOrder?> placeOrder({
    required OrderSide side,
    required String symbol,
    required Decimal quantity,
  }) async {
    final ltp = _marketData.quoteFor(symbol).ltp;
    final orderValue = ltp * quantity;

    if (side == OrderSide.buy) {
      if (orderValue > walletBalance) return null;
      walletBalance -= orderValue;
      _updateHoldingAfterBuy(symbol, quantity, ltp);
    } else {
      final held = quantityHeld(symbol);
      if (quantity > held) return null;
      walletBalance += orderValue;
      _updateHoldingAfterSell(symbol, quantity);
    }

    final order = TradeOrder(
      id: _uuid.v4(),
      symbol: symbol,
      side: side,
      quantity: quantity,
      price: ltp,
      executedAt: DateTime.now(),
    );
    orders = [order, ...orders];
    await _persistAll();
    notifyListeners();
    return order;
  }

  void _updateHoldingAfterBuy(String symbol, Decimal qty, Decimal price) {
    final existing = holdingFor(symbol);
    if (existing == null) {
      holdings = [...holdings, Holding(symbol: symbol, quantity: qty, avgCost: price)];
    } else {
      final totalQty = existing.quantity + qty;
      final totalCost = existing.invested + qty * price;
      final newAvg = (totalCost / totalQty).toDecimal(scaleOnInfinitePrecision: 10);
      holdings = holdings
          .map((h) => h.symbol == symbol
              ? h.copyWith(quantity: totalQty, avgCost: newAvg)
              : h)
          .toList();
    }
  }

  void _updateHoldingAfterSell(String symbol, Decimal qty) {
    final existing = holdingFor(symbol)!;
    final remaining = existing.quantity - qty;
    if (remaining <= Decimal.zero) {
      holdings = holdings.where((h) => h.symbol != symbol).toList();
    } else {
      holdings = holdings
          .map((h) => h.symbol == symbol ? h.copyWith(quantity: remaining) : h)
          .toList();
    }
  }

  Future<void> _persistWatchlists() =>
      _storage.saveWatchlists(watchlists);

  Future<void> _persistAll() async {
    await Future.wait([
      _storage.saveHoldings(holdings),
      _storage.saveWalletBalance(walletBalance),
      _storage.saveOrders(orders),
    ]);
  }

  @override
  void dispose() {
    _marketData.removeListener(_onMarketTick);
    super.dispose();
  }
}

class HoldingMetrics {
  const HoldingMetrics({
    required this.holding,
    required this.quote,
    required this.currentValue,
    required this.pnl,
    required this.pnlPercent,
  });

  final Holding holding;
  final StockQuote quote;
  final Decimal currentValue;
  final Decimal pnl;
  final Decimal pnlPercent;
}
