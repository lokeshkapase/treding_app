/// The 10 stocks used throughout the app.
const List<String> kStockSymbols = [
  'RELIANCE',
  'TCS',
  'INFY',
  'HDFCBANK',
  'ICICIBANK',
  'SBIN',
  'ITC',
  'LT',
  'BHARTIARTL',
  'AXISBANK',
];

/// Reasonable starting prices (₹) for each stock.
const Map<String, String> kStartingPrices = {
  'RELIANCE': '2450.00',
  'TCS': '3850.00',
  'INFY': '1520.00',
  'HDFCBANK': '1680.00',
  'ICICIBANK': '1120.00',
  'SBIN': '620.00',
  'ITC': '420.00',
  'LT': '3400.00',
  'BHARTIARTL': '1180.00',
  'AXISBANK': '1050.00',
};

/// Default wallet balance for new users.
const String kInitialWalletBalance = '1000000.00';

/// Default mock feed tick interval in milliseconds.
const int kDefaultTickIntervalMs = 200;

/// Storage keys for SharedPreferences.
class StorageKeys {
  static const watchlists = 'watchlists';
  static const holdings = 'holdings';
  static const walletBalance = 'wallet_balance';
  static const orders = 'orders';
  static const tickIntervalMs = 'tick_interval_ms';
}
