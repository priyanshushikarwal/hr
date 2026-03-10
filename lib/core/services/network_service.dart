import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current network connectivity status
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
      return NetworkStatusNotifier();
    });

enum NetworkStatus { online, offline }

class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  Timer? _pollTimer;

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
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        state = NetworkStatus.online;
      } else {
        state = NetworkStatus.offline;
      }
    } on SocketException catch (_) {
      state = NetworkStatus.offline;
    } on TimeoutException catch (_) {
      state = NetworkStatus.offline;
    } catch (_) {
      // Default to online if check fails for unknown reasons
      state = NetworkStatus.online;
    }
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
