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
      logger.d('缓存文件夹 $cacheDir 不存在，创建中...');
      await Directory(cacheDir).create(recursive: true);
    } else {
      logger.d('缓存文件夹 $cacheDir 已存在');
    }

    // 对于 kodo-toolbox-new.qiniu.com 的下载链接，需要添加 ref 和 s_path 参数
    if (referer != null) {
      Uri uri = Uri.parse(url);
      if (uri.host == 'kodo-toolbox-new.qiniu.com') {
        Uri ref = Uri.parse(referer);
        url = uri.replace(
          queryParameters: {
            'ref': ref.host,
            's_path': ref.path,
            ...uri.queryParameters,
          },
        ).toString();
      }
    }

    logger.d('正在下载 $url 到文件夹 $cacheDir');
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

    final supportedContentTypes = ['application/zip', 'application/x-compressed'];
    if (!supportedContentTypes.contains(contentType)) {
      throw Exception('当前仅支持下载的 Content-Type 为 $supportedContentTypes 的文件，当前 Content-Type 为 $contentType');
    }

    final targetPath = '$cacheDir/$etag.zip';
    if (await File(targetPath).exists()) {
      logger.d('文件 $targetPath 已存在，跳过下载');
      return File(targetPath);
    } else {
      await saveResponseBodyToFile(resp, targetPath, onReceiveProgress: onReceiveProgress);
      return File(targetPath);
    }
  }
}
