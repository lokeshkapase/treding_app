import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/portfolio_state.dart';
import '../../widgets/stock_widgets.dart';
import 'watchlist_detail_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New watchlist',
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: portfolio.watchlists.isEmpty
          ? EmptyState(
              icon: Icons.playlist_add,
              title: 'No watchlists yet',
              subtitle: 'Create a watchlist to track your favourite stocks.',
              action: FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create watchlist'),
              ),
            )
          : ListView.separated(
              itemCount: portfolio.watchlists.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final watchlist = portfolio.watchlists[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${watchlist.symbols.length}'),
                  ),
                  title: Text(watchlist.name),
                  subtitle: Text(
                    watchlist.symbols.isEmpty
                        ? 'Empty'
                        : watchlist.symbols.take(4).join(', ') +
                            (watchlist.symbols.length > 4 ? '…' : ''),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'rename') {
                        await _showRenameDialog(context, watchlist.id, watchlist.name);
                      } else if (action == 'delete') {
                        await _confirmDelete(context, watchlist.id, watchlist.name);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'rename', child: Text('Rename')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => WatchlistDetailScreen(watchlistId: watchlist.id),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New watchlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<PortfolioState>().createWatchlist(name);
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    String id,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename watchlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<PortfolioState>().renameWatchlist(id, name);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete watchlist?'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PortfolioState>().deleteWatchlist(id);
    }
  }
}
