import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/stock_quote.dart';
import '../services/market_data_service.dart';

/// Rebuilds only when this symbol's quote changes.
class StockQuoteBuilder extends StatelessWidget {
  const StockQuoteBuilder({
    super.key,
    required this.symbol,
    required this.builder,
  });

  final String symbol;
  final Widget Function(BuildContext context, StockQuote quote) builder;

  @override
  Widget build(BuildContext context) {
    return Selector<MarketDataService, StockQuote>(
      selector: (_, market) => market.quoteFor(symbol),
      shouldRebuild: (prev, next) => prev != next,
      builder: (context, quote, _) => builder(context, quote),
    );
  }
}

class PriceChangeText extends StatelessWidget {
  const PriceChangeText({
    super.key,
    required this.change,
    required this.changePercent,
    this.compact = false,
  });

  final Decimal change;
  final Decimal changePercent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isGain = change >= Decimal.zero;
    final color = isGain ? AppTheme.gainGreen : AppTheme.lossRed;
    if (compact) {
      return Text(
        AppFormatters.signedPercent(changePercent),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppFormatters.signedChange(change),
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        Text(
          AppFormatters.signedPercent(changePercent),
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}

/// Row with flash animation on price update.
class StockPriceRow extends StatefulWidget {
  const StockPriceRow({
    super.key,
    required this.symbol,
    this.onTap,
    this.trailing,
    this.subtitle,
    this.showFlash = true,
  });

  final String symbol;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? subtitle;
  final bool showFlash;

  @override
  State<StockPriceRow> createState() => _StockPriceRowState();
}

class _StockPriceRowState extends State<StockPriceRow> {
  Color? _flashColor;
  Decimal? _lastLtp;

  void _maybeFlash(StockQuote quote) {
    if (!widget.showFlash || quote.lastDirection == PriceDirection.flat) return;
    if (_lastLtp == quote.ltp) return;
    _lastLtp = quote.ltp;

    final flash = quote.lastDirection == PriceDirection.up
        ? AppTheme.gainFlash
        : AppTheme.lossFlash;
    setState(() => _flashColor = flash);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _flashColor = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StockQuoteBuilder(
      symbol: widget.symbol,
      builder: (context, quote) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeFlash(quote);
        });

        return Material(
          color: _flashColor ?? Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (widget.subtitle != null) widget.subtitle!,
                      ],
                    ),
                  ),
                  Text(
                    AppFormatters.price(quote.ltp),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 16),
                  widget.trailing ??
                      PriceChangeText(
                        change: quote.change,
                        changePercent: quote.changePercent,
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
