# Flutter POS App — Architecture & Screen Reference

> **Doc status (2026-07-05):** the top sections below (Overview → API
> Communication, Dependencies, Running) are kept current. The **Screens**
> and **state-management reference** sections further down were written
> against the early prototype and are kept as behavioral reference — the
> domain rules they describe (PIN lockout tiers, NKT fallback, payment
> flows) still hold, but class names (`AuthBloc`, `SalesBloc`) are
> pre-Riverpod, and the app has since grown screens they don't cover
> (setup wizard, returns, X-report, manager override, approvals, delivery,
> analytics, audit). For locked invariants read `CLAUDE.md`; for the
> product-level view read `README.md`.

## Overview

Cross-platform POS register for retail in Kazakhstan. Offline-first: Flutter 3.x with **Riverpod** state management and a local **drift** (SQLite, WAL) database as the source of truth; syncs to the .NET central server (`pos-server`) via REST push/pull (`sync_outbox` deltas).

**Stack**: Flutter 3.x (Dart 3) | Riverpod 2.x | drift (SQLite) | dio/http REST + gRPC stubs | bundled fonts

**Platforms**: Windows, Linux, macOS, Android, iOS (web is not a shipping target)

## Architecture

```
lib/
├── main.dart                          # Entry point, navigation shell, sidebar
├── core/
│   ├── constants/                     # Currency, VAT, PIN length, breakpoints
│   ├── feature_flags.dart
│   ├── l10n/                          # ARB-driven strings (kk + ru)
│   ├── theme/                         # app_theme.dart + hifi.dart design tokens
│   ├── utils/                         # Tiyin formatting, VAT, weight calc
│   └── widgets/                       # NumPad, sync status chip/sheet, brand mark
├── data/
│   ├── database.dart                  # drift database (source of truth)
│   ├── tables/                        # drift table definitions
│   └── repositories/                  # typed access over drift
├── features/                          # screen + controller per domain
│   ├── auth/       ├── sales/         # controllers/*_controller.dart (Riverpod
│   ├── products/   ├── users/         #   Notifier), screens/, widgets/
│   ├── clients/    ├── settings/
│   ├── setup/      ├── analytics/
│   ├── approval/   ├── audit/
│   └── delivery/
├── services/                          # auth, products, sales, stock, sync,
│                                      #   reports, reconciliation, override, locale
├── sync/                              # outbox drain + pull cursor client
└── migration/                         # legacy-data migration helpers
```

### Patterns

- **Features-based** directory structure — each domain has its own controllers/models/screens/widgets
- **Riverpod Notifier controllers** for complex state (`lib/features/*/controllers/*_controller.dart` — migrated from flutter_bloc in Phase 0b, one method per former event); StatefulWidget for simpler screens
- **Immutable models** with computed properties (CartItem.total, CartItem.vatAmount)
- **Responsive layouts** — width breakpoints: ≥800px wide (sidebar + split), <800px narrow (bottom nav + tabs)
- **Theme-driven** — all colors/typography from `AppTheme`; semantic helpers via `PosColors.of(context)`

### Design System — "Architectural Ledger" (Stitch V4)

> Superseded in practice by the hi-fi pass (`lib/core/theme/hifi.dart`, Variant C,
> 2026-04) and the **KeregeSystem** brand (mark + palette in `assets/brand/`);
> fonts are now bundled, not fetched from Google Fonts. The tokens below are the
> original Stitch V4 baseline the hi-fi theme evolved from.

Based on stitch_design/ HTML mockups. Key principles:

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#002556` | Sidebar, headers, buttons, totals |
| Primary Container | `#003A80` | Gradient CTAs, badges |
| Secondary (Green) | `#006C49` | Success states, shift open |
| Tertiary (Red) | `#56000B` | Deletions, void, errors |
| Surface | `#F8F9FF` | Main background |
| Surface Container Low | `#EFF4FF` | Cards, inputs |
| Font | Inter | All text, Google Fonts |

**No-Line Rule**: Borders are avoided; sections are separated by background color shifts and whitespace.

**Gradient CTA**: `LinearGradient(primary → primaryContainer)` at 135° with drop shadow.

**Touch Targets**: Minimum 52px height for buttons; keypad keys 72px.

### Money & Currency

All prices stored as **tiyin** (INTEGER). 1 ₸ = 100 tiyin.

```dart
Money.format(144050)      // → "1 440,50 ₸"
Money.formatTenge(144050) // → "1 440 ₸"
Money.tengeToTiyin(14.5)  // → 1450
```

