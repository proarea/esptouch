import '../task/esptouch_result.dart';

abstract class IEsptouchTask {
  bool get cancelled;

  set esptouchListener(EsptouchResultListener esptouchListener);

  Future<EsptouchResult> connectOne();

  Future<List<EsptouchResult>> connectMany(int deviceCount);

  void interrupt();
}
