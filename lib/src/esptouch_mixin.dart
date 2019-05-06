import 'package:flutter/material.dart';

import 'task/esptouch_result.dart';
import 'wifi_info.dart';
import 'esptouch.dart';

@optionalTypeArgs
mixin EsptouchMixin<T extends StatefulWidget> on State<T> {
  bool get esptouchExecuting => Esptouch.executing;

  Future<void> startEsptouch(WifiInfo wifiInfo) async {
    if (esptouchExecuting) return;
    try {
      Esptouch.connect(
        wifiInfo,
        deviceCount: 1,
        onEsptouchResult: onEsptouchResult,
        onEsptouchFinished: onEsptouchFinished,
        onEsptouchError: onEsptouchError,
      );
    } catch (e) {
      Esptouch.stop();
      onEsptouchError(e);
    }
  }

  void stopEsptouch() => Esptouch.stop();

  void onEsptouchError(dynamic error) {}

  void onEsptouchResult(EsptouchResult result) {}

  void onEsptouchFinished(List<EsptouchResult> results) {}
}