**Weighted goods**: `(weightGrams * pricePerKgTiyin + 500) ~/ 1000` (banker's rounding)

**VAT "inside"**: `totalTiyin * vatRate / (100 + vatRate)` — Kazakhstan standard 12% or 0%.

### Navigation

**Wide (≥700px)**: Dark sidebar (240px) with 6 nav items + shift status + user card. Top bar with status badge.

**Narrow (<700px)**: Bottom NavigationBar with 4 items (Касса, Товары, История, Ещё). "Ещё" opens a bottom sheet for remaining screens.

Nav items: КАССА (POS) → ИСТОРИЯ (Shift) → ТОВАРЫ (Products) → ПЕРСОНАЛ (Cashiers) → ДОЛГИ (Debts) → НАСТРОЙКИ (Settings)

### Data & Sync

**drift (SQLite, WAL) is the local source of truth** — every write lands in drift first; the register is fully functional offline. Sync to the .NET central server (`pos-server`) happens in the background:

- **Push**: receipts + stock movements queue in `sync_outbox` and drain to `POST /api/sync/push` (~2 KB deltas) when a connection exists.
- **Pull**: master data (products, prices, cashiers) arrives via cursor-based `GET /api/sync/pull` polling. A gRPC `Subscribe` stream is defined in `proto/` but not yet implemented server-side.
- **NKT**: national-catalog lookups (GTIN/NTIN/name) proxy through central.

`ApiClient` wraps the REST calls; `ApiException` carries HTTP status code + message. Sync state is surfaced in the UI via the sync status chip/sheet (`lib/core/widgets/`).

---

## Screens

### 1. PIN Authentication (`pin_screen.dart`)

**Purpose**: Cashier login via 4-digit PIN code.

**Layouts**:
- **Wide (≥800px)**: Split card — left panel (profile selection, terminal ID, branding) + right panel (welcome text, PIN dots, 4×3 keypad). Decorative blur blobs in background.
- **Narrow**: Centered logo + PIN dots + keypad.

**States**:
- `AuthInitial(isFirstRun: true)` → shows first-run setup (name + PIN + confirm)
- `AuthInitial(pin, error, failedAttempts, lockedUntil)` → shows keypad with PIN dots; error banner if wrong PIN; lockout countdown if locked
- `AuthLoading` → spinner
- `AuthAuthenticated` → navigates to main shell (handled in main.dart)

**Behavior**: Auto-login triggers when 4th digit is entered. Backspace and clear supported. First-run creates "owner" role cashier.

**Edge Cases & Security**:

| Scenario | Handling |
|----------|----------|
| **Wrong PIN** | Error message with remaining attempts count (e.g. "Неверный PIN (3 попытки)") |
| **5 consecutive failures** | Lockout 30 seconds — keypad disabled, countdown timer shown |
| **10 failures** | Lockout escalates to 2 minutes |
| **15 failures** | Lockout escalates to 5 minutes |
| **20+ failures** | Lockout escalates to 15 minutes (max tier) |
| **Successful login** | Resets all failure counters and lockout state |
| **Lockout during input** | Digit/backspace events silently blocked while `isLockedOut` is true |
| **Lockout persists across logout** | Counters preserved — logging out doesn't reset the lockout |
| **Server unreachable** | "Нет связи с сервером" error, does NOT count as a failed attempt toward lockout |
| **Server error (non-401)** | "Ошибка сервера" error, does NOT trigger lockout |
| **First-run setup** | PIN confirmation required (must match); no lockout on setup screen |
| **PIN too short** | Digits accumulate silently; login only triggers at exactly 4 digits |

**Lockout implementation**: `AuthBloc` tracks `_totalFailedAttempts` and `_lockedUntil` across state transitions. `AuthInitial.isLockedOut` checks `DateTime.now()` dynamically. UI shows `_LockoutCountdown` widget with 1-second refresh timer. Timer clears `_lockedUntil` when lockout expires.

**Stitch Design**: v4_pin_auth — rounded keypad buttons (72px, r18), profile card with check icon, "Encrypted Terminal Access" footer.

---

### 2. POS Sales Terminal (`pos_screen.dart`)

**Purpose**: Main cashier workflow — browse/search products, build cart, proceed to payment.

**Layouts**:
- **Wide (≥800px)**: Product grid (flex: 5) + Cart sidebar (380px)
- **Narrow**: TabBar switching between Products and Receipt tabs

**Product Panel**:
- Search field with 300ms debounce, auto-clear button
- Horizontal category chips (All, Продукты, Напитки, Бакалея, Молочные, Прочее)
- Responsive product grid (2/3/4 columns by width)
- **NKT Fallback**: When barcode (8–14 digits) entered and not found locally → auto-searches National Catalog → shows results with "add to catalog" action

**Product Cards**: Rounded (20px), icon placeholder with NKT badge overlay, add-button in corner, product name, type label (Весовой/Штучный), heroized price (20px w800).

**Cart Panel**:
- Header: "Текущий чек" with item count badge
- Item list: name, unit price × qty, line total, +/− quantity stepper
- Quantity dialog with full NumPad for manual entry
- Footer: subtotal, discount, VAT 12%, total (30px w900 heroized)
- Gradient CTA: "ОПЛАТА" button → navigates to PaymentScreen
- Quick actions: "С собой" (takeaway), "Отмена" (void cart)

**Stitch Design**: v4_sales_terminal — product grid with image containers, cart with stepper controls, gradient payment CTA.

---

### 3. Payment (`payment_screen.dart`)

**Purpose**: Accept payment for cart total. Supports 4 methods.

**Methods**:
| Method | UI |
|--------|----|
| Наличные (Cash) | NumPad + quick amount buttons (500–20K ₸), auto-calculates change |
| Карта (Card) | "Приложите карту к терминалу" placeholder |
| Kaspi QR | QR code display placeholder |
| Смешанная (Mixed) | Three input fields (cash/card/QR), tap to switch active, running remaining counter |

**Flow**: Select method tab → enter amount(s) → "Оплатить" button (enabled when amount ≥ total) → returns `{method, cash, card, qr, change}` map → SalesBloc.CompleteSale → POST receipt to server → clear cart.

---

### 4. Shift / Cash Management (`shift_screen.dart`)

**Purpose**: Open/close shifts, view sales stats, reconcile cash.

**States**:
- **No shift**: Centered form with cashier name, cash-start input, "Открыть смену" button
- **Open shift (wide ≥800px)**: Split layout matching Stitch v4_cash_management
  - Left: denomination counting panel (20K, 10K, 5K, 2K, 1K, 500₸ bill cards with input fields), manual adjustment area, payment breakdown stats
  - Right: shift summary sidebar — opening float, cash sales, returns, expected in drawer (heroized 36px), counted total, variance, "Закрыть смену" gradient CTA
- **Open shift (narrow)** or **Closed shift**: Scrollable dashboard with gradient hero card (shift number + total sales + receipt count), 4 stat cards, cash info, close button

**Stitch Design**: v4_cash_management — denomination grid, shift summary sidebar, gradient close button with lock icon.

---

### 5. Products Catalog (`products_screen.dart`)

**Purpose**: Manage product catalog — view, add, delete, search.

**Layout**:
- Header with "Добавить товар" button
- Bento stat cards: total products, weighted, piece-count, avg price
- Search field + refresh + filter tabs (Все / Весовой / Штучный)
- Scrollable data table: icon, name + type, barcode, VAT %, price, delete button
- Empty state with "загрузите демо-данные" hint

**Add Product Dialog**:
- Barcode input with NKT lookup button (auto-populates name + NTIN)
- Name, price (₸), weighted toggle
- Creates product via API with temp ID

---

### 6. Cashiers / Personnel (`cashiers_screen.dart`)

**Purpose**: View and add cashiers.

**Layout**:
- Stat cards: total cashiers, owners, admins
- Table: gradient avatar (first letter), name, role badge (color-coded)
- Add dialog: name, PIN (4 digits), role dropdown (Кассир / Старший кассир / Администратор)

**Roles**: owner (created on first run), admin, senior_cashier, cashier.

---

### 7. Debts / Credit Sales (`debts_screen.dart`)

**Purpose**: Track customer debts for credit sales ("продажа в долг").

**Layout**:
- Tabs: Открытые (Open) / Все (All)
- Total debt banner (red gradient) showing count + total amount
- Debt rows: status icon, client name, note, remaining/paid amounts, progress bar, pay button
- Create debt dialog: client dropdown, amount, note
- Pay dialog: pre-filled with remaining amount

---

### 8. Settings (`settings_screen.dart`)

**Purpose**: System configuration and diagnostics.

**Sections**:
- **Действия**: Load demo data, NKT search dialog (GTIN/name search with result details)
- **Система**: About (v0.1.0), server URL, health check (live FutureBuilder)
- **Интеграции**: Language selector (Русский / қазақша planned), fiscalization status, NKT status check
- **Выход**: Logout button (red)

---

## State Reference (historical — pre-Riverpod names)

> Written when Auth/Sales state lived in flutter_bloc. The Phase 0b migration
> moved these to Riverpod `Notifier` controllers with **one method per former
> event**, keeping the sealed state classes and call-site behavior intact —
> so the event tables below still describe the controller API surface;
> mentally replace `AuthBloc` → `AuthController`, `SalesBloc` → `SalesController`.

### AuthBloc

| Event | Effect |
|-------|--------|
| `CheckFirstRun` | Checks if any cashiers exist → sets `isFirstRun` |
| `PinDigitPressed(digit)` | Appends digit; auto-triggers login on 4th. Blocked during lockout |
| `PinBackspacePressed` | Removes last digit. Blocked during lockout |
| `PinCleared` | Resets PIN input |
| `CreateFirstCashier(name, pin)` | Creates owner cashier + auto-login |
| `LogoutRequested` | Returns to PIN screen (preserves lockout state) |

**Security**: 5 consecutive wrong PINs → 30s lockout. Escalates: 10→2min, 15→5min, 20+→15min. Success resets all counters.

### SalesBloc

| Event | Effect |
|-------|--------|
| `AddToCart(CartItem)` | Adds item (increments qty if duplicate) |
| `RemoveFromCart(index)` | Removes item at index |
| `UpdateQuantity(index, qty)` | Sets quantity for item |
| `UpdateWeight(index, grams)` | Sets weight for weighted item |
| `ApplyDiscount(tiyin)` | Sets flat discount |
| `ClearCart` | Empties cart + discount |
| `SearchProduct(query)` | Searches locally; if barcode 8–14 digits + no local results → auto NKT |
| `ScanBarcode(barcode)` | Direct barcode lookup with NKT fallback |
| `CompleteSale(...)` | POSTs receipt to server, clears cart on success |
| `ClearNktResults` | Dismisses NKT result panel |

**Computed state**: `subtotal`, `total` (subtotal − discount), `vatAmount`, `itemCount`.

---

## Edge Cases & Error Handling

### Authentication
- **PIN brute force**: Escalating lockout (30s → 2m → 5m → 15m) after every 5 failures
- **Lockout persistence**: Survives logout — can't bypass by logging out and back in
- **Server down during login**: Shows "Нет связи с сервером", does NOT count toward lockout
- **First-run guard**: Requires PIN confirmation match before creating owner account

### Sales / Cart
- **Empty cart payment**: Pay button disabled when cart is empty
- **No shift open**: Payment blocked with warning "Сначала откройте смену"
- **Duplicate product**: AddToCart increments quantity if same productId already in cart
- **Weighted goods zero weight**: Weight defaults to 0g, total calculates as 0₸
- **Barcode partial entry**: Shows hint "Введено X из 8–14 цифр" instead of NKT search
- **NKT fallback**: Only triggers for full barcodes (8–14 digits) when local search returns empty
- **Search debounce**: 300ms delay prevents excessive API calls during typing
- **Network failure on sale**: Error shown via SnackBar, cart NOT cleared (user can retry)

### Payments
- **Insufficient amount**: Pay button disabled until entered amount ≥ total
- **Cash change**: Auto-calculated and displayed before confirming
- **Mixed payment**: Three fields (cash/card/QR), remaining amount shown dynamically
- **Overpayment on card/QR**: Not possible — limited to exact remaining amount

### Shifts
- **Double open**: Server rejects if shift already open for this cashier
- **Close confirmation**: Requires explicit dialog confirmation (Z-report is irreversible)
- **Denomination counting**: Visual reconciliation of expected vs counted cash

### Products
- **NKT product creation**: Creates with temp ID, auto-populates name/NTIN from national catalog
- **Delete confirmation**: Dialog required before removing product
- **Price in tiyin**: UI shows ₸, internally converts to tiyin on save

### General
- **Responsive breakpoints**: 800px for split layouts, 700px for sidebar vs bottom nav, 500px for stat card grid
- **API timeout**: 10 seconds — shows error on timeout, doesn't hang
- **Offline mode**: Implemented — drift is the source of truth; writes queue in `sync_outbox` and drain when a connection returns

---

## Dependencies (key ones — see `pubspec.yaml` for the full, commented list)

```yaml
flutter_riverpod: ^2.5.1  # State management (replaced flutter_bloc in Phase 0b)
provider: ^6.1.2          # Repository/service DI at widget-tree leaves
drift: (see pubspec)      # Local SQLite (WAL) — source of truth
dio: ^5.7.0               # REST client with interceptors (http kept for legacy ApiClient)
intl: ^0.20.2             # Pinned — keeps Russian plural rules stable
cupertino_icons: ^1.0.8   # iOS-style icons
```

Fonts are bundled (no runtime Google Fonts fetch — registers may be offline).

## Running

```bash
flutter pub get
make run                # flutter run (debug)
flutter run -d windows  # desktop
flutter build apk       # Android release
make test               # test suite
make analyze            # dart analyze
```

The register runs fully standalone on its local drift database. To exercise sync, run `pos-server` locally (see that repo's README) and point the register at it via the setup wizard.
