import 'dart:io';

typedef void EsptouchResultListener(EsptouchResult result);

class EsptouchResult {
  final bool succeed;
  final String bssid;
  final InternetAddress internetAddress;

  bool cancelled;

  EsptouchResult(this.succeed, this.bssid, this.internetAddress) : this.cancelled = false;
  EsptouchResult.fail(this.cancelled)
      : succeed = false,
        bssid = null,
        internetAddress = null;

  @override
  String toString() => '{ succeed: $succeed, bssid: $bssid, internetAddress: $internetAddress }';
}
