// This is a basic Flutter widget test for MediRemind app.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:medi_reminder/app.dart';
import 'package:medi_reminder/providers/medicine_provider.dart';
import 'package:medi_reminder/providers/log_provider.dart';

void main() {
  testWidgets('MediRemind app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MedicineProvider()),
          ChangeNotifierProvider(create: (_) => LogProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify the app launches
    await tester.pumpAndSettle();

    // Check if the home screen title is displayed
    expect(find.text('Today\'s Medicines'), findsOneWidget);
  });
}
