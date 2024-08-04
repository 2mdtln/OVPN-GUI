import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    title: "openvpn gui - Mamy",
    size: Size(400, 500),
    center: true,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions);
  windowManager.show();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Hello, World!')),
      ),
    );
  }
}
