import 'package:flutter_test/flutter_test.dart';

import 'package:esptouch/esptouch.dart';

// TODO cover with tests

void main() {
  test('test', () {
    expect(test1(2), 7);
    expect(() => test2(2), throwsNoSuchMethodError);
  });
}

int test1(int a) => a + 5;
int test2(int a) => throw NoSuchMethodError.withInvocation(null, null);
