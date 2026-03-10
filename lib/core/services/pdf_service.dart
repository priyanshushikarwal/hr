import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

/// PDF Generation Service for salary slips, offer letters, and reports
class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  final _currencyFormat = NumberFormat('#,##,###.00', 'en_IN');

  /// Generate Salary Slip PDF
  Future<String?> generateSalarySlip({
    required Map<String, dynamic> employee,
    required Map<String, dynamic> salary,
    required Map<String, dynamic> payment,
    Map<String, dynamic>? company,
  }) async {
    final pdf = pw.Document();
    final companyName = company?['name'] ?? 'Company Name';
    final companyAddress = company?['address'] ?? '';
    final month = payment['month'] ?? '';
    final year = payment['year'] ?? '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey800),
                  color: PdfColors.blue50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (companyAddress.isNotEmpty)
                          pw.Text(
                            companyAddress,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'SALARY SLIP',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '$month $year',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Employee Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: _pdfLabelValue(
                        'Employee Name',
                        '${employee['firstName'] ?? ''} ${employee['lastName'] ?? ''}',
                      ),
                    ),
                    pw.Expanded(
                      child: _pdfLabelValue(
                        'Employee Code',
                        employee['employeeCode'] ?? '',
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: _pdfLabelValue(
                        'Department',
                        employee['department'] ?? '',
                      ),
                    ),
                    pw.Expanded(
                      child: _pdfLabelValue(
                        'Designation',
                        employee['designation'] ?? '',
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: _pdfLabelValue(
                        'Bank Account',
                        employee['bankAccountNumber'] ?? 'N/A',
                      ),
                    ),
                    pw.Expanded(
                      child: _pdfLabelValue(
                        'PAN',
                        employee['panNumber'] ?? 'N/A',
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Salary Breakdown Table
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Earnings
                  pw.Expanded(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Container(
                            color: PdfColors.green50,
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'EARNINGS',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          _pdfSalaryRow('Basic Salary', salary['basicSalary']),
                          _pdfSalaryRow('HRA', salary['hra']),
                          _pdfSalaryRow('DA', salary['da']),
                          _pdfSalaryRow(
                            'Conveyance',
                            salary['conveyanceAllowance'],
                          ),
                          _pdfSalaryRow('Medical', salary['medicalAllowance']),
                          _pdfSalaryRow('Special', salary['specialAllowance']),
                          _pdfSalaryRow('Other', salary['otherAllowance']),
                          pw.Divider(),
                          _pdfSalaryRow(
                            'Gross Salary',
                            salary['grossSalary'],
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  // Deductions
                  pw.Expanded(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Container(
                            color: PdfColors.red50,
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'DEDUCTIONS',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          _pdfSalaryRow('PF (Employee)', salary['pfEmployee']),
                          _pdfSalaryRow(
                            'ESIC (Employee)',
                            salary['esicEmployee'],
                          ),
                          _pdfSalaryRow(
                            'Professional Tax',
                            salary['professionalTax'],
                          ),
                          _pdfSalaryRow('TDS', salary['tds']),
                          _pdfSalaryRow('Advance', salary['advanceDeduction']),
                          _pdfSalaryRow('Loan EMI', salary['loanDeduction']),
                          _pdfSalaryRow('Other', salary['otherDeduction']),
                          pw.Divider(),
                          _pdfSalaryRow(
                            'Total Deductions',
                            salary['totalDeductions'],
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Net Pay
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue800, width: 2),
                  color: PdfColors.blue50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'NET PAY',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '₹ ${_currencyFormat.format(salary['netSalary'] ?? 0)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Payment Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: _pdfLabelValue(
                        'Payment Mode',
                        payment['paymentMode'] ?? 'Bank Transfer',
                      ),
                    ),
                    pw.Expanded(
                      child: _pdfLabelValue(
                        'Transaction No.',
                        payment['transactionNumber'] ?? 'N/A',
                      ),
                    ),
                    pw.Expanded(
                      child: _pdfLabelValue(
                        'Payment Date',
                        payment['paymentDate'] ?? '',
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // Signature Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.grey800,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Employee Signature',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.grey800,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Signatory',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'This is a computer-generated document. No signature is required.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Ask for save location
    final empName =
        '${employee['firstName'] ?? 'employee'}_${employee['lastName'] ?? ''}';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Salary Slip',
      fileName: 'salary_slip_${empName}_${month}_$year.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (savePath == null) return null;

    final file = File(savePath);
    await file.writeAsBytes(await pdf.save());
    return savePath;
  }

  /// Generate Offer Letter PDF
  Future<String?> generateOfferLetter({
    required Map<String, dynamic> employee,
    required Map<String, dynamic> salary,
    Map<String, dynamic>? company,
  }) async {
    final pdf = pw.Document();
    final companyName = company?['name'] ?? 'Company Name';
    final companyAddress = company?['address'] ?? '';
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM, yyyy').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          // Letterhead
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    if (companyAddress.isNotEmpty)
                      pw.Text(
                        companyAddress,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Date
          pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 16),

          // To
          pw.Text('To,', style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            '${employee['firstName'] ?? ''} ${employee['lastName'] ?? ''}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 24),

          // Subject
          pw.Text(
            'Subject: Offer of Employment',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 16),

          // Body
          pw.Text(
            'Dear ${employee['firstName'] ?? 'Candidate'},',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'We are pleased to offer you the position of ${employee['designation'] ?? 'Associate'} in the ${employee['department'] ?? 'General'} department at $companyName. We believe your skills and experience will be a valuable asset to our organization.',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'The details of your employment are as follows:',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 16),

          // Employment Details Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              _offerTableRow('Position', employee['designation'] ?? ''),
              _offerTableRow('Department', employee['department'] ?? ''),
              _offerTableRow('Employment Type', employee['employeeType'] ?? ''),
              _offerTableRow('Joining Date', employee['joiningDate'] ?? ''),
              _offerTableRow(
                'Gross Salary (Monthly)',
                '₹ ${_currencyFormat.format(salary['grossSalary'] ?? 0)}',
              ),
              _offerTableRow(
                'CTC (Annual)',
                '₹ ${_currencyFormat.format((salary['grossSalary'] ?? 0) * 12)}',
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Terms
          pw.Text(
            'Terms and Conditions:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _bulletPoint(
            'This offer is valid for 7 days from the date of this letter.',
          ),
          _bulletPoint(
            'You will be on probation for the first 6 months from the date of joining.',
          ),
          _bulletPoint(
            'Your employment is subject to satisfactory verification of your documents and references.',
          ),
          _bulletPoint(
            'You are required to maintain confidentiality regarding all company information.',
          ),
          _bulletPoint(
            'Either party may terminate this agreement with one month\'s written notice.',
          ),
          pw.SizedBox(height: 24),

          pw.Text(
            'We look forward to welcoming you to our team.',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Warm Regards,', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 40),
          pw.Container(width: 150, height: 1, color: PdfColors.grey800),
          pw.Text('HR Manager', style: const pw.TextStyle(fontSize: 11)),
          pw.Text(companyName, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );

    final empName =
        '${employee['firstName'] ?? 'candidate'}_${employee['lastName'] ?? ''}';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Offer Letter',
      fileName: 'offer_letter_$empName.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (savePath == null) return null;

    final file = File(savePath);
    await file.writeAsBytes(await pdf.save());
    return savePath;
  }

  /// Preview PDF in print dialog
  Future<void> previewPdf(
    pw.Document pdf, {
    String title = 'PDF Preview',
  }) async {
    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: title);
  }

  // Helper methods
  pw.Widget _pdfLabelValue(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  pw.Widget _pdfSalaryRow(String label, dynamic amount, {bool bold = false}) {
    final amtStr =
        '₹ ${_currencyFormat.format((amount as num?)?.toDouble() ?? 0)}';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            amtStr,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.TableRow _offerTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  pw.Widget _bulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
