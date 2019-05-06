class CRC8 {
  static const int _crcPolynom = 0x8c;
  static const int _crcInitial = 0x00;

  static createCrcTable() {
    List<int> crcTable = List(256);
    for (int dividend = 0; dividend < 256; dividend++) {
      int remainder = dividend; // << 8;
      for (int bit = 0; bit < 8; ++bit)
        if ((remainder & 0x01) != 0)
          remainder = (remainder >> 1) ^ _crcPolynom;
        else
          remainder >>= 1;
      crcTable[dividend] = remainder;
    }
    return crcTable;
  }

  final int init;
  int _value;

  CRC8()
      : init = _crcInitial,
        _value = _crcInitial;

  int get value => _value & 0xff;

  void updateByteBuffer(List<int> buffer) => update(buffer, 0, buffer.length);

  void updateByte(int b) => update([b], 0, 1);

  void update(List<int> buffer, int offset, int len) {
    List<int> crcTable = createCrcTable();
    for (int i = 0; i < len; i++) {
      int data = buffer[offset + i] ^ _value;
      _value = (crcTable[data & 0xff] ^ (_value << 8));
    }
  }

  void reset() {
    _value = init;
  }
}
