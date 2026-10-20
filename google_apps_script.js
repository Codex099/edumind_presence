/**
 * ==========================================================================
 *  EDUMIND SCOLAIRE — Google Apps Script Backend (API Cloud & Base de Données)
 *  نظام إدارة حضور وغياب التلاميذ — تطبيق الأستاذ والربط السحابي
 * ==========================================================================
 */

const TEACHERS_SHEET    = 'teachers';
const GROUPS_SHEET      = 'groups';
const SCHEDULES_SHEET   = 'schedules';
const STUDENTS_SHEET    = 'students';
const ATTENDANCES_SHEET = 'attendances';
const CONFIG_SHEET      = 'config';

const TEACHER_HEADERS = ['id', 'matricule', 'name', 'phone', 'password', 'pin', 'subject', 'active', 'updated_at'];
const GROUP_HEADERS   = ['id', 'name', 'level_id', 'level_name', 'subject_name', 'room_name', 'teacher_id', 'updated_at'];
const SCHEDULE_HEADERS = ['id', 'group_id', 'group_name', 'teacher_id', 'teacher_name', 'day_of_week', 'start_time', 'end_time', 'room_name', 'subject_name', 'updated_at'];
const STUDENT_HEADERS  = ['id', 'matricule', 'first_name', 'last_name', 'full_name', 'group_id', 'group_name', 'photo_url', 'active', 'updated_at'];
const ATTENDANCE_HEADERS = ['id', 'session_date', 'time_slot', 'group_id', 'group_name', 'subject_name', 'room_name', 'teacher_id', 'teacher_name', 'student_id', 'student_matricule', 'student_name', 'status', 'note', 'synced_desktop', 'timestamp', 'created_at'];

// ══════════════════════════════════════════════════════════════
//  HELPER: NORMALISATION DU NUMÉRO DE TÉLÉPHONE (Conserve le 0)
// ══════════════════════════════════════════════════════════════
function normalizePhone(p) {
  if (!p) return '';
  let str = String(p).trim();
  if (str.startsWith("'")) str = str.slice(1);
  let digits = str.replace(/\D/g, '');
  if (digits.startsWith('213') && digits.length === 12) {
    digits = '0' + digits.slice(3);
  }
  // Si le numéro a 9 chiffres (ex: 555123456 car le 0 a sauté), restaurer le 0 initial
  if (digits.length === 9 && !digits.startsWith('0')) {
    digits = '0' + digits;
  }
  return digits;
}

// ══════════════════════════════════════════════════════════════
//  ROUTAGE GET
// ══════════════════════════════════════════════════════════════

function doGet(e) {
  const params = (e && e.parameter) || {};
  const action = params.action || 'ping';

  try {
    if (action === 'ping') {
      return jsonResponse({ status: 'ok', app: 'EDUMIND Presence', version: '2.1.0', ts: new Date().toISOString() });
    }
    if (action === 'setup_headers') {
      return jsonResponse(setupAllSheets());
    }
    if (action === 'get_config_last_modified') {
      return jsonResponse({ lastModified: getConfigLastModified() });
    }
    if (action === 'login_teacher') {
      const phone = (params.phone || '').trim();
      const pass = (params.password || params.pin || '').trim();
      return jsonResponse(loginTeacher(phone, pass));
    }
    if (action === 'get_teacher_data') {
      const teacherId = params.teacher_id;
      return jsonResponse(getTeacherData(teacherId));
    }
    if (action === 'get_attendances') {
      const teacherId = params.teacher_id;
      const date = params.date;
      const syncedDesktop = params.synced_desktop;
      return jsonResponse(getAttendances({ teacherId, date, syncedDesktop }));
    }
    if (action === 'get_all_teachers') {
      return jsonResponse(getAllRecords(TEACHERS_SHEET));
    }
    if (action === 'get_all_groups') {
      return jsonResponse(getAllRecords(GROUPS_SHEET));
    }
    if (action === 'get_all_students') {
      return jsonResponse(getAllRecords(STUDENTS_SHEET));
    }
    if (action === 'get_all_schedules') {
      return jsonResponse(getAllRecords(SCHEDULES_SHEET));
    }

    return jsonResponse({ error: 'Action non reconnue: ' + action });
  } catch (err) {
    return jsonResponse({ error: err.toString() });
  }
}

