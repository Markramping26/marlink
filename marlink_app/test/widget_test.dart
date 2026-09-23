import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marlink_app/main.dart';

void main() {
  testWidgets('MarLink App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MarLinkApp(),
      ),
    );
    expect(find.byType(MarLinkApp), findsOneWidget);
  });
}
