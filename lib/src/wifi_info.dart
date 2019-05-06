import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

class WifiInfo {
  final ByteString ip;
  final ByteString ssid;
  final ByteString bssid;
  final ByteString password;

  WifiInfo({
    @required String ip,
    @required String ssid,
    @required String bssid,
    @required String password,
  })  : ip = ByteString(ip),
        ssid = ByteString(ssid),
        bssid = ByteString(bssid),
        password = ByteString(password ?? '');

  WifiInfo.copy(WifiInfo source)
      : ip = ByteString(source.ip.text),
        ssid = ByteString(source.ssid.text),
        bssid = ByteString(source.bssid.text),
        password = ByteString(source.password.text ?? '');

  InternetAddress get internetAddress => InternetAddress(ip.text);
  List<int> get rawInternetAddress => InternetAddress(ip.text)?.rawAddress;

  @override
  String toString() => '[$ip $ssid $bssid $password]';
}

class ByteString {
  final String _text;

  ByteString(this._text);

  String get text => _text;

  List<int> get bytes => utf8.encode(text);

  @override
  String toString() => '$_text';
}
