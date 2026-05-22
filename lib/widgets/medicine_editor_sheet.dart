import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../providers/medicine_catalog.dart';
import '../theme/app_theme.dart';

Future<void> showMedicineEditorSheet(
    BuildContext context, {
      Medicine? existing,
    }) async {
  final formKey = GlobalKey<FormState>();

  final nameCtr = TextEditingController(
    text: existing?.name ?? '',
  );

  final dosageCtr = TextEditingController(
    text: existing?.dosage ?? '',
  );

  final notesCtr = TextEditingController(
    text: existing?.notes ?? '',
  );

  final times = List<String>.from(
    existing?.reminderTimes ?? [],
  );

  final List<String> selectedDays =
  List<String>.from(
    existing?.repeatDays ?? [],
  );

  final allDays = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (picked != null) {
              final formatted =
              picked.format(context);

              if (!times.contains(formatted)) {
                setModalState(() {
                  times.add(formatted);
                });
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom:
              MediaQuery.of(context)
                  .viewInsets
                  .bottom,
            ),
            child: Container(
              padding:
              const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [

                      // TITLE
                      Text(
                        existing == null
                            ? "Add Medicine"
                            : "Edit Medicine",
                        style:
                        const TextStyle(
                          fontSize: 24,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          AppTheme
                              .deepTeal,
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      // NAME
                      TextFormField(
                        controller: nameCtr,
                        decoration:
                        const InputDecoration(
                          labelText:
                          "Medicine Name",
                          border:
                          OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null ||
                              v.trim()
                                  .isEmpty) {
                            return "Enter medicine name";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(
                          height: 16),

                      // DOSAGE
                      TextFormField(
                        controller:
                        dosageCtr,
                        decoration:
                        const InputDecoration(
                          labelText:
                          "Dosage",
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                          height: 16),

                      // NOTES
                      TextFormField(
                        controller:
                        notesCtr,
                        maxLines: 3,
                        decoration:
                        const InputDecoration(
                          labelText:
                          "Notes",
                          border:
                          OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      // TIMES
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          const Text(
                            "Reminder Times",
                            style: TextStyle(
                              fontWeight:
                              FontWeight
                                  .bold,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                            pickTime,
                            icon: const Icon(
                              Icons.access_time,
                            ),
                            label: const Text(
                              "Add Time",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t
                          in times)
                            Chip(
                              label: Text(t),
                              deleteIcon:
                              const Icon(
                                Icons.close,
                              ),
                              onDeleted: () {
                                setModalState(
                                        () {
                                      times.remove(
                                          t);
                                    });
                              },
                            ),
                        ],
                      ),

                      const SizedBox(
                          height: 24),

                      // REPEAT DAYS
                      const Text(
                        "Repeat Days",
                        style: TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final day
                          in allDays)
                            FilterChip(
                              label:
                              Text(day),
                              selected:
                              selectedDays
                                  .contains(
                                day,
                              ),
                              onSelected:
                                  (selected) {
                                setModalState(
                                        () {
                                      if (selected) {
                                        selectedDays
                                            .add(
                                          day,
                                        );
                                      } else {
                                        selectedDays
                                            .remove(
                                          day,
                                        );
                                      }
                                    });
                              },
                            ),
                        ],
                      ),

                      const SizedBox(
                          height: 28),

                      // SAVE BUTTON
                      SizedBox(
                        width:
                        double.infinity,
                        height: 54,
                        child:
                        ElevatedButton(
                          onPressed:
                              () async {

                            if (!formKey
                                .currentState!
                                .validate()) {
                              return;
                            }

                            if (times
                                .isEmpty) {
                              ScaffoldMessenger.of(
                                  context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Add at least one reminder time",
                                  ),
                                ),
                              );
                              return;
                            }

                            final catalog =
                            context.read<
                                MedicineCatalog>();

                            String? warning;

                            if (existing !=
                                null) {

                              warning =
                              await catalog
                                  .replaceMedicine(
                                existing,

                                name:
                                nameCtr
                                    .text,

                                dosage:
                                dosageCtr
                                    .text,

                                reminderTimes:
                                times,

                                repeatDays:
                                selectedDays,

                                notes:
                                notesCtr
                                    .text,
                              );
                            } else {

                              warning =
                              await catalog
                                  .addMedicine(
                                name:
                                nameCtr
                                    .text,

                                dosage:
                                dosageCtr
                                    .text,

                                reminderTimes:
                                times,

                                repeatDays:
                                selectedDays,

                                notes:
                                notesCtr
                                    .text,
                              );
                            }

                            if (context
                                .mounted) {

                              Navigator.pop(
                                  context);

                              ScaffoldMessenger.of(
                                  context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    warning ??
                                        "Medicine saved successfully",
                                  ),
                                ),
                              );
                            }
                          },

                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            AppTheme
                                .deepTeal,
                            foregroundColor:
                            Colors.white,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                16,
                              ),
                            ),
                          ),

                          child: Text(
                            existing == null
                                ? "Save Medicine"
                                : "Update Medicine",
                            style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}