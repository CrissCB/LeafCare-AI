import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/alerts/data/models/alert_model.dart';

/// Consultas a la tabla `ia_alerts` en Supabase.
class AlertsDatasource {
  const AlertsDatasource({required this.supabaseClient});

  final AppSupabaseClient supabaseClient;

  SupabaseClient get _client => supabaseClient.client;

  /// Trae todas las alertas del usuario, de la más nueva a la más vieja.
  Future<List<AlertModel>> fetchAlerts() async {
    final userId = supabaseClient.currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('ia_alerts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data
        .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Marca una alerta como leída.
  Future<void> markAsRead(String alertId) async {
    await _client.from('ia_alerts').update({'is_read': true}).eq('id', alertId);
  }

  /// Marca todas las alertas indicadas como leídas en una sola consulta batch.
  Future<void> markAllAsRead(List<String> alertIds) async {
    if (alertIds.isEmpty) return;

    await _client
        .from('ia_alerts')
        .update({'is_read': true})
        .inFilter('id', alertIds);
  }

  /// Borra una alerta de PostgreSQL.
  Future<void> deleteAlert(String alertId) async {
    await _client.from('ia_alerts').delete().eq('id', alertId);
  }
}
