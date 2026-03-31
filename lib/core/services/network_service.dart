import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/appwrite_config.dart';

/// Provides the current network connectivity status
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
      return NetworkStatusNotifier();
    });

enum NetworkStatus { online, offline }

class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  Timer? _pollTimer;
  static final List<String> _healthHosts = [
    Uri.parse(AppwriteConfig.endpoint).host,
    'google.com',
  ];

  NetworkStatusNotifier() : super(NetworkStatus.online) {
    _init();
  }

  /// Uses actual HTTP ping instead of connectivity_plus
  /// because connectivity_plus doesn't work reliably on Windows desktop
  Future<void> _init() async {
    await _checkConnectivity();
    // Poll every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    for (final host in _healthHosts) {
      try {
        final result = await InternetAddress.lookup(
          host,
        ).timeout(const Duration(seconds: 5));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          state = NetworkStatus.online;
          return;
        }
      } on SocketException catch (_) {
        continue;
      } on TimeoutException catch (_) {
        continue;
      } catch (_) {
        continue;
      }
    }

    state = NetworkStatus.offline;
  }

  /// Manually trigger a check
  Future<void> checkNow() async {
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
