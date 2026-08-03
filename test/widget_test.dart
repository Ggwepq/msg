import 'package:flutter_test/flutter_test.dart';
import 'package:key_msg/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KeyMsgApp());
    expect(find.byType(KeyMsgApp), findsOneWidget);
  });
}
