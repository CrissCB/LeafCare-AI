import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/alerts/data/models/care_reminder_item_model.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_model.dart';
import 'package:leafcare_ia/features/alerts/presentation/bloc/alerts_bloc.dart';
import 'package:leafcare_ia/features/alerts/presentation/widgets/alerts_header.dart';
import 'package:leafcare_ia/features/alerts/presentation/widgets/reminder_day_section.dart';
import 'package:leafcare_ia/features/alerts/presentation/widgets/reminder_form_sheet.dart';
import 'package:leafcare_ia/features/alerts/presentation/widgets/ia_alerts_section.dart';
import 'package:leafcare_ia/features/alerts/presentation/widgets/ia_alert_detail_sheet.dart';
import 'package:leafcare_ia/features/alerts/presentation/widgets/ia_engine_banner.dart';

/// Pantalla principal del Centro de Alertas (`/alerts`).
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, this.initialTab = AlertsTab.reminders});

  final AlertsTab initialTab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AlertsBloc(initialTab: initialTab)..add(const LoadAlertsModule()),
      child: _AlertsView(requestedTab: initialTab),
    );
  }
}

class _AlertsView extends StatefulWidget {
  const _AlertsView({required this.requestedTab});

  final AlertsTab requestedTab;

  @override
  State<_AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<_AlertsView> {
  @override
  void didUpdateWidget(covariant _AlertsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestedTab != widget.requestedTab) {
      context.read<AlertsBloc>().add(AlertsTabChanged(widget.requestedTab));
    }
  }

  void _snack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _openIaAlertDetail(BuildContext context, IaAlertModel alert) {
    if (!alert.isRead && !alert.isDeleted) {
      context.read<AlertsBloc>().add(MarkIaAlertAsReadRequested(alert.id));
    }
    IaAlertDetailSheet.show(context, alert: alert);
  }

  Future<void> _openCreateReminder(
    BuildContext context,
    AlertsLoaded state,
  ) async {
    if (state.plantOptions.isEmpty) {
      _snack(
        context,
        'Primero escanea o registra una planta para crear recordatorios.',
      );
      return;
    }

    final bloc = context.read<AlertsBloc>();
    final result = await ReminderFormSheet.show(
      context,
      plants: state.plantOptions,
      groups: state.groupOptions,
    );

    if (!context.mounted || result == null || result.plantId == null) return;

    bloc.add(
      CreateReminderRequested(
        plantId: result.plantId!,
        treatmentAction: result.treatmentAction,
        iconName: result.iconName,
        scheduledTime: result.scheduledTime,
        isRecurrent: result.isRecurrent,
        recurrenceDays: result.recurrenceDays,
      ),
    );
  }

  Future<void> _openEditReminder(
    BuildContext context,
    AlertsLoaded state,
    CareReminderItemModel reminder,
  ) async {
    final bloc = context.read<AlertsBloc>();
    final result = await ReminderFormSheet.show(
      context,
      plants: state.plantOptions,
      groups: state.groupOptions,
      initialReminder: reminder,
    );

    if (!context.mounted || result == null) return;

    bloc.add(
      UpdateReminderRequested(
        reminderId: reminder.id,
        treatmentAction: result.treatmentAction,
        iconName: result.iconName,
        scheduledTime: result.scheduledTime,
        isRecurrent: result.isRecurrent,
        recurrenceDays: result.recurrenceDays,
      ),
    );
  }

