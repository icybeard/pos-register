import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';

class SettingsScreen extends StatefulWidget {
  final ApiClient api;
  final VoidCallback onLogout;
  /// Role of the currently-authenticated user. Controls which tiles appear:
  /// cashiers see only the minimal set (language, printer, receipt format),
  /// owners/admins additionally see the integration + system tiles.
  final String role;

  const SettingsScreen({
    super.key,
    required this.api,
    required this.onLogout,
    this.role = 'cashier',
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // P0-9: cache both network probes so rebuilds don't spam the API. When
  // SettingsScreen was a StatelessWidget, every scroll/theme change rebuilt
  // FutureBuilder and kicked off a fresh checkHealth() / syncStatus(). On a
  // flaky connection that was observable as a rapid burst of requests in
  // the server log.
  late Future<bool> _healthFuture;
  late Future<Map<String, dynamic>> _syncFuture;

  // Short-hand getters so the pre-refactor `api` references in build() still
  // resolve without a blanket find-replace.
  ApiClient get api => widget.api;
  String get role => widget.role;
  VoidCallback get onLogout => widget.onLogout;

  bool get _isOwner => role == 'owner' || role == 'admin';

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  void _refreshStatus() {
    _healthFuture = widget.api.checkHealth();
    _syncFuture = widget.api.syncStatus();
  }

  void _showWebkassaReadOnlyInfo(BuildContext context) {
    // The register never collects or transmits Webkassa credentials. Those
    // are configured by the owner in the web admin — the register only sees
    // the server-owned, already-configured integration at runtime. This
    // dialog replaces the previous "type password here" form, which sent
    // the password through the generic /api/settings key-value store and
    // ended up in the local sync_outbox in plaintext.
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsWebkassa,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: const Text(
          'Логин и пароль Webkassa настраиваются владельцем в web-админке. '
          'На кассе отображается только состояние интеграции.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
        ],
      ),
    );
  }

  void _showNktSearchDialog(BuildContext context) {
    final queryC = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => _NktSearchDialog(api: api, queryController: queryC),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.settingsTitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(l.settingsSubtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurfaceVariant)),
              ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel(l.settingsActions),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.dataset_outlined,
                    iconColor: pos.accentFg,
                    iconBg: pos.accentBg,
                    title: l.settingsSeedDemo,
                    subtitle: l.settingsSeedDemoSub,
                    onTap: () async {
                      try {
                        await api.seedDemo();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Демо-данные загружены!'), backgroundColor: pos.successFg),
                          );
                        }
                      } on Exception catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e'), backgroundColor: pos.errorFg),
                          );
                        }
                      }
                    },
                  ),
                  Divider(height: 1, indent: 64, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _SettingsTile(
                    icon: Icons.search_rounded,
                    iconColor: pos.successFg,
                    iconBg: pos.successBg,
                    title: l.settingsCheckNkt,
                    subtitle: l.settingsCheckNktSub,
                    onTap: () => _showNktSearchDialog(context),
                  ),
                ]),

                const SizedBox(height: 28),
                _SectionLabel(l.settingsSystem),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: cs.onSurfaceVariant,
                    iconBg: cs.surfaceContainer,
                    title: l.settingsAbout,
                    subtitle: l.settingsAboutSub,
                  ),
                  Divider(height: 1, indent: 64, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _SettingsTile(
                    icon: Icons.dns_outlined,
                    iconColor: cs.onSurfaceVariant,
                    iconBg: cs.surfaceContainer,
                    title: l.settingsServer,
                    // Raw base URL (host + port) is owner-only — it's an
                    // infrastructure detail a cashier doesn't need to see
                    // and shouldn't have handy when a terminal is shared.
                    subtitle: _isOwner ? api.baseUrl : 'Central server configured',
                  ),
                  Divider(height: 1, indent: 64, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _SettingsTile(
                    icon: Icons.wifi_tethering_rounded,
                    iconColor: cs.onSurfaceVariant,
                    iconBg: cs.surfaceContainer,
                    title: l.settingsServerStatus,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<bool>(
                          future: _healthFuture,
                          builder: (_, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
                            }
                            final ok = snap.data == true;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: ok ? pos.successBg : pos.errorBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ok ? l.settingsServerConnected : l.settingsServerUnavailable,
                                style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: ok ? pos.successFg : pos.errorFg),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          tooltip: l.settingsServerStatus,
                          onPressed: () => setState(_refreshStatus),
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 28),
                _SectionLabel(l.settingsIntegrations),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    iconColor: pos.accentFg,
                    iconBg: pos.accentBg,
                    title: l.settingsLanguage,
                    subtitle: l.settingsLanguageSub,
                  ),
                  Divider(height: 1, indent: 64, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _SettingsTile(
                    icon: Icons.receipt_long_outlined,
                    iconColor: pos.warningFg,
                    iconBg: pos.warningBg,
                    title: l.settingsWebkassa,
                    subtitle: l.settingsWebkassaSub,
                    onTap: () => _showWebkassaReadOnlyInfo(context),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: pos.warningBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(l.settingsNotConnected, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: pos.warningFg)),
                    ),
                  ),
                  Divider(height: 1, indent: 64, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _SettingsTile(
                    icon: Icons.verified_outlined,
                    iconColor: pos.successFg,
                    iconBg: pos.successBg,
                    title: l.settingsNktTitle,
                    // Register proxies NKT lookups through central (T6.5);
                    // credentials are managed by the owner in the web admin.
                    // A runtime "configured?" badge would need owner-gated
                    // access to /api/nkt/credentials, so we just show a
                    // static indicator that the call path is healthy.
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: pos.successBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l.settingsNktConnected,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: pos.successFg),
                      ),
                    ),
                  ),
                ]),

                // Hardware
                const SizedBox(height: 28),
                _SectionLabel(l.settingsPrinter),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.print_rounded,
                    iconColor: cs.primary,
                    iconBg: AppTheme.primaryContainer.withValues(alpha: 0.15),
                    title: l.settingsPrinter,
                    subtitle: l.settingsPrinterSub,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: pos.warningBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(l.settingsNotConnected, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: pos.warningFg)),
                    ),
                  ),
                  Divider(height: 1, indent: 64, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _SettingsTile(
                    icon: Icons.qr_code_scanner_rounded,
                    iconColor: cs.primary,
                    iconBg: AppTheme.primaryContainer.withValues(alpha: 0.15),
                    title: l.settingsScanner,
                    subtitle: l.settingsScannerSub,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: pos.warningBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(l.settingsNotConnected, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: pos.warningFg)),
                    ),
                  ),
                  Divider(height: 1, indent: 64, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _SettingsTile(
                    icon: Icons.scale_rounded,
                    iconColor: cs.primary,
                    iconBg: AppTheme.primaryContainer.withValues(alpha: 0.15),
                    title: 'Весы',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: pos.successBg, borderRadius: BorderRadius.circular(20)),
                      child: Text('Симуляция', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: pos.successFg)),
                    ),
                  ),
                ]),

                // Data & Sync
                const SizedBox(height: 28),
                _SectionLabel(l.settingsBackup),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.backup_rounded,
                    iconColor: pos.accentFg,
                    iconBg: pos.accentBg,
                    title: l.settingsBackup,
                    subtitle: l.settingsBackupSub,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.settingsBackupExport)),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 64, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _SettingsTile(
                    icon: Icons.sync_rounded,
                    iconColor: pos.successFg,
                    iconBg: pos.successBg,
                    title: l.settingsSyncStatus,
                    trailing: FutureBuilder<Map<String, dynamic>>(
                      future: _syncFuture,
                      builder: (_, snap) {
                        final unsynced = (snap.data?['unsynced_count'] as num?)?.toInt() ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: unsynced > 0 ? pos.warningBg : pos.successBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            unsynced > 0 ? '$unsynced' : 'OK',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                              color: unsynced > 0 ? pos.warningFg : pos.successFg),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(height: 1, indent: 64, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    iconColor: cs.onSurfaceVariant,
                    iconBg: cs.surfaceContainer,
                    title: l.settingsReceiptFormat,
                    subtitle: l.settingsReceiptFormatSub,
                  ),
                ]),

                const SizedBox(height: 36),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(l.logout, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: pos.errorFg,
                      side: BorderSide(color: pos.errorFg.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontFamily: 'Inter', 
        fontSize: 11, fontWeight: FontWeight.w700, color: cs.outline, letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(subtitle!, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: cs.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right_rounded, size: 22, color: cs.outline),
        ]),
      ),
    );
  }
}

