import 'package:flutter_test/flutter_test.dart';
import 'package:market_ai/main.dart';

void main() {
  testWidgets('MarketAI login screen loads', (tester) async {
    await tester.pumpWidget(const MarketAiApp());
    expect(find.text('Enter your mobile number'), findsOneWidget);
  });
}
