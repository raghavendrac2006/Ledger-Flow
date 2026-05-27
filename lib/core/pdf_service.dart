import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'app_state.dart';
import 'pdf_save_helper.dart';

class PdfService {
  static Future<void> generateAndDownloadSalesReport({
    required String productName,
    required DateTimeRange dateRange,
    required List<DeliveryLog> allLogs,
  }) async {
    // 1. Filter Logs by Product and Date Range (Inclusive of boundaries)
    final filteredLogs = allLogs.where((log) {
      final matchesProduct = log.itemName.toLowerCase() == productName.toLowerCase();
      
      // Clean dates to exclude time component
      final logDate = DateTime(log.dateTime.year, log.dateTime.month, log.dateTime.day);
      final startDate = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final endDate = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
      
      final matchesDate = !logDate.isBefore(startDate) && !logDate.isAfter(endDate);
      return matchesProduct && matchesDate;
    }).toList();

    // Sort chronologically (oldest first for the report rows)
    filteredLogs.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // 2. Calculate Report Statistics
    int totalSalesCount = filteredLogs.length;
    double totalSalesValue = filteredLogs.fold(0.0, (sum, log) => sum + log.amount);
    double totalCollected = filteredLogs
        .where((log) => log.isPaid)
        .fold(0.0, (sum, log) => sum + log.amount);
    double pendingCollection = totalSalesValue - totalCollected;
    double collectionRate = totalSalesValue > 0 ? (totalCollected / totalSalesValue) * 100 : 0.0;

    // 3. Setup PDF Document
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy');
    final formattedStart = dateFormat.format(dateRange.start);
    final formattedEnd = dateFormat.format(dateRange.end);
    final generatedOn = dateFormat.format(DateTime.now());

    // Clean brand indigo color matching `#000666`
    const primaryColor = PdfColor.fromInt(0xff000666);
    const borderColor = PdfColors.black;
    const accentGrey = PdfColors.grey200;

    // Define custom high-contrast cell layouts
    pw.Widget tableCell(String text, {bool isHeader = false, bool isRight = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 10 : 9,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isHeader ? PdfColors.white : PdfColors.black,
          ),
          textAlign: isRight ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36.0),
        build: (pw.Context context) {
          return [
            // A. HEADER BAR BLOCK (High-Contrast Modernist Design)
            pw.Container(
              decoration: pw.BoxDecoration(
                color: primaryColor,
                border: pw.Border.all(color: borderColor, width: 2.0),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "SALES TRACKING",
                        style: pw.TextStyle(
                          fontSize: 22.0,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(color: borderColor, width: 1.5),
                        ),
                        child: pw.Text(
                          "SALES REPORT",
                          style: pw.TextStyle(
                            fontSize: 9.0,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16.0),
                  pw.Container(
                    height: 1.5,
                    color: PdfColors.white,
                  ),
                  pw.SizedBox(height: 12.0),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "PRODUCT LEDGER",
                            style: pw.TextStyle(fontSize: 8.0, color: PdfColors.grey300),
                          ),
                          pw.SizedBox(height: 2.0),
                          pw.Text(
                            productName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 14.0,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            "DATE RANGE FILTER",
                            style: pw.TextStyle(fontSize: 8.0, color: PdfColors.grey300),
                          ),
                          pw.SizedBox(height: 2.0),
                          pw.Text(
                            "$formattedStart - $formattedEnd",
                            style: pw.TextStyle(
                              fontSize: 11.0,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24.0),

            // B. KEY METRICS BENTO GRID ROW
            pw.Row(
              children: [
                // Metric 1: Total Sold
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor, width: 1.5),
                    ),
                    padding: const pw.EdgeInsets.all(12.0),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("TOTAL DELIVERIES", style: pw.TextStyle(fontSize: 8.0, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4.0),
                        pw.Text("$totalSalesCount", style: pw.TextStyle(fontSize: 16.0, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12.0),
                // Metric 2: Total Value
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor, width: 1.5),
                    ),
                    padding: const pw.EdgeInsets.all(12.0),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("TOTAL SALES VALUE", style: pw.TextStyle(fontSize: 8.0, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4.0),
                        pw.Text("INR ${totalSalesValue.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 14.0, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12.0),
                // Metric 3: Collection Rate
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor, width: 1.5),
                    ),
                    padding: const pw.EdgeInsets.all(12.0),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("COLLECTION RATE", style: pw.TextStyle(fontSize: 8.0, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4.0),
                        pw.Text("${collectionRate.toStringAsFixed(1)}%", style: pw.TextStyle(fontSize: 14.0, fontWeight: pw.FontWeight.bold, color: collectionRate > 80 ? PdfColors.green900 : PdfColors.red900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 28.0),

            // C. TRANSACTIONS LEDGER TABLE
            pw.Text(
              "ITEMIZED RECORD OF SALES DELIVERIES",
              style: pw.TextStyle(fontSize: 9.0, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0),
            ),
            pw.SizedBox(height: 8.0),

            filteredLogs.isEmpty
                ? pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 36.0),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderColor, width: 1.5),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        "No recorded deliveries found for this product and date range.",
                        style: pw.TextStyle(fontSize: 10.0, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                      ),
                    ),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: borderColor, width: 1.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.2), // Serial
                      1: const pw.FlexColumnWidth(2.0), // Date
                      2: const pw.FlexColumnWidth(3.8), // Client
                      3: const pw.FlexColumnWidth(2.0), // Value
                      4: const pw.FlexColumnWidth(1.8), // Status
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: primaryColor),
                        children: [
                          tableCell("SERIAL", isHeader: true),
                          tableCell("DATE", isHeader: true),
                          tableCell("CLIENT NAME", isHeader: true),
                          tableCell("SALES VALUE", isHeader: true, isRight: true),
                          tableCell("STATUS", isHeader: true),
                        ],
                      ),
                      // Data Rows
                      ...filteredLogs.map((log) {
                        return pw.TableRow(
                          children: [
                            tableCell("#${log.serialNo}"),
                            tableCell(log.date),
                            tableCell(log.customerName),
                            tableCell("INR ${log.amount.toStringAsFixed(2)}", isRight: true),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                              child: pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                decoration: pw.BoxDecoration(
                                  color: log.isPaid ? PdfColors.green100 : PdfColors.red100,
                                  border: pw.Border.all(color: log.isPaid ? PdfColors.green : PdfColors.red, width: 1.0),
                                ),
                                child: pw.Text(
                                  log.isPaid ? "PAID" : "UNPAID",
                                  style: pw.TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: log.isPaid ? PdfColors.green900 : PdfColors.red900,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
            pw.SizedBox(height: 32.0),

            // D. BALANCE SUMMARY DRAWER BLOCK
            pw.Container(
              decoration: pw.BoxDecoration(
                color: accentGrey,
                border: pw.Border.all(color: borderColor, width: 1.5),
              ),
              padding: const pw.EdgeInsets.all(16.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "FINANCIAL CONSOLIDATION SUMMARY",
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5),
                  ),
                  pw.SizedBox(height: 12.0),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Total Gross Sales Value:", style: const pw.TextStyle(fontSize: 9.0)),
                      pw.Text("INR ${totalSalesValue.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 9.0, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 6.0),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Total Cash Collections (Paid Invoices):", style: const pw.TextStyle(fontSize: 9.0)),
                      pw.Text("INR ${totalCollected.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 9.0, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    ],
                  ),
                  pw.SizedBox(height: 6.0),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Total Outstanding Receivables (Unpaid Invoices):", style: const pw.TextStyle(fontSize: 9.0)),
                      pw.Text("INR ${pendingCollection.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 9.0, fontWeight: pw.FontWeight.bold, color: pendingCollection > 0 ? PdfColors.red900 : PdfColors.black)),
                    ],
                  ),
                  pw.SizedBox(height: 10.0),
                  pw.Container(height: 1.0, color: PdfColors.grey400),
                  pw.SizedBox(height: 8.0),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Report Generated On:", style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                      pw.Text("Generated on: $generatedOn (Sales Tracking)", style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // 4. Save and Download
    final bytes = await pdf.save();
    final cleanFileName = "${productName.replaceAll(' ', '_')}_Sales_Report_${formattedStart.replaceAll(' ', '_')}_to_${formattedEnd.replaceAll(' ', '_')}.pdf";
    
    savePdfFile(bytes, cleanFileName);
  }
}
