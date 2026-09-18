import 'package:flutter_test/flutter_test.dart';
import 'package:ola_map_view_flutter_example/main.dart';

void main() {
  testWidgets('Shows example app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Ola Maps Example'), findsOneWidget);
  });
}
