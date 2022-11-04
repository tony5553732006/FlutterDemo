import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:demo/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as Path;
// import 'package:percent_indicator/linear_percent_indicator.dart';

import 'package:permission_handler/permission_handler.dart';

///下載檔案 Demo
///Created by tony on 2022/10/31
class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);
  static const routeName = '/downloadDemo';

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final ReceivePort _port = ReceivePort();
  static const String _portName = 'downloader_send_port';

  String downloadUrl =
      'https://hkqn.zyosoft.cn/psnext/layatest_s2/s1u01a.zip?version=2022110301';
  String fileName = '';
  String saveDir = '';
  String savePath = '';
  double _percent = 0;

  @override
  void initState() {
    super.initState();
    //UI is rendered on the main isolate,
    //while download events come from the background isolate (in other words, code in callback is run in the background isolate),
    //so you have to handle the communication between two isolates.
    IsolateNameServer.registerPortWithName(_port.sendPort, _portName);
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      debugPrint(
          'Download task ($id) is in status ($status) and process ($progress)');
      if (status == DownloadTaskStatus.complete) {
        debugPrint('下載完成');
        _unZip();
      } else if (status == DownloadTaskStatus.running) {
        debugPrint('下載中...');
      } else if (status == DownloadTaskStatus.failed) {
        debugPrint('下載失敗，請稍後再試');
      }

      setState(() {
        _percent = progress.toDouble();
        debugPrint('percent = ' + _percent.toString());
      });
    });

    //設定下載回調
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(_portName);
    super.dispose();
  }

  Future<bool> _checkPermission(Permission permission) async {
    return await permission.isGranted;
  }

  Future<PermissionStatus> _requestPermission(Permission permission) async {
    return await permission.request();
  }

  //獲取儲存路徑
  Future<String> _getSaveDirectory() async {
    //因為Apple沒有外接儲存，所以第一步我們需要先對所在平臺進行判斷
    //如果是android，使用getExternalStorageDirectory
    //如果是iOS，使用getApplicationSupportDirectory
    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationSupportDirectory();
    return directory!.path;
  }

  //callback must be a top-level or a static function
  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send!.send([id, status, progress]);
  }

  Future _download() async {
    debugPrint('下載');
    fileName = 's1u01a.zip';

    saveDir = await _getSaveDirectory();
    savePath = Path.join(saveDir, fileName);
    debugPrint('儲存路徑:' + saveDir);
    // final saveDir = File(savePath);
    // //判斷下載路徑是否存在
    // bool isExists = await saveDir.exists();
    // //不存在就新建
    // if (!isExists) {
    //   await saveDir.create();
    // }

    var file = File(savePath);
    bool isFileExists = await file.exists();
    if (isFileExists) {
      debugPrint('刪除已存在檔案:' + savePath);
      await file.delete();
    }

    //開始下載
    debugPrint('開始下載...');
    await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: saveDir,
        showNotification: true,
        openFileFromNotification:
            true // click on notification to open downloaded file (for Android)
        );
  }

  void _unZip() async {
    debugPrint('開始解壓縮');
    // Read the Zip file from disk.
    final bytes = File(savePath).readAsBytesSync();
    // Decode the Zip file
    final archive = ZipDecoder().decodeBytes(bytes);

    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      final filename = file.name;
      int size = file.size;
      if (file.isFile) {
        final data = file.content as List<int>;
        File(Path.join(saveDir, filename))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(Path.join(saveDir, filename)).create(recursive: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('檔案路徑:\n' + downloadUrl),
            Stack(
              children: [
                LinearProgressIndicator(
                  minHeight: 20,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Colors.red),
                  value: _percent / 100,
                  semanticsValue: _percent.toString(),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: Text("${_percent.toString()}%"),
                  ),
                )
              ],
            ),

            // LinearPercentIndicator(
            //   width: 250,
            //   lineHeight: 20,
            //   animation: true,
            //   animationDuration: 0,
            //   linearStrokeCap: LinearStrokeCap.butt,
            //   padding: const EdgeInsets.symmetric(horizontal: 0),
            //   percent: _percent / 100,
            //   center: Text("${_percent.toString()}%"),
            //   progressColor: Colors.red,
            // ),
            ElevatedButton(
                onPressed: () async {
                  bool isGranted = await _checkPermission(Permission.storage);
                  if (isGranted) {
                    _download();
                  } else {
                    _requestPermission(Permission.storage);
                  }
                },
                child: const Text('下載檔案'))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          saveDir = await _getSaveDirectory();
          Get.toNamed(Routes.webView,
              arguments: {'webUrl': saveDir + "/" + "s1u01a/index.html"});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
