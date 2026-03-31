// ignore_for_file: avoid_print
/// Run this script ONCE to create all collections in your Appwrite project.
/// Usage:  dart run scripts/setup_appwrite.dart
///
/// Make sure your Appwrite project ID and endpoint are correct in appwrite_config.dart
/// You also need an Appwrite API key with Database permissions.

import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';

// ─── CONFIG ────────────────────────────────────────────────────
const String endpoint = 'https://fra.cloud.appwrite.io/v1';
const String projectId = '69a6abd60016b9d9b287';
const String databaseId = 'hrms_database';

// Paste your Appwrite API key here (Settings → API Keys → Create)
// The key needs permissions: databases.read, databases.write,
// collections.read, collections.write, attributes.read, attributes.write
const String apiKey =
    'standard_207fdbbe0325c8ba58258ef2ed923252116f1c91011c4372ca6575d3a640d19128f5e2e1f8e817349c2c82f981861bf6c1160f72273f303168dd7a660ffe2a7a4c6e59db15d657e8f756e78c0185b1a2994687dbb66b09cf21c484619ded198429ca25d56d7c697ce8aaf1d07d417d403ae823a829f51cdf5f82ef7831c37c76'; // <-- PASTE YOUR API KEY

// ─── MAIN ──────────────────────────────────────────────────────
void main() async {
  if (apiKey.isEmpty) {
    print('❌ Please set your Appwrite API key in this file first!');
    print('   Go to Appwrite Console → Settings → API Keys → Create Key');
    print('   Give it Database permissions, then paste the secret above.');
    exit(1);
  }

  final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey)
      .setSelfSigned(status: true);

  final databases = Databases(client);

  // 1) Create the database (if it doesn't exist)
  await _createDatabase(databases);

  // 2) Create all collections
  await _createCollection(databases, 'users', 'Users', [
    _attr('userId', 'string', size: 100, required: true),
    _attr('email', 'string', size: 255, required: true),
    _attr('name', 'string', size: 200, required: true),
    _attr('role', 'string', size: 50, required: true),
    _attr('phone', 'string', size: 20),
    _attr('status', 'string', size: 20),
    _attr('createdAt', 'string', size: 50),
  ]);

  await _createCollection(databases, 'employees', 'Employees', [
    _attr('employeeId', 'string', size: 100),
    _attr('employeeCode', 'string', size: 50, required: true),
    _attr('firstName', 'string', size: 100, required: true),
    _attr('lastName', 'string', size: 100),
    _attr('email', 'string', size: 255),
    _attr('phone', 'string', size: 20),
    _attr('alternatePhone', 'string', size: 20),
    _attr('department', 'string', size: 100),
    _attr('designation', 'string', size: 100),
    _attr('employeeType', 'string', size: 50),
    _attr('status', 'string', size: 20),
    _attr('joiningDate', 'string', size: 50),
    _attr('confirmationDate', 'string', size: 50),
    _attr('gender', 'string', size: 20),
    _attr('maritalStatus', 'string', size: 50),
    _attr('bloodGroup', 'string', size: 10),
    _attr('dateOfBirth', 'string', size: 50),
    _attr('fatherName', 'string', size: 100),
    _attr('motherName', 'string', size: 100),
    _attr('spouseName', 'string', size: 100),
    _attr('emergencyContact', 'string', size: 20),
    _attr('emergencyContactName', 'string', size: 100),
    _attr('currentAddress', 'string', size: 500),
    _attr('currentCity', 'string', size: 100),
    _attr('currentState', 'string', size: 100),
    _attr('currentPincode', 'string', size: 10),
    _attr('permanentAddress', 'string', size: 500),
    _attr('permanentCity', 'string', size: 100),
    _attr('permanentState', 'string', size: 100),
    _attr('permanentPincode', 'string', size: 10),
    _attr('aadhaarNumber', 'string', size: 20),
    _attr('panNumber', 'string', size: 20),
    _attr('bankName', 'string', size: 100),
    _attr('bankAccountNumber', 'string', size: 50),
    _attr('ifscCode', 'string', size: 20),
    _attr('uan', 'string', size: 50),
    _attr('esicNumber', 'string', size: 50),
    _attr('isPfApplicable', 'boolean'),
    _attr('isEsicApplicable', 'boolean'),
    _attr('profileImageUrl', 'string', size: 500),
    _attr('reportingManager', 'string', size: 100),
    _attr('reportingManagerId', 'string', size: 100),
    _attr('remarks', 'string', size: 1000),
    _attr('createdAt', 'string', size: 50),
    _attr('updatedAt', 'string', size: 50),
    _attr('createdBy', 'string', size: 100),
    _attr('updatedBy', 'string', size: 100),
  ]);

  await _createCollection(databases, 'attendance', 'Attendance', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('employeeCode', 'string', size: 50),
    _attr('date', 'string', size: 50, required: true),
    _attr('status', 'string', size: 20, required: true),
    _attr('checkIn', 'string', size: 50),
    _attr('checkOut', 'string', size: 50),
    _attr('hoursWorked', 'double'),
    _attr('overtimeHours', 'double'),
    _attr('remarks', 'string', size: 500),
    _attr('approvalStatus', 'string', size: 20),
    _attr('approvedBy', 'string', size: 100),
    _attr('location', 'string', size: 200),
    _attr('selfieId', 'string', size: 100),
    _attr('createdAt', 'string', size: 50),
    _attr('updatedAt', 'string', size: 50),
    _attr('createdBy', 'string', size: 100),
  ]);

  await _createCollection(databases, 'leave_requests', 'Leave Requests', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('employeeName', 'string', size: 200),
    _attr('employeeCode', 'string', size: 50),
    _attr('fromDate', 'string', size: 50, required: true),
    _attr('toDate', 'string', size: 50, required: true),
    _attr('reason', 'string', size: 1000, required: true),
    _attr('status', 'string', size: 20),
    _attr('approvedBy', 'string', size: 100),
    _attr('approvedAt', 'string', size: 50),
    _attr('rejectionReason', 'string', size: 500),
    _attr('createdAt', 'string', size: 50),
    _attr('updatedAt', 'string', size: 50),
  ]);

  await _createCollection(databases, 'salary_structures', 'Salary Structures', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('employeeCode', 'string', size: 50),
    _attr('effectiveFrom', 'string', size: 50),
    _attr('effectiveTo', 'string', size: 50),
    _attr('basicSalary', 'double'),
    _attr('hra', 'double'),
    _attr('da', 'double'),
    _attr('conveyanceAllowance', 'double'),
    _attr('medicalAllowance', 'double'),
    _attr('specialAllowance', 'double'),
    _attr('otherAllowances', 'double'),
    _attr('grossSalary', 'double'),
    _attr('pfEmployee', 'double'),
    _attr('pfEmployer', 'double'),
    _attr('esicEmployee', 'double'),
    _attr('esicEmployer', 'double'),
    _attr('professionalTax', 'double'),
    _attr('tds', 'double'),
    _attr('otherDeductions', 'double'),
    _attr('isPfApplicable', 'boolean'),
    _attr('isEsicApplicable', 'boolean'),
    _attr('pfActivationDate', 'string', size: 50),
    _attr('esicActivationDate', 'string', size: 50),
    _attr('totalDeductions', 'double'),
    _attr('netSalary', 'double'),
    _attr('ctc', 'double'),
    _attr('advanceBalance', 'double'),
    _attr('loanBalance', 'double'),
    _attr('remarks', 'string', size: 1000),
    _attr('createdAt', 'string', size: 50),
    _attr('updatedAt', 'string', size: 50),
    _attr('createdBy', 'string', size: 100),
    _attr('status', 'string', size: 20),
  ]);

  await _createCollection(databases, 'factory_salary', 'Factory Salary', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('employeeCode', 'string', size: 50),
    _attr('date', 'string', size: 50, required: true),
    _attr('shiftType', 'string', size: 50),
    _attr('hoursWorked', 'double'),
    _attr('overtimeHours', 'double'),
    _attr('kva', 'double'),
    _attr('rate', 'double'),
    _attr('basicAmount', 'double'),
    _attr('overtimeAmount', 'double'),
    _attr('incentive', 'double'),
    _attr('deductions', 'double'),
    _attr('totalAmount', 'double'),
    _attr('remarks', 'string', size: 500),
    _attr('createdAt', 'string', size: 50),
    _attr('createdBy', 'string', size: 100),
    _attr('status', 'string', size: 20),
  ]);

  await _createCollection(databases, 'payments', 'Payments', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('employeeCode', 'string', size: 50),
    _attr('employeeName', 'string', size: 200),
    _attr('month', 'integer'),
    _attr('year', 'integer'),
    _attr('grossSalary', 'double'),
    _attr('totalDeductions', 'double'),
    _attr('netSalary', 'double'),
    _attr('paymentMode', 'string', size: 50),
    _attr('transactionNumber', 'string', size: 100),
    _attr('paymentDate', 'string', size: 50),
    _attr('status', 'string', size: 20),
    _attr('isLocked', 'boolean'),
    _attr('salarySlipPath', 'string', size: 500),
    _attr('remarks', 'string', size: 500),
    _attr('createdAt', 'string', size: 50),
    _attr('updatedAt', 'string', size: 50),
    _attr('createdBy', 'string', size: 100),
  ]);

  await _createCollection(databases, 'advance_salary', 'Advance Salary', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('employeeCode', 'string', size: 50, required: true),
    _attr('advanceAmount', 'double', required: true),
    _attr('reason', 'string', size: 1000, required: true),
    _attr('status', 'string', size: 50, required: true),
    _attr('repaidAmount', 'double', required: true),
    _attr('pendingAmount', 'double', required: true),
    _attr('installments', 'integer', required: true),
    _attr('installmentsCleared', 'integer', required: true),
    _attr('requestDate', 'string', size: 50, required: true),
    _attr('approvalDate', 'string', size: 50),
    _attr('clearanceDate', 'string', size: 50),
    _attr('remarks', 'string', size: 1000),
    _attr('approvedBy', 'string', size: 100),
    _attr('createdBy', 'string', size: 100),
    _attr('updatedBy', 'string', size: 100),
    _attr('createdAt', 'string', size: 50, required: true),
    _attr('updatedAt', 'string', size: 50, required: true),
  ]);

  await _createCollection(databases, 'offer_letters', 'Offer Letters', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('employeeCode', 'string', size: 50),
    _attr('employeeName', 'string', size: 200),
    _attr('designation', 'string', size: 100),
    _attr('department', 'string', size: 100),
    _attr('employeeType', 'string', size: 50),
    _attr('grossSalary', 'double'),
    _attr('ctc', 'double'),
    _attr('joiningDate', 'string', size: 50),
    _attr('status', 'string', size: 20),
    _attr('approvedBy', 'string', size: 100),
    _attr('approvedAt', 'string', size: 50),
    _attr('sentAt', 'string', size: 50),
    _attr('pdfStorageId', 'string', size: 100),
    _attr('localPdfPath', 'string', size: 500),
    _attr('remarks', 'string', size: 1000),
    _attr('createdAt', 'string', size: 50),
    _attr('updatedAt', 'string', size: 50),
    _attr('createdBy', 'string', size: 100),
  ]);

  await _createCollection(databases, 'notifications', 'Notifications', [
    _attr('userId', 'string', size: 100, required: true),
    _attr('title', 'string', size: 200, required: true),
    _attr('message', 'string', size: 1000),
    _attr('type', 'string', size: 50),
    _attr('isRead', 'boolean'),
    _attr('readAt', 'string', size: 50),
    _attr('createdAt', 'string', size: 50),
    _attr('data', 'string', size: 2000),
  ]);

  await _createCollection(databases, 'company_settings', 'Company Settings', [
    _attr('key', 'string', size: 100, required: true),
    _attr('value', 'string', size: 2000),
    _attr('updatedAt', 'string', size: 50),
    _attr('updatedBy', 'string', size: 100),
  ]);

  await _createCollection(databases, 'employee_documents', 'Employee Documents', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('documentName', 'string', size: 255, required: true),
    _attr('documentType', 'string', size: 100, required: true),
    _attr('fileId', 'string', size: 100, required: true),
    _attr('fileUrl', 'string', size: 500),
    _attr('uploadedAt', 'string', size: 50, required: true),
    _attr('approvalStatus', 'string', size: 20),
    _attr('approvedBy', 'string', size: 100),
    _attr('reviewedAt', 'string', size: 50),
    _attr('rejectionReason', 'string', size: 500),
  ]);

  await _createCollection(databases, 'visits', 'Visits', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('employeeName', 'string', size: 200),
    _attr('employeeCode', 'string', size: 50),
    _attr('purpose', 'string', size: 500, required: true),
    _attr('clientName', 'string', size: 200),
    _attr('visitAddress', 'string', size: 500),
    _attr('visitDate', 'string', size: 50, required: true),
    _attr('selfieFileId', 'string', size: 100),
    _attr('latitude', 'double'),
    _attr('longitude', 'double'),
    _attr('locationAddress', 'string', size: 500),
    _attr('selfieTimestamp', 'string', size: 50),
    _attr('status', 'string', size: 20, required: true),
    _attr('remarks', 'string', size: 500),
    _attr('approvedBy', 'string', size: 100),
    _attr('approvedAt', 'string', size: 50),
    _attr('rejectionReason', 'string', size: 500),
    _attr('createdAt', 'string', size: 50, required: true),
    _attr('updatedAt', 'string', size: 50, required: true),
  ]);

  await _createCollection(databases, 'tasks', 'Tasks', [
    _attr('title', 'string', size: 500, required: true),
    _attr('description', 'string', size: 2000),
    _attr('dueDate', 'string', size: 50, required: true),
    _attr('status', 'string', size: 20, required: true),
    _attr('priority', 'string', size: 20),
    _attr('createdBy', 'string', size: 100, required: true),
    _attr('assignedTo', 'string', size: 100),
    _attr('completedAt', 'string', size: 50),
    _attr('completedBy', 'string', size: 100),
    _attr('createdAt', 'string', size: 50, required: true),
    _attr('updatedAt', 'string', size: 50, required: true),
  ]);

  await _createCollection(databases, 'experience', 'Experience', [
    _attr('employeeId', 'string', size: 100, required: true),
    _attr('companyName', 'string', size: 255, required: true),
    _attr('designation', 'string', size: 255, required: true),
    _attr('startDate', 'string', size: 50, required: true),
    _attr('endDate', 'string', size: 50),
    _attr('isCurrent', 'boolean'),
    _attr('location', 'string', size: 255),
    _attr('description', 'string', size: 1000),
    _attr('createdAt', 'string', size: 50, required: true),
    _attr('updatedAt', 'string', size: 50, required: true),
  ]);

  print('\n✅ All collections created successfully!');
  print('   Your app should now work without collection_not_found errors.');
}