// ══════════════════════════════════════════════════════════════
//  ROUTAGE POST
// ══════════════════════════════════════════════════════════════

function doPost(e) {
  let payload;
  try {
    payload = JSON.parse(e.postData.contents);
  } catch (err) {
    return jsonResponse({ error: 'Invalid JSON payload' });
  }

  const action = payload.action;

  try {
    switch (action) {
      case 'login_teacher':
        return jsonResponse(loginTeacher(payload.phone, payload.password || payload.pin));

      case 'submit_attendance_sheet':
        return jsonResponse(submitAttendanceSheet(payload.data));

      case 'sync_desktop_data':
        // Synchronisation globale envoyée par le logiciel de bureau EDUMIND
        return jsonResponse(syncDesktopData(payload.data));

      case 'mark_attendances_synced':
        return jsonResponse(markAttendancesSynced(payload.ids));

      case 'upsert_teacher':
        return jsonResponse(upsertTeacher(payload.data));

      case 'setup_headers':
        return jsonResponse(setupAllSheets());

      default:
        return jsonResponse({ error: 'Action inconnue: ' + action });
    }
  } catch (err) {
    return jsonResponse({ error: err.toString() });
  }
}

// ══════════════════════════════════════════════════════════════
//  FONCTIONS MÉTIER
// ══════════════════════════════════════════════════════════════

/**
 * Connexion de l'enseignant par téléphone et mot de passe ou code PIN
 */
function loginTeacher(phone, secret) {
  if (!phone || !secret) {
    return { success: false, error: 'Numéro de téléphone et mot de passe/PIN requis' };
  }

  const cleanPhone = normalizePhone(phone);
  const teachers = getAllRecords(TEACHERS_SHEET);

  const teacher = teachers.find(t => {
    const tPhone = normalizePhone(t.phone);
    const active = String(t.active) === '1' || t.active === true || t.active === 'true';
    if (!active) return false;

    const phoneMatch = (tPhone === cleanPhone) || (tPhone.endsWith(cleanPhone) || cleanPhone.endsWith(tPhone));
    if (!phoneMatch) return false;

    const passMatch = String(t.password || '').trim() === String(secret).trim();
    const pinMatch  = String(t.pin || '').trim() === String(secret).trim();
    return passMatch || pinMatch;
  });

  if (!teacher) {
    return { success: false, error: 'Identifiants invalides ou compte enseignant inactif' };
  }

  // Ne pas renvoyer le mot de passe dans la réponse
  const safeTeacher = Object.assign({}, teacher);
  delete safeTeacher.password;

  return {
    success: true,
    teacher: safeTeacher,
    data: getTeacherData(teacher.id)
  };
}

/**
 * Récupère le bundle complet des données de l'enseignant (classes, élèves, emploi du temps)
 */
function getTeacherData(teacherId) {
  if (!teacherId) return { groups: [], schedules: [], students: [] };

  const sTeacherId = String(teacherId);

  // 1. Emploi du temps de l'enseignant
  const allSchedules = getAllRecords(SCHEDULES_SHEET);
  const schedules = allSchedules.filter(s => String(s.teacher_id) === sTeacherId);

  // Groupes assignés à l'enseignant
  const assignedGroupIds = new Set();
  schedules.forEach(s => {
    if (s.group_id) assignedGroupIds.add(String(s.group_id));
  });

  // 2. Groupes
  const allGroups = getAllRecords(GROUPS_SHEET);
  const groups = allGroups.filter(g => assignedGroupIds.has(String(g.id)) || String(g.teacher_id) === sTeacherId);
  groups.forEach(g => assignedGroupIds.add(String(g.id)));

  // 3. Élèves de ces groupes
  const allStudents = getAllRecords(STUDENTS_SHEET);
  const students = allStudents.filter(st => {
    const active = String(st.active) === '1' || st.active === true || st.active === 'true';
    return active && assignedGroupIds.has(String(st.group_id));
  });

  return {
    schedules: schedules,
    groups: groups,
    students: students
  };
}

