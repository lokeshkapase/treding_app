import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:treding_app/app.dart';
import 'package:treding_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads home shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    await tester.pumpWidget(TradingApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Watchlists'), findsOneWidget);
    expect(find.text('Live Market'), findsNothing);
  });
}
