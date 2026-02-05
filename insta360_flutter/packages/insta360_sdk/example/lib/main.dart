import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insta360_sdk/insta360_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _cameraState = 'Unknown';
  final _insta360SdkPlugin = Insta360Sdk.instance;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String cameraState;
    try {
      await _insta360SdkPlugin.initialize();
      final state = await _insta360SdkPlugin.getCameraState();
      cameraState = state.toString();
    } on PlatformException {
      cameraState = 'Failed to get camera state.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _cameraState = cameraState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Camera state: $_cameraState\n'),
        ),
      ),
    );
  }
}
