import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/notification_settings_model.dart';

/// Lee y guarda las preferencias de avisos del usuario en Supabase.
class NotificationsDatasource {
  const NotificationsDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Trae las preferencias actuales desde la tabla `profiles`.
  Future<NotificationSettingsModel> fetchSettings() async {
    final userId = supabaseClient.currentUserId;

    if (userId == null) {
      throw Exception('No hay una sesión abierta.');
    }

    final response = await _client
        .from('profiles')
        .select(
          'push_notifications_enabled, daily_email_summary, weekly_email_summary',
        )
        .eq('id', userId)
        .maybeSingle();

    return NotificationSettingsModel(
      pushEnabled: response?['push_notifications_enabled'] == true,
      dailyEmail: response?['daily_email_summary'] == true,
      weeklyEmail: response?['weekly_email_summary'] == true,
    );
  }

  /// Guarda los cambios de las preferencias en la tabla `profiles`.
  Future<void> updateSettings(NotificationSettingsModel settings) async {
    final userId = supabaseClient.currentUserId;

    if (userId == null) {
      throw Exception('No hay una sesión abierta.');
    }

    await _client
        .from('profiles')
        .update({
          'push_notifications_enabled': settings.pushEnabled,
          'daily_email_summary': settings.dailyEmail,
          'weekly_email_summary': settings.weeklyEmail,
        })
        .eq('id', userId);
  }
}
