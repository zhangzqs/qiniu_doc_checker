import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:qiniu_doc_checker/config.dart';
import 'package:qiniu_doc_checker/logger.dart';
import 'package:qiniu_doc_checker/qiniu_doc_checker.dart';
import 'package:yaml/yaml.dart';

import 'checkers.dart';

Future<QiniuDocumentCheckerConfiguration> loadConfigFromYamlFile(File file) async {
  final content = await file.readAsString();
  final yamlDoc = loadYaml(content);

  return QiniuDocumentCheckerConfiguration(
    workingDirectory: yamlDoc['working-directory'],
    documentList: (yamlDoc['document-list'] as YamlList).toList().cast<YamlMap>().map((e) {
      return QiniuDocument(
        name: e['name'],
        url: e['url'],
        afterDownloadCheckers: ((e) =>
            e == null ? <String>[] : (e as YamlList).map((x) => x.toString()).toList())(e['after-download-checkers']),
        afterInferencerCheckers: ((e) =>
            e == null ? <String>[] : (e as YamlList).map((x) => x.toString()).toList())(e['after-inferencer-checkers']),
      );
    }).toList(),
    userAgent: yamlDoc['user-agent'],
    logger: () {
      final map = (yamlDoc['logger'] as YamlMap).cast<String, dynamic>();
      return QiniuLoggerConfiguration(
        level: LogLevel.values.firstWhere(
          (e) => e.name.toUpperCase() == map['level'].toString().toUpperCase(),
        ),
        showStackTrace: map['show-stack-trace'],
      );
    }(),
  );
}

Future<int> _run(List<String> arguments) async {
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

  logger.i('使用配置文件: $yamlConfigFile');

  final config = await loadConfigFromYamlFile(File(yamlConfigFile));
  logger.level = config.logger.level;
  logger.showStackTrace = config.logger.showStackTrace;

  await QiniuDocumentsChecker(
    config: config,
    afterInferencerCallbackMap: afterInferencerCheckers,
    afterDownloadCallbackMap: {}, // TODO
  ).check();

  final warnLogs = logger.logItems.where((e) => e.level == LogLevel.warn).toList();
  if (warnLogs.isNotEmpty) {
    print('\x1B[33m Some Warnings: \x1B[0m');
    print('${warnLogs.join('\n')}\n');
  }

  final errorLogs = logger.logItems.where((e) => e.level == LogLevel.error).toList();
  if (errorLogs.isNotEmpty) {
    print('\x1B[31m Some Errors: \x1B[0m');
    print('${errorLogs.join('\n')}\n');
    return 1;
  }

  logger.level = LogLevel.info;
  logger.i('\x1B[32m 所有文档检查均成功通过！！！ \x1B[0m');
  return 0;
}

Future<void> _writeAllPrintToLogFile(Iterable<String> printRecords) async {
  final logDirPath = '${Directory.current.path}/logs';
  await Directory(logDirPath).create(recursive: true);

  final logFile = File(
    '$logDirPath/qiniu_doc_checker_${DateFormat("yyyy-MM-dd_HH-mm-ss").format(DateTime.now())}.log',
  );

  await logFile.writeAsString(printRecords.join('\n'), mode: FileMode.append);
  print('日志文件已保存： ${logFile.path}');
}

Future<void> main(List<String> arguments) async {
  List<String> printRecords = [];
  final result = await runZonedGuarded(
    () => _run(arguments),
    (e, stackTrace) async {
      print(e);
      print(stackTrace);
      printRecords.addAll([e.toString(), stackTrace.toString()]);
      await _writeAllPrintToLogFile(printRecords);
      exit(-1);
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        parent.print(zone, line);
        printRecords.add(line);
      },
    ),
  );
  await _writeAllPrintToLogFile(printRecords);
  exit(result!);
}
