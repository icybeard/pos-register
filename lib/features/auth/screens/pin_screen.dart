import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/hifi.dart';
import '../controllers/auth_controller.dart';
import 'owner_login_screen.dart';

// Internal two-state UI flag. The user-facing segmented switcher is gone
// (everyone lands on the grid; legacy "Имя + PIN" / "Биометрия" tabs were
// removed). What remains is the grid → PIN keypad transition: tapping a
// cashier tile selects them, then "Далее → PIN" flips this flag to keypad.
enum _LoginFlavor { pin, grid }

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  // Default to the cashier grid — quickest path for the "switch cashier"
  // scenario (tap your tile, enter 4-digit PIN). Users who want the full
  // Имя + PIN form can tap that tab explicitly. Biometrics is tab 3 —
  // prompts Face ID / Touch ID on supported devices.
  _LoginFlavor _flavor = _LoginFlavor.grid;

  void selectFlavor(_LoginFlavor v) {
    if (!mounted) return;
    setState(() => _flavor = v);
  }

  @override
  void initState() {
    super.initState();
    // checkFirstRun must run after this frame so build() can render the
    // initial state first; doing it inline in initState would race the
    // Notifier's build() callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).checkFirstRun();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the state once — the chrome chip + body both depend on it.
    final state = ref.watch(authControllerProvider);
    final ws = ref.read(authControllerProvider.notifier).activeWorkstation;

    // ref.listen handles the AuthAuthenticated maybePop — same screen
    // pop behaviour as OwnerLoginScreen (this screen sits on the Navigator
    // stack above main.dart's root Consumer, which renders _MainShell as
    // home: but doesn't pop the pushed PinScreen on its own).
    ref.listen<AuthState>(authControllerProvider, (prev, curr) {
      if (curr is AuthAuthenticated) {
        Navigator.of(context).maybePop();
      }
    });

    return Scaffold(
      backgroundColor: Hifi.canvas,
      body: Column(children: [
        // Real store + terminal binding from the activation payload. The
        // controller keeps `_activeWorkstation` populated for the lifetime
        // of the process once activation/hydrate completes. We re-read on
        // each rebuild so post-mount hydration (which can complete after
        // the screen first paints) refreshes the chip.
        if (ws == null)
          const HifiChrome()
        else
          HifiChrome(
            shiftNumber: ws.storeName.isNotEmpty ? ws.storeName : null,
            // workstationId is a UUID v4; surface only the leading 8 chars
            // so operators can disambiguate registers in the same store
            // without displaying the full GUID.
            storeLabel: 'Терминал ${ws.workstationId.length >= 8 ? ws.workstationId.substring(0, 8) : ws.workstationId}',
          ),
        Expanded(
          child: Builder(builder: (context) {
            if (state is AuthInitial && state.isFirstRun) {
              return Center(child: _FirstRunSetup());
            }
            // Surface a `RegisterActivated.error` (e.g. listCashiers 401
            // because the device JWT is missing / expired). Without this
            // the grid renders empty and the operator has no clue why.
            final activatedError =
                state is RegisterActivated ? state.error : null;
            return Column(children: [
              if (activatedError != null) _ErrorBanner(message: activatedError),
              // No segmented switcher anymore. Grid is the only entry point;
              // "Далее → PIN" inside the grid flips the internal flag to
              // show the keypad. Biometric was a separate tab; it's now a
              // per-tile badge on the matching cashier (see _CashierGridTile).
              Expanded(child: _flavorBody()),
            ]);
          }),
        ),
      ]),
    );
  }

  Widget _flavorBody() {
    switch (_flavor) {
      case _LoginFlavor.pin:
        return Center(child: _PinEntry());
      case _LoginFlavor.grid:
        return _GridFlavor(onSwitchToPin: () => selectFlavor(_LoginFlavor.pin));
    }
  }
}

