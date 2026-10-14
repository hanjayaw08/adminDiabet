import 'package:flutter_test/flutter_test.dart';

import 'package:admindiabetes/main.dart';

void main() {
  testWidgets('shows admin login form as the first screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Masuk Admin'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Ingat saya'), findsOneWidget);
  });

  testWidgets('help button shows a support message',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Bantuan'));
    await tester.pump();

    expect(find.textContaining('Hubungi'), findsOneWidget);
  });
}
