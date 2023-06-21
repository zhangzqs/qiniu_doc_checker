import 'dart:io';

import 'package:yaml/yaml.dart';

class QiniuDocumentCheckerConfiguration {
  final String workingDirectory;
  final List<String> urlList;
  final String userAgent;

  QiniuDocumentCheckerConfiguration({
    String? workingDirectory,
    List<String>? urlList,
    String? userAgent,
  })  : workingDirectory = (() {
          final result = workingDirectory ?? '${Directory.current.path}/workdir';
          return result;
        })(),
        urlList = urlList ?? [],
        userAgent = userAgent ??
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4658.0 Safari/537.36';

  static Future<QiniuDocumentCheckerConfiguration> fromYaml(String yaml) async {
    final content = await File(yaml).readAsString();
    final yamlDoc = loadYaml(content);
    return QiniuDocumentCheckerConfiguration(
      workingDirectory: yamlDoc['workingDirectory'],
      urlList: (yamlDoc['urlList'] as YamlList).toList().cast<String>(),
      userAgent: yamlDoc['userAgent'],
    );
  }
}
