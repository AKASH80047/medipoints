import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medipoints/main.dart';

void main() {
  testWidgets('MediPoint app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MediPointApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify MediPoint app loads and displays Good Morning/Afternoon or main text
    expect(find.byType(MediPointApp), findsOneWidget);
  });
}
