import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:qiniu_doc_checker/crawler.dart';
import 'package:test/scaffolding.dart';

void main() {
  final crawler = WebPageCrawler(
    url: 'https://developer.qiniu.com/kodo/1302/qshell',
    cacheDir: './workdir/html',
  );
  test('crawler test', () async {
    final content = await crawler.getContent();
    BeautifulSoup bs = BeautifulSoup(content);
    List<Bs4Element> tbs = bs.findAll('table').where((element) {
      return element.text.contains('下载') && element.text.contains('链接') && element.text.contains('平台');
    }).toList();

    print(tbs.length);
  });

  test('get download table test', () async {
    final table = await crawler.getDownloadTable();
    print(table);
  });
}
