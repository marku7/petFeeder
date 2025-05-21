import 'package:shared_preferences/shared_preferences.dart';

class IpAddressService {
  static final IpAddressService _instance = IpAddressService._internal();
  factory IpAddressService() => _instance;
  IpAddressService._internal();

  static const String _ipAddressKey = 'camera_ip_address';
  static const String _defaultIpAddress = 'http://192.168.1.130';

  Future<String> getIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ipAddressKey) ?? _defaultIpAddress;
  }

  Future<void> setIpAddress(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipAddressKey, ipAddress);
  }

  Future<void> clearIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ipAddressKey);
  }
} 