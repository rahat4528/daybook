import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/day_page.dart';

class BookExportService {
  /// Generates a publication-grade PDF book for a given month.
  /// Supports standard theme and high-contrast print-friendly black-on-white variant.
  static Future<Uint8List> exportMonthToPdf(
    List<DayPageModel> days,
    int year,
    int month, {
    bool blackOnWhite = false,
    bool isBangla = false,
  }) async {
    final pdf = pw.Document();

    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
    final bgColor = blackOnWhite ? PdfColors.white : const PdfColor.fromInt(0xFF000000);
    final textColor = blackOnWhite ? PdfColors.black : PdfColors.white;
    final secondaryTextColor = blackOnWhite ? const PdfColor.fromInt(0xFF555555) : const PdfColor.fromInt(0xFFA3A3A3);
    final borderColor = blackOnWhite ? const PdfColor.fromInt(0xFFCCCCCC) : const PdfColor.fromInt(0xFF262626);
    final accentLime = blackOnWhite ? const PdfColor.fromInt(0xFF000000) : const PdfColor.fromInt(0xFFB6FF00);

    // 1. Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Container(
            color: bgColor,
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: accentLime, width: 2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        isBangla ? 'দিনবই' : 'DAYBOOK',
                        style: pw.TextStyle(
                          color: accentLime,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 48),
                    pw.Text(
                      monthName.toUpperCase(),
                      style: pw.TextStyle(
                        color: textColor,
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      isBangla ? 'জীবনের প্রতিটি দিন একটি পৃষ্ঠা' : 'Every day is one page in a book.',
                      style: pw.TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _statCol('PAGES', '${days.length}', textColor, secondaryTextColor),
                      _statCol(
                        'AVG SCORE',
                        days.isEmpty ? '0' : '${(days.fold<int>(0, (s, d) => s + d.computeDayScore()) / days.length).round()}',
                        textColor,
                        secondaryTextColor,
                      ),
                      _statCol(
                        'STARRED',
                        '${days.where((d) => d.isStarred).length}',
                        textColor,
                        secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 2. One Page Per Day
    for (final day in days) {
      final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(day.date);
      final score = day.computeDayScore();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context context) {
            return pw.Container(
              color: bgColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Day Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            dateStr,
                            style: pw.TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (day.title != null && day.title!.isNotEmpty)
                            pw.Text(
                              day.title!,
                              style: pw.TextStyle(
                                color: accentLime,
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: accentLime),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                        ),
                        child: pw.Text(
                          'Score: $score',
                          style: pw.TextStyle(
                            color: accentLime,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(color: borderColor, height: 24),

                  // Timeline section
                  pw.Text(
                    isBangla ? 'দৈনিক ঘটনাবলী' : 'DAY TIMELINE',
                    style: pw.TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  if (day.entries.isEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 20),
                      child: pw.Text(
                        isBangla ? 'এই দিনে কোন এন্ট্রি নেই।' : 'No entries recorded for this day.',
                        style: pw.TextStyle(color: secondaryTextColor, fontSize: 10),
                      ),
                    )
                  else
                    ...day.entries.take(12).map((e) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(
                              width: 45,
                              child: pw.Text(
                                e.timeFormatted,
                                style: pw.TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            pw.Container(
                              width: 6,
                              height: 6,
                              margin: const pw.EdgeInsets.only(top: 3, right: 8),
                              decoration: pw.BoxDecoration(
                                color: e.isPinned ? accentLime : secondaryTextColor,
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                e.displayText(isBangla: isBangla),
                                style: pw.TextStyle(
                                  color: textColor,
                                  fontSize: 10,
                                  fontWeight: e.isPinned ? pw.FontWeight.bold : pw.FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  pw.Spacer(),

                  // Nightly Summary Block
                  if (day.nightlySummary != null && day.nightlySummary!.isNotEmpty)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 12),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            isBangla ? 'রাতের সারসংক্ষেপ' : 'NIGHTLY SUMMARY',
                            style: pw.TextStyle(
                              color: accentLime,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            day.nightlySummary!,
                            style: pw.TextStyle(
                              color: textColor,
                              fontSize: 9,
                              lineSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Reflection and Gratitude
                  if ((day.reflectionNote != null && day.reflectionNote!.isNotEmpty) ||
                      (day.gratitudeNote != null && day.gratitudeNote!.isNotEmpty)) ...[
                    pw.SizedBox(height: 8),
                    if (day.reflectionNote != null && day.reflectionNote!.isNotEmpty)
                      pw.Text(
                        '${isBangla ? "প্রতিফলন: " : "Reflection: "}${day.reflectionNote!}',
                        style: pw.TextStyle(color: secondaryTextColor, fontSize: 9, fontStyle: pw.FontStyle.italic),
                      ),
                    if (day.gratitudeNote != null && day.gratitudeNote!.isNotEmpty)
                      pw.Text(
                        '${isBangla ? "কৃতজ্ঞতা: " : "Gratitude: "}${day.gratitudeNote!}',
                        style: pw.TextStyle(color: accentLime, fontSize: 9),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _statCol(String label, String value, PdfColor textColor, PdfColor labelColor) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            color: labelColor,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Exports month to Markdown format
  static String exportMonthToMarkdown(List<DayPageModel> days, int year, int month, {bool isBangla = false}) {
    final buffer = StringBuffer();
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    buffer.writeln('# DayBook - $monthName');
    buffer.writeln();

    for (final day in days) {
      final dateStr = DateFormat('yyyy-MM-dd (EEEE)').format(day.date);
      buffer.writeln('## $dateStr ${day.isStarred ? "★" : ""}');
      if (day.title != null && day.title!.isNotEmpty) {
        buffer.writeln('**${day.title!}**');
      }
      buffer.writeln('*Day Score: ${day.computeDayScore()}/100*');
      buffer.writeln();

      buffer.writeln('### Timeline');
      for (final e in day.entries) {
        buffer.writeln('- `${e.timeFormatted}` ${e.displayText(isBangla: isBangla)} ${e.isPinned ? "📌" : ""}');
      }
      buffer.writeln();

      if (day.nightlySummary != null && day.nightlySummary!.isNotEmpty) {
        buffer.writeln('### Nightly Summary');
        buffer.writeln(day.nightlySummary!);
        buffer.writeln();
      }

      if (day.reflectionNote != null && day.reflectionNote!.isNotEmpty) {
        buffer.writeln('**Reflection:** ${day.reflectionNote!}');
      }
      if (day.gratitudeNote != null && day.gratitudeNote!.isNotEmpty) {
        buffer.writeln('**Gratitude:** ${day.gratitudeNote!}');
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Exports month to structured JSON
  static String exportMonthToJson(List<DayPageModel> days, int year, int month) {
    final data = {
      'app': 'DayBook',
      'version': '1.0.0',
      'year': year,
      'month': month,
      'exported_at': DateTime.now().toIso8601String(),
      'days': days.map((d) => d.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
