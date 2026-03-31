import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../../../profile/domain/providers/profile_providers.dart';

class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeCode;
  final String date;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String? remarks;
  final String? location;
  final String? wifiConnectedAt;
  final String? officeWifiName;
  final String? wifiDisconnectedAt;
  final String? wifiReconnectedAt;
  final String? requiredPunchOutAt;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.remarks,
    this.location,
    this.wifiConnectedAt,
    this.officeWifiName,
    this.wifiDisconnectedAt,
    this.wifiReconnectedAt,
    this.requiredPunchOutAt,
  });

  factory AttendanceRecord.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    final normalizedStatus = _normalizeShiftStatus(
      json['status']?.toString() ?? 'absent',
      json['checkIn']?.toString(),
    );

    return AttendanceRecord(
      id: docId ?? json['\$id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      employeeCode: json['employeeCode'] ?? '',
      date: json['date'] ?? '',
      status: normalizedStatus,
      checkIn: json['checkIn'],
      checkOut: json['checkOut'],
      remarks: json['remarks'],
      location: json['location'],
      wifiConnectedAt:
          json['wifiConnectedAt'] ?? _extractAttendanceMeta(json['remarks'], 'wifiConnectedAt'),
      officeWifiName:
          json['officeWifiName'] ?? _extractAttendanceMeta(json['remarks'], 'wifiName'),
      wifiDisconnectedAt:
          json['wifiDisconnectedAt'] ??
          _extractAttendanceMeta(json['remarks'], 'wifiDisconnectedAt'),
      wifiReconnectedAt:
          json['wifiReconnectedAt'] ??
          _extractAttendanceMeta(json['remarks'], 'wifiReconnectedAt'),
      requiredPunchOutAt:
          json['requiredPunchOutAt'] ??
          _extractAttendanceMeta(json['remarks'], 'requiredPunchOutAt'),
    );
  }
}

DateTime _toIndiaOfficeTime(DateTime source) {
  final utc = source.toUtc();
  return DateTime(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
    utc.millisecond,
    utc.microsecond,
  ).add(const Duration(hours: 5, minutes: 30));
}

String _normalizeShiftStatus(String rawStatus, String? checkInIso) {
  final normalizedRaw = rawStatus.toLowerCase().trim();
  if (checkInIso == null || checkInIso.isEmpty) return normalizedRaw;

  final parsedCheckIn = DateTime.tryParse(checkInIso);
  final checkIn = parsedCheckIn == null ? null : _toIndiaOfficeTime(parsedCheckIn);
  if (checkIn == null) return normalizedRaw;

  if (normalizedRaw == 'present' ||
      normalizedRaw == 'late' ||
      normalizedRaw == 'half day' ||
      normalizedRaw == 'half_day') {
    final minutesSinceMidnight = (checkIn.hour * 60) + checkIn.minute;
    if (minutesSinceMidnight >= 11 * 60) return 'half day';
    if (minutesSinceMidnight > ((9 * 60) + 15)) return 'late';
    return 'present';
  }

  return normalizedRaw;
}

String? _extractAttendanceMeta(dynamic remarks, String key) {
  final source = remarks?.toString();
  if (source == null || source.isEmpty) return null;
  final match = RegExp('$key=([^|]+)').firstMatch(source);
  return match?.group(1)?.trim();
}

String _buildAttendanceRemarks({
  required DateTime connectedAt,
  required String? wifiName,
  required DateTime requiredPunchOutAt,
  String? attendanceRuleStatus,
  DateTime? ruleEvaluatedAt,
  DateTime? disconnectedAt,
  DateTime? reconnectedAt,
}) {
  final parts = <String>[
    'Marked from employee app on office Wi-Fi',
    'wifiConnectedAt=${connectedAt.toIso8601String()}',
    'requiredPunchOutAt=${requiredPunchOutAt.toIso8601String()}',
  ];

  if (wifiName != null && wifiName.isNotEmpty) {
    parts.add('wifiName=$wifiName');
  }
  if (attendanceRuleStatus != null && attendanceRuleStatus.isNotEmpty) {
    parts.add('attendanceRuleStatus=$attendanceRuleStatus');
  }
  if (ruleEvaluatedAt != null) {
    parts.add('ruleEvaluatedAt=${ruleEvaluatedAt.toIso8601String()}');
  }
  if (disconnectedAt != null) {
    parts.add('wifiDisconnectedAt=${disconnectedAt.toIso8601String()}');
  }
  if (reconnectedAt != null) {
    parts.add('wifiReconnectedAt=${reconnectedAt.toIso8601String()}');
  }

  return parts.join(' | ');
}

