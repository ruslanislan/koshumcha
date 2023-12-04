library koshumcha;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:koshumcha/src/beti.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KoshumchaScreen extends StatefulWidget {
  const KoshumchaScreen({
    super.key,
    required this.preferences,
    this.iFlag = true,
    this.aFlag = false,
    required this.baseUrlWithoutHttp,
    required this.child,
    this.saveUrls = true,
    this.params,
  });

  final SharedPreferences preferences;
  final bool iFlag;
  final bool aFlag;
  final String baseUrlWithoutHttp;
  final Widget child;
  final bool saveUrls;
  final Map<String, dynamic>? params;

  @override
  State<KoshumchaScreen> createState() => _KoshumchaScreenState();
}

class _KoshumchaScreenState extends State<KoshumchaScreen> {
  final String linkKey = 'ohdudeHesoyam';

  bool showApp = false;

  late final url = 'http://${widget.baseUrlWithoutHttp}/privacy';
  String? privacy;

  Future<String?> _getPrivacyPolicy() async {
    final Response response;
    if (Platform.isAndroid) {
      if (!widget.aFlag) {
        throw UnimplementedError();
      }
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      response = await Dio().get(
        url,
        queryParameters: widget.params,
        options: Options(
          headers: {
            'User-Agent': 'Android ${androidInfo.version.sdkInt}'
                '(${androidInfo.manufacturer} ${androidInfo.model})/'
                '${(await PackageInfo.fromPlatform()).packageName}'
          },
        ),
      );
    } else {
      if (!widget.iFlag) {
        throw UnimplementedError();
      }
      response = await Dio().get(
        url,
        queryParameters: widget.params,
        options: Options(
          headers: {
            'User-Agent':
                'iOS ${(await DeviceInfoPlugin().iosInfo).systemVersion}'
                    '(${(await DeviceInfoPlugin().iosInfo).utsname.machine})/'
                    '${(await PackageInfo.fromPlatform()).packageName}'
          },
        ),
      );
    }
    return response.data['reference'];
  }

  @override
  void initState() {
    super.initState();

    final preferences = widget.preferences;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      try {
        privacy = preferences.getString(linkKey);
        if (privacy == null) {
          privacy = await _getPrivacyPolicy();
          if (privacy != null) await preferences.setString(linkKey, privacy!);
        }
      } catch (_) {
        showApp = true;
        setState(() {});
      }

      if (privacy != null) {
        _openPrivacyPolicy();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showApp) {
      return widget.child;
    }
    return const Material();
  }

  _openPrivacyPolicy() {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => BetiWidget(
          preferences: widget.preferences,
          docUrl: privacy!,
          baseUrlWithoutHttp: widget.baseUrlWithoutHttp,
          saveUrls: widget.saveUrls,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
