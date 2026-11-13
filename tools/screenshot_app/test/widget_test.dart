import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_app/main.dart';

void main() {
  testWidgets('ScreenshotHelperApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ScreenshotHelperApp());
    expect(find.textContaining('Screenshot'), findsWidgets);
  });
}
