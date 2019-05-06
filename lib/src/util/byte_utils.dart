import 'dart:math';

import 'dart:typed_data' show Uint8List;

import '../util/illegal_argument_exception.dart';

class ByteUtil {
  static const int intMax = 0x7FFFFFFF;
  static const int intMin = -0x80000000;

  static final String esptouchEncodingCharset = "UTF-8";

  static int convertUint8toByte(int uint8) {
    if (uint8 > intMax - intMin) {
      throw EsptouchArgumentException(
        'ByteUtil',
        'convertUint8toByte',
        'Out of Boundary',
      );
    }

    return Uint8List.fromList([uint8]).buffer.asByteData().getInt8(0);
  }

  static List<int> convertUint8ToBytes(List<int> uint8s) {
    return uint8s.map<int>((int uint8) => convertUint8toByte(uint8)).toList();
  }

  static int convertByteToUint8(int byte) => (byte & 0xff);

  static String convertByte2HexString(int byte) =>
      convertByteToUint8(byte).toRadixString(16);

  static String convertUint8ToHexString(int uint8) => uint8.toRadixString(16);

  static List<int> splitUint8ToTwoBytes(int uint8) {
    if (uint8 < 0 || uint8 > 0xff) {
      throw EsptouchArgumentException(
        'ByteUtil',
        'splitUint8ToTwoBytes',
        'Out of Boundary',
      );
    }

    String hexString = uint8.toRadixString(16);
    int lowByte;
    int highByte;
    if (hexString.length > 1) {
      highByte = int.parse(hexString.substring(0, 1), radix: 16);
      lowByte = int.parse(hexString.substring(1, 2), radix: 16);
    } else {
      highByte = 0;
      lowByte = int.parse(hexString.substring(0, 1), radix: 16);
    }
    return [highByte, lowByte];
  }

  static int combineTwoBytesToOne(int highByte, int lowByte) {
    if (highByte < 0 || highByte > 0xf || lowByte < 0 || lowByte > 0xf) {
      throw EsptouchArgumentException(
        'ByteUtil',
        'combineTwoBytesToOne',
        'Out of Boundary',
      );
    }

    return (highByte << 4 | lowByte);
  }

  static int combineTwoBytesToUint16(int highByte, int lowByte) {
    int highUint8 = convertByteToUint8(highByte);
    int lowUint8 = convertByteToUint8(lowByte);

    return (highUint8 << 8 | lowUint8);
  }

  static int randomByte() => (127 - Random().nextInt(256));

  static List<int> randomBytes(int length) =>
      List.generate(length, (_) => randomByte());

  static List<int> genSpecBytes(int length) =>
      List.generate(length, (_) => '1'.codeUnitAt(0));

  static List<int> randomUInt8Bytes(int length) {
    int uint8Length = convertByteToUint8(length);
    return randomBytes(uint8Length);
  }

  static List<int> genSpecUInt8Bytes(int length) {
    int uint8Length = convertByteToUint8(length);
    return genSpecBytes(uint8Length);
  }

  static void testSplitUint8To2bytes() {
    // 20 = 0x14
    List<int> result = splitUint8ToTwoBytes(20);
    if (result[0] == 1 && result[1] == 4) {
      print("testSplitUint8To2bytes(): pass");
    } else {
      print("testSplitUint8To2bytes(): fail");
    }
  }

  static void testCombine2bytesToOne() {
    int high = 0x01;
    int low = 0x04;
    if (combineTwoBytesToOne(high, low) == 20) {
      print("testCombine2bytesToOne(): pass");
    } else {
      print("testCombine2bytesToOne(): fail");
    }
  }

  static void testConvertChar2Uint8() {
    int b1 = 'a'.codeUnitAt(0);
    // -128: 1000 0000 should be 128 in unsigned int
    // -1: 1111 1111 should be 255 in unsigned int
    int b2 = -128;
    int b3 = -1;
    if (convertByteToUint8(b1) == 97 &&
        convertByteToUint8(b2) == 128 &&
        convertByteToUint8(b3) == 255) {
      print("testConvertChar2Uint8(): pass");
    } else {
      print("testConvertChar2Uint8(): fail");
    }
  }

  static void testConvertUint8toByte() {
    int c1 = 'a'.codeUnitAt(0);
    // 128: 1000 0000 should be -128 in int
    // 255: 1111 1111 should be -1 in int
    int c2 = 128 & 0xFF;
    int c3 = 255 & 0xFF;
    int c1Converted = convertUint8toByte(c1);
    int c2Converted = convertUint8toByte(c2);
    int c3Converted = convertUint8toByte(c3);
    if (c1Converted == 97 && c2Converted == -128 && c3Converted == -1) {
      print("testConvertUint8toByte(): pass");
    } else {
      print("testConvertUint8toByte(): fail");
    }
  }
}
