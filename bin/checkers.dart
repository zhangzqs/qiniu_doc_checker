import 'dart:io';

import 'package:qiniu_doc_checker/common.dart';
import 'package:qiniu_doc_checker/logger.dart';
import 'package:qiniu_doc_checker/qiniu_doc_checker.dart';
import 'package:system_info2/system_info2.dart';

const Map<String, AfterInferencerCallback> afterInferencerCheckers = {
  'qshellVersionChecker': qshellVersionChecker,
  'kodoImportVersionChecker': kodoImportVersionChecker,
  'kodoBrowserVersionChecker': kodoBrowserVersionChecker,
};

void kodoImportVersionChecker({
  required String downloadUrl,
  required String inferOutput,
  required Architecture arch,
  required Platform platform,
}) {
  commonVersionChecker(
    'kodoimport',
    versionSubCommands: ['--version'],
    expectRegex: r'version:v(\d+\.\d+\.\d+)',
    downloadUrl: downloadUrl,
    inferOutput: inferOutput,
    arch: arch,
    platform: platform,
  );
}

void kodoBrowserVersionChecker({
  required String downloadUrl,
  required String inferOutput,
  required Architecture arch,
  required Platform platform,
}) {
  if (platform == Platform.unknown) {
    logger.w('跳过未知操作系统平台的版本运行检查');
    return;
  }
  // 跳过非本地平台的运行检查
  if (Platform.parse(SysInfo.kernelName) != platform) {
    return;
  }
  // 跳过非本地架构的运行检查
  if (Architecture.parse(SysInfo.kernelArchitecture.name) != arch) {
    return;
  }
  // TODO
  logger.w('暂时不支持获取 kodo-browser 版本进行运行版本检查');
}

void qshellVersionChecker({
  required String downloadUrl,
  required String inferOutput,
  required Architecture arch,
  required Platform platform,
}) {
  commonVersionChecker(
    'qshell',
    versionSubCommands: ['version'],
    downloadUrl: downloadUrl,
    inferOutput: inferOutput,
    arch: arch,
    platform: platform,
  );
}

void commonVersionChecker(
  String executable, {
  List<String> versionSubCommands = const ['version'],
  String expectRegex = r'^v(\d+\.\d+\.\d+)$',
  required String downloadUrl,
  required String inferOutput,
  required Architecture arch,
  required Platform platform,
}) {
  if (platform == Platform.unknown) {
    logger.w('跳过未知操作系统平台的版本运行检查');
    return;
  }
  // 跳过非本地平台的运行检查
  if (Platform.parse(SysInfo.kernelName) != platform) {
    return;
  }
  // 跳过非本地架构的运行检查
  if (Architecture.parse(SysInfo.kernelArchitecture.name) != arch) {
    return;
  }
  final version = Process.runSync(
    platform == Platform.windows ? '$executable.exe' : executable,
    versionSubCommands,
    runInShell: true,
    workingDirectory: inferOutput,
  ).stdout.toString().trim();
  logger.i('$executable 版本号: $version');

  if (!RegExp(expectRegex).hasMatch(version)) {
    logger.e('$executable 版本号格式不正确: $version, 期望格式为 $expectRegex');
    return;
  }
  if (!downloadUrl.contains(version)) {
    logger.e('$executable 下载链接不包含版本号或版本号不匹配: $downloadUrl');
    return;
  }
}
