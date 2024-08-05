import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';

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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});
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
          child: Container(
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
        ),
      ),
    );
  }
}

  void _handleDroppedFiles(files) {
    if (files.isNotEmpty) {
      for (var file in files) {
        if (file.path.endsWith('.ovpn')) {
          debugPrint('Dropped .ovpn file: ${file.path}');
        } else {
          debugPrint('Dropped file is not a .ovpn file: ${file.path}');
        }
      }
    } else {
      debugPrint('No files dropped');
    }
  }