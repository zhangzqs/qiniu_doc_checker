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
    return '下载项 { 原始页面信息: $sourceInfo, 目标平台系统: $supportedPlatform, 目标平台架构: $supportedArchitecture, 目标下载链接: $downloadUrl }';
  }
}

class DownloadTable {
  final List<DownloadItem> items;

  DownloadTable({
    required this.items,
  });

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('下载表 {\n总长度: ${items.length},\n');
    for (var item in items) {
      sb.writeln('  $item, \n');
    }
    sb.writeln('}');
    return sb.toString();
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
        logger.d('缓存文件夹 $cacheDir 不存在，创建中...');
        await Directory(cacheDir!).create(recursive: true);
      } else {
        logger.d('缓存文件夹 $cacheDir 已存在，跳过创建');
      }
      final resp = await dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );
      final saveTime = resp.headers['X-Swift-Savetime']?.firstOrNull;
      logger.d('X-Swift-Savetime: $saveTime');
      if (saveTime == null) {
        throw Exception('X-Swift-Savetime is null');
      }

      final hashData = "$url#salt#$saveTime";
      final digest = md5.convert(utf8.encode(hashData));
      final hash = digest.toString();
      final file = File('$cacheDir/$hash.html');
      if (await file.exists()) {
        logger.d('缓存文件 $cacheDir/$hash.html 已存在，跳过下载');
        return await file.readAsString();
      } else {
        logger.d('缓存文件 $cacheDir/$hash.html 不存在，下载中...');
        await for (final bs in resp.data!.stream) {
          await file.writeAsBytes(bs, mode: FileMode.writeOnlyAppend);
        }
        return await file.readAsString();
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
      throw Exception('找不到下载表');
    }
    logger.d('成功找到下载表');

    Bs4Element table = tbs.first;
    // 跳过表头
    List<Bs4Element> trs = table.findAll('tr').skip(1).toList();
    logger.d('下载表共有 ${trs.length} 项待下载');

    final items = trs.map((Bs4Element e) {
      final tds = e.findAll('td');
      final platform = tds[0].text;
      final url = tds[1].find('a')?.attributes['href'];
      if (url == null) {
        throw Exception('找不到下载链接，原始下载项信息为: $tds');
      }
      final supportedPlatform = Platform.parse(platform);
      if (supportedPlatform == Platform.unknown) {
        logger.w('文档描述中的平台未知，原始下载项信息为: $tds');
      }
      final supportedArchitecture = () {
        final r = Architecture.parse(platform);
        if (r == Architecture.unknown) {
          logger.w('文档描述中的架构未知，默认设为amd64，原始下载项信息为: $tds');
          return Architecture.amd64;
        } else {
          return r;
        }
      }();
      final urlPlatform = Platform.parse(Uri.decodeComponent(url.split('/').last));
      if (urlPlatform == Platform.unknown) {
        logger.w('下载链接中的平台未知，原始下载项信息为: $tds');
      }
      final urlArchitecture = () {
        final r = Architecture.parse(url);
        if (r == Architecture.unknown) {
          logger.w('下载链接中的架构未知，默认设为amd64，原始下载项信息为: $tds');
          return Architecture.amd64;
        } else {
          return r;
        }
      }();

      if (supportedPlatform != urlPlatform) {
        logger.e('文档中描述的平台 $supportedPlatform 与下载链接中的平台 $urlPlatform 不匹配，原始下载项信息为: $tds');
      }

      if (supportedArchitecture != urlArchitecture) {
        logger.e('文档中描述的架构 $supportedArchitecture 与下载链接中的架构 $urlArchitecture 不匹配，原始下载项信息为: $tds');
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
