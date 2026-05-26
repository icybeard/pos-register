import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/l10n/app_localizations.dart';
import 'package:pos_system/features/auth/bloc/auth_bloc.dart';
import 'package:pos_system/features/auth/screens/owner_login_screen.dart';

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
  // (and the screen itself) can resolve `context.read<AuthBloc>()`. With
  // the provider under MaterialApp.home, pushed routes are siblings of
  // the provider in the Navigator tree and `read` throws.
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

  testWidgets('renders email + password fields and login button', (tester) async {
    await tester.pumpWidget(wrap(const OwnerLoginScreen()));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('empty submit shows form validation errors and does not call api',
      (tester) async {
    var ownerLoginCalled = false;
    mockApi.onOwnerLogin = ({required email, required password}) async {
      ownerLoginCalled = true;
      return <String, dynamic>{};
    };

    await tester.pumpWidget(wrap(const OwnerLoginScreen()));
    await tester.tap(find.text('Войти'));
    await tester.pump();

    expect(find.text('Введите email'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
    expect(ownerLoginCalled, isFalse);
  });

  testWidgets('valid submit dispatches owner-login with trimmed email',
      (tester) async {
    String? receivedEmail;
    String? receivedPassword;
    mockApi.onOwnerLogin = ({required email, required password}) async {
      receivedEmail = email;
      receivedPassword = password;
      // Throwing keeps the bloc on the error branch — fine here, we only
      // need to verify the call shape.
      throw Exception('no-network in test');
    };

    await tester.pumpWidget(wrap(const OwnerLoginScreen()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  owner@example.com  ');
    await tester.enterText(fields.at(1), 'hunter2');
    await tester.tap(find.text('Войти'));
    // Drain the bloc's async chain in real time. The bloc's stream queue
    // runs in a zone the test scheduler doesn't drive, so a plain pump
    // can't complete the dispatch. runAsync hands control to the real
    // Dart event loop just long enough for the mock callback to fire.
    await tester.runAsync(() async {
      for (var i = 0; i < 20 && receivedEmail == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

    expect(receivedEmail, 'owner@example.com');
    expect(receivedPassword, 'hunter2');
  });
}
