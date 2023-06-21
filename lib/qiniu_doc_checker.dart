import 'dart:io';

import 'package:dio/dio.dart';
import 'package:qiniu_doc_checker/common.dart';
import 'package:qiniu_doc_checker/config.dart';
import 'package:qiniu_doc_checker/downloader.dart';
import 'package:qiniu_doc_checker/file_inferencer.dart';

import 'crawler.dart';
import 'logger.dart';

class QiniuDocumentsChecker {
  final QiniuDocumentCheckerConfiguration config;

  QiniuDocumentsChecker(this.config);

  Future<void> check() async {
    for (var url in config.urlList) {
      final checker = QiniuDocumentChecker(
        workingDirectory: config.workingDirectory,
        documentUrl: url,
        userAgent: config.userAgent,
      );
      await checker.check();
    }
  }
}

class QiniuDocumentChecker {
  final String workingDirectory;
  final String documentUrl;
  final String? userAgent;

  QiniuDocumentChecker({
    required this.workingDirectory,
    required this.documentUrl,
    this.userAgent,
  });

  late final downloader = FileDownloader(
    cacheDir: '$workingDirectory/download',
    dio: Dio(BaseOptions(
      headers: {
        if (userAgent != null) 'User-Agent': userAgent!,
        'Referer': documentUrl,
      },
    )),
  );

  late final crawler = WebPageCrawler(
    url: documentUrl,
    cacheDir: '$workingDirectory/html',
  );

  Future<AFileTypeInferencer> buildFileTypeInferencer(File file) async {
    final result = CompressedFileTypeInferencer(
      file: file,
      cacheDir: '$workingDirectory/inferencer',
    );
    await result.init();
    return result;
  }

  Future<void> check() async {
    if (!await Directory(workingDirectory).exists()) {
      logger.d('Cache workingDirectory $workingDirectory does not exist, creating...');
      await Directory(workingDirectory).create(recursive: true);
    } else {
      logger.d('Cache workingDirectory $workingDirectory exists');
    }
    logger.i('Checking $documentUrl');
    DownloadTable table = await crawler.getDownloadTable();
    logger.i('Found ${table.items.length} items');
    for (final item in table.items) {
      logger.i('Checking ${item.downloadUrl}');
      File file = await downloader.download(
        url: item.downloadUrl,
        referer: documentUrl,
      );
      logger.i('Downloaded ${file.path}');
      AFileTypeInferencer inferencer = await buildFileTypeInferencer(file);
      final arch = await inferencer.getArchitecture();
      final platform = await inferencer.getPlatform();
      logger.i('arch: $arch, platform: $platform');

      if (arch == Architecture.unknown) {
        logger.e('cannot infer file arch: ${file.path}');
        return;
      }
      if (platform == Platform.unknown) {
        logger.e('cannot infer file platform: ${file.path}');
        return;
      }
      if (item.supportedArchitecture == Architecture.unknown) {
        logger.e('cannot infer doc arch: $item');
        return;
      }
      if (item.supportedPlatform == Platform.unknown) {
        logger.e('cannot infer doc platform: $item');
        return;
      }

      if (arch != item.supportedArchitecture) {
        throw Exception('arch not match, file: $arch, but doc: $item');
      }
      if (platform != item.supportedPlatform) {
        throw Exception('platform not match, file: $platform, but doc: $item');
      }
    }
  }
}
