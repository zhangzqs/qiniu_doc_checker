import 'dart:async';
import 'dart:io';

import 'common.dart';
import 'logger.dart';

abstract class AFileTypeInferencer {
  final File file;

  AFileTypeInferencer(this.file) {
    if (!file.existsSync()) {
      throw Exception('File not exists: ${file.path}');
    }
    logger.d('File type infer: ${file.absolute.path}');
  }

  /// Infer file architecture
  Future<Architecture> getArchitecture();

  /// Infer file platform
  Future<Platform> getPlatform();
}

/// File type inferencer
class FileTypeInferencer extends AFileTypeInferencer {
  final Completer<String> _fileResultCompleter = Completer();

  FileTypeInferencer(super.file) {
    Process.run("file", [file.absolute.path]).then((result) {
      logger.d(result.stdout);
      String resultOutput = result.stdout;
      resultOutput = resultOutput.substring(resultOutput.indexOf(': '));
      _fileResultCompleter.complete(resultOutput);
    });
  }

  /// Infer file architecture
  @override
  Future<Architecture> getArchitecture() async {
    String result = await _fileResultCompleter.future;
    result = result.toLowerCase();
    if (result.contains('x86_64') || result.contains('x86-64') || result.contains('amd64') || result.contains('x64')) {
      return Architecture.amd64;
    } else if (result.contains('aarch64') || result.contains('arm64') || result.contains('armv8')) {
      return Architecture.arm64;
    } else if (result.contains('arm') || result.contains('armv7')) {
      return Architecture.arm;
    } else if (result.contains('i386') || result.contains('x86') || result.contains('386')) {
      return Architecture.i386;
    } else if (result.contains('mips64le')) {
      return Architecture.mips64le;
    } else if (result.contains('mips64')) {
      return Architecture.mips64;
    } else if (result.contains('mipsle')) {
      return Architecture.mipsle;
    } else if (result.contains('mips')) {
      return Architecture.mips;
    } else if (result.contains('loong64')) {
      return Architecture.loong64;
    } else if (result.contains('riscv64')) {
      return Architecture.riscv64;
    } else {
      return Architecture.unknown;
    }
  }

  /// Infer file platform
  @override
  Future<Platform> getPlatform() async {
    String result = await _fileResultCompleter.future;
    if (result.contains('Mach-O')) {
      return Platform.darwin;
    } else if (result.contains('PE32')) {
      return Platform.windows;
    } else if (result.contains('ELF')) {
      return Platform.linux;
    } else {
      return Platform.unknown;
    }
  }
}

class CompressedFileTypeInferencer extends AFileTypeInferencer {
  final String cacheDir;

  bool _isInited = false;

  CompressedFileTypeInferencer({
    required File file,
    required this.cacheDir,
  }) : super(file);

  Directory get outputDir {
    // 获取文件名并去除后缀
    String fileName = file.path.split('/').last;
    fileName = fileName.substring(0, fileName.lastIndexOf('.'));
    return Directory('$cacheDir/$fileName');
  }

  Future<bool> _isZipFile() async {
    ProcessResult result = await Process.run('file', [file.absolute.path]);
    return result.stdout.toString().contains('Zip archive data');
  }

  Future<bool> _isTarGzFile() async {
    ProcessResult result = await Process.run('file', [file.absolute.path]);
    return result.stdout.toString().contains('gzip compressed data');
  }

  Future<void> _initByZip() async {
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
      ProcessResult result = await Process.run('unzip', [file.absolute.path, '-d', outputDir.absolute.path]);
      if (result.exitCode != 0) {
        throw Exception('unzip failed: ${result.stderr}');
      }
    }
  }

  Future<void> _initByTarGz() async {
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
      ProcessResult result = await Process.run('tar', ['-zxvf', file.absolute.path, '-C', outputDir.absolute.path]);
      if (result.exitCode != 0) {
        throw Exception('tar failed: ${result.stderr}');
      }
    }
  }

  Future<void> init() async {
    if (!await file.exists()) {
      throw Exception('File not exists: ${file.path}');
    }
    logger.d('File type infer: ${file.absolute.path}');
    if (await _isZipFile()) {
      await _initByZip();
    } else if (await _isTarGzFile()) {
      await _initByTarGz();
    } else {
      throw Exception('Unsupported file type: ${file.path}');
    }
    _isInited = true;
  }

  @override
  Future<Architecture> getArchitecture() async {
    if (!_isInited) {
      await init();
    }
    await for (final e in outputDir.list(recursive: true)) {
      if (e is File) {
        final arch = await FileTypeInferencer(e).getArchitecture();
        if (arch != Architecture.unknown) {
          return arch;
        }
      }
    }
    return Architecture.unknown;
  }

  @override
  Future<Platform> getPlatform() async {
    if (!_isInited) {
      await init();
    }
    await for (final e in outputDir.list(recursive: true)) {
      if (e is File) {
        final platform = await FileTypeInferencer(e).getPlatform();
        if (platform != Platform.unknown) {
          return platform;
        }
      }
    }
    return Platform.unknown;
  }
}
