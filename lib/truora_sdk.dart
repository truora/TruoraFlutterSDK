export 'truora_sdk.dart';

import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

const _identityURL = 'https://identity.truora.com?token=';

// The identity process succeeded event
const _processSucceeded = 'truora.process.succeeded';

// The identity process failed event
const _processFailed = 'truora.process.failed';

// The identity process steps completed event
const _stepsCompleted = 'truora.steps.completed';

enum TruoraPermission {
  camera(value: 1, name: 'Camera'),
  location(value: 5, name: 'Location'),
  photos(value: 9, name: 'Photos');

  final int value;
  final String name;

  const TruoraPermission({required this.value, required this.name});
}

class TruoraSDK extends StatefulWidget {
  /// Api Key to create identity process
  final String token;

  /// List of permissions needed for the process
  final List<TruoraPermission> requiredPermissions;

  /// Callback to handle errors
  final Function(String) onError;

  /// Callback that recieves the process id
  /// once the identity process steps are completed
  final Function(String) onStepsCompleted;

  /// Callback that recieves the process id
  /// once an identity process is succeeded
  final Function(String) onProcessSucceeded;

  /// Callback that recieves the process id
  /// once an identity process is failed
  final Function(String) onProcessFailed;

  const TruoraSDK({
    super.key,
    required this.token,
    required this.requiredPermissions,
    required this.onError,
    required this.onStepsCompleted,
    required this.onProcessSucceeded,
    required this.onProcessFailed,
  });

  @override
  // ignore: library_private_types_in_public_api
  _TruoraSDKState createState() => _TruoraSDKState();
}

class _TruoraSDKState extends State<TruoraSDK> with WidgetsBindingObserver {
  late WebViewController _controller;
  late BuildContext scaffoldContext;
  bool _isWebViewLoaded = false;
  bool _returningFromSettings = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebViewController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returningFromSettings) {
      _returningFromSettings = false;
      _requestPermissions();
    }
  }

  Future<void> _initializeWebViewController() async {
    final params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params);

    if (_controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController)
          .setOnPlatformPermissionRequest(
        (PlatformWebViewPermissionRequest request) {
          request.grant();
        },
      );
    }

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
      (_controller.platform as AndroidWebViewController)
          .setOnPlatformPermissionRequest(
        (PlatformWebViewPermissionRequest request) {
          request.grant();
        },
      );
    }

    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) => setState(() => _isLoading = true),
        onPageFinished: (String url) => setState(() => _isLoading = false),
      ),
    );

    _controller.addJavaScriptChannel(
      'FlutterWebViewSDK',
      onMessageReceived: (JavaScriptMessage message) {
        final messageParts = message.message.split(',');
        if (messageParts.length != 2) {
          widget.onError('Internal error: message format invalid');
          return;
        }

        final event = messageParts[0];
        final processID = messageParts[1];

        switch (event) {
          case _stepsCompleted:
            widget.onStepsCompleted(processID);
            break;
          case _processSucceeded:
            widget.onProcessSucceeded(processID);
            break;
          case _processFailed:
            widget.onProcessFailed(processID);
            break;
          default:
            widget.onError('Internal error: invalid message received');
            break;
        }
      },
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      _controller.loadRequest(Uri.parse('$_identityURL${widget.token}'));
      return;
    }

    for (final permission in widget.requiredPermissions) {
      final status = await Permission.byValue(permission.value).request();
      if (!status.isGranted) {
        _showAppSettingsDialog(permission.name);
        return;
      }
    }

    if (!_isWebViewLoaded) {
      _controller.loadRequest(Uri.parse('$_identityURL${widget.token}'));
      _isWebViewLoaded = true;
    }
  }

  void _showAppSettingsDialog(String name) {
    showDialog(
      context: scaffoldContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$name Permission Required'),
          content: Text('Please grant $name access in app settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                _returningFromSettings = true;
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(72, 0, 255, 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
