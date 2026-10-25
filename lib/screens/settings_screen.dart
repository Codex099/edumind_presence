import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/sheets_service.dart';
import '../services/connectivity_service.dart';
import '../services/update_service.dart';
import '../utils/theme.dart';
import '../utils/translations.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = Get.find<AuthService>();
  final _sheetsService = Get.find<SheetsService>();
  final _conn = Get.find<ConnectivityService>();
  final _updateService = Get.find<UpdateService>();

  void _showUrlDialog(String lang) {
    final controller = TextEditingController(text: _sheetsService.scriptUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EdumindTheme.cardDark,
        title: Text(AppTranslations.get('script_url', lang: lang), style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppTranslations.get('script_url_desc', lang: lang), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showQrModal(lang);
            },
            icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: EdumindTheme.accentCyan),
            label: Text(
              AppTranslations.get('show_qr', lang: lang),
              style: const TextStyle(color: EdumindTheme.accentCyan, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.get('cancel', lang: lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await _sheetsService.updateScriptUrl(controller.text);
              nav.pop();
              Get.snackbar('EDUMIND', 'تم تحديث رابط السحابة بنجاح', snackPosition: SnackPosition.BOTTOM);
            },
            child: Text(AppTranslations.get('save', lang: lang)),
          ),
        ],
      ),
    );
  }

  void _showQrModal(String lang) {
    final url = _sheetsService.scriptUrl.trim();
    final isAr = lang == 'ar';
    final school = _sheetsService.schoolName.trim();

    if (url.isEmpty) {
      Get.snackbar(
        'EDUMIND',
        isAr ? 'يرجى إدخال وتعيين رابط السحابة أولاً' : 'Veuillez d\'abord configurer le lien Google Script',
        backgroundColor: EdumindTheme.lateOrange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final qrPayload = jsonEncode({
      'url': url,
      if (school.isNotEmpty) 'school': school,
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: EdumindTheme.bgDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: EdumindTheme.borderDark, width: 1.5)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: EdumindTheme.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: EdumindTheme.accentCyan.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: EdumindTheme.accentCyan, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.get('share_qr', lang: lang),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (school.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                school,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: EdumindTheme.presentGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppTranslations.get('share_qr_desc', lang: lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: EdumindTheme.accentCyan.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 210.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: url));
                            Get.snackbar(
                              'EDUMIND',
                              AppTranslations.get('link_copied', lang: lang),
                              backgroundColor: EdumindTheme.cardDark,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                              icon: const Icon(Icons.check_circle_rounded, color: EdumindTheme.presentGreen),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: EdumindTheme.borderDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 18, color: EdumindTheme.accentCyan),
                          label: Text(
                            AppTranslations.get('copy_link', lang: lang),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EdumindTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            AppTranslations.get('close', lang: lang),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EdumindTheme.cardDark,
        title: Text(AppTranslations.get('logout', lang: lang)),
        content: Text(AppTranslations.get('confirm_logout', lang: lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.get('no', lang: lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EdumindTheme.absentRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              Get.offAll(() => const LoginScreen());
            },
            child: Text(AppTranslations.get('yes', lang: lang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lang = _authService.currentLang.value;
      final isAr = lang == 'ar';
      final teacher = _authService.currentTeacher.value;
      final isOnline = _conn.isOnline.value;

      return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: EdumindTheme.bgDark,
          appBar: AppBar(
            backgroundColor: EdumindTheme.bgDark,
            title: Text(AppTranslations.get('settings', lang: lang)),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Teacher Profile Card
              if (teacher != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: EdumindTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: EdumindTheme.borderDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EdumindTheme.primaryBlue.withValues(alpha: 0.2),
                          border: Border.all(color: EdumindTheme.primaryBlue, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teacher.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text(teacher.phone, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            if (teacher.subject.isNotEmpty)
                              Text(teacher.subject, style: const TextStyle(fontSize: 12, color: EdumindTheme.accentCyan)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Network Status
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: EdumindTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EdumindTheme.borderDark),
                ),
                child: ListTile(
                  leading: Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    color: isOnline ? EdumindTheme.presentGreen : EdumindTheme.lateOrange,
                  ),
                  title: Text(AppTranslations.get('offline_status', lang: lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOnline ? EdumindTheme.presentBgDark : EdumindTheme.lateBgDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isOnline ? AppTranslations.get('online', lang: lang) : AppTranslations.get('offline', lang: lang),
                      style: TextStyle(
                        color: isOnline ? EdumindTheme.presentGreen : EdumindTheme.lateOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // Language Selector
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: EdumindTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EdumindTheme.borderDark),
                ),
                child: ListTile(
                  leading: const Icon(Icons.language_rounded, color: EdumindTheme.primaryBlue),
                  title: Text(AppTranslations.get('language', lang: lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isAr ? 'العربية' : 'Français'),
                  trailing: DropdownButton<String>(
                    value: lang,
                    underline: const SizedBox.shrink(),
                    dropdownColor: EdumindTheme.cardDark,
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                    ],
                    onChanged: (val) {
                      if (val != null) _authService.setLanguage(val);
                    },
                  ),
                ),
              ),

              // Script URL Setting & QR Code Share
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: EdumindTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EdumindTheme.borderDark),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_sync_outlined, color: EdumindTheme.accentCyan),
                      title: Text(AppTranslations.get('script_url', lang: lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        _sheetsService.scriptUrl.isNotEmpty ? _sheetsService.scriptUrl : '---',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code_2_rounded, color: EdumindTheme.accentCyan, size: 26),
                            tooltip: AppTranslations.get('share_qr', lang: lang),
                            onPressed: () => _showQrModal(lang),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white70),
                            onPressed: () => _showUrlDialog(lang),
                          ),
                        ],
                      ),
                      onTap: () => _showQrModal(lang),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: InkWell(
                        onTap: () => _showQrModal(lang),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: EdumindTheme.accentCyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: EdumindTheme.accentCyan.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_rounded, size: 18, color: EdumindTheme.accentCyan),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.get('share_qr', lang: lang),
                                style: const TextStyle(
                                  color: EdumindTheme.accentCyan,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Check Updates Button
              Obx(() {
                final isChecking = _updateService.isChecking.value;
                return OutlinedButton.icon(
                  onPressed: isChecking
                      ? null
                      : () => _updateService.checkForUpdate(silent: false, context: context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: EdumindTheme.primaryBlue.withValues(alpha: 0.5)),
                    backgroundColor: EdumindTheme.primaryBlue.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: EdumindTheme.accentCyan),
                        )
                      : const Icon(Icons.system_update_rounded, color: EdumindTheme.accentCyan, size: 20),
                  label: Text(
                    isChecking
                        ? AppTranslations.get('checking_updates', lang: lang)
                        : AppTranslations.get('check_updates', lang: lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () => _confirmLogout(lang),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EdumindTheme.absentRed.withValues(alpha: 0.15),
                  foregroundColor: EdumindTheme.absentRed,
                  side: BorderSide(color: EdumindTheme.absentRed.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  AppTranslations.get('logout', lang: lang),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'EDUMIND Présence',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppTranslations.get('app_version', lang: lang),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
