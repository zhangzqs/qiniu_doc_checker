import 'package:intl/intl.dart';

var logger = Logger();

class _LogItem {
  final DateTime time = DateTime.now();
  final String level;
  final dynamic message;
  final dynamic error;
  final StackTrace stackTrace;

  _LogItem(this.level, this.message, this.error, this.stackTrace);

  String _toColorStringByLevel(String s) {
    return {
      'DEBUG': '\x1B[2m$s\x1B[0m',
      'INFO': '\x1B[32m$s\x1B[0m',
      'WARN': '\x1B[33m$s\x1B[0m',
      'ERROR': '\x1B[31m$s\x1B[0m',
    }[level]!;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("[${DateFormat("yyyy-MM-dd HH:mm:ss").format(time)}]");
    sb.write(' ');
    sb.write(_toColorStringByLevel("[$level]"));
    sb.write(' ');
    sb.write(message);
    if (error != null) {
      sb.write(' ');
      sb.write(error);
    }
    sb.write(' ');
    sb.write(stackTrace.toString().split('\n')[1]);
    return sb.toString();
  }
}

class Logger {
  final List<_LogItem> _logItems = [];

  List<_LogItem> get logItems => List.unmodifiable(_logItems);

  void d(dynamic e) {
    final log = _LogItem('DEBUG', e, null, StackTrace.current);
    _logItems.add(log);
    print(log);
  }

  void i(dynamic e) {
    final log = _LogItem('INFO', e, null, StackTrace.current);
    _logItems.add(log);
    print(log);
  }

  void e(dynamic e) {
    final log = _LogItem('ERROR', e, null, StackTrace.current);
    _logItems.add(log);
    print(log);
  }

  void w(dynamic e) {
    final log = _LogItem('WARN', e, null, StackTrace.current);
    _logItems.add(log);
    print(log);
  }
}
