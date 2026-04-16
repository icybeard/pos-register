import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';

class CashiersScreen extends StatefulWidget {
  final ApiClient api;
  const CashiersScreen({super.key, required this.api});

  @override
  State<CashiersScreen> createState() => _CashiersScreenState();
}

class _CashiersScreenState extends State<CashiersScreen> {
  List<Map<String, dynamic>> _cashiers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await widget.api.listCashiers();
      setState(() {
        _cashiers = (resp['cashiers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _loading = false;
      });
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: ${e is ApiException ? "Сервер недоступен" : "Нет связи"}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final owners = _cashiers.where((c) => c['Role'] == 'owner').length;
    final admins = _cashiers.where((c) => c['Role'] == 'admin' || c['Role'] == 'senior_cashier').length;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.cashiersTitle, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(l.cashiersCountLabel(_cashiers.length),
                              style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant)),
                        ]),
                      ),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.person_add_outlined, size: 20),
                          label: Text(l.add, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                  ),
                ),

                // Stat chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(children: [
                      _StatChip(label: l.cashiersStatTotal, value: '${_cashiers.length}', color: pos.accentFg),
                      const SizedBox(width: 10),
                      _StatChip(label: l.cashiersStatOwners, value: '$owners', color: pos.warningFg),
                      const SizedBox(width: 10),
                      _StatChip(label: l.cashiersStatManagers, value: '$admins', color: pos.successFg),
                    ]),
                  ),
                ),

                // Table header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 52),
                        Expanded(flex: 3, child: Text(l.cashiersColName, style: _headerStyle(cs))),
                        Expanded(flex: 2, child: Text(l.cashiersColRole, style: _headerStyle(cs))),
                        const SizedBox(width: 48),
                      ]),
                    ),
                  ),
                ),

                // Cashier rows
                _cashiers.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmpty(context))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _CashierRow(
                              cashier: _cashiers[i],
                              index: i,
                              isLast: i == _cashiers.length - 1,
                              api: widget.api,
                              onRefresh: _load,
                            ),
                            childCount: _cashiers.length,
                          ),
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  TextStyle _headerStyle(ColorScheme cs) => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w700, color: cs.outline, letterSpacing: 0.8,
      );

  Widget _buildEmpty(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.people_outline, size: 32, color: cs.outline),
          ),
          const SizedBox(height: 16),
          Text(l.cashiersEmpty, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final nameC = TextEditingController();
    final pinC = TextEditingController();
    final confirmPinC = TextEditingController();
    String role = 'cashier';
    bool submitting = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.cashiersNew, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, decoration: InputDecoration(labelText: l.cashiersFieldName)),
            const SizedBox(height: 14),
            TextField(
              controller: pinC,
              decoration: InputDecoration(labelText: l.cashiersFieldPin),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmPinC,
              decoration: InputDecoration(labelText: l.cashiersPinConfirm),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: InputDecoration(labelText: l.cashiersFieldRole),
              items: [
                DropdownMenuItem(value: 'cashier', child: _RoleItem(l.roleCashier, l.cashiersRoleCashierDesc)),
                DropdownMenuItem(value: 'senior_cashier', child: _RoleItem(l.roleSeniorCashier, l.cashiersRoleSeniorDesc)),
                DropdownMenuItem(value: 'admin', child: _RoleItem(l.roleAdmin, l.cashiersRoleAdminDesc)),
              ],
              onChanged: (v) => setDialogState(() => role = v!),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final name = nameC.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.cashiersEnterName)));
                        return;
                      }
                      if (pinC.text.length != 4) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pinErrorLength)));
                        return;
                      }
                      if (pinC.text != confirmPinC.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pinErrorMismatch)));
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        await widget.api.createCashier(name: name, pin: pinC.text, role: role);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) await _load();
                      } on Exception catch (e) {
                        if (ctx.mounted) setDialogState(() => submitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.create),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(width: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _CashierRow extends StatelessWidget {
  final Map<String, dynamic> cashier;
  final int index;
  final bool isLast;
  final ApiClient api;
  final VoidCallback onRefresh;

  const _CashierRow({
    required this.cashier,
    required this.index,
    required this.isLast,
    required this.api,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final role = cashier['Role'] as String? ?? 'cashier';
    final name = cashier['Name'] as String? ?? '';
    final isOwner = role == 'owner';

    Color avatarColor;
    if (isOwner) {
      avatarColor = pos.warningFg;
    } else if (role == 'admin') {
      avatarColor = pos.accentFg;
    } else if (role == 'senior_cashier') {
      avatarColor = pos.successFg;
    } else {
      avatarColor = cs.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: index.isEven ? cs.surfaceContainerLowest : cs.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(20)) : null,
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [avatarColor, avatarColor.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Name
        Expanded(
          flex: 3,
          child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
        ),

        // Role badge
        Expanded(
          flex: 2,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isOwner ? pos.warningBg : cs.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (isOwner) ...[
                  Icon(Icons.star_rounded, size: 13, color: pos.warningFg),
                  const SizedBox(width: 4),
                ],
                Text(
                  _roleLabel(role, l),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOwner ? pos.warningFg : cs.onSurfaceVariant,
                  ),
                ),
              ]),
            ),
          ]),
        ),

        // Actions menu
        SizedBox(
          width: 48,
          child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
            onSelected: (action) {
              switch (action) {
                case 'edit': _showEditCashierDialog(context);
                case 'reset_pin': _showResetPinDialog(context);
                case 'deactivate': _showDeactivateDialog(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(l.cashiersEdit),
                ]),
              ),
              PopupMenuItem(
                value: 'reset_pin',
                child: Row(children: [
                  const Icon(Icons.lock_reset, size: 18),
                  const SizedBox(width: 8),
                  Text(l.cashiersResetPin),
                ]),
              ),
              PopupMenuItem(
                value: 'deactivate',
                child: Row(children: [
                  Icon(Icons.person_off_outlined, size: 18, color: pos.errorFg),
                  const SizedBox(width: 8),
                  Text(l.cashiersDeactivate, style: TextStyle(color: pos.errorFg)),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _showResetPinDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pinC = TextEditingController();
    final confirmC = TextEditingController();
    final cashierId = cashier['ID'] as String? ?? '';
    bool submitting = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.cashiersResetPin, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              cashier['Name'] as String? ?? '',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinC,
              decoration: InputDecoration(labelText: l.cashiersNewPin),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmC,
              decoration: InputDecoration(labelText: l.pinFieldConfirm),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (pinC.text.length != 4) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pinErrorLength)));
                        return;
                      }
                      if (pinC.text != confirmC.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pinErrorMismatch)));
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        await api.resetCashierPin(cashierId, pinC.text);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l.cashiersResetPinSuccess),
                              backgroundColor: const Color(0xFF059669),
                            ),
                          );
                        }
                        onRefresh();
                      } on Exception catch (e) {
                        if (ctx.mounted) setDialogState(() => submitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCashierDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cashierId = cashier['ID'] as String? ?? '';
    final nameC = TextEditingController(text: cashier['Name'] as String? ?? '');
    String role = cashier['Role'] as String? ?? 'cashier';
    bool submitting = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.cashiersEdit, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, decoration: InputDecoration(labelText: l.cashiersFieldName)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: InputDecoration(labelText: l.cashiersFieldRole),
              items: [
                DropdownMenuItem(value: 'cashier', child: Text(l.roleCashier)),
                DropdownMenuItem(value: 'senior_cashier', child: Text(l.roleSeniorCashier)),
                DropdownMenuItem(value: 'admin', child: Text(l.roleAdmin)),
              ],
              onChanged: (v) => setDialogState(() => role = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (nameC.text.trim().isEmpty) return;
                      setDialogState(() => submitting = true);
                      try {
                        await api.updateCashier(cashierId, name: nameC.text.trim(), role: role);
                        if (ctx.mounted) Navigator.pop(ctx);
                        onRefresh();
                      } on Exception catch (e) {
                        if (ctx.mounted) setDialogState(() => submitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pos = PosColors.of(context);
    final cashierId = cashier['ID'] as String? ?? '';
    final name = cashier['Name'] as String? ?? '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cashiersDeactivateConfirm, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: pos.errorBg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: pos.errorFg),
              const SizedBox(width: 8),
              Expanded(child: Text(l.cashiersDeactivateHint, style: GoogleFonts.inter(fontSize: 13, color: pos.errorFg))),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () async {
              try {
                await api.deactivateCashier(cashierId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l.cashiersDeactivated),
                    backgroundColor: const Color(0xFF059669),
                  ));
                }
                onRefresh();
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: Text(l.cashiersDeactivate),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role, AppLocalizations l) => switch (role) {
        'owner' => l.roleOwner,
        'admin' => l.roleAdmin,
        'senior_cashier' => l.roleSeniorCashierShort,
        _ => l.roleCashier,
      };
}

class _RoleItem extends StatelessWidget {
  final String title;
  final String description;
  const _RoleItem(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        Text(description, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF74777D))),
      ],
    );
  }
}
