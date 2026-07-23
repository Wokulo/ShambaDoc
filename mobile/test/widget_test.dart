// Smoke test: the app builds and the splash screen renders.

import 'package:flutter_test/flutter_test.dart';
import 'package:shambadoc/main.dart';

void main() {
  testWidgets('App builds and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ShambaDocApp());

    // Splash shows the app name.
    expect(find.text('ShambaDoc'), findsWidgets);

    // Let the 2s splash timer fire so no pending timers remain.
    await tester.pump(const Duration(seconds: 3));
  });
}
