import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/l10n/app_localizations.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/cashier_repository.dart';
import 'package:pos_system/features/sales/widgets/manager_override_dialog.dart';
import 'package:pos_system/services/override/manager_override_service.dart';

void main() {
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const storeId = '22222222-2222-2222-2222-222222222222';

  // Plain-text verifier — the service-level tests already cover bcrypt.
  bool plainVerify(String pin, String hash) => pin == hash;

  late AppDatabase db;
  late CashierRepository cashiers;
  late ManagerOverrideService svc;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cashiers = CashierRepository(db, tenantId: tenantId);
    svc = ManagerOverrideService(cashiers, verifier: plainVerify);
  });

  tearDown(() async => db.close());

  Future<void> seed({
    required String login,
    required String role,
    String pin = '1234',
    bool isActive = true,
  }) async {
    await cashiers.create(
      storeId: storeId,
      name: login,
      login: login,
      pinHash: pin,
      role: role,
      isActive: isActive,
    );
  }

  /// Pump a scaffold that opens the dialog on build, returning the Future the
  /// dialog will complete with. The default 800×600 test surface clips the
  /// dialog's submit row off-screen (the dialog renders ~700px tall with
  /// header + reason strip + login + pin pad + buttons), so we enlarge the
  /// vertical extent before pumping. addTearDown restores the default size
  /// so unrelated tests aren't affected.
  Future<Future<UserRow?>> pumpDialog(
    WidgetTester tester, {
    String? subtitle,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late Future<UserRow?> resultFuture;
    await tester.pumpWidget(MaterialApp(
      // Dialog renders Russian strings via AppLocalizations; tests assert
      // on the literal RU text below, so pin the locale to ru.
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () {
              resultFuture = ManagerOverrideDialog.show(
                ctx,
                service: svc,
                subtitle: subtitle,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return resultFuture;
  }

  /// Tap each digit on the HifiPinPad. Replaces a TextField-based entry
  /// that was used by an earlier dialog design — current implementation
  /// drives PIN state through a custom keypad, not an input field.
  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
  }

  /// Tap the submit FilledButton. Its label is `"✓ Подтвердить"`, so a
  /// strict `find.text('Подтвердить')` misses; match on the substring.
  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.tap(find.textContaining('Подтвердить'));
    await tester.pumpAndSettle();
  }

  group('success paths', () {
    testWidgets('manager with correct PIN → dialog pops with the user',
        (tester) async {
      await seed(login: 'masha', role: 'manager', pin: '9999');
      final future = await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'masha');
      await enterPin(tester, '9999');
      await tapSubmit(tester);

      final user = await future;
      expect(user, isNotNull);
      expect(user!.login, 'masha');
      expect(user.role, 'manager');
      expect(find.byType(ManagerOverrideDialog), findsNothing);
    });
  });

  group('failure outcomes (dialog stays open, PIN cleared, role-specific message)', () {
    testWidgets('unknown login → "Логин не найден"', (tester) async {
      await pumpDialog(tester);
      await tester.enterText(find.byType(TextField), 'ghost');
      await enterPin(tester, '1234');
      await tapSubmit(tester);
      expect(find.text('Логин не найден'), findsOneWidget);
      expect(find.byType(ManagerOverrideDialog), findsOneWidget,
          reason: 'dialog stays open so the user can fix the login');
    });

    testWidgets('wrong PIN → "Неверный PIN" + PIN cleared, login kept',
        (tester) async {
      await seed(login: 'masha', role: 'manager', pin: '9999');
      await pumpDialog(tester);
      await tester.enterText(find.byType(TextField), 'masha');
      await enterPin(tester, '0000');
      await tapSubmit(tester);

      expect(find.text('Неверный PIN'), findsOneWidget);
      // Login kept so the cashier retries only the PIN.
      final loginField = tester.widget<TextField>(find.byType(TextField));
      expect(loginField.controller!.text, 'masha');
      // PIN cleared so a fat-fingered attempt can't replay — verify by
      // confirming the submit button is disabled (it requires _pin.length
      // == 4 to be onPressed-non-null). When _pin is reset to '', the
      // button is disabled.
      final submit = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, '✓ Подтвердить'));
      expect(submit.onPressed, isNull,
          reason: 'submit disabled because _pin was cleared after failure');
    });

    testWidgets('plain cashier → "не может авторизовать" (names the user)',
        (tester) async {
      await seed(login: 'ivan', role: 'cashier');
      await pumpDialog(tester);
      await tester.enterText(find.byType(TextField), 'ivan');
      await enterPin(tester, '1234');
      await tapSubmit(tester);
      // Widget message: "$name не может авторизовать эту операцию".
      // Use textContaining so this test doesn't bind to the exact wording —
      // the contract is just that the user's name is surfaced.
      expect(find.textContaining('ivan не может авторизовать'), findsOneWidget);
    });

    testWidgets('inactive manager → "Учётная запись отключена"',
        (tester) async {
      await seed(login: 'former', role: 'manager', isActive: false);
      await pumpDialog(tester);
      await tester.enterText(find.byType(TextField), 'former');
      await enterPin(tester, '1234');
      await tapSubmit(tester);
      expect(find.textContaining('отключена'), findsOneWidget);
    });
  });

  group('UX', () {
    testWidgets('Cancel returns null', (tester) async {
      final future = await pumpDialog(tester);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(await future, isNull);
    });

    testWidgets('subtitle renders when provided', (tester) async {
      await pumpDialog(tester,
          subtitle: 'Продажа ниже остатка: Кола — 2 шт при 1');
      expect(find.textContaining('Продажа ниже остатка'), findsOneWidget);
    });
  });
}