/**
 * Enregistrement par lot d'une feuille d'appel pour une séance
 */
function submitAttendanceSheet(data) {
  if (!data || !Array.isArray(data.records) || data.records.length === 0) {
    return { success: false, error: 'Aucun enregistrement de présence fourni' };
  }

  const sheet = getOrCreateSheet(ATTENDANCES_SHEET, ATTENDANCE_HEADERS);
  const now = new Date();
  const nowIso = now.toISOString();
  const nowTs = now.getTime();

  // Lecture des clés existantes pour éviter les doublons (idempotence)
  const existingRows = sheet.getDataRange().getValues();
  const keyIndexMap = {};
  if (existingRows.length > 1) {
    for (let i = 1; i < existingRows.length; i++) {
      const r = existingRows[i];
      const key = `${r[1]}_${r[2]}_${r[3]}_${r[9]}`; // date_timeslot_group_student
      keyIndexMap[key] = i + 1; // 1-indexed row
    }
  }

  const rowsToAppend = [];
  let updatedCount = 0;
  let insertedCount = 0;

  data.records.forEach(rec => {
    const key = `${rec.session_date}_${rec.time_slot}_${rec.group_id}_${rec.student_id}`;
    const rowValues = [
      rec.id || ('att_' + Utilities.getUuid().slice(0, 8)),
      rec.session_date || '',
      rec.time_slot || '',
      rec.group_id || '',
      rec.group_name || '',
      rec.subject_name || '',
      rec.room_name || '',
      rec.teacher_id || '',
      rec.teacher_name || '',
      rec.student_id || '',
      rec.student_matricule ? "'" + String(rec.student_matricule) : '',
      rec.student_name || '',
      rec.status || 'present',
      rec.note || '',
      0, // synced_desktop = 0
      nowTs,
      nowIso
    ];

    if (keyIndexMap[key]) {
      const rowNum = keyIndexMap[key];
      sheet.getRange(rowNum, 1, 1, ATTENDANCE_HEADERS.length).setValues([rowValues]);
      updatedCount++;
    } else {
      rowsToAppend.push(rowValues);
      insertedCount++;
    }
  });

  if (rowsToAppend.length > 0) {
    sheet.getRange(sheet.getLastRow() + 1, 1, rowsToAppend.length, ATTENDANCE_HEADERS.length).setValues(rowsToAppend);
  }

  bumpLastModified();

  return {
    success: true,
    message: 'Feuille de présence enregistrée avec succès',
    inserted: insertedCount,
    updated: updatedCount,
    total: data.records.length
  };
}

/**
 * Récupère les présences avec filtres
 */
function getAttendances(filters) {
  const records = getAllRecords(ATTENDANCES_SHEET);
  return records.filter(r => {
    if (filters.teacherId && String(r.teacher_id) !== String(filters.teacherId)) return false;
    if (filters.date && String(r.session_date) !== String(filters.date)) return false;
    if (filters.syncedDesktop !== undefined && String(r.synced_desktop) !== String(filters.syncedDesktop)) return false;
    return true;
  });
}

/**
 * Marque les absences comme synchronisées vers le bureau
 */
function markAttendancesSynced(ids) {
  if (!ids || !Array.isArray(ids) || ids.length === 0) {
    return { success: true, count: 0 };
  }

  const sheet = getOrCreateSheet(ATTENDANCES_SHEET, ATTENDANCE_HEADERS);
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return { success: true, count: 0 };

  const idSet = new Set(ids.map(String));
  const idCol = ATTENDANCE_HEADERS.indexOf('id');
  const syncCol = ATTENDANCE_HEADERS.indexOf('synced_desktop');

  let count = 0;
  for (let i = 1; i < data.length; i++) {
    if (idSet.has(String(data[i][idCol]))) {
      sheet.getRange(i + 1, syncCol + 1).setValue(1);
      count++;
    }
  }

  return { success: true, count: count };
}

