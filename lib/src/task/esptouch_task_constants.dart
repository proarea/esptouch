class EsptouchConstants {
  EsptouchConstants._();

  static const int intervalGuideCodeMillisecond = 8;
  static const int intervalDataCodeMillisecond = 8;
  static const int timeoutGuideCodeMillisecond = 2000;
  static const int timeoutDataCodeMillisecond = 4000;
  static const int timeoutTotalCodeMillisecond =
      timeoutGuideCodeMillisecond + timeoutDataCodeMillisecond;
  static const int waitUdpReceivingMillisecond = 15000;
  static const int waitUdpSendingMillisecond = 45000;
  static const int waitUdpTotalMillisecond =
      waitUdpReceivingMillisecond + waitUdpSendingMillisecond;
  static const int totalRepeatTime = 1;
  static const int esptouchResultOneLen = 1;
  static const int esptouchResultMacLen = 6;
  static const int esptouchResultIpLen = 4;
  static const int esptouchResultTotalLen =
      esptouchResultOneLen + esptouchResultMacLen + esptouchResultIpLen;
  static const int portListening = 18266;
  static const int portTarget = 7001;
  static const int thresholdSucBroadcastCount = 1;
}
