import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/local_store.dart';

import '../models/food_entry.dart';
import '../providers/calorie_journal.dart';
import '../theme/app_theme.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  static const _meals = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  static const _quickFoods = <({String name, int kcal, String meal})>[
    (name: 'Oatmeal', kcal: 280, meal: 'Breakfast'),
    (name: 'Eggs & toast', kcal: 350, meal: 'Breakfast'),
    (name: 'Rice & curry', kcal: 520, meal: 'Lunch'),
    (name: 'Sandwich', kcal: 400, meal: 'Lunch'),
    (name: 'Chicken rice', kcal: 480, meal: 'Dinner'),
    (name: 'Fruit', kcal: 100, meal: 'Snack'),
    (name: 'Tea & snacks', kcal: 150, meal: 'Snack'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        if (!Hive.isBoxOpen(LocalStore.foodBoxId) ||
            !Hive.isBoxOpen(LocalStore.settingsBoxId)) {
          await LocalStore.init();
        }
        if (mounted) context.read<CalorieJournal>().reload();
      } catch (e) {
        debugPrint('NutritionScreen init: $e');
      }
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickGoal(CalorieJournal journal) async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Daily calorie goal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            for (final g in [1500, 1800, 2000, 2200, 2500, 3000])
              ListTile(
                title: Text('$g kcal'),
                trailing: journal.calorieGoal == g ? const Icon(Icons.check, color: AppTheme.deepTeal) : null,
                onTap: () => Navigator.pop(ctx, g),
              ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Custom amount…'),
              onTap: () async {
                Navigator.pop(ctx);
                final ctrl = TextEditingController(text: '${journal.calorieGoal}');
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Custom goal'),
                    content: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'kcal per day'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Save')),
                    ],
                  ),
                );
                final v = int.tryParse(ctrl.text.trim());
                ctrl.dispose();
                if (ok == true && v != null && mounted) {
                  await journal.setCalorieGoal(v);
                  _snack('Goal set to $v kcal');
                }
              },
            ),
          ],
        ),
      ),
    );
    if (choice != null && mounted) {
      await journal.setCalorieGoal(choice);
      _snack('Goal set to $choice kcal');
    }
  }

  Future<void> _logMeal(CalorieJournal journal, {String? meal}) async {
    final result = await showDialog<({String label, int kcal, String meal})>(
      context: context,
      builder: (ctx) => _LogMealDialog(initialMeal: meal ?? _meals.first),
    );
    if (result == null || !mounted) return;
    try {
      await journal.addEntry(
        label: result.label,
        calories: result.kcal,
        meal: result.meal,
      );
      _snack('Logged ${result.label} (${result.kcal} kcal)');
    } catch (e) {
      _snack('Could not save meal. Try again.');
    }
  }

  Future<void> _quickAdd(CalorieJournal journal, String name, int kcal, String meal) async {
    try {
      await journal.addEntry(label: name, calories: kcal, meal: meal);
      _snack('Added $name');
    } catch (_) {
      _snack('Could not save. Try again.');
    }
  }

  Future<void> _repeatLast(CalorieJournal journal) async {
    if (journal.lastMeal == null) {
      _snack('No previous meal to repeat');
      return;
    }
    await journal.repeatLastMeal();
    _snack('Repeated ${journal.lastMeal!.label}');
  }

  Future<void> _deleteMeal(CalorieJournal journal, FoodEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text('Remove "${entry.label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await journal.deleteEntry(entry.id);
      _snack('Meal removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildContent(context);
    } catch (e, st) {
      debugPrint('NutritionScreen build error: $e\n$st');
      return MediBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.accentCoral),
                const SizedBox(height: 16),
                const Text(
                  'Food log could not load',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.inkMuted)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    context.read<CalorieJournal>().reload();
                    setState(() {});
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    final j = context.watch<CalorieJournal>();
    final today = j.todayEntries;
    final byMeal = j.todayByMeal;
    final week = j.last7DailyTotals();
    final days = week.keys.toList()..sort();
    final maxKcal = week.values.fold<int>(1, (m, v) => v > m ? v : m);

    return MediBackground(
      pad: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
                      title: 'Food log',
                      subtitle: 'Saved on this phone · pull down to refresh',
                      trailing: IconButton(
                        tooltip: 'Calorie goal',
                        onPressed: () => _pickGoal(j),
                        icon: const Icon(Icons.flag_rounded, color: AppTheme.deepTeal),
                      ),
                    ),

                    // Today summary
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.coralGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Today', style: TextStyle(color: AppTheme.inkMuted, fontSize: 13)),
                                    Text(
                                      '${j.todayTotal} / ${j.calorieGoal} kcal',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                j.isOverGoal ? 'Over goal' : '${j.caloriesRemaining} left',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: j.isOverGoal ? AppTheme.accentCoral : AppTheme.deepTeal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: j.todayProgress.clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: AppTheme.mintGlow,
                              color: j.isOverGoal ? AppTheme.accentCoral : AppTheme.deepTeal,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _logMeal(j),
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: const Text('Log meal'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: j.lastMeal == null ? null : () => _repeatLast(j),
                                child: const Icon(Icons.replay_rounded, size: 22),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Water
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop_rounded, color: Color(0xFF3B9AE8)),
                              const SizedBox(width: 10),
                              Text(
                                'Water · ${j.waterLitersToday.toStringAsFixed(1)} / ${j.waterGoalLiters.toStringAsFixed(1)} L',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (j.waterMlToday / j.waterGoalMl).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE3F4FC),
                              color: const Color(0xFF3B9AE8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: j.waterGlassesToday > 0
                                      ? () async {
                                          await j.removeWater();
                                          _snack('Water updated');
                                        }
                                      : null,
                                  child: const Text('− glass'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: () async {
                                    await j.addWater();
                                    _snack('+1 glass (250 ml)');
                                  },
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3B9AE8)),
                                  child: const Text('+1 glass'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            const SizedBox(height: 18),

            const Text('Today by meal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _MealSlotCard(meal: _meals[0], kcal: byMeal[_meals[0]] ?? 0, onTap: () => _logMeal(j, meal: _meals[0]))),
                const SizedBox(width: 8),
                Expanded(child: _MealSlotCard(meal: _meals[1], kcal: byMeal[_meals[1]] ?? 0, onTap: () => _logMeal(j, meal: _meals[1]))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _MealSlotCard(meal: _meals[2], kcal: byMeal[_meals[2]] ?? 0, onTap: () => _logMeal(j, meal: _meals[2]))),
                const SizedBox(width: 8),
                Expanded(child: _MealSlotCard(meal: _meals[3], kcal: byMeal[_meals[3]] ?? 0, onTap: () => _logMeal(j, meal: _meals[3]))),
              ],
            ),
            const SizedBox(height: 18),

                    // Quick add
                    const Text('Quick add', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 8),
                    ..._quickFoods.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppTheme.cardWhite.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.mintGlow,
                              child: Text('${f.kcal}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.deepTeal)),
                            ),
                            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${f.meal} · ${f.kcal} kcal'),
                            trailing: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.deepTeal),
                            onTap: () => _quickAdd(j, f.name, f.kcal, f.meal),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Week chart (simple bars — always works)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Last 7 days', style: TextStyle(fontWeight: FontWeight.w700)),
                              Text('avg ${j.weekAverage} kcal', style: const TextStyle(color: AppTheme.inkMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 130,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final day in days)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${week[day]}',
                                            style: const TextStyle(fontSize: 9, color: AppTheme.inkMuted),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: maxKcal == 0 ? 4 : (week[day]! / maxKcal) * 70 + 4,
                                            decoration: BoxDecoration(
                                              color: DateUtils.isSameDay(day, DateTime.now())
                                                  ? AppTheme.deepTeal
                                                  : AppTheme.tealLight.withValues(alpha: 0.6),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            DateFormat('E').format(day),
                                            style: const TextStyle(fontSize: 10, color: AppTheme.inkMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Today's log
                    Text(
                      today.isEmpty ? 'No meals today' : "Today's log (${today.length})",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    if (today.isEmpty)
                      const GlassCard(
                        child: Text(
                          'Tap Log meal, a meal slot above, or Quick add to start tracking.',
                          style: TextStyle(color: AppTheme.inkMuted, height: 1.45),
                        ),
                      )
            else
              for (final e in today)
                _EntryTile(entry: e, onDelete: () => _deleteMeal(j, e)),
          ],
        ),
      ),
    );
  }
}

