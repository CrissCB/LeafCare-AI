import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_profile_model.dart';

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.profile,
    required this.totalPlantsCount,
    required this.unreadAlertsCount,
    required this.topPlants,
    required this.todayReminders,
    required this.dailyTip,
  });

  final UserProfileModel profile;
  final int totalPlantsCount;
  final int unreadAlertsCount;
  final List<UserPlantModel> topPlants;
  final List<CareReminderModel> todayReminders;
  final String dailyTip;

  bool get hasUnreadAlerts => unreadAlertsCount > 0;

  DashboardSummaryModel copyWith({
    UserProfileModel? profile,
    int? totalPlantsCount,
    int? unreadAlertsCount,
    List<UserPlantModel>? topPlants,
    List<CareReminderModel>? todayReminders,
    String? dailyTip,
  }) {
    return DashboardSummaryModel(
      profile: profile ?? this.profile,
      totalPlantsCount: totalPlantsCount ?? this.totalPlantsCount,
      unreadAlertsCount: unreadAlertsCount ?? this.unreadAlertsCount,
      topPlants: topPlants ?? this.topPlants,
      todayReminders: todayReminders ?? this.todayReminders,
      dailyTip: dailyTip ?? this.dailyTip,
    );
  }
}
