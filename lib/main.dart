import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/teacher.dart';
import 'models/group_class.dart';
import 'models/schedule_slot.dart';
import 'models/student.dart';
import 'models/attendance_record.dart';
import 'models/pending_action.dart';

import 'services/connectivity_service.dart';
import 'services/sheets_service.dart';
import 'services/auth_service.dart';
import 'services/pending_queue_service.dart';
import 'services/sync_service.dart';

import 'utils/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await initializeDateFormatting('fr', null);

  // Hive Initialization
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(TeacherAdapter());
  Hive.registerAdapter(GroupClassAdapter());
  Hive.registerAdapter(ScheduleSlotAdapter());
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(AttendanceStatusAdapter());
  Hive.registerAdapter(AttendanceRecordAdapter());
  Hive.registerAdapter(PendingActionAdapter());

  // Open Storage Boxes
  await Hive.openBox('settings');
  await Hive.openBox(AuthService.teacherBoxName);
  await Hive.openBox<PendingAction>(PendingQueueService.boxName);
  await Hive.openBox<GroupClass>(SyncService.groupsBoxName);
  await Hive.openBox<ScheduleSlot>(SyncService.schedulesBoxName);
  await Hive.openBox<Student>(SyncService.studentsBoxName);
  await Hive.openBox<AttendanceRecord>(SyncService.attendancesBoxName);

  // Initialize Get Services
  Get.put(ConnectivityService(), permanent: true);
  Get.put(SheetsService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(PendingQueueService(), permanent: true);
  Get.put(SyncService(), permanent: true);

  // System UI Overlay (Translucent status bar on dark theme)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const EdumindPresenceApp());
}

class EdumindPresenceApp extends StatelessWidget {
  const EdumindPresenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return Obx(() {
      final lang = auth.currentLang.value;

      return GetMaterialApp(
        title: 'EDUMIND Présence',
        debugShowCheckedModeBanner: false,
        theme: EdumindTheme.darkTheme(lang),
        darkTheme: EdumindTheme.darkTheme(lang),
        themeMode: ThemeMode.dark,
        locale: Locale(lang),
        fallbackLocale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('fr'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      );
    });
  }
}
