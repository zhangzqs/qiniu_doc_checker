import 'dart:convert';
import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:qiniu_doc_checker/logger.dart';

import 'common.dart';

class DownloadItem {
  final String sourceInfo;
  final Platform supportedPlatform;
  final Architecture supportedArchitecture;
  final String downloadUrl;

  DownloadItem({
    required this.sourceInfo,
    required this.supportedPlatform,
    required this.supportedArchitecture,
    required this.downloadUrl,
  });

  @override
  String toString() {
    return 'DownloadItem { platform: $supportedPlatform, architecture: $supportedArchitecture, url: $downloadUrl }';
  }
}

class DownloadTable {
  final List<DownloadItem> items;

  DownloadTable({
    required this.items,
  });

  @override
  String toString() {
    return 'DownloadTable { items: $items }';
  }
}

class WebPageCrawler {
  final String url;
  final Dio dio;
  final String? cacheDir;

  WebPageCrawler({
    required this.url,
    Dio? dio,
    this.cacheDir,
  }) : dio = dio ?? Dio();

  Future<String> getContent() async {
    if (cacheDir == null) {
      final resp = await dio.get(url);
      String html = resp.data;
      return html;
    } else {
      if (!await Directory(cacheDir!).exists()) {
        logger.d('Cache dir $cacheDir does not exist, creating...');
        await Directory(cacheDir!).create(recursive: true);
      } else {
        logger.d('Cache dir $cacheDir exists');
      }
      final headResp = await dio.head(url);
      final saveTime = headResp.headers['X-Swift-Savetime']?.firstOrNull;
      logger.d('X-Swift-Savetime: $saveTime');
      if (saveTime == null) {
        throw Exception('X-Swift-Savetime is null');
      }

      final hashData = "$url#salt#$saveTime";
      final digest = md5.convert(utf8.encode(hashData));
      final hash = digest.toString();

      if (await File('$cacheDir/$hash.html').exists()) {
        logger.d('Cache file $cacheDir/$hash.html exists');
        return await File('$cacheDir/$hash.html').readAsString();
      } else {
        logger.d('Cache file $cacheDir/$hash.html does not exist, downloading...');
        final resp = await dio.get(url);
        String html = resp.data;
        await File('$cacheDir/$hash.html').writeAsString(html);
        return html;
      }
    }
  }

  Future<DownloadTable> getDownloadTable() async {
    final content = await getContent();
    BeautifulSoup bs = BeautifulSoup(content);
    List<Bs4Element> tbs = bs.findAll('table').where((element) {
      return element.text.contains('下载') && element.text.contains('链接') && element.text.contains('平台');
    }).toList();
    if (tbs.isEmpty) {
      throw Exception('No download table found');
    }
    logger.d('Download table found');

    Bs4Element table = tbs.first;
    // 跳过表头
    List<Bs4Element> trs = table.findAll('tr').skip(1).toList();
    logger.d('Download table rows: ${trs.length}');

    final items = trs.map((Bs4Element e) {
      final tds = e.findAll('td');
      final platform = tds[0].text;
      final url = tds[1].find('a')?.attributes['href'];
      if (url == null) {
        throw Exception('Download url not found with { platform: $platform }');
      }
      final supportedPlatform = Platform.parse(platform);
      final supportedArchitecture = Architecture.parse(platform);
      final urlPlatform = Platform.parse(url);
      final urlArchitecture = Architecture.parse(url);

      if ([supportedPlatform, urlPlatform].contains(Platform.unknown)) {
        logger.w('Platform unknown with { platform: $platform, url: $url }');
      } else {
        if (supportedPlatform != urlPlatform) {
          throw Exception(
              'Platform not match with { platform: $supportedPlatform, url: $urlPlatform, sourcePlatform: $platform, sourceUrl: $url }');
        }
      }

      if ([supportedArchitecture, urlArchitecture].contains(Architecture.unknown)) {
        logger.w('Architecture unknown with { platform: $platform, url: $url }');
      } else {
        if (supportedArchitecture != urlArchitecture) {
          throw Exception(
              'Architecture not match with { architecture: $supportedArchitecture, url: $urlArchitecture, sourcePlatform: $platform, sourceUrl: $url }');
        }
      }

      return DownloadItem(
        sourceInfo: '$platform $url',
        supportedPlatform: supportedPlatform,
        supportedArchitecture: supportedArchitecture,
        downloadUrl: url,
      );
    }).toList();
    return DownloadTable(items: items);
  }
}
