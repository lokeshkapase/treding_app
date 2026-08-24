import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../services/market_data_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/stock_widgets.dart';
import '../trade/trade_ticket_screen.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketDataService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Tick rate settings',
            onPressed: () => _showTickSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              'Tick: ${market.tickIntervalMs}ms (~${market.ticksPerSecondPerStock.toStringAsFixed(1)}/s per stock)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: kStockSymbols.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final symbol = kStockSymbols[index];
                return StockPriceRow(
                  key: ValueKey('market_$symbol'),
                  symbol: symbol,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TradeTicketScreen(symbol: symbol),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTickSettings(BuildContext context) async {
    final market = context.read<MarketDataService>();
    final storage = context.read<StorageService>();

    final presets = [
      (label: 'Normal (200ms)', ms: 200),
      (label: 'Fast (100ms)', ms: 100),
      (label: 'Stress (50ms)', ms: 50),
    ];

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Mock feed tick rate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Lower interval = more ticks. Stress mode (~20 ticks/s per stock) tests UI performance.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              for (final preset in presets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () async {
                      market.setTickInterval(preset.ms);
                      await storage.saveTickInterval(preset.ms);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(preset.label),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
