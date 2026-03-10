import 'package:hive_flutter/hive_flutter.dart';

/// Hive box names for local caching
class HiveBoxes {
  HiveBoxes._();

  static const String employees = 'employees';
  static const String attendance = 'attendance';
  static const String officeSalary = 'office_salary';
  static const String factorySalary = 'factory_salary';
  static const String leaveRequests = 'leave_requests';
  static const String offerLetters = 'offer_letters';
  static const String payments = 'payments';
  static const String notifications = 'notifications_box';
  static const String companySettings = 'company_settings';
  static const String visits = 'visits';
  static const String offlineQueue = 'offline_queue';
  static const String syncMeta = 'sync_meta';
}

/// Initialize Hive and open all boxes
class HiveService {
  HiveService._();

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Open all boxes
    await Future.wait([
      Hive.openBox<Map>(HiveBoxes.employees),
      Hive.openBox<Map>(HiveBoxes.attendance),
      Hive.openBox<Map>(HiveBoxes.officeSalary),
      Hive.openBox<Map>(HiveBoxes.factorySalary),
      Hive.openBox<Map>(HiveBoxes.leaveRequests),
      Hive.openBox<Map>(HiveBoxes.offerLetters),
      Hive.openBox<Map>(HiveBoxes.payments),
      Hive.openBox<Map>(HiveBoxes.notifications),
      Hive.openBox<Map>(HiveBoxes.companySettings),
      Hive.openBox<Map>(HiveBoxes.visits),
      Hive.openBox<Map>(HiveBoxes.offlineQueue),
      Hive.openBox<String>(HiveBoxes.syncMeta),
    ]);
  }

  /// Generic box accessor by name
  static Box<Map> getBox(String name) => Hive.box<Map>(name);

  static Box<Map> get employeesBox => Hive.box<Map>(HiveBoxes.employees);
  static Box<Map> get attendanceBox => Hive.box<Map>(HiveBoxes.attendance);
  static Box<Map> get officeSalaryBox => Hive.box<Map>(HiveBoxes.officeSalary);
  static Box<Map> get factorySalaryBox =>
      Hive.box<Map>(HiveBoxes.factorySalary);
  static Box<Map> get leaveRequestsBox =>
      Hive.box<Map>(HiveBoxes.leaveRequests);
  static Box<Map> get offerLettersBox => Hive.box<Map>(HiveBoxes.offerLetters);
  static Box<Map> get paymentsBox => Hive.box<Map>(HiveBoxes.payments);
  static Box<Map> get notificationsBox =>
      Hive.box<Map>(HiveBoxes.notifications);
  static Box<Map> get companySettingsBox =>
      Hive.box<Map>(HiveBoxes.companySettings);
  static Box<Map> get offlineQueueBox => Hive.box<Map>(HiveBoxes.offlineQueue);
  static Box<String> get syncMetaBox => Hive.box<String>(HiveBoxes.syncMeta);
}
