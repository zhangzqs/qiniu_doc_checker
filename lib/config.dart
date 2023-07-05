import 'dart:io';

import 'package:qiniu_doc_checker/logger.dart';

class QiniuLoggerConfiguration {
  final LogLevel level;
  final bool showStackTrace;

  const QiniuLoggerConfiguration({
    this.level = LogLevel.info,
    this.showStackTrace = false,
  });
}

class QiniuDocument {
  final String name;
  final String url;
  final List<String> afterDownloadCheckers;
  final List<String> afterInferencerCheckers;

  const QiniuDocument({
    required this.name,
    required this.url,
    this.afterDownloadCheckers = const [],
    this.afterInferencerCheckers = const [],
  });
}

class QiniuDocumentCheckerConfiguration {
  static const defaultUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4658.0 Safari/537.36';
  final String workingDirectory;
  final List<QiniuDocument> documentList;
  final String userAgent;
  final QiniuLoggerConfiguration logger;

  QiniuDocumentCheckerConfiguration({
    String? workingDirectory,
    this.documentList = const [],
    this.userAgent = defaultUserAgent,
    this.logger = const QiniuLoggerConfiguration(),
  }) : workingDirectory = workingDirectory ?? '${Directory.current.path}/workdir';
}
