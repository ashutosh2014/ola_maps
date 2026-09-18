import 'package:flutter_test/flutter_test.dart';
import 'package:ola_map_view_flutter_example/main.dart';

void main() {
  testWidgets('Shows example app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Ola Maps Example'), findsOneWidget);
    expect(find.text('Places'), findsOneWidget);
    expect(find.text('Search a location…'), findsOneWidget);
    expect(find.text('Coverage'), findsOneWidget);
    expect(find.text('Circle'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });
}
