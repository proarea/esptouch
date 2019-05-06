import 'dart:async';
import 'dart:io';

import '../protocol/esptouch_generator.dart';
import '../protocol/i_esptouch_generator.dart';
import '../task/esptouch_task_constants.dart';
import '../task/i_esptouch_task_parameter.dart';
import '../task/esptouch_result.dart';
import '../task/i_esptouch_task.dart';
import '../task/util/bssid_parser.dart';
import '../task/util/esp_net_util.dart';
import '../udp/udp_socket_client.dart';
import '../udp/udp_socket_server.dart';
import '../util/illegal_argument_exception.dart';
import '../esptouch_config.dart';
import '../wifi_info.dart';

class InternalEsptouchTask implements IEsptouchTask {
  static const int oneDataLength = 3;
  static const int maxDeviceCount = 0x7FFFFFFF;

  final IEsptouchTaskParameter parameter;
  final UDPSocketServer socketServer;
  final UDPSocketClient socketClient;
  final WifiInfo wifiInfo;
  final bool ssidHidden;
  bool successfull = false;
  bool interrupted = false;
  bool executed = false;
  bool cancelled;
  int _lastDatagramReceivedTimestamp = DateTime.now().millisecondsSinceEpoch;
  List<EsptouchResult> resultList;
  Map<String, int> connectedDevices;
  EsptouchResultListener esptouchListener;

  InternalEsptouchTask._({
    this.parameter,
    this.wifiInfo,
    this.socketServer,
    this.socketClient,
    this.esptouchListener,
    bool ssidHidden,
  })  : ssidHidden = ssidHidden ?? true,
        resultList = List(),
        connectedDevices = Map();

  static Future<IEsptouchTask> create(
    WifiInfo wifiInfo,
    IEsptouchTaskParameter parameter, {
    bool ssidHidden,
  }) async {
    final UDPSocketServer socketServer = await UDPSocketServer.create();
    final UDPSocketClient socketClient =
        await UDPSocketClient.create(EsptouchConstants.portListening);

    InternalEsptouchTask internalTask = InternalEsptouchTask._(
      parameter: parameter,
      wifiInfo: wifiInfo,
      socketServer: socketServer,
      socketClient: socketClient,
      ssidHidden: ssidHidden,
    );

    return internalTask;
  }

  void _cacheEsptouchResult(
      bool succeed, String bssid, InternetAddress internetAddress) {
    int count = connectedDevices[bssid] ?? 0;

    count++;
    connectedDevices[bssid] = count;
    if (EsptouchConfig.logging) {
      print('[InternalEsptouchTask][_cacheEsptouchResult]: count = $count');
    }

    bool enoughDevicesConnected =
        count >= EsptouchConstants.thresholdSucBroadcastCount;
    if (!enoughDevicesConnected) {
      if (EsptouchConfig.logging) {
        print(
            '[InternalEsptouchTask][_cacheEsptouchResult]: count = $count, is not enough');
      }
      return;
    }

    bool exist = false;
    for (EsptouchResult result in resultList) {
      if (result.bssid == bssid) {
        exist = true;
        break;
      }
    }

    if (!exist) {
      if (EsptouchConfig.logging) {
        print(
            '[InternalEsptouchTask][_cacheEsptouchResult]: cache result bssid=$bssid, address=$internetAddress');
      }
      final EsptouchResult newResult =
          new EsptouchResult(succeed, bssid, internetAddress);
      resultList.add(newResult);
      if (esptouchListener != null) {
        esptouchListener(newResult);
      }
    }
  }

  List<EsptouchResult> _getResultList() {
    if (resultList.isEmpty) {
      resultList.add(EsptouchResult.fail(cancelled));
    }

    return resultList;
  }

  void _interrupt() {
    if (!interrupted) {
      interrupted = true;
      socketServer.interrupt();
      socketClient.interrupt();
    }
  }

  void _listenWifiBroadcast(final int expectDataLength) {
    _lastDatagramReceivedTimestamp = DateTime.now().millisecondsSinceEpoch;
    socketClient.listenSpecLengthBytes(expectDataLength, _onDatagramReceived);
  }

