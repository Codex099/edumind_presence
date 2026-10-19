import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/sheets_service.dart';
import '../services/connectivity_service.dart';
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

              // Script URL Setting
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: EdumindTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EdumindTheme.borderDark),
                ),
                child: ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: EdumindTheme.accentCyan),
                  title: Text(AppTranslations.get('script_url', lang: lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    _sheetsService.scriptUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _showUrlDialog(lang),
                ),
              ),

              const SizedBox(height: 18),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () => _confirmLogout(lang),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EdumindTheme.absentRed.withValues(alpha: 0.15),
                  foregroundColor: EdumindTheme.absentRed,
                  side: BorderSide(color: EdumindTheme.absentRed.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
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