class _PinEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // sizeOf() subscribes only to the size aspect of MediaQueryData, not
    // every aspect (orientation, keyboard insets, font scale, ...). Far
    // fewer rebuilds when the keyboard appears/disappears.
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 800;

    if (isWide) {
      return _WidePinLayout();
    }
    return _NarrowPinLayout();
  }
}

// ─── Color-based avatar ─────────────────────────────────────

/// Generates a consistent gradient color pair from a name string.
List<Color> _avatarColors(String name) {
  const palettes = [
    [Color(0xFFBF5F30), Color(0xFFA44D24)], // blue
    [Color(0xFFA44D24), Color(0xFF843D1D)], // violet
    [Color(0xFFEC4899), Color(0xFFB8332E)], // pink
    [Color(0xFFB6781A), Color(0xFFB6781A)], // amber
    [Color(0xFF2C8A5A), Color(0xFF226E47)], // emerald
    [Color(0xFF1E7A93), Color(0xFF155F73)], // cyan
    [Color(0xFFB8332E), Color(0xFFB8332E)], // red
    [Color(0xFFBF5F30), Color(0xFFBF5F30)], // indigo
  ];
  final hash = name.codeUnits.fold<int>(0, (h, c) => h * 31 + c);
  return palettes[hash.abs() % palettes.length];
}

Widget _buildAvatar(String name, {double size = 44, double fontSize = 18}) {
  final colors = _avatarColors(name);
  final initials = name.trim().isEmpty
      ? '?'
      : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors),
      borderRadius: BorderRadius.circular(size * 0.27),
    ),
    child: Center(
      child: Text(
        initials,
        style: TextStyle(fontFamily: 'Inter', 
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

// ─── Live clock widget ───────────────────────────────────────
//
// This is the BIG clock that sits above the cashier grid on the login
// screen. NOT a duplicate of `HifiLiveClock` in `lib/core/widgets/
// live_clock.dart` — that one is the small chrome-corner clock with a
// different format (`dd.mm.yyyy HH:MM`, 30s tick) and styling. Keep
// both: the big display here needs 1s tick + the "D MMM YYYY" date
// format to match the Variant C login mock; HifiLiveClock's compact
// format would look wrong at 28pt.

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    final date = '${_now.day} ${months[_now.month - 1]} ${_now.year}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: const TextStyle(fontFamily: 'Inter', 
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: Color(0xFF837B6D),
            letterSpacing: 2,
          ),
        ),
        Text(
          date,
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF837B6D).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ─── Wide layout: profile selection left, keypad right ───────

class _WidePinLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960, maxHeight: 640),
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 12)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [
          // Left: profile selection
          SizedBox(
            width: 340,
            child: Container(
              color: const Color(0xFFFAF7F0),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branding
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.point_of_sale_rounded, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('POS SYSTEM',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -0.3)),
                      Text('KAZAKHSTAN',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF837B6D), letterSpacing: 2)),
                    ]),
                  ]),
                  const SizedBox(height: 8),
                  Text(l.pinTerminal,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF837B6D))),

                  const SizedBox(height: 32),
                  Text(l.pinSelectProfile,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF837B6D), letterSpacing: 1.5)),
                  const SizedBox(height: 12),

                  // Cashier profiles from server
                  Expanded(child: Consumer(
                    builder: (context, ref, _) {
                      final state = ref.watch(authControllerProvider);
                      final cashiers = state is AuthInitial ? state.cashiers : <Map<String, dynamic>>[];
                      final selected = state is AuthInitial ? state.selectedCashierName : null;
                      final openShifts = state is AuthInitial ? state.openShifts : <String, String>{};

                      if (cashiers.isEmpty) {
                        return _ProfileCard(
                          name: l.pinCashierLabel,
                          subtitle: l.pinEnterForLogin,
                          selected: true,
                        );
                      }

                      return ListView.separated(
                        itemCount: cashiers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = cashiers[i];
                          final name = c['Name'] as String? ?? '';
                          final role = c['Role'] as String? ?? 'cashier';
                          final cashierId = c['ID'] as String? ?? '';
                          final isSelected = selected == name || (selected == null && i == 0);
                          final shiftOpenedAt = openShifts[cashierId];
                          return GestureDetector(
                            onTap: () => ref.read(authControllerProvider.notifier).selectCashierProfile(name),
                            child: _ProfileCard(
                              name: name,
                              subtitle: _roleLabel(l, role),
                              selected: isSelected,
                              shiftOpenedAt: shiftOpenedAt,
                            ),
                          );
                        },
                      );
                    },
                  )),

                  const SizedBox(height: 12),
                  // Clock at bottom of profile panel
                  const Center(child: _LiveClock()),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Right: keypad
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.pinWelcome,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    const SizedBox(height: 6),
                    Text(l.pinEnterCode,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF837B6D))),
                    const SizedBox(height: 28),
                    _PinDotsAndError(),
                    const SizedBox(height: 28),
                    _PinKeypad(),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFFC8BFAC)),
                      const SizedBox(width: 6),
                      Text(l.pinEncryptedAccess,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFC8BFAC), letterSpacing: 1.5)),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Narrow layout: vertical keypad (for mobile)