/**
 * Synchronisation globale par EDUMIND-SCOLAIRE (Bureau)
 */
function syncDesktopData(data) {
  if (!data) return { success: false, error: 'Aucune donnée reçue' };

  if (Array.isArray(data.teachers)) {
    overwriteSheetData(TEACHERS_SHEET, TEACHER_HEADERS, data.teachers);
  }
  if (Array.isArray(data.groups)) {
    overwriteSheetData(GROUPS_SHEET, GROUP_HEADERS, data.groups);
  }
  if (Array.isArray(data.schedules)) {
    overwriteSheetData(SCHEDULES_SHEET, SCHEDULE_HEADERS, data.schedules);
  }
  if (Array.isArray(data.students)) {
    overwriteSheetData(STUDENTS_SHEET, STUDENT_HEADERS, data.students);
  }

  bumpLastModified();

  return {
    success: true,
    message: 'Données scolaires synchronisées avec succès vers Google Sheets'
  };
}

/**
 * Ajout ou modification d'un enseignant (Admin)
 */
function upsertTeacher(teacherData) {
  if (!teacherData || !teacherData.phone) {
    return { success: false, error: 'Numéro de téléphone requis' };
  }

  const sheet = getOrCreateSheet(TEACHERS_SHEET, TEACHER_HEADERS);
  const data = sheet.getDataRange().getValues();
  const phoneCol = TEACHER_HEADERS.indexOf('phone');
  const idCol = TEACHER_HEADERS.indexOf('id');

  const cleanPhone = normalizePhone(teacherData.phone);
  let foundRow = -1;

  for (let i = 1; i < data.length; i++) {
    const rowPhone = normalizePhone(data[i][phoneCol]);
    const rowId = String(data[i][idCol]);
    if (rowPhone === cleanPhone || (teacherData.id && rowId === String(teacherData.id))) {
      foundRow = i + 1;
      break;
    }
  }

  // Format phone & pin columns as text to retain leading zeroes
  sheet.getRange(2, phoneCol + 1, Math.max(data.length, 50), 1).setNumberFormat('@');

  const rowValues = TEACHER_HEADERS.map(h => {
    if (h === 'updated_at') return new Date().toISOString();
    let val = teacherData[h] !== undefined ? teacherData[h] : '';
    if (h === 'phone') {
      const p = normalizePhone(val);
      return p ? "'" + p : '';
    }
    if (h === 'pin' || h === 'matricule') {
      let str = String(val).trim();
      if (str.startsWith("'")) str = str.slice(1);
      return str ? "'" + str : '';
    }
    return val;
  });

  if (foundRow > 0) {
    sheet.getRange(foundRow, 1, 1, TEACHER_HEADERS.length).setValues([rowValues]);
  } else {
    if (!teacherData.id) rowValues[idCol] = 't_' + Utilities.getUuid().slice(0, 8);
    sheet.appendRow(rowValues);
  }

  bumpLastModified();
  return { success: true, message: 'Enseignant enregistré' };
}

// ══════════════════════════════════════════════════════════════
//  UTILITAIRES FEUILLES & FORMATAGE
// ══════════════════════════════════════════════════════════════

function getOrCreateSheet(name, headers) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(name);
  if (!sheet) {
    sheet = ss.insertSheet(name);
    if (headers && headers.length > 0) {
      sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
      styleHeaderRow(sheet, headers.length);
    }
  } else if (headers && headers.length > 0 && sheet.getLastRow() === 0) {
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    styleHeaderRow(sheet, headers.length);
  }
  return sheet;
}

function styleHeaderRow(sheet, colCount) {
  const range = sheet.getRange(1, 1, 1, colCount);
  range.setBackground('#0A1124'); // EDUMIND Deep Navy
  range.setFontColor('#FFFFFF');
  range.setFontWeight('bold');
  sheet.setFrozenRows(1);
}

