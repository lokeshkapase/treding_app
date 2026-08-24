import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/holding.dart';
import '../../services/portfolio_state.dart';
import '../../widgets/stock_widgets.dart';
import '../trade/trade_ticket_screen.dart';

class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioState>();
    final summary = portfolio.portfolioSummary();
    final sorted = portfolio.sortedHoldings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
        actions: [
          PopupMenuButton<HoldingsSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort holdings',
            initialValue: portfolio.holdingsSort,
            onSelected: portfolio.setHoldingsSort,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: HoldingsSort.pnlDesc,
                child: Text('P&L (high to low)'),
              ),
              PopupMenuItem(
                value: HoldingsSort.symbolAsc,
                child: Text('Symbol (A–Z)'),
              ),
              PopupMenuItem(
                value: HoldingsSort.valueDesc,
                child: Text('Current value (high to low)'),
              ),
            ],
          ),
        ],
      ),
      body: portfolio.holdings.isEmpty
          ? const EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No holdings yet',
              subtitle: 'Buy stocks from a watchlist or the market tab to build your portfolio.',
            )
          : Column(
              children: [
                _PortfolioSummary(summary: summary),
                Expanded(
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final holding = sorted[index];
                      return _HoldingRow(
                        key: ValueKey(holding.symbol),
                        holding: holding,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary({required this.summary});

  final ({
    Decimal invested,
    Decimal currentValue,
    Decimal pnl,
    Decimal pnlPercent,
  }) summary;

  @override
  Widget build(BuildContext context) {
    final isGain = summary.pnl >= Decimal.zero;
    final pnlColor = isGain ? AppTheme.gainGreen : AppTheme.lossRed;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio summary',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Invested',
                  value: AppFormatters.price(summary.invested),
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'Current value',
                  value: AppFormatters.price(summary.currentValue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Total P&L ',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              Text(
                '${AppFormatters.signedChange(summary.pnl)} (${AppFormatters.signedPercent(summary.pnlPercent)})',
                style: TextStyle(
                  color: pnlColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({super.key, required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    return Selector<PortfolioState, HoldingMetrics>(
      selector: (_, portfolio) => portfolio.metricsFor(holding),
      shouldRebuild: (prev, next) =>
          prev.currentValue != next.currentValue ||
          prev.pnl != next.pnl ||
          prev.quote.ltp != next.quote.ltp,
      builder: (context, metrics, _) {
        final isGain = metrics.pnl >= Decimal.zero;
        final pnlColor = isGain ? AppTheme.gainGreen : AppTheme.lossRed;

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TradeTicketScreen(symbol: holding.symbol),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        holding.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      AppFormatters.price(metrics.quote.ltp),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Qty ${AppFormatters.quantity(holding.quantity)} · Avg ${AppFormatters.price(holding.avgCost)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                    Text(
                      AppFormatters.price(metrics.currentValue),
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'P&L ${AppFormatters.signedChange(metrics.pnl)} (${AppFormatters.signedPercent(metrics.pnlPercent)})',
                  style: TextStyle(color: pnlColor, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
