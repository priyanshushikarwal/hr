import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../employees/data/models/employee_model.dart';

/// Salary Slip data bundle
class SalarySlipData {
  final Employee employee;
  final int month;
  final int year;
  final int paidDays;
  final int monthDays;
  final int remainingLeave;
  final String payMode;
  final String branchName;

  // Earnings
  final double basicPay;
  final double hra;
  final double specialAllowance;
  final double otherEarnings;

  // Deductions
  final double pfEmployee;
  final double esic;
  final double otherDeduction;
  final double advance;

  SalarySlipData({
    required this.employee,
    required this.month,
    required this.year,
    required this.paidDays,
    required this.monthDays,
    this.remainingLeave = 0,
    this.payMode = 'NEFT',
    this.branchName = '-',
    required this.basicPay,
    required this.hra,
    required this.specialAllowance,
    this.otherEarnings = 0,
    this.pfEmployee = 0,
    this.esic = 0,
    this.otherDeduction = 0,
    this.advance = 0,
  });

  double get totalEarnings => basicPay + hra + specialAllowance + otherEarnings;
  double get totalDeductions => pfEmployee + esic + otherDeduction + advance;
  double get netAmount => totalEarnings - totalDeductions;
}

/// Generate the salary slip PDF matching the company format
class SalarySlipPdfGenerator {
  SalarySlipPdfGenerator._();

  static const _companyName = 'Doon Infrapower Projects Pvt.Ltd.';
  static const _address =
      '711, DOON ENCLAVE, VIDHYADHAR NAGAR, SECTOR 1,\nJAIPUR (302039)';

  /// Generate and open the print/preview dialog
  static Future<void> printPreview(SalarySlipData data) async {
    final pdfDoc = await _buildPdf(data);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfDoc.save(),
      name:
          'Salary_Slip_${data.employee.fullName.replaceAll(' ', '_')}_${_getMonthName(data.month)}_${data.year}.pdf',
    );
  }

  /// Generate and save to file
  static Future<File> generateAndSave(
    SalarySlipData data,
    String outputPath,
  ) async {
    final pdfDoc = await _buildPdf(data);
    final bytes = await pdfDoc.save();
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<pw.Document> _buildPdf(SalarySlipData data) async {
    final doc = pw.Document();
    final emp = data.employee;
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Load Google Font for Unicode support (₹ symbol, etc.)
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontItalic = await PdfGoogleFonts.notoSansItalic();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // == Company Header ==
              pw.Text(
                _companyName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _address,
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 8),

              // == Title ==
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Text(
                  'Monthly Salary Slip - ${_getMonthName(data.month)} ${data.year}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // == Employee Details Table ==
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.3),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  _detailRow(
                    'Reg. No.',
                    emp.employeeCode,
                    'Branch Name',
                    data.branchName,
                  ),
                  _detailRow(
                    'Employee Name',
                    emp.fullName,
                    'Date Of Birth',
                    emp.dateOfBirth != null
                        ? dateFormat.format(emp.dateOfBirth!)
                        : '-',
                  ),
                  _detailRow(
                    'Bank Name',
                    emp.bankName ?? '-',
                    'Joining Date',
                    dateFormat.format(emp.joiningDate),
                  ),
                  _detailRow(
                    'Bank A/C No.',
                    emp.bankAccountNumber ?? '-',
                    'IFSC',
                    emp.ifscCode ?? '-',
                  ),
                  _detailRow(
                    'Pay Mode',
                    data.payMode,
                    'ESIC Number',
                    emp.esicNumber ?? '-',
                  ),
                  _detailRow(
                    'Department',
                    emp.department,
                    'UAN No.',
                    emp.uan ?? '-',
                  ),
                  _detailRow(
                    'Paid Days',
                    data.paidDays.toString(),
                    'Month Days',
                    data.monthDays.toString(),
                  ),
                  _detailRow(
                    'Remaining Leave',
                    data.remainingLeave.toString(),
                    'Designation',
                    emp.designation,
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // == Earnings & Deductions Table ==
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE8E8E8),
                    ),
                    children: [
                      _headerCell('Earnings'),
                      _headerCell('Rs'),
                      _headerCell('Deductions'),
                      _headerCell('Rs'),
                    ],
                  ),
                  _earningsDeductionsRow(
                    'Basic Pay',
                    data.basicPay,
                    'P F Employee',
                    data.pfEmployee,
                  ),
                  _earningsDeductionsRow('HRA', data.hra, 'ESIC', data.esic),
                  _earningsDeductionsRow(
                    'Special Allowance',
                    data.specialAllowance,
                    'Other – Advance',
                    data.advance,
                  ),
                  _earningsDeductionsRow(
                    'Other',
                    data.otherEarnings,
                    '',
                    0,
                    hideRight: data.otherDeduction == 0,
                  ),
                  // Totals
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE8E8E8),
                    ),
                    children: [
                      _boldCell('Total Earning in Rs'),
                      _boldCell(data.totalEarnings.toInt().toString()),
                      _boldCell('Total Deduction In Rs.'),
                      _boldCell(data.totalDeductions.toInt().toString()),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // == Net Amount ==
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Net Amount:   ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${data.netAmount.toInt()}/-',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // == In Words ==
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'In Words:   ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${_numberToWords(data.netAmount.toInt())} Only.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  static pw.TableRow _detailRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return pw.TableRow(
      children: [
        _labelCell(label1),
        _valueCell(value1),
        _labelCell(label2),
        _valueCell(value2),
      ],
    );
  }

  static pw.Widget _labelCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _valueCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _boldCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.TableRow _earningsDeductionsRow(
    String earning,
    double earningVal,
    String deduction,
    double deductionVal, {
    bool hideRight = false,
  }) {
    return pw.TableRow(
      children: [
        _labelCell(earning),
        _valueCell(earningVal > 0 ? earningVal.toInt().toString() : '-'),
        _labelCell(deduction),
        _valueCell(
          hideRight
              ? ''
              : (deductionVal > 0 ? deductionVal.toInt().toString() : '-'),
        ),
      ],
    );
  }

  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// Convert number to words (Indian system)
  static String _numberToWords(int number) {
    if (number == 0) return 'Zero';

    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String convert(int n) {
      if (n < 20) return ones[n];
      if (n < 100) {
        return '${tens[n ~/ 10]}${n % 10 > 0 ? ' ${ones[n % 10]}' : ''}';
      }
      if (n < 1000) {
        return '${ones[n ~/ 100]} Hundred${n % 100 > 0 ? ' ${convert(n % 100)}' : ''}';
      }
      if (n < 100000) {
        return '${convert(n ~/ 1000)} Thousand${n % 1000 > 0 ? ' ${convert(n % 1000)}' : ''}';
      }
      if (n < 10000000) {
        return '${convert(n ~/ 100000)} Lakh${n % 100000 > 0 ? ' ${convert(n % 100000)}' : ''}';
      }
      return '${convert(n ~/ 10000000)} Crore${n % 10000000 > 0 ? ' ${convert(n % 10000000)}' : ''}';
    }

    return convert(number);
  }
}
