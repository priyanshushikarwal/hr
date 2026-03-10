/// Appwrite Configuration — Same as HRMS Desktop
class AppwriteConfig {
  AppwriteConfig._();

  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = '69a6abd60016b9d9b287';
  static const String databaseId = 'hrms_database';

  // Collections
  static const String usersCollectionId = 'users';
  static const String employeesCollectionId = 'employees';
  static const String attendanceCollectionId = 'attendance';
  static const String leaveRequestsCollectionId = 'leave_requests';
  static const String notificationsCollectionId = 'notifications';
  static const String employeeDocumentsCollectionId = 'employee_documents';

  // Storage
  static const String visitSelfiesBucketId = 'visit_selfies';
  static const String employeeDocumentsBucketId = 'employee_documents';
}
