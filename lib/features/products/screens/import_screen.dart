import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/hifi.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';

/// Экран импорта товаров из Excel
class ImportScreen extends StatefulWidget {
  final ApiClient api;
  const ImportScreen({super.key, required this.api});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

enum _ImportStep { upload, preview, done }

class _ImportScreenState extends State<ImportScreen> {
  _ImportStep _step = _ImportStep.upload;
  bool _loading = false;
  String? _taskId;
  List<dynamic>? _preview;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _downloadTemplate() async {
    setState(() => _loading = true);
    try {
      final bytes = await widget.api.downloadImportTemplate();
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/import_template.xlsx');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.importTemplateSaved}: ${file.path}')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    // On desktop, read from a simple file dialog or allow user to type path
    // For simplicity, we use a file chooser-like approach with stdin
    // In a real app, use file_picker package. For now, show text input dialog.
    final path = await _showFilePathDialog();
    if (path == null || path.isEmpty) return;

    final file = File(path);
    if (!file.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл не найден')),
        );
      }
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final bytes = await file.readAsBytes();
      final filename = path.split(Platform.pathSeparator).last;
      final response = await widget.api.uploadProductsExcel(bytes, filename);

      setState(() {
        _taskId = response['task_id'] as String?;
        _preview = response['preview'] as List?;
        _step = _ImportStep.preview;
        _loading = false;
      });
    } on Exception catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<String?> _showFilePathDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Путь к Excel-файлу'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '/path/to/file.xlsx'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Загрузить'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    if (_taskId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final response = await widget.api.confirmImport(_taskId!);
      setState(() {
        _result = response;
        _step = _ImportStep.done;
        _loading = false;
      });
    } on Exception catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _cancel() async {
    if (_taskId == null) return;
    try {
      await widget.api.cancelImport(_taskId!);
    } on Exception catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);

    return Scaffold(
      backgroundColor: Hifi.canvas,
      // Push-routed flow (Navigator.push from ProductsScreen). Outside
      // the shell, so render the navy chrome locally with a back button.
      appBar: HifiChrome(
        leading: BackButton(color: Colors.white, onPressed: () => Navigator.of(context).maybePop()),
        title: l.importTitle,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : switch (_step) {
              _ImportStep.upload => _buildUploadStep(l, cs, pos),
              _ImportStep.preview => _buildPreviewStep(l, cs, pos),
              _ImportStep.done => _buildDoneStep(l, cs, pos),
            },
    );
  }

  Widget _buildUploadStep(AppLocalizations l, ColorScheme cs, PosColors pos) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.upload_file_rounded, size: 64, color: cs.primary),
        const SizedBox(height: 16),
        Text(l.importUploadHint, style: const TextStyle(fontFamily: 'Inter', fontSize: 16), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(fontFamily: 'Inter', color: pos.errorFg, fontSize: 13)),
          const SizedBox(height: 16),
        ],
        Row(mainAxisSize: MainAxisSize.min, children: [
          OutlinedButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download_rounded),
            label: Text(l.importDownloadTemplate),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _pickAndUpload,
            icon: const Icon(Icons.file_open_rounded),
            label: Text(l.importSelectFile),
          ),
        ]),
      ]),
    ));
  }

  Widget _buildPreviewStep(AppLocalizations l, ColorScheme cs, PosColors pos) {
    final creates = _preview?.where((p) => p['action'] == 'create' && (p['errors'] as List?)?.isEmpty != false).length ?? 0;
    final updates = _preview?.where((p) => p['action'] == 'update' && (p['errors'] as List?)?.isEmpty != false).length ?? 0;
    final errors = _preview?.where((p) => (p['errors'] as List?)?.isNotEmpty == true).length ?? 0;

    return Column(children: [
      // Summary bar
      Container(
        padding: const EdgeInsets.all(16),
        color: cs.surfaceContainerHighest,
        child: Row(children: [
          _CountChip(label: l.importCreate, count: creates, color: pos.successFg),
          const SizedBox(width: 12),
          _CountChip(label: l.importUpdate, count: updates, color: pos.accentFg),
          const SizedBox(width: 12),
          _CountChip(label: l.importErrors, count: errors, color: pos.errorFg),
          const Spacer(),
          TextButton(onPressed: _cancel, child: Text(l.cancel)),
          const SizedBox(width: 8),
          FilledButton(onPressed: creates + updates > 0 ? _confirm : null, child: Text(l.importConfirm)),
        ]),
      ),
      if (_error != null) Padding(
        padding: const EdgeInsets.all(8),
        child: Text(_error!, style: TextStyle(color: pos.errorFg)),
      ),
      // Preview table
      Expanded(child: ListView.builder(
        itemCount: _preview?.length ?? 0,
        itemBuilder: (context, i) {
          final row = _preview![i];
          final action = row['action'] as String? ?? '';
          final name = row['name'] as String? ?? '';
          final barcode = row['barcode'] as String? ?? '';
          final rowErrors = (row['errors'] as List?) ?? [];
          final data = row['data'] as Map<String, dynamic>? ?? {};
          final price = (data['sale_price'] as num?)?.toInt() ?? 0;

          Color actionColor;
          String actionLabel;
          switch (action) {
            case 'create':
              actionColor = pos.successFg;
              actionLabel = l.importCreate;
            case 'update':
              actionColor = pos.accentFg;
              actionLabel = l.importUpdate;
            default:
              actionColor = cs.outline;
              actionLabel = '-';
          }

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: rowErrors.isNotEmpty ? pos.errorFg.withValues(alpha: 0.15) : actionColor.withValues(alpha: 0.15),
              child: rowErrors.isNotEmpty
                  ? Icon(Icons.error_outline, size: 16, color: pos.errorFg)
                  : Text(actionLabel[0], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: actionColor)),
            ),
            title: Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: rowErrors.isNotEmpty
                ? Text(rowErrors.join(', '), style: TextStyle(fontSize: 11, color: pos.errorFg))
                : Text('$barcode  ${Money.format(price)}', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.outline)),
            trailing: Text(actionLabel, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: actionColor)),
          );
        },
      )),
    ]);
  }

  Widget _buildDoneStep(AppLocalizations l, ColorScheme cs, PosColors pos) {
    final created = (_result?['created'] as num?)?.toInt() ?? 0;
    final updated = (_result?['updated'] as num?)?.toInt() ?? 0;
    final skipped = (_result?['skipped'] as num?)?.toInt() ?? 0;

    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, size: 64, color: pos.successFg),
        const SizedBox(height: 16),
        Text(l.importDone, style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text('${l.importCreate}: $created', style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
        Text('${l.importUpdate}: $updated', style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
        Text('${l.importSkipped}: $skipped', style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.done)),
      ]),
    ));
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $count', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
