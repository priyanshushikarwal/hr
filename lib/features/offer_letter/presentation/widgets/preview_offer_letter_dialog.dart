import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/widgets/buttons.dart';
import '../../data/models/offer_letter_model.dart';
import '../utils/offer_letter_pdf_generator.dart';

/// Preview Offer Letter Dialog — shows the letter in a formatted view
class PreviewOfferLetterDialog extends StatelessWidget {
  final OfferLetter letter;

  const PreviewOfferLetterDialog({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final ctc = letter.ctc;
    final gross =
        (ctc /
                (1 +
                    (letter.isPfApplicable ? 0.072 : 0) +
                    (letter.isEsicApplicable ? 0.0325 : 0)))
            .round();
    final basic = (gross * 0.60).round();
    final hra = gross - basic;
    final pfEmp = letter.isPfApplicable ? (basic * 0.12).round() : 0;
    final esicEmp = letter.isEsicApplicable ? (gross * 0.0075).round() : 0;
    final totalDeductions = pfEmp + esicEmp;
    final netPay = gross - totalDeductions;
    final pfEmployer = letter.isPfApplicable ? (basic * 0.12).round() : 0;
    final esicEmployer = letter.isEsicApplicable ? (gross * 0.0325).round() : 0;
    final totalEmployerDeductions = pfEmployer + esicEmployer;
    final costToCompany = gross + totalEmployerDeductions;

    final refNo =
        'DIP/${letter.joiningDate.year % 100}-${(letter.joiningDate.year + 1) % 100}/${letter.employeeCode.replaceAll('EMP', '')}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 750),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.view, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Offer Letter Preview',
                    style: AppTypography.titleMedium,
                  ),
                  const Spacer(),
                  GhostButton(
                    text: 'Download PDF',
                    icon: AppIcons.download,
                    onPressed: () {
                      OfferLetterPdfGenerator.printPreview(letter);
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'M/s DOON INFRAPOWER PROJECTS PVT. LTD.',
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Office Add - 711, Doon Enclave, Vidhyadhar Nagar, Jaipur, 302039',
                              style: AppTypography.caption,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Email ID - info@dooninfra.in  Mob No. 9660041866',
                              style: AppTypography.caption,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Transformer Manufacturing, Repairing & Solar EPC Company',
                              style: AppTypography.caption.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(height: 2, color: AppColors.primary),
                      const SizedBox(height: 14),
                      Text(
                        'Ref. $refNo',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Date: ${dateFormat.format(letter.joiningDate)}',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      Text('To,', style: AppTypography.bodySmall),
                      Text(
                        letter.employeeName,
                        style: AppTypography.labelLarge,
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: 'Subject: ',
                              style: AppTypography.labelMedium,
                            ),
                            TextSpan(
                              text: 'Offer of Employment',
                              style: AppTypography.labelMedium.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Dear ${letter.employeeName.split(' ').first},',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'We are pleased to offer you the position of ',
                            ),
                            TextSpan(
                              text: letter.designation,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' at '),
                            const TextSpan(
                              text: 'Doon Infrapower Projects Pvt. Ltd.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text:
                                  ', under the following terms and conditions:',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _sectionTitle('1. Commencement of Employment'),
                      _bodyText(
                        'Your employment will commence from ${DateFormat("d'-'MMM'-'yy").format(letter.joiningDate)}.',
                      ),
                      const SizedBox(height: 10),
                      _sectionTitle('2. Job Title & Reporting'),
                      _bodyText(
                        'Your designation will be ${letter.designation}.',
                      ),
                      const SizedBox(height: 10),
                      _sectionTitle('3. Salary & Benefits'),
                      _bulletPoint(
                        'Your Cost to Company (CTC) will be Rs ${ctc.toInt()}/- per month, as detailed in Annexure-A.',
                      ),
                      const SizedBox(height: 10),
                      _sectionTitle('4. Place of Posting'),
                      _bodyText('Your initial posting will be at Jaipur Office.'),
                      const SizedBox(height: 10),
                      _sectionTitle('5. Probation & Confirmation'),
                      _bulletPoint(
                        'You will be on probation for 3 months from your joining date.',
                      ),
                      _bulletPoint(
                        'Upon successful completion, you will be issued a formal confirmation letter.',
                      ),
                      const SizedBox(height: 10),
                      _sectionTitle('6. Working Hours'),
                      _bulletPoint(
                        'Normal office hours are 9:00 AM - 6:00 PM, Monday to Saturday.',
                      ),
                      const SizedBox(height: 10),
                      _sectionTitle('10. Termination & Notice Period'),
                      _bulletPoint(
                        'During probation: 7 days\' written notice.',
                      ),
                      _bulletPoint(
                        'After confirmation: 30 days\' written notice.',
                      ),
                      const SizedBox(height: 10),
                      _sectionTitle('11. Confidentiality & NDA Clause'),
                      _bulletPoint(
                        'You shall maintain strict confidentiality regarding all company information.',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'For Doon Infrapower Projects Pvt. Ltd.',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('HR Department', style: AppTypography.bodySmall),
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/images/seal_signature.jpg',
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Container(height: 2, color: AppColors.primary),
                      const SizedBox(height: 14),
                      Text(
                        'Annexure - A: Salary Breakup',
                        style: AppTypography.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      Table(
                        border: TableBorder.all(color: AppColors.border),
                        columnWidths: const {
                          0: FixedColumnWidth(40),
                          1: FlexColumnWidth(3),
                          2: FixedColumnWidth(90),
                          3: FixedColumnWidth(90),
                        },
                        children: [
                          _tableHeaderRow(),
                          _tableRow('1', 'BASIC', basic),
                          _tableRow('2', 'HRA', hra),
                          _tableRow('3', 'GROSS SALARY', gross, highlight: true),
                          _tableRow('4', 'PF share employee', pfEmp),
                          _tableRow('5', 'ESIC employee', esicEmp),
                          _tableRow(
                            '6',
                            'TOTAL EMPLOYEE DEDUCTION',
                            totalDeductions,
                          ),
                          _tableRow(
                            '7',
                            'NET PAY IN HAND (A-B)',
                            netPay,
                            highlight: true,
                          ),
                          _tableRow('8', 'PF share employer', pfEmployer),
                          _tableRow('9', 'ESIC employer', esicEmployer),
                          _tableRow(
                            '10',
                            'Total employer deduction (C)',
                            totalEmployerDeductions,
                          ),
                          _tableRow(
                            '11',
                            'COST OF COMPANY IN RUPEES (A+C)',
                            costToCompany,
                            highlight: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _tableHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.green.shade50),
      children: [
        _headerCell('Sno.'),
        _headerCell('SALARY BREAKUP'),
        _headerCell('Monthly'),
        _headerCell('Yearly'),
      ],
    );
  }

  TableRow _tableRow(
    String sno,
    String label,
    int monthly, {
    bool highlight = false,
  }) {
    return TableRow(
      decoration: highlight ? BoxDecoration(color: Colors.yellow.shade50) : null,
      children: [
        _dataCell(sno, center: true),
        _dataCell(label, bold: highlight),
        _dataCell(monthly.toString(), center: true, bold: highlight),
        _dataCell((monthly * 12).toString(), center: true, bold: highlight),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _dataCell(
    String text, {
    bool center = false,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