function setupAllSheets() {
  getOrCreateSheet(TEACHERS_SHEET, TEACHER_HEADERS);
  getOrCreateSheet(GROUPS_SHEET, GROUP_HEADERS);
  getOrCreateSheet(SCHEDULES_SHEET, SCHEDULE_HEADERS);
  getOrCreateSheet(STUDENTS_SHEET, STUDENT_HEADERS);
  getOrCreateSheet(ATTENDANCES_SHEET, ATTENDANCE_HEADERS);
  getOrCreateConfigSheet();
  return { success: true, message: 'Toutes les feuilles EDUMIND ont été initialisées avec succès' };
}

function getOrCreateConfigSheet() {
  const sheet = getOrCreateSheet(CONFIG_SHEET, ['key', 'value']);
  if (sheet.getLastRow() <= 1) {
    sheet.appendRow(['lastModified', String(Date.now())]);
    sheet.appendRow(['schoolName', 'EDUMIND SCOLAIRE']);
  }
  return sheet;
}

function getConfigLastModified() {
  const sheet = getOrCreateConfigSheet();
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === 'lastModified') return String(data[i][1]);
  }
  return '0';
}

function bumpLastModified() {
  const sheet = getOrCreateConfigSheet();
  const data = sheet.getDataRange().getValues();
  const now = String(Date.now());
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === 'lastModified') {
      sheet.getRange(i + 1, 2).setValue(now);
      return;
    }
  }
  sheet.appendRow(['lastModified', now]);
}

function getAllRecords(sheetName) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const results = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const obj = {};
    for (let c = 0; c < headers.length; c++) {
      const h = headers[c];
      let val = row[c];
      if (h === 'phone') {
        val = normalizePhone(val);
      } else if (h === 'pin' || h === 'matricule') {
        let s = String(val !== undefined && val !== null ? val : '').trim();
        if (s.startsWith("'")) s = s.slice(1);
        val = s;
      } else if (h === 'start_time' || h === 'end_time') {
        if (val instanceof Date) {
          const hours = String(val.getHours()).padStart(2, '0');
          const minutes = String(val.getMinutes()).padStart(2, '0');
          val = `${hours}:${minutes}`;
        }
        let s = String(val !== undefined && val !== null ? val : '').trim();
        if (s.startsWith("'")) s = s.slice(1);
        val = s;
      } else if (h === 'session_date') {
        if (val instanceof Date) {
          const y = val.getFullYear();
          const m = String(val.getMonth() + 1).padStart(2, '0');
          const d = String(val.getDate()).padStart(2, '0');
          val = `${y}-${m}-${d}`;
        } else {
          let s = String(val !== undefined && val !== null ? val : '').trim();
          if (s.startsWith("'")) s = s.slice(1);
          val = s;
        }
      }
      obj[h] = val;
    }
    results.push(obj);
  }
  return results;
}

function overwriteSheetData(sheetName, headers, records) {
  const sheet = getOrCreateSheet(sheetName, headers);
  sheet.clearContents();
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  styleHeaderRow(sheet, headers.length);

  if (!records || records.length === 0) return;

  const totalRows = Math.max(records.length, 50);

  // 1. Appliquer le format Texte brut '@' sur toutes les colonnes pour forcer Google Sheets à garder les zéros initiaux
  sheet.getRange(2, 1, totalRows, headers.length).setNumberFormat('@');

  const rows = records.map(rec => {
    return headers.map(h => {
      let val = rec[h];
      if (val === undefined || val === null) return '';

      // Conserver le 0 initial pour le téléphone
      if (h === 'phone') {
        const p = normalizePhone(val);
        return p ? ("'" + p) : ''; // L'apostrophe force Google Sheets à conserver le 0
      }

      // Conserver les zéros pour PIN ou matricule
      if (h === 'pin' || h === 'matricule' || h === 'student_matricule') {
        let str = String(val).trim();
        if (str.startsWith("'")) str = str.slice(1);
        return str ? ("'" + str) : '';
      }

      if (h === 'start_time' || h === 'end_time') {
        let str = String(val).trim();
        if (str.startsWith("'")) str = str.slice(1);
        return str ? ("'" + str) : '';
      }

      return val;
    });
  });

  sheet.getRange(2, 1, rows.length, headers.length).setValues(rows);
}

function jsonResponse(data) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
