import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../services/sheets_service.dart';
import '../utils/theme.dart';
import 'login_screen.dart';

class QrLinkScreen extends StatefulWidget {
  final bool canGoBack;

  const QrLinkScreen({super.key, this.canGoBack = false});

  @override
  State<QrLinkScreen> createState() => _QrLinkScreenState();
}

class _QrLinkScreenState extends State<QrLinkScreen> {
  final SheetsService _sheetsService = Get.find<SheetsService>();
  final AuthService _authService = Get.find<AuthService>();

  late MobileScannerController _scannerController;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _showManualInput = false;
  double _currentZoom = 1.0;
  final TextEditingController _manualUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Optimized specifically for budget hardware (MediaTek Helio G85 on Redmi Note 9)
    // 1. Restrict formats to QR Code only (drops CPU load by 80%)
    // 2. Disable returnImage bitmap allocations
    // 3. noDuplicates detection speed to avoid redundant frames
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualUrlController.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _currentZoom = _currentZoom == 1.0 ? 2.0 : 1.0;
    });
    try {
      _scannerController.setZoomScale(_currentZoom);
    } catch (_) {}
  }

  Future<void> _handleScannedData(String raw) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    String targetUrl = raw.trim();
    String? schoolName;

    // Check if payload is JSON
    if (targetUrl.startsWith('{') && targetUrl.endsWith('}')) {
      try {
        final decoded = jsonDecode(targetUrl);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('url')) {
            targetUrl = decoded['url'].toString().trim();
          }
          if (decoded.containsKey('school')) {
            schoolName = decoded['school'].toString().trim();
          }
        }
      } catch (_) {}
    }

    final success = await _sheetsService.linkSchool(url: targetUrl, name: schoolName);

    if (!mounted) return;

    if (success) {
      final lang = _authService.currentLang.value;
      final isAr = lang == 'ar';
      final displayName = schoolName ?? _sheetsService.schoolName;

      Get.snackbar(
        isAr ? 'تم ربط المؤسسة بنجاح' : 'Établissement lié',
        isAr ? 'تم الاتصال بنجاح مع $displayName' : 'Connexion réussie avec $displayName',
        backgroundColor: EdumindTheme.presentGreen.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        duration: const Duration(seconds: 3),
      );

      // Navigate to login
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Get.offAll(() => const LoginScreen());
      }
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = _authService.currentLang.value == 'ar'
            ? 'تعذر الاتصال بالرابط. تأكد من صحة رمز QR وتوفر الإنترنت.'
            : 'Échec de connexion. Vérifiez le QR Code et la connexion internet.';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _manualUrlController.text = data.text!.trim();
      setState(() {});
    }
  }

  void _submitManualUrl() {
    final text = _manualUrlController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = _authService.currentLang.value == 'ar'
            ? 'يرجى إدخال الرابط أولاً'
            : 'Veuillez saisir un lien valide';
      });
      return;
    }
    _handleScannedData(text);
  }

  @override
  Widget build(BuildContext context) {
    final lang = _authService.currentLang.value;
    final isAr = lang == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: EdumindTheme.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.canGoBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Text(
            isAr ? 'ربط المؤسسة التعليمية' : 'Lier l\'Établissement',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            if (!_showManualInput) ...[
              // Zoom Scale Toggle (Essential for Redmi Note 9 camera minimum focus distance)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _currentZoom > 1.0 ? EdumindTheme.accentCyan.withValues(alpha: 0.25) : Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentZoom > 1.0 ? EdumindTheme.accentCyan : Colors.white24,
                    ),
                  ),
                  child: Text(
                    '${_currentZoom.toInt()}x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _currentZoom > 1.0 ? EdumindTheme.accentCyan : Colors.white,
                    ),
                  ),
                ),
                tooltip: 'Zoom',
                onPressed: _toggleZoom,
              ),
              // Torch / Flashlight Toggle
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: _scannerController,
                builder: (context, state, child) {
                  final isOn = state.torchState == TorchState.on;
                  return IconButton(
                    icon: Icon(
                      isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: isOn ? EdumindTheme.accentCyan : Colors.white70,
                    ),
                    tooltip: 'Flash',
                    onPressed: () => _scannerController.toggleTorch(),
                  );
                },
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Header description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      isAr
                          ? 'امسح رمز QR المعروض في برنامج الإدارة'
                          : 'Scannez le QR Code affiché sur le logiciel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? 'افتح الإعدادات ➔ تطبيق الأساتذة (Google Sheets) في حاسوب الإدارة لمسح الرمز وربط هاتفك فوراً.'
                          : 'Ouvrez Paramètres ➔ Application Mobile dans le logiciel EDUMIND pour scanner le code.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Scanner / Manual View
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Live Scanner
                        if (!_showManualInput)
                          MobileScanner(
                            controller: _scannerController,
                            errorBuilder: (context, error) {
                              return Container(
                                color: EdumindTheme.cardDark,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.videocam_off_rounded,
                                      size: 48,
                                      color: EdumindTheme.lateOrange,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isAr ? 'تعذر تشغيل الكاميرا' : 'Accès caméra indisponible',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isAr
                                          ? 'تأكد من تفعيل إذن الكاميرا لتطبيق EDUMIND في إعدادات الهاتف، أو استخدم خيار الإدخال اليدوي.'
                                          : 'Vérifiez l\'autorisation de la caméra dans les paramètres de votre téléphone, ou utilisez la saisie manuelle.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _showManualInput = true;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: EdumindTheme.primaryBlue,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.keyboard_rounded, size: 18),
                                      label: Text(
                                        isAr ? 'إدخال الرابط يدوياً' : 'Saisie manuelle du lien',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDetect: (capture) {
                              if (_isProcessing) return;
                              final barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final val = barcode.rawValue ?? barcode.displayValue;
                                if (val != null && val.trim().isNotEmpty) {
                                  _handleScannedData(val.trim());
                                  break;
                                }
                              }
                            },
                          )
                        else
                          Container(
                            color: EdumindTheme.cardDark,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  size: 48,
                                  color: EdumindTheme.accentCyan,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isAr
                                      ? 'إدخال رابط السحابة يدوياً'
                                      : 'Saisie manuelle du lien Web App',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isAr
                                      ? 'الصق رابط Google Apps Script Web App المنتهي بـ /exec'
                                      : 'Collez le lien Google Apps Script se terminant par /exec',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _manualUrlController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: EdumindTheme.bgDark,
                                    hintText: 'https://script.google.com/macros/s/.../exec',
                                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.paste_rounded, color: EdumindTheme.accentCyan, size: 20),
                                      tooltip: isAr ? 'لصق من الحافظة' : 'Coller le lien',
                                      onPressed: _pasteFromClipboard,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: EdumindTheme.borderDark),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: EdumindTheme.borderDark),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: EdumindTheme.accentCyan),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitManualUrl,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: EdumindTheme.accentCyan,
                                      foregroundColor: const Color(0xFF0F172A),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      isAr ? 'ربط وتحقق من الاتصال' : 'Valider et connecter',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Viewfinder Overlay Reticle
                        if (!_showManualInput) ...[
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _isProcessing
                                    ? EdumindTheme.presentGreen
                                    : EdumindTheme.accentCyan.withValues(alpha: 0.6),
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            width: 240,
                            height: 240,
                          ),
                          // Distance tip floating pill
                          Positioned(
                            bottom: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_camera_rounded, size: 14, color: EdumindTheme.accentCyan),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAr
                                        ? 'حافظ على مسافة 20-30 سم من الشاشة'
                                        : 'Gardez 20-30 cm de distance avec l\'écran',
                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Processing Loading Overlay
                        if (_isProcessing)
                          Container(
                            color: Colors.black.withValues(alpha: 0.75),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(EdumindTheme.accentCyan),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  isAr
                                      ? 'جاري التحقق من الاتصال بالمؤسسة...'
                                      : 'Vérification de la connexion avec l\'établissement...',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Error banner if any
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: EdumindTheme.absentRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EdumindTheme.absentRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: EdumindTheme.absentRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: EdumindTheme.absentRed, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom Actions: Toggle Manual Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showManualInput = !_showManualInput;
                          _errorMessage = null;
                        });
                      },
                      icon: Icon(
                        _showManualInput ? Icons.qr_code_scanner_rounded : Icons.keyboard_rounded,
                        color: EdumindTheme.accentCyan,
                        size: 20,
                      ),
                      label: Text(
                        _showManualInput
                            ? (isAr ? 'العودة لمسح الكود عبر الكاميرا' : 'Utiliser le scanner caméra')
                            : (isAr ? 'إدخال الرابط يدوياً' : 'Saisir le lien manuellement'),
                        style: const TextStyle(
                          color: EdumindTheme.accentCyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