class ShiftAttendanceRuleResult {
  final String status;
  final DateTime requiredPunchOutAt;
  final String label;

  const ShiftAttendanceRuleResult({
    required this.status,
    required this.requiredPunchOutAt,
    required this.label,
  });
}

ShiftAttendanceRuleResult _evaluateShiftAttendance(DateTime now) {
  final officeNow = _toIndiaOfficeTime(now);
  final minutesSinceMidnight = (officeNow.hour * 60) + officeNow.minute;
  const shiftStartMinutes = 9 * 60;
  const graceEndMinutes = (9 * 60) + 15;
  const halfDayStartMinutes = 11 * 60;
  final standardShiftEnd = DateTime(
    officeNow.year,
    officeNow.month,
    officeNow.day,
    18,
    0,
  );

  if (minutesSinceMidnight >= halfDayStartMinutes) {
    return ShiftAttendanceRuleResult(
      status: 'half day',
      requiredPunchOutAt: standardShiftEnd,
      label: 'Half Day',
    );
  }

  if (minutesSinceMidnight <= graceEndMinutes) {
    return ShiftAttendanceRuleResult(
      status: 'present',
      requiredPunchOutAt: standardShiftEnd,
      label: 'Present',
    );
  }

  if (minutesSinceMidnight > graceEndMinutes &&
      minutesSinceMidnight < halfDayStartMinutes) {
    return ShiftAttendanceRuleResult(
      status: 'late',
      requiredPunchOutAt: officeNow.add(const Duration(hours: 9)),
      label: 'Late',
    );
  }

  return ShiftAttendanceRuleResult(
    status: minutesSinceMidnight < shiftStartMinutes ? 'present' : 'half day',
    requiredPunchOutAt:
        minutesSinceMidnight < shiftStartMinutes
            ? standardShiftEnd
            : standardShiftEnd,
    label: minutesSinceMidnight < shiftStartMinutes ? 'Present' : 'Half Day',
  );
}

class OfficeWifiSessionState {
  final bool isConnectedToOfficeWifi;
  final String? wifiName;
  final DateTime? connectedAt;
  final DateTime? attendanceMarkedAt;
  final DateTime? disconnectedAt;
  final String? todayAttendanceId;

  const OfficeWifiSessionState({
    required this.isConnectedToOfficeWifi,
    this.wifiName,
    this.connectedAt,
    this.attendanceMarkedAt,
    this.disconnectedAt,
    this.todayAttendanceId,
  });

  OfficeWifiSessionState copyWith({
    bool? isConnectedToOfficeWifi,
    String? wifiName,
    DateTime? connectedAt,
    bool clearConnectedAt = false,
    DateTime? attendanceMarkedAt,
    bool clearAttendanceMarkedAt = false,
    DateTime? disconnectedAt,
    bool clearDisconnectedAt = false,
    String? todayAttendanceId,
    bool clearTodayAttendanceId = false,
  }) {
    return OfficeWifiSessionState(
      isConnectedToOfficeWifi:
          isConnectedToOfficeWifi ?? this.isConnectedToOfficeWifi,
      wifiName: wifiName ?? this.wifiName,
      connectedAt: clearConnectedAt ? null : (connectedAt ?? this.connectedAt),
      attendanceMarkedAt: clearAttendanceMarkedAt
          ? null
          : (attendanceMarkedAt ?? this.attendanceMarkedAt),
      disconnectedAt: clearDisconnectedAt
          ? null
          : (disconnectedAt ?? this.disconnectedAt),
      todayAttendanceId: clearTodayAttendanceId
          ? null
          : (todayAttendanceId ?? this.todayAttendanceId),
    );
  }
}

