import 'package:flutter_test/flutter_test.dart';

import 'package:pong_pong/app/app.dart';

void main() {
  testWidgets('start flow reaches scan setup', (WidgetTester tester) async {
    await tester.pumpWidget(const PongPongApp());

    expect(find.text('Motion table tennis for your phone.'), findsOneWidget);

    await tester.ensureVisible(find.text('Start Game'));
    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(find.text('Safety first'), findsOneWidget);

    await tester.tap(find.text('Space is clear'));
    await tester.pumpAndSettle();

    expect(find.text('Scan your play area'), findsOneWidget);
  });
}
