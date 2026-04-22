# SQLite3 Multiple Ciphers (vendored)

Upstream: https://github.com/utelle/SQLite3MultipleCiphers
Version: **v2.3.3** (based on SQLite 3.53.0)
License: MIT — see `LICENSE`.

## Why it's vendored

The `sqlite3` pub package (^3.0.0 override in `pubspec.yaml`) uses a native-asset
hook that downloads pre-compiled dylibs from `release-assets.githubusercontent.com`
on every `flutter pub get`. That CDN is unreachable from some networks in KZ.
Vendoring the sqlite3mc amalgamation + configuring the hook with
`source: source` (see `pubspec.yaml`'s `hooks.user_defines.sqlite3`) makes the
build self-contained — `flutter pub get` compiles this C file locally instead.

## Why sqlite3mc, not SQLCipher proper

The register encrypts its drift DB via `PRAGMA key` (SQLCipher-compatible).
sqlite3mc:
- accepts the same `PRAGMA key` wire format with `SQLITE3MC_USE_SQL_CIPHER=1`;
- ships its own AES — no `-framework Security` on iOS/macOS, no libcrypto on
  Linux/Android, no OpenSSL on Windows;
- MIT-licensed (looser than SQLCipher Community BSD).

One amalgamation works across all five target platforms.

## Re-vendoring (future version bump)

```bash
cd /tmp && rm -rf sqlite3mc-dl && mkdir sqlite3mc-dl && cd sqlite3mc-dl
gh release download vX.Y.Z --repo utelle/SQLite3MultipleCiphers \
  --pattern 'sqlite3mc-*-amalgamation.zip'
unzip -o sqlite3mc-*.zip
cp sqlite3mc_amalgamation.c sqlite3mc_amalgamation.h sqlite3.h \
  <repo>/third_party/sqlite3mc/
curl -sL https://raw.githubusercontent.com/utelle/SQLite3MultipleCiphers/vX.Y.Z/LICENSE \
  -o <repo>/third_party/sqlite3mc/LICENSE
```

Do NOT modify the amalgamation files locally — keep them byte-identical to the
upstream release so future upgrades are a clean replace.
