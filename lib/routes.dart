import 'package:demo/pages/download.dart';
import 'package:demo/pages/web_view.dart';
import 'package:get/get.dart';

class Routes {
  static var downloadDemo = DownloadPage.routeName;
  static var webView = WebViewPage.routeName;

  static final List<GetPage> pages = [
    GetPage(name: downloadDemo, page: () => const DownloadPage()),
    GetPage(name: webView, page: () => const WebViewPage()),
  ];
}
