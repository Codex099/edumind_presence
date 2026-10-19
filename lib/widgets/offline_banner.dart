import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/connectivity_service.dart';
import '../services/pending_queue_service.dart';
import '../utils/theme.dart';
import '../utils/translations.dart';

class OfflineBanner extends StatelessWidget {
  final String lang;

  const OfflineBanner({super.key, this.lang = 'ar'});

  @override
  Widget build(BuildContext context) {
    final conn = Get.find<ConnectivityService>();
    final queue = Get.find<PendingQueueService>();

    return Obx(() {
      final isOnline = conn.isOnline.value;
      final pendingCount = queue.pendingCount.value;

      if (isOnline && pendingCount == 0) {
        return const SizedBox.shrink();
      }

      if (!isOnline) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: EdumindTheme.lateOrange.withValues(alpha: 0.15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 16, color: EdumindTheme.lateOrange),
              const SizedBox(width: 8),
              Text(
                AppTranslations.get('offline', lang: lang) + (pendingCount > 0 ? ' ($pendingCount ${AppTranslations.get('pending_sync', lang: lang)})' : ''),
                style: const TextStyle(
                  color: EdumindTheme.lateOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }

      // Online but pending sync items exist
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: EdumindTheme.primaryBlue.withValues(alpha: 0.15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: EdumindTheme.primaryBlue),
            ),
            const SizedBox(width: 8),
            Text(
              '$pendingCount ${AppTranslations.get('pending_sync', lang: lang)}...',
              style: const TextStyle(
                color: EdumindTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    });
  }
}
