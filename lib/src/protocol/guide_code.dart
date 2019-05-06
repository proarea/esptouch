import '../protocol/util/uint8_data.dart';
import '../util/byte_utils.dart';

class GuideCode implements Uint8Data {
  final List<int> _guideCode = [515, 514, 513, 512];
  final int _guideCodeLength = 4;

  @override
  List<int> get uint8s => _guideCode;

  @override
  String toString() {
    StringBuffer stringBuffer = StringBuffer();
    List<int> dataU8s = uint8s;
    for (int i = 0; i < _guideCodeLength; i++) {
      String hexString = ByteUtil.convertUint8ToHexString(dataU8s[i]);
      stringBuffer.write('0x');
      if (hexString.length == 1) {
        stringBuffer.write('0');
      }
      stringBuffer.write(hexString);
      stringBuffer.write(' ');
    }
    return stringBuffer.toString();
  }
}
