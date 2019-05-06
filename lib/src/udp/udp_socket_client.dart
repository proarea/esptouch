import 'dart:async';
import 'dart:io';

import '../esptouch_config.dart';

class UDPSocketClient {
  final List<StreamSubscription> _subscriptions = [];

  RawDatagramSocket mServerSocket;
  bool _closed;

  UDPSocketClient._();

  static Future<UDPSocketClient> create(int port) async {
    UDPSocketClient server = UDPSocketClient._();
    try {
      server.mServerSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, port,
          reuseAddress: true);
    } catch (e) {
      if (EsptouchConfig.logging) {
        print('[UDPSocketClient][create] IOException');
      }
    }
    server._closed = false;
    return server;
  }

  void listenSpecLengthBytes(
      final int length, void Function(List<int> bytes) onReceived) {
    if (EsptouchConfig.logging) {
      print('[UDPSocketClient][listenSpecLengthBytes] length=$length');
    }
    _subscriptions.add(
      mServerSocket.listen(
        (event) {
          Datagram datagram = mServerSocket.receive();
          if (datagram == null) return;

          if (onReceived != null) {
            List<int> specLengthData = List.from(datagram.data);
            if (EsptouchConfig.udpLogging) {
              String receivedDataInfo =
                  'recevied=${specLengthData.length}, data=$specLengthData';
              print(
                  '[UDPSocketClient][listenSpecLengthBytes] length=$length, $receivedDataInfo');
            }

            onReceived(specLengthData);
          }
        },
      ),
    );
  }

  void interrupt() {
    if (EsptouchConfig.logging) {
      print('[UDPSocketClient][interrupt] interrupted');
    }
    close();
  }

  void close() {
    for (StreamSubscription subscription in _subscriptions) {
      subscription.cancel();
    }

    if (!this._closed) {
      if (EsptouchConfig.logging) {
        print('[UDPSocketClient][interrupt] closed');
      }
      mServerSocket.close();
      // releaseLock();
      this._closed = true;
    }
  }
}
