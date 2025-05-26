import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pet_feeder/services/ip_address_service.dart';
import 'package:pet_feeder/services/notification_service.dart';
import 'package:pet_feeder/main.dart' as main_app;
import 'package:shared_preferences/shared_preferences.dart';

class PetDetectionService {
  static final PetDetectionService _instance = PetDetectionService._internal();
  factory PetDetectionService() => _instance;
  PetDetectionService._internal();

  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final IpAddressService _ipAddressService = IpAddressService();
  bool _lastDetectionState = false;
  DateTime? _lastNotificationTime;
  bool _isMonitoring = false;

  bool get isMonitoring => _isMonitoring;
  bool get lastDetectionState => _lastDetectionState;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    const interval = Duration(seconds: 3);
    _timer = Timer.periodic(interval, (timer) => _checkPetDetection());
    _isMonitoring = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pet_detection_enabled', true);
  }

  Future<void> stopMonitoring() async {
    _timer?.cancel();
    _timer = null;
    _isMonitoring = false;
    _lastDetectionState = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pet_detection_enabled', false);
  }

  bool _canSendNotification() {
    if (_lastNotificationTime == null) return true;
    
    final now = DateTime.now();
    final lastNotification = _lastNotificationTime!;
    
    bool isDifferentPeriod = false;
    
    // Morning: 5 AM to 11 AM
    bool isMorning = now.hour >= 5 && now.hour < 11;
    bool wasMorning = lastNotification.hour >= 5 && lastNotification.hour < 11;
    
    // Noon: 11 AM to 5 PM
    bool isNoon = now.hour >= 11 && now.hour < 17;
    bool wasNoon = lastNotification.hour >= 11 && lastNotification.hour < 17;
    
    // Evening: 5 PM to 5 AM
    bool isEvening = now.hour >= 17 || now.hour < 5;
    bool wasEvening = lastNotification.hour >= 17 || lastNotification.hour < 5;
    
    isDifferentPeriod = (isMorning && !wasMorning) || 
                        (isNoon && !wasNoon) || 
                        (isEvening && !wasEvening);
    
    return isDifferentPeriod;
  }

  Future<void> _checkPetDetection() async {
    if (!_isMonitoring) return;
    
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
          print('DEBUG [PetDetectionService]: Pet detected');
          await _notificationService.showPetDetectionNotification();
          if (main_app.navigatorKey.currentState != null) {
            main_app.openPetDetectionScreen();
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