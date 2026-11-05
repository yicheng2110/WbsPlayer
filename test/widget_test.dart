import 'package:flutter_test/flutter_test.dart';
import 'package:wbs_player/main.dart';

void main() {
  testWidgets('renders the Wbs Player app', (WidgetTester tester) async {
    await tester.pumpWidget(const WbsPlayerApp());

    expect(find.text('Wbs Player'), findsOneWidget);
  });
}
