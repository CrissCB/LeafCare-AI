import 'package:pocketbase/pocketbase.dart';

import 'package:leafcare_ia/core/network/pocketbase_client.dart';

class AuthRemoteDatasource {
  Future<RecordAuth> login(String email, String password) async {
    final pb = await PocketBaseClient.getInstance();
    return await pb.collection('users').authWithPassword(email, password);
  }
}
