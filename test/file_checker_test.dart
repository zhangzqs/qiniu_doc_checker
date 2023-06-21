import 'dart:io';

import 'package:qiniu_doc_checker/file_inferencer.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('file checker test', () async {
    FileTypeInferencer inferencer = FileTypeInferencer(File('README.md'));
    final arch = await inferencer.getArchitecture();
    final platform = await inferencer.getPlatform();
    print('arch: $arch, platform: $platform');
  });
}