class _NarrowPinLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.point_of_sale_rounded, size: 34, color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Clock on mobile
            const _LiveClock(),
            const SizedBox(height: 16),
            const Text('POS System',
              style: TextStyle(fontFamily: 'Inter', fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text('KAZAKHSTAN',
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF837B6D), letterSpacing: 3)),
            const SizedBox(height: 32),
            Text(l.pinEnterCode,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF837B6D))),
            const SizedBox(height: 24),
            _PinDotsAndError(),
            _PinLoadingIndicator(),
            const SizedBox(height: 36),
            _PinKeypad(),
          ],
        ),
      ),
    );
  }
}

/// Localized role label. Mirrors `_MainShellState._roleLabel` in
/// `main.dart`. Takes `AppLocalizations` rather than a BuildContext so
/// callers in narrow widget builders can pass the already-resolved
/// instance and we don't repeat `AppLocalizations.of(context)!` per tile.
String _roleLabel(AppLocalizations l, String role) => switch (role) {
  'owner' => l.roleOwner,
  'admin' => l.roleAdmin,
  'senior_cashier' => l.roleSeniorCashier,
  _ => l.roleCashier,
};

class _ProfileCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool selected;
  final String? shiftOpenedAt;

  const _ProfileCard({
    required this.name,
    required this.subtitle,
    this.selected = false,
    this.shiftOpenedAt,
  });

  String? _formatShiftTime() {
    if (shiftOpenedAt == null) return null;
    try {
      final dt = DateTime.parse(shiftOpenedAt!);
      final local = dt.toLocal();
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftTime = _formatShiftTime();
    final hasShift = shiftTime != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFC8BFAC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        _buildAvatar(name),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.primary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF837B6D))),
          if (hasShift) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF226E47)),
                ),
                const SizedBox(width: 4),
                Text(
                  'Смена с $shiftTime',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF226E47)),
                ),
              ]),
            ),
          ],
        ])),
        if (selected)
          const Icon(Icons.check_circle, size: 22, color: AppTheme.primary),
      ]),
    );
  }
}

class _PinDotsAndError extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final pinLength = state is AuthInitial ? state.pin.length : 0;
    final error = state is AuthInitial ? state.error : null;
    final isLocked = state is AuthInitial && state.isLockedOut;
    return Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < pinLength;
              final hasError = error != null;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: filled ? 18 : 14,
                height: filled ? 18 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasError || isLocked
                      ? AppTheme.error
                      : filled
                          ? AppTheme.primary
                          : Colors.transparent,
                  border: Border.all(
                    color: hasError || isLocked
                        ? AppTheme.error
                        : filled
                            ? AppTheme.primary
                            : const Color(0xFFC8BFAC),
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          // Fixed-height error/lockout area so keypad doesn't shift
          SizedBox(
            height: 48,
            child: isLocked
                ? _LockoutCountdown(lockedUntil: state.lockedUntil!)
                : error != null
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBE9E7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            error,
                            style: const TextStyle(fontFamily: 'Inter', color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ]);
  }
}

