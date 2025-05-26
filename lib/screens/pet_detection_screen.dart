import 'package:flutter/material.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/screens/camera_screen.dart';
import 'package:pet_feeder/services/ip_address_service.dart';
import 'package:pet_feeder/services/pet_detection_service.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class PetDetectionScreen extends StatefulWidget {
  const PetDetectionScreen({Key? key}) : super(key: key);

  @override
  State<PetDetectionScreen> createState() => _PetDetectionScreenState();
}

class _PetDetectionScreenState extends State<PetDetectionScreen> {
  final TextEditingController _ipController = TextEditingController();
  final IpAddressService _ipAddressService = IpAddressService();
  final PetDetectionService _petDetectionService = PetDetectionService();
  bool _isPetDetected = false;
  bool _isLoading = false;
  bool _isDetectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _isDetectionEnabled = false;
    _loadSavedIp();
    _loadDetectionState();
    _startDetectionListener();
  }

  void _startDetectionListener() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDetectionEnabled) {
        setState(() {
          _isPetDetected = _petDetectionService.lastDetectionState;
        });
      }
    });
  }

  Future<void> _loadDetectionState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('pet_detection_enabled') ?? false;
    setState(() {
      _isDetectionEnabled = saved == true ? true : false;
    });
    if (saved == true) {
      await _petDetectionService.startMonitoring();
    } else {
      await _petDetectionService.stopMonitoring();
    }
  }

  Future<void> _toggleDetection(bool value) async {
    setState(() {
      _isDetectionEnabled = value;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pet_detection_enabled', value);
    
    if (value) {
      await _petDetectionService.startMonitoring();
    } else {
      await _petDetectionService.stopMonitoring();
      setState(() {
        _isPetDetected = false;
      });
    }
  }

  Future<void> _loadSavedIp() async {
    final savedIp = await _ipAddressService.getDetectionIpAddress();
    setState(() {
      _ipController.text = savedIp;
    });
  }

  Future<void> _saveIpAddress() async {
    if (_ipController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'IP address cannot be empty',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _ipAddressService.setDetectionIpAddress(_ipController.text);
      Fluttertoast.showToast(
        msg: 'IP address saved successfully',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error saving IP address',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Pet Detection',
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PIR Sensor IP Address',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _isDetectionEnabled,
                            onChanged: _toggleDetection,
                            activeColor: primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          labelText: 'IP Address',
                          hintText: 'http://192.168.1.139',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: _isLoading ? null : _saveIpAddress,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.pets,
                        size: 80,
                        color: _isPetDetected ? primary : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isPetDetected ? 'Pet Detected!' : 'No Pet Detected',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isPetDetected ? primary : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      IntrinsicWidth(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isPetDetected && _isDetectionEnabled
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const CameraScreen(),
                                          ),
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.videocam),
                                label: const Text('Monitor Pet'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  minimumSize: const Size(100, 48),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isPetDetected && _isDetectionEnabled
                                    ? () {
                                        Navigator.pushReplacementNamed(context, '/');
                                      }
                                    : null,
                                icon: const Icon(Icons.pets),
                                label: const Text('Feed Pet'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  minimumSize: const Size(100, 48),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }
} 