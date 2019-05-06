import '../protocol/util/byte_data.dart';
import '../protocol/util/crc8.dart';
import '../util/illegal_argument_exception.dart';
import '../util/byte_utils.dart';

/// one data format:(data code should have 2 to 65 data)
/// <p>
/// control byte       high 4 bits    low 4 bits
/// 1st 9bits:       0x0             crc(high)      data(high)
/// 2nd 9bits:       0x1                sequence header
/// 3rd 9bits:       0x0             crc(low)       data(low)
/// <p>
/// sequence header: 0,1,2,...
///
/// @author afunx

class DataCode implements ByteData {
  static final int dataCodeLen = 6;
  static final int _indexMax = 127;

  int _seqHeader;
  int _dataHigh;
  int _dataLow;

  /// the crc here means the crc of the data and sequence header be transformed
  /// it is calculated by index and data to be transformed
  int _crcHigh;
  int _crcLow;

  DataCode(int uint8, int index) {
    if (index > _indexMax) {
      throw EsptouchArgumentException(
        'DataCode',
        'constructor',
        'index > INDEX_MAX',
      );
    }
    List<int> dataBytes = ByteUtil.splitUint8ToTwoBytes(uint8);
    _dataHigh = dataBytes[0];
    _dataLow = dataBytes[1];
    CRC8 crc8 = CRC8();
    crc8.updateByte(ByteUtil.convertUint8toByte(uint8));
    crc8.updateByte(index);
    List<int> crcBytes = ByteUtil.splitUint8ToTwoBytes(crc8.value);
    _crcHigh = crcBytes[0];
    _crcLow = crcBytes[1];
    _seqHeader = index;
  }

  @override
  List<int> get bytes {
    List<int> dataBytes = List(dataCodeLen);
    dataBytes[0] = 0x00;
    dataBytes[1] = ByteUtil.combineTwoBytesToOne(_crcHigh, _dataHigh);
    dataBytes[2] = 0x01;
    dataBytes[3] = _seqHeader;
    dataBytes[4] = 0x00;
    dataBytes[5] = ByteUtil.combineTwoBytesToOne(_crcLow, _dataLow);
    return dataBytes;
  }

  @override
  String toString() {
    StringBuffer stringBuffer = StringBuffer();
    List<int> dataBytes = bytes;
    for (int i = 0; i < dataCodeLen; i++) {
      String hexString = ByteUtil.convertByte2HexString(dataBytes[i]);
      stringBuffer.write("0x");
      if (hexString.length == 1) {
        stringBuffer.write('0');
      }
      stringBuffer.write(hexString);
      stringBuffer.write(" ");
    }
    return stringBuffer.toString();
  }
}
