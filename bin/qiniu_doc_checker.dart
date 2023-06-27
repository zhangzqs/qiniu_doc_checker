import 'dart:io';

import 'package:qiniu_doc_checker/config.dart';
import 'package:qiniu_doc_checker/logger.dart';
import 'package:qiniu_doc_checker/qiniu_doc_checker.dart';

Future<void> main(List<String> arguments) async {
  String yamlConfigFile = await () async {
    if (arguments.isEmpty) {
      List<String> yamlFilePaths = await Directory.current
          .list(recursive: false)
          .where((e) => e.path.endsWith('.yaml'))
          .map((e) => e.path)
          .toList();
      if (yamlFilePaths.length == 1) {
        return yamlFilePaths.first;
      } else {
        if (yamlFilePaths.length > 1) {
          print('too many yaml files found: $yamlFilePaths');
        } else {
          print('Usage: qiniu_doc_checker <yaml_config_file>');
        }
        exit(1);
      }
    } else {
      return arguments[0];
    }
  }();

  print('yamlConfigFile: $yamlConfigFile');

  final config = await QiniuDocumentCheckerConfiguration.fromYaml(yamlConfigFile);

  await QiniuDocumentsChecker(config).check();

  final errorLogs = logger.logItems.where((e) {
    return e.level == 'ERROR';
  }).toList();

  if (errorLogs.isNotEmpty) {
    logger.e('\x1B[31m Some Error: \x1B[0m');
    for (var log in errorLogs) {
      print(log);
    }
    exit(1);
  } else {
    logger.i('\x1B[32m All check passed! \x1B[0m');
    exit(0);
  }
}
