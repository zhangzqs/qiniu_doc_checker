import 'dart:io';

import 'package:qiniu_doc_checker/common.dart';
import 'package:qiniu_doc_checker/logger.dart';
import 'package:system_info2/system_info2.dart';

void qshellVersionChecker({
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
    platform == Platform.windows ? 'qshell.exe' : 'qshell',
    ['version'],
    runInShell: true,
    workingDirectory: inferOutput,
  ).stdout.toString().trim();
  logger.i('qshell 版本号: $version');

  // 版本号格式为 vx.x.x
  if (!version.startsWith('v')) {
    logger.e('qshell 版本号格式不正确: $version');
    return;
  }
  final versionNumber = version.substring(1);
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(versionNumber)) {
    logger.e('qshell 版本号格式不正确: $version');
    return;
  }
  if (!downloadUrl.contains(version)) {
    logger.e('qshell 下载链接不包含版本号或版本号不匹配: $downloadUrl');
    return;
  }
}
