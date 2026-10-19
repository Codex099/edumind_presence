import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/theme.dart';
import '../utils/translations.dart';
import '../services/sheets_service.dart';
import 'home_timetable_screen.dart';
import 'qr_link_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _secretController = TextEditingController();
  bool _rememberMe = true;
  bool _obscureSecret = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  void _loadSavedPhone() {
    try {
      final box = Hive.box('settings');
      final lastPhone = box.get('lastPhone', defaultValue: '');
      if (lastPhone.isNotEmpty) {
        _phoneController.text = lastPhone;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final secret = _secretController.text.trim();
    final auth = Get.find<AuthService>();
    final lang = auth.currentLang.value;

    if (phone.isEmpty) {
      setState(() => _errorMessage = AppTranslations.get('phone_required', lang: lang));
      return;
    }
    if (secret.isEmpty) {
      setState(() => _errorMessage = AppTranslations.get('pass_required', lang: lang));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await auth.login(phone, secret, remember: _rememberMe);

    if (result['success'] == true && mounted) {
      // Sync teacher data
      await Get.find<SyncService>().refreshTeacherData();
      Get.offAll(() => const HomeTimetableScreen());
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = result['error'] ?? AppTranslations.get('login_error', lang: lang);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return Obx(() {
      final lang = auth.currentLang.value;
      final isAr = lang == 'ar';

      return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: EdumindTheme.bgDark,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Language Switch Pill at top
                    Align(
                      alignment: isAr ? Alignment.topLeft : Alignment.topRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: EdumindTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: EdumindTheme.borderDark),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            auth.setLanguage(isAr ? 'fr' : 'ar');
                          },
                          icon: const Icon(Icons.language, size: 16, color: EdumindTheme.accentCyan),
                          label: Text(
                            isAr ? 'Français' : 'العربية',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Brand Header
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: EdumindTheme.primaryBlue.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppTranslations.get('login_title', lang: lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppTranslations.get('login_subtitle', lang: lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error Alert Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: EdumindTheme.absentBgDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: EdumindTheme.absentRed.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: EdumindTheme.absentRed, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: EdumindTheme.absentRed, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Phone Number Input
                    Text(
                      AppTranslations.get('phone_number', lang: lang),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: AppTranslations.get('phone_hint', lang: lang),
                        prefixIcon: const Icon(Icons.phone_iphone_rounded, color: EdumindTheme.primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password or PIN Input
                    Text(
                      AppTranslations.get('password_or_pin', lang: lang),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _secretController,
                      obscureText: _obscureSecret,
                      decoration: InputDecoration(
                        hintText: AppTranslations.get('pin_hint', lang: lang),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: EdumindTheme.primaryBlue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSecret ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                        ),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 14),

                    // Remember Me Checkbox
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: EdumindTheme.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: Text(
                            AppTranslations.get('remember_me', lang: lang),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              AppTranslations.get('btn_login', lang: lang),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Linked School Info & Change QR Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: EdumindTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EdumindTheme.borderDark),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded, size: 20, color: EdumindTheme.accentCyan),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'المؤسسة المرتبطة :' : 'Établissement lié :',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  Get.find<SheetsService>().schoolName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => Get.to(() => const QrLinkScreen(canGoBack: true)),
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                            label: Text(
                              isAr ? 'تغيير' : 'Changer',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: EdumindTheme.accentCyan,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Demo Helper Box for Quick Testing
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: EdumindTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EdumindTheme.primaryBlue.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: EdumindTheme.accentCyan),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isAr ? 'حساب تجريبي للاختبار الفوري :' : 'Compte Démo pour test immédiat :',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('📱 0550000000', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                              const Text('🔑 PIN: 1234', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                              InkWell(
                                onTap: () {
                                  _phoneController.text = '0550000000';
                                  _secretController.text = '1234';
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: EdumindTheme.primaryBlue.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAr ? 'ملء تلقائي' : 'Remplir',
                                    style: const TextStyle(fontSize: 11, color: EdumindTheme.accentCyan, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer Version
                    Center(
                      child: Text(
                        AppTranslations.get('app_version', lang: lang),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
