import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'api_client.dart';

/// Service for generating and printing price labels
class PrintService {
  final ApiClient api;

  PrintService(this.api);

  /// Generate PDF labels from Go backend and send to printer
  Future<void> printLabels({
    required List<String> productIds,
    required BuildContext context,
    String size = 'shelf', // 'shelf' (60x40mm) or 'thermal' (80x30mm)
  }) async {
    final pdfBytes = await api.generateLabels(productIds: productIds, size: size);

    await Printing.layoutPdf(
      onLayout: (_) => Future.value(pdfBytes),
      name: 'price-labels',
    );
  }

  /// Preview PDF in dialog before printing
  Future<void> previewLabels({
    required List<String> productIds,
    required BuildContext context,
    String size = 'shelf',
  }) async {
    final pdfBytes = await api.generateLabels(productIds: productIds, size: size);

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Ценники')),
          body: PdfPreview(
            build: (_) => Future.value(pdfBytes),
            canChangeOrientation: false,
            canChangePageFormat: false,
          ),
        ),
      ),
    );
  }
}
