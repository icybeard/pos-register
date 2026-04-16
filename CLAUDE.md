# CLAUDE.md — pos-register

Flutter register client. Read this before making changes.

## Stack

- Flutter 3.x (Dart 3) + BLoC for state
- [drift](https://drift.simonbinder.eu) (SQLite with WAL) as local source of truth
- gRPC client for `Subscribe` stream, REST for push/pull sync
- Targets: Windows, Linux, macOS, Android, iOS
- l10n: қазақша + русский (all UI strings via `l10n.yaml` ARB files)

## Locked rules

- **Money in tiyin (`int`)**. 1 ₸ = 100 тиын. No floats for money anywhere.
- **Weighted goods:** `total = (weight_g / 1000) × price_per_kg_tiyin`
- **Every product must have NTIN** (National Commodity Catalogue id). Temporary XTIN valid 30 days.
- **KZ VAT rates:** 12% or 0%. Never 10% or 20%.
- **Currency:** tenge (₸), ISO code KZT.
- **RAM target:** < 150 MB on cash register hardware.
- **Startup:** < 3 seconds.
- **Offline-first:** drift is source of truth. All writes go to drift first; `sync_outbox` drains later.

## Architecture constraints

- **No master-cash-register.** Registers are thin clients to the central server (cloud/SaaS). Each register is independent.
- Receipts + stock movements are owned by the register, pushed to server.
- Master data (products, prices, cashiers) is owned by server, pulled to register.

## Proto

Proto schemas live in `proto/` as a git submodule (→ `pos-shared`). Do not edit them here — change in `pos-shared`, bump the submodule pointer.

```bash
git submodule update --remote proto
make proto-gen     # regen Dart stubs
```

## Related repos

- pos-server — .NET central API
- pos-admin — React admin panel
- pos-shared — proto + product spec
