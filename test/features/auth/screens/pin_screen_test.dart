import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/l10n/app_localizations.dart';
import 'package:pos_system/features/auth/controllers/auth_controller.dart';
import 'package:pos_system/features/auth/screens/owner_login_screen.dart';
import 'package:pos_system/features/auth/screens/pin_screen.dart';
import 'package:pos_system/services/auth/device_id_store.dart';

import '../../../mocks/mock_api_client.dart';

/// See activation_screen_test.dart — the real FlutterSecureStorage hangs
/// in flutter_test, so we substitute an in-process DeviceIdStore.
class _FakeDeviceIdStore extends DeviceIdStore {
  @override
  Future<String> getOrCreate() async => 'test-device-id';
}

void main() {
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
  });

  // ProviderScope sits ABOVE MaterialApp so any route the screen pushes
  // (PinScreen → OwnerLoginScreen via the admin tile) can resolve
  // `ref.read(authControllerProvider)`. With the scope under MaterialApp.home,
  // pushed routes would be siblings of the scope in the Navigator tree and
  // couldn't see it.
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

  testWidgets(
      'renders cashier grid with admin tile after checkFirstRun resolves',
      (tester) async {
    mockApi.onListCashiers = () async => {
          'cashiers': [
            {'ID': 'c1', 'Name': 'Алия', 'Role': 'cashier'},
          ],
        };

    await tester.pumpWidget(wrap(const PinScreen()));
    // checkFirstRun is dispatched from initState via a post-frame callback;
    // let the controller round-trip.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Выберите кассира'), findsOneWidget);
    // The admin tile + the add-cashier tile are always appended to the grid.
    expect(find.text('Администратор'), findsOneWidget);
    expect(find.text('Новый кассир'), findsOneWidget);
  });

  testWidgets('tapping the admin tile pushes the owner login screen',
      (tester) async {
    // At least one cashier required — an empty list trips checkFirstRun's
    // first-run branch in AuthController and the screen renders
    // _FirstRunSetup instead of the cashier grid.
    mockApi.onListCashiers = () async => {
          'cashiers': [
            {'ID': 'c1', 'Name': 'Алия', 'Role': 'cashier'},
          ],
        };

    await tester.pumpWidget(wrap(const PinScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Администратор'));
    await tester.pumpAndSettle();

    // OwnerLoginScreen renders the "Войти" submit button — finding it
    // proves the route was pushed and is visible above PinScreen.
    expect(find.byType(OwnerLoginScreen), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });
}
