import 'dart:isolate';

import 'package:meta/meta.dart';

import 'task/esptouch_result.dart';
import 'task/esptouch_task.dart';
import 'util/esptouch_exception.dart';
import 'wifi_info.dart';
import 'esptouch_config.dart';

typedef void EsptouchErrorListener(dynamic error);
typedef void EsptouchResultListListener(List<EsptouchResult> resultList);

class Esptouch {
  static bool _executing = false;
  static Isolate isolate;
  static EsptouchTask esptouchTask;

  static EsptouchErrorListener onEsptouchError;
  static EsptouchResultListener onEsptouchResult;
  static EsptouchResultListListener onEsptouchFinished;

  Esptouch._();

  static bool get executing => _executing;

  static void connect(
    WifiInfo wifiInfo, {
    EsptouchErrorListener onEsptouchError,
    EsptouchResultListener onEsptouchResult,
    EsptouchResultListListener onEsptouchFinished,
    int deviceCount = -1,
  }) async {
    if (_executing) {
      throw EsptouchException('Esptouch', 'connect', 'already executing');
    }

    _executing = true;

    Esptouch.onEsptouchError = onEsptouchError;
    Esptouch.onEsptouchResult = onEsptouchResult;
    Esptouch.onEsptouchFinished = onEsptouchFinished;

    if (EsptouchConfig.logging) {
      print('[Esptouch][connect]: start connecting');
    }

    ReceivePort receivePort = ReceivePort();
    _IsolateParameter isolateParameter = _IsolateParameter(
      wifiInfo,
      sendPort: receivePort.sendPort,
      deviceCount: deviceCount ?? -1,
    );

    isolate = await Isolate.spawn(_isolateCallback, isolateParameter);

    receivePort.listen((dynamic data) {
      if (Esptouch.onEsptouchResult != null && data is EsptouchResult) {
        Esptouch.onEsptouchResult(data);
      } else if (data is List<EsptouchResult>) {
        Esptouch.stop();

        if (Esptouch.onEsptouchFinished != null) {
          Esptouch.onEsptouchFinished(data);
        }
      } else if (data is Exception || data is Error) {
        Esptouch.stop();

        if (Esptouch.onEsptouchError != null) {
          Esptouch.onEsptouchError(data);
        }
      }
    });
  }

  static void stop() {
    if (esptouchTask != null) {
      esptouchTask.interrupt();
      esptouchTask = null;
    }

    if (isolate != null) {
      isolate.kill();
    }

    _executing = false;

    Esptouch.onEsptouchFinished([]);

    onEsptouchError = null;
    onEsptouchResult = null;
    onEsptouchFinished = null;
    if (EsptouchConfig.logging) {
      print('[Esptouch][stop]: stopped');
    }
  }

  static void _isolateCallback(final _IsolateParameter parameter) async {
    WifiInfo wifiInfo = parameter;
    try {
      esptouchTask = await EsptouchTask.create(wifiInfo, deviceCount: parameter.deviceCount);
      esptouchTask.esptouchListener = (EsptouchResult result) => parameter.sendPort.send(result);

      parameter.sendPort.send(await esptouchTask.connectMany(parameter.deviceCount));
    } catch (e) {
      parameter.sendPort.send(e);
    }
  }
}

class _IsolateParameter extends WifiInfo {
  final int deviceCount;
  final SendPort sendPort;

  _IsolateParameter(
    WifiInfo wifiInfo, {
    @required this.sendPort,
    @required this.deviceCount,
  }) : super.copy(wifiInfo);
}
