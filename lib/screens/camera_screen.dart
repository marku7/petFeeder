import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/text_widget.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pet_feeder/services/ip_address_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String _url = 'https://50bd-122-2-10-30.ngrok-free.app';
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isReconnecting = false;
  final TextEditingController _urlController = TextEditingController();
  bool _isUrlEmpty = false;
  final IpAddressService _ipAddressService = IpAddressService();

  @override
  void initState() {
    super.initState();
    _loadSavedIpAddress();
    _initializeWebView();
  }

  Future<void> _loadSavedIpAddress() async {
    final savedIp = await _ipAddressService.getMonitoringIpAddress();
    if (savedIp.isNotEmpty) {
      setState(() {
        _url = savedIp;
        _urlController.text = savedIp;
      });
    } else {
      setState(() {
        _urlController.text = _url;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    return url.startsWith('http://') || 
           url.startsWith('https://') || 
           url.startsWith('rtsp://');
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _isReconnecting = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _isReconnecting = false;
            });
            Fluttertoast.showToast(
              msg: 'Connection error: ${error.description}',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
    Fluttertoast.showToast(
      msg: 'Connecting to: $_url',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  void _showUrlConfigDialog() {
    _urlController.text = _url;
    _isUrlEmpty = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Camera Stream URL'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'URL',
                      hintText: 'rtsp://192.168.1.127 or http://192.168.1.127',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _isUrlEmpty 
                              ? null 
                              : () {
                                  _urlController.clear();
                                  setDialogState(() {
                                    _isUrlEmpty = true;
                                  });
                                },
                          ),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _isUrlEmpty = value.isEmpty;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Examples:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Text(
                    '• http://192.168.1.127\n• rtsp://192.168.1.127:554/live\n• http://admin:password@192.168.1.127/video',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: _isUrlEmpty 
                    ? null 
                    : () async {
                        String newUrl = _urlController.text.trim();
                        if (newUrl.isEmpty) {
                          Fluttertoast.showToast(
                            msg: 'URL cannot be empty',
                            backgroundColor: Colors.red,
                          );
                          return;
                        }
                        if (!_isValidUrl(newUrl)) {
                          if (newUrl.startsWith("rtsp")) {
                            newUrl = newUrl.substring(4);
                          } else {
                            newUrl = '$newUrl';
                          }
                        }
                        await _ipAddressService.setMonitoringIpAddress(newUrl);
                        setState(() {
                          _url = newUrl;
                          _isReconnecting = true;
                        });
                        Navigator.of(context).pop();
                        Fluttertoast.showToast(
                          msg: 'Connecting to: $_url',
                          backgroundColor: Colors.green,
                          toastLength: Toast.LENGTH_SHORT,
                        );
                        _controller.loadRequest(Uri.parse(_url));
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('CONNECT'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Live Monitoring',
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 80.0),
        child: FloatingActionButton(
          mini: true,
          onPressed: _showUrlConfigDialog,
          child: const Icon(Icons.link),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isReconnecting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isReconnecting ? 'Reconnecting...' : 'Loading...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _url,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isReconnecting = true;
                  });
                  _controller.reload();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reconnect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 