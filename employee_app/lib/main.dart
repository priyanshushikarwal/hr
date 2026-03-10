import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/domain/providers/auth_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);

  runApp(const ProviderScope(child: HRMSEmployeeApp()));
}

class HRMSEmployeeApp extends ConsumerStatefulWidget {
  const HRMSEmployeeApp({super.key});

  @override
  ConsumerState<HRMSEmployeeApp> createState() => _HRMSEmployeeAppState();
}

class _HRMSEmployeeAppState extends ConsumerState<HRMSEmployeeApp> {
  @override
  void initState() {
    super.initState();
    // Check authentication on startup
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Employee Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
