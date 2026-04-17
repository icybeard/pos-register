import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(CheckFirstRun());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FF),
      body: SafeArea(
        child: Stack(children: [
          // Decorative blur blobs (Stitch V4 aesthetic)
          Positioned(
            top: -80, right: -40,
            child: Container(
              width: 360, height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryContainer.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -40,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryContainer.withValues(alpha: 0.07),
              ),
            ),
          ),
          Center(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthInitial && state.isFirstRun) {
                  return _FirstRunSetup();
                }
                return _PinEntry();
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _PinEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
    [Color(0xFF3B82F6), Color(0xFF2563EB)], // blue
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // violet
    [Color(0xFFEC4899), Color(0xFFDB2777)], // pink
    [Color(0xFFF59E0B), Color(0xFFD97706)], // amber
    [Color(0xFF10B981), Color(0xFF059669)], // emerald
    [Color(0xFF06B6D4), Color(0xFF0891B2)], // cyan
    [Color(0xFFEF4444), Color(0xFFDC2626)], // red
    [Color(0xFF6366F1), Color(0xFF4F46E5)], // indigo
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
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

// ─── Live clock widget ───────────────────────────────────────

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
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: const Color(0xFF74777D),
            letterSpacing: 2,
          ),
        ),
        Text(
          date,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF74777D).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ─── Wide layout: profile selection left, keypad right ───────

class _WidePinLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFFE6EEFF),
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
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('POS SYSTEM',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -0.3)),
                      Text('KAZAKHSTAN',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF74777D), letterSpacing: 2)),
                    ]),
                  ]),
                  const SizedBox(height: 8),
                  Text(l.pinTerminal,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF74777D))),

                  const SizedBox(height: 32),
                  Text(l.pinSelectProfile,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF74777D), letterSpacing: 1.5)),
                  const SizedBox(height: 12),

                  // Cashier profiles from server
                  Expanded(child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
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
                            onTap: () => context.read<AuthBloc>().add(SelectCashierProfile(name)),
                            child: _ProfileCard(
                              name: name,
                              subtitle: _roleLabel(role),
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
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    const SizedBox(height: 6),
                    Text(l.pinEnterCode,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF74777D))),
                    const SizedBox(height: 28),
                    _PinDotsAndError(),
                    const SizedBox(height: 28),
                    _PinKeypad(),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFFC4C6CD)),
                      const SizedBox(width: 6),
                      Text(l.pinEncryptedAccess,
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFFC4C6CD), letterSpacing: 1.5)),
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
            Text('POS System',
              style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('KAZAKHSTAN',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF74777D), letterSpacing: 3)),
            const SizedBox(height: 32),
            Text(l.pinEnterCode,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF74777D))),
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

String _roleLabel(String role) => switch (role) {
  'owner' => 'Владелец',
  'admin' => 'Администратор',
  'senior_cashier' => 'Ст. кассир',
  _ => 'Кассир',
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
        color: selected ? const Color(0xFFD5E3FD) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        _buildAvatar(name),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.primary)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF74777D))),
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
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF059669)),
                ),
                const SizedBox(width: 4),
                Text(
                  'Смена с $shiftTime',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF059669)),
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

class _PinDotsAndError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
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
                            : const Color(0xFFC4C6CD),
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
                            color: const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            error,
                            style: GoogleFonts.inter(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ]);
      },
    );
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
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_clock_rounded, size: 16, color: AppTheme.error),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.pinLockedMessage(display),
            style: GoogleFonts.inter(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

class _PinLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5)),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _PinKeypad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AuthBloc>();
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
                child: _buildKey(bloc, label),
              ),
            )).toList(),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildKey(AuthBloc bloc, String label) {
    final isBackspace = label == '<';
    final isConfirm = label == 'OK';

    return SizedBox(
      height: 72,
      child: Material(
        color: isConfirm
            ? AppTheme.primary
            : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(18),
        elevation: isConfirm ? 4 : 0,
        shadowColor: isConfirm ? AppTheme.primary.withValues(alpha: 0.3) : Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (label == '<') {
              bloc.add(PinBackspacePressed());
            } else if (label == 'OK') {
              // Auto-login fires on the 4th digit; OK here is the explicit
              // fallback for the "user backspaced and re-typed" case and the
              // general expectation that a labelled key does something. The
              // handler is a no-op unless pin.length == 4, so a tap with 0-3
              // digits still does nothing (plan P0-1 acceptance).
              bloc.add(PinSubmitPressed());
            } else {
              bloc.add(PinDigitPressed(label));
            }
          },
          child: Center(
            child: isBackspace
                ? const Icon(Icons.backspace_outlined, size: 20, color: Color(0xFF43474C))
                : isConfirm
                    ? const Icon(Icons.login_rounded, size: 22, color: Colors.white)
                    : Text(
                        label,
                        style: GoogleFonts.inter(
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

class _FirstRunSetup extends StatefulWidget {
  @override
  State<_FirstRunSetup> createState() => _FirstRunSetupState();
}

class _FirstRunSetupState extends State<_FirstRunSetup> {
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
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(l.pinFirstRunSubtitle,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF74777D))),
              const SizedBox(height: 32),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l.pinFieldName, prefixIcon: const Icon(Icons.person_outline)),
                style: GoogleFonts.inter(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pinController,
                decoration: InputDecoration(labelText: l.pinFieldPin, prefixIcon: const Icon(Icons.lock_outline)),
                style: GoogleFonts.inter(),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                decoration: InputDecoration(labelText: l.pinFieldConfirm, prefixIcon: const Icon(Icons.lock_outline)),
                style: GoogleFonts.inter(),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),

              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final error = state is AuthInitial ? state.error : null;
                  return Column(children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(error, style: GoogleFonts.inter(color: AppTheme.error, fontSize: 13)),
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
                                context.read<AuthBloc>().add(CreateFirstCashier(_nameController.text, pin));
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: state is AuthLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text(l.pinCreateAndLogin, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
