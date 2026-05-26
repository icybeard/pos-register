# pos-register

**🇬🇧 English** · [🇰🇿 Қазақша](README.kk.md) · [🇷🇺 Русский](README.ru.md) 

---

Open-source point-of-sale register for Kazakhstan retail. Runs on Windows,
Linux, macOS, Android, and iOS — works offline by default, syncs to the
cloud when it has a connection.

Built in Flutter. Free to use, free to inspect, free to fork. Apache 2.0.

---

## What is this?

`pos-register` is the cash-register app that runs on the till. It handles
scanning, weighing, discounts, splits, debt-on-account, fiscal receipts,
and the daily shift open / close + X-report / Z-report flow.

It's one piece of a small family of open-source POS apps for shops in
Kazakhstan (and anywhere the same patterns fit — VAT 12 % or 0 %, tenge,
NTIN / XTIN product catalogue):

| Repo | What it does |
|---|---|
| **pos-register** _(this repo)_ | the cashier app on the till |
| [pos-server](https://github.com/icybeard/pos-server) | the cloud side — .NET 10 + PostgreSQL 16, multi-tenant with row-level security |
| [pos-admin](https://github.com/icybeard/pos-admin) | the back-office web app (products, stock, payment calendar, reports) |
| [pos-shared](https://github.com/icybeard/pos-shared) | the wire-format contracts — protobuf schemas shared by all three |

Each repo is a real, working app you can clone today. The register runs
fully on its own with a local SQLite database if you want to kick the
tyres before standing up the cloud side.

---

## For shop owners and accountants

You don't have to be a developer to use this. The first release ships with
a small, focused admin surface — enough to run a single-store shop end to
end: products, prices, cashiers, shifts, receipts, the basic stock list,
and the payment calendar. Bigger features (multi-store transfers, batch /
expiry tracking, recipes for café menus, supplier price lists, etc.) are
already in the codebase and shipping over the next few releases — see
[`specs/`](https://github.com/icybeard/pos-docs/tree/main/specs) in
[pos-docs](https://github.com/icybeard/pos-docs) for the roadmap.

If you'd like to try it on real hardware, the easiest path is:

1. Install Flutter on a laptop. ([How to install Flutter →](https://docs.flutter.dev/get-started/install))
2. Run the three commands in **Quick start** below.
3. The register opens on your screen with an empty cart and no products.
4. To get products, prices, and cashiers, you'll also want pos-server + pos-admin running. The README in [pos-server](https://github.com/icybeard/pos-server) walks through the cloud side.

If you'd rather have someone set it up for you, the project is young and
there isn't yet a "buy a hosted plan" button — that's coming. In the
meantime, the code is yours: any developer can stand up the stack from
this repo + the other three.

---

## For developers

```bash
git clone --recurse-submodules https://github.com/icybeard/pos-register.git
cd pos-register
flutter pub get
flutter run -d macos    # or: linux / windows / chrome / <device>
```

That's the full quick start — no server, no Postgres, no Docker. The
register runs against a local SQLite database (via
[drift](https://drift.simonbinder.eu/)) and is fully usable offline. The
local DB is the source of truth on the device; `sync_outbox` drains to
the central server when one is reachable.

> **Heads-up on first build.** The first `flutter pub get` (and the
> first build per platform) compiles ~13 MB of SQLite3 Multiple Ciphers
> source from [`third_party/sqlite3mc/`](third_party/sqlite3mc/). That
> takes ~60–90 s per target triple, then it caches in
> `.dart_tool/hooks_runner/`. We vendor the source so builds are
> self-contained — no dependency on the GitHub-release CDN being up.
> See [`third_party/sqlite3mc/README.md`](third_party/sqlite3mc/README.md)
> for the why.

### Run against a local server

1. Start [pos-server](https://github.com/icybeard/pos-server) (its README
   covers Postgres on `:5433` and the API on `:5000`).
2. Start `pos-register`.
3. From [pos-admin](https://github.com/icybeard/pos-admin), open
   **Register → Activate** to bind this device to a tenant + workstation
   id. The register starts pulling product / cashier / shift data over
   sync.

### Regenerate proto stubs

```bash
dart pub global activate protoc_plugin   # first time only
make proto-gen
```

Proto schemas live in [pos-shared](https://github.com/icybeard/pos-shared)
as a git submodule at `proto/`. Edit there, bump the submodule pointer
here, regenerate.

### Tests

```bash
make test       # unit + widget + BLoC tests, golden-PDF receipts
make analyze    # flutter analyze (must be clean before PR)
```

### What's inside

| Stack | |
|---|---|
| Flutter 3.x + Dart 3 | UI + state (BLoC) |
| drift (SQLite + WAL) | local source of truth |
| gRPC Subscribe stream | real-time stock pushes from the server |
| REST sync push / pull | bulk catalogue + receipt sync |
| Apache 2.0 | the whole thing, no strings |

A few locked-in conventions worth knowing before you contribute:

- **Money is integer tiyin** (1 ₸ = 100 тиын). No floats anywhere on the wire or in calculations.
- **Weighted goods**: `total = (weight_g / 1000) × price_per_kg_tiyin`.
- **VAT rates**: 12 % or 0 % (never 10 / 20). Kazakhstan-specific.
- **NTIN / XTIN**: every product needs a National Commodity Catalogue id; temporary XTIN is valid 30 days.
- **Offline-first**: every write hits drift first. The sync layer drains later. If you find a spot that writes to the server before drift, that's a bug.
- **No master cash register**. Each register is a thin client to the cloud — there's no "primary" register that other tills depend on.

The full architectural read-out is in [`CLAUDE.md`](CLAUDE.md) (originally
written as an AI-agent briefing, but it's the most concise project
overview we have).

---

## Project status

This is a young project. Things will break, designs will change, and the
first few releases will lean on technical users to fill the gaps in
admin tooling. We're being deliberate about not over-promising before
the code is ready.

- ✅ Cashier flow, scan / weigh / discount, mixed payment, debt on account.
- ✅ Offline operation + sync.
- ✅ Two-language UI (русский, қазақша).
- 🟡 Admin surface (products, stock, payment calendar, reports) — minimal but functional in v1; expanding each release.
- 🟡 NKT integration (nct.kz lookup) — works for the common cases; rough edges remain.
- ⏳ Webkassa fiscalisation (Phase P8) — designed, not yet shipped.
- ⏳ Bank reconciliation, Telegram notifications, multi-currency, 1С export, ЭСФ — designed, not yet shipped.

If you want to follow the roadmap, [pos-docs](https://github.com/icybeard/pos-docs)
has the per-feature specs and an implementation log.

---

## Contributing

PRs welcome. The shortest path:

1. Open or comment on an issue first so we don't duplicate work.
2. Branch from `main`, keep PRs focused (one feature or fix per PR).
3. `make analyze && make test` must be clean.
4. New user-facing strings go through the l10n ARB files
   (`lib/core/l10n/app_ru.arb` + `app_kk.arb`) — no hardcoded text in widgets.
5. Money stays integer tiyin. Always.

There's no CLA. Contributions are licensed under Apache 2.0, same as the
project.

---

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).

Copyright 2026 Adil Tansykbayev and the pos-register contributors.
