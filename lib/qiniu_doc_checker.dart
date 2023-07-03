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
      logger.d('工作目录 $workingDirectory 不存在，创建中...');
      await Directory(workingDirectory).create(recursive: true);
    } else {
      logger.d('工作目录 $workingDirectory 已存在');
    }
    logger.i('准备检查文档页面： $documentUrl');
    DownloadTable table = await crawler.getDownloadTable();
    logger.i('找到下载项 ${table.items.length} 个');
    for (final (i, item) in table.items.indexed) {
      logger.i('正在检查第${i + 1}项，下载链接：${item.downloadUrl}');
      File file = await downloader.download(
        url: item.downloadUrl,
        referer: documentUrl,
      );
      logger.i('下载完毕，文件路径：${file.path}');
      AFileTypeInferencer inferencer = await buildFileTypeInferencer(file);
      final arch = await inferencer.getArchitecture();
      final platform = await inferencer.getPlatform();
      logger.i('推断出的文件架构：$arch，推断出的文件平台：$platform');

      if (arch == Architecture.unknown) {
        logger.e('无法推断文件架构：${file.path}');
        return;
      }
      if (platform == Platform.unknown) {
        logger.e('无法推断文件平台：${file.path}');
        return;
      }
      if (item.supportedArchitecture == Architecture.unknown) {
        logger.e('无法推断文档描述架构：$item');
        return;
      }
      if (item.supportedPlatform == Platform.unknown) {
        logger.e('无法推断文档描述平台：$item');
        return;
      }

      if (arch != item.supportedArchitecture) {
        throw Exception('架构不匹配, 文件内容架构为: $arch, 但是文档描述为: $item');
      }
      if (platform != item.supportedPlatform) {
        throw Exception('平台不匹配, 文件内容平台为: $platform, 但是文档描述为: $item');
      }
    }
  }
}
