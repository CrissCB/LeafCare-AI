import 'package:leafcare_ia/features/alerts/data/datasources/alerts_datasource.dart';
import 'package:leafcare_ia/features/alerts/data/models/care_reminder_item_model.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_scan_detail_model.dart';
import 'package:leafcare_ia/features/alerts/data/models/ia_alert_model.dart';

typedef PlantSelectOption = ({
  String id,
  String name,
  String? imageUrl,
  String? groupId,
});

typedef GroupFilterOption = ({String id, String name, String iconName});

class AlertsRepository {
  const AlertsRepository({required this.datasource});

  final AlertsDatasource datasource;

  Future<
    ({
      String userName,
      String? avatarUrl,
      List<IaAlertModel> iaAlerts,
      List<CareReminderItemModel> reminders,
      List<PlantSelectOption> plantOptions,
      List<GroupFilterOption> groupOptions,
    })
  >
  loadAlertsModuleData() async {
    final results = await Future.wait([
      datasource.fetchUserHeaderInfo(),
      datasource.fetchIaAlerts(),
      datasource.fetchCareReminders(),
      datasource.fetchUserPlantOptions(),
      datasource.fetchUserGroupOptions(),
    ]);

    final headerInfo = results[0] as ({String userName, String? avatarUrl});

    return (
      userName: headerInfo.userName,
      avatarUrl: headerInfo.avatarUrl,
      iaAlerts: results[1] as List<IaAlertModel>,
      reminders: results[2] as List<CareReminderItemModel>,
      plantOptions: results[3] as List<PlantSelectOption>,
      groupOptions: results[4] as List<GroupFilterOption>,
    );
  }

  Future<IaAlertScanDetailModel> fetchAlertScanDetail(IaAlertModel alert) =>
      datasource.fetchAlertScanDetail(alert);

  Future<void> markIaAlertAsRead(String alertId) =>
      datasource.markIaAlertAsRead(alertId);

  Future<void> deleteIaAlert(String alertId) =>
      datasource.deleteIaAlert(alertId);

  Future<void> restoreIaAlert(String alertId) =>
      datasource.restoreIaAlert(alertId);

  Future<CareReminderItemModel> createReminder({
    required String plantId,
    required String treatmentAction,
    required String iconName,
    required DateTime scheduledTime,
    required bool isRecurrent,
    int? recurrenceDays,
  }) {
    return datasource.createReminder(
      plantId: plantId,
      treatmentAction: treatmentAction,
      iconName: iconName,
      scheduledTime: scheduledTime,
      isRecurrent: isRecurrent,
      recurrenceDays: recurrenceDays,
    );
  }

  Future<void> updateReminder({
    required String reminderId,
    required String treatmentAction,
    required String iconName,
    required DateTime scheduledTime,
    required bool isRecurrent,
    int? recurrenceDays,
  }) {
    return datasource.updateReminder(
      reminderId: reminderId,
      treatmentAction: treatmentAction,
      iconName: iconName,
      scheduledTime: scheduledTime,
      isRecurrent: isRecurrent,
      recurrenceDays: recurrenceDays,
    );
  }

  Future<void> completeReminder(String reminderId) =>
      datasource.completeReminder(reminderId);

  Future<void> snoozeReminderByOneHour(CareReminderItemModel reminder) =>
      datasource.snoozeReminderByOneHour(reminder);

  Future<void> deleteReminder(String reminderId) =>
      datasource.deleteReminder(reminderId);
}
