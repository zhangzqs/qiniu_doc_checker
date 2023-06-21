import 'package:qiniu_doc_checker/downloader.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('downloader test', () async {
    final downloader = FileDownloader(cacheDir: './workdir/download');
    final file = await downloader.download(
      url:
          'https://devtools.qiniu.com/qshell-v2.11.0-windows-386.zip?ref=developer.qiniu.com&s_path=%2Fkodo%2F1302%2Fqshell',
      onReceiveProgress: (count, total) {
        print('正在下载：${((count / total) * 100).toInt()}%');
      },
    );
    print('file downloaded: $file');
  });
}