/// Countdown timer shown during lockout period.
class _LockoutCountdown extends StatefulWidget {
  final DateTime lockedUntil;
  const _LockoutCountdown({required this.lockedUntil});

  @override
  State<_LockoutCountdown> createState() => _LockoutCountdownState();
}

class _LockoutCountdownState extends State<_LockoutCountdown> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.lockedUntil.difference(DateTime.now());
    if (remaining.isNegative) return const SizedBox.shrink();

    final seconds = remaining.inSeconds;
    final display = seconds >= 60
        ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
        : '$seconds ${AppLocalizations.of(context)!.pinSec}';

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE9E7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_clock_rounded, size: 16, color: AppTheme.error),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.pinLockedMessage(display),
            style: const TextStyle(fontFamily: 'Inter', color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

class _PinLoadingIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    if (state is AuthLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: SizedBox(width: 24, height: 24,
          child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5)),
      );
    }
    return const SizedBox.shrink();
  }
}

class _PinKeypad extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider.notifier);
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['<', '0', 'OK'],
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((label) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _buildKey(controller, label),
              ),
            )).toList(),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildKey(AuthController controller, String label) {
    final isBackspace = label == '<';
    final isConfirm = label == 'OK';

    return SizedBox(
      height: 72,
      child: Material(
        color: isConfirm
            ? AppTheme.primary
            : const Color(0xFFFAF7F0),
        borderRadius: BorderRadius.circular(18),
        elevation: isConfirm ? 4 : 0,
        shadowColor: isConfirm ? AppTheme.primary.withValues(alpha: 0.3) : Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (label == '<') {
              controller.pinBackspace();
            } else if (label == 'OK') {
              // PinSubmitPressed: no-op if pin.length < 4 (controller guards).
              // Login is also auto-triggered on the 4th digit press; this
              // path covers the "backspace then re-type" case where the OK
              // key is the only remaining way to re-submit.
              controller.pinSubmit();
            } else {
              controller.pinDigit(label);
            }
          },
          child: Center(
            child: isBackspace
                ? const Icon(Icons.backspace_outlined, size: 20, color: Color(0xFF4A453C))
                : isConfirm
                    ? const Icon(Icons.login_rounded, size: 22, color: Colors.white)
                    : Text(
                        label,
                        style: const TextStyle(fontFamily: 'Inter', 
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Flavor 2 — Сетка кассиров (grid)
// ════════════════════════════════════════════════════════════════════════════

class _GridFlavor extends ConsumerWidget {
  // Parent-supplied callback to flip the segmented toggle to PIN entry.
  // Replaces the previous `findAncestorStateOfType<_PinScreenState>()` walk —
  // grid tile children stay decoupled from _PinScreenState's private API.
  final VoidCallback onSwitchToPin;
  const _GridFlavor({required this.onSwitchToPin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(authControllerProvider);
    final cashiers = state is AuthInitial ? state.cashiers : const <Map<String, dynamic>>[];
    final selected = state is AuthInitial ? state.selectedCashierName : null;
    return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(l.pinSelectCashier, style: Hifi.ui(size: 22, weight: FontWeight.w700, color: Hifi.chrome)),
              const SizedBox(width: 10),
              Text(
                l.pinCashierCountLabel(cashiers.length),
                style: Hifi.mono(size: 12, color: const Color(0xFF837B6D)),
              ),
            ]),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Hifi.border),
                ),
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  // +2: cashier tiles, then admin tile, then "+ Новый кассир".
                  // Admin tile is part of the grid (per the "everyone in
                  // grid form" decision) so admins land on the same screen
                  // as cashiers and pick their entry path visually.
                  itemCount: cashiers.length + 2,
                  itemBuilder: (context, i) {
                    if (i == cashiers.length) {
                      return _AdminLoginTile(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OwnerLoginScreen(),
                          ),
                        ),
                      );
                    }
                    if (i == cashiers.length + 1) return const _AddCashierTile();
                    final c = cashiers[i];
                    final name = c['Name'] as String? ?? '';
                    final role = c['Role'] as String? ?? 'cashier';
                    final id = c['ID'] as String? ?? '';
                    final isSelected = selected == name;
                    // "ПОСЛЕДНИЙ" badge marks the most-recently-active cashier.
                    // Server contract: GET /api/cashiers returns the list sorted
                    // by last_active_at DESC, so index 0 is "the cashier whose
                    // shift just closed or whose session is current". If the
                    // backend ever changes that ordering, the badge migrates to
                    // a random tile — when touching the cashiers endpoint,
                    // re-verify this invariant or move the marker server-side
                    // (e.g. an explicit `is_last_active` flag on the row).
                    final isLast = i == 0;
                    // Face ID badge only on the cashier whose session is
                    // currently saved AND only if the device has biometrics.
                    // BiometricLoginRequested unlocks "the saved session" —
                    // it can't pick a different cashier — so showing the
                    // badge on every tile would mislead the operator.
                    final controller = ref.read(authControllerProvider.notifier);
                    final showBio = controller.isBiometricAvailable
                        && id.isNotEmpty
                        && controller.savedCashierUserId == id;
                    return _CashierGridTile(
                      name: name,
                      role: _roleLabel(l, role),
                      last: isLast,
                      selected: isSelected,
                      onTap: () => controller.selectCashierProfile(name),
                      showFaceIdBadge: showBio,
                      onFaceIdTap: showBio
                          ? controller.biometricLogin
                          : null,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              if (selected != null)
                Text.rich(
                  TextSpan(style: Hifi.ui(size: 12, color: const Color(0xFF837B6D)), children: [
                    TextSpan(text: l.pinSelectedPrefix),
                    TextSpan(text: selected, style: Hifi.ui(size: 12, weight: FontWeight.w700, color: Hifi.chrome)),
                  ]),
                ),
              const Spacer(),
              FilledButton(
                onPressed: selected == null ? null : onSwitchToPin,
                style: FilledButton.styleFrom(
                  backgroundColor: Hifi.chrome,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(l.pinProceedToPin),
                ),
              ),
            ]),
          ]),
        );
  }
}

