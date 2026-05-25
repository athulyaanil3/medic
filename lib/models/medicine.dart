import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {

  Medicine({

    required this.id,

    required this.name,

    required this.dosage,

    required this.reminderTimes,

    required this.repeatDays,

    // NEW
    required this.stock,

    // NEW
    required this.dailyDose,

    this.notes,

    DateTime? createdAt,

  }) : createdAt =
      createdAt ??
          DateTime.now();

  final String id;

  final String name;

  final String dosage;

  final List<String> reminderTimes;

  // REPEAT DAYS
  final List<String> repeatDays;

  // NEW
  final int stock;

  // NEW
  final int dailyDose;

  final String? notes;

  final DateTime createdAt;

  Map<String, dynamic> toMap() => {

    'id': id,

    'name': name,

    'dosage': dosage,

    'reminderTimes':
    reminderTimes,

    'repeatDays':
    repeatDays,

    // NEW
    'stock': stock,

    // NEW
    'dailyDose':
    dailyDose,

    'notes': notes,

    'createdAt':
    createdAt
        .toIso8601String(),
  };

  factory Medicine.fromMap(
      Map<dynamic, dynamic> raw) {

    // REMINDER TIMES

    final rtDyn =
    raw['reminderTimes'];

    final reminderTimes =
    <String>[];

    if (rtDyn is List) {

      reminderTimes.addAll(

        rtDyn.map(
              (e) => e.toString(),
        ),
      );

    } else if (rtDyn != null) {

      reminderTimes.add(
        rtDyn.toString(),
      );
    }

    // REPEAT DAYS

    final rdDyn =
    raw['repeatDays'];

    final repeatDays =
    <String>[];

    if (rdDyn is List) {

      repeatDays.addAll(

        rdDyn.map(
              (e) => e.toString(),
        ),
      );

    } else if (rdDyn != null) {

      repeatDays.add(
        rdDyn.toString(),
      );
    }

    // CREATED TIME

    final createdParsed =
    raw['createdAt'];

    DateTime created =
    DateTime.now();

    if (createdParsed
    is DateTime) {

      created =
          createdParsed;

    } else if (createdParsed
    is Timestamp) {

      created =
          createdParsed.toDate();

    } else if (createdParsed
        !=
        null) {

      created =
          DateTime.tryParse(

            createdParsed
                .toString(),
          ) ??
              DateTime.now();
    }

    return Medicine(

      id:
      raw['id']
          .toString(),

      name:
      raw['name']
          .toString(),

      dosage:
      raw['dosage']
          .toString(),

      reminderTimes:
      reminderTimes,

      repeatDays:
      repeatDays,

      // NEW
      stock:
      int.tryParse(
        raw['stock']
            ?.toString() ??
            '0',
      ) ??
          0,

      // NEW
      dailyDose:
      int.tryParse(
        raw['dailyDose']
            ?.toString() ??
            '0',
      ) ??
          0,

      notes:
      raw['notes']
          ?.toString(),

      createdAt:
      created,
    );
  }
}