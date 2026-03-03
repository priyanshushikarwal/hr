/// Appwrite Configuration Constants
/// Update these values with your Appwrite instance details
class AppwriteConfig {
  AppwriteConfig._();

  // ============ APPWRITE INSTANCE ============
  /// Your Appwrite endpoint URL
  /// For self-hosted: 'https://your-domain.com/v1'
  /// For Cloud: 'https://cloud.appwrite.io/v1'
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';

  /// Your Appwrite Project ID
  static const String projectId = '69a6abd60016b9d9b287';

  // ============ DATABASE ============
  static const String databaseId = 'hrms_database';

  // ============ COLLECTION IDs ============
  static const String usersCollectionId = 'users';
  static const String employeesCollectionId = 'employees';
  static const String attendanceCollectionId = 'attendance';
  static const String leaveRequestsCollectionId = 'leave_requests';
  static const String notificationsCollectionId = 'notifications';

  // ============ STORAGE BUCKETS ============
  static const String visitSelfiesBucketId = 'visit_selfies';

  // ============ ROLES ============
  static const String roleHR = 'hr';
  static const String roleManager = 'manager';
  static const String roleAccountant = 'accountant';
  static const String roleEmployee = 'employee';

  /// Roles allowed for HR Desktop app
  static const List<String> desktopAllowedRoles = [
    roleHR,
    roleManager,
    roleAccountant,
  ];

  /// Roles allowed for Employee Mobile app
  static const List<String> mobileAllowedRoles = [roleEmployee];
}
