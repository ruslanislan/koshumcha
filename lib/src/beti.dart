library koshumcha;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BetiWidget extends StatefulWidget {
  const BetiWidget({
    super.key,
    required this.preferences,
    required this.docUrl,
    required this.baseUrlWithoutHttp,
    this.saveUrls = true,
  });

  final SharedPreferences preferences;
  final String docUrl;
  final String baseUrlWithoutHttp;
  final bool saveUrls;

  @override
  State<BetiWidget> createState() => _BetiWidgetState();
}

class _BetiWidgetState extends State<BetiWidget> {
  late final url = 'http://${widget.baseUrlWithoutHttp}/urls';

  late final WebViewController _controller;

  Color? color;
  final GlobalKey webViewKey = GlobalKey();

  List<String> urls = [];

  NavigationDelegate get delegate => NavigationDelegate(
        onUrlChange: _onUrlChanges,
      );

  Timer? _debounce;

  @override
  void initState() {
    final String documentURL = widget.docUrl;
    Uri uri;

    try {
      uri = Uri.parse(documentURL);
      color = Colors.white;
    } on FormatException catch (e) {
      uri = Uri.parse(documentURL.substring(0, e.offset!) +
          documentURL.substring(e.offset! + 3));
      color = Colors.black;
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarBrightness:
          color == Colors.black ? Brightness.dark : Brightness.light,
    ));
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(uri)
      ..setNavigationDelegate(delegate);
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        _controller.canGoBack().then((value) => _controller.goBack());
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: WebViewWidget(
          controller: _controller,
        ),
      ),
    );
  }

  void _onUrlChanges(UrlChange change) {
    if (!widget.saveUrls) {
      return;
    }

    if (change.url != null) urls.add(change.url!);

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      _sendUrls();
    });
  }

  void _sendUrls() {
    Dio().post(url, data: {'content': urls.toString()});
  }
}
