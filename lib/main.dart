import 'dart:convert';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    title: "openvpn gui - Mamy",
    size: Size(500, 250),
  );
  await windowManager.waitUntilReadyToShow(windowOptions);
  windowManager.show();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  createState() => _MyHomePageState();
}

class CloudPainter extends CustomPainter {
  final bool show;
  CloudPainter({required this.show});
  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 20)
      ..lineTo(20, 0)
      ..lineTo(size.width - 20, 0)
      ..lineTo(size.width, 20)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Copied!',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2,
            (size.height - textPainter.height) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => show;
}

class _MyHomePageState extends State<MyHomePage> {
  String _ipAddress = 'XXX.XXX.XXX.XXX';
  Process? _vpnProcess;
  String? _lastUsedConfigFile;
  String _activeTun = 'No active TUN';

  @override
  void initState() {
    super.initState();
    _loadLastUsedConfigFile();
  }

  Future<void> _loadLastUsedConfigFile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastUsedConfigFile = prefs.getString('lastUsedConfigFile');
    });
  }

  Future<void> _saveLastUsedConfigFile(String filepath) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('lastUsedConfigFile', filepath);
  }

  void _handleDroppedFiles(files) {
    if (files.isNotEmpty) {
      for (var file in files) {
        if (file.path.endsWith('.ovpn')) {
          _handleConnection(file.path);
          debugPrint(file.path);
          break;
        } else {
          const SnackBar(content: Text('Not a .ovpn file'));
        }
      }
    } else {
      const SnackBar(content: Text('No files dropped'));
    }
  }

  Future<void> _handleConnection(String filepath) async {
    try {
      debugPrint('Starting VPN connection with file: $filepath');
      _lastUsedConfigFile = filepath;
      await _saveLastUsedConfigFile(filepath);
      _vpnProcess = await Process.start("openvpn",
          ["--config", filepath, "--verb", "3", "--suppress-timestamps"]);
      setState(() {
        _activeTun = 'No active TUN';
        _ipAddress = 'Connecting';
      });
      String result = '';
      _vpnProcess?.stdout.transform(utf8.decoder).listen((data) {
        result += data;
      });
      await Future.delayed(const Duration(seconds: 5));
      if (result == '') {
        setState(() {
          _ipAddress = 'Connection failed';
        });
        return;
      }
      var regexTun = RegExp(r'TUN/TAP device (\w+) opened');
      var match = regexTun.firstMatch(result);
      if (match != null) {
        var activeTun = match.group(1) ?? 'No active TUN';
        setState(() {
          _activeTun = activeTun;
          _ipAddress = 'Fetching IP address...';
        });
        await _fetchIpAddress();
      } else {
        setState(() {
          _activeTun = 'No active TUN';
          _ipAddress = 'TUN interface not found';
        });
      }
    } catch (e) {
      setState(() {
        _ipAddress = 'Connection error';
      });
    }
  }

  Future<void> _connectToLastFile() async {
    if (_lastUsedConfigFile != null) {
      await _handleConnection(_lastUsedConfigFile!);
    } else {
      const SnackBar(content: Text('No last used .ovpn file found'));
    }
  }

  Future<void> _fetchIpAddress() async {
    try {
      var result = await Process.run('ip', ['addr', 'show', _activeTun]);
      if (result.exitCode != 0) {
        setState(() {
          _ipAddress = 'Error running ip command';
        });
        return;
      }
      var output = result.stdout as String;
      var regexInet = RegExp(r'inet (\d+\.\d+\.\d+\.\d+)');
      var ipMatch = regexInet.firstMatch(output);
      if (ipMatch != null && _activeTun != 'No active TUN') {
        var ipAddress = ipMatch.group(1) ?? 'IP address not found';
        setState(() {
          _ipAddress = ipAddress;
        });
      } else {
        setState(() {
          _ipAddress = 'IP address not found';
        });
      }
    } catch (e) {
      setState(() {
        _ipAddress = 'Error fetching IP address';
      });
    }
  }

  void _showPopup(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 150,
        left: 210,
        child: Material(
          color: Colors.transparent,
          child: CustomPaint(
            size: const Size(60, 30),
            painter: CloudPainter(show: true),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  Future<void> _disconnect() async {
    try {
      if (_vpnProcess != null) {
        _vpnProcess!.kill();
        const SnackBar(content: Text('Disconnected'));
      }
      setState(() {
        _vpnProcess = null;
        _activeTun = 'No active TUN';
        _ipAddress = 'Disconnected';
      });
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DropTarget(
        onDragDone: (details) {
          _handleDroppedFiles(details.files);
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Drop a .ovpn file to connect',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (_vpnProcess != null) {
                    Clipboard.setData(ClipboardData(text: _ipAddress));
                    _showPopup(context);
                  }
                },
                child: Text(
                  'IP Address: $_ipAddress ($_activeTun)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _disconnect,
                child: const Text('Disconnect'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _connectToLastFile,
                child: Text(_lastUsedConfigFile != null
                    ? 'Connect to last .ovpn: ${_lastUsedConfigFile!.split('/').last}'
                    : 'Connect to last .ovpn'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
