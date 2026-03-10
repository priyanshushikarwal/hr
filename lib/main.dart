import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/services/appwrite_service.dart';
import 'core/services/realtime_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/network_service.dart';
import 'core/config/hive_config.dart';
import 'core/widgets/offline_banner.dart';
import 'features/auth/domain/providers/auth_providers.dart';
import 'shared/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (local storage)
  await HiveService.initialize();

  // Initialize Appwrite
  AppwriteService.instance.initialize();

  // Initialize window manager for desktop
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1440, 900),
    minimumSize: Size(1200, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'HR Management System',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: HRMSApp()));
}

class HRMSApp extends ConsumerStatefulWidget {
  const HRMSApp({super.key});

  @override
  ConsumerState<HRMSApp> createState() => _HRMSAppState();
}

class _HRMSAppState extends ConsumerState<HRMSApp> {
  DateTime? _lastSyncTriggered;

  @override
  void initState() {
    super.initState();
    // Subscribe to realtime events after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        RealtimeService.instance.subscribeAll();
      }
    });
  }

  @override
  void dispose() {
    RealtimeService.instance.unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Subscribe/unsubscribe realtime based on auth state
    if (authState.isAuthenticated) {
      RealtimeService.instance.subscribeAll();
      // Auto-sync when network comes back online (debounced — max once per 5 min)
      final networkStatus = ref.watch(networkStatusProvider);
      if (networkStatus == NetworkStatus.online) {
        final now = DateTime.now();
        if (_lastSyncTriggered == null ||
            now.difference(_lastSyncTriggered!).inMinutes >= 5) {
          _lastSyncTriggered = now;
          SyncService.instance.syncAll();
        }
      }
    } else {
      RealtimeService.instance.unsubscribeAll();
    }

    // Show loading spinner while checking auth
    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      );
    }

    final router = AppRouter.createRouter(ref);

    return MaterialApp.router(
      title: 'HR Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        // Add custom window title bar for desktop
        return Column(
          children: [
            // Custom Title Bar
            const _WindowTitleBar(),
            // Offline Banner
            const OfflineBanner(),
            // Main Content
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}

/// Custom Window Title Bar for Desktop
class _WindowTitleBar extends StatelessWidget {
  const _WindowTitleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Drag Area (for moving window)
          Expanded(
            child: GestureDetector(
              onPanStart: (_) => windowManager.startDragging(),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.only(left: 16),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    // App Icon
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A3D), Color(0xFFFFB380)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'H',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HRMS - HR Management System',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Window Controls
          _WindowButton(
            icon: Icons.remove,
            onPressed: () => windowManager.minimize(),
          ),
          _WindowButton(
            icon: Icons.crop_square,
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
          ),
          _WindowButton(
            icon: Icons.close,
            onPressed: () => windowManager.close(),
            isClose: true,
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          color: _isHovered
              ? (widget.isClose ? Colors.red : Colors.grey.withOpacity(0.2))
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 14,
            color: _isHovered && widget.isClose
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
