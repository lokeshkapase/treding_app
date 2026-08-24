import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../services/portfolio_state.dart';
import '../../widgets/stock_widgets.dart';
import '../trade/trade_ticket_screen.dart';

class WatchlistDetailScreen extends StatelessWidget {
  const WatchlistDetailScreen({super.key, required this.watchlistId});

  final String watchlistId;

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioState>();
    final watchlist = portfolio.watchlistById(watchlistId);

    if (watchlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Watchlist not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(watchlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add stock',
            onPressed: () => _showStockPicker(context, watchlistId, watchlist.symbols),
          ),
        ],
      ),
      body: watchlist.symbols.isEmpty
          ? EmptyState(
              icon: Icons.candlestick_chart_outlined,
              title: 'No stocks in this watchlist',
              subtitle: 'Add stocks from the 10 available symbols.',
              action: FilledButton.icon(
                onPressed: () =>
                    _showStockPicker(context, watchlistId, watchlist.symbols),
                icon: const Icon(Icons.add),
                label: const Text('Add stock'),
              ),
            )
          : ReorderableListView.builder(
              itemCount: watchlist.symbols.length,
              onReorder: (oldIndex, newIndex) {
                context.read<PortfolioState>().reorderWatchlistStock(
                      watchlistId,
                      oldIndex,
                      newIndex,
                    );
              },
              itemBuilder: (context, index) {
                final symbol = watchlist.symbols[index];
                return StockPriceRow(
                  key: ValueKey(symbol),
                  symbol: symbol,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TradeTicketScreen(symbol: symbol),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StockQuoteBuilder(
                        symbol: symbol,
                        builder: (_, quote) => PriceChangeText(
                          change: quote.change,
                          changePercent: quote.changePercent,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Remove',
                        onPressed: () {
                          context.read<PortfolioState>().removeStockFromWatchlist(
                                watchlistId,
                                symbol,
                              );
                        },
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showStockPicker(
    BuildContext context,
    String watchlistId,
    List<String> existing,
  ) async {
    final available = kStockSymbols.where((s) => !existing.contains(s)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All stocks are already in this watchlist')),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Add stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (_, i) {
                  final symbol = available[i];
                  return ListTile(
                    title: Text(symbol),
                    onTap: () => Navigator.pop(ctx, symbol),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && context.mounted) {
      await context.read<PortfolioState>().addStockToWatchlist(watchlistId, selected);
    }
  }
}
