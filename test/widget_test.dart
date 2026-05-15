import 'package:flutter_test/flutter_test.dart';
import 'package:pongpong/main.dart';

void main() {
  testWidgets('start flow reaches scan screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PongPongApp());

    expect(find.text('PongPong MVP'), findsWidgets);
    expect(find.text('Start Game'), findsOneWidget);

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(find.text('Safety Check'), findsWidgets);

    await tester.tap(find.text('I Have Space'));
    await tester.pumpAndSettle();

    expect(find.text('Scan Your Play Area'), findsWidgets);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Scan Left Boundary'), findsOneWidget);
  });

  testWidgets('scan flow passes play area into calibration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PongPongApp());

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I Have Space'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Scan Left Boundary'));
    await tester.tap(find.text('Scan Left Boundary'));
    await tester.pumpAndSettle();
    expect(find.text('Scanning width...'), findsOneWidget);

    await tester.ensureVisible(find.text('Scan Right Boundary'));
    await tester.tap(find.text('Scan Right Boundary'));
    await tester.pumpAndSettle();
    expect(find.text('Scanning length...'), findsOneWidget);

    await tester.ensureVisible(find.text('Scan Forward Length'));
    await tester.tap(find.text('Scan Forward Length'));
    await tester.pumpAndSettle();
    expect(find.text('Play area ready'), findsWidgets);

    await tester.ensureVisible(find.text('Start Game Setup'));
    await tester.tap(find.text('Start Game Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Calibration'), findsWidgets);
    expect(find.text('2.5 m wide by 3.0 m long.'), findsOneWidget);
  });
}
