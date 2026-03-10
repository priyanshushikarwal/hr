/// Appwrite Configuration Constants
class AppwriteConfig {
  AppwriteConfig._();

  // ============ APPWRITE INSTANCE ============
  static const String endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String projectId = '69a6abd60016b9d9b287';

  // ============ DATABASE ============
  static const String databaseId = 'hrms_database';

  // ============ COLLECTION IDs ============
  static const String usersCollectionId = 'users';
  static const String employeesCollectionId = 'employees';
  static const String attendanceCollectionId = 'attendance';
  static const String leaveRequestsCollectionId = 'leave_requests';
  static const String notificationsCollectionId = 'notifications';
  static const String salaryStructuresCollectionId = 'salary_structures';
  static const String factorySalaryCollectionId = 'factory_salary';
  static const String paymentsCollectionId = 'payments';
  static const String offerLettersCollectionId = 'offer_letters';
  static const String companySettingsCollectionId = 'company_settings';
  static const String employeeDocumentsCollectionId = 'employee_documents';
  static const String visitsCollectionId = 'visits';

  // ============ STORAGE BUCKETS ============
  static const String visitSelfiesBucketId = 'employee_documents';
  static const String companyAssetsBucketId = 'company_assets';
  static const String documentsBucketId = 'documents';
  static const String employeeDocumentsBucketId = 'employee_documents';
  static const String salarySlipsBucketId = 'salary_slips';
  static const String offerLetterPdfsBucketId = 'offer_letter_pdfs';

  // ============ ROLES ============
  static const String roleHR = 'hr';
  static const String roleManager = 'manager';
  static const String roleAccountant = 'accountant';
  static const String roleEmployee = 'employee';

  static const List<String> desktopAllowedRoles = [
    roleHR,
    roleManager,
    roleAccountant,
  ];
  static const List<String> mobileAllowedRoles = [roleEmployee];
}
