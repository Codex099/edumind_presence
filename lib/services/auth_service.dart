import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/teacher.dart';
import 'sheets_service.dart';

class AuthService extends GetxService {
  static const String teacherBoxName = 'teacher_session';
  static const String settingsBoxName = 'settings';

  final Rx<Teacher?> currentTeacher = Rx<Teacher?>(null);
  final isRemembered = true.obs;
  final currentLang = 'ar'.obs;

  bool get isLoggedIn => currentTeacher.value != null;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    loadSavedSession();
  }

  void _loadSettings() {
    try {
      final box = Hive.box(settingsBoxName);
      currentLang.value = box.get('lang', defaultValue: 'ar');
      isRemembered.value = box.get('rememberMe', defaultValue: true);
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    currentLang.value = lang;
    final box = Hive.box(settingsBoxName);
    await box.put('lang', lang);
  }

  /// Loads saved teacher session if "remember me" was checked
  Future<bool> loadSavedSession() async {
    try {
      final box = Hive.box(teacherBoxName);
      final savedTeacher = box.get('teacher');
      if (savedTeacher != null && savedTeacher is Teacher) {
        currentTeacher.value = savedTeacher;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Logs in with phone and password or PIN
  Future<Map<String, dynamic>> login(String phone, String secret, {bool remember = true}) async {
    final cleanPhone = phone.trim();
    final cleanSecret = secret.trim();

    // 1. Try Google Sheets API
    String? apiErrorMessage;
    try {
      final sheets = Get.find<SheetsService>();
      final result = await sheets.login(cleanPhone, cleanSecret);

      if (result['success'] == true && result['teacher'] != null) {
        final teacher = Teacher.fromJson(result['teacher']);
        currentTeacher.value = teacher;

        final sessionBox = Hive.box(teacherBoxName);
        final settingsBox = Hive.box(settingsBoxName);

        await settingsBox.put('rememberMe', remember);
        await settingsBox.put('lastPhone', cleanPhone);

        if (remember) {
          await sessionBox.put('teacher', teacher);
        } else {
          await sessionBox.delete('teacher');
        }

        return {'success': true, 'teacher': teacher, 'data': result['data']};
      } else if (result['error'] != null) {
        apiErrorMessage = result['error'].toString();
      }
    } catch (e) {
      apiErrorMessage = e.toString();
    }

    // 2. Offline / Demo Credentials Fallback
    if ((cleanPhone == '0550000000' || cleanPhone == '0666666666' || cleanPhone == 'demo') &&
        (cleanSecret == '1234' || cleanSecret == 'password123' || cleanSecret == '0000')) {
      final isMain = cleanPhone != '0666666666';
      final teacher = Teacher(
        id: isMain ? '1' : '4',
        matricule: isMain ? 'ENS-001' : 'ENS-004',
        name: isMain ? 'الأستاذ الرئيسي' : 'أستاذ المادة',
        phone: cleanPhone,
        subject: isMain ? 'الرياضيات' : 'الفيزياء والكيمياء',
        active: true,
      );
      currentTeacher.value = teacher;

      final sessionBox = Hive.box(teacherBoxName);
      final settingsBox = Hive.box(settingsBoxName);

      await settingsBox.put('rememberMe', remember);
      await settingsBox.put('lastPhone', cleanPhone);

      if (remember) {
        await sessionBox.put('teacher', teacher);
      } else {
        await sessionBox.delete('teacher');
      }

      return {'success': true, 'teacher': teacher, 'isDemo': true};
    }

    return {
      'success': false,
      'error': apiErrorMessage ?? 'Numéro ou code PIN incorrect (ou Google Sheets non synchronisé)',
    };
  }

  /// Logs out and clears local session
  Future<void> logout() async {
    currentTeacher.value = null;
    final box = Hive.box(teacherBoxName);
    await box.delete('teacher');
  }
}
