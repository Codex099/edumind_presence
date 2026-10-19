import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ConnectivityService extends GetxService {
  final isOnline = false.obs;
  late final StreamSubscription<ConnectivityResult> _subscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    await _checkActualInternet(result);

    _subscription = Connectivity().onConnectivityChanged.listen((result) async {
      await _checkActualInternet(result);
    });
  }

  Future<void> _checkActualInternet(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      isOnline.value = false;
      return;
    }

    try {
      final response = await http.get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));
      isOnline.value = (response.statusCode == 204 || response.statusCode == 200);
    } catch (_) {
      isOnline.value = false;
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
