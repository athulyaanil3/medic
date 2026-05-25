import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:medic/providers/calorie_journal.dart';
import 'package:medic/screens/nutrition_screen.dart';
import 'package:medic/services/local_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    await Hive.openBox(LocalStore.medicinesBoxId);
    await Hive.openBox(LocalStore.foodBoxId);
    await Hive.openBox(LocalStore.settingsBoxId);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('NutritionScreen builds with food entries and functions', (WidgetTester tester) async {
    final journal = CalorieJournal();

    await tester.runAsync(() async {
      await journal.addEntry(label: 'Oatmeal', calories: 300, meal: 'Breakfast');
      await journal.addEntry(label: 'Salad', calories: 150, meal: 'Lunch');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<CalorieJournal>.value(
            value: journal,
            child: const NutritionScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Food log'), findsOneWidget);
    expect(find.text('Oatmeal'), findsNWidgets(2)); // One in Quick add, one in Today's log
    expect(find.text('Salad'), findsOneWidget);

    // Tap +1 glass water
    await tester.tap(find.text('+1 glass'));
    await tester.runAsync(() async {
      await tester.pump();
    });
    
    expect(journal.waterMlToday, 250);
  });
}
