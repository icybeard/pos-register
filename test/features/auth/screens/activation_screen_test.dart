import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/l10n/app_localizations.dart';
import 'package:pos_system/features/auth/controllers/auth_controller.dart';
import 'package:pos_system/features/auth/screens/activation_screen.dart';
import 'package:pos_system/services/auth/device_id_store.dart';

import '../../../mocks/mock_api_client.dart';

/// In-process DeviceIdStore for widget tests. Bypasses the real
/// FlutterSecureStorage round-trip — that platform channel hangs in
/// flutter_test instead of throwing MissingPluginException, which made
/// the controller's activateRegister handler stall on its first await.
class _FakeDeviceIdStore extends DeviceIdStore {
  @override
  Future<String> getOrCreate() async => 'test-device-id';
}

void main() {
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
  });

  // ProviderScope sits ABOVE MaterialApp so any route the screen pushes (and
  // the screen itself) can resolve `ref.read(authControllerProvider...)`.
  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          authApiClientProvider.overrideWithValue(mockApi),
          authDeviceIdStoreProvider.overrideWithValue(_FakeDeviceIdStore()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: child,
        ),
      );

  testWidgets('renders header, code field, and submit button', (tester) async {
    await tester.pumpWidget(wrap(const ActivationScreen()));
    expect(find.text('Активация кассы'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Активировать'), findsOneWidget);
  });

  testWidgets(
      'tapping submit after a valid code dispatches activation with normalized code',
      (tester) async {
    String? receivedCode;
    mockApi.onActivateRegister = ({required code, required deviceId, required deviceName}) async {
      receivedCode = code;
      // Returning an empty map keeps the controller on the error path
      // (missing workstation_id), which is fine — we only need to verify
      // dispatch.
      return <String, dynamic>{};
    };

    await tester.pumpWidget(wrap(const ActivationScreen()));
    // Lower-case + dash mimics a pasted code; the screen is contracted to
    // strip both before dispatching.
    await tester.enterText(find.byType(TextField), 'abcd-1234');
    await tester.pump();
    await tester.tap(find.text('Активировать'));
    // Drain the controller's async chain in real time. pumpAndSettle alone
    // returns before the mock-call microtask fires; runAsync gives the
    // real Dart event loop a chance to flush those microtasks.
    await tester.runAsync(() async {
      for (var i = 0; i < 20 && receivedCode == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

    expect(receivedCode, 'ABCD1234');
  });
}
