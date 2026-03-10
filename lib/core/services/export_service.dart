import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

/// Export service for generating Excel and CSV files
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// Export data to Excel file
  /// [headers] - Column headers
  /// [rows] - List of row data (each row is a list of cell values)
  /// [sheetName] - Name of the Excel sheet
  /// [defaultFileName] - Default file name for save dialog
  /// Returns the file path if saved, null if cancelled
  Future<String?> exportToExcel({
    required List<String> headers,
    required List<List<dynamic>> rows,
    String sheetName = 'Sheet1',
    required String defaultFileName,
  }) async {
    if (rows.isEmpty) {
      throw Exception('Cannot export empty data');
    }

    final excel = Excel.createExcel();
    final sheet = excel[sheetName];

    // Remove default sheet if it exists
    if (excel.getDefaultSheet() != sheetName) {
      excel.delete('Sheet1');
    }

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Add data rows
    for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      final rowData = rows[rowIdx];
      for (int colIdx = 0; colIdx < rowData.length; colIdx++) {
        final value = rowData[colIdx];
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx + 1),
        );
        if (value is int) {
          cell.value = IntCellValue(value);
        } else if (value is double) {
          cell.value = DoubleCellValue(value);
        } else if (value is DateTime) {
          cell.value = TextCellValue(DateFormat('dd/MM/yyyy').format(value));
        } else {
          cell.value = TextCellValue(value?.toString() ?? '');
        }
      }
    }

    // Let user pick save location
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Excel File',
      fileName: '$defaultFileName.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (savePath == null) return null;

    final fileBytes = excel.encode();
    if (fileBytes == null) throw Exception('Failed to encode Excel file');

    final file = File(savePath);
    await file.writeAsBytes(fileBytes);

    return savePath;
  }

  /// Export employees to Excel
  Future<String?> exportEmployees(List<Map<String, dynamic>> employees) async {
    final headers = [
      'Employee Code',
      'Full Name',
      'Email',
      'Phone',
      'Department',
      'Designation',
      'Employee Type',
      'Status',
      'Joining Date',
      'Gender',
      'Date of Birth',
    ];

    final rows = employees
        .map(
          (e) => [
            e['employeeCode'] ?? '',
            '${e['firstName'] ?? ''} ${e['lastName'] ?? ''}',
            e['email'] ?? '',
            e['phone'] ?? '',
            e['department'] ?? '',
            e['designation'] ?? '',
            e['employeeType'] ?? '',
            e['status'] ?? '',
            e['joiningDate'] ?? '',
            e['gender'] ?? '',
            e['dateOfBirth'] ?? '',
          ],
        )
        .toList();

    return exportToExcel(
      headers: headers,
      rows: rows,
      sheetName: 'Employees',
      defaultFileName:
          'employees_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  /// Export attendance to Excel
  Future<String?> exportAttendance(
    List<Map<String, dynamic>> records, {
    int? month,
    int? year,
  }) async {
    final monthStr = month != null
        ? DateFormat(
            'MMMM',
          ).format(DateTime(year ?? DateTime.now().year, month))
        : 'all';
    final yearStr = year?.toString() ?? DateTime.now().year.toString();

    final headers = [
      'Employee Code',
      'Employee Name',
      'Date',
      'Status',
      'Check In',
      'Check Out',
      'Hours Worked',
      'Overtime Hours',
      'Remarks',
    ];

    final rows = records
        .map(
          (r) => [
            r['employeeCode'] ?? '',
            r['employeeName'] ?? '',
            r['date'] ?? '',
            r['status'] ?? '',
            r['checkIn'] ?? '',
            r['checkOut'] ?? '',
            r['hoursWorked'] ?? 0.0,
            r['overtimeHours'] ?? 0.0,
            r['remarks'] ?? '',
          ],
        )
        .toList();

    return exportToExcel(
      headers: headers,
      rows: rows,
      sheetName: 'Attendance',
      defaultFileName: 'attendance_${monthStr}_$yearStr',
    );
  }

  /// Export salary register to Excel
  Future<String?> exportSalaryRegister(
    List<Map<String, dynamic>> salaries, {
    int? month,
    int? year,
  }) async {
    final headers = [
      'Employee Code',
      'Employee Name',
      'Basic',
      'HRA',
      'DA',
      'Gross',
      'PF Employee',
      'ESIC Employee',
      'TDS',
      'Total Deductions',
      'Net Salary',
    ];

    final rows = salaries
        .map(
          (s) => [
            s['employeeCode'] ?? '',
            s['employeeName'] ?? '',
            s['basicSalary'] ?? 0.0,
            s['hra'] ?? 0.0,
            s['da'] ?? 0.0,
            s['grossSalary'] ?? 0.0,
            s['pfEmployee'] ?? 0.0,
            s['esicEmployee'] ?? 0.0,
            s['tds'] ?? 0.0,
            s['totalDeductions'] ?? 0.0,
            s['netSalary'] ?? 0.0,
          ],
        )
        .toList();

    final monthStr = month != null
        ? DateFormat(
            'MMMM_yyyy',
          ).format(DateTime(year ?? DateTime.now().year, month))
        : 'all';

    return exportToExcel(
      headers: headers,
      rows: rows,
      sheetName: 'Salary Register',
      defaultFileName: 'salary_register_$monthStr',
    );
  }
}