// ─── HELPERS ───────────────────────────────────────────────────

Future<void> _createDatabase(Databases databases) async {
  try {
    await databases.create(databaseId: databaseId, name: 'HRMS Database');
    print('✅ Database "$databaseId" created');
  } catch (e) {
    if (e.toString().contains('already exists') ||
        e.toString().contains('409')) {
      print('ℹ️  Database "$databaseId" already exists — skipping');
    } else {
      print('⚠️  Database create error: $e');
    }
  }
}

Future<void> _createCollection(
  Databases databases,
  String collectionId,
  String name,
  List<_AttrDef> attributes,
) async {
  // Create collection
  try {
    await databases.createCollection(
      databaseId: databaseId,
      collectionId: collectionId,
      name: name,
      permissions: [
        Permission.read(Role.any()),
        Permission.create(Role.users()),
        Permission.update(Role.users()),
        Permission.delete(Role.users()),
      ],
      documentSecurity: false,
    );
    print('✅ Collection "$name" ($collectionId) created');
  } catch (e) {
    if (e.toString().contains('already exists') ||
        e.toString().contains('409')) {
      print(
        'ℹ️  Collection "$name" already exists — adding missing attributes',
      );
    } else {
      print('❌ Collection "$name" error: $e');
      return;
    }
  }

  // Create attributes
  for (final attr in attributes) {
    try {
      switch (attr.type) {
        case 'string':
          await databases.createStringAttribute(
            databaseId: databaseId,
            collectionId: collectionId,
            key: attr.key,
            size: attr.size ?? 255,
            xrequired: attr.required,
          );
          break;
        case 'double':
          await databases.createFloatAttribute(
            databaseId: databaseId,
            collectionId: collectionId,
            key: attr.key,
            xrequired: attr.required,
          );
          break;
        case 'integer':
          await databases.createIntegerAttribute(
            databaseId: databaseId,
            collectionId: collectionId,
            key: attr.key,
            xrequired: attr.required,
          );
          break;
        case 'boolean':
          await databases.createBooleanAttribute(
            databaseId: databaseId,
            collectionId: collectionId,
            key: attr.key,
            xrequired: attr.required,
          );
          break;
      }
    } catch (e) {
      if (e.toString().contains('already exists') ||
          e.toString().contains('409')) {
        // Attribute already exists — skip silently
      } else {
        print('   ⚠️  Attribute "${attr.key}" error: $e');
      }
    }
  }
}

class _AttrDef {
  final String key;
  final String type;
  final int? size;
  final bool required;
  _AttrDef(this.key, this.type, {this.size, this.required = false});
}

_AttrDef _attr(String key, String type, {int? size, bool required = false}) {
  return _AttrDef(key, type, size: size, required: required);
}
