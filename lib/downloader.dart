import 'dart:io';

import 'package:dio/dio.dart';
import 'package:qiniu_doc_checker/logger.dart';
import 'package:qiniu_doc_checker/util.dart';

typedef ProgressCallback = void Function(int count, int total);

class FileDownloader {
  final Dio dio;
  final String cacheDir;

  FileDownloader({
    Dio? dio,
    required this.cacheDir,
  }) : dio = dio ?? Dio();

  Future<File> download({
    required String url,
    String? referer,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (!await Directory(cacheDir).exists()) {
      logger.d('Cache cacheDir $cacheDir does not exist, creating...');
      await Directory(cacheDir).create(recursive: true);
    } else {
      logger.d('Cache cacheDir $cacheDir exists');
    }

    if (referer != null) {
      Uri uri = Uri.parse(url);
      if (uri.host == 'kodo-toolbox-new.qiniu.com') {
        Uri ref = Uri.parse(referer);
        final map = {
          'ref': ref.host,
          's_path': ref.path,
        };
        map.addAll(uri.queryParameters);
        url = uri.replace(queryParameters: map).toString();
      }
    }

    logger.d('Downloading $url to $cacheDir');
    final resp = await dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
      ),
    );
    final etag = resp.headers['Etag']?.firstOrNull?.replaceAll('"', '');
    logger.d('Etag: $etag');
    if (etag == null) {
      throw Exception('Etag is null');
    }

    final contentType = resp.headers['Content-Type']?.firstOrNull;
    logger.d('Content-Type: $contentType');
    if (contentType == null) {
      throw Exception('Content-Type is null');
    }
    if (contentType != 'application/zip' && contentType != 'application/x-compressed') {
      throw Exception('Content-Type is not application/zip or application/x-compressed');
    }

    final targetPath = '$cacheDir/$etag.zip';
    if (await File(targetPath).exists()) {
      logger.d('File $targetPath exists, skipping download');
      return File(targetPath);
    } else {
      await saveResponseBodyToFile(
        resp,
        targetPath,
        onReceiveProgress: onReceiveProgress,
      );
      return File(targetPath);
    }
  }
}