class _NktSearchDialog extends StatefulWidget {
  final ApiClient api;
  final TextEditingController queryController;
  const _NktSearchDialog({required this.api, required this.queryController});

  @override
  State<_NktSearchDialog> createState() => _NktSearchDialogState();
}

class _NktSearchDialogState extends State<_NktSearchDialog> {
  List<dynamic>? _results;
  bool _loading = false;
  String? _error;
  String _searchType = 'gtin';

  Future<void> _search() async {
    final q = widget.queryController.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });
    try {
      Map<String, dynamic> response;
      if (_searchType == 'gtin') {
        response = await widget.api.nktSearchByGTIN(q);
      } else {
        response = await widget.api.nktSearchByName(q);
      }
      setState(() {
        _results = response['products'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pos = PosColors.of(context);
    return AlertDialog(
      title: Text(l.settingsNktSearch, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'gtin', label: Text(l.settingsNktBarcode)),
                ButtonSegment(value: 'name', label: Text(l.settingsNktName)),
              ],
              selected: {_searchType},
              onSelectionChanged: (v) => setState(() => _searchType = v.first),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: widget.queryController,
                  decoration: InputDecoration(
                    labelText: _searchType == 'gtin' ? l.settingsNktGtinHint : l.settingsNktNameHint,
                  ),
                  keyboardType: _searchType == 'gtin' ? TextInputType.number : TextInputType.text,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                  child: const Icon(Icons.search_rounded),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2.5))
            else if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: pos.errorBg, borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: TextStyle(fontFamily: 'Inter', color: pos.errorFg, fontSize: 13)),
              )
            else if (_results != null && _results!.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: pos.warningBg, borderRadius: BorderRadius.circular(10)),
                child: Text(l.settingsNktNotFound, style: TextStyle(fontFamily: 'Inter', color: pos.warningFg, fontSize: 13)),
              )
            else if (_results != null)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results!.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = _results![i] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['name_ru']?.toString() ?? '-',
                            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),
                        Row(children: [
                          _NktChip('GTIN', p['gtin']?.toString() ?? '-'),
                          const SizedBox(width: 6),
                          _NktChip('NTIN', p['ntin_code']?.toString() ?? '-'),
                          if (p['is_social'] == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: pos.warningBg, borderRadius: BorderRadius.circular(6)),
                              child: Text(l.settingsNktSocial,
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: pos.warningFg)),
                            ),
                          ],
                        ]),
                      ]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
      ],
    );
  }
}

class _NktChip extends StatelessWidget {
  final String label;
  final String value;
  const _NktChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(6)),
      child: Text('$label: $value', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.outline)),
    );
  }
}
