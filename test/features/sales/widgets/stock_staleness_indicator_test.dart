import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/features/sales/widgets/stock_staleness_indicator.dart';
import 'package:pos_system/services/stock/stock_freshness_service.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  StockFreshnessSnapshot snap(StockFreshness t, Duration age) =>
      StockFreshnessSnapshot(tier: t, age: age);

  // Colour from the indicator — read from the decoration of the single
  // circular Container descendant. Reading the decoration keeps the test
  // resilient to Tooltip / Semantics wrapping changes.
  Color? dotColor(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(StockStalenessIndicator),
        matching: find.byType(Container),
      ),
    );
    return (container.decoration as BoxDecoration?)?.color;
  }

  group('StockStalenessIndicator', () {
    testWidgets('shows grey for unknown tier (no data yet)', (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessIndicator(stream: ctrl.stream)));
      await tester.pumpAndSettle();
      expect(dotColor(tester), Colors.grey);
    });

    testWidgets('shows green when fresh', (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessIndicator(stream: ctrl.stream)));
      ctrl.add(snap(StockFreshness.fresh, const Duration(seconds: 10)));
      await tester.pumpAndSettle();
      expect(dotColor(tester), Colors.green);
    });

    testWidgets('shows amber when stale', (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessIndicator(stream: ctrl.stream)));
      ctrl.add(snap(StockFreshness.stale, const Duration(minutes: 2)));
      await tester.pumpAndSettle();
      expect(dotColor(tester), Colors.amber);
    });

    testWidgets('shows red when outdated', (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessIndicator(stream: ctrl.stream)));
      ctrl.add(snap(StockFreshness.outdated, const Duration(minutes: 10)));
      await tester.pumpAndSettle();
      expect(dotColor(tester), Colors.red);
    });

    testWidgets('tier transitions are reflected on the next pump', (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessIndicator(stream: ctrl.stream)));
      ctrl.add(snap(StockFreshness.fresh, const Duration(seconds: 5)));
      await tester.pumpAndSettle();
      expect(dotColor(tester), Colors.green);

      ctrl.add(snap(StockFreshness.outdated, const Duration(minutes: 30)));
      await tester.pumpAndSettle();
      expect(dotColor(tester), Colors.red);
    });

    testWidgets('semantic label describes the tier for screen readers',
        (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessIndicator(stream: ctrl.stream)));
      ctrl.add(snap(StockFreshness.outdated, const Duration(minutes: 12)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Остаток устарел'), findsOneWidget);
    });
  });

  group('StockStalenessBanner', () {
    testWidgets('renders nothing when tier is fresh', (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessBanner(stream: ctrl.stream)));
      ctrl.add(snap(StockFreshness.fresh, const Duration(seconds: 3)));
      await tester.pumpAndSettle();
      // No warning text when data is fresh
      expect(find.textContaining('неточным'), findsNothing);
    });

    testWidgets('renders nothing when tier is stale (yellow, still usable)',
        (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessBanner(stream: ctrl.stream)));
      ctrl.add(snap(StockFreshness.stale, const Duration(minutes: 3)));
      await tester.pumpAndSettle();
      expect(find.textContaining('неточным'), findsNothing);
    });

    testWidgets('shows the warning text when tier is outdated', (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessBanner(stream: ctrl.stream)));
      ctrl.add(snap(StockFreshness.outdated, const Duration(minutes: 10)));
      await tester.pumpAndSettle();
      expect(find.textContaining('неточным'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('hides again when tier recovers to fresh', (tester) async {
      final ctrl = StreamController<StockFreshnessSnapshot>.broadcast();
      addTearDown(ctrl.close);
      await tester.pumpWidget(host(StockStalenessBanner(stream: ctrl.stream)));
      ctrl.add(snap(StockFreshness.outdated, const Duration(minutes: 10)));
      await tester.pumpAndSettle();
      expect(find.textContaining('неточным'), findsOneWidget);

      ctrl.add(snap(StockFreshness.fresh, const Duration(seconds: 1)));
      await tester.pumpAndSettle();
      expect(find.textContaining('неточным'), findsNothing);
    });
  });
}
