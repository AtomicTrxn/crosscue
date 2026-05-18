import 'package:crosscue/core/utils/uuid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('v4 returns RFC-4122-canonical lowercase strings', () {
    for (var i = 0; i < 50; i++) {
      expect(Uuid.v4(), matches(pattern));
    }
  });

  test('v4 generates distinct values across many calls', () {
    final seen = <String>{};
    for (var i = 0; i < 1000; i++) {
      seen.add(Uuid.v4());
    }
    expect(seen, hasLength(1000));
  });
}
