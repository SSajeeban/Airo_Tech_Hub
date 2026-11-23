



import 'package:flutter_test/flutter_test.dart';
import 'package:invetory_system/main.dart';

void main() {
  testWidgets('Airo Tech Hub app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AiroApp());

    expect(find.byType(AiroApp), findsOneWidget);
  });
}

