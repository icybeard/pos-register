import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// `BaseClient` wrapper that logs every request/response that flows through
/// `package:http`. Drop it around any `http.Client()` and all GETs, POSTs,
/// multipart uploads, etc. funnel through one `send()` — so logging lives in
/// one place instead of being sprinkled per-method.
///
/// Output is gated by [kDebugMode] so release builds stay silent. Auth-ish
/// fields in JSON bodies are redacted before printing.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient(this._inner);

  final http.Client _inner;

  static const _redactKeys = {
    'password',
    'pin',
    'new_pin',
    'access_token',
    'refresh_token',
    'token',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!kDebugMode) return _inner.send(request);

    final sw = Stopwatch()..start();
    debugPrint('[HTTP →] ${request.method} ${request.url}');
    if (request is http.Request && request.body.isNotEmpty) {
      debugPrint('         body: ${_redact(request.body)}');
    } else if (request is http.MultipartRequest) {
      final files = request.files.map((f) => '${f.field}=${f.filename}(${f.length}B)').join(', ');
      debugPrint('         multipart fields=${request.fields} files=[$files]');
    }

    try {
      final resp = await _inner.send(request);
      final bytes = await resp.stream.toBytes();
      sw.stop();
      debugPrint(
        '[HTTP ←] ${resp.statusCode} ${request.method} ${request.url} '
        '(${sw.elapsedMilliseconds}ms, ${bytes.length}B)',
      );
      if (resp.statusCode >= 400) {
        debugPrint('         err: ${_truncate(utf8.decode(bytes, allowMalformed: true))}');
      }
      return http.StreamedResponse(
        Stream.value(bytes),
        resp.statusCode,
        contentLength: bytes.length,
        request: resp.request,
        headers: resp.headers,
        isRedirect: resp.isRedirect,
        persistentConnection: resp.persistentConnection,
        reasonPhrase: resp.reasonPhrase,
      );
    } catch (e) {
      sw.stop();
      debugPrint('[HTTP ✗] ${request.method} ${request.url} (${sw.elapsedMilliseconds}ms): $e');
      rethrow;
    }
  }

  String _redact(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map) {
        final masked = <String, dynamic>{
          for (final e in decoded.entries)
            e.key.toString():
                _redactKeys.contains(e.key.toString().toLowerCase()) ? '***' : e.value,
        };
        return _truncate(json.encode(masked));
      }
    } on FormatException {
      // Not JSON — fall through to raw truncation.
    }
    return _truncate(body);
  }

  String _truncate(String s, {int max = 500}) =>
      s.length <= max ? s : '${s.substring(0, max)}…(+${s.length - max})';

  @override
  void close() => _inner.close();
}
