import '../protocol/datum_code.dart';
import '../protocol/guide_code.dart';
import '../protocol/i_esptouch_generator.dart';
import '../util/byte_utils.dart';
import '../wifi_info.dart';

class EsptouchGenerator implements IEsptouchGenerator {
  List<List<int>> _gcBytes2;
  List<List<int>> _dcBytes2;

  EsptouchGenerator(WifiInfo wifiInfo, bool isSsidHiden) {
    // generate guide code
    GuideCode gc = GuideCode();
    List<int> gcU81 = gc.uint8s;
    _gcBytes2 = List<List<int>>(gcU81.length);

    for (int i = 0; i < _gcBytes2.length; i++) {
      _gcBytes2[i] = ByteUtil.genSpecBytes(gcU81[i]);
    }

    // generate data code
    DatumCode dc = DatumCode(wifiInfo, isSsidHiden);
    List<int> dcU81 = dc.uint8s;
    _dcBytes2 = List<List<int>>(dcU81.length);

    for (int i = 0; i < _dcBytes2.length; i++) {
      _dcBytes2[i] = ByteUtil.genSpecBytes(dcU81[i]);
    }
  }

  @override
  List<List<int>> getGCBytes2() => _gcBytes2;

  @override
  List<List<int>> getDCBytes2() => _dcBytes2;
}
