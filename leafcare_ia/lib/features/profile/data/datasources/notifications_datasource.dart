import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/notification_settings_model.dart';

/// Lee y guarda las preferencias de avisos del usuario.
class NotificationsDatasource {
  /// Trae las preferencias actuales desde la colección `users`.
  Future<NotificationSettingsModel> fetchSettings() async {
    final pb = await PocketBaseClient.getInstance();
    final current = pb.authStore.record;

    if (current == null) {
      throw Exception('No hay una sesión abierta.');
    }

    final record = await pb.collection('users').getOne(current.id);
    final data = record.data;

    return NotificationSettingsModel(
      pushEnabled: data['push_notifications_enabled'] == true,
      dailyEmail: data['daily_email_summary'] == true,
      weeklyEmail: data['weekly_email_summary'] == true,
    );
  }

  /// Guarda los cambios de las preferencias.
  Future<void> updateSettings(NotificationSettingsModel settings) async {
    final pb = await PocketBaseClient.getInstance();
    final current = pb.authStore.record;

    if (current == null) {
      throw Exception('No hay una sesión abierta.');
    }

    final updated = await pb.collection('users').update(
      current.id,
      body: {
        'push_notifications_enabled': settings.pushEnabled,
        'daily_email_summary': settings.dailyEmail,
        'weekly_email_summary': settings.weeklyEmail,
      },
    );

    // Mantenemos la sesión guardada al día.
    pb.authStore.save(pb.authStore.token, updated);
  }
}
