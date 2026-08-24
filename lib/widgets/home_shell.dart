import 'package:flutter/material.dart';

import '../features/holdings/holdings_screen.dart';
import '../features/market/market_screen.dart';
import '../features/watchlist/watchlist_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.star_outline, label: 'Watchlist'),
    (icon: Icons.show_chart, label: 'Market'),
    (icon: Icons.account_balance_wallet_outlined, label: 'Holdings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          WatchlistScreen(),
          MarketScreen(),
          HoldingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(_selectedIcon(tab.icon)),
              label: tab.label,
            ),
        ],
      ),
    );
  }

  IconData _selectedIcon(IconData outline) {
    return switch (outline) {
      Icons.star_outline => Icons.star,
      Icons.show_chart => Icons.show_chart,
      Icons.account_balance_wallet_outlined => Icons.account_balance_wallet,
      _ => outline,
    };
  }
}
