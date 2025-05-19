import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pet_feeder/services/ip_address_service.dart';
import 'notification_service.dart';

class PetDetectionService {
  static final PetDetectionService _instance = PetDetectionService._internal();
  factory PetDetectionService() => _instance;
  PetDetectionService._internal();

  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final IpAddressService _ipAddressService = IpAddressService();
  bool _lastDetectionState = false;

  Future<void> startMonitoring() async {
    const interval = Duration(seconds: 5);
    _timer = Timer.periodic(interval, (timer) => _checkPetDetection());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkPetDetection() async {
    try {
      final ipAddress = await _ipAddressService.getIpAddress();
      final cleanIp = ipAddress.replaceAll('http://', '').replaceAll('https://', '');
      
      final response = await http.get(Uri.parse('http://$cleanIp/petDetector'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isPetNear = data['isPetNear'] == 'true';
        
        if (isPetNear && !_lastDetectionState) {
          await _notificationService.showPetDetectionNotification();
        }
        
        _lastDetectionState = isPetNear;
      }
    } catch (e) {
      print('Error checking pet detection: $e');
    }
  }
} 