final officeWifiSessionProvider = AsyncNotifierProvider<
  OfficeWifiSessionController,
  OfficeWifiSessionState
>(OfficeWifiSessionController.new);

class OfficeWifiSessionController extends AsyncNotifier<OfficeWifiSessionState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  Future<OfficeWifiSessionState> build() async {
    final state = await _loadSessionState();
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen((_) {
      unawaited(_refreshSession());
    });
    ref.onDispose(() {
      _connectivitySub?.cancel();
      _connectivitySub = null;
    });
    return state;
  }

  Future<void> refresh() => _refreshSession(forceReconnectTimestamp: true);

  Future<void> registerAttendanceMarked({
    required String attendanceId,
    required DateTime markedAt,
    required DateTime connectedAt,
    required String? wifiName,
  }) async {
    final current = state.valueOrNull ??
        const OfficeWifiSessionState(isConnectedToOfficeWifi: false);

    state = AsyncData(
      current.copyWith(
        isConnectedToOfficeWifi: true,
        wifiName: wifiName,
        connectedAt: connectedAt,
        attendanceMarkedAt: markedAt,
        disconnectedAt: null,
        todayAttendanceId: attendanceId,
      ),
    );
  }

  Future<void> punchOut() async {
    final todayAttendance = await _loadTodayAttendance();
    if (todayAttendance == null) {
      throw Exception('Attendance not marked for today');
    }
    if (todayAttendance.checkOut != null && todayAttendance.checkOut!.isNotEmpty) {
      throw Exception('Punch out already marked');
    }

    final now = DateTime.now();
    final db = AppwriteService.instance.databases;
    await db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.attendanceCollectionId,
      documentId: todayAttendance.id,
      data: {
        'checkOut': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    );

    final current = state.valueOrNull ??
        const OfficeWifiSessionState(isConnectedToOfficeWifi: false);
    state = AsyncData(
      current.copyWith(
        attendanceMarkedAt:
            todayAttendance.checkIn == null ? null : DateTime.tryParse(todayAttendance.checkIn!),
        disconnectedAt: current.disconnectedAt,
        todayAttendanceId: todayAttendance.id,
      ),
    );
  }

  Future<void> _refreshSession({bool forceReconnectTimestamp = false}) async {
    ref.invalidate(currentWifiNameProvider);
    ref.invalidate(canMarkWifiAttendanceProvider);
    final previous = state.valueOrNull;
    final next = await _loadSessionState(
      previous: previous,
      forceReconnectTimestamp: forceReconnectTimestamp,
    );
    state = AsyncData(next);
  }

  Future<OfficeWifiSessionState> _loadSessionState({
    OfficeWifiSessionState? previous,
    bool forceReconnectTimestamp = false,
  }) async {
    final allowedSsids = await ref.read(officeWifiSsidsProvider.future);
    final wifiName = await ref.read(currentWifiNameProvider.future);
    final todayAttendance = await _loadTodayAttendance();
    final isOfficeWifi =
        wifiName != null &&
        allowedSsids.any(
          (ssid) => ssid.toLowerCase() == wifiName.toLowerCase(),
        );

    final recordedConnectedAt = todayAttendance?.wifiConnectedAt == null
        ? null
        : DateTime.tryParse(todayAttendance!.wifiConnectedAt!);
    final recordedMarkedAt = todayAttendance?.checkIn == null
        ? null
        : DateTime.tryParse(todayAttendance!.checkIn!);
    final recordedDisconnectedAt = todayAttendance?.wifiDisconnectedAt == null
        ? null
        : DateTime.tryParse(todayAttendance!.wifiDisconnectedAt!);
    final recordedReconnectedAt = todayAttendance?.wifiReconnectedAt == null
        ? null
        : DateTime.tryParse(todayAttendance!.wifiReconnectedAt!);

    final now = DateTime.now();
    DateTime? connectedAt = recordedConnectedAt ?? previous?.connectedAt;
    DateTime? disconnectedAt = recordedDisconnectedAt ?? previous?.disconnectedAt;

    if (isOfficeWifi) {
      if (forceReconnectTimestamp ||
          previous == null ||
          previous.isConnectedToOfficeWifi == false) {
        final hasDisconnectedBefore =
            recordedDisconnectedAt != null || previous?.disconnectedAt != null;
        connectedAt = hasDisconnectedBefore
            ? (recordedReconnectedAt ?? now)
            : (recordedConnectedAt ?? now);
        disconnectedAt = recordedDisconnectedAt;
        final attendanceId = todayAttendance?.id ?? previous?.todayAttendanceId;
        if (attendanceId != null &&
            hasDisconnectedBefore &&
            recordedReconnectedAt == null) {
          await _saveWifiMovement(
            attendanceId: attendanceId,
            connectedAt: recordedConnectedAt ?? connectedAt!,
            wifiName: wifiName,
            requiredPunchOutAt:
                todayAttendance?.requiredPunchOutAt == null
                    ? null
                    : DateTime.tryParse(todayAttendance!.requiredPunchOutAt!),
            disconnectedAt: recordedDisconnectedAt,
            reconnectedAt: connectedAt,
          );
        }
      }
    } else if (previous?.isConnectedToOfficeWifi == true) {
      disconnectedAt = recordedDisconnectedAt ?? now;
      final attendanceId = todayAttendance?.id ?? previous?.todayAttendanceId;
      if (attendanceId != null && recordedDisconnectedAt == null) {
        await _saveWifiMovement(
          attendanceId: attendanceId,
          connectedAt: recordedConnectedAt ?? previous?.connectedAt ?? now,
          wifiName: previous?.wifiName,
          requiredPunchOutAt:
              todayAttendance?.requiredPunchOutAt == null
                  ? null
                  : DateTime.tryParse(todayAttendance!.requiredPunchOutAt!),
          disconnectedAt: disconnectedAt,
          reconnectedAt: recordedReconnectedAt,
        );
      }
    }

    return OfficeWifiSessionState(
      isConnectedToOfficeWifi: isOfficeWifi,
      wifiName: isOfficeWifi ? wifiName : null,
      connectedAt: connectedAt,
      attendanceMarkedAt: recordedMarkedAt ?? previous?.attendanceMarkedAt,
      disconnectedAt: isOfficeWifi ? recordedDisconnectedAt : disconnectedAt,
      todayAttendanceId: todayAttendance?.id ?? previous?.todayAttendanceId,
    );
  }

  Future<AttendanceRecord?> _loadTodayAttendance() async {
    final profile = await ref.read(employeeProfileProvider.future);
    if (profile == null) return null;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final db = AppwriteService.instance.databases;

    final result = await db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.attendanceCollectionId,
      queries: [
        Query.equal('employeeId', profile.id),
        Query.greaterThanEqual('date', startOfDay.toIso8601String()),
        Query.lessThanEqual('date', endOfDay.toIso8601String()),
        Query.limit(1),
        Query.orderDesc('date'),
      ],
    );

    if (result.documents.isEmpty) return null;
    final doc = result.documents.first;
    return AttendanceRecord.fromJson(doc.data, docId: doc.$id);
  }

  Future<void> _saveWifiMovement({
    required String attendanceId,
    required DateTime connectedAt,
    required String? wifiName,
    required DateTime? requiredPunchOutAt,
    DateTime? disconnectedAt,
    DateTime? reconnectedAt,
  }) async {
    final db = AppwriteService.instance.databases;
    await db.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.attendanceCollectionId,
      documentId: attendanceId,
      data: {
        'remarks': _buildAttendanceRemarks(
          connectedAt: connectedAt,
          wifiName: wifiName,
          requiredPunchOutAt: requiredPunchOutAt ?? connectedAt,
          disconnectedAt: disconnectedAt,
          reconnectedAt: reconnectedAt,
        ),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }
}

