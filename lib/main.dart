import 'dart:io';

import 'package:demo/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_server/http_server.dart' show VirtualDirectory;

void main() async {
  //初始化FlutterDownloader
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, widget) {
        widget = EasyLoading.init()(context, widget);
        return MediaQuery(
          //设置文字大小不随系统设置改变
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: widget,
        );
      },
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      getPages: Routes.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  HttpServer? server;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  @override
  void dispose() {
    super.dispose();
    if (server != null) {
      server!.close();
    }
  }

  void _startServer() async {
    if (server != null) {
      return;
    }
    debugPrint('startServer');
    var dir = await getExternalStorageDirectory();
    debugPrint('dir = ' + dir!.path);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
    // server = await HttpServer.bind('127.0.0.1', 8080);

    var virDir = VirtualDirectory(dir.path);
    virDir.allowDirectoryListing = true;

    debugPrint("Server running on IP : " +
        server!.address.toString() +
        " On Port : " +
        server!.port.toString());

    //Listening for requests to send responses to clients
    await server!.forEach((HttpRequest request) {
      var uri = request.uri;
      debugPrint("uri = " + uri.toString());
      debugPrint("filePath = " + dir.path +  uri.toString());
      virDir.serveRequest(request);

      // request.response.headers.contentType =
      //     ContentType("text", "plain", charset: "utf-8");
      // request.response.write('\n\n\n\n\n\n\n\nHello, world!');
      // // request.response.write(File(dir.path + "/s1u01a" + uri.toString()));
      // request.response.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
          child: ListView(
            children: [
              ElevatedButton(
                  onPressed: () {
                    Get.toNamed(Routes.downloadDemo);
                  },
                  child: const Text('DownloadDemo')),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

        },
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
