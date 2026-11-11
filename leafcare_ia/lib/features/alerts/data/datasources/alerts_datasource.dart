import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/alerts/data/models/alert_model.dart';

/// Consultas a la colección `ia_alerts` de PocketBase.
class AlertsDatasource {
  /// Trae todas las alertas del usuario, de la más nueva a la más vieja.
  Future<List<AlertModel>> fetchAlerts() async {
    final pb = await PocketBaseClient.getInstance();
    final userId = pb.authStore.record?.id;
    if (userId == null) return [];

    final records = await pb.collection('ia_alerts').getFullList(
      filter: 'user_id = "$userId"',
      sort: '-created',
    );

    return records.map(AlertModel.fromRecord).toList();
  }

  /// Marca una alerta como leída.
  Future<void> markAsRead(String alertId) async {
    final pb = await PocketBaseClient.getInstance();

    await pb.collection('ia_alerts').update(
      alertId,
      body: {'is_read': true},
    );
  }

  /// Marca todas las alertas indicadas como leídas.
  Future<void> markAllAsRead(List<String> alertIds) async {
    for (final id in alertIds) {
      await markAsRead(id);
    }
  }

  /// Borra una alerta.
  Future<void> deleteAlert(String alertId) async {
    final pb = await PocketBaseClient.getInstance();
    await pb.collection('ia_alerts').delete(alertId);
  }
}
