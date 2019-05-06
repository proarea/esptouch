import '../task/i_esptouch_task_parameter.dart';

class EsptouchTaskParameter implements IEsptouchTaskParameter {
  static const String broadcastHostname = '255.255.255.255';

  static int getNextDatagramCount() => 1 + (_datagramCount++) % 100;
  static int _datagramCount = 0;

  int deviceCount;

  EsptouchTaskParameter(this.deviceCount);

  @override
  String get targetHostname => broadcastHostname;
}
