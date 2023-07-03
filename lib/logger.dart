import 'package:intl/intl.dart';

final logger = Logger(
  logRecorder: (logItem) {
    print(logItem);
  },
);

enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error;

  @override
  String toString() {
    return name.toUpperCase();
  }
}

class LogItem {
  final DateTime time = DateTime.now();
  final LogLevel level;
  final dynamic message;
  final StackTrace? stackTrace;

  LogItem(this.level, this.message, [this.stackTrace]);

  String _toColorStringByLevel(String s) {
    return {
      LogLevel.trace: '\x1B[2m$s\x1B[0m',
      LogLevel.debug: '\x1B[2m$s\x1B[0m',
      LogLevel.info: '\x1B[32m$s\x1B[0m',
      LogLevel.warn: '\x1B[33m$s\x1B[0m',
      LogLevel.error: '\x1B[31m$s\x1B[0m',
    }[level]!;
  }

  Exception get asException => Exception(message);

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("[${DateFormat("yyyy-MM-dd HH:mm:ss").format(time)}]");
    sb.write(' ');
    sb.write(_toColorStringByLevel("[$level]"));
    sb.write(' ');
    sb.write(message);
    if (stackTrace != null) {
      sb.write(' ');
      final stackInfo = stackTrace.toString().split('\n')[1];
      sb.write(_toColorStringByLevel(stackInfo));
    }
    return sb.toString();
  }
}

class Logger {
  final List<LogItem> _logItems = [];
  final void Function(LogItem)? _logRecorder;
  LogLevel level;
  bool showStackTrace;

  Logger({
    void Function(LogItem)? logRecorder,
    this.level = LogLevel.info,
    this.showStackTrace = false,
  }) : _logRecorder = logRecorder ?? print;

  List<LogItem> get logItems => List.unmodifiable(_logItems);

  LogItem _log(LogLevel level, dynamic e, StackTrace stackTrace) {
    final log = LogItem(
      level,
      e,
      showStackTrace ? stackTrace : null,
    );
    if (level.index >= this.level.index) {
      _logItems.add(log);
      _logRecorder!(log);
    }
    return log;
  }

  LogItem t(dynamic e) => _log(LogLevel.trace, e, StackTrace.current);

  LogItem d(dynamic e) => _log(LogLevel.debug, e, StackTrace.current);

  LogItem i(dynamic e) => _log(LogLevel.info, e, StackTrace.current);

  LogItem w(dynamic e) => _log(LogLevel.warn, e, StackTrace.current);

  LogItem e(dynamic e) => _log(LogLevel.error, e, StackTrace.current);
}
