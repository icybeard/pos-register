# pos-register

Flutter register client for the POS System Kazakhstan stack. Runs on Windows, Linux, macOS, Android, and iOS. Local-first: SQLite via [drift](https://drift.simonbinder.eu) is the source of truth on the device, `sync_outbox` drains to the central server when online. Works fully offline.

## Sibling repos

- **[pos-server](https://github.com/icybeard/pos-server)** — .NET 9 central API (REST + gRPC Subscribe, PostgreSQL 16 + RLS).
- **[pos-admin](https://github.com/icybeard/pos-admin)** — React admin panel.
- **[pos-shared](https://github.com/icybeard/pos-shared)** — Protobuf schemas + product spec. Consumed here as a git submodule at `proto/`.

## Run locally (no server required)

```bash
git clone --recurse-submodules https://github.com/icybeard/pos-register.git
cd pos-register
flutter pub get
flutter run -d macos    # or: linux / windows / chrome / <device>
```

The register works fully offline against its local drift DB. To talk to a server, activate it from the admin panel.

> **First `flutter pub get` (and first build per platform) compiles ~13 MB of SQLite3 Multiple Ciphers source from [third_party/sqlite3mc/](third_party/sqlite3mc/).** Takes ~60–90 s per target triple; cached afterward in `.dart_tool/hooks_runner/`. See [third_party/sqlite3mc/README.md](third_party/sqlite3mc/README.md) for why it's vendored (self-contained builds — no GitHub-release-CDN dependency).

## Run against a local server

1. Start `pos-server` (see its README — Postgres on :5433, API on :5000).
2. Start `pos-register`.
3. In the admin panel, click **Activate Register** to bind this device to a tenant + workstation id.

## Regenerate proto stubs

```bash
dart pub global activate protoc_plugin   # first time only
make proto-gen
```

## Tests

```bash
make test           # unit + widget + BLoC tests, golden-PDF receipts
make analyze        # flutter analyze
```

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).