final officeWifiSsidsProvider = FutureProvider<List<String>>((ref) async {
  final db = AppwriteService.instance.databases;
  final response = await db.listDocuments(
    databaseId: AppwriteConfig.databaseId,
    collectionId: AppwriteConfig.companySettingsCollectionId,
    queries: [
      Query.equal('key', 'office_wifi_ssids'),
      Query.limit(1),
    ],
  );

  if (response.documents.isEmpty) return const [];
  final rawValue = response.documents.first.data['value']?.toString() ?? '';
  return rawValue
      .split(RegExp(r'[\n,]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
});

final currentWifiNameProvider = FutureProvider<String?>((ref) async {
  final connectivity = await Connectivity().checkConnectivity();
  if (!connectivity.contains(ConnectivityResult.wifi)) {
    return null;
  }

  final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isLocationEnabled) {
    return null;
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  final info = NetworkInfo();
  final wifiName = await info.getWifiName();
  if (wifiName == null) return null;
  return wifiName.replaceAll('"', '').trim();
});

final canMarkWifiAttendanceProvider = FutureProvider<bool>((ref) async {
  final allowedSsids = await ref.watch(officeWifiSsidsProvider.future);
  final wifiName = await ref.watch(currentWifiNameProvider.future);
  if (wifiName == null || allowedSsids.isEmpty) return false;
  return allowedSsids.any(
    (ssid) => ssid.toLowerCase() == wifiName.toLowerCase(),
  );
});

final attendanceActionProvider = Provider<AttendanceActionService>((ref) {
  return AttendanceActionService(ref);
});

class AttendanceActionService {
  final Ref _ref;

  AttendanceActionService(this._ref);

  Future<void> markAttendanceFromEmployeeApp() async {
    final profile = await _ref.read(employeeProfileProvider.future);
    final auth = _ref.read(authProvider);
    final canMark = await _ref.read(canMarkWifiAttendanceProvider.future);
    final wifiName = await _ref.read(currentWifiNameProvider.future);
    final officeWifiSession = _ref.read(officeWifiSessionProvider).valueOrNull;

    if (!canMark) {
      throw Exception('Connect to the configured office Wi-Fi to mark attendance');
    }
    if (profile == null) {
      throw Exception('Employee profile not found');
    }

    final now = DateTime.now();
    final shiftRule = _evaluateShiftAttendance(now);
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final db = AppwriteService.instance.databases;

    final existing = await db.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.attendanceCollectionId,
      queries: [
        Query.equal('employeeId', profile.id),
        Query.greaterThanEqual('date', startOfDay.toIso8601String()),
        Query.lessThanEqual('date', endOfDay.toIso8601String()),
        Query.limit(1),
      ],
    );

    if (existing.documents.isNotEmpty) {
      throw Exception('Attendance already marked for today');
    }

    final connectedAt = officeWifiSession?.connectedAt ?? now;
    final response = await db.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.attendanceCollectionId,
      documentId: ID.unique(),
      data: {
        'employeeId': profile.id,
        'employeeCode': profile.employeeCode,
        'date': now.toIso8601String(),
        'status': shiftRule.status,
        'checkIn': now.toIso8601String(),
        'hoursWorked': 0.0,
        'overtimeHours': 0.0,
        'remarks': _buildAttendanceRemarks(
          connectedAt: connectedAt,
          wifiName: wifiName,
          requiredPunchOutAt: shiftRule.requiredPunchOutAt,
          attendanceRuleStatus: shiftRule.status,
          ruleEvaluatedAt: now,
        ),
        'location': wifiName ?? 'Office Wi-Fi',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': auth.user?.userId,
      },
    );

    final savedStatus = response.data['status']?.toString();
    if (savedStatus != shiftRule.status) {
      await db.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.attendanceCollectionId,
        documentId: response.$id,
        data: {
          'status': shiftRule.status,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    }

    await _ref
        .read(officeWifiSessionProvider.notifier)
        .registerAttendanceMarked(
          attendanceId: response.$id,
          markedAt: now,
          connectedAt: connectedAt,
          wifiName: wifiName,
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
