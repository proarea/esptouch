class EsptouchException implements Exception {
  final String className;
  final String methodName;
  final String message;

  const EsptouchException(this.className, this.methodName, this.message);

  String toString() => 'EsptouchException: [$className][$methodName] $message';
}
