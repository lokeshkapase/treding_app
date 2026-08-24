# Trading App (Flutter Assignment)

A mock trading app with watchlists, live market prices, buy/sell orders, and portfolio holdings. Built with Flutter (stable) and a single in-app mock market-data feed.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- A device/emulator (Android, iOS, Windows, macOS, Linux, or Chrome)

## Run

```bash
flutter pub get
flutter run
```

No backend, API keys, or extra setup required.

## Walkthrough video

End-to-end demo of all four features:

**[Screenrecorder-2026-08-24-21-09-44-584.mp4](./Screenrecorder-2026-08-24-21-09-44-584.mp4)**

GitHub: [Watch on GitHub](https://github.com/lokeshkapase/treding_app/blob/master/Screenrecorder-2026-08-24-21-09-44-584.mp4)

The recording covers:

1. Watchlist — create/rename, add stocks, reorder, remove
2. Live Market — live ticks and stress tick rate
3. Buy/Sell — place orders, validation, confirmation
4. Holdings — live P&L, sorting, portfolio summary
5. App restart — watchlists, holdings, and balance restored

## Features

### 1. Watchlist
- Create, rename, and delete multiple watchlists
- Add stocks from the 10 supported symbols via a picker
- Drag to reorder; swipe/remove via the close button
- Live LTP, change, and change % per row
- Persists across restarts (SharedPreferences)
- Tap a row to open the Buy/Sell ticket pre-filled

### 2. Live Market
- All 10 stocks with live updating prices
- Green/red flash on up/down ticks
- Configurable tick rate (Market tab → tune icon): Normal (200ms), Fast (100ms), Stress (50ms)
- `MarketDataService` is the single source of price data for the entire app
- Per-symbol `Selector` widgets minimize rebuilds under load

### 3. Buy / Sell Ticket
- Side toggle (Buy/Sell), quantity input, live LTP and projected order value
- Validates balance (buy), holdings (sell), and quantity (positive integers only)
- Executes at current LTP; updates wallet and holdings
- Order confirmation screen; wallet, holdings, and order history persist

### 4. Holdings
- Portfolio summary: invested, current value, total P&L (₹ and %)
- Per-row: symbol, qty, avg cost, LTP, current value, P&L
- Sort by P&L (default), symbol, or current value — reorders live as prices move
- Tap a row to trade; empty state when no holdings

## Stocks

RELIANCE, TCS, INFY, HDFCBANK, ICICIBANK, SBIN, ITC, LT, BHARTIARTL, AXISBANK

## Architecture

```
lib/
├── main.dart                 # App entry + storage init
├── app.dart                  # Provider setup
├── core/                     # Constants, money, formatters, theme
├── models/                   # Domain models
├── services/
│   ├── market_data_service.dart   # Mock price feed (single source)
│   ├── portfolio_state.dart       # Watchlists, holdings, orders, wallet
│   └── storage_service.dart       # SharedPreferences persistence
├── features/
│   ├── watchlist/
│   ├── market/
│   ├── trade/
│   └── holdings/
└── widgets/                  # Reusable stock UI (Selector-based rows)
```

## Tech choices

- **provider** — state management; `Selector` for granular rebuilds
- **decimal** — precise money math (no float drift in UI)
- **shared_preferences** — local persistence

## Initial wallet

New users start with **₹10,00,000.00** paper balance.
