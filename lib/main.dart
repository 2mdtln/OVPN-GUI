import 'package:window_manager/window_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:process_run/shell_run.dart';
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
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _ipAddress = 'Fetching IP address...';

  @override
  void initState() {
    super.initState();
    _fetchIpAddress();
  }

  Future<void> _fetchIpAddress() async {
    try {
      var result = await Process.run('ip', ['addr', 'show', 'tun0']);
      var output = result.stdout as String;
      var regex = RegExp(r'inet (\d+\.\d+\.\d+\.\d+)');
      var match = regex.firstMatch(output);
      if (match != null) {
        setState(() {
          _ipAddress = match.group(1) ?? 'IP address not found';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DropTarget(
        onDragDone: (details) {
          _handleDroppedFiles(details.files);
        },
        onDragEntered: (details) => debugPrint('Drag entered'),
        onDragExited: (details) => debugPrint('Drag exited'),
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
                'IP Address: $_ipAddress',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
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

Future<void> _handleConnection(String filepath) async {
  try {
    var shell = Shell();
    await shell.runExecutableArguments("openvpn", [filepath]);
    debugPrint('Connected with $filepath');
  } catch (e) {
    debugPrint('Error: $e');
  }
}
