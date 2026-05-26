import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/l10n/app_localizations.dart';
import 'package:pos_system/features/auth/bloc/auth_bloc.dart';
import 'package:pos_system/features/auth/screens/owner_login_screen.dart';
import 'package:pos_system/features/auth/screens/pin_screen.dart';

import '../../../mocks/mock_api_client.dart';

void main() {
  late MockApiClient mockApi;
  late AuthBloc bloc;

  setUp(() {
    mockApi = MockApiClient();
    bloc = AuthBloc(mockApi);
  });

  tearDown(() async {
    await bloc.close();
  });

  // BlocProvider must be ABOVE MaterialApp so any route the screen pushes
  // (PinScreen → OwnerLoginScreen via the admin tile) can resolve
  // `context.read<AuthBloc>()`. With the provider under MaterialApp.home,
  // pushed routes are siblings of the provider in the Navigator tree.
  Widget wrap(Widget child) => BlocProvider<AuthBloc>.value(
        value: bloc,
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
      'renders cashier grid with admin tile after CheckFirstRun resolves',
      (tester) async {
    mockApi.onListCashiers = () async => {
          'cashiers': [
            {'ID': 'c1', 'Name': 'Алия', 'Role': 'cashier'},
          ],
        };

    await tester.pumpWidget(wrap(const PinScreen()));
    // CheckFirstRun is dispatched from initState; let the bloc round-trip.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Выберите кассира'), findsOneWidget);
    // The admin tile + the add-cashier tile are always appended to the grid.
    expect(find.text('Администратор'), findsOneWidget);
    expect(find.text('Новый кассир'), findsOneWidget);
  });

  testWidgets('tapping the admin tile pushes the owner login screen',
      (tester) async {
    mockApi.onListCashiers = () async => {
          'cashiers': <Map<String, dynamic>>[],
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
