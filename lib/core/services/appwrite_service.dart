import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';

final Client client = Client()
    .setProject("69a6abd60016b9d9b287")
    .setEndpoint("https://fra.cloud.appwrite.io/v1")
    .setSelfSigned(status: true);

/// Singleton Appwrite Service
/// Provides access to all Appwrite SDK services
class AppwriteService {
  AppwriteService._internal();

  static final AppwriteService _instance = AppwriteService._internal();
  static AppwriteService get instance => _instance;

  late final Client _client;
  late final Account _account;
  late final Databases _databases;
  late final Storage _storage;
  late final Realtime _realtime;

  bool _isInitialized = false;

  /// Initialize the Appwrite client with configuration
  void initialize() {
    if (_isInitialized) return;

    _client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId)
        .setSelfSigned(status: true); // Remove in production with valid SSL

    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
    _realtime = Realtime(_client);

    _isInitialized = true;
  }

  // ============ GETTERS ============
  Client get client {
    _ensureInitialized();
    return _client;
  }

  Account get account {
    _ensureInitialized();
    return _account;
  }

  Databases get databases {
    _ensureInitialized();
    return _databases;
  }

  Storage get storage {
    _ensureInitialized();
    return _storage;
  }

  Realtime get realtime {
    _ensureInitialized();
    return _realtime;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'AppwriteService not initialized. Call AppwriteService.instance.initialize() first.',
      );
    }
  }
}
