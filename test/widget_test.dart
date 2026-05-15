import 'package:flutter_test/flutter_test.dart';

import 'package:phonepong/app.dart';

void main() {
  testWidgets('Home screen renders START GAME button', (tester) async {
    await tester.pumpWidget(const PhonePongApp());
    await tester.pumpAndSettle();
    expect(find.text('START GAME'), findsOneWidget);
    expect(find.text('PHONE'), findsOneWidget);
    expect(find.text('PONG'), findsOneWidget);
  });
}
