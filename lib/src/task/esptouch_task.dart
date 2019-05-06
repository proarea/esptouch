import '../task/esptouch_result.dart';
import '../task/i_esptouch_task.dart';
import '../task/internal_esptouch_task.dart';
import '../task/esptouch_task_parameter.dart';
import '../util/illegal_argument_exception.dart';
import '../wifi_info.dart';

class EsptouchTask implements IEsptouchTask {
  IEsptouchTask _internalTask;

  EsptouchTask._(this._internalTask);

  static Future<IEsptouchTask> create(
    WifiInfo wifiInfo, {
    int deviceCount = 1,
    bool ssidHidden = true,
  }) async {
    String ssid = wifiInfo.ssid.text;
    if (ssid == null || ssid.isEmpty) {
      throw EsptouchArgumentException(
        'EsptouchTask',
        'create',
        'SSID can not be empty',
      );
    }

    String bssid = wifiInfo.bssid.text;
    if (bssid == null || bssid.isEmpty) {
      throw EsptouchArgumentException(
        'EsptouchTask',
        'create',
        'BSSID can not be empty',
      );
    }

    EsptouchTaskParameter parameter = EsptouchTaskParameter(deviceCount ?? 1);
    IEsptouchTask internalTask = await InternalEsptouchTask.create(
      wifiInfo,
      parameter,
      ssidHidden: ssidHidden,
    );

    return EsptouchTask._(internalTask);
  }

  @override
  bool get cancelled => _internalTask.cancelled;

  @override
  set esptouchListener(EsptouchResultListener listener) {
    _internalTask.esptouchListener = listener;
  }

  @override
  Future<EsptouchResult> connectOne() => _internalTask.connectOne();

  @override
  Future<List<EsptouchResult>> connectMany(int deviceCount) =>
      _internalTask.connectMany(deviceCount);

  @override
  void interrupt() => _internalTask.interrupt();
}
