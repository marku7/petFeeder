import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pet_feeder/services/ip_address_service.dart';
import 'package:pet_feeder/services/notification_service.dart';
import 'package:pet_feeder/main.dart' as main_app;

class PetDetectionService {
  static final PetDetectionService _instance = PetDetectionService._internal();
  factory PetDetectionService() => _instance;
  PetDetectionService._internal();

  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final IpAddressService _ipAddressService = IpAddressService();
  bool _lastDetectionState = false;

  Future<void> startMonitoring() async {
    const interval = Duration(seconds: 3);
    _timer = Timer.periodic(interval, (timer) => _checkPetDetection());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkPetDetection() async {
    try {
      final ipAddress = await _ipAddressService.getDetectionIpAddress();
      final cleanIp = ipAddress.replaceAll('http://', '').replaceAll('https://', '');
      
      final url = 'http://$cleanIp/petDetector';
      print('DEBUG [PetDetectionService]: Checking URL: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG [PetDetectionService]: Response data: $data');
        
        final isPetNear = data['isPetNear'] == 'true';
        
        if (isPetNear && !_lastDetectionState) {
          print('DEBUG [PetDetectionService]: Pet detected, showing notification');
          await _notificationService.showPetDetectionNotification();
          if (main_app.navigatorKey.currentState != null) {
            main_app.navigatorKey.currentState!.pushNamed('/pet-detection');
          }
        }
        
        _lastDetectionState = isPetNear;
      } else {
        print('DEBUG [PetDetectionService]: Error response: ${response.statusCode}');
      }
    } on TimeoutException {
      print('DEBUG [PetDetectionService]: Connection timed out');
    } catch (e) {
      print('DEBUG [PetDetectionService]: Error checking pet detection: $e');
    }
  }
} 