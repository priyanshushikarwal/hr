/// HRMS Application Constants
library;

class AppConstants {
  AppConstants._();

  // ============ APP INFO ============
  static const String appName = 'HR Management System';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Professional HR Management Desktop Application';
  static const String companyName = 'Your Company Name';

  // ============ EMPLOYEE TYPES ============
  static const String employeeTypeOffice = 'office';
  static const String employeeTypeFactory = 'factory';

  // ============ EMPLOYEE STATUS ============
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusOnLeave = 'on_leave';
  static const String statusTerminated = 'terminated';

  // ============ APPROVAL STATUS ============
  static const String approvalDraft = 'draft';
  static const String approvalPending = 'pending';
  static const String approvalApproved = 'approved';
  static const String approvalRejected = 'rejected';
  static const String approvalSent = 'sent';

  // ============ DOCUMENT TYPES ============
  static const List<String> documentTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Passport',
    'Driving License',
    'Voter ID',
    'Bank Passbook',
    '10th Marksheet',
    '12th Marksheet',
    'Graduation Certificate',
    'Post Graduation Certificate',
    'Experience Letter',
    'Relieving Letter',
    'Salary Slip',
    'Offer Letter',
    'Other',
  ];

  // ============ LEAVE TYPES ============
  static const List<String> leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Earned Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Unpaid Leave',
    'Compensatory Off',
    'Work From Home',
    'Half Day',
    'Other',
  ];

  // ============ SHIFT TYPES ============
  static const List<String> shiftTypes = [
    'General Shift',
    'Morning Shift',
    'Afternoon Shift',
    'Night Shift',
    'Rotational Shift',
  ];

  // ============ PAYMENT MODES ============
  static const List<String> paymentModes = [
    'Bank Transfer',
    'Cheque',
    'Cash',
    'UPI',
    'NEFT',
    'RTGS',
    'IMPS',
  ];

  // ============ DEPARTMENTS ============
  static const List<String> departments = [
    'Human Resources',
    'Finance & Accounts',
    'Engineering',
    'Production',
    'Quality Control',
    'Sales & Marketing',
    'Administration',
    'IT Support',
    'Logistics',
    'Maintenance',
    'Research & Development',
    'Customer Support',
  ];

  // ============ DESIGNATIONS ============
  static const List<String> designations = [
    'CEO',
    'CTO',
    'CFO',
    'Director',
    'General Manager',
    'Senior Manager',
    'Manager',
    'Assistant Manager',
    'Team Lead',
    'Senior Engineer',
    'Engineer',
    'Junior Engineer',
    'Trainee',
    'Executive',
    'Senior Executive',
    'Associate',
    'Senior Associate',
    'Analyst',
    'Senior Analyst',
    'Supervisor',
    'Operator',
    'Technician',
    'Helper',
    'Intern',
  ];

  // ============ ROLES ============
  static const List<String> userRoles = [
    'Super Admin',
    'Admin',
    'HR Manager',
    'HR Executive',
    'Accountant',
    'Manager',
    'Viewer',
  ];

  // ============ GENDER ============
  static const List<String> genders = ['Male', 'Female', 'Other'];

  // ============ MARITAL STATUS ============
  static const List<String> maritalStatus = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  // ============ BLOOD GROUPS ============
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // ============ BANKS ============
  static const List<String> banks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Bank of Baroda',
    'Punjab National Bank',
    'Canara Bank',
    'Union Bank of India',
    'Bank of India',
    'IndusInd Bank',
    'Yes Bank',
    'IDFC First Bank',
    'Federal Bank',
    'Other',
  ];

  // ============ STATES (INDIA) ============
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Chandigarh',
    'Jammu & Kashmir',
    'Ladakh',
    'Puducherry',
    'Andaman & Nicobar Islands',
    'Dadra & Nagar Haveli and Daman & Diu',
    'Lakshadweep',
  ];

  // ============ FORMAT PATTERNS ============
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String timeFormat = 'hh:mm a';
  static const String monthFormat = 'MMM yyyy';
  static const String currencySymbol = '₹';
  static const String currencyFormat = '##,##,###.##';

  // ============ ID PREFIXES ============
  static const String employeeIdPrefix = 'EMP';
  static const String offerLetterIdPrefix = 'OL';
  static const String salarySlipIdPrefix = 'SS';
  static const String transactionIdPrefix = 'TXN';

  // ============ LIMITS ============
  static const int maxFileUploadSize = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentsPerEmployee = 20;
  static const int recentEmployeesLimit = 10;
  static const int paginationLimit = 25;

  // ============ TABLE COLUMN WIDTHS ============
  static const double tableCheckboxWidth = 50;
  static const double tableIdWidth = 100;
  static const double tableNameWidth = 200;
  static const double tableEmailWidth = 220;
  static const double tablePhoneWidth = 140;
  static const double tableDepartmentWidth = 150;
  static const double tableStatusWidth = 120;
  static const double tableActionsWidth = 120;
  static const double tableDateWidth = 140;
  static const double tableAmountWidth = 140;
}
