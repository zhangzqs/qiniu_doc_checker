import 'package:qiniu_doc_checker/qiniu_doc_checker.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('qiniu doc checker', () async {
    final checker = QiniuDocumentChecker(
      workingDirectory: 'workdir',
      documentUrl: 'https://developer.qiniu.com/kodo/6435/kodoimport',
    );
    await checker.check();
  });
}
