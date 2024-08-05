import 'dart:convert';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
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

class _MyHomePageState extends State<MyHomePage> {
  String _ipAddress = 'XXX.XXX.XXX.XXX';
  Process? _vpnProcess;
  String _activeTun = 'No active TUN';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleConnection(String filepath) async {
    try {
      debugPrint('Starting VPN connection with file: $filepath');
      _vpnProcess = await Process.start("openvpn",
          ["--config", filepath, "--verb", "3", "--suppress-timestamps"]);
      setState(() {
        _activeTun = 'No active TUN';
        _ipAddress = 'Connecting';
      });
      String result = '';
      _vpnProcess?.stdout.transform(utf8.decoder).listen((data) {
        debugPrint('OpenVPNN: $data');
        result += data;
      });
      await Future.delayed(const Duration(seconds: 5));
      debugPrint(result);
      if (result == '') {
        debugPrint('OpenVPN result is null.');
        setState(() {
          _ipAddress = 'Connection failed';
        });
        return;
      }
      var regexTun = RegExp(r'TUN/TAP device (\w+) opened');
      var match = regexTun.firstMatch(result);
      if (match != null) {
        var activeTun = match.group(1) ?? 'No active TUN';
        debugPrint('TUN interface found: $activeTun');
        setState(() {
          _activeTun = activeTun;
          _ipAddress = 'Fetching IP address...';
        });
        await _fetchIpAddress();
      } else {
        debugPrint('No TUN interface found.');
        setState(() {
          _activeTun = 'No active TUN';
          _ipAddress = 'TUN interface not found';
        });
      }
    } catch (e) {
      debugPrint('Error in _handleConnection: $e');
      setState(() {
        _ipAddress = 'Connection error';
      });
    }
  }

  Future<void> _fetchIpAddress() async {
    try {
      debugPrint('Fetching IP address...');

      var result = await Process.run('ip', ['addr']);

      if (result.exitCode != 0) {
        debugPrint('Error running ip command. Exit code: ${result.exitCode}');
        setState(() {
          _ipAddress = 'Error running ip command';
        });
        return;
      }

      var output = result.stdout as String;
      debugPrint('IP command output: $output');

      var regexInet = RegExp(r'inet (\d+\.\d+\.\d+\.\d+)');
      var ipMatch = regexInet.firstMatch(output);

      if (ipMatch != null && _activeTun != 'No active TUN') {
        var ipAddress = ipMatch.group(1) ?? 'IP address not found';
        debugPrint('IP address found: $ipAddress');

        setState(() {
          _ipAddress = ipAddress;
        });
      } else {
        debugPrint('No IP address found or no active TUN.');
        setState(() {
          _ipAddress = 'IP address not found';
        });
      }
    } catch (e) {
      debugPrint('Error in _fetchIpAddress: $e');
      setState(() {
        _ipAddress = 'Error fetching IP address';
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      if (_vpnProcess != null) {
        _vpnProcess!.kill();
        setState(() {
          _vpnProcess = null;
          _activeTun = 'No active TUN';
          _ipAddress = 'Disconnected';
        });
        debugPrint('Disconnected');
      }
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
        //onDragEntered: (details) => debugPrint('Drag entered'),
        //onDragExited: (details) => debugPrint('Drag exited'),
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
              Text(
                'IP Address: $_ipAddress ($_activeTun)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _disconnect,
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDroppedFiles(files) {
    if (files.isNotEmpty) {
      for (var file in files) {
        if (file.path.endsWith('.ovpn')) {
          _handleConnection(file.path);
          debugPrint(file.path);
          break;
        } else {
          debugPrint('Not a .ovpn file');
        }
      }
    } else {
      debugPrint('No files dropped');
    }
  }
}
