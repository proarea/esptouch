import 'dart:io';

import '../../util/byte_utils.dart';

class EspNetUtil {
  static String formatIpString(int value) {
    StringBuffer stringBuffer = StringBuffer();
    List<int> ipNumbers = intToByte(value);

    for (int i = ipNumbers.length - 1; i >= 0; i--) {
      stringBuffer.write((ipNumbers[i] & 0xFF).toString());
      if (i > 0) {
        stringBuffer.write(".");
      }
    }

    return stringBuffer.toString();
  }

  static List<int> intToByte(int value) {
    List<int> bytes = List(4);

    for (int i = 0; i < 4; i++) {
      int offset = (bytes.length - 1 - i) * 8;
      bytes[i] = ((value >> offset) & 0xFF);
    }

    return bytes;
  }

  static InternetAddress parseInternetAddress(
      List<int> inetAddrBytes, int offset, int count) {
    StringBuffer stringBuffer = StringBuffer();

    for (int i = 0; i < count; i++) {
      stringBuffer.write((inetAddrBytes[offset + i] & 0xff).toString());
      if (i != count - 1) {
        stringBuffer.write('.');
      }
    }

    try {
      return InternetAddress(stringBuffer.toString());
    } catch (e) {
      e.printStackTrace();
    }
    return null;
  }

  static List<int> convertBssidToBytes(String bssid) {
    List<String> bssidSplits = bssid.split(':');
    List<int> result = new List(bssidSplits.length);

    for (int i = 0; i < bssidSplits.length; i++) {
      result[i] =
          ByteUtil.convertUint8toByte(int.parse(bssidSplits[i], radix: 16));
    }

    return result;
  }
}