class _CashierGridTile extends StatelessWidget {
  final String name;
  final String role;
  final bool last;
  final bool selected;
  final VoidCallback onTap;
  /// Render a small Face ID button in the bottom-right corner. Set when this
  /// tile's cashier matches the saved session AND the device has biometrics
  /// enrolled — then tapping the button unlocks without typing the PIN.
  /// Cashiers who never logged in via PIN on this device don't get a badge,
  /// because [BiometricLoginRequested] only restores the most-recent saved
  /// session — it can't pick a different cashier on demand.
  final bool showFaceIdBadge;
  final VoidCallback? onFaceIdTap;
  const _CashierGridTile({
    required this.name,
    required this.role,
    required this.last,
    required this.selected,
    required this.onTap,
    this.showFaceIdBadge = false,
    this.onFaceIdTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFAE0C9) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? Hifi.chrome : Hifi.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              _buildAvatar(name, size: 44),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: Hifi.ui(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(role, style: Hifi.ui(size: 11, color: const Color(0xFF837B6D))),
                ],
              )),
            ]),
          ),
          if (last)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Hifi.chrome, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  AppLocalizations.of(context)!.pinLastBadge,
                  style: Hifi.ui(size: 9, weight: FontWeight.w700, color: Colors.white).copyWith(letterSpacing: 0.3),
                ),
              ),
            ),
          if (showFaceIdBadge)
            // Bottom-right Face ID shortcut. Distinct InkWell so its tap
            // doesn't bubble to the tile's onTap (which would just select
            // the tile, defeating the point of a one-tap unlock).
            Positioned(
              bottom: 6,
              right: 6,
              child: Material(
                color: Hifi.chrome,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onFaceIdTap,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.face_retouching_natural,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Admin / owner entry point in the cashier grid. Visually distinct
/// (navy fill + white text) so it doesn't blend with cashier tiles —
/// admins are on a different login path (email + password) and need
/// to recognize their tile at a glance. Tap pushes [OwnerLoginScreen].
class _AdminLoginTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AdminLoginTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Hifi.chrome,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Hifi.chrome, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.pinAdminTile,
                  style: Hifi.ui(size: 14, weight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.pinAdminTileSubtitle,
                  style: Hifi.ui(size: 11, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            )),
          ]),
        ),
      ),
    );
  }
}