  void _onDatagramReceived(List<int> bytes) {
    if (resultList.length < parameter.deviceCount && !interrupted) {
      int expectOneByte =
          wifiInfo.ssid.bytes.length + wifiInfo.password.bytes.length + 9;

      if (bytes != null) {
        int receiveOneByte = bytes != null ? bytes[0] : -1;

        if (receiveOneByte == expectOneByte) {
          // change the socket's timeout
          int consume = DateTime.now().millisecondsSinceEpoch -
              _lastDatagramReceivedTimestamp;
          int timeout = EsptouchConstants.waitUdpTotalMillisecond - consume;

          if (timeout < 0) {
            if (EsptouchConfig.udpListenerLogging) {
              print(
                  '[InternalEsptouchTask][_onDatagramReceived]: esptouch timeout');
            }
            _onDatagramReceivingFinished();
          } else {
            if (EsptouchConfig.udpListenerLogging) {
              print(
                  '[InternalEsptouchTask][_onDatagramReceived]: received correct broadcast $receiveOneByte');
            }
            String bssid = BssidParser.parseBssid(
              bytes,
              EsptouchConstants.esptouchResultOneLen,
              EsptouchConstants.esptouchResultMacLen,
            );
            InternetAddress inetAddress = EspNetUtil.parseInternetAddress(
              bytes,
              EsptouchConstants.esptouchResultOneLen +
                  EsptouchConstants.esptouchResultMacLen,
              EsptouchConstants.esptouchResultIpLen,
            );
            _cacheEsptouchResult(true, bssid, inetAddress);
          }
        } else {
          if (EsptouchConfig.udpListenerLogging) {
            print(
                '[InternalEsptouchTask][_onDatagramReceived]: receive rubbish message, just ignore');
          }
        }
      }
    } else {
      _onDatagramReceivingFinished();
    }
  }

  void _onDatagramReceivingFinished() {
    successfull = resultList.length >= parameter.deviceCount;
    _interrupt();
    if (EsptouchConfig.logging) {
      print('[InternalEsptouchTask][_onDatagramReceivingFinished]: finish');
    }
  }

  Future<bool> _execute(IEsptouchGenerator generator) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;
    int currentTime = startTime;
    int lastTime = currentTime - EsptouchConstants.timeoutTotalCodeMillisecond;

    List<List<int>> gcBytes2 = generator.getGCBytes2();
    List<List<int>> dcBytes2 = generator.getDCBytes2();

    int index = 0;
    while (!interrupted) {
      if (currentTime - lastTime >=
          EsptouchConstants.timeoutTotalCodeMillisecond) {
        if (EsptouchConfig.logging) {
          print('[InternalEsptouchTask][_execute]: send GuideCode');
        }
        int timeoutGuideCodeMillis =
            EsptouchConstants.timeoutGuideCodeMillisecond;
        while (!interrupted &&
            DateTime.now().millisecondsSinceEpoch - currentTime <
                timeoutGuideCodeMillis) {
          await socketServer.sendData(
            gcBytes2,
            parameter.targetHostname,
            EsptouchConstants.portTarget,
            EsptouchConstants.intervalGuideCodeMillisecond,
          );
          if (DateTime.now().millisecondsSinceEpoch - startTime >
              EsptouchConstants.waitUdpSendingMillisecond) {
            break;
          }
        }
        lastTime = currentTime;
      } else {
        List<List<int>> dataToSend =
            dcBytes2.sublist(index, index + oneDataLength);
        await socketServer.sendData(
          dataToSend,
          parameter.targetHostname,
          EsptouchConstants.portTarget,
          EsptouchConstants.intervalDataCodeMillisecond,
        );
        index = (index + oneDataLength) % dcBytes2.length;
      }
      currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - startTime >
          EsptouchConstants.waitUdpSendingMillisecond) {
        break;
      }
    }

    return successfull;
  }

  @override
  Future<EsptouchResult> connectOne() async => (await connectMany(1))?.first;

  @override
  Future<List<EsptouchResult>> connectMany(int deviceCount) async {
    if (this.executed) {
      throw EsptouchArgumentException('InternalEsptouchTask',
          'connectManyDevices', 'Esptouch task already executed');
    }
    this.executed = true;

    if (deviceCount <= 0) {
      parameter.deviceCount = maxDeviceCount;
    } else {
      parameter.deviceCount = deviceCount;
    }

    if (EsptouchConfig.logging) {
      print(
          '[InternalEsptouchTask][connectMany]: started deviceCount=$deviceCount');
    }

    InternetAddress localInetAddress;
    try {
      localInetAddress = InternetAddress(wifiInfo.ip.text);
    } catch (e) {
      print(e);
    }

    if (EsptouchConfig.logging) {
      print(
          '[InternalEsptouchTask][connectMany]: localInetAddress = $localInetAddress');
    }

    IEsptouchGenerator generator = EsptouchGenerator(wifiInfo, ssidHidden);

    _listenWifiBroadcast(EsptouchConstants.esptouchResultTotalLen);

    bool succeed = false;
    for (int i = 0; i < EsptouchConstants.totalRepeatTime; i++) {
      succeed = await _execute(generator);
      if (succeed) {
        return _getResultList();
      }
    }

    if (!interrupted) {
      await Future.delayed(Duration(
          milliseconds: EsptouchConstants.waitUdpReceivingMillisecond));
      this._interrupt();
    }

    return _getResultList();
  }

  @override
  void interrupt() {
    if (EsptouchConfig.logging) {
      print('[InternalEsptouchTask][interrupt]');
    }
    cancelled = true;
    _interrupt();
  }
}
