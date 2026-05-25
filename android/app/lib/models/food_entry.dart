class FoodEntry {
  FoodEntry({
    required this.id,
    required this.label,
    required this.calories,
    DateTime? at,
    this.meal,
  }) : at = at ?? DateTime.now();

  final String id;
  final String label;
  final int calories;
  final DateTime at;
  final String? meal;

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'calories': calories,
        'at': at.toIso8601String(),
        'meal': meal,
      };

  factory FoodEntry.fromMap(Map<dynamic, dynamic> raw) => FoodEntry(
        id: raw['id'].toString(),
        label: raw['label'].toString(),
        calories: raw['calories'] is int
            ? raw['calories'] as int
            : int.tryParse(raw['calories'].toString()) ?? 0,
        at: raw['at'] != null
            ? DateTime.tryParse(raw['at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        meal: raw['meal'] as String?,
      );
}
