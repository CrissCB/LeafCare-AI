import 'package:pocketbase/pocketbase.dart';

import '../config.dart';

/// Cliente PocketBase único para toda la app, apuntando al backend local.
final PocketBase pocketBase = PocketBase(AppConfig.pocketBaseUrl);
