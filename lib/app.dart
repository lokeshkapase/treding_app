import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'services/market_data_service.dart';
import 'services/portfolio_state.dart';
import 'services/storage_service.dart';
import 'widgets/home_shell.dart';

class TradingApp extends StatelessWidget {
  const TradingApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider(
          create: (_) {
            final tickMs = storage.loadTickInterval();
            final market = MarketDataService(tickIntervalMs: tickMs)..start();
            return market;
          },
        ),
        ChangeNotifierProxyProvider<MarketDataService, PortfolioState>(
          create: (context) => PortfolioState(
            storage: storage,
            marketData: context.read<MarketDataService>(),
          ),
          update: (_, market, previous) =>
              previous ??
              PortfolioState(storage: storage, marketData: market),
        ),
      ],
      child: MaterialApp(
        title: 'Trading App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeShell(),
      ),
    );
  }
}
