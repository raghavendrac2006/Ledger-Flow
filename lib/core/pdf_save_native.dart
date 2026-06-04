import 'package:flutter/foundation.dart';

void savePdfFile(List<int> bytes, String fileName) {
  // Safe mock file logger for native compilations
  debugPrint("PDF Sales Report generated with ${bytes.length} bytes.");
}