class _MealSlotCard extends StatelessWidget {
  const _MealSlotCard({required this.meal, required this.kcal, required this.onTap});

  final String meal;
  final int kcal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(meal, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$kcal kcal', style: const TextStyle(color: AppTheme.deepTeal, fontWeight: FontWeight.w800)),
                  const Icon(Icons.add_rounded, size: 20, color: AppTheme.deepTeal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete});

  final FoodEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '${entry.meal ?? 'Meal'} · ${DateFormat('h:mm a').format(entry.at)}',
                    style: const TextStyle(color: AppTheme.inkMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text('${entry.calories}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.deepTeal)),
            IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

/// Reliable dialog — returns data via Navigator.pop (no controller lifecycle bugs).
class _LogMealDialog extends StatefulWidget {
  const _LogMealDialog({required this.initialMeal});

  final String initialMeal;

  @override
  State<_LogMealDialog> createState() => _LogMealDialogState();
}

class _LogMealDialogState extends State<_LogMealDialog> {
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  late String _meal;
  static const _kcalPresets = [100, 200, 300, 400, 500, 600, 800];

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final kcal = int.tryParse(_kcalCtrl.text.trim());
    if (name.isEmpty || kcal == null || kcal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter food name and calories')),
      );
      return;
    }
    Navigator.pop(context, (label: name, kcal: kcal, meal: _meal));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log meal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Food name',
                hintText: 'e.g. Rice and chicken',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kcalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calories (kcal)'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in _kcalPresets)
                  ActionChip(
                    label: Text('$k'),
                    onPressed: () => setState(() => _kcalCtrl.text = '$k'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownMenu<String>(
              initialSelection: _meal,
              label: const Text('Meal'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'Breakfast', label: 'Breakfast'),
                DropdownMenuEntry(value: 'Lunch', label: 'Lunch'),
                DropdownMenuEntry(value: 'Dinner', label: 'Dinner'),
                DropdownMenuEntry(value: 'Snack', label: 'Snack'),
              ],
              onSelected: (v) {
                if (v != null) setState(() => _meal = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
