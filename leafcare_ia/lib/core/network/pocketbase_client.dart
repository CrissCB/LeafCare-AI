import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leafcare_ia/core/constants/api_constants.dart';

class PocketBaseClient {
  static PocketBase? _instance;

  static Future<PocketBase> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();

      // AuthStore
      final store = AsyncAuthStore(
        save: (String data) async => prefs.setString('pb_auth', data),
        initial: prefs.getString('pb_auth'),
      );

      _instance = PocketBase(ApiConstants.pocketbaseBaseUrl, authStore: store);
    }

    return _instance!;
  }
}
