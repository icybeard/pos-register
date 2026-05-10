import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/features/auth/bloc/auth_bloc.dart';
import 'package:pos_system/services/api_client.dart';
import 'package:pos_system/services/auth/auth_token_store.dart';
import 'package:pos_system/services/auth/workstation_store.dart';
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

  // -------------------------------------------------------------------------
  // Helper: collect N states after adding an event
  // -------------------------------------------------------------------------
  Future<List<AuthState>> collectStates(
    AuthBloc bloc,
    AuthEvent event, {
    int count = 1,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final states = <AuthState>[];
    final completer = Completer<void>();
    final sub = bloc.stream.listen((AuthState s) {
      states.add(s);
      if (states.length >= count && !completer.isCompleted) {
        completer.complete();
      }
    });

    bloc.add(event);
    await completer.future.timeout(timeout);
    await sub.cancel();
    return states;
  }

  // -------------------------------------------------------------------------
  // CheckFirstRun
  // -------------------------------------------------------------------------
  group('CheckFirstRun', () {
    test('emits isFirstRun=true when no cashiers exist', () async {
      mockApi.onListCashiers = () async => {'cashiers': <Map<String, dynamic>>[]};

      final states = await collectStates(bloc, CheckFirstRun());

      expect(states.last, isA<AuthInitial>());
      expect((states.last as AuthInitial).isFirstRun, isTrue);
    });

    test('does not change state when cashiers exist', () async {
      mockApi.onListCashiers = () async => {
            'cashiers': [
              {'ID': 'c1', 'Name': 'Admin'}
            ]
          };

      // No state TRANSITION expected for non-empty cashier list — should stay AuthInitial.
      // (AuthInitial doesn't have value equality so we filter by type, not by instance.)
      final transitions = <AuthState>[];
      final sub = bloc.stream.listen((s) {
        if (s is! AuthInitial) {
          transitions.add(s);
        }
      });
      bloc.add(CheckFirstRun());
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await sub.cancel();

      expect(transitions, isEmpty,
          reason: 'no non-AuthInitial state should be emitted when cashiers exist');
      expect(bloc.state, isA<AuthInitial>());
    });
  });

  // -------------------------------------------------------------------------
  // PinDigitPressed — accumulation
  // -------------------------------------------------------------------------
  group('PinDigitPressed accumulation', () {
    test('accumulates digits up to 3 without submitting', () async {
      final states =
          await collectStates(bloc, PinDigitPressed('1'));
      expect((states.last as AuthInitial).pin, '1');

      final states2 =
          await collectStates(bloc, PinDigitPressed('2'));
      expect((states2.last as AuthInitial).pin, '12');

      final states3 =
          await collectStates(bloc, PinDigitPressed('3'));
      expect((states3.last as AuthInitial).pin, '123');
    });

    // NOTE: the legacy `_api.login(pin)` flow was replaced with explicit
    // owner-login (email+password) and cashier-login (workstation-scoped
    // login+pin) in the activation-first auth redesign. The PIN digit
    // accumulation is still wired to a cashier-login attempt via
    // `_ownerTenantId`, but without activation the bloc rejects with a
    // clear error. New flows are covered in the "OwnerLoginRequested" and
    // "ActivateRegisterRequested" groups below; we keep a single
    // regression test here for the "dormant PIN path" guardrail.
    test('4th digit with no active workstation surfaces a clear error', () async {
      for (final d in ['1', '2', '3']) {
        await collectStates(bloc, PinDigitPressed(d));
      }
      final states =
          await collectStates(bloc, PinDigitPressed('4'), count: 2);
      expect(states.any((s) => s is AuthLoading), isTrue);
      expect(states.last, isA<AuthInitial>());
      expect((states.last as AuthInitial).error, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // PinBackspacePressed
  // -------------------------------------------------------------------------
  group('PinBackspacePressed', () {
    test('removes last digit', () async {
      await collectStates(bloc, PinDigitPressed('1'));
      await collectStates(bloc, PinDigitPressed('2'));

      final states = await collectStates(bloc, PinBackspacePressed());
      expect((states.last as AuthInitial).pin, '1');
    });

    test('does nothing on empty pin', () async {
      // No transition out of AuthInitial — filter by type since AuthInitial lacks value equality.
      final transitions = <AuthState>[];
      final sub = bloc.stream.listen((s) {
        if (s is! AuthInitial) {
          transitions.add(s);
        }
      });
      bloc.add(PinBackspacePressed());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
      expect(transitions, isEmpty);
      expect(bloc.state, isA<AuthInitial>());
    });
  });

  // -------------------------------------------------------------------------
  // LogoutRequested
  // -------------------------------------------------------------------------
  group('LogoutRequested', () {
    test('without a workstation, logout lands on RegisterNotActivated', () async {
      // Sans activation payload, logout falls back to the pre-activation
      // state so the boot router shows ActivationScreen. `AuthInitial` is
      // a legacy state reached only through the owner-login error path.
      final states = await collectStates(bloc, LogoutRequested());
      expect(states.last, isA<RegisterNotActivated>());
    });
  });

  // -------------------------------------------------------------------------
  // CreateFirstCashier — LEGACY PATH
  //
  // The setup-wizard flow was removed when registration moved exclusively
  // to the React web admin. The `CreateFirstCashier` event is retained
  // only so a stray dispatch surfaces an informative error instead of
  // crashing. Full tenant creation is tested server-side via
  // `POST /api/signup` integration tests.
  // -------------------------------------------------------------------------
  group('CreateFirstCashier (legacy stub)', () {
    test('emits an explicit "use web admin" message, no auth', () async {
      final states = await collectStates(
        bloc,
        CreateFirstCashier('Admin', '1234'),
        count: 1,
      );
      expect(states.last, isA<AuthInitial>());
      final last = states.last as AuthInitial;
      expect(last.error, isNotNull);
      expect(last.error!.toLowerCase(), contains('админ'));
    });
  });

  // -------------------------------------------------------------------------
  // OwnerLoginRequested — primary boot path on the register
  // -------------------------------------------------------------------------
  group('OwnerLoginRequested', () {
    test('owner credentials surface a sensible error on 401', () async {
      mockApi.onOwnerLogin = ({required email, required password}) async =>
          throw ApiException(401, '{"error":"bad credentials"}');
      final states = await collectStates(
        bloc,
        OwnerLoginRequested(email: 'a@b.c', password: 'wrong'),
        count: 2,
      );
      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthInitial>());
      final last = states.last as AuthInitial;
      expect(last.error, isNotNull);
      // Looking for the Russian-language equivalent of "invalid credentials".
      expect(last.error!.toLowerCase(), anyOf(contains('неверн'), contains('паро')));
    });

    test('network error surfaces "нет связи"', () async {
      mockApi.onOwnerLogin = ({required email, required password}) async =>
          throw Exception('timeout');
      final states = await collectStates(
        bloc,
        OwnerLoginRequested(email: 'a@b.c', password: 'x'),
        count: 2,
      );
      final last = states.last as AuthInitial;
      expect(last.error!.toLowerCase(), contains('связи'));
    });
  });

  // -------------------------------------------------------------------------
  // ActivateRegisterRequested — first-boot activation flow
  // -------------------------------------------------------------------------
  group('ActivateRegisterRequested', () {
    test('401 "already used" maps to the specific Russian message', () async {
      mockApi.onActivateRegister =
          ({required code, required deviceId, required deviceName}) async =>
              throw ApiException(401, '{"error":"activation code already used"}');
      final states = await collectStates(
        bloc,
        ActivateRegisterRequested('USED1234'),
        count: 2,
      );
      expect(states.last, isA<RegisterNotActivated>());
      final last = states.last as RegisterNotActivated;
      expect(last.error, isNotNull);
      expect(last.error!.toLowerCase(), contains('уже использован'));
    });

    test('network error surfaces "нет связи"', () async {
      mockApi.onActivateRegister =
          ({required code, required deviceId, required deviceName}) async =>
              throw Exception('dns');
      final states = await collectStates(
        bloc,
        ActivateRegisterRequested('ANYCODE1'),
        count: 2,
      );
      final last = states.last as RegisterNotActivated;
      expect(last.error!.toLowerCase(), contains('связи'));
    });
  });

  // Lockout after maxAttempts — register-side lockout tracking was tied
  // to the removed PIN auto-submit flow. Server-side lockout lives in
  // Pos.Infrastructure.Auth.PinLockoutService and is covered by the .NET
  // integration tests (attempt counters and 423 responses from
  // /api/auth/cashier-login).

  // -------------------------------------------------------------------------
  // HydrateSession — activation invariant
  // -------------------------------------------------------------------------
  //
  // A workstation row without a usable device JWT pair is NOT really
  // activated. Without this guard, a register that was activated under the
  // pre-JWT anonymous flow (or whose tokens have fully expired) would land
  // on PinScreen, hit 401 on listCashiers, and show an empty cashier grid
  // with no way out. The hydrate handler must clear the stale binding and
  // route to ActivationScreen instead.
  group('HydrateSession', () {
    test('workstation present but device tokens missing → RegisterNotActivated + clears stores', () async {
      final wsInfo = WorkstationInfo(
        workstationId: 'ws-1',
        tenantId: 'tn-1',
        storeId: 'st-1',
        storeName: 'Test',
        activatedAt: DateTime.now().toUtc(),
      );
      final wsStore = _FakeWorkstationStore(initial: wsInfo);
      final userTokens = _FakeAuthTokenStore();
      final deviceTokens = _FakeAuthTokenStore(); // load() returns null

      final hydrateBloc = AuthBloc(
        mockApi,
        workstation: wsStore,
        tokens: userTokens,
        deviceTokens: deviceTokens,
      );
      addTearDown(hydrateBloc.close);

      final states = await collectStates(hydrateBloc, HydrateSession());

      expect(states.last, isA<RegisterNotActivated>(),
          reason: 'no device tokens ⇒ register is not really activated');
      expect(wsStore.clearCalls, 1, reason: 'stale workstation must be wiped');
      expect(userTokens.clearCalls, 1);
      expect(deviceTokens.clearCalls, 1);
    });

    test('workstation present with valid device tokens → RegisterActivated', () async {
      final wsInfo = WorkstationInfo(
        workstationId: 'ws-1',
        tenantId: 'tn-1',
        storeId: 'st-1',
        storeName: 'Test',
        activatedAt: DateTime.now().toUtc(),
      );
      final future = DateTime.now().toUtc().add(const Duration(hours: 23));
      final wsStore = _FakeWorkstationStore(initial: wsInfo);
      final userTokens = _FakeAuthTokenStore();
      final deviceTokens = _FakeAuthTokenStore(
        initial: AuthTokens(
          accessToken: 'access-jwt',
          refreshToken: 'refresh-secret',
          accessExpiresAt: future,
          refreshExpiresAt: future.add(const Duration(days: 90)),
          tenantId: 'tn-1',
          role: 'device',
          storeId: 'st-1',
          workstationId: 'ws-1',
        ),
      );

      final hydrateBloc = AuthBloc(
        mockApi,
        workstation: wsStore,
        tokens: userTokens,
        deviceTokens: deviceTokens,
      );
      addTearDown(hydrateBloc.close);

      final states = await collectStates(hydrateBloc, HydrateSession());

      expect(states.last, isA<RegisterActivated>(),
          reason: 'valid device tokens ⇒ register is activated');
      expect(wsStore.clearCalls, 0, reason: 'must NOT wipe a healthy binding');
      expect(deviceTokens.clearCalls, 0);
    });
  });
}

// In-test fakes. We subclass the real stores rather than mocking the
// FlutterSecureStorage they hold, because the storage field is initialised
// in the const default constructor and never touched once we override the
// three public methods (load / save / clear).

class _FakeWorkstationStore extends WorkstationStore {
  _FakeWorkstationStore({WorkstationInfo? initial}) : _info = initial;
  WorkstationInfo? _info;
  int clearCalls = 0;

  @override
  Future<WorkstationInfo?> load() async => _info;

  @override
  Future<void> save(WorkstationInfo info) async {
    _info = info;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    _info = null;
  }
}

class _FakeAuthTokenStore extends AuthTokenStore {
  _FakeAuthTokenStore({AuthTokens? initial}) : _tokens = initial;
  AuthTokens? _tokens;
  int clearCalls = 0;

  @override
  Future<AuthTokens?> load() async => _tokens;

  @override
  Future<void> save(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    _tokens = null;
  }
}
