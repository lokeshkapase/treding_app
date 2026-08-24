import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/order.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final TradeOrder order;

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: isBuy ? Colors.green.shade600 : Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              '${isBuy ? 'Buy' : 'Sell'} order executed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: 'Symbol', value: order.symbol),
                    _DetailRow(
                      label: 'Side',
                      value: isBuy ? 'Buy' : 'Sell',
                    ),
                    _DetailRow(
                      label: 'Quantity',
                      value: AppFormatters.quantity(order.quantity),
                    ),
                    _DetailRow(
                      label: 'Price',
                      value: AppFormatters.price(order.price),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      label: 'Order value',
                      value: AppFormatters.price(order.orderValue),
                      bold: true,
                    ),
                    _DetailRow(
                      label: 'Executed at',
                      value: AppFormatters.dateTime(order.executedAt),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Back to app'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