  void _showReminderActionsMenu(
    BuildContext context,
    AlertsLoaded state,
    CareReminderItemModel reminder,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Editar recordatorio',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.anthracite,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _openEditReminder(context, state, reminder);
                },
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'Eliminar recordatorio',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.read<AlertsBloc>().add(
                    DeleteReminderRequested(reminder.id),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AlertsBloc, AlertsState>(
      listenWhen: (previous, current) =>
          current is AlertsLoaded &&
          current.notice != null &&
          previous != current,
      listener: (context, state) {
        if (state is AlertsLoaded && state.notice != null) {
          _snack(context, state.notice!, isError: state.noticeIsError);
        }
      },
      builder: (context, state) {
        if (state is AlertsInitial || state is AlertsLoading) {
          return const Scaffold(body: LoadingIndicator());
        }

        if (state is AlertsError) {
          return Scaffold(
            body: EmptyStateView(
              icon: Icons.wifi_off_rounded,
              title: 'No se pudo cargar',
              subtitle: state.message,
              onRetry: () =>
                  context.read<AlertsBloc>().add(const LoadAlertsModule()),
            ),
          );
        }

        final loaded = state as AlertsLoaded;
        final todayList = loaded.todayReminders;
        final tomorrowList = loaded.tomorrowReminders;
        final upcomingList = loaded.upcomingReminders;
        final hasAnyReminder =
            todayList.isNotEmpty ||
            tomorrowList.isNotEmpty ||
            upcomingList.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.pageBg,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final bloc = context.read<AlertsBloc>();
              bloc.add(const RefreshAlertsModule());
              await bloc.stream.firstWhere(
                (s) => s is AlertsLoaded || s is AlertsError,
              );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: AlertsHeader(
                    userName: loaded.userName,
                    avatarUrl: loaded.avatarUrl,
                    selectedTab: loaded.selectedTab,
                    todayRemindersCount: loaded.todayPendingCount,
                    unreadIaAlertsCount: loaded.unreadIaAlertsCount,
                    onTabChanged: (tab) =>
                        context.read<AlertsBloc>().add(AlertsTabChanged(tab)),
                  ),
                ),

                if (loaded.selectedTab == AlertsTab.reminders)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasAnyReminder)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.notifications_none_rounded,
                                      size: 36,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Sin recordatorios programados',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.anthracite,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Crea un recordatorio de riego, poda o fertilización para tus plantas.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.slate,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            ReminderDaySection(
                              sectionTitle: 'Hoy',
                              reminders: todayList,
                              busyReminderIds: loaded.busyReminderIds,
                              onTapReminder: (r) =>
                                  _showReminderActionsMenu(context, loaded, r),
                              onCompleteReminder: (r) => context
                                  .read<AlertsBloc>()
                                  .add(CompleteReminderRequested(r.id)),
                              onSnoozeReminder: (r) => context
                                  .read<AlertsBloc>()
                                  .add(SnoozeReminderRequested(r)),
                            ),
                            ReminderDaySection(
                              sectionTitle: 'Mañana',
                              reminders: tomorrowList,
                              busyReminderIds: loaded.busyReminderIds,
                              onTapReminder: (r) =>
                                  _showReminderActionsMenu(context, loaded, r),
                              onCompleteReminder: (r) => context
                                  .read<AlertsBloc>()
                                  .add(CompleteReminderRequested(r.id)),
                              onSnoozeReminder: (r) => context
                                  .read<AlertsBloc>()
                                  .add(SnoozeReminderRequested(r)),
                            ),
                            ReminderDaySection(
                              sectionTitle: 'Próximos',
                              reminders: upcomingList,
                              showWeekdayPrefix: true,
                              busyReminderIds: loaded.busyReminderIds,
                              onTapReminder: (r) =>
                                  _showReminderActionsMenu(context, loaded, r),
                              onCompleteReminder: (r) => context
                                  .read<AlertsBloc>()
                                  .add(CompleteReminderRequested(r.id)),
                              onSnoozeReminder: (r) => context
                                  .read<AlertsBloc>()
                                  .add(SnoozeReminderRequested(r)),
                            ),
                          ],

                          // Botón inferior "+ Añadir nuevo recordatorio"
                          _AddReminderButton(
                            onTap: () => _openCreateReminder(context, loaded),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IaEngineBanner(
                            monitoredPlantsCount: loaded.plantOptions.length,
                          ),
                          const SizedBox(height: 18),
                          IaAlertsSection(
                            unreadAlerts: loaded.unreadIaAlerts,
                            readAlerts: loaded.readIaAlerts,
                            deletedRecentAlerts: loaded.deletedRecentIaAlerts,
                            onTapAlert: (alert) =>
                                _openIaAlertDetail(context, alert),
                            onDeleteAlert: (alert) => context
                                .read<AlertsBloc>()
                                .add(DeleteIaAlertRequested(alert.id)),
                            onRestoreAlert: (alert) => context
                                .read<AlertsBloc>()
                                .add(RestoreIaAlertRequested(alert.id)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddReminderButton extends StatelessWidget {
  const _AddReminderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              color: AppColors.primaryDark,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              'Añadir nuevo recordatorio',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
