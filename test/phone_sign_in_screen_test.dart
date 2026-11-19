import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invetory_system/phone_sign_in_screen.dart';

void main() {
  testWidgets('member sign-in matches phone OTP flow on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PhoneSignInScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in with your phone'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('SEND OTP'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Back to the site'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).first, '0770000000');
    await tester.tap(find.text('SEND OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Verification code'), findsOneWidget);
    expect(find.text('VERIFY OTP'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
