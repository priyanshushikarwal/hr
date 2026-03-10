import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';

/// Singleton Appwrite service
class AppwriteService {
  static AppwriteService? _instance;
  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  late final Realtime realtime;

  AppwriteService._() {
    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId)
        .setSelfSigned(status: true);
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    realtime = Realtime(client);
  }

  static AppwriteService get instance {
    _instance ??= AppwriteService._();
    return _instance!;
  }
}
