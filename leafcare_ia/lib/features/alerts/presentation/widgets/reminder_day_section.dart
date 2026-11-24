import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/alerts/data/models/care_reminder_item_model.dart';
import 'package:leafcare_ia/features/alerts/presentation/widgets/reminder_card.dart';

/// Renderiza un bloque de recordatorios por fecha (HOY, MAÑANA o PRÓXIMOS).
class ReminderDaySection extends StatelessWidget {
  const ReminderDaySection({
    super.key,
    required this.sectionTitle,
    required this.reminders,
    this.showWeekdayPrefix = false,
    required this.busyReminderIds,
    required this.onTapReminder,
    required this.onCompleteReminder,
    required this.onSnoozeReminder,
  });

  final String sectionTitle;
  final List<CareReminderItemModel> reminders;
  final bool showWeekdayPrefix;
  final Set<String> busyReminderIds;
  final ValueChanged<CareReminderItemModel> onTapReminder;
  final ValueChanged<CareReminderItemModel> onCompleteReminder;
  final ValueChanged<CareReminderItemModel> onSnoozeReminder;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) return const SizedBox.shrink();

    final pendingCount = reminders.where((r) => !r.isCompleted).length;
    final badgeText = pendingCount == 1
        ? '1 pendiente'
        : '$pendingCount pendientes';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                sectionTitle.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final reminder in reminders)
            ReminderCard(
              reminder: reminder,
              showWeekdayPrefix: showWeekdayPrefix,
              isBusy: busyReminderIds.contains(reminder.id),
              onTapCard: () => onTapReminder(reminder),
              onToggleComplete: () => onCompleteReminder(reminder),
              onSnoozeOneHour: () => onSnoozeReminder(reminder),
            ),
        ],
      ),
    );
  }
}
