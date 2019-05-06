import 'dart:io';

import '../esptouch_config.dart';

class UDPSocketServer {
  RawDatagramSocket _socket;
  bool _stopped;
  bool _closed;
  UDPSocketServer._();

  static Future<UDPSocketServer> create() async {
    UDPSocketServer client = UDPSocketServer._();
    try {
      client._socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      client._socket.broadcastEnabled = true;
      client._stopped = false;
      client._closed = false;
    } catch (e) {
      if (EsptouchConfig.logging) {
        print('[UDPSocketServer][create] SocketException');
      }
      e.printStackTrace();
    }
    return client;
  }

  void interrupt() {
    if (EsptouchConfig.logging) {
      print('[UDPSocketServer][interrupt] interrupted');
    }
    this._stopped = true;
  }

  void close() {
    if (!this._closed) {
      this._socket.close();
      this._closed = true;
    }
  }

  Future<void> sendData(
    List<List<int>> data,
    String targetHostName,
    int targetPort,
    int interval,
  ) {
    return _sendData(
      data,
      0,
      data.length,
      targetHostName,
      targetPort,
      interval,
    );
  }

  Future<void> _sendData(
    List<List<int>> data,
    int offset,
    int count,
    String hostname,
    int targetPort,
    int intervalMillis,
  ) async {
    if (EsptouchConfig.udpLogging) {
      print('[UDPSocketServer][_sendData] sending...');
    }
    if ((data == null) || (data.length <= 0)) {
      if (EsptouchConfig.udpLogging) {
        print('[UDPSocketServer][_sendData] data == null or length <= 0');
      }
      return;
    }
    for (int i = offset; !_stopped && i < offset + count; i++) {
      if (data[i].length == 0) {
        continue;
      }
      try {
        InternetAddress targetInetAddress = InternetAddress(hostname);
        this._socket.send(data[i], targetInetAddress, targetPort);
        if (EsptouchConfig.udpLogging) {
          print('[UDPSocketServer][_sendData] sent');
        }
      } on IOException catch (_) {
        if (EsptouchConfig.udpLogging) {
          print('[UDPSocketServer][_sendData] IOException, but just ignore it');
        }
      } catch (e) {
        if (EsptouchConfig.udpLogging) {
          print('[UDPSocketServer][_sendData] UnknownHostException');
        }
        _stopped = true;
        break;
      }
      try {
        await Future.delayed(Duration(milliseconds: intervalMillis));
      } catch (e) {
        if (EsptouchConfig.udpLogging) {
          print('[UDPSocketServer][_sendData] interrupted');
        }
        _stopped = true;
        break;
      }
    }
    if (_stopped) {
      close();
    }
  }
}
