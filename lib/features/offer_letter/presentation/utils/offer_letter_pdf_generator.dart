import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/models/offer_letter_model.dart';

/// Generates a professional offer letter PDF matching the company format
class OfferLetterPdfGenerator {
  OfferLetterPdfGenerator._();

  // Company details
  static const _companyName = 'M/s DOON INFRAPOWER PROJECTS PVT. LTD.';
  static const _gst = 'GST No. 08AAGCD1602E1Z7';
  static const _address =
      'Office Add - 711, Doon Enclave, Vidhyadhar Nagar, Jaipur, 302039';
  static const _email = 'info@dooninfra.in';
  static const _phone = '9660041866';
  static const _tagline =
      'Transformer Manufacturing, Repairing & Solar EPC Company';

  /// Generate and save PDF to file
  static Future<File> generateAndSave(
    OfferLetter letter, {
    required String outputPath,
    String? reportingManager,
    String? employeeAddress,
    double? basic,
    double? hra,
    double? sa,
  }) async {
    final pdfDoc = await _buildPdf(
      letter,
      reportingManager: reportingManager,
      employeeAddress: employeeAddress,
      basic: basic,
      hra: hra,
      sa: sa,
    );
    final bytes = await pdfDoc.save();
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Generate and print/preview PDF
  static Future<void> printPreview(
    OfferLetter letter, {
    String? reportingManager,
    String? employeeAddress,
    double? basic,
    double? hra,
    double? sa,
  }) async {
    final pdfDoc = await _buildPdf(
      letter,
      reportingManager: reportingManager,
      employeeAddress: employeeAddress,
      basic: basic,
      hra: hra,
      sa: sa,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => pdfDoc.save(),
      name: 'Offer_Letter_${letter.employeeName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Build the PDF document
  static Future<pw.Document> _buildPdf(
    OfferLetter letter, {
    String? reportingManager,
    String? employeeAddress,
    double? basic,
    double? hra,
    double? sa,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dayMonth = DateFormat("d'-'MMM'-'yy");

    // Load Google Font for Unicode support (₹ symbol, – etc.)
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    // Load Seal Image
    final sealImage = await imageFromAssetBundle('assets/images/seal_signature.jpg');

    // Calculate salary components from CTC
    final ctc = letter.ctc;
    final basicSalary = basic ?? (ctc * 0.50);
    final hraSalary = hra ?? (ctc * 0.25);
    final saSalary = sa ?? (ctc - basicSalary - hraSalary);
    final gross = basicSalary + hraSalary + saSalary;
    final pfEmployee = (basicSalary * 0.12).roundToDouble();
    final esicEmployee = (gross * 0.0075).roundToDouble();
    final totalDeductions = pfEmployee + esicEmployee;
    final netPay = gross - totalDeductions;
    final pfEmployer = (basicSalary * 0.13).roundToDouble();
    final esicEmployer = (gross * 0.0325).roundToDouble();
    final totalEmployerDeductions = pfEmployer + esicEmployer;
    final costToCompany = gross + totalEmployerDeductions;

    // Reference number
    final refNo =
        'DIP/${letter.joiningDate.year % 100}-${(letter.joiningDate.year + 1) % 100}/${letter.employeeCode.replaceAll('EMP', '')}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => _buildHeader(),
        build: (context) => [
          // Reference
          pw.Text(
            'Ref. $refNo',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Date: ${dateFormat.format(letter.joiningDate)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 14),

          // To
          pw.Text('To,', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            letter.employeeName,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          if (employeeAddress != null && employeeAddress.isNotEmpty)
            pw.Text(employeeAddress, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 14),

          // Subject
          pw.RichText(
            text: pw.TextSpan(
              text: 'Subject: ',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              children: [
                pw.TextSpan(
                  text: 'Offer of Employment',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Text(
            'Dear ${letter.employeeName.split(' ').first},',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),

          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 10),
              children: [
                const pw.TextSpan(
                  text: 'We are pleased to offer you the position of ',
                ),
                pw.TextSpan(
                  text: '${letter.designation} ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                const pw.TextSpan(text: 'at '),
                pw.TextSpan(
                  text: 'Doon Infrapower Projects Pvt. Ltd.',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                const pw.TextSpan(
                  text: ', under the following terms and conditions:',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // 1. Commencement of Employment
          _sectionTitle('1. Commencement of Employment'),
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 10),
              children: [
                const pw.TextSpan(text: 'Your employment will commence from '),
                pw.TextSpan(
                  text: '${dayMonth.format(letter.joiningDate)}.',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // 2. Job Title & Reporting
          _sectionTitle('2. Job Title & Reporting'),
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 10),
              children: [
                const pw.TextSpan(text: 'Your designation will be '),
                pw.TextSpan(
                  text: letter.designation,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                if (reportingManager != null) ...[
                  const pw.TextSpan(text: ' reporting to the '),
                  pw.TextSpan(
                    text: '$reportingManager.',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // 3. Salary & Benefits
          _sectionTitle('3. Salary & Benefits'),
          pw.Bullet(
            text:
                'Your Cost to Company (CTC) will be ₹ ${ctc.toInt().toString()}/- per month, as detailed in Annexure-A.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'For field/site employees, travel, food, and accommodation (if applicable) may be provided as per company norms.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          // 4. Place of Posting
          _sectionTitle('4. Place of Posting'),
          pw.Text(
            'Your initial posting will be at Jaipur Office. However, based on business requirements, you may be assigned duties at any project site, client location, or branch of the company.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          // 5. Probation & Confirmation
          _sectionTitle('5. Probation & Confirmation'),
          pw.Bullet(
            text:
                'You will be on probation for 3 months from your joining date.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'The Company reserves the right to extend the probation period based on performance.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'Upon successful completion, you will be issued a formal confirmation letter.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          // 6. Working Hours
          _sectionTitle('6. Working Hours'),
          pw.Bullet(
            text:
                'Normal office hours are 9:00 AM – 6:00 PM, Monday to Saturday.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'For field/site employees, working hours may vary depending on project/tender/client requirements/performance.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'You may be required to work additional hours/weekends as per business needs.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          // 7. Leave Policy & Weekly Offs
          _sectionTitle('7. Leave Policy & Weekly Offs'),
          pw.Bullet(
            text:
                'Office Employees: Entitled to 12 Casual Leaves annually (after confirmation) and weekly offs as per company calendar (generally Sundays or 4 per month).',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'Field / Site / Sales Employees: Weekly offs and leave entitlements will be governed by project requirements, client schedules, and management instructions.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          // 8. Salary Increment
          _sectionTitle('8. Salary Increment'),
          pw.Bullet(
            text:
                'Increment will depend on individual and departmental performance.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'After 12 months of service, increment will normally range between 5-10% of CTC.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          // 9. Company Property
          _sectionTitle('9. Company Property'),
          pw.Bullet(
            text:
                'Any property issued (documents, laptop, mobile, ID card, tools, etc.) must be properly maintained and returned upon exit.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text: 'Any loss or damage will be recovered from your dues.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          // 10. Termination & Notice Period
          _sectionTitle('10. Termination & Notice Period'),
          pw.Bullet(
            text:
                'During probation: Either party may terminate employment with 7 days\' written notice or salary in lieu thereof.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'After confirmation: Either party may terminate employment with 30 days\' written notice or salary in lieu thereof.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'The Company reserves the right to terminate your services immediately without notice in case of misconduct, breach of confidentiality, or gross negligence.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'Full & Final Settlement will be processed within 45 days of exit.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          // 11. Confidentiality & NDA
          _sectionTitle('11. Confidentiality & NDA Clause'),
          pw.Bullet(
            text:
                'You shall maintain strict confidentiality regarding all company, client, vendor, and project-related information.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'You shall not, during or after employment, disclose, misuse, or exploit any confidential data for personal or third party benefit.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'Any breach of confidentiality will be treated as serious misconduct and may lead to immediate termination and legal action under applicable laws.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Bullet(
            text:
                'This Non-Disclosure Agreement (NDA) remains binding even after you leave the Company.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 14),

          // Closing
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 10),
              children: [
                const pw.TextSpan(
                  text:
                      'We look forward to your valuable contribution in strengthening ',
                ),
                pw.TextSpan(
                  text: "Doon Infra's Solar EPC & Sales operations",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                const pw.TextSpan(
                  text:
                      '. Please sign and return a copy of this letter as a token of your acceptance.',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'For Doon Infrapower Projects Pvt. Ltd.',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('HR Department', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),
          // Seal and Signature
          pw.Image(sealImage, width: 120),
          pw.SizedBox(height: 10),

          // Candidate's Acceptance
          pw.Text(
            "Candidate's Acknowledgment & Acceptance",
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'I, _________________________ , accept the terms and conditions mentioned in this offer letter and agree to join the organization on the specified date.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 30),

          // Annexure A - Salary Breakup
          pw.Header(level: 2, text: 'Annexure – A: Salary Breakup'),
          pw.SizedBox(height: 8),
          _buildSalaryTable(
            basic: basicSalary,
            hra: hraSalary,
            sa: saSalary,
            gross: gross,
            pfEmployee: pfEmployee,
            esicEmployee: esicEmployee,
            totalDeductions: totalDeductions,
            netPay: netPay,
            pfEmployer: pfEmployer,
            esicEmployer: esicEmployer,
            totalEmployerDeductions: totalEmployerDeductions,
            costToCompany: costToCompany,
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _companyName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(_address, style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(
                    'Email ID - $_email  Mob No. $_phone',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(_tagline, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.Text(_gst, style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 1.5),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildSalaryTable({
    required double basic,
    required double hra,
    required double sa,
    required double gross,
    required double pfEmployee,
    required double esicEmployee,
    required double totalDeductions,
    required double netPay,
    required double pfEmployer,
    required double esicEmployer,
    required double totalEmployerDeductions,
    required double costToCompany,
  }) {
    final rows = [
      _SalaryRow('1', 'BASIC', basic, false),
      _SalaryRow('2', 'HRA', hra, false),
      _SalaryRow('3', 'SA', sa, false),
      _SalaryRow('4', 'GROSS SALARY', gross, true),
      _SalaryRow('5', 'PF share employee', pfEmployee, false),
      _SalaryRow('6', 'ESIC employee', esicEmployee, false),
      _SalaryRow('7', 'TOTAL EMPLOYEE DEDUCTION', totalDeductions, false),
      _SalaryRow('8', 'NET PAY IN HAND (A-B)', netPay, true),
      _SalaryRow('9', 'PF share employer', pfEmployer, false),
      _SalaryRow('10', 'ESIC employer', esicEmployer, false),
      _SalaryRow(
        '11',
        'Total employer deduction©',
        totalEmployerDeductions,
        false,
      ),
      _SalaryRow('12', 'COST OF COMPANY IN RUPEES(A+C)', costToCompany, true),
    ];

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(80),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFD9EAD3),
          ),
          children: [
            _tableHeaderCell('Sno.'),
            _tableHeaderCell(''),
            _tableHeaderCell('Monthly'),
            _tableHeaderCell('Yearly'),
          ],
        ),
        // Data rows
        ...rows.map((row) {
          return pw.TableRow(
            decoration: row.isHighlighted
                ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFF2CC))
                : null,
            children: [
              _tableCell(row.sno, center: true),
              _tableCell(row.label, bold: row.isHighlighted),
              _tableCell(
                row.monthly.toInt().toString(),
                center: true,
                bold: row.isHighlighted,
              ),
              _tableCell(
                (row.monthly * 12).toInt().toString(),
                center: true,
                bold: row.isHighlighted,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool center = false,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

class _SalaryRow {
  final String sno;
  final String label;
  final double monthly;
  final bool isHighlighted;

  const _SalaryRow(this.sno, this.label, this.monthly, this.isHighlighted);
}
