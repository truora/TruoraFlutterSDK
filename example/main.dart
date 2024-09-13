import 'package:flutter/material.dart';
import 'package:truora_sdk/truora_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truora SDK Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TruoraWebViewPage(),
    );
  }
}

class TruoraWebViewPage extends StatefulWidget {
  const TruoraWebViewPage({super.key});

  @override
  _TruoraWebViewPageState createState() => _TruoraWebViewPageState();
}

class _TruoraWebViewPageState extends State<TruoraWebViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
      ),
      body: TruoraSDK(
        token: 'replace_me',
        requiredPermissions: const [
          TruoraPermission.camera,
          TruoraPermission.location
        ],
        onError: (errorMessage) {
          _showAlertDialog(context, 'Error', errorMessage);
        },
        onStepsCompleted: (processID) {
          _showAlertDialog(
              context, 'Steps Completed', 'Process ID: $processID');
        },
        onProcessSucceeded: (processID) {
          _showAlertDialog(
              context, 'Process Succeeded', 'Process ID: $processID');
        },
        onProcessFailed: (processID) {
          _showAlertDialog(context, 'Process Failed', 'Process ID: $processID');
        },
      ),
    );
  }

  void _showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
