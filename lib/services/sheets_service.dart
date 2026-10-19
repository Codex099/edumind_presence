import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/group_class.dart';
import '../models/schedule_slot.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';

class SheetsService extends GetxService {
  static const String defaultScriptUrl =
      'https://script.google.com/macros/s/AKfycbylDllDn_uQqnrTkyJt3HlSTtkQ-PwQ-EUfkUZsCj3RZBfN5cQXyxyufss4Y6ZiYdq7/exec';

  bool get isSchoolConfigured {
    try {
      final box = Hive.box('settings');
      return box.get('is_school_linked', defaultValue: false) == true;
    } catch (_) {
      return false;
    }
  }

  String get schoolName {
    try {
      final box = Hive.box('settings');
      return box.get('school_name', defaultValue: 'المؤسسة التعليمية');
    } catch (_) {
      return 'المؤسسة التعليمية';
    }
  }

  String get scriptUrl {
    try {
      final box = Hive.box('settings');
      final saved = box.get('scriptUrl');
      if (saved != null && saved.toString().isNotEmpty) {
        return saved.toString();
      }
      return defaultScriptUrl;
    } catch (_) {
      return defaultScriptUrl;
    }
  }

  Future<void> updateScriptUrl(String newUrl) async {
    final box = Hive.box('settings');
    await box.put('scriptUrl', newUrl.trim());
  }

  Future<bool> linkSchool({required String url, String? name}) async {
    final cleanUrl = url.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      return false;
    }
    try {
      final testUri = Uri.parse(cleanUrl.contains('?') ? '$cleanUrl&action=ping' : '$cleanUrl?action=ping');
      final res = await http.get(testUri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 || res.statusCode == 302) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'ok') {
          final box = Hive.box('settings');
          await box.put('scriptUrl', cleanUrl);
          if (name != null && name.isNotEmpty) {
            await box.put('school_name', name.trim());
          }
          await box.put('is_school_linked', true);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> unlinkSchool() async {
    try {
      final box = Hive.box('settings');
      await box.put('is_school_linked', false);
    } catch (_) {}
  }

  /// Ping the Web App
  Future<bool> ping() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=ping'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200 || response.statusCode == 302) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
    } catch (_) {}
    return false;
  }

  /// Google Apps Script Web Apps return a 302 redirect for POST requests.
  /// Dart HttpClient does not follow 302 redirects on POST automatically.
  /// This helper sends the POST and follows redirects using GET to obtain the JSON response.
  Future<http.Response> _postGoogleScript(Uri uri, Map<String, dynamic> data, {Duration timeout = const Duration(seconds: 15)}) async {
    final client = http.Client();
    try {
      var response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(timeout);

      int redirects = 0;
      while ((response.statusCode == 301 || response.statusCode == 302 || response.statusCode == 303 || response.statusCode == 307) &&
          response.headers.containsKey('location') &&
          redirects < 5) {
        final redirectUrl = response.headers['location']!;
        response = await client.get(Uri.parse(redirectUrl)).timeout(timeout);
        redirects++;
      }

      return response;
    } finally {
      client.close();
    }
  }

  /// Teacher Login
  Future<Map<String, dynamic>> login(String phone, String secret) async {
    final cleanPhone = phone.trim();
    final cleanSecret = secret.trim();

    try {
      final uri = Uri.parse(scriptUrl);
      final response = await _postGoogleScript(
        uri,
        {
          'action': 'login_teacher',
          'phone': cleanPhone,
          'password': cleanSecret,
          'pin': cleanSecret,
        },
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final resData = jsonDecode(response.body);
        return resData;
      }
      return {'success': false, 'error': 'Code HTTP ${response.statusCode}'};
    } catch (e) {
      // Fallback: try GET if POST fails (e.g. strict firewall or network edge case)
      try {
        final getUrl = '$scriptUrl?action=login_teacher&phone=${Uri.encodeComponent(cleanPhone)}&password=${Uri.encodeComponent(cleanSecret)}';
        final getResponse = await http.get(Uri.parse(getUrl)).timeout(const Duration(seconds: 12));
        if (getResponse.statusCode == 200 && getResponse.body.isNotEmpty) {
          return jsonDecode(getResponse.body);
        }
      } catch (_) {}
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch full teacher dataset (classes, schedules, students)
  Future<Map<String, dynamic>> fetchTeacherData(String teacherId) async {
    try {
      final url = '$scriptUrl?action=get_teacher_data&teacher_id=${Uri.encodeComponent(teacherId)}';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'groups': (data['groups'] as List? ?? []).map((g) => GroupClass.fromJson(g)).toList(),
          'schedules': (data['schedules'] as List? ?? []).map((s) => ScheduleSlot.fromJson(s)).toList(),
          'students': (data['students'] as List? ?? []).map((st) => Student.fromJson(st)).toList(),
        };
      }
      return {'success': false, 'error': 'Erreur HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Submit an attendance roll sheet (batch of student records)
  Future<Map<String, dynamic>> submitAttendanceSheet(List<AttendanceRecord> records) async {
    if (records.isEmpty) return {'success': true, 'total': 0};

    try {
      final uri = Uri.parse(scriptUrl);
      final response = await _postGoogleScript(
        uri,
        {
          'action': 'submit_attendance_sheet',
          'data': {
            'records': records.map((r) => r.toJson()).toList(),
          }
        },
        timeout: const Duration(seconds: 20),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final resData = jsonDecode(response.body);
        return resData;
      }
      return {'success': false, 'error': 'Code HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch attendances marked by teacher
  Future<List<AttendanceRecord>> fetchTeacherAttendances(String teacherId, {String? date}) async {
    try {
      var url = '$scriptUrl?action=get_attendances&teacher_id=${Uri.encodeComponent(teacherId)}';
      if (date != null && date.isNotEmpty) {
        url += '&date=${Uri.encodeComponent(date)}';
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List? ?? [];
        return list.map((item) => AttendanceRecord.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }
}
