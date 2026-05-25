import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/food_entry.dart';
import '../services/local_store.dart';

class CalorieJournal extends ChangeNotifier {
  CalorieJournal() {
    _refresh();
  }

  final _uuid = const Uuid();
  late List<FoodEntry> _entries;

  List<FoodEntry> get entries => List.unmodifiable(_entries);
  int get todayTotal => LocalStore.todayCalorieTotal();

  static DateTime _weekStart(DateTime now) =>
      DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

  Future<void> addEntry({required String label, required int calories, String? meal}) async {
    await LocalStore.upsertFood(FoodEntry(
      id: _uuid.v4(),
      label: label.trim(),
      calories: calories.abs(),
      meal: meal,
    ));
    _refresh();
  }

  Future<void> deleteEntry(String id) async {
    await LocalStore.deleteFood(id);
    _refresh();
  }

  void _refresh() {
    _entries = LocalStore.readFoodSince(_weekStart(DateTime.now()));
    _entries.sort((a, b) => b.at.compareTo(a.at));
    notifyListeners();
  }

  Map<DateTime, int> last7DailyTotals() {
    final totals = <DateTime, int>{};
    final today = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      totals[day] = LocalStore.readFoodSince(day).fold(0, (s, e) {
        final d = DateTime(e.at.year, e.at.month, e.at.day);
        return d == day ? s + e.calories : s;
      });
    }
    return totals;
  }
}
