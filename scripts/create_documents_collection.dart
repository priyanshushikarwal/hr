import 'package:dart_appwrite/dart_appwrite.dart';

const String endpoint = 'https://fra.cloud.appwrite.io/v1';
const String projectId = '69a6abd60016b9d9b287';
const String databaseId = 'hrms_database';
const String apiKey =
    'standard_207fdbbe0325c8ba58258ef2ed923252116f1c91011c4372ca6575d3a640d19128f5e2e1f8e817349c2c82f981861bf6c1160f72273f303168dd7a660ffe2a7a4c6e59db15d657e8f756e78c0185b1a2994687dbb66b09cf21c484619ded198429ca25d56d7c697ce8aaf1d07d417d403ae823a829f51cdf5f82ef7831c37c76';

void main() async {
  final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey)
      .setSelfSigned(status: true);

  final databases = Databases(client);
  final storage = Storage(client);

  try {
    await storage.createBucket(
      bucketId: 'employee_documents',
      name: 'Employee Documents',
      permissions: [
        Permission.read(Role.users()),
        Permission.create(Role.users()),
        Permission.update(Role.users()),
        Permission.delete(Role.users()),
      ],
      fileSecurity: false,
      enabled: true,
      maximumFileSize: 50000000,
      allowedFileExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
    );
    print('Bucket created successfully');
  } catch (e) {
    if (e.toString().contains('already exists')) {
      print('Bucket already exists');
    } else {
      print('Bucket error: $e');
    }
  }

  try {
    await databases.createCollection(
      databaseId: databaseId,
      collectionId: 'employee_documents',
      name: 'Employee Documents',
      permissions: [
        Permission.read(Role.users()),
        Permission.create(Role.users()),
        Permission.update(Role.users()),
        Permission.delete(Role.users()),
      ],
    );
    print('Collection created successfully');

    await Future.delayed(Duration(seconds: 1));
    await databases.createStringAttribute(
      databaseId: databaseId,
      collectionId: 'employee_documents',
      key: 'employeeId',
      size: 100,
      xrequired: true,
    );
    await databases.createStringAttribute(
      databaseId: databaseId,
      collectionId: 'employee_documents',
      key: 'documentName',
      size: 255,
      xrequired: true,
    );
    await databases.createStringAttribute(
      databaseId: databaseId,
      collectionId: 'employee_documents',
      key: 'documentType',
      size: 100,
      xrequired: true,
    );
    await databases.createStringAttribute(
      databaseId: databaseId,
      collectionId: 'employee_documents',
      key: 'fileId',
      size: 100,
      xrequired: true,
    );
    await databases.createStringAttribute(
      databaseId: databaseId,
      collectionId: 'employee_documents',
      key: 'fileUrl',
      size: 1000,
      xrequired: true,
    );
    await databases.createStringAttribute(
      databaseId: databaseId,
      collectionId: 'employee_documents',
      key: 'uploadedAt',
      size: 50,
      xrequired: true,
    );
    print('Attributes created successfully');
  } catch (e) {
    if (e.toString().contains('already exists')) {
      print('Collection already exists');
    } else {
      print('Collection error: $e');
    }
  }
}
