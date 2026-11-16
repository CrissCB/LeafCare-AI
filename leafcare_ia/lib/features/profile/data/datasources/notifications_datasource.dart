import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/profile/data/models/notification_settings_model.dart';

class NotificationsDatasource {
  const NotificationsDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  Future<NotificationSettingsModel> fetchSettings() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    final row = await _client
        .from('profiles')
        .select(
          'push_notifications_enabled, daily_email_summary, weekly_email_summary',
        )
        .eq('id', user.id)
        .maybeSingle();

    return NotificationSettingsModel.fromProfileRow(
      row: row,
      userEmail: user.email ?? '',
    );
  }

  Future<void> updateSettings(NotificationSettingsModel settings) async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) {
      throw Exception('No hay una sesión activa.');
    }

    await _client
        .from('profiles')
        .update(settings.toProfileUpdateJson())
        .eq('id', userId);
  }
}
