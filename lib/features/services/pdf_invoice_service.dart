import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale_model.dart';

class PdfInvoiceService {
  static Future<pw.Document> buildPdfDocument(Sale sale) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - Shop Details
              pw.Center(
                child: pw.Text(
                  sale.shopName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (sale.shopAddress.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    sale.shopAddress,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              if (sale.shopPhone.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    'Ph: ${sale.shopPhone}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),

              // Invoice Meta
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice #: ${sale.invoiceNumber}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(sale.paymentMethod.displayName,
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Text('Date: ${dateFormat.format(sale.dateTime)}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),

              // Item Headers
              pw.Row(
                children: [
                  pw.Expanded(
                      flex: 4,
                      child: pw.Text('Item',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Price',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Total',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.SizedBox(height: 4),

              // Item Lines
              ...sale.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.medicine.name,
                                style: pw.TextStyle(
                                    fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                                'Batch: ${item.batch.batchNumber}',
                                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text('${item.quantity}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('Rs.${item.unitPrice.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('Rs.${item.totalPrice.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1),

              // Summary
              if (sale.discount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Rs.${sale.subtotal.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('- Rs.${sale.discount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 3),
              ],

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL:',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs.${sale.totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your visit!',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Get well soon!',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static Future<void> printInvoice(Sale sale) async {
    final pdf = await buildPdfDocument(sale);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${sale.invoiceNumber}',
    );
  }

  static Future<void> shareInvoice(Sale sale) async {
    final pdf = await buildPdfDocument(sale);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Invoice_${sale.invoiceNumber}.pdf',
    );
  }
}
