import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../server_url.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ReportExporter {
  /// Downloads a report from the backend, saves it locally to Downloads/Docs,
  /// attempts to open it via OpenFilex, and displays an export sheet with options to Open, Share, or Preview.
  static Future<void> exportReport({
    required BuildContext context,
    required String token,
    required String reportType,
    String? reportTitle,
    String? adAccountId,
    String? socialAccountId,
    String? period,
    String? pageId,
    String? formId,
  }) async {
    final title = reportTitle ?? '${reportType.toUpperCase()} Report';

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: AppCard(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              SizedBox(width: 16),
              Text(
                'Generating CSV Report...',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final query = <String, String>{
        if (adAccountId != null && adAccountId.isNotEmpty) 'adAccountId': adAccountId,
        if (pageId != null && pageId.isNotEmpty) 'pageId': pageId,
        if (formId != null && formId.isNotEmpty) 'formId': formId,
      };
      if (reportType == 'social') {
        if (socialAccountId != null && socialAccountId.isNotEmpty) query['socialAccountId'] = socialAccountId;
        if (period != null && period.isNotEmpty) query['period'] = period;
      }

      final uri = Uri.parse('$baseUrl/api/reports/$reportType/download').replace(queryParameters: query);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 25));

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final cleanType = reportType.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        final fileName = 'MarketAI_${cleanType}_Report_$dateStr.csv';

        final savedFile = await _saveFileLocally(fileName, response.bodyBytes);
        final csvContent = utf8.decode(response.bodyBytes, allowMalformed: true);

        if (!context.mounted) return;

        // Try opening directly with Google Sheets / default CSV app
        _attemptDirectOpen(savedFile.path, fileName);

        // Show Export Action Sheet
        _showExportSuccessSheet(
          context: context,
          file: savedFile,
          fileName: fileName,
          title: title,
          csvContent: csvContent,
        );
      } else {
        if (context.mounted) {
          showAppSnackBar(context, 'Failed to download report (Server status: ${response.statusCode})');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Ensure dialog closes
        showAppSnackBar(context, 'Export error: $e');
      }
    }
  }

  /// Multi-directory strategy to save file in public Downloads folder or accessible docs folder
  static Future<File> _saveFileLocally(String fileName, Uint8List bytes) async {
    List<Directory> candidateDirs = [];

    if (Platform.isAndroid) {
      // 1. Try public standard Downloads directory
      final publicDownloads = Directory('/storage/emulated/0/Download');
      candidateDirs.add(publicDownloads);

      // 2. Try external storage app directory
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) candidateDirs.add(extDir);
      } catch (_) {}
    } else if (Platform.isIOS) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        candidateDirs.add(docsDir);
      } catch (_) {}
    }

    try {
      final appDocs = await getApplicationDocumentsDirectory();
      candidateDirs.add(appDocs);
    } catch (_) {}

    try {
      final temp = await getTemporaryDirectory();
      candidateDirs.add(temp);
    } catch (_) {}

    for (final dir in candidateDirs) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);
        return file;
      } catch (_) {
        // Fallthrough to next candidate
      }
    }

    // Ultimate fallback
    final fallbackDir = await getTemporaryDirectory();
    final file = File('${fallbackDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Attempt direct opening via OpenFilex
  static Future<bool> _attemptDirectOpen(String filePath, String fileName) async {
    try {
      final result = await OpenFilex.open(filePath, type: 'text/csv');
      if (result.type == ResultType.done) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Open via SharePlus (works 100% reliably with Google Sheets, Excel, Drive, WhatsApp)
  static Future<void> shareFile(String filePath, String fileName, {String? title}) async {
    try {
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'text/csv', name: fileName)],
        text: 'Exported MarketAI Report: $fileName',
        subject: title ?? 'MarketAI Report - $fileName',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  /// Displays the interactive modal sheet
  static void _showExportSuccessSheet({
    required BuildContext context,
    required File file,
    required String fileName,
    required String title,
    required String csvContent,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isPublicDownload = file.path.contains('/Download') || file.path.contains('/Downloads');
        final locationLabel = isPublicDownload ? 'Saved to phone Downloads folder' : 'Saved to App Documents';

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          fileName,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationLabel,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action 1: Open in Sheets / Excel
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final opened = await _attemptDirectOpen(file.path, fileName);
                    if (!opened && ctx.mounted) {
                      // If direct open failed, trigger Share sheet (Google Sheets appears in share sheet)
                      await shareFile(file.path, fileName, title: title);
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open in Google Sheets / Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Action 2: Share / Send File
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => shareFile(file.path, fileName, title: title),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share CSV (WhatsApp / Drive / Gmail)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Action 3: In-App CSV Viewer
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showInAppCsvViewer(context, title, fileName, csvContent);
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.muted),
                  label: const Text('Preview CSV Data in App', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// In-App CSV Preview Modal
  static void _showInAppCsvViewer(BuildContext context, String title, String fileName, String csvContent) {
    final lines = csvContent
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (sheetCtx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'In-App Table Preview (${lines.length} lines)',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: lines.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                      itemBuilder: (context, index) {
                        final line = lines[index];
                        if (line.startsWith('===') || line.startsWith('---')) {
                          return const SizedBox(height: 4);
                        }

                        if (RegExp(r'^\d+\.').hasMatch(line)) {
                          return Container(
                            color: AppColors.lavender.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              line.replaceAll('"', ''),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                            ),
                          );
                        }

                        final cells = _parseCsvLine(line);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < cells.length; i++)
                                Expanded(
                                  flex: i == 0 ? 3 : (i == 1 ? 2 : 4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      cells[i],
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: index < 10 && i == 0 ? FontWeight.w700 : FontWeight.normal,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static List<String> _parseCsvLine(String line) {
    List<String> result = [];
    StringBuffer cur = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          cur.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(cur.toString().trim());
        cur.clear();
      } else {
        cur.write(char);
      }
    }
    result.add(cur.toString().trim());
    return result;
  }
}
