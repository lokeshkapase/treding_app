import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/holding.dart';
import '../models/order.dart';
import '../models/watchlist.dart';

class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  List<Watchlist> loadWatchlists() {
    final raw = _prefs.getString(StorageKeys.watchlists);
    if (raw == null) {
      return [
        Watchlist(
          id: 'default',
          name: 'My Watchlist',
          symbols: ['RELIANCE', 'TCS', 'INFY'],
        ),
      ];
    }
    final list = jsonDecode(raw) as List;
    return list.map((e) => Watchlist.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveWatchlists(List<Watchlist> watchlists) async {
    final json = jsonEncode(watchlists.map((w) => w.toJson()).toList());
    await _prefs.setString(StorageKeys.watchlists, json);
  }

  List<Holding> loadHoldings() {
    final raw = _prefs.getString(StorageKeys.holdings);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Holding.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveHoldings(List<Holding> holdings) async {
    final json = jsonEncode(holdings.map((h) => h.toJson()).toList());
    await _prefs.setString(StorageKeys.holdings, json);
  }

  Decimal loadWalletBalance() {
    final raw = _prefs.getString(StorageKeys.walletBalance);
    if (raw == null) return Decimal.parse(kInitialWalletBalance);
    return Decimal.parse(raw);
  }

  Future<void> saveWalletBalance(Decimal balance) async {
    await _prefs.setString(StorageKeys.walletBalance, balance.toString());
  }

  List<TradeOrder> loadOrders() {
    final raw = _prefs.getString(StorageKeys.orders);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => TradeOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveOrders(List<TradeOrder> orders) async {
    final json = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _prefs.setString(StorageKeys.orders, json);
  }

  int loadTickInterval() {
    return _prefs.getInt(StorageKeys.tickIntervalMs) ?? kDefaultTickIntervalMs;
  }

  Future<void> saveTickInterval(int ms) async {
    await _prefs.setInt(StorageKeys.tickIntervalMs, ms);
  }
}
