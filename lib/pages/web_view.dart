
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
/// webView
/// Created by tony on 2022/10/31
///
class WebViewPage extends StatefulWidget {
  const WebViewPage({Key? key}) : super(key: key);
  static const routeName = '/webView';

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with AutomaticKeepAliveClientMixin {
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String initialUrl = Get.arguments['webUrl'];
    debugPrint('webUrl = ' + initialUrl);
    debugPrint('webUrl = ' + Uri.file(initialUrl).toString());

    return WebView(
      // initialUrl: initialUrl,
      // initialUrl: Uri.file(initialUrl).toString(),
      // initialUrl: 'about:blank',
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: {
        //Js調用JSInterface.postMessage("");
        JavascriptChannel(
            name: "JSInterface",
            onMessageReceived: (message) async {

            }),
      },
      initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
      allowsInlineMediaPlayback: true,
      onWebViewCreated: (WebViewController webViewController) {
        _controller.complete(webViewController);
        //Loads the file located at the specified absoluteFilePath.
        webViewController.loadFile(initialUrl);
      },
      navigationDelegate: (NavigationRequest request) {
        return NavigationDecision.navigate;
      },
      onPageStarted: (String url) {
        //debugPrint('Page started loading: $url');
        EasyLoading.show();
      },
      onProgress: (int progress) {
        //debugPrint("WebView is loading (progress : $progress%)");
      },
      onPageFinished: (String url) {
        EasyLoading.dismiss();
        //debugPrint('Page finished loading: $url');
      },
      gestureNavigationEnabled: false,
    );
  }
}
