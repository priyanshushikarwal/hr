import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../../../profile/domain/providers/profile_providers.dart';

class AttendanceRecord {
  final String id;
  final String employeeId;
  final String date;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String? remarks;
  final String? location;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.remarks,
    this.location,
  });

  factory AttendanceRecord.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    return AttendanceRecord(
      id: docId ?? json['\$id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'absent',
      checkIn: json['checkIn'],
      checkOut: json['checkOut'],
      remarks: json['remarks'],
      location: json['location'],
    );
  }
}

final attendanceProvider =
    FutureProvider.family<List<AttendanceRecord>, String>((
      ref,
      monthKey,
    ) async {
      final auth = ref.watch(authProvider);

      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final db = AppwriteService.instance.databases;
      // monthKey format: "2026-03"
      
      final profileConfig = await ref.watch(employeeProfileProvider.future);
      final queryParam = profileConfig?.id ?? auth.user?.employeeId;
      
      print('=== ATTENDANCE DEBUG ===');
      print('Auth User ID: ${auth.user?.userId}');
      print('Auth Email: ${auth.user?.email}');
      print('Profile Config ID: ${profileConfig?.id}');
      print('Resolved queryParam: $queryParam');
      print('========================');
      
      if (queryParam == null) return [];

      // ----------------------------------------------------
      // REALTIME WEBSOCKET SUBSCRIPTION
      // ----------------------------------------------------
      RealtimeService.instance.subscribeToAttendance();
      final sub = RealtimeService.instance.attendanceStream.listen((event) {
        if (event.data['employeeId'] == queryParam) {
          final eventDate = event.data['date'] as String?;
          if (eventDate != null && eventDate.startsWith(monthKey)) {
             ref.invalidateSelf(); // Refresh data!
          }
        }
      });
      ref.onDispose(() {
        sub.cancel();
      });
      // ----------------------------------------------------

      final docs = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.attendanceCollectionId,
        queries: [
          Query.equal('employeeId', queryParam),
          Query.greaterThanEqual('date', startDate.toIso8601String()),
          Query.lessThanEqual('date', endDate.toIso8601String()),
          Query.limit(100),
          Query.orderDesc('date'),
        ],
      );

      return docs.documents
          .map((d) => AttendanceRecord.fromJson(d.data, docId: d.$id))
          .toList();
    });
