import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

Future<Response> saveResponseBodyToFile(
  Response<ResponseBody> response,
  dynamic savePath, {
  ProgressCallback? onReceiveProgress,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
  bool deleteOnError = true,
  String lengthHeader = Headers.contentLengthHeader,
}) async {
  final File file;
  if (savePath is FutureOr<String> Function(Headers)) {
    // Add real Uri and redirect information to headers.
    response.headers
      ..add('redirects', response.redirects.length.toString())
      ..add('uri', response.realUri.toString());
    file = File(await savePath(response.headers));
  } else if (savePath is String) {
    file = File(savePath);
  } else {
    throw ArgumentError.value(
      savePath.runtimeType,
      'savePath',
      'The type must be `String` or `FutureOr<String> Function(Headers)`.',
    );
  }

  // If the file already exists, the method fails.
  file.createSync(recursive: true);

  // Shouldn't call file.writeAsBytesSync(list, flush: flush),
  // because it can write all bytes by once. Consider that the file is
  // a very big size (up to 1 Gigabytes), it will be expensive in memory.
  RandomAccessFile raf = file.openSync(mode: FileMode.write);

  // Create a Completer to notify the success/error state.
  final completer = Completer<Response>();
  Future<Response> future = completer.future;
  int received = 0;

  // Stream<Uint8List>
  final stream = response.data!.stream;
  bool compressed = false;
  int total = 0;
  final contentEncoding = response.headers.value(
    Headers.contentEncodingHeader,
  );
  if (contentEncoding != null) {
    compressed = ['gzip', 'deflate', 'compress'].contains(contentEncoding);
  }
  if (lengthHeader == Headers.contentLengthHeader && compressed) {
    total = -1;
  } else {
    total = int.parse(response.headers.value(lengthHeader) ?? '-1');
  }

  Future<void>? asyncWrite;
  bool closed = false;
  Future<void> closeAndDelete() async {
    if (!closed) {
      closed = true;
      await asyncWrite;
      await raf.close();
      if (deleteOnError && file.existsSync()) {
        await file.delete();
      }
    }
  }

  late StreamSubscription subscription;
  subscription = stream.listen(
    (data) {
      subscription.pause();
      // Write file asynchronously
      asyncWrite = raf.writeFrom(data).then((result) {
        // Notify progress
        received += data.length;
        onReceiveProgress?.call(received, total);
        raf = result;
        if (cancelToken == null || !cancelToken.isCancelled) {
          subscription.resume();
        }
      }).catchError((Object e) async {
        try {
          await subscription.cancel();
        } finally {
          completer.completeError(
            DioMixin.assureDioException(e, response.requestOptions),
          );
        }
      });
    },
    onDone: () async {
      try {
        await asyncWrite;
        closed = true;
        await raf.close();
        completer.complete(response);
      } catch (e) {
        completer.completeError(
          DioMixin.assureDioException(e, response.requestOptions),
        );
      }
    },
    onError: (e) async {
      try {
        await closeAndDelete();
      } finally {
        completer.completeError(
          DioMixin.assureDioException(e, response.requestOptions),
        );
      }
    },
    cancelOnError: true,
  );
  cancelToken?.whenCancel.then((_) async {
    await subscription.cancel();
    await closeAndDelete();
  });

  final timeout = response.requestOptions.receiveTimeout;
  if (timeout != null) {
    future = future.timeout(timeout).catchError(
      (dynamic e, StackTrace s) async {
        await subscription.cancel();
        await closeAndDelete();
        if (e is TimeoutException) {
          throw DioException.receiveTimeout(
            timeout: timeout,
            requestOptions: response.requestOptions,
            error: e,
          );
        } else {
          throw e;
        }
      },
    );
  }
  return DioMixin.listenCancelForAsyncTask(cancelToken, future);
}
