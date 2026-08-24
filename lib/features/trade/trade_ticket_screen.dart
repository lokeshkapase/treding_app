import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/order.dart';
import '../../services/portfolio_state.dart';
import '../../widgets/stock_widgets.dart';
import 'order_confirmation_screen.dart';

class TradeTicketScreen extends StatefulWidget {
  const TradeTicketScreen({
    super.key,
    required this.symbol,
    this.initialSide = OrderSide.buy,
  });

  final String symbol;
  final OrderSide initialSide;

  @override
  State<TradeTicketScreen> createState() => _TradeTicketScreenState();
}

class _TradeTicketScreenState extends State<TradeTicketScreen> {
  late OrderSide _side;
  final _qtyController = TextEditingController();
  String? _quantityError;
  String? _submitError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
    _qtyController.addListener(_clearErrors);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_quantityError != null || _submitError != null) {
      setState(() {
        _quantityError = null;
        _submitError = null;
      });
    }
  }

  Decimal? _parseQuantity() {
    final raw = _qtyController.text.trim();
    if (raw.isEmpty) return null;
    try {
      return Decimal.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String? _validateQuantity(Decimal? qty, PortfolioState portfolio) {
    if (qty == null) {
      return 'Enter a valid quantity';
    }
    if (qty <= Decimal.zero) {
      return 'Quantity must be greater than zero';
    }
    if (qty != qty.truncate()) {
      return 'Fractional quantities are not allowed';
    }
    if (_side == OrderSide.sell && qty > portfolio.quantityHeld(widget.symbol)) {
      return 'You only hold ${AppFormatters.quantity(portfolio.quantityHeld(widget.symbol))} shares';
    }
    return null;
  }

  Future<void> _submit(PortfolioState portfolio, Decimal ltp) async {
    final qty = _parseQuantity();
    final qtyError = _validateQuantity(qty, portfolio);
    if (qtyError != null) {
      setState(() => _quantityError = qtyError);
      return;
    }

    final orderValue = ltp * qty!;
    if (_side == OrderSide.buy && orderValue > portfolio.walletBalance) {
      setState(() {
        _submitError =
            'Insufficient balance. Available: ${AppFormatters.price(portfolio.walletBalance)}';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final order = await portfolio.placeOrder(
      side: _side,
      symbol: widget.symbol,
      quantity: qty,
    );

    if (!mounted) return;

    if (order == null) {
      setState(() {
        _submitting = false;
        _submitError = _side == OrderSide.buy
            ? 'Insufficient balance for this order'
            : 'Insufficient quantity to sell';
      });
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_side == OrderSide.buy ? 'Buy' : 'Sell'} ${widget.symbol}'),
      ),
      body: StockQuoteBuilder(
        symbol: widget.symbol,
        builder: (context, quote) {
          final qty = _parseQuantity();
          final projectedValue = qty != null && qty > Decimal.zero
              ? quote.ltp * qty
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.symbol,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'LTP ',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            AppFormatters.price(quote.ltp),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          PriceChangeText(
                            change: quote.change,
                            changePercent: quote.changePercent,
                            compact: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<OrderSide>(
                segments: const [
                  ButtonSegment(
                    value: OrderSide.buy,
                    label: Text('Buy'),
                    icon: Icon(Icons.add_shopping_cart),
                  ),
                  ButtonSegment(
                    value: OrderSide.sell,
                    label: Text('Sell'),
                    icon: Icon(Icons.sell_outlined),
                  ),
                ],
                selected: {_side},
                onSelectionChanged: (selection) {
                  setState(() {
                    _side = selection.first;
                    _quantityError = null;
                    _submitError = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  errorText: _quantityError,
                  helperText: _side == OrderSide.sell
                      ? 'Held: ${AppFormatters.quantity(portfolio.quantityHeld(widget.symbol))}'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                label: 'Order value (at LTP)',
                value: projectedValue != null
                    ? AppFormatters.price(projectedValue)
                    : '—',
                emphasized: true,
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Available balance',
                value: AppFormatters.price(portfolio.walletBalance),
              ),
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _submitError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting
                    ? null
                    : () => _submit(portfolio, quote.ltp),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Place ${_side == OrderSide.buy ? 'Buy' : 'Sell'} Order'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            fontSize: emphasized ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
