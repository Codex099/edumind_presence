import 'package:flutter/material.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _values = {
    'ar': {
      'app_title': 'EDUMIND الحضور والغياب',
      'app_subtitle': 'نظام تسجيل الحضور واليوميات المدرسية',
      'login': 'تسجيل الدخول',
      'login_title': 'منصة الأستاذ',
      'login_subtitle': 'تسجيل الدخول برقم الهاتف وكلمة المرور أو PIN',
      'phone_number': 'رقم الهاتف',
      'phone_hint': '05 / 06 / 07 XX XX XX XX',
      'password_or_pin': 'كلمة المرور أو رمز PIN',
      'pin_hint': 'أدخل كلمة المرور أو 4 أرقام',
      'remember_me': 'تذكرني على هذا الهاتف',
      'btn_login': 'دخول إلى حسابي',
      'logging_in': 'جاري التحقق من الحساب...',
      'login_error': 'رقم الهاتف أو كلمة المرور غير صحيحة',
      'phone_required': 'يرجى إدخال رقم الهاتف',
      'pass_required': 'يرجى إدخال كلمة المرور أو رمز PIN',
      
      // Home & Smart Timetable
      'welcome_teacher': 'مرحباً، أستاذ',
      'today_schedule': 'جدول اليوم',
      'current_session': 'الحصة الحالية',
      'free_period_title': 'وقت فراغ نظامي',
      'free_period_desc': 'ليس لديك حصة مبرمجة حالياً حسب جدول التوقيت الأسبوعي',
      'next_session': 'الحصة القادمة',
      'room': 'القاعة',
      'class_group': 'القسم',
      'subject': 'المادة',
      'time': 'التوقيت',
      'mark_attendance': 'تسجيل الحضور الآن',
      'manual_selection': 'اختيار قسم يدوي (حصة استدراكية)',
      'all_sessions_done': 'اكتملت جميع حصص اليوم بنجاح',
      'no_schedule_today': 'لا توجد حصص مبرمجة لهذا اليوم',
      
      // Attendance Sheet
      'attendance_sheet': 'ورقة المناداة',
      'total_students': 'مجموع التلاميذ',
      'present_count': 'حاضر',
      'absent_count': 'غائب',
      'late_count': 'متأخر',
      'tap_tip': 'المس اسم التلميذ لتغيير حالته: أحمر (غائب) · برتقالي (متأخر) · أخضر (حاضر)',
      'search_student': 'بحث عن تلميذ بالاسم أو رقم القيد...',
      'confirm_submit': 'تأكيد وإرسال ورقة الحضور',
      'submitting': 'جاري إرسال البيانات للسحابة...',
      'saved_online': 'تم حفظ ورقة الحضور بنجاح في السحابة',
      'saved_offline': 'تم الحفظ محلياً في الهاتف — بانتظار توفر الإنترنت للمزامنة',
      'add_note': 'إضافة ملاحظة',
      'note_hint': 'سبب الغياب أو ملاحظة تربوية...',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      
      // History
      'history_title': 'سجل الحصص السابقة',
      'synced': 'تمت المزامنة',
      'pending_sync': 'بانتظار المزامنة',
      'empty_history': 'لا توجد أوراق حضور مسجلة مؤخراً',
      'sync_now': 'مزامنة السجلات المعلقة',
      'all_synced': 'جميع السجلات متزامنة بنجاح مع السحابة',
      
      // Settings
      'settings': 'الإعدادات',
      'script_url': 'رابط السحابة (Google Apps Script Web App)',
      'script_url_desc': 'الرابط البرمجي لجدول Google Sheets للمؤسسة',
      'language': 'اللغة / Langue',
      'arabic': 'العربية (Arabic)',
      'french': 'الفرنسية (Français)',
      'dark_mode': 'الوضع الليلي (Dark Mode)',
      'offline_status': 'حالة الاتصال',
      'online': 'متصل بالإنترنت',
      'offline': 'وضع عدم الاتصال (أوفلاين)',
      'logout': 'تسجيل الخروج',
      'confirm_logout': 'هل تريد بالفعل تسجيل الخروج من هذا الهاتف؟',
      'yes': 'نعم',
      'no': 'لا',
      'app_version': 'الإصدار 2.0.0 (EDUMIND Attendance)',
    },
    'fr': {
      'app_title': 'EDUMIND Présence',
      'app_subtitle': 'Système de gestion des présences et cahier d\'appel',
      'login': 'Connexion',
      'login_title': 'Espace Enseignant',
      'login_subtitle': 'Connexion avec n° de téléphone et mot de passe ou code PIN',
      'phone_number': 'Numéro de téléphone',
      'phone_hint': '05 / 06 / 07 XX XX XX XX',
      'password_or_pin': 'Mot de passe ou Code PIN',
      'pin_hint': 'Entrez le mot de passe ou 4 chiffres',
      'remember_me': 'Se souvenir de moi sur ce téléphone',
      'btn_login': 'Se connecter',
      'logging_in': 'Vérification du compte...',
      'login_error': 'Numéro de téléphone ou mot de passe incorrect',
      'phone_required': 'Veuillez saisir votre numéro de téléphone',
      'pass_required': 'Veuillez saisir votre mot de passe ou PIN',

      // Home & Smart Timetable
      'welcome_teacher': 'Bienvenue, Professeur',
      'today_schedule': 'Planning d\'aujourd\'hui',
      'current_session': 'Séance en cours',
      'free_period_title': 'Heure de permanence / Temps libre',
      'free_period_desc': 'Aucune séance programmée pour vous à cette heure selon l\'emploi du temps',
      'next_session': 'Prochaine séance',
      'room': 'Salle',
      'class_group': 'Classe',
      'subject': 'Matière',
      'time': 'Horaire',
      'mark_attendance': 'Faire l\'appel maintenant',
      'manual_selection': 'Sélectionner une classe (Rattrapage / Remplacement)',
      'all_sessions_done': 'Toutes les séances du jour sont terminées',
      'no_schedule_today': 'Aucun cours programmé aujourd\'hui',

      // Attendance Sheet
      'attendance_sheet': 'Feuille d\'appel',
      'total_students': 'Total élèves',
      'present_count': 'Présent(s)',
      'absent_count': 'Absent(s)',
      'late_count': 'En retard',
      'tap_tip': 'Touchez un élève pour changer son état : Rouge (Absent) · Orange (Retard) · Vert (Présent)',
      'search_student': 'Rechercher un élève par nom ou matricule...',
      'confirm_submit': 'Confirmer et envoyer la feuille',
      'submitting': 'Envoi des données vers le cloud...',
      'saved_online': 'Feuille d\'appel enregistrée avec succès sur le cloud',
      'saved_offline': 'Enregistré localement — En attente du réseau pour synchronisation',
      'add_note': 'Ajouter une note',
      'note_hint': 'Motif d\'absence ou remarque...',
      'cancel': 'Annuler',
      'save': 'Enregistrer',

      // History
      'history_title': 'Historique des appels',
      'synced': 'Synchronisé',
      'pending_sync': 'En attente',
      'empty_history': 'Aucun appel enregistré récemment',
      'sync_now': 'Synchroniser les éléments en attente',
      'all_synced': 'Toutes les feuilles sont synchronisées avec le cloud',

      // Settings
      'settings': 'Paramètres',
      'script_url': 'URL Google Apps Script (Web App)',
      'script_url_desc': 'Lien vers l\'API Google Sheets de l\'établissement',
      'language': 'Langue / اللغة',
      'arabic': 'Arabe (العربية)',
      'french': 'Français (French)',
      'dark_mode': 'Mode Sombre',
      'offline_status': 'Statut réseau',
      'online': 'En ligne',
      'offline': 'Hors ligne (Mode local)',
      'logout': 'Déconnexion',
      'confirm_logout': 'Voulez-vous vraiment vous déconnecter ?',
      'yes': 'Oui',
      'no': 'Non',
      'app_version': 'Version 2.0.0 (EDUMIND Attendance)',
    }
  };

  static String get(String key, {String lang = 'ar'}) {
    final map = _values[lang] ?? _values['ar']!;
    return map[key] ?? key;
  }
}

extension TranslationExtension on String {
  String tr(BuildContext context) {
    // Simple lookup using default or InheritedLocale
    return AppTranslations.get(this, lang: 'ar');
  }

  String trLang(String lang) {
    return AppTranslations.get(this, lang: lang);
  }
}
