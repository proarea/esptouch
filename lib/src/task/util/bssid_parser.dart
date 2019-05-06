class BssidParser {
  BssidParser._();

  static String parseBssid(List<int> bssidBytes, int offset, int count) {
    List<int> bytes = List(count);
    for (int i = 0; i < count; i++) {
      bytes[i] = bssidBytes[i + offset];
    }
    return _parseBssid(bytes);
  }

  static String _parseBssid(List<int> bssidBytes) {
    StringBuffer stringBuffer = StringBuffer();
    int k;
    String hexK;
    String str;
    for (int bssidByte in bssidBytes) {
      k = 0xff & bssidByte;
      hexK = k.toRadixString(16);
      str = ((k < 16) ? ('0' + hexK) : (hexK));
      stringBuffer.write(str);
    }
    return stringBuffer.toString();
  }
}
