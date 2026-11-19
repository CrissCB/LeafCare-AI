import 'package:leafcare_ia/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_profile_model.dart';

class DashboardRepository {
  const DashboardRepository({required this.datasource});

  final DashboardDatasource datasource;

  static const List<String> _dailyTips = [
    'Comprueba la humedad introduciendo un dedo 2 cm en el sustrato antes de regar; el exceso de agua es la causa #1 de pudrición de raíces.',
    'Limpia el polvo de las hojas con un paño húmedo una vez al mes para mejorar la fotosíntesis y prevenir plagas.',
    'Gira tus macetas un cuarto de vuelta cada semana para que la planta crezca recta y reciba luz uniforme.',
    'Evita regar las hojas directamente por la noche para reducir el riesgo de hongos foliares.',
    'Usa agua a temperatura ambiente; el agua muy fría puede provocar choque térmico en raíces tropicales.',
  ];

  /// Ejecuta en paralelo las consultas de lectura para construir el estado del Dashboard.
  Future<DashboardSummaryModel> loadDashboardSummary() async {
    final results = await Future.wait([
      datasource.fetchUserProfile(),
      datasource.fetchTotalPlantsCount(),
      datasource.fetchUnreadAlertsCount(),
      datasource.fetchTopPlants(limit: 5),
      datasource.fetchTodayReminders(),
    ]);

    return DashboardSummaryModel(
      profile: results[0] as UserProfileModel,
      totalPlantsCount: results[1] as int,
      unreadAlertsCount: results[2] as int,
      topPlants: results[3] as List<UserPlantModel>,
      todayReminders: results[4] as List<CareReminderModel>,
      dailyTip: _tipOfTheDay(),
    );
  }

  String _tipOfTheDay() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays;
    return _dailyTips[dayOfYear % _dailyTips.length];
  }
}
