import 'package:intl/intl.dart';

var logger = Logger(
  logRecorder: (logItem) {
    print(logItem);
  },
);

class LogItem {
  final DateTime time = DateTime.now();
  final String level;
  final dynamic message;
  final StackTrace stackTrace;

  LogItem(this.level, this.message, this.stackTrace);

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
    sb.write(' ');
    final stackInfo = stackTrace.toString().split('\n')[1];
    sb.write(_toColorStringByLevel(stackInfo));
    return sb.toString();
  }
}

class Logger {
  final List<LogItem> _logItems = [];
  final void Function(LogItem)? _logRecorder;

  Logger({
    void Function(LogItem)? logRecorder,
  }) : _logRecorder = logRecorder ?? print;

  List<LogItem> get logItems => List.unmodifiable(_logItems);

  LogItem _log(String level, dynamic e, StackTrace stackTrace) {
    final log = LogItem(level, e, stackTrace);
    _logItems.add(log);
    _logRecorder?.call(log);
    return log;
  }

  LogItem d(dynamic e) => _log('DEBUG', e, StackTrace.current);

  LogItem i(dynamic e) => _log('INFO', e, StackTrace.current);

  LogItem e(dynamic e) => _log('ERROR', e, StackTrace.current);

  LogItem w(dynamic e) => _log('WARN', e, StackTrace.current);
}
