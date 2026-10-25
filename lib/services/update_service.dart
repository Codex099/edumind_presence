import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/translations.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final int apkSizeBytes;
  final bool isUpdateAvailable;

  AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.apkSizeBytes,
    required this.isUpdateAvailable,
  });

  String get formattedSize {
    if (apkSizeBytes <= 0) return '';
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class UpdateService extends GetxService {
  static const String githubOwner = 'Codex099';
  static const String githubRepo = 'edumind_presence';

  final isChecking = false.obs;
  final isDownloading = false.obs;
  final isDownloaded = false.obs;
  final downloadedFilePath = ''.obs;
  final downloadProgress = 0.0.obs;
  final downloadedBytes = 0.obs;
  final totalBytes = 0.obs;

  /// Helper to compare semver versions (e.g. 2.1.0 > 2.0.0)
  static bool isNewerVersion(String current, String latest) {
    try {
      final cleanCurrent = current.replaceAll('v', '').split('+').first.trim();
      final cleanLatest = latest.replaceAll('v', '').split('+').first.trim();

      final currParts = cleanCurrent.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final latParts = cleanLatest.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (currParts.length < 3) {
        currParts.add(0);
      }
      while (latParts.length < 3) {
        latParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latParts[i] > currParts[i]) return true;
        if (latParts[i] < currParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks GitHub Releases API for the latest version
  Future<AppUpdateInfo?> checkForUpdate({bool silent = true, BuildContext? context}) async {
    isChecking.value = true;
    final auth = Get.find<AuthService>();
    final lang = auth.currentLang.value;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final url = Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest');
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'EDUMIND-Presence-App',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tagName = (data['tag_name'] ?? '').toString();
        final cleanTag = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        final body = (data['body'] ?? '').toString().trim();
        final assets = data['assets'] as List? ?? [];

        String downloadUrl = '';
        int sizeBytes = 0;

        for (final asset in assets) {
          final name = (asset['name'] ?? '').toString().toLowerCase();
          if (name.endsWith('.apk')) {
            downloadUrl = (asset['browser_download_url'] ?? '').toString();
            sizeBytes = int.tryParse(asset['size']?.toString() ?? '0') ?? 0;
            break;
          }
        }

        final isAvailable = isNewerVersion(currentVersion, cleanTag);

        final info = AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: cleanTag.isNotEmpty ? cleanTag : currentVersion,
          downloadUrl: downloadUrl,
          releaseNotes: body,
          apkSizeBytes: sizeBytes,
          isUpdateAvailable: isAvailable,
        );

        isChecking.value = false;

        if (isAvailable && context != null && context.mounted) {
          showUpdateDialog(context, info);
        } else if (!isAvailable && !silent) {
          Get.snackbar(
            'EDUMIND',
            '${AppTranslations.get('app_up_to_date', lang: lang)} (v$currentVersion)',
            backgroundColor: EdumindTheme.cardDark,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.check_circle_rounded, color: EdumindTheme.presentGreen),
          );
        }

        return info;
      } else {
        if (!silent) {
          Get.snackbar(
            'EDUMIND',
            AppTranslations.get('update_error', lang: lang),
            backgroundColor: EdumindTheme.cardDark,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (_) {
      if (!silent) {
        Get.snackbar(
          'EDUMIND',
          AppTranslations.get('update_error', lang: lang),
          backgroundColor: EdumindTheme.cardDark,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    isChecking.value = false;
    return null;
  }

  /// Explicitly launches Android Package Installer for an APK file
  Future<void> triggerInstall({String? path}) async {
    final targetPath = path ?? downloadedFilePath.value;
    if (targetPath.isEmpty) return;

    final file = File(targetPath);
    if (!await file.exists()) {
      Get.snackbar(
        'EDUMIND',
        'Fichier APK introuvable. Veuillez relancer le téléchargement.',
        backgroundColor: EdumindTheme.absentRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        Get.snackbar(
          'EDUMIND',
          'Veuillez autoriser l\'installation d\'applications pour EDUMIND dans les paramètres (${result.message})',
          backgroundColor: EdumindTheme.lateOrange,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'EDUMIND',
        'Erreur d\'ouverture : $e',
        backgroundColor: EdumindTheme.absentRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Downloads the APK with linear stream handling and triggers installation
  Future<void> downloadAndInstallApk(AppUpdateInfo info, {VoidCallback? onDone}) async {
    if (info.downloadUrl.isEmpty || isDownloading.value) return;

    isDownloading.value = true;
    isDownloaded.value = false;
    downloadProgress.value = 0.0;
    downloadedBytes.value = 0;
    totalBytes.value = info.apkSizeBytes;

    File? file;
    IOSink? sink;
    http.Client? client;

    try {
      client = http.Client();
      final request = http.Request('GET', Uri.parse(info.downloadUrl));
      request.headers['User-Agent'] = 'EDUMIND-Presence-App';

      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentLength = response.contentLength ?? info.apkSizeBytes;
        totalBytes.value = contentLength;

        // Use accessible external cache on Android so PackageInstaller can read the file
        Directory? baseDir;
        if (Platform.isAndroid) {
          try {
            final extDirs = await getExternalCacheDirectories();
            if (extDirs != null && extDirs.isNotEmpty) {
              baseDir = extDirs.first;
            }
          } catch (_) {}
        }
        baseDir ??= await getApplicationSupportDirectory();

        final filePath = '${baseDir.path}/edumind_v${info.latestVersion}.apk';
        file = File(filePath);

        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }

        sink = file.openWrite();
        int received = 0;

        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          downloadedBytes.value = received;
          if (contentLength > 0) {
            downloadProgress.value = (received / contentLength).clamp(0.0, 1.0);
          }
        }

        await sink.flush();
        await sink.close();
        sink = null;
        client.close();
        client = null;

        downloadProgress.value = 1.0;
        downloadedBytes.value = totalBytes.value > 0 ? totalBytes.value : received;
        isDownloading.value = false;
        isDownloaded.value = true;
        downloadedFilePath.value = file.path;

        if (onDone != null) onDone();

        // Trigger native Android installer
        await triggerInstall(path: file.path);
      } else {
        client.close();
        isDownloading.value = false;
        Get.snackbar(
          'EDUMIND',
          'Erreur serveur (${response.statusCode}) lors du téléchargement.',
          backgroundColor: EdumindTheme.absentRed,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      try {
        await sink?.close();
      } catch (_) {}
      client?.close();
      isDownloading.value = false;
      Get.snackbar(
        'EDUMIND',
        'Erreur : $e',
        backgroundColor: EdumindTheme.absentRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Displays an update dialog matching Edumind theme
  void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    final auth = Get.find<AuthService>();
    final lang = auth.currentLang.value;
    final isAr = lang == 'ar';

    showModalBottomSheet(
      context: context,
      isDismissible: !isDownloading.value,
      enableDrag: !isDownloading.value,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: EdumindTheme.bgDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: EdumindTheme.borderDark, width: 1.5),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Obx(() {
                  final downloading = isDownloading.value;
                  final progress = downloadProgress.value;
                  final receivedMb = (downloadedBytes.value / (1024 * 1024)).toStringAsFixed(1);
                  final totalMb = (totalBytes.value / (1024 * 1024)).toStringAsFixed(1);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: EdumindTheme.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: EdumindTheme.primaryBlue.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(
                              Icons.rocket_launch_rounded,
                              color: EdumindTheme.accentCyan,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.get('update_available', lang: lang),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: EdumindTheme.presentGreen.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'v${info.latestVersion}',
                                        style: const TextStyle(
                                          color: EdumindTheme.presentGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(actuel: v${info.currentVersion})',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                    if (info.formattedSize.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${info.formattedSize}',
                                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Release Notes Card
                      if (info.releaseNotes.isNotEmpty) ...[
                        Text(
                          AppTranslations.get('update_notes', lang: lang),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: EdumindTheme.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: EdumindTheme.borderDark),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              info.releaseNotes,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Downloading progress section
                      if (downloading) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: EdumindTheme.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: EdumindTheme.primaryBlue.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppTranslations.get('downloading_update', lang: lang),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: EdumindTheme.accentCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress > 0 ? progress : null,
                                  backgroundColor: EdumindTheme.inputDark,
                                  valueColor: const AlwaysStoppedAnimation<Color>(EdumindTheme.accentCyan),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$receivedMb MB / $totalMb MB',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  const Text(
                                    'GitHub Releases CDN',
                                    style: TextStyle(color: Colors.white30, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else if (isDownloaded.value) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: EdumindTheme.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: EdumindTheme.presentGreen.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: EdumindTheme.presentGreen, size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      AppTranslations.get('update_ready', lang: lang),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () => triggerInstall(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EdumindTheme.presentGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.system_security_update_good_rounded, size: 22),
                                label: Text(
                                  AppTranslations.get('install_now', lang: lang),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppTranslations.get('permission_tip', lang: lang),
                                style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.35),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: EdumindTheme.borderDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            AppTranslations.get('close', lang: lang),
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ] else ...[
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: EdumindTheme.borderDark),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(
                                  AppTranslations.get('later', lang: lang),
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () => downloadAndInstallApk(info),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EdumindTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.download_rounded, size: 20),
                                label: Text(
                                  AppTranslations.get('download_and_install', lang: lang),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
