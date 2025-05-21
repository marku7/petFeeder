import 'package:shared_preferences/shared_preferences.dart';

class IpAddressService {
  static final IpAddressService _instance = IpAddressService._internal();
  factory IpAddressService() => _instance;
  IpAddressService._internal();

  static const String _monitoringIpKey = 'monitoring_ip_address';
  static const String _detectionIpKey = 'detection_ip_address';
  static const String _defaultMonitoringIp = 'http://192.168.1.229';
  static const String _defaultDetectionIp = 'http://192.168.1.130';

  Future<String> getMonitoringIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_monitoringIpKey) ?? _defaultMonitoringIp;
  }

  Future<String> getDetectionIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_detectionIpKey) ?? _defaultDetectionIp;
  }

  Future<void> setMonitoringIpAddress(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_monitoringIpKey, ipAddress);
  }

  Future<void> setDetectionIpAddress(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_detectionIpKey, ipAddress);
  }

  Future<void> clearIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_monitoringIpKey);
    await prefs.remove(_detectionIpKey);
  }
} 