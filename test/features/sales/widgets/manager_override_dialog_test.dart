import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  /// dialog will complete with. The test drives the dialog through taps.
  Future<Future<UserRow?>> pumpDialog(
    WidgetTester tester, {
    String? subtitle,
  }) async {
    late Future<UserRow?> resultFuture;
    await tester.pumpWidget(MaterialApp(
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

  group('success paths', () {
    testWidgets('manager with correct PIN → dialog pops with the user', (tester) async {
      await seed(login: 'masha', role: 'manager', pin: '9999');
      final future = await pumpDialog(tester);

      await tester.enterText(find.byType(TextField).at(0), 'masha');
      await tester.enterText(find.byType(TextField).at(1), '9999');
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();

      final user = await future;
      expect(user, isNotNull);
      expect(user!.login, 'masha');
      expect(user.role, 'manager');
      // Dialog is gone
      expect(find.byType(ManagerOverrideDialog), findsNothing);
    });
  });

  group('failure outcomes (dialog stays open, PIN cleared, role-specific message)', () {
    testWidgets('unknown login → "Логин не найден"', (tester) async {
      await pumpDialog(tester);
      await tester.enterText(find.byType(TextField).at(0), 'ghost');
      await tester.enterText(find.byType(TextField).at(1), '1234');
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
      expect(find.text('Логин не найден'), findsOneWidget);
      expect(find.byType(ManagerOverrideDialog), findsOneWidget,
          reason: 'dialog stays open so the user can fix the login');
    });

    testWidgets('wrong PIN → "Неверный PIN" + PIN cleared, login kept', (tester) async {
      await seed(login: 'masha', role: 'manager', pin: '9999');
      await pumpDialog(tester);
      await tester.enterText(find.byType(TextField).at(0), 'masha');
      // PIN field enforces digitsOnly — must use a numeric wrong PIN, else
      // the formatter eats the input and the empty-pin short-circuit fires
      // which would look like `notFound` instead of `wrongPin`.
      await tester.enterText(find.byType(TextField).at(1), '0000');
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();

      expect(find.text('Неверный PIN'), findsOneWidget);
      final loginField = tester.widget<TextField>(find.byType(TextField).at(0));
      final pinField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(loginField.controller!.text, 'masha',
          reason: 'login kept so cashier just retypes the PIN');
      expect(pinField.controller!.text, '',
          reason: 'PIN cleared so a fat-fingered attempt cant replay');
    });

    testWidgets('plain cashier → "не может авторизовать" (names the user)', (tester) async {
      await seed(login: 'ivan', role: 'cashier');
      await pumpDialog(tester);
      await tester.enterText(find.byType(TextField).at(0), 'ivan');
      await tester.enterText(find.byType(TextField).at(1), '1234');
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
      // User's name is in the message so the cashier knows which person
      // actually needs to come over — not a generic "ask a manager". Find the
      // full error text so we don't collide with the login TextField also
      // containing "ivan".
      expect(
        find.text('ivan не может авторизовать продажу ниже остатка — позовите менеджера'),
        findsOneWidget,
      );
    });

    testWidgets('inactive manager → "Учётная запись отключена"', (tester) async {
      await seed(login: 'former', role: 'manager', isActive: false);
      await pumpDialog(tester);
      await tester.enterText(find.byType(TextField).at(0), 'former');
      await tester.enterText(find.byType(TextField).at(1), '1234');
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
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
      await pumpDialog(tester, subtitle: 'Продажа ниже остатка: Кола — 2 шт при 1');
      expect(find.textContaining('Продажа ниже остатка'), findsOneWidget);
    });
  });
}
