import '../protocol/data_code.dart';
import '../protocol/util/byte_data.dart';
import '../protocol/util/crc8.dart';
import '../protocol/util/uint8_data.dart';
import '../util/byte_utils.dart';
import '../wifi_info.dart';

class DatumCode implements ByteData, Uint8Data {
  // define by the Esptouch protocol, all of the datum code should add 1 at last to prevent 0
  static final int _extraLength = 40;
  static final int _extraHeadLength = 5;

  List<DataCode> _dataCodes;

  DatumCode(WifiInfo wifiInfo, bool ssidHidden) {
    // Data = total len(1 int) + apPwd len(1 int) + SSID CRC(1 int) +
    // BSSID CRC(1 int) + TOTAL XOR(1 int)+ ipAddress(4 int) + apPwd + apSsid apPwdLen <=
    // 105 at the moment

    // total xor
    int totalXor = 0;

    int wifiPasswordLength = wifiInfo.password.bytes.length;
    CRC8 crc = CRC8();
    crc.updateByteBuffer(wifiInfo.ssid.bytes);
    int wifiSsidCrc = crc.value;

    crc.reset();
    crc.updateByteBuffer(wifiInfo.bssid.bytes);
    int wifiBssidCrc = crc.value;

    int wifiSsidLength = wifiInfo.ssid.bytes.length;

    List<int> ipBytes = ByteUtil.convertUint8ToBytes(wifiInfo.rawInternetAddress);
    int ipLength = ipBytes.length;

    int _totalLen = (_extraHeadLength + ipLength + wifiPasswordLength + wifiSsidLength);
    int totalLen = ssidHidden
        ? (_extraHeadLength + ipLength + wifiPasswordLength + wifiSsidLength)
        : (_extraHeadLength + ipLength + wifiPasswordLength);

    // build data codes
    _dataCodes = List();
    _dataCodes.add(DataCode(_totalLen, 0));
    totalXor ^= _totalLen;
    _dataCodes.add(DataCode(wifiPasswordLength, 1));
    totalXor ^= wifiPasswordLength;
    _dataCodes.add(DataCode(wifiSsidCrc, 2));
    totalXor ^= wifiSsidCrc;
    _dataCodes.add(DataCode(wifiBssidCrc, 3));
    totalXor ^= wifiBssidCrc;
    // ESPDataCode 4 is null
    for (int i = 0; i < ipLength; ++i) {
      int c = ByteUtil.convertByteToUint8(ipBytes[i]);
      totalXor ^= c;
      _dataCodes.add(DataCode(c, i + _extraHeadLength));
    }

    for (int i = 0; i < wifiInfo.password.bytes.length; i++) {
      int c = ByteUtil.convertByteToUint8(wifiInfo.password.bytes[i]);
      totalXor ^= c;
      _dataCodes.add(DataCode(c, i + _extraHeadLength + ipLength));
    }

    // totalXor will xor apSsidChars no matter whether the ssid is hidden
    for (int i = 0; i < wifiInfo.ssid.bytes.length; i++) {
      int c = ByteUtil.convertByteToUint8(wifiInfo.ssid.bytes[i]);
      totalXor ^= c;
      if (ssidHidden) {
        _dataCodes.add(DataCode(c, i + _extraHeadLength + ipLength + wifiPasswordLength));
      }
    }

    // add total xor last
    _dataCodes.insert(4, DataCode(totalXor, 4));

    // add bssid
    int bssidInsertIndex = _extraHeadLength;
    for (int i = 0; i < wifiInfo.bssid.bytes.length; i++) {
      int index = totalLen + i;
      int c = ByteUtil.convertByteToUint8(wifiInfo.bssid.bytes[i]);
      DataCode dc = DataCode(c, index);
      if (bssidInsertIndex >= _dataCodes.length) {
        _dataCodes.add(dc);
      } else {
        _dataCodes.insert(bssidInsertIndex, dc);
      }
      bssidInsertIndex += 4;
    }
  }

  @override
  String toString() {
    StringBuffer stringBuffer = StringBuffer();
    for (int dataByte in bytes) {
      String hexString = ByteUtil.convertByte2HexString(dataByte);
      stringBuffer.write('0x');
      if (hexString.length == 1) {
        stringBuffer.write('0');
      }
      stringBuffer.write(hexString);
      stringBuffer.write(' ');
    }
    return stringBuffer.toString();
  }

  @override
  List<int> get uint8s {
    int len = bytes.length ~/ 2;
    List<int> dataU8s = List(len);
    int high, low;
    for (int i = 0; i < len; i++) {
      high = bytes[i * 2];
      low = bytes[i * 2 + 1];
      dataU8s[i] = ByteUtil.combineTwoBytesToUint16(high, low) + _extraLength;
    }
    return dataU8s;
  }

  @override
  List<int> get bytes {
    List<int> datumCode = List(_dataCodes.length * DataCode.dataCodeLen);
    int index = 0;
    for (DataCode dataCode in _dataCodes) {
      for (int byte in dataCode.bytes) {
        datumCode[index++] = byte;
      }
    }
    return datumCode;
  }
}
