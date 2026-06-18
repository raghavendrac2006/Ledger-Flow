import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> savePdfFile(List<int> bytes, String fileName) async {
  debugPrint("PDF Sales Report generating with ${bytes.length} bytes.");
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    debugPrint("PDF saved to ${file.path}");
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: 'Product Ledger Report',
    );
  } catch (e) {
    debugPrint("Error saving/sharing PDF file: $e");
  }
}