class _AddCashierTile extends StatelessWidget {
  const _AddCashierTile();
  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Intentionally disabled until the admin "add cashier" flow lands —
      // tapping was a no-op which confused cashiers. The dotted-border tile
      // still hints at the upcoming feature without claiming to be live.
      // TODO(add-cashier): route to admin cashier-create screen + role-gate
      // so only manager+ can open it.
      onTap: null,
      child: DottedBorderBox(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('＋', style: Hifi.ui(size: 26, color: const Color(0xFF837B6D))),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.pinNewCashier,
            style: Hifi.ui(size: 12, color: const Color(0xFF837B6D)),
          ),
        ]),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(),
      child: Center(child: child),
    );
  }
}

/// Inline error strip rendered above the cashier grid when the bloc reports
/// a non-fatal failure (e.g. listCashiers 401 because the device JWT is
/// missing / expired). Visual: red-tinted full-width banner with an icon and
/// the bloc-supplied message — no dismiss action, since the underlying
/// problem (re-activate, fix network, etc.) requires explicit operator
/// intervention.
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFBE9E7),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 18, color: Color(0xFF721B18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: Hifi.ui(size: 13, color: const Color(0xFF721B18)),
          ),
        ),
      ]),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Hifi.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    const dash = 4.0;
    const gap = 4.0;
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double d = 0;
      while (d < m.length) {
        final end = (d + dash).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}


class _FirstRunSetup extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FirstRunSetup> createState() => _FirstRunSetupState();
}

class _FirstRunSetupState extends ConsumerState<_FirstRunSetup> {
  final _nameController = TextEditingController(text: 'Владелец');
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 12)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.store_rounded, size: 34, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(l.pinFirstRunTitle,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(l.pinFirstRunSubtitle,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF837B6D))),
              const SizedBox(height: 32),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l.pinFieldName, prefixIcon: const Icon(Icons.person_outline)),
                style: const TextStyle(fontFamily: 'Inter', ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pinController,
                decoration: InputDecoration(labelText: l.pinFieldPin, prefixIcon: const Icon(Icons.lock_outline)),
                style: const TextStyle(fontFamily: 'Inter', ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                decoration: InputDecoration(labelText: l.pinFieldConfirm, prefixIcon: const Icon(Icons.lock_outline)),
                style: const TextStyle(fontFamily: 'Inter', ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),

              Consumer(builder: (context, ref, _) {
                final state = ref.watch(authControllerProvider);
                final error = state is AuthInitial ? state.error : null;
                return Column(children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE9E7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(error, style: const TextStyle(fontFamily: 'Inter', color: AppTheme.error, fontSize: 13)),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state is AuthLoading
                          ? null
                          : () {
                              final pin = _pinController.text;
                              if (pin.length != 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l.pinErrorLength)),
                                );
                                return;
                              }
                              if (pin != _confirmController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l.pinErrorMismatch)),
                                );
                                return;
                              }
                              ref.read(authControllerProvider.notifier).createFirstCashier(_nameController.text, pin);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: state is AuthLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(l.pinCreateAndLogin, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
