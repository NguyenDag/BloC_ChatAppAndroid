import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileService {
  // static Future<void> downloadFile(String fileUrl, String fileName) async {
  //   final appStorage = await getApplicationDocumentsDirectory();
  //   final file = File('${appStorage.path}/$fileName');
  //
  //   final response = await Dio().get(
  //     fileUrl,
  //     options: Options(
  //       responseType: ResponseType.bytes,
  //       followRedirects: false,
  //       receiveTimeout: Duration.zero,
  //     ),
  //   );
  //   final raf = file.openSync(mode: FileMode.write);
  //   raf.writeFromSync(response.data);
  //   await raf.close();
  //
  // }

  static Future<void> downloadToDownloadFolder(
    String fileUrl,
    String fileName,
  ) async {
    if (!await _requestPermission()) {
      return;
    }

    // Lấy thư mục Downloads (Android only)
    Directory? downloadDir;
    if (Platform.isAndroid) {
      downloadDir = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      downloadDir = await getApplicationDocumentsDirectory();
    }

    if (downloadDir == null) {
      return;
    }

    final String baseUrl = "http://30.30.30.85:8888/api";
    final String fullUrl = "$baseUrl$fileUrl";
    final file = File('${downloadDir.path}/$fileName');

    try {
      final response = await Dio().get(
        fullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: Duration.zero,
        ),
      );

      await file.writeAsBytes(response.data);
    } catch (e) {
      // print('Download error: $e');
    }
  }

  static Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }

  static Future<bool> requestStoragePermission() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    if (!status.isGranted) {
      return false;
    }
    return true;
  }
}
