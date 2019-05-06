class EsptouchArgumentException implements Exception {
  final String className;
  final String methodName;
  final String message;

  const EsptouchArgumentException(this.className, this.methodName, this.message);

  String toString() => 'EsptouchArgumentException: [$className][$methodName] $message';
}
