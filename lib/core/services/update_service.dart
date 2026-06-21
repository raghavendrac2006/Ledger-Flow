import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import '../app_theme.dart';

class UpdateService {
  // Target raw URL for GitHub releases tracking
  static const String versionUrl = "https://raw.githubusercontent.com/raghavendrac2006/Ledger-Flow/main/version.json";

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // 1. Fetch current local version information
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final int localBuild = int.parse(packageInfo.buildNumber);

      // 2. Fetch latest version info from the remote repository
      final response = await http.get(Uri.parse(versionUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String latestVersion = data['latest_version'] ?? '1.0.0';
        final int latestBuild = data['build_number'] ?? 1;
        final String apkUrl = data['apk_url'] ?? '';
        final String releaseNotes = data['release_notes'] ?? "Bug fixes and performance improvements.";

        // 3. Compare build numbers (or version strings)
        if (latestBuild > localBuild && apkUrl.isNotEmpty) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, releaseNotes, apkUrl);
          }
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  static void _showUpdateDialog(BuildContext context, String version, String notes, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        double downloadProgress = 0.0;
        bool isDownloading = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                side: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
              ),
              backgroundColor: Colors.white,
              title: Text("NEW UPDATE AVAILABLE", style: AppTheme.headlineMd.copyWith(fontSize: 18.0)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Version: v$version", style: AppTheme.labelBold.copyWith(color: AppTheme.primary)),
                  const SizedBox(height: 12.0),
                  Text("What's New:", style: AppTheme.labelBold),
                  const SizedBox(height: 4.0),
                  Text(notes, style: AppTheme.bodyMd),
                  if (isDownloading) ...[
                    const SizedBox(height: 20.0),
                    LinearProgressIndicator(
                      value: downloadProgress / 100,
                      backgroundColor: AppTheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                    const SizedBox(height: 8.0),
                    Center(
                      child: Text(
                        "Downloading update: ${downloadProgress.toStringAsFixed(0)}%",
                        style: AppTheme.labelBold.copyWith(fontSize: 12.0),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isDownloading) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "LATER",
                      style: AppTheme.labelBold.copyWith(color: AppTheme.outline),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                     child: TextButton(
                      onPressed: () {
                        setModalState(() {
                          isDownloading = true;
                        });
                        _startOtaUpdate(downloadUrl, version, (progress) {
                          setModalState(() {
                            downloadProgress = progress;
                          });
                        });
                      },
                      child: Text(
                        "UPDATE NOW",
                        style: AppTheme.labelBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }

  static void _startOtaUpdate(String url, String version, Function(double) onProgress) {
    try {
      final safeVersion = version.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      OtaUpdate().execute(
        url,
        destinationFilename: 'app-release_$safeVersion.apk',
      ).listen(
        (OtaEvent event) {
          if (event.status == OtaStatus.DOWNLOADING) {
            final double progress = double.tryParse(event.value ?? "0") ?? 0.0;
            onProgress(progress);
          } else if (event.status == OtaStatus.INSTALLING) {
            debugPrint("Installer screen launched successfully.");
          } else {
            debugPrint("OTA Update status event: ${event.status}");
          }
        },
        onError: (err) {
          debugPrint('OTA update installation error: $err');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize OTA execution: $e');
    }
  }
}
