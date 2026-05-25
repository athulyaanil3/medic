import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medicine_catalog.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medi_background.dart';
import '../widgets/medicine_editor_sheet.dart';
import '../widgets/ui_kit.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() =>
      _MedicinesScreenState();
}

class _MedicinesScreenState
    extends State<MedicinesScreen> {

  ReminderPermissionStatus?
  _permissionStatus;

  @override
  void initState() {

    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      _refreshReminders();
    });
  }

  Future<void> _refreshReminders()
  async {

    final catalog =
    context.read<MedicineCatalog>();

    catalog.reload();

    await rescheduleAllMedicineNotifications(
      catalog.items,
    );

    final status =
    await getReminderPermissionStatus();

    if (mounted) {

      setState(() {
        _permissionStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final items =
        context.watch<MedicineCatalog>().items;

    final catalog =
    context.read<MedicineCatalog>();

    return Scaffold(

      backgroundColor:
      Colors.transparent,

      floatingActionButton:
      FloatingActionButton.extended(

        onPressed: () =>
            showMedicineEditorSheet(
              context,
            ),

        elevation: 6,

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: Text(

          items.isEmpty
              ? 'Add medicine'
              : 'Add another',
        ),
      ),

      body: MediBackground(

        child: CustomScrollView(

          physics:
          const BouncingScrollPhysics(),

          slivers: [

            // HEADER
            SliverToBoxAdapter(

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,

                children: [

                  PageHeader(

                    title:
                    'Medicine reminders',

                    subtitle: items.isEmpty

                        ? 'Add as many medicines as you need — no limit.'

                        : '${items.length} medicine${items.length == 1 ? '' : 's'} saved',
                  ),

                  // PERMISSION WARNING
                  if (_permissionStatus !=
                      null &&
                      !_permissionStatus!
                          .ready) ...[

                    Padding(

                      padding:
                      const EdgeInsets
                          .only(
                        bottom: 12,
                      ),

                      child: GlassCard(

                        padding:
                        const EdgeInsets
                            .all(14),

                        child: Column(

                          crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,

                          children: [

                            const Text(

                              'Reminders are off',

                              style: TextStyle(
                                fontWeight:
                                FontWeight
                                    .w800,

                                color: AppTheme
                                    .accentCoral,
                              ),
                            ),

                            const SizedBox(
                                height: 6),

                            Text(

                              _permissionStatus
                                  ?.setupHint ??
                                  'Enable notifications',

                              style:
                              const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),

                            const SizedBox(
                                height: 10),

                            FilledButton.icon(

                              onPressed:
                              openReminderPermissionSettings,

                              icon:
                              const Icon(
                                Icons
                                    .settings_rounded,
                                size: 18,
                              ),

                              label:
                              const Text(
                                'Open settings',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // EMPTY STATE
            if (items.isEmpty)

              SliverFillRemaining(

                hasScrollBody: false,

                child: GlassCard(

                  child: Column(

                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                    children: [

                      Icon(

                        Icons
                            .medication_outlined,

                        size: 64,

                        color: AppTheme
                            .deepTeal
                            .withValues(
                          alpha: 0.45,
                        ),
                      ),

                      const SizedBox(
                          height: 16),

                      const Text(

                        'No medicines yet',

                        style: TextStyle(
                          fontWeight:
                          FontWeight
                              .w700,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      const Text(

                        'Add your first medicine to start reminders.',

                        textAlign:
                        TextAlign.center,
                      ),

                      const SizedBox(
                          height: 20),

                      FilledButton.icon(

                        onPressed: () =>
                            showMedicineEditorSheet(
                              context,
                            ),

                        icon: const Icon(
                          Icons.add_rounded,
                        ),

                        label: const Text(
                          'Add medicine',
                        ),
                      ),
                    ],
                  ),
                ),
              )

            // MEDICINE LIST
            else

              SliverList.separated(

                itemCount: items.length,

                separatorBuilder:
                    (_, __) =>
                const SizedBox(
                  height: 12,
                ),

                itemBuilder: (_, i) {

                  final med = items[i];

                  return GlassCard(

                    padding:
                    const EdgeInsets
                        .all(18),

                    child: Column(

                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [

                        Row(

                          children: [

                            const IconBadge(

                              icon: Icons
                                  .medication_liquid_rounded,

                              size: 44,
                            ),

                            const SizedBox(
                                width: 14),

                            Expanded(

                              child: Text(

                                med.name,

                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  fontSize:
                                  18,
                                ),
                              ),
                            ),

                            // EDIT BUTTON
                            IconButton(

                              icon:
                              const Icon(
                                Icons
                                    .edit_rounded,

                                color:
                                AppTheme
                                    .inkMuted,

                                size: 20,
                              ),

                              onPressed: () {

                                showMedicineEditorSheet(

                                  context,

                                  existing:
                                  med,
                                );
                              },
                            ),

                            // DELETE BUTTON
                            IconButton(

                              icon:
                              const Icon(
                                Icons
                                    .delete_rounded,

                                color: Colors
                                    .redAccent,

                                size: 22,
                              ),

                              onPressed:
                                  () async {

                                // DELETE
                                await catalog
                                    .removeMedicine(
                                  med,
                                );

                                // CANCEL NOTIFICATION
                                await cancelMedicineNotifications(
                                  med,
                                );

                                if (context
                                    .mounted) {

                                  ScaffoldMessenger
                                      .of(
                                      context)
                                      .showSnackBar(

                                    SnackBar(

                                      content:
                                      Text(
                                        '${med.name} deleted',
                                      ),

                                      behavior:
                                      SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),

                        // DOSAGE
                        if (med.dosage
                            .isNotEmpty) ...[

                          const SizedBox(
                              height: 10),

                          Text(

                            med.dosage,

                            style:
                            const TextStyle(
                              color: AppTheme
                                  .inkMuted,
                            ),
                          ),
                        ],

                        const SizedBox(
                            height: 12),

                        // TIMES
                        Wrap(

                          spacing: 8,
                          runSpacing: 8,

                          children: [

                            for (final t
                            in med
                                .reminderTimes)

                              MediChip(

                                label: t,

                                icon: Icons
                                    .schedule_rounded,
                              ),
                          ],
                        ),

                        const SizedBox(
                            height: 14),

                        // REPEAT DAYS
                        Row(

                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            const Icon(

                              Icons
                                  .calendar_today_rounded,

                              size: 18,

                              color:
                              AppTheme
                                  .deepTeal,
                            ),

                            const SizedBox(
                                width: 8),

                            Expanded(

                              child: Text(

                                med.repeatDays
                                    .isEmpty

                                    ? 'Daily'

                                    : med
                                    .repeatDays
                                    .join(
                                    ', '),

                                style:
                                const TextStyle(

                                  fontSize:
                                  14,

                                  color:
                                  AppTheme
                                      .inkMuted,

                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ADD MORE BUTTON
            if (items.isNotEmpty)

              SliverToBoxAdapter(

                child: Padding(

                  padding:
                  const EdgeInsets.only(
                    top: 8,
                    bottom: 8,
                  ),

                  child:
                  OutlinedButton.icon(

                    onPressed: () =>
                        showMedicineEditorSheet(
                          context,
                        ),

                    icon: const Icon(
                      Icons.add_rounded,
                    ),

                    label: const Text(
                      'Add another medicine',
                    ),

                    style:
                    OutlinedButton
                        .styleFrom(

                      minimumSize:
                      const Size
                          .fromHeight(
                        52,
                      ),

                      side: BorderSide(
                        color: AppTheme
                            .deepTeal
                            .withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(

              child: SizedBox(
                height: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